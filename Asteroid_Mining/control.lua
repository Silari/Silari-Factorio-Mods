--Resets miner module recipes.
require("scripts/recipes.lua")

-- Scripting for advanced mode.
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
        --log(serpent.block(storage.astmine))
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
                    storage.astmine.surfaces[name] = nil
                end
            end
            -- Possible for old version to have left partial info for a surface now deleted - clear those out.
            local removename = {}
            for name, surftable in pairs(storage.astmine.surfaces) do
                -- No resource table and no forces info means there is nothing here. Mark it to delete.
                if surftable.resources == nil and table_size(surftable.forces) == 0 then
                    table.insert(removename, name)
                end
            end
            --log(serpent.block(removename))
            for _, name in ipairs(removename) do
                storage.astmine.surfaces[name] = nil
            end
        end
        --log(serpent.block(storage.astmine))
    end
end
script.on_configuration_changed(on_changed)

