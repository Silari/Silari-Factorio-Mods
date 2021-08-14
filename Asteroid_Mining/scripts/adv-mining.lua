--Easiest way to make the asteroid target entity is to make it a constant combinator. If it's unset, nothing gets sent. Otherwise use the signals to determine that maximum amount of that resource around, and/or any resource with a signal gets a 1/X chance to be sent. 
--For now it's a simple 'if it's off, send nothing. If signal is set, try to send that resource or nothing if it's not available. Otherwise, send a random available resource'

-- OLD METHOD, may revisit efficiency research or something. Math works out easier to just use lvl<multiplier> though.
--upgrade mechanics: needs 3 lvl1 miners, send up a triangular configuration module which upgrades them to a 1 lvl2 miner which mines at x5 speed. Also needs an Orbital Upgrade Station module sent up on a rocket, which is what performs the modifications to weld the three together. Sending 5 lvl1 mines at the same speed as 3 + TCM + OUS, but 10 rockets sending lvl1s is slower than 10 sending 7 lvl1, 2 TCM, and 1 MUS.
--For resource specific miners the gain is better: they mine at 50% speed compared to mixed miners at lvl1, but lvl2 is ALSO 70% speed of lvl2 mixed. Level 3 probably 90%. Probably uses a different TCM - add in radars or something similar to indicate it's enhanced sensor package that lets it locate specific resources better. Could also have research to improve the efficiency as well.

--Possibly some mechanic for miners to locate derilect miners in space with the ability to reactivate them via research? Allowing a research to add new miners ("nothing" effect type and an on_researched event) would allow a seablock style game to add resource production without yet having the rocket silo. Eff research above would also help, on top of the normal bonuses mining prod would add.

-- Some conventions I need to try and hold to:
-- ALWAYSALWAYSALWAYS check for substitutes!
-- surfname = get_sub_surface(surfacename)
-- surftable = global.astmine.surfaces[surfname]
-- forcetable = global.astmine.surfaces[surfname].forces[forcename]
-- restable = global.astmine.surfaces[surfname].resources

-- Our data layout
-- global.astmine
    -- .surfaces = {}
        -- .forces = {force.name = table} -- table of forces to hold their mining info
            -- .orbiting = {surface.name = table} -- table of "resource type" = table of {level = count}
            -- .available = table of {resource-name = amount} -- tracks how much of each resource is in orbit ready to be dropped
            -- .targets = something -- possibly use this to keep tracks of what targets there are
            -- .upgrades = table of level = count {[5] = 0, [25] = 0} right now
        -- .resources = {resource-name = ResourceInfo} -- Resources available for the given surface. If not set, it will use the default set of resources. Unsure exactly if I want flat percentages or weighting or what quite yet. MAYBE: table of {rate (per mixed miner level) = #, maxrate = (maximum per minute from each source regardless of level)}. If amount=0, mixed miner can't find but specific miner can - specific miner uses a rate based on the total amount of ore a mixed miner would get. Maybe allow specrate to override with a specific value.
    -- .substitute = {surface.name = surface.name} -- Surface in this table uses the given surface instead for resources. This allows for something like Space Exploration to have a planet and it's orbit use the same resource pool. Setting it to nil removes it and becomes it's own surface, setting it to "" disallows asteroid mining - for something like Factorissimo or underground mods.
    -- .default = {resource-name = ResourceInfo}
    -- .research = {tech-name = itemtogive}
    -- .researcht = string with surface name. Used by the research events which default to nauvis if this isn't defined

-- Data layout of resource amount is table of ResourceInfo
-- {rate = rate obtained per level, maxrate = maximum generated per minute - if not defined defaults to astminmaxrate, specrate = rate for specialized miner - if not defined defaults to rate based on combined rate of all ores on surface, specmax = maximum per minute for specialized miners - if not defined defaults to maxrate}

--Some constants we use here for easy changing
astminmaxrate = 2000000 -- Default amount of maximum ore per tick, if none set on the ore.
astminmaxstored = 2000000000 -- No ore can have more than this stored.

astminratio = 0.6

astminbaserate = 100 -- Base rate to use for ore gathering.

--Useful functions to do things
function add_resource(resourcename, surfacename)
    -- Interface function to add a resource to the given surface, or the default if none given.
end

function add_item(itemname, surfacename)
    --Function to add an item to the given surface, or the default if none given.
    --This needs to make a resource that gives the item, so I need to move this into a script in data stage instead, so it can later be added using add_resource. That means surface_name is useless.
end

function get_sub_surface(surfacename)
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

--Ensures that globals were initialized. Called on init and by on_configuration_changed
function init_mining()
    log("Asteroid Mining advanced mining init")
    if not global.astmine then -- Holds asteroid mining data
      global.astmine = {}
    end
    if not global.astmine.surface then -- Holds per surface data, including force info for the surface
        -- nauvis is initialized here since the game doesn't call the surface_created event for it
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
        -- Skip anything that has a substitute.
        if global.astmine.substitute[name] == nil then
            -- Skip any surface we already have a table for.
            if global.astmine.surfaces[name] == nil then
                global.astmine.surfaces[name] = {}
                global.astmine.surfaces[name]["forces"] = {}
            end
        end
    end
    if not global.astmine.research then
        global.astmine.research = {}
    end
end

--Command to get information about the current surface, based on using player's force.
function surfaceinfo(event)
    --log(serpent.block(global.astmine))
    local force, surface, player, message
    message = "An error occurred, no valid return found." -- Should be replaced so seeing it means something went wrong.
    if event.player_index then
        player = game.players[event.player_index]
        force = player.force
        surface = player.surface
    else -- If used from server console
        force = game.forces['player']
        surface = game.surfaces['nauvis']
    end
    local surfname = get_sub_surface(surface.name)
    -- surfname should always point to a valid surface table.
    --log("surfaceinfo: " .. surfname .. " : " .. force.name)
    local surftable = global.astmine.surfaces[surfname]
    --log(serpent.block(surftable))
    local forcetable = surftable.forces[force.name]
    --log("post forcetable" .. serpent.block(forcetable))
    if forcetable then
        message = force.name .. "-" .. surface.name .. ": "
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
        message = "Force '" .. force.name .. "' does not have any information for " .. surfname .. "."
    end
    -- Grab the table that lists resources for this surface. It may be in the surftable
    local restable = global.astmine.surfaces[surface.name].resources
    -- If resources isn't defined for that surface, we instead use the default table.
    if restable == nil then
        restable = global.astmine.default
    end
    local resources = ""
    for name, value in pairs(restable) do
        resources = resources .. "\n    " .. name .. " Base Rate: " .. value["rate"] .. " per minute"
    end
    if resources then
        message = message .. "\nSurface Resources:" .. resources
    else
        message = message .. "\nUnable to find resources for surface!"
    end
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
function init_force(forcename, surfacename)
    surfname = get_sub_surface(surfacename)
    --game.print("Surfname: " .. surfname)
    surftable = global.astmine.surfaces[surfname]
    --game.print("init force" .. serpent.block(surftable))
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

-- Builds the list of resources for the given surface, or the default table based on nauvis if none given.
function make_resource_table(surfacename)
    -- This should attempt to build the resources for this surface from the map generation settings. 
    -- Get the table for this surface and make sure it's initialized if needed
    local restable
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
    local surface = game.surfaces[surfacename]
    if surface == nil then
        log("Invalid surface! " .. surfacename)
        return
    end
    --log("Making resource table!")
    local mapgen = surface.map_gen_settings.autoplace_controls
    --log(serpent.block(mapgen))
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
                local miningrate = astminbaserate -- Default rate to use for any ore.
                if resource.autoplace_specification then -- Autoplace specification exists, try to match amounts with commonality of the resource
                    -- TODO Finish this
                    --log("Control name: " .. resource.autoplace_specification.control)
                    local rescontrols = mapgen[resource.autoplace_specification.control]
                    --log(serpent.block(rescontrols))
                    if rescontrols ~= nil then
                        -- We multiply our base mining rate with the values for frequency, richness, and size.
                        miningrate = miningrate * rescontrols.frequency
                        miningrate = miningrate * rescontrols.richness
                        miningrate = miningrate * rescontrols.size
                    end
                end
                restable[name] = {["rate"] = miningrate}
                --log(serpent.block(restable[name]))
            end
        end
    end
    -- log(serpent.block(restable))
end

-- **************************
-- Events section
-- **************************

script.on_init(function()
  init_mining()
  commands.add_command("asteroid","asteroidcommand",surfaceinfo)
end)

script.on_load(function()
  commands.add_command("asteroid","asteroidcommand",surfaceinfo)
end)


--Migrations
function on_changed()
    --Updates the recipes when mod configurations change. Ensures recipes on rocket silo tech are enabled/disabled as they should be.
    reset_recipes() -- in scripts/recipes.lua
    --Ensures global needed for asteroid mining are created.
    init_mining()
end
script.on_configuration_changed(on_changed)

-- script.on_event(ALL THE BUILDING) -- We need to register our am-target when it gets built. If we stop using find_entities_filtered, that is.
-- script.on_event(defines.events.on_surface_deleted,nil) -- Remove any stored references to the surface. Biggest issue would be if one is set as a substitute target - need to loop over that table. Might not even want to do that if we use surface.name, so if two surfaces are shared we leave the shared name in use for the others. In that case surface_cleared SHOULD remove all the info though.
-- script.on_event(defines.events.on_surface_cleared,nil) -- Probably do nothing for this, shouldn't be used much. If we do it'd just be the same as deleted, except then reinit like creating. CHANGED: This should clear the info, as we don't do that when the surface is deleted.
-- on_force_created -- make a table for the force? No we lazily init the table when needed.
-- on_forces_merged/on_forces_merging -- probably use the second one JIC as it's slightly earlier and old force still exists at that time. Nothing we do is really affected by the merging, we just need to add the .orbiting and .resources for the two forces.

function techdone(event)
    --game.print(serpent.block(event) .. " : techname : " .. event.research.name)
    -- Tech result is what kind of miner to give
    local techresult = global.astmine.research[event.research.name]
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
    local surfacename = get_sub_surface(surface.name)
    if not global.astmine.surfaces[surfacename] then
        global.astmine.surfaces[surfacename] = {forces = {}} 
    end
end)

function renamesurface(event)
    -- TODO This needs to account for the new name being substituted already.
    local newname = event.new_name
    local oldname = event.old_name
    -- Move the surface table, which includes all our force tables
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
function checkupgrade(forcetable, force, orename)
    -- TODO Add check for orbital upgrade station
    -- If no upgrade station and no orename, user just sent up an upgrade - warn them they need the station.
    if forcetable.upgrades["station"] == nil then
        -- No upgrade station in orbit, force can not upgrade their rockets. If orename is nil they sent an upgrade, warn them it can't be used yet.
        if orename == nil then
            force.print({"astmine-no-station"})
        end
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
    --log("checkupgrade2 " .. serpent.block(orestocheck))
    for name, value in pairs(orestocheck) do
        --log(name .. " : " .. serpent.block(value))
        -- value = {1=,5=,25=}
        if value[1] > 2 and forcetable.upgrades[5] > 0 then
            value[1] = value[1] - 3
            forcetable.upgrades[5] = forcetable.upgrades[5] - 1
            value[5] = value[5] + 1
        end
        if value[5] > 2 and forcetable.upgrades[25] > 0 then
            value[5] = value[5] - 3
            forcetable.upgrades[25] = forcetable.upgrades[25] - 1
            value[25] = value[25] + 1
        end
    end
end

function addlevel(orbtable, oretype, count)
    -- Add <count> orbiting miners of <oretype> resource.
    oretable = orbtable[oretype]
    if oretable == nil then
        orbtable[oretype] = {[1] = 0, [5] = 0, [25] = 0}
        oretable = orbtable[oretype]
    end
    -- We don't allow less than 0.
    oretable[1] = math.max((oretable[1] or 0) + count,0)
    return oretable[1]
end

-- See if what launched was one of our items
function rocklaunch(event)
    local rocket = event.rocket
    local surf = get_sub_surface(rocket.surface.name) -- Rocket always exists, silo may not.
    --game.print("Surf: " .. surf)
    local inv = rocket.get_inventory(defines.inventory.rocket)
    --game.print(serpent.block(inv.get_contents()))
    for itemname, count in pairs(inv.get_contents()) do -- There COULD be more than one item in a rocket via modding?
        -- Our modules all start with 'astmin-module-'
        i, j = string.find(itemname, "astmin%-advmodule%-")
        if i == 1 then 
            modtype = string.sub(itemname,j+1)
            --game.print('asteroid miner: ' .. modtype)
            -- Do we HAVE a resource called what it's expecting?
            -- TODO: Add this check, skipped for now - really this shouldn't be needed since we're gonna MAKE them based on a resource.
            -- Ensure we've got this force and surface initialized, and get the surface info for this force
            local forcetable = init_force(rocket.force.name, surf)
            --game.print(serpent.block(forcetable))
            -- Increase the orbiting miner count for the resource by count of miners - 1 for our types, mods can add others
            if addlevel(forcetable.orbiting,modtype, count) == 3 then
                checkupgrade(forcetable, rocket.force, modtype) -- If the count is 3, see if we can upgrade it with an upgrade module already in orbit.
            end
            -- game.print(serpent.block(forcetable))
        end
        if itemname == "astmin-mixed" then -- Mixed miner module, slightly special handling
            local forcetable = init_force(rocket.force.name, surf)
            --game.print(serpent.block(forcetable))
            -- Increase the orbiting miner count for the resource by count of miners - currently always 1
            if addlevel(forcetable.orbiting,itemname, count) == 3 then
                checkupgrade(forcetable, rocket.force, itemname) -- If the count is 3, see if we can upgrade it with an upgrade module already in orbit.
            end
            -- game.print(serpent.block(forcetable))
        end
        -- Upgrade modules start with astmin-upgrade-
        i, j = string.find(itemname, "astmin%-upgrade%-")
        --log(itemname)
        if i == 1 then 
            modtype = string.sub(itemname,j+1)
            --log(modtype)
            if modtype == '5' then
                local forcetable = init_force(rocket.force.name, surf)
                forcetable.upgrades[5] = forcetable.upgrades[5] + 1
                checkupgrade(forcetable, rocket.force)
            elseif modtype == '25' then
                local forcetable = init_force(rocket.force.name, surf)
                forcetable.upgrades[25] = forcetable.upgrades[25] + 1
                checkupgrade(forcetable, rocket.force)            
            end
        end
        if itemname == "astmin-upgrade-module" then
            local forcetable = init_force(rocket.force.name, surf)
            -- Set it to 1, which means it's no longer nil. Later we might have multiple upgrade station levels.
            forcetable.upgrades["station"] = 1
            -- Since we CAN upgrade stuff now, go ahead and check in case they sent the upgrade first.
            checkupgrade(forcetable, rocket.force)
        end
    end
end

-- Event for when a rocket has been launched, we need to see what was on it.
script.on_event(defines.events.on_rocket_launched,rocklaunch)

-- **************************
-- on_tick control code
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
    local resamount = settings.global["astmine-resamount"].value
    -- Iterate over our table of forces. Most cases, this will be nothing, as no one has sent anything up, or just the "player" force.
    for surfacename, surftable in pairs(global.astmine.surfaces) do
        -- game.print(surfacename .. " : " .. serpent.block(surftable))
        local surface = game.get_surface(surfacename)
        if surface == nil then -- Surface no longer exists, possibly deleted.
            -- Eventually I might want to do something with this, like move it to a "deleted surfaces" table and move it back if the surface is recreated. For now, nothing.
            goto nosurf
        end
        -- TODO Two issues here - one is that we should redo targets to only need to search ONCE per surface, with a lazy init so it only searches if there's actually a force in the forces subtable - should be done
        -- SECOND we don't actually check the force of the targets. Maybe a function that returns a list of what targets match our forcename.
        local targets
        -- Iterate every surface that we've stored Asteroid Mining data for
        -- If no surfaces have been initialized yet for this force, it should skip.
        for forcename, forcetable in pairs(surftable.forces) do
            --game.print("Force:" .. forcename)
            -- We need this table several times so lets nab a local reference
            local avail = surftable.available
            -- Find all the asteroid mining targets on the map.
            if not targets then
                targets = surface.find_entities_filtered({name = "astmine-target"})
            end
            -- game.print("Targets: " .. #targets)
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
                --game.print(respos)
                if respos then -- Nothing to do if there isn't a valid position.
                    local newent = surface.create_entity({name=orename, position = respos,amount = transfer})
                    -- Remove created ore from the available pool
                    surftable.available[orename] = surftable.available[orename] - transfer
                end
                ::continue::
            end
            -- Surface is done outputting ore, lets debug check it
            -- game.print(serpent.block(surftable.available))
        end
        ::nosurf:: -- No surface found, skip
    end
end

function gather_resources()
    -- for each force for each surface, add resources based on what's in .orbiting
    -- can't write this until I figure out HTF the resource weighting works
    --game.print("Gathering!")
    -- Iterate every surface with data - ie those that aren't subbed.
    for surfacename, surftable in pairs(global.astmine.surfaces) do
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
                -- if orename is 'astmin-mixed' it needs special handling based on surface's settings
                if orename == "astmin-mixed" then
                    --Iterate over all ores on this surface and add them to the amount available
                    for surfore, values in pairs(restable) do
                        --game.print("Surfore: " .. surfore .. " : Values: " .. serpent.block(values))
                        forcetable.available[surfore] = math.min((forcetable.available[surfore] or 0) + math.min(orelevel * values.rate, values.maxrate or astminmaxrate),astminmaxstored)
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
                            --For base rates, this is 60 per ore, or 300 total
                            thisrate = math.floor(totalore * astminratio) -- Floor value to a whole integer
                        end
                        forcetable.available[orename] = math.min((forcetable.available[orename] or 0) + math.min(orelevel * thisrate, oreinfo.specmax or oreinfo.maxrate or astminmaxrate),astminmaxstored)
                    end
                end
            end
            --game.print(serpent.block(forcetable.available))
        end
    end
end

function tick_handler()
    --game.print("Astmin tick")
    gather_resources() -- Add in what our orbiters gathered
    spawnresource() -- Then distribute it to our landing sites
end

-- TODO adjust this timing. 3600 = Every minute
script.on_nth_tick(3600,tick_handler)