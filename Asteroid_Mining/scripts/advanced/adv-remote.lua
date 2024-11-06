-- Our data layout
-- storage.astmine
    -- .surfaces = {}
        -- .forces = {force.name = table} -- table of forces to hold their mining info
            -- .orbiting = {resource-name = {table of "resource type" = table of {level = count}}}
            -- .available = table of {resource-name = amount} -- tracks how much of each resource is in orbit ready to be dropped
            -- .targets = Not currently used -- possibly use this to keep tracks of what targets there are
            -- .upgrades = table of level = count {[5] = 0, [25] = 0} right now
        -- .resources = {resource-name = ResourceInfo} -- Resources available for the given surface. If not set, it will use the default set of resources. MAYBE: table of {rate (per mixed miner level) = #, maxrate = (maximum per minute from each source regardless of level)}. If amount=0, mixed OR specific miner can't find on this surface. If non-zero a specific miner uses a rate based on a percentage of the total ore per minute for the surface. Maybe allow a specrate value to override with a specific value.
    -- .substitute = {surface.name = surface.name} -- Surface in this table uses the given surface instead for resources. This allows for something like Space Exploration to have a planet and it's orbit use the same resource pool. Setting it to nil removes it and becomes it's own surface, setting it to "" disallows asteroid mining - for something like Factorissimo or underground mods.
    -- .default = {resource-name = ResourceInfo} -- MOSTLY UNUSED, as all real surfaces get their own table, and things generally default to 'nauvis' instead now that multi-surface support is functional.
    -- .research = {tech-name = itemtogive}
    -- .researcht = string with surface name. Used by the research events which default to nauvis if this isn't defined

local myinterfaces = {}

--update-gui - No parameters. Causes the Asteroid Mining GUI to update for any players who have it opened. Should be called once if changing surface info, after all changes have run
--Return: true
myinterfaces["update-gui"] = function(surfacename) -- TESTED GOOD
    updateplayerGUI()
    return true
end

--get-substitute - String name of the surface to get the substitute for.
--Return: the name of the surface to substitute, or nil if not set. A value of "" (an empty string) means the surface has been disabled for use in the mod, generally due to being a special surface (like Factorissimo factory floors).
myinterfaces["get-substitute"] = function(surfacename) -- TESTED GOOD
    return storage.astmine.substitute[tostring(surfacename)]
end

--Function to set a substitute surface. Any asteroid mining functions that attempt to use a substitute surface instead acts on the substituted surface.
--set-substitute - String: name of surface to substitute, String: name of surface to substitute it for (use nil to clear, or "" to disallow surface)
--Return: the name of the substituted surface - this may be different than the one given if that surface has been substituted. Returns false if a parameter is invalid ("" for surface name)
myinterfaces["set-substitute"] = function(surfacename, subsurface) -- TESTED GOOD
    surfacename = tostring(surfacename)
    if surfacename == "" then
        return false
    end
    subsurface = tostring(subsurface)
    --game.print("astmine-sub: " .. surfacename .. " : " .. subsurface)
    if surfacename and subsurface then
        --If the surface is substituted, use that instead.
        local subsubsurface = storage.astmine.substitute[subsurface]
        if subsubsurface ~= nil and subsubsurface ~= "" then
            storage.astmine.substitute[surfacename] = subsubsurface
        else
            storage.astmine.substitute[surfacename] = subsurface
        end
    end
    return storage.astmine.substitute[surfacename]
end


--Remote function to clear all info for surface_name
--clear-surface - String: surface to clear info. This removes ALL info for a surface - the resource table, force orbitals, force available ore, force upgrades in orbit. It does not clear any substitute set for or pointing at the surface. Some actions may lead to the surface table being rebuilt, like launching a rocket. NOTE: Deleted surfaces with info left in this table will work fine. If the surface is going to be recreated later (like SE), leaving it is fine. This is more in the case of remaking an entirely new surface with the old name.
myinterfaces["clear-surface"] = function(surfacename) -- TESTED GOOD
    storage.astmine.surfaces[surfacename] = nil
end

--**** Interfaces for manipulating a surface's ores/rates

--set-baserate - String: name of the surface (pass nil to change the default surface), String: name of the resource entity prototype (e.g. "iron-ore"), integer: rate per level (nil to remove, 0 to not allow in mixed but allow for specific miner), Optional setmax (defaults true. if true will attempt to set the max rate automatically - currently this means based on Space Exploration radius if installed, or no max if not installed)
--Return: true if success, false if failed (surface not found)
myinterfaces["set-baserate"] = function(surfacename, resourcename, baserate, setmax) -- TESTED GOOD
    surfacename = tostring(surfacename)
    surftable = storage.astmine.surfaces[surfacename]
    if surftable == nil then return false end -- Bad surface name, no table exists
    restable = surftable.resources
    if restable == nil then -- This shouldn't happen if surftable exists
        surftable.resources = {}
        restable = surftable.resources
    end
    resourcename = tostring(resourcename)
    baserate = math.floor(baserate)
    if setmax == nil then setmax = true end -- defaults to true
    --game.print("astmine-sub: " .. surfacename .. " : " .. resourcename .. " : " .. baserate)
    local maxrate = nil
    if setmax then
        maxrate = get_radius_max(surfacename, baserate)
    end
    restable[resourcename] = {["rate"] = baserate, ["maxrate"] = maxrate}
    return true
end

--set-maxrate - String: surface to set the max rate on, String: name of the resource entity prototype (e.g. "iron-ore"), integer: maximum rate for this resource (nil to remove max, negative to auto-calc (currently this means using the Space Exploration radius of the surface if installed)). If the ore did not exist on this surface, and maxrate is not nil, it will now exist with a rate of 0.
--Return: true if succeded. false if failed (due to surface table not existing)
myinterfaces["set-maxrate"] = function(surfacename, resourcename, maxrate) -- TESTED GOOD
    surfacename = tostring(surfacename)
    surftable = storage.astmine.surfaces[surfacename]
    if surftable == nil then return false end -- Bad surface name, no table exists
    restable = surftable.resources
    if restable == nil then -- This shouldn't happen if surftable exists
        surftable.resources = {}
        restable = surftable.resources
    end
    resourcename = tostring(resourcename)
    local oreinfo = restable[resourcename]
    if oreinfo == nil then
        if maxrate == nil then return true end
        restable[resourcename] = {["rate"] = 0,}
        oreinfo = restable[resourcename]
    end
    --game.print("astmine-sub: " .. surfacename .. " : " .. resourcename .. " : " .. maxrate)
    if maxrate < 0 then
        maxrate = get_radius_max(surfacename, oreinfo["rate"] or 0)
    end
    oreinfo["maxrate"] = maxrate
end

--clear-resources - String: surface to clear the resource table of. Surface will no longer provide resources and may get set as disabled if certain checks run. NOTE: If your desire is to make the surface invalid for asteroid mining, use set-substitute with a value of "" instead. This function is more to build a custom set of resources for a surface.
--Return: true
myinterfaces["clear-resources"] = function(surfacename) -- TESTED GOOD
    storage.astmine.surfaces[surfacename].resources = {}
    return true
end

--Set a surfaces resources, optionally based on another surface
--set-resources - String: surface to build the table for, Optional String: surface to use to create the resource table (defaults to the previous surface)
--Return: true if succeeded, else false (second surface is invalid or does not have map_gen_settings.autoplace_controls, factorio log should have a message with details)
myinterfaces["set-resources"] = function(surfacename, ressurfacename) -- TESTED GOOD
    return make_resource_table(surfacename, ressurfacename)
end


--**** Interfaces to manipulate miner levels (by tech research, directly, etc)

--add-techforminer - String: name of technology prototype that grants a free miner, Optional String: name of the resource prototype the miner is of. If not given it gives a mixed miner.
--Return: true
myinterfaces["add-techforminer"] = function(techname, resourcename) -- TESTED GOOD
    techname = tostring(techname)
    resourcename = tostring((resourcename or "astmine-mixed"))
    storage.astmine.research[techname] = resourcename
    --game.print("Setting " .. techname .. " : " .. resourcename)
    return true
end

--TODO add-techsforminer - Array of Strings: names of technology prototypes to grant free miner, Optional String: name of the resource prototype the miner is of. If not given it gives a mixed miner.

--set-techsurface - String: name of the surface to give any free miners from technology research to. Default is nauvis, which should be fine unless that surface is not used at all.
--Return: true
myinterfaces["set-techsurface"] = function(surfacename) -- TESTED GOOD
    storage.astmine.researcht = surfacename
    return true
end

--function addlevel(orbtable, oretype, count)
--add-miner - String: name of the surface to give the miner, String: name of the force to give the miner (eg "player"), String: name of the resource to give. Pass nil to give a mixed miner.
--Return: true if succeded, false if failed (negative count and not enough level 1 miners to remove)
myinterfaces["add-miner"] = function(surfacename, forcename, resourcename, count) -- TESTED GOOD
    surfacename = get_sub_surface(tostring(surfacename))
    local forcetable = init_force(tostring(forcename), surfacename)
    return addlevel(forcetable.orbiting, (resourcename or "astmine-mixed"), (count or 1)) >= 0
end

-- Will add all remote interfaces defined above
remote.add_interface("asteroid-mining", myinterfaces)