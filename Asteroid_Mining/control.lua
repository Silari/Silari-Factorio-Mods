--Resets miner module recipes.
require("scripts/recipes.lua")

require("scripts/advanced/adv-mining.lua")

function on_changed(event)
    --Updates the recipes when mod configurations change. Ensures recipes on rocket silo tech are enabled/disabled as they should be.
    reset_recipes(event)
    --Ensures globals needed for advanced method are created.
    init_mining()
    --Updates player GUIs for the advanced method
    on_config_change(event)
    --log ("on change!")
    --log(serpent.block(event.mod_changes))
    --Fix for initial versions with ADV mining not setting surface resources.
    if event.mod_changes and event.mod_changes["Asteroid_Mining"] then
        --log(serpent.block(global.astmine))
        local oldver = event.mod_changes["Asteroid_Mining"].old_version
        if oldver == "0.9.8" or oldver == "0.9.9" then
            log("Found old AM version! Fixing up tables.")
            make_resource_table() -- Remake the default table as old versions allowed 0 values.
            for name, surface in pairs(game.surfaces) do -- Iterate all existing surfaces
                --log(name)
                -- We check if this is a valid surface to use.
                if check_surface(name) then
                    log("Resetting surface " .. name)
                    -- Good surface, (re)make the resource table. Old versions didn't make them on init/created.
                    make_resource_table(name)
                else
                    global.astmine.surfaces[name] = nil
                end
            end
            -- Possible for old version to have left partial info for a surface now deleted - clear those out.
            local removename = {}
            for name, surftable in pairs(global.astmine.surfaces) do
                -- No resource table and no forces info means there is nothing here. Mark it to delete.
                if surftable.resources == nil and table_size(surftable.forces) == 0 then
                    table.insert(removename, name)
                end
            end
            --log(serpent.block(removename))
            for _, name in ipairs(removename) do
                global.astmine.surfaces[name] = nil
            end
        end
        -- 0.9.10 changes a lot of stuff which I may not have tested enough. Warn users to make a backup.
        if event.mod_changes["Asteroid_Mining"].new_version == "0.9.10" and settings.startup["astmine-makerockets"].value then
            game.print("WARNING: You are using the advanced mode of Asteroid Mining. Please keep in mind it is still in a beta state, and this update makes a LOT of changes to how surfaces work. Be sure to check the GUI and ensure surface info (amount of resources, orbital assets, etc) looks correct before saving your game. Making a backup of the save you loaded is recommended prior to saving over it.")
        end
        --log(serpent.block(global.astmine))
    end
end
script.on_configuration_changed(on_changed)

