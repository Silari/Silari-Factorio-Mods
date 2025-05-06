-- TODO Possibly change get_source_inv to check for empty inventory and return nil. Could save some time, especially if every inventory is empty since it could skip the whole flow. Would need to adjust error message in that case then.
-- TODO Possibly allow get_source_inv to return multiple inventories for some entities. grab_items supports it fine, just a minor tweak to get_source_inv call to iterate the return for insert if not nil. Not sure it's useful though - generally things have ONE output inventory. Might be useful for furnace, since it could have a burnt_result_inventory we'd want to use.


function on_hotkey( event )
    player = game.players[event.player_index]
    myent = player.selected
    mychar = player.character
    -- Does the player have a character? No logistics if not, so stop.
    if mychar == nil then
        player.print({"ManLog-NoPlayer"})
        return
    end
    -- Nothing selected - do nothing.
    if myent == nil then
        return
    end
    -- Player must be able to reach the given entity.
    if player.can_reach_entity(myent) then
        local entlist = {}
        -- They must be on the same force. Theoretically allied forces should also be fine but we don't allow those.
        if (player.force == myent.force) then
            -- Check if the entity has a compatible inventory.
            entinv = get_source_inv(myent)
            if entinv == nil or (not entinv.valid) then
                -- No good inventory found.
                player.create_local_flying_text{text = {"ManLog-NoInv"}, create_at_cursor = true}
                return
            else
                -- Checks passed, call the function to move items.
                table.insert(entlist, entinv)
                grab_items(player, entlist, mychar)
            end
        else
            -- Uses a vanilla string
            player.create_local_flying_text{text = {"cant-transfer-from-enemy-structures"}, create_at_cursor = true}
        end
    else
        -- Also a vanilla string
        player.create_local_flying_text{text = {"cant-reach"}, create_at_cursor = true}
    end
end

script.on_event("manuallogistics", on_hotkey)

-- Function to get the most appropriate inventory to get items from for the given entity
-- Possible upgrade - make this return a list of inventories as some do have multiple, especially with junk slots now. Though I don't think there's much in a junk slot you'd want to take with this.
function get_source_inv(myent)
    --myent.get_output_inventory() -- might want to use this over the table below but documentation doesn't say WHAT this evaluates to for anything.
    --myent.get_burnt_result_inventory()
    entinv = nil -- Will be filled with the most proper inventory of our entity.
    --log(myent.type)
    -- Don't support character_corpse, artillery turret/wagon, inserters, robots (too much chance of it being a misclick), or roboports. We're concerned with STORAGE and OUTPUTS.
    -- We explicitly don't support godmode or editor mode inventories. Not even sure HOW since you can't select them.
    -- TODO: Maybe add a way to take from characters with this too. At the least - character_trash if same force. NOTE: since we use this for multi-grab we'd need to exclude that since we don't want players taking from characters on accident. Also, not sure if it's even possible without admin to do that.
    if myent.type == "container" or myent.type == "logistic-container" or myent.type == "infinity-container" then
        entinv = myent.get_inventory(defines.inventory.chest)
    elseif myent.type == "spider-vehicle" then
        entinv = myent.get_inventory(defines.inventory.spider_trunk)
    elseif myent.type == "car" then
        entinv = myent.get_inventory(defines.inventory.car_trunk)
    elseif myent.type == "assembling-machine" then
        entinv = myent.get_inventory(defines.inventory.assembling_machine_output)
    elseif myent.type == "furnace" then
        entinv = myent.get_inventory(defines.inventory.furnace_result)
    elseif myent.type == "cargo-landing-pad" then
        entinv = myent.get_inventory(defines.inventory.cargo_landing_pad_main)
    elseif myent.type == "space-platform-hub" then
        entinv = myent.get_inventory(defines.inventory.hub_main)
    elseif myent.type == "cargo-wagon" then
        entinv = myent.get_inventory(defines.inventory.cargo_wagon)
    elseif myent.type == "boiler" or myent.type == "locomotive" or myent.type == "reactor" then
        entinv = myent.get_burnt_result_inventory()
    end
    return entinv
end

-- Checks if an item has health, ammo, or non-infinite durability.
-- Unfortunately they cause issues with transferring, as amounts get refilled.
function has_health(protoname)
    if proto.place_result and proto.place_result.get_max_health() > 0 then --This item has an entity with health attached.
        return true -- Therefore, it has health
    end
    if proto.magazine_size then
        return true -- Has a magazine size
    end
    if proto.get_durability() then
        if proto.infinite then --Has durability but is infinite, then it's fine
            return false
        else
            return true --Non infinite durability is not fine.
        end
    end
    return false
end

--May be faster to setup a table of player requests with ["itemname" = amountneeded] and 0 needed discarded.
function grab_items(player, entlist, mychar)
    --Step 1 - Loop through logistic requests
    --Step 2 - See if each one is filled, if not find missing amount
    --Step 3 - Find out how much we could give to player, up to amount missing.
    --Step 3 - Try to remove that amount from the chest, store amount actually removed.
    --Step 4 - Give to the player however much we removed.
    --Step 4b - Check if removed and stored amounts are inequal. They shouldn't ever be but maybe.
    --Step 5 - If any items taken, add to count. If not all items were taken, set allfilled to false.
    --Step 6 - Loop done. Print to player "X items were taken, <all requests filled><some requests unfilled>"
    -- log("Doing stuff")
    local playerinv = mychar.get_main_inventory()
    if playerinv == nil or (not playerinv.valid) then
        player.print({"ManLog-NoPlayerInv"})
        return
    end
    local filled = 0
    local allfilled = true -- Set to false if any requests were left unfilled.
    local ignored = 0
    local invfull = 0
    local mylogpt = mychar.get_logistic_point(defines.logistic_member_index.character_requester)
    -- If there isn't a logistic point for the character, exit. Or if they have no filters, exit.
    if mylogpt == nil or mylogpt.filters == nil then return end
    --log(serpent.block(mylogpt.filters))
    --log(#mylogpt.filters)
    for _, arequest in pairs(mylogpt.filters) do
        --log(serpent.block(arequest))
        -- Not an empty request
        if arequest.name ~= nil then
            -- Count is the minimum we want to have on hand.
            local needed = arequest.count - playerinv.get_item_count{name=arequest.name,quality=arequest.quality}
            -- Player has less than the minimum they want of this item
            if needed > 0 then
                -- log(arequest.name .. " needs " .. tostring(needed))
                proto = prototypes.item[arequest.name]
                -- We can use these to determine if this item can have health, and then deny the attempt for now.
                -- Later I can rewrite this to have a separate method for dealing with it that iterates item stacks.
                -- player.print("ManLog Health check: " .. tostring(settings.global["ManualLogistics-NoHealthOnly"].value) .. " : " .. tostring(has_health(arequest.name)))
                -- Can only add in however much the inventory can hold up to the amount we need.
                local amounttoadd = math.min(needed, playerinv.get_insertable_count{name=arequest.name,quality=arequest.quality})
                if amounttoadd < needed then
                    allfilled = false
                end
                -- We can't fit ANY of this item, so we're not going to try adding it so we mark this request failed and skip the rest.
                if amounttoadd == 0 then
                    -- Mark this request as having none of the needed satisifed for the checks below.
                    amounttoadd = needed
                    invfull = invfull + 1 -- Also tell the player we failed to transfer at least one item due to no room.
                elseif proto.inventory_size or proto.equipment_grid or has_health(proto) then -- Items with an inventory or equipment grid must be moved via the stack itself so it won't erase items inside.
                    if amounttoadd > 0 then
                        -- There are no empty stacks, don't bother looping anything.
                        if playerinv.count_empty_stacks(true,true) == 0 then
                            goto donestack
                        end
                        for _, entinv in ipairs(entlist) do
                            local keeprunning = true
                            while keeprunning do -- We want to keep trying to find the item we need
                                local playstack, ind = playerinv.find_empty_stack{name=arequest.name, quality=arequest.quality}
                                if playstack == nil then -- We couldn't find an empty stack, we can not do a transfer. Skip the loop.
                                    goto donestack
                                end
                                local entstack, inde = entinv.find_item_stack{name=arequest.name, quality=arequest.quality}
                                if entstack ~= nil then -- Found the stack in the inventory
                                    didit = playstack.transfer_stack(entstack,amounttoadd)
                                    amounttoadd = amounttoadd - playstack.count -- remove how many we moved from how many we need to move
                                else -- The item doesn't exist in this container, stop looking in this container.
                                    keeprunning = false
                                end
                                if amounttoadd < 1 then -- no more to add, we can stop working on this request
                                    goto donestack
                                end
                            end
                        end
                    end
                    ::donestack::
                else
                    --log("To add: " .. tostring(amounttoadd))
                    if amounttoadd > 0 then
                        for _, entinv in ipairs(entlist) do
                            -- health here does nothing. It removes ANY items regardless of health
                            removed = entinv.remove({name = arequest.name, count = amounttoadd, quality=arequest.quality})
                            --log("removed: " .. tostring(removed))
                            if removed > 0 then
                                added = playerinv.insert({name = arequest.name, count = removed, quality=arequest.quality})
                                --log("added: " .. tostring(added))
                                if added ~=  removed then
                                    --log("Added a different amount than we removed!")
                                    --Readd the remaining amount. This SHOULDNT ever trigger as we check above, but maybe.
                                    entinv.insert({name = arequest.name, count = removed-added, quality=arequest.quality})
                                end
                                if added > 0 then
                                    amounttoadd = amounttoadd - added
                                    if amounttoadd < 1 then -- no more to add, we can stop working on this request
                                        goto done
                                    end
                                end
                            end
                        end
                    end
                    ::done::  
                end
                if amounttoadd ~= needed then -- This means we at least got some of them
                    filled = filled + 1
                end
                if amounttoadd > 0 then -- We still needed more and didn't get them
                    allfilled = false
                end
            end
        end
    end
    --log(tostring(allfilled) .. " : " .. tostring(filled))
    message = nil
    if allfilled then
        message = {"ManLog-FoundAll"}
    elseif filled > 0 then
        message = {"ManLog-FoundSome",filled}
    else
        message = {"ManLog-FoundNone"}
    end
    if ignored > 0 then -- If this trips then there is a bug. Message was changed to ask user to report this.
        message = {"", message, " ", {"ManLog-Ignored",ignored}}
    end
    if invfull > 0 then
        message = {"", message, " ", {"ManLog-InvFull",invfull}}
    end
    if message ~= nil then
        player.create_local_flying_text{text = message, create_at_cursor = true}
    end
end

-- Finds entities in range of the player and adds their inventories to list of invs to send to grab_items
function pre_grab_mult(event)
    player = game.players[event.player_index]
    mychar = player.character
    -- Does the player have a character? No logistics if not, so stop.
    if mychar == nil then
        player.print({"ManLog-NoPlayer"})
        return
    end
    -- Grab the logistic point for the character.
    mylogpt = mychar.get_logistic_point(defines.logistic_member_index.character_requester)
    -- Does the player have at least 1 request slot? We check this because it's almost certainly faster than the entity search we need to do.
    if mylogpt.filters and #mylogpt.filters > 0 then
        -- log(mychar.request_slot_count)
        -- Default reach in vanilla seems to be 10
        -- We limit the max reach to 20 so this doesn't take forever.
        myrad = math.min(player.reach_distance, 20)
        -- Gets entities around the player on the same force, within reach distance (max of 20 spaces)
        foundlist = player.surface.find_entities_filtered{position = player.position, radius = myrad, force = player.force}
        local entlist = {}
        -- log("List size: " .. #foundlist)
        for _ , myent in ipairs(foundlist) do
            entinv = get_source_inv(myent)
            if entinv == nil or (not entinv.valid) then
                -- Do nothing
            else -- Valid inventory, add it to our list
                table.insert(entlist, entinv)
            end
        end
        -- log("Inv list size: " .. #entlist)
        if #entlist > 0 then -- At least one inventory to search through
            grab_items(player, entlist, mychar)
        else
            player.create_local_flying_text{text = {"ManLog-NoInv"}, position = player.position}
        end
    end
end


script.on_event("manuallogistics-mult", pre_grab_mult)

function pre_trash_items(event)
    --log(serpent.block(event))
    player = game.players[event.player_index]
    myent = player.selected
    --log(serpent.block(myent))
    mychar = player.character
    -- log(serpent.block(mychar))
    -- log(mychar.character_personal_logistic_requests_enabled)
    -- Does the player have a currently selected entity and a character?
    if mychar == nil then
        player.print({"ManLog-NoPlayer"})
        return
    end
    if myent then
        --log(serpent.block(mychar.request_slot_count))
        -- Player must be able to reach the given entity AND they must be on the same force.
        if player.can_reach_entity(myent) then
            if (player.force == myent.force) then
                trash_items(player, myent, mychar)
            else
                player.create_local_flying_text{text = {"cant-transfer-to-enemy-structures"}, create_at_cursor = true}
            end
        else
            player.create_local_flying_text{text = {"cant-reach"}, create_at_cursor = true}
        end
    end
end

script.on_event("manuallogisticstrash", pre_trash_items)

function trash_items(player, myent, mychar)
    --Step 1 - Loop through trash slots
    --Step 2 - If something in slot, select itemstack
    --Step 3 - Find an emtpy itemstack in the selected inventory
    --Step 4 - Transfer from trash stack to new stack
    --Step 5 - If any items taken, add to count. If not all items were taken, set allfilled to false.
    --Step 6 - Loop done. Print to player "X items were transferred" or <all requests filled>
    playerinv = mychar.get_inventory(defines.inventory.character_trash)
    --If there is no inventory, or that inventory isn't valid, or that inventory is empty, we stop
    if playerinv == nil or (not playerinv.valid) then
        player.print({"ManLog-NoPlayerInv"})
        return
    end
    if playerinv.is_empty() then --Nothing in trash to transfer
        player.create_local_flying_text{text = {"ManLog-FoundNone"}, create_at_cursor = true}
        return
    end
    local entinv = nil -- Will be filled with the most proper inventory of our entity.
    --log("ManLog ent type: " .. myent.type)
    if myent.type == "container" or myent.type == "logistic-container" or myent.type == "infinity-container" then
        entinv = myent.get_inventory(defines.inventory.chest)
    elseif myent.type == "spider-vehicle" then
        entinv = myent.get_inventory(defines.inventory.spider_trunk)
    elseif myent.type == "car" then
        entinv = myent.get_inventory(defines.inventory.car_trunk)
    -- elseif myent.type == "assembling-machine" then
        -- entinv = myent.get_inventory(defines.inventory.assembling_machine_output)
    -- elseif myent.type == "furnace" then
        -- entinv = myent.get_inventory(defines.inventory.furnace_result)
    -- elseif myent.type == "rocket-silo" then
        -- entinv = myent.get_inventory(defines.inventory.rocket_silo_result)
    elseif myent.type == "cargo-wagon" then
        entinv = myent.get_inventory(defines.inventory.cargo_wagon)
    end
    if entinv == nil or (not entinv.valid) then
        player.create_local_flying_text{text = {"ManLog-NoInv"}, create_at_cursor = true}
        return
    end
    transferred = 0 -- How many items we've moved
    -- The actual loop
    for curslot=1,#playerinv do -- Loop over all the trash slots
        aslot = playerinv[curslot]
        -- Not an empty request
        if aslot.valid_for_read then -- Is this a valid-to-read stack? If not, it's empty.
            --player.print("Valid, slot " .. curslot)
            --Find empty slot in entity, to hold item in 
            empty = entinv.find_empty_stack(aslot.name)
            --Swap the stacks. That means empty trash slot, no-longer-empty destination slot.
            if empty then -- This would be nil if there is no empty slots
                aslot.swap_stack(empty)
            end
        end
    end
    message = nil
    if playerinv.is_empty() then
        message = {"ManLog-MovedAll"}
    elseif transferred > 0 then
        message = {"ManLog-FoundSomeTrash",transferred}
    else
        message = {"ManLog-MovedNone"}
    end
    if message ~= nil then
        player.create_local_flying_text{text = message, create_at_cursor = true}
    end
end

function enable_logistics(event)
    game.print("setting changed " .. event.setting)
    if event.setting == "ManualLogistics-UnlockLogistics" then
        -- Neither of these should ever be nil but JIC.
        if event.player_index and game.get_player(event.player_index) then
            game.get_player(event.player_index).force.character_logistic_requests = true
        end
    end
end

script.on_event(defines.events.on_runtime_mod_setting_changed, enable_logistics)