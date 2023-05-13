-- Some conventions I need to try and hold to:
-- ALWAYSALWAYSALWAYS check for substitutes!
-- surfname = get_sub_surface(surfacename)
-- surftable = global.astmine.surfaces[surfname]
-- forcetable = global.astmine.surfaces[surfname].forces[forcename] -- note there's a init_force function that should be used instead. It inits if needed and returns the force table.
-- restable = global.astmine.surfaces[surfname].resources

-- Our data layout
-- global.astmine
    -- .surfaces = {}
        -- .forces = {force.name = table} -- table of forces to hold their mining info
            -- .orbiting = {resource-name = {table of "resource type" = table of {level = count}}}
            -- .available = table of {resource-name = amount} -- tracks how much of each resource is in orbit ready to be dropped
            -- .targets = Not currently used -- possibly use this to keep tracks of what targets there are
            -- .upgrades = table of level = count {[5] = 0, [25] = 0} right now
        -- .resources = {resource-name = ResourceInfo} -- Resources available for the given surface. If not set, it will use the default set of resources. MAYBE: table of {rate (per mixed miner level) = #, maxrate = (maximum per minute from each source regardless of level)}. If amount=0, mixed OR specific miner can't find on this surface. If non-zero a specific miner uses a rate based on a percentage of the total ore per minute for the surface. Maybe allow a specrate value to override with a specific value.
    -- .substitute = {surface.name = surface.name} -- Surface in this table uses the given surface instead for resources. This allows for something like Space Exploration to have a planet and it's orbit use the same resource pool. Setting it to nil removes it and becomes it's own surface, setting it to "" disallows asteroid mining - for something like Factorissimo or underground mods.
    -- .default = {resource-name = ResourceInfo}
    -- .research = {tech-name = itemtogive}
    -- .researcht = string with surface name. Used by the research events which default to nauvis if this isn't defined

-- Data layout of resource amount is table of ResourceInfo
-- {rate = rate obtained per level, maxrate = maximum generated per minute - if not defined defaults to astminemaxrate, (NI) specrate = rate for specialized miner - if not defined defaults to rate based on combined rate of all ores on surface, (NI) specmax = maximum per minute for specialized miners - if not defined defaults to maxrate}

--Has our GUI components
require("adv_gui")

--Has our remote interfaces
require("adv-remote")

--Some constants we use here for easy changing
astminemaxrate = 2000000 -- Default amount of maximum ore per tick, if none set on the ore.
astminemaxstored = 2000000 -- No ore can have more than this stored.

astmineratio = 0.6 -- Ratio of a specific miner's output compared to the total output of a mixed miner.

astminebaserate = 100 -- Base rate to use for ore gathering.

--Useful functions to do things
function add_resource(resourcename, surfacename)
    -- Interface function to add a resource to the given surface, or the default if none given.
end

function add_item(itemname, surfacename)
    --Function to add an item to the given surface, or the default if none given.
    --This needs to make a resource that gives the item, so I need to move this into a script in data stage instead, so it can later be added using add_resource. That means surface_name is useless. Really this whole function is likely to not make it in - the add_resource one above would be the better option.
end

function get_sub_surface(surfacename)
    --Single surface uses nauvis for everything.
    if settings.startup["astmine-singlesurface"].value then
        return 'nauvis'
    end
    -- Returns the surface substituted for this surface, or this surface if not substituted.
    subsurf = global.astmine.substitute[surfacename]
    if subsurf then
        return subsurf
    end
    return surfacename
end

function set_sub_surface(surfacename, nametosub)
    global.astmine.substitute[surfacename] = nametosub
end

--Command to get information about the current surface, based on using player's force.
function surfaceinfo(event)
    --log(serpent.block(global.astmine))
    --log(event.parameter)
    local force, surface, player, message
    message = "An error occurred, no valid return found." -- Should be replaced so seeing it means something went wrong.
    if event.player_index then -- Used by a player, as opposed to server console
        player = game.players[event.player_index]
        force = player.force
        surface = player.surface
    else -- If used from server console
        force = game.forces['player']
        surface = game.surfaces['nauvis']
    end
    -- Rebuild the current surface info.
    if event.parameter == "rebuild" then
        if check_surface(surface.name) then -- will fail if surface subbed or if invalid surface (ie SE special surface)
            make_resource_table(surface.name)
        end
    end
    if event.parameter == "sezone" then
        get_radius_max(surface.name)
    end
    local surfname = get_sub_surface(surface.name)
    if surfname == "" then -- Surface is not useable for asteroid mining.
        if player then -- Used by a player, so print to them.
            player.print("Surface can not be used for mining. Please try another surface.")
        else -- Possibly used by console, so just log it.
            log("Surface can not be used for mining. Please try another surface.")
        end   
        return
    end
    -- surfname should always point to a valid surface table.
    --log("surfaceinfo: " .. surfname .. " : " .. force.name)
    local surftable = global.astmine.surfaces[surfname]
    --log(serpent.block(surftable))
    local forcetable = surftable.forces[force.name]
    --log("post forcetable" .. serpent.block(forcetable))
    if forcetable then
        message = force.name .. " force - Surface: " .. surface.name .. " "
        local available = ""
        local total = 0
        for name, value in pairs(forcetable.available) do
            total = total + value
            available = available .. name .. ": " .. value .. " "
        end
        if total > 0 then
            message = message .. "\nAvailable: " .. available
        else
            message = message .. "\nNo ore awaiting deorbit on this surface. "
        end
        --log("Postavail: " .. message)
        local orbiting = ""
        for name, value in pairs(forcetable.orbiting) do
            local total = (value[1] or 0)
            total = total + (value[5] or 0) * 5
            total = total + (value[25] or 0) * 25
            if total > 0 then -- This subtable shouldn't exist unless we have at least 1, but JIC
                local newstring = "\n    " .. name .. ": Level 1 = " .. (value[1] or 0) .. " " .. ":: Level 5 = " .. (value[5] or 0) .. " " .. ":: Level 25 = " .. (value[25] or 0) .. " :: Total = " .. total
                orbiting = orbiting .. newstring
            end
        end
        if orbiting then
            message = message .. "\nOrbiting: " .. orbiting
        else
            message = message .. "\nOrbiting: No miners in orbit. "
        end
        --log("Postorbit: " .. message)
        if forcetable.upgrades["station"] ~= nil then
            message = message .. "\nUpgrade station in orbit. "
        else
            message = message .. "\nUpgrade station not yet deployed. "
        end
        --log("Poststation: " .. message)
        local upgrades = ""
        if (forcetable.upgrades[5] > 0) or (forcetable.upgrades[25] > 0) then -- At least one upgrade in orbit
            upgrades = "Level 5 = " .. (forcetable.upgrades[5] or 0) .. " " .. " :: Level 25 = " .. (forcetable.upgrades[25] or 0)
            message = message .. "\nUpgrades: " .. upgrades
        else
            -- We don't actually expect upgrades to always be around, so just do nothing if there aren't any waiting.
            message = message .. "\nNo upgrades in orbit. "
        end            
        --log("Postupgrade: " .. message)
    else -- No info for that force
        message = "Force '" .. force.name .. "' does not have any orbitals for " .. surfname .. "."
    end
    -- Grab the table that lists resources for this surface. It may be in the surftable
    -- If resources isn't defined for that surface, we instead use the default table.
    local restable = (surftable.resources or global.astmine.default)
    local resources = ""
    for name, value in pairs(restable) do
        resources = resources .. "\n    " .. name .. " Base Rate: " .. value["rate"] .. " per minute"
        if value["maxrate"] then
            resources = resources .. " Max Rate: " .. value["maxrate"] .. " per minute"
        end
    end
    if resources then
        message = message .. "\nSurface Resources:" .. resources
    else
        message = message .. "\nUnable to find resources for surface!"
    end
    message = message .. "\nYou can use the 'rebuild' parameter to force rebuilding the resource table for this surface."
    --log(message)
    if player then -- Used by a player, so print to them.
        player.print(message)
    else -- Possibly used by console, so just log it.
        log(message)
    end
end

-- This ensures the given force has the given surface initialized.
-- Should be called when force launches something, when building is registered, maybe more later.
-- It is NOT called when a force or surface is created. We're using a lazy init to save time in later loops.
-- Several functions also use this to grab a copy of the force table, ensuring it's ready for use.
function init_force(forcename, surfacename)
    surfname = get_sub_surface(surfacename)
    --game.print("Surfname: " .. surfname)
    surftable = global.astmine.surfaces[surfname]
    --game.print("init force" .. serpent.block(surftable))
    -- Surface hasn't been initialized, do it now.
    if not surftable then
        if not check_surface(surfacename) then return false end -- Don't use this surface for anything
        global.astmine.surfaces[surfacename] = {forces = {}}
        make_resource_table(surfacename)
        surftable = global.astmine.surfaces[surfname]
    end
    -- If we haven't made a table for the force yet, do it
    if not surftable.forces[forcename] then
        surftable.forces[forcename] = {orbiting = {}, available = {}, upgrades = {[5] = 0, [25] = 0}}
    end
    return surftable.forces[forcename]
end

-- Checks product table for any fluid products.
function givesfluid(products)
    for _, product in ipairs(products) do
        if product['type'] == 'fluid' then return true end
    end
    return false
end

-- Checks if we should make a surface/resource table for this surface - ie isn't subbed or blacklisted.
function check_surface(surfacename)
    --log("Check surface " .. surfacename)
    if settings.startup["astmine-singlesurface"].value then
        return true -- Under single surface, every surface is valid.
    end
    if global.astmine.substitute[surfacename] then return false end -- Surface is subbed, do nothing
    if surfacename == "aai-signals" then -- Probably for the inter-planet signals
        set_sub_surface(surfacename,"")
        return false
    end
    if game.active_mods["space-exploration"] then
        --log("SE installed")
        -- The fake surface used for the star map view. Always invalid.
        if surfacename == "starmap-1" then 
            set_sub_surface(surfacename,"")
            return false
        end
        -- Surfaces used for spaceships in transit. We can ignore those.
        if string.sub(surfacename,1,10) == "spaceship-" then
            set_sub_surface(surfacename,"")
            return false
        end
        local surfindex = game.surfaces[surfacename].index
        -- We can't use surftype always cause it's nil at this point for surface_created, despite the next call succeeding fine.
        local surftype = remote.call("space-exploration", "get_surface_type", {surface_index = surfindex})
        local sezone = false
        if surftype == nil then
            sezone = remote.call("space-exploration", "get_zone_from_name", {zone_name = surfacename})
            --log(serpent.block(sezone))
        end
        if sezone then surftype = sezone.type end
        --log(surfacename .. " : " .. (surftype or "no type"))
        if surftype == "planet" or surftype == "moon" then
            --log("Planet/moon")
        elseif surftype == nil then
            log("nil type, shouldn't happen anymore.")
        elseif surftype == "orbit" then -- Orbit of a planet, we want to substitute to that planet.
            --Orbits would need to call get_zone_from_surface_index, grab the parent_index property, get_zone_from_zone_index using the parent_index to find the surface name. That would be the sub.
            --if sezone == false then sezone = remote.call("space-exploration", "get_zone_from_name", {zone_name = surfacename}) end
            --log(serpent.block(sezone))
            --Parent is sezone.parent_index
            -- The problem we have is that the orbit might be created and the surface not yet (or ever). There might be enough info in sezone for me to create it from that but not sure if THATS created before the surface. Look into it later.
            set_sub_surface(surfacename,"") -- For now we stop it until I write this code.            
            return false -- We still return false as this is not a real surface - it's substituted
        else
            set_sub_surface(surfacename,"")
            return false
        end
    end
    if game.active_mods["Factorissimo2"] or game.active_mods["factorissimo-2-notnotmelon"] then
        --log("Factorissimo2 or fork installed")
        -- We want to ignore any Factorissimo surface
        if string.sub(surfacename,1,14) == "Factory floor " then
            set_sub_surface(surfacename,"")
            return false
        end
        -- We want to ignore the single-surface fork floor
        if surfacename == 'factory-floor-1' then
            set_sub_surface(surfacename,"")
            return false
        end
        -- Apparently used by the notmelon fork for power connections
        if surfacename == 'factory-power-connection' then
            set_sub_surface(surfacename,"")
            return false
        end
    end
    return true -- Got to the end and it didn't fail, must be fine
end

-- Gets the SE radius multiplier for the given surface, for max resources per minute.
function get_radius_max(surfacename, miningrate)
    -- radius = 1245.5232602250646, radius_multiplier = 0.3, - MOON
    -- For planets radius multiplier is 1/10000 the radius. Nauvis is an exception: (nauvis radius = 5691.7291654647397, radius_multiplier = 0.66069768030008618)
    --log("get_radius_max : " .. surfacename)
    -- SE uses a different name for nauvis
    if game.active_mods["space-exploration"] then
        if surfacename == 'nauvis' then surfacename = 'Nauvis' end
        local sezone = remote.call("space-exploration", "get_zone_from_name", {zone_name = surfacename})
        if sezone then
            --log(serpent.block(sezone))
            if sezone.radius then
                -- Maximum rate is 50, adjusted for the radius of the surface.
                return math.floor(sezone.radius / 10000 * 50 * miningrate)
            end
        end
    end
    -- No return to this point, we don't have a max rate
    return nil
end

-- Builds the list of resources for the given surface, or the default table based on nauvis if none given.
function make_resource_table(surfacename, ressurfacename)
    -- This should attempt to build the resources for this surface from the map generation settings. 
    -- Get the table for this surface and make sure it's initialized if needed
    local restable
    log("Making resource table for: " .. (surfacename or "default"))
    if surfacename == nil then
        restable = global.astmine.default -- No surface given so we init the default table, which any surface without a table will use.
        -- This table is based on nauvis settings, because it is guaranteed to exist.
        surfacename = 'nauvis'
    else
        -- By default we don't make a resources table for a surface, so it would use the default. Since we were explicitly told to init a specific surface, we make the table.
        if global.astmine.surfaces[surfacename].resources == nil then
            global.astmine.surfaces[surfacename].resources = {}
        end
        restable = global.astmine.surfaces[surfacename].resources
    end
    -- If we weren't given a surface to base resources on, use the surface we're making the table for
    if ressurfacename == nil then
        ressurfacename = surfacename
    end
    local surface = game.surfaces[ressurfacename]
    if surface == nil then
        log("Invalid surface! " .. ressurfacename)
        return false
    end
    local mapgen = surface.map_gen_settings.autoplace_controls
    --log(serpent.block(mapgen))
    if mapgen == nil then
        log("No autoplace controls for surface " .. surfacename)
        -- This surface isn't valid since it has no resources. Remove it.
        set_sub_surface(surfacename,"")
        return false
    end
    -- This should get all resource entities so we can add them to our table.
    for name, resource in pairs(game.get_filtered_entity_prototypes({{filter="type", type="resource"}})) do
        --log("Resource name: " .. name)
        -- I don't need to take into account anything about products EXCEPT fluids since we're generating the RESOURCE not the PRODUCTS. All we need to do is adjust amounts for map generation settings.
        local products = resource.mineable_properties.products
        -- We skip resources that make nothing, infinite resources, TODO optionally resources requiring fluids, 
        if products == nil or resource.infinite_resource or (false and (resource.mineable_properties.fluid_amount ~= nil and resource.mineable_properties.fluid_amount > 0)) then
            --log("Skipping resource " .. name)
        else
            if givesfluid(products) then
                --log("Fluid found in resource! " .. name .. " : " .. serpent.block(products))
            else
                local miningrate = astminebaserate -- Default rate to use for any ore.
                if resource.autoplace_specification then -- Autoplace specification exists, try to match amounts with commonality of the resource
                    -- TODO Finish this
                    --log("Control name: " .. resource.autoplace_specification.control)
                    local rescontrols = mapgen[resource.autoplace_specification.control]
                    --log(serpent.block(rescontrols))
                    if rescontrols ~= nil then
                        -- Averages frequency, richness, and size values to get the rate adjustment for the surface.
                        local avgrate = (rescontrols.frequency + rescontrols.richness + rescontrols.size) / 3
                        -- We multiply our base mining rate with the values for frequency, richness, and size.
                        miningrate = miningrate * rescontrols.frequency
                        miningrate = miningrate * rescontrols.richness
                        miningrate = math.floor(miningrate * rescontrols.size) -- We want an integer value, so floor it.
                        miningrate = math.floor(astminebaserate * avgrate)
                    end
                end
                -- We don't want 0 values in here for legibility. While we're at it, at least 1.
                if miningrate >= 1 then
                    -- Calculated mining rate for this resource. Also the maxrate based on the Space Exploration radius - for non-SE games, this is nil and thus is removed.
                    restable[name] = {["rate"] = miningrate, ["maxrate"] = get_radius_max(surfacename, miningrate)}
                else
                    restable[name] = nil -- Clears out any value less than one that may have been stored previously
                end
                --log(serpent.block(restable[name]))
            end
        end
    end
    --log(serpent.block(restable))
    return true
end

-- Attempts to upgrade the miner for the given resource.
function minerupgrade(forcetable, player, orename)
    --game.print(player.name .. " : " .. orename)
    -- If the surface has no orbital upgrade station, tell the user.
    if forcetable.upgrades["station"] == nil then
        -- No upgrade station in orbit, player can not upgrade their rockets. If orename is nil they sent an upgrade, warn them it can't be used yet.
        player.print({"astmine-no-station"})
        return
    end
    -- See if there's any upgrades waiting. If not, do nothing.
    --log("checkupgrade " .. serpent.block(forcetable))
    if forcetable.upgrades[5] == 0 and forcetable.upgrades[25] == 0 then
        player.print({"astmine-no-upgrades"})
        return
    end
    -- If we were provided a resource name, check that only.
    local orestocheck = {orename = forcetable.orbiting[orename]}
    if orename == nil then
        orestocheck = forcetable.orbiting
    end
    local updategui = false
    --log("checkupgrade2 " .. serpent.block(orestocheck))
    for name, value in pairs(orestocheck) do
        --log(name .. " : " .. serpent.block(value))
        -- value = {1=,5=,25=}
        if value[1] > 2 and forcetable.upgrades[5] > 0 then
            value[1] = value[1] - 3
            forcetable.upgrades[5] = forcetable.upgrades[5] - 1
            value[5] = value[5] + 1
            updategui = true
        end
        -- By running them in this order we allow for using both upgrades at once; if they have 3 level 1, 2 level 5, and both upgrade modules in orbit they end with 1 level 25.
        if value[5] > 2 and forcetable.upgrades[25] > 0 then
            value[5] = value[5] - 3
            forcetable.upgrades[25] = forcetable.upgrades[25] - 1
            value[25] = value[25] + 1
            updategui = true
        end
    end
    -- If any of upgrades happened, update player GUIs to account for it.
    if updategui then 
        updateplayerGUI()
        player.print({"astmine-upgraded"})
    else
        player.print({"astmine-upgrade-failed"})
    end
end


-- **************************
-- Events section
-- **************************
-- Stuff we may need to add later.
-- script.on_event(ALL THE BUILDING) -- We need to register our am-target when it gets built. If we stop using find_entities_filtered, that is.
-- script.on_event(defines.events.on_surface_deleted,nil) -- Remove any stored references to the surface. Biggest issue would be if one is set as a substitute target - need to loop over that table. Might not even want to do that if we use surface.name, so if two surfaces are shared we leave the shared name in use for the others. In that case surface_cleared SHOULD remove all the info though.
-- script.on_event(defines.events.on_surface_cleared,nil) -- Probably do nothing for this, shouldn't be used much. If we do it'd just be the same as deleted, except then reinit like creating. CHANGED: This should clear the info, as we don't do that when the surface is deleted.
-- on_force_created -- make a table for the force? No we lazily init the table when needed.
-- on_forces_merged/on_forces_merging -- probably use the second one JIC as it's slightly earlier and old force still exists at that time. Nothing we do is really affected by the merging, we just need to add the .orbiting and .resources for the two forces.

--Ensures that globals were initialized. Called on init and by on_configuration_changed
function init_mining()
    log("Asteroid Mining advanced mining init")
    if not global.astmine then -- Holds asteroid mining data
      global.astmine = {}
    end
    if not global.astmine.surfaces then -- Holds per surface data, including force info for the surface
        -- nauvis is initialized here since the game doesn't call the surface_created event for it
        -- This is no longer true - we initialize surfaces when they are first used, not before.
        global.astmine.surfaces = {}
    end
    if not global.astmine.substitute then -- Holds surface substitutions - ie so surface and orbit surface share.
      global.astmine.substitute = {}
    end
    if not global.astmine.default then -- Holds resources for any surface not configured.
      global.astmine.default = {}
    end
    -- If default surface wasn't init yet, do so now.
    if next(global.astmine.default) == nil then
        --log("Making resource table")
        make_resource_table()
    end
    -- We're done making our surface related tables, so let's initialize all our surfaces
    for name, surface in pairs(game.surfaces) do
        -- Check this is a good surface to use (skips anything with a sub or blacklisted)
        if check_surface(name) then  -- Removed: name ~= "nauvis" and 
            -- Skip any surface we already have a table for.
            if global.astmine.surfaces[name] == nil then
                global.astmine.surfaces[name] = {}
                global.astmine.surfaces[name]["forces"] = {}
            end
            make_resource_table(name)
        end
    end
    if not global.astmine.research then
        global.astmine.research = {}
    end
end

script.on_init(function()
  init_mining()
  commands.add_command("asteroid","Displays Asteroid Mining surface info",surfaceinfo)
  --addremote()
end)

script.on_load(function()
  commands.add_command("asteroid","Displays Asteroid Mining surface info",surfaceinfo)
  --addremote()
end)




function techdone(event)
    --game.print(serpent.block(event) .. " : techname : " .. event.research.name)
    -- Tech result is what kind of miner to give
    local techresult = global.astmine.research[event.research.name]
    --game.print(techresult)
    if techresult == nil then return end -- Not in our table, ignore
    local forcename = event.research.force.name
    local surfacename = global.astmine.researcht or 'nauvis'
    surfacename = get_sub_surface(surfacename)
    local forcetable = init_force(forcename, surfacename)
    addlevel(forcetable.orbiting, techresult, 1)
end

function techundone(event)
    --game.print(serpent.block(event) .. " : techname : " .. event.research.name)
    local techresult = global.astmine.research[event.research.name]
    if techresult == nil then return end -- Not in our table, ignore
    local forcename = event.research.force.name
    local surfacename = global.astmine.researcht or 'nauvis'
    surfacename = get_sub_surface(surfacename)
    local forcetable = init_force(forcename, surfacename)
    addlevel(forcetable.orbiting, techresult, -1)
end

script.on_event(defines.events.on_research_finished, techdone) -- Give miners if a miner research was completed
script.on_event(defines.events.on_research_reversed, techundone) -- undo the above if research was uncompleted

script.on_event(defines.events.on_surface_created,function(event)
    -- We need to add the default tables for our surface when it's created.
    -- Forces is empty for now, it'll get filled in as needed by the rocket launch events. This means our nth tick loop can save time by not iterating over a bunch of forces that have nothing.
    local surface = game.surfaces[event.surface_index]
    if not surface then -- this really shouldn't happen but JIC
        log("Surface created but index invalid!")
        return
    end
    if not check_surface(surface.name) then return end -- Don't use this surface for anything
    local surfacename = get_sub_surface(surface.name)
    if not global.astmine.surfaces[surfacename] then
        global.astmine.surfaces[surfacename] = {forces = {}} 
    end
    make_resource_table(surfacename)
    updateplayerGUI(surfacename)
end)

function renamesurface(event)
    -- OLDTODO This needs to account for the new name being substituted already. As it is the new name's sub value gets overwritten by the old one. DONOTFIX: Honestly ok with that since it's a different surface.
    local newname = event.new_name
    local oldname = event.old_name
    -- Move the surface table, which includes all our force tables.
    global.astmine.surfaces[newname] = global.astmine.surfaces[oldname]
    global.astmine.surfaces[oldname] = nil
    -- If the name is in the subtable remove the old and add the new with the old target. If it's not both are nil now.
    global.astmine.substitute[newname] = global.substitute[oldname]
    global.astmine.substitute[oldname] = nil
    -- If the name is in the subtable as a target, update to the new info
    for surfname, subname in pairs(global.substitute) do
        if subname == oldname then
            global.substitutes[surfname] = newname
        end
    end
end

script.on_event(defines.events.on_surface_renamed,renamesurface) -- Need to update anything using the old name

-- **************************
-- Rocket launching code
-- **************************
-- This checks if an upgrade is possible. It requires a station in orbit, an upgrade module in orbit, and a resource with enough rockets of appropriate level to upgrade. This can be triggered by launching an upgrade OR a mining module OR the upgrade station module. NOTE: THIS NO LONGER RUNS AT ALL. We now use manual triggering by the player in minerupgrade.
function checkupgrade(forcetable, force, orename)
    --game.print(force.name .. " : " .. orename)
    -- If no upgrade station and no orename, user just sent up an upgrade - warn them they need the station.
    if forcetable.upgrades["station"] == nil then
        -- No upgrade station in orbit, force can not upgrade their rockets. If orename is nil they sent an upgrade, warn them it can't be used yet.
        force.print({"astmine-no-station"})
        return
    end
    -- See if there's any upgrades waiting. If not, do nothing.
    --log("checkupgrade " .. serpent.block(forcetable))
    if forcetable.upgrades[5] == 0 and forcetable.upgrades[25] == 0 then
        return
    end
    -- If we were provided a resource name, check that only.
    local orestocheck = {orename = forcetable.orbiting[orename]}
    if orename == nil then
        orestocheck = forcetable.orbiting
    end
    local updategui = false
    --log("checkupgrade2 " .. serpent.block(orestocheck))
    for name, value in pairs(orestocheck) do
        --log(name .. " : " .. serpent.block(value))
        -- value = {1=,5=,25=}
        if value[1] > 2 and forcetable.upgrades[5] > 0 then
            value[1] = value[1] - 3
            forcetable.upgrades[5] = forcetable.upgrades[5] - 1
            value[5] = value[5] + 1
            updategui = true
        end
        -- By running them in this order we allow for using both upgrades at once; if they have 3 level 1, 2 level 5, and both upgrade modules in orbit they end with 1 level 25.
        if value[5] > 2 and forcetable.upgrades[25] > 0 then
            value[5] = value[5] - 3
            forcetable.upgrades[25] = forcetable.upgrades[25] - 1
            value[25] = value[25] + 1
            updategui = true
        end
    end
    -- If any of upgrades happened, update player GUIs to account for it.
    if updategui then updateplayerGUI() end
end

-- Add <count> orbiting miners of <oretype> resource.
function addlevel(orbtable, oretype, count)
    oretable = orbtable[oretype]
    if oretable == nil then
        orbtable[oretype] = {[1] = 0, [5] = 0, [25] = 0}
        oretable = orbtable[oretype]
    end
    -- TODO - make this unupgrade if necessary to remove the level, since it may have been used in an upgrade. Alternatively
    -- allow it to go negative in a section, just not negative overall.
    -- We don't allow less than 0. Count may be negative.
    local newlevel = (oretable[1] or 0) + count
    oretable[1] = math.max(newlevel,0)
    -- Return the new level of miners (used to check if upgrades are possible by rocklaunch)
    return newlevel
end

-- Prints an error message and refunds rocket parts if a launch wasn't valid for the surface - invalid surface, resource doesn't exist on the surface, (MAYBE upgrade module already present), etc
function badlaunch(force, silo, message)
    -- We're going to print an error and attempt to refund the rocket parts.
    force.print(message)
    if silo and silo.valid then
        -- Currently this has an issue where the silo won't attempt to build another rocket without another part being built. I've reported it to the factorio devs. SHOULD BE FIXED in 1.1.69.
        silo.rocket_parts = silo.rocket_parts + silo.prototype.rocket_parts_required
        force.print({"astmine-refund-parts"}) -- Tell them we've refunded parts
    end
end

-- Are all the items in this rocket Asteroid Mining items?
function asteroiditem(items)
    local isours = true
    -- There's USUALLY only one item in a rocket but possibly more.
    for itemname, count in pairs(items) do
        local i, j, k, l
        i, j = string.find(itemname, "astmine%-advmodule%-")
        k, l = string.find(itemname, "astmine%-upgrade%-")
        if (i == 1) or (k == 1) then 
            
        elseif itemname == "astmine-mixed" then
            
        elseif itemname == "astmine-upgrade-module" then
            
        else
            isours = false -- this is not one of our Advanced Mining items
        end
    end
    --game.print("Asteroid Item?: " .. tostring(isours))
    return isours
end

-- See if what launched was one of our items, and if it was perform appropriate steps.
function rocklaunch(event)
    local rocket = event.rocket
    local surfname = get_sub_surface(rocket.surface.name) -- Rocket always exists, silo may not.
    local inv = rocket.get_inventory(defines.inventory.rocket) -- Get this now since we may need it in the next check
    local items = inv.get_contents() -- Same here.
    --game.print("Rocklaunch items: " .. tostring(inv.is_empty()))
    if inv.is_empty() then
        return -- No items were launched, so we don't need to do a thing.
    end
    --game.print("Surf: " .. surfname)
    if surfname == "" and asteroiditem(items) then -- Not a valid surface to mine with, bad launch.
        badlaunch(rocket.force, event.rocket_silo, {"astmine-not-valid-surface"})
        return
    end 
    --game.print(serpent.block(inv.get_contents()))
    local updategui = false
    for itemname, count in pairs(items) do -- There COULD be more than one item in a rocket via modding?
        -- Our resource specific modules all start with 'astmine-module-'
        local i, j = string.find(itemname, "astmine%-advmodule%-")
        if i == 1 then -- We found the string, it's our module
            modtype = string.sub(itemname,j+1)
            --game.print('asteroid miner: ' .. modtype)
            -- Does the resource this module is for exist on this surface?
            surftable = global.astmine.surfaces[surfname]
            if surftable.resources[modtype] == nil then -- if not, it's a bad launch
                badlaunch(rocket.force, event.rocket_silo, {"astmine-not-valid-resource"})
                return
            end
            -- Ensure we've got this force and surface initialized, and get the surface info for this force
            local forcetable = init_force(rocket.force.name, surfname)
            --game.print(serpent.block(forcetable))
            if not forcetable then
                -- This surface wasn't inited before, and now that we have it's invalid. Do the badlaunch.
                badlaunch(rocket.force, event.rocket_silo, {"astmine-not-valid-surface"})
                return
            end
            -- Increase the orbiting miner count for the resource by count of miners - 1 for our types, mods can add others
            -- We no longer do this. Upgrades are done manually by the player using the GUI.
            -- if addlevel(forcetable.orbiting,modtype, count) == 3 then
                -- checkupgrade(forcetable, rocket.force, modtype) -- If the count is 3, see if we can upgrade it with an upgrade module already in orbit.
            -- end
            addlevel(forcetable.orbiting,modtype, count)
            -- game.print(serpent.block(forcetable))
            updategui = true -- We need to update player GUIs.
        end
        if itemname == "astmine-mixed" then -- Mixed miner module, slightly special handling. This is always valid if the surface isn't subbed to "", though there may still be 0 resources.
            local forcetable = init_force(rocket.force.name, surfname)
            --game.print(serpent.block(forcetable))
            -- Increase the orbiting miner count for the resource by count of miners - currently always 1
            -- We no longer do this. Upgrades are done manually by the player using the GUI.
            -- if addlevel(forcetable.orbiting,itemname, count) == 3 then
                -- checkupgrade(forcetable, rocket.force, itemname) -- If the count is 3, see if we can upgrade it with an upgrade module already in orbit.
            -- end
            addlevel(forcetable.orbiting,itemname, count)
            -- game.print(serpent.block(forcetable))
            updategui = true -- We need to update player GUIs.
        end
        -- Upgrade modules start with astmin-upgrade-
        local i, j = string.find(itemname, "astmine%-upgrade%-")
        --log(itemname)
        if i == 1 then 
            modtype = string.sub(itemname,j+1)
            --log(modtype)
            if modtype == '5' then
                local forcetable = init_force(rocket.force.name, surfname)
                forcetable.upgrades[5] = forcetable.upgrades[5] + 1
                --checkupgrade(forcetable, rocket.force)
            elseif modtype == '25' then
                local forcetable = init_force(rocket.force.name, surfname)
                forcetable.upgrades[25] = forcetable.upgrades[25] + 1
                --checkupgrade(forcetable, rocket.force)            
            end
            updategui = true -- We need to update player GUIs.
        end
        if itemname == "astmine-upgrade-module" then
            local forcetable = init_force(rocket.force.name, surfname)
            -- Add 1, which means it's no longer nil. Later we might require multiple upgrade station levels.
            forcetable.upgrades["station"] = (forcetable.upgrades["station"] or 0) + 1
            -- Since we CAN upgrade stuff now, go ahead and check in case they sent the upgrade first.
            -- We no longer do this. Upgrades are done manually by the player using the GUI.
            --checkupgrade(forcetable, rocket.force)
            updategui = true -- We need to update player GUIs.
        end
    end
    -- If any of our modules were launched, update player GUIs to account for it.
    if updategui then updateplayerGUI() end
end

-- Event for when a rocket has been launched, we need to see what was on it.
script.on_event(defines.events.on_rocket_launched,rocklaunch)

-- **************************
-- on_tick control code. Generates and spawns resources.
-- **************************
-- Gets the requested or random ore and amount from the forces available ores.
function getore(entcontrol, available, resamount)
    -- Check if entity only wants one ore type, if so return that from table.
    local sig = entcontrol.get_signal(1)
    local orename
    if sig.signal == nil then -- No signal has been set, get random ore
        -- Get a random ore from our list.
        local ores = {}
        for k in pairs(available) do -- Gather our ore names if they have at least 1 available.
            if available[k] > 0 then
                table.insert(ores,k)
            end
        end
        -- game.print(serpent.block(ores))
        if #ores == 0 then -- No ores left in available.
            return nil, nil -- nil amount breaks the spawnresource loop for the surface.
        end
        orename = ores[math.random(#ores)] -- Get a random name from the list of ores with at least 1 available.
    else
        orename = sig.signal.name
        avail = available[orename]
        if avail == nil then -- No ore of that type available
            return nil, 0 -- nil as the first return indicates this machine has no ores available.
        end
    end
    -- game.print("Available - " .. avail)
    -- Calculate how much ore to add - min of setting that sets the max, or how much is available.
    -- game.print("Name:" .. orename)
    transfer = math.min(resamount, available[orename])
    if transfer == 0 then
        return nil, nil -- There's no ore left to transfer
    end
    -- game.print(orename .. " name::transfer " .. transfer)
    return orename, transfer
end

-- Iterates all the am_target and distributes the forces surfaces .available ores to them
-- TODO I might want to copy the code I made for Teleportation Redux to dynamically adjust the update rate based on how many targets there are. If I did that and included a setting for the rate, between that and the setting for resource size it'd be very easy to mid-game adjust numbers. Or maybe just a setting for "Update Multiplier" that muliplies both seconds/update and resamount. Current method allows first targets to hog all the resources, until it's full. NOTE this would require using the saved list of targets method rather than the find method.
function spawnresource()
    local resamount = settings.global["astmine-resamount"].value -- I should move this to getore - it's the ONLY place it's used!
    -- Iterate over our table of forces. Most cases, this will be nothing, as no one has sent anything up, or just the "player" force.
    for surfacename, asurftable in pairs(global.astmine.surfaces) do
        local surftable = asurftable
        --game.print(surfacename .. " : " .. serpent.block(surftable))
        local subname = get_sub_surface(surfacename)
        if subname == "" then -- Surface has been disallowed from Asteroid Mining. Do nothing.
            goto nosurf
        end
        local surface = game.get_surface(surfacename)
        if surface == nil then -- Surface no longer exists, possibly deleted.
            -- Eventually I might want to do something with this, like move it to a "deleted surfaces" table and move it back if the surface is recreated. For now, nothing.
            goto nosurf
        end
        -- Surface is subbed. We need to have it use a different table.
        if subname then
            surftable = global.astmine.surfaces[subname]
        end
        -- Iterate every surface that we've stored Asteroid Mining data for
        -- If no surfaces have been initialized yet for this force, it should skip.
        for forcename, forcetable in pairs(surftable.forces) do
            --game.print("Force:" .. forcename)
            -- We need this table several times so lets nab a local reference
            local avail = forcetable.available
            -- Find all the asteroid mining targets on the map for this force.
            local targets = surface.find_entities_filtered({name = "astmine-target", force = forcename})
            --game.print(forcename .. " targets: " .. #targets)
            for n, target in pairs(targets) do -- If no targets found this does nothing
                local entcontrol = target.get_control_behavior() -- ConstantCombinatorControl for this target
                if entcontrol.enabled == false then -- Disabled, so don't send anything.
                    goto continue
                end
                -- orename is the name of the ore, transfer is the amount.
                orename, transfer = getore(entcontrol, avail, resamount) -- Gets the ore and amount we're sending down.
                if transfer == nil then -- nil transfer means there is no ore in .available
                    break -- Surface has no ores to send, stop the loop.
                end
                if orename == nil or transfer == 0 then -- Nothing to do here
                    goto continue
                end
                local respos = surface.find_non_colliding_position(orename,target.position, 5, 1, true)
                --game.print("Found POS")
                --game.print(respos)
                if respos then -- Nothing to do if there isn't a valid position.
                    local newent = surface.create_entity({name=orename, position = respos,amount = transfer})
                    -- Remove created ore from the available pool
                    avail[orename] = avail[orename] - transfer
                end
                ::continue:: -- Target is off or no ore to send.
            end
            -- Surface is done outputting ore, lets debug check it
            --game.print("Final Avail:")
            --game.print(serpent.block(avail))
        end
        ::nosurf:: -- No surface found or surface invalid for AM, skip
    end
end

function gather_resources()
    -- for each force for each surface, add resources based on what's in .orbiting
    -- can't write this until I figure out HTF the resource weighting works
    --game.print("Gathering!")
    -- Iterate every surface with data - ie those that aren't subbed.
    for surfacename, surftable in pairs(global.astmine.surfaces) do
        if surfacename ~= get_sub_surface(surfacename) then
            -- If the surface was substituted it no longer gets processed here.
            goto skipsurf
        end
        -- Table with resources available on this surface.
        local restable = global.astmine.surfaces[surfacename].resources
        -- If resources isn't defined for that surface, we instead use the default table.
        if restable == nil then
            restable = global.astmine.default
        end
        local totalore = 0 -- Stores total ore rate for this surface, lazy init
        for forcename, forcetable in pairs(surftable.forces) do 
            -- Need to see what's orbiting, then use that to add to available
            --game.print(serpent.block(forcetable.available))
            for orename, leveltable in pairs(forcetable.orbiting) do
                -- Find out our effective mining level for this resource. This should never be 0 or it wouldn't exist.
                local orelevel = leveltable[1] or 0
                orelevel = orelevel + (leveltable[5] or 0) * 5
                orelevel = orelevel + (leveltable[25] or 0) * 25
                --game.print("Orelevel:" .. orelevel)
                -- if orename is 'astmine-mixed' it needs special handling based on surface's settings
                if orename == "astmine-mixed" then
                    -- Iterate over all ores on this surface and add them to the amount available
                    for surfore, values in pairs(restable) do
                        --game.print("Surfore: " .. surfore .. " : Values: " .. serpent.block(values))
                        forcetable.available[surfore] = math.min((forcetable.available[surfore] or 0) + math.min(orelevel * values.rate or 0, values.maxrate or astminemaxrate),astminemaxstored)
                    end
                else -- Resource specific miner handling, just spawns the 1 kind of ore.
                    local oreinfo = restable[orename]
                    if oreinfo ~= nil then -- Ore might not exist for this surface
                        --Modify ore amount for inefficiency of targeted module (since this isn't a mixed module). 
                        local thisrate = oreinfo.specrate or -1 -- -1 means it isn't set, 0 is a valid value
                        -- If the ore has a specrate set we need to use that
                        if thisrate < 0 then -- Otherwise we need to use a rate based on total surface ore rate
                            if totalore == 0 then -- We haven't calculated total ore rate yet, do it now
                                --This way means we only need to do it once per surface.
                                for surfore, values in pairs(restable) do
                                    totalore = totalore + values.rate
                                end
                            end
                            --For base vanilla rates, this is 100 each of 5 ores, at a 0.6 ratio.
                            thisrate = math.floor(totalore * astmineratio) -- Floor value to a whole integer
                        end
                        forcetable.available[orename] = math.min((forcetable.available[orename] or 0) + math.min(orelevel * thisrate, oreinfo.specmax or oreinfo.maxrate or astminemaxrate),astminemaxstored)
                    end
                end
            end
            --game.print(serpent.block(forcetable.available))
        end
        ::skipsurf::
    end
end

function tick_handler()
    --game.print("Astmine tick")
    gather_resources() -- Add in what our orbiters gathered
    spawnresource() -- Then distribute it to our landing sites
    updateplayerGUI() -- Changes were almost certainly made so update player GUIs.
end

-- TODO Put this into a setting. 3600 = Every minute
script.on_nth_tick(3600,tick_handler)