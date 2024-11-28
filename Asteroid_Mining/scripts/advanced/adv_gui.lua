local mod_gui = require("mod-gui")

function on_player_created( event ) --Add GUI button
    local player = game.players[event.player_index]
    local modbut = mod_gui.get_button_flow(player)
    if settings.startup["astmine-makerockets"].value == true then -- Advanced mode, ensure button exists.
        if not modbut["AMBTN"] then
            modbut.add{type="button",caption="AM",name="AMBTN",tooltip={"asteroidminingbutton"},style=mod_gui.button_style}
        end
    else
        if modbut["AMBTN"] then
            modbut["AMBTN"].destroy()
        end
    end    
end
script.on_event(defines.events.on_player_created,on_player_created)

function on_config_change( event )
    --Ensure the mod GUI is on for all players if advanced mode is used, or off for all players if it isn't.
    for _, player in pairs(game.players) do
        -- If the old GUI button exists (not in any released version), destroy it.
        if player.gui.top["AMBTN"] then
            player.gui.top["AMBTN"].destroy()
        end
        local modbut = mod_gui.get_button_flow(player)
        if false or settings.startup["astmine-makerockets"].value == true then -- Advanced mode, ensure button exists.
            if not modbut["AMBTN"] then
                modbut.add{type="button",caption="AM",name="AMBTN",tooltip={"asteroidminingbutton"},style=mod_gui.button_style}
            end
            -- If our GUI is open, close and reopen it. This will reset selected surface and tab but better than crashing due to changes in the GUI structure.
            local gui = player.gui.left
            if gui.astmine then
                gui.astmine.destroy()
                gui.add{type="frame", name="astmine", caption="Asteroid Mining", direction="vertical"}
                makegui(gui.astmine, player)
            end
        else
            if modbut["AMBTN"] then
                modbut["AMBTN"].destroy()
            end
        end
    end
end

--Player clicked the GUI button in the top
function on_gui_click(event)
    if event.element.name == "AMBTN" then
        --log("AM BTN click")
        local player = game.players[event.player_index]
        local gui = player.gui.left
        if gui.astmine then
            -- Asteroid Mining gui is open, close it
            gui.astmine.destroy()
        else
            -- Asteroid Mining gui is closed, show it
            gui.add{type="frame", name="astmine", caption="Asteroid Mining", direction="vertical"}
            makegui(gui.astmine, player)
        end
    elseif event.element.tags.amresname then -- element has our tag, its an upgrade request
        local player = game.players[event.player_index]
        local force = player.force
        -- Surfsel holds the currently selected surface.
        local surfsel = player.gui.left.astmine.surflow.playtabl.surfsel
        local surfacename = surfsel.items[surfsel.selected_index]
        local forcetable = init_force(force.name, surfacename)
        --game.print("Resource name: " .. event.element.tags.amresname)
        minerupgrade(forcetable, player, event.element.tags.amresname)
    end
end
script.on_event(defines.events.on_gui_click, on_gui_click)

--Player changed the selected tab in the GUI, update the info since it's either empty or possibly out of date.
function on_gui_selected_tab_changed(event)
    if event.element.name == "amtabpane" or event.element.name == "surfsel" then
        --log("update")
        local player = game.players[event.player_index]
        local gui = player.gui.left
        if gui.astmine then
            local surfsel = gui.astmine.surflow.playtabl.surfsel
            updatetab(gui.astmine.amtabpane, player, surfsel.items[surfsel.selected_index])
        end
    end
end
--Selected tab changed
script.on_event(defines.events.on_gui_selected_tab_changed, on_gui_selected_tab_changed)
--Selected surface changed
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selected_tab_changed)

function makegui(parent, player) -- Parent (flow or frame) to use as our display
    local surflow = parent.add{type="flow", name="surflow"}
    surflow.add{type="label", caption="Surface: "}
    local playtabl = surflow.add{type="table", name="playtabl", column_count = 3}
    -- Dropdown to select what surface to view. Player's current surface is always included and initially selected.
    local surfsel = playtabl.add{type="drop-down",name="surfsel", items={player.surface.name},selected_index=1}
    playtabl.add{type="label", caption="        "}
    playtabl.add{type="label", caption="  Force: " .. player.force.name}
    local amtabpane = parent.add{type="tabbed-pane",name="amtabpane"}
    local tabone = amtabpane.add{type="tab", name="tabone", caption="Resources"}
    amtabpane.add_tab(tabone, amtabpane.add{type="flow", name="flowone", direction="vertical"})
    local tabtwo = amtabpane.add{type="tab", caption="Space Equipment"}    
    amtabpane.add_tab(tabtwo, amtabpane.add{type="flow", name="flowtwo", direction="vertical"})
    amtabpane.selected_tab_index = 1
    updatesurfsel(surfsel,player.surface.name)
    --log("SEL VALUE " .. surfsel.items[surfsel.selected_index])    
    updatetab(amtabpane, player, surfsel.items[surfsel.selected_index])
end

function updatesurfsel(surfsel,playsurf)
    -- for key, value in pairs(game.surfaces) do
        -- if check_surface(key) then -- Surface is useable (not subbed or blacklisted)
            -- surfsel.add_item(key)
        -- end
    -- end
    -- Iterate over any surface that has surface info - they should be valid if they're in the list.
    for key, value in pairs(storage.astmine.surfaces) do
        if key ~= playsurf then -- Ignore player's current surface - we already have that.
            surfsel.add_item(key)
        end
    end
    --log("SEL VALUES: " .. serpent.block(surfsel.items))
end

function invalid(tabpane)
    local myflow = tabpane.flowone
    if tabpane.selected_tab_index == 2 then
        myflow = tabpane.flowtwo
    end
    myflow.clear()
    myflow.add{type="label", caption={"astmine-not-valid-surface"}}
end

function updatetab(tabpane, player, surfacename)
    -- Update the currently open tab of the GUI. Called periodically and when tab changes.
    --log("astmineupdatetab " .. surfacename)
    local surfname = get_sub_surface(surfacename) -- Name of the surface to use for this surfaces resources (may be substituted)
    --log("astmine " .. surfname)
    if surfname == "" then -- Surface isn't valid for using. Throw in a message to the user about that.
        invalid(tabpane)
        return
    end
    local surftable = storage.astmine.surfaces[surfname] -- Table with the info for this surface.
    --log(serpent.block(surftable))
    if surftable == nil then -- this doesn't usually happen but might if the surface was cleared/deleted since the GUI was opened.
        invalid(tabpane)
        return
    end
    local forcetable = (surftable.forces[player.force.name] or {}) -- Table with force data, may be nil if force not initialized.
    local resources = (forcetable.available or {}) -- Table with forces resources, may be nil if above or nothing launched.
    -- Holds the forces orbital assets for this surface. Empty if none.
    local orbiting = (forcetable.orbiting or {})
    -- log(serpent.block(orbiting))
    -- find open tab index, if 1 resources, if 2 miners+upgrades.
    if tabpane.selected_tab_index == 1 then
        local restable = (surftable.resources or storage.astmine.default) -- holds resources on this surface
        --log(serpent.block(restable))
        -- A secret tool that'll help us later.
        local crates = {}
        -- Contains the sum of all ore base rates on this surface.
        local totalbaserate = 0
        -- Update Resources tab
        local mixvalue = (orbiting["astmine-mixed"] or {})
        -- The resource miner level of the special Mixed Ore. Used later.
        local mixedlevel = (mixvalue[1] or 0) + (mixvalue[5] or 0) * 5 + (mixvalue[25] or 0) * 25
        local myflow = tabpane.flowone
        myflow.clear() -- Clear the tab so we can update it
        local orecounttable = myflow.add{type="table", column_count = 3, vertical_centering=false}--, draw_vertical_lines=true}
        orecounttable.add{type="sprite-button", sprite="item/astmine-mixed", tags={amresname = "astmine-mixed"}}
        local mixdores = orecounttable.add{type="label", caption = "Total Mixed Rate: "}
        local specores = orecounttable.add{type="label", caption = "     Spec. Miner Rate: "}
        -- Add a line for each resource on this surface - maybe a sprite button, rate/m/level, available
        for name, value in pairs(restable) do
            --log(value)
            local maxrate = value.maxrate
            local mytable
            if maxrate then
                mytable = myflow.add{type="table", column_count = 5}
            else
                mytable = myflow.add{type="table", column_count = 4}
            end
            -- The basic rate per minute of this ore
            local baserate = (value.rate or 0)
            totalbaserate = totalbaserate + baserate
            local orbvalue = (orbiting[name] or {})
            -- The resource miner level of this ore.
            local reslevel = (orbvalue[1] or 0) + (orbvalue[5] or 0) * 5 + (orbvalue[25] or 0) * 25
            --game.print(name .. " : " .. reslevel)
            --mytable.add{type="label", caption=name}
            mytable.add{type="sprite-button", sprite="entity/" .. name, tags={amresname = name}}
            mytable.add{type="label", caption="Base Rate: " .. baserate .. "/m  "}
            if maxrate then mytable.add{type="label", caption="Max Rate: " .. maxrate .. "/m "} end
            -- Store the pure ore miner level and the label for the current rate so we can update it later using the calculated totalbaserate. We don't know it yet.
            table.insert(crates,{mixedlevel * baserate,reslevel,mytable.add{type="label", caption=""}})
            mytable.add{type="label", caption="Available: " .. (resources[name] or 0)}
        end
        mixdores.caption = "Mixed Rate: " .. totalbaserate .. "/m"
        specores.caption = "Spec. Miner Rate: " .. (totalbaserate * astmineratio) .. "/m"
        for index, value in ipairs(crates) do
            local purerate = value[2] * totalbaserate * astmineratio
            local finalrate = purerate + value[1]
            --log("TBR " .. totalbaserate .. " MR: " .. value[1] .. " RL: " .. value[2] .. " PR: " .. purerate .. " FR: " .. finalrate)
            value[3].caption = "Current Rate: " .. finalrate .. "/m  "
        end
    else
        -- Update Space Equipment
        local myflow = tabpane.flowtwo
        myflow.clear()
        -- Nothing in the force table, so it has nothing
        if next(forcetable) == nil then
            myflow.add{type="label", caption="Force has no orbital assets on this surface."}
            return
        end
        -- Does this force have an orbital upgrade station?
        if forcetable.upgrades["station"] ~= nil then
            myflow.add{type="label", caption="Orbital Upgrade Station deployed."}
        else
            myflow.add{type="label", caption="No Orbital Upgrade Station deployed."}
        end
        -- Add a line for each orbital asset for this force on this surface.
        for name, value in pairs(orbiting) do
            local mytable = myflow.add{type="table", column_count = 4}
            if name == "astmine-mixed" then 
                --name = {"astmine-mixed-ore"}
                mytable.add{type="sprite-button", sprite="item/" .. name, tags={amresname = name}}
            else
                mytable.add{type="sprite-button", sprite="entity/" .. name, tags={amresname = name}}
            end
            --mytable.add{type="label", caption=name}
            mytable.add{type="label", caption="Level 1: " .. (value[1] or 0)}
            mytable.add{type="label", caption="Level 5: " .. (value[5] or 0)}
            mytable.add{type="label", caption="Level 25: " .. (value[25] or 0)}
        end
        if (forcetable.upgrades[5] > 0) or (forcetable.upgrades[25] > 0) then -- At least one upgrade in orbit
            local mytable = myflow.add{type="table", column_count = 3}
            mytable.add{type="label", caption="Upgrades in Orbit: "}
            mytable.add{type="label", caption="Level 5 = " .. (forcetable.upgrades[5] or 0)}
            mytable.add{type="label", caption="Level 25 = " .. (forcetable.upgrades[25] or 0)}
        else
            myflow.add{type="label", caption="No upgrade modules in orbit"}
        end
    end
end

function updateplayerGUI(newsurface)
    for i, player in pairs(game.players) do
        local gui = player.gui.left
        if gui.astmine then
            local surfsel = gui.astmine.surflow.playtabl.surfsel
            if newsurface then -- Given a new surface, just add it to the selection box
                surfsel.add_item(newsurface)
            else
                updatetab(gui.astmine.amtabpane, player, surfsel.items[surfsel.selected_index])
            end
        end
    end
end
