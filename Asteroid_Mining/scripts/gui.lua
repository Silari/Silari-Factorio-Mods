function add_button(player)
    if not player.gui.top["Homeworld_btn"] then
        player.gui.top.add{type="button",caption="HW:R",name="Homeworld_btn"}
    end
end

function on_init( event )
    GUI.init()
    Homeworld:init()
    --If mod was loaded into a save, give a portal to all players
    for _, player in pairs(game.players) do
        give_items(player)
        --Also load up the new GUI
        add_button(player)
    end
    log("Loaded init")
    if remote.interfaces["freeplay"] then
        log("Found interface")
        shipitems = remote.call("freeplay", "get_ship_items")
        shipitems["homeworld_portal"] = 1
        remote.call("freeplay", "set_ship_items", shipitems)
    end
end
script.on_init(on_init)

function on_player_created( event )
    --New players get a homeworld portal
    --This will silently fail in freeplay - we fix that in on_init
    local player = game.players[event.player_index]
    give_items(player)
    
    --Add HW GUI button
    add_button(player)
end
script.on_event(defines.events.on_player_created, on_player_created)
function on_config_change( event )
    --Ensure the mod GUI is on for all players
    for _, player in pairs(game.players) do
        --Also load up the new GUI
        --PrintToAllPlayers(serpent.block(player.gui.top["Homeworld_btn"]))
        --top[creative_mode_defines.names.gui.main_menu_open_button]
        add_button(player)
    end
end
script.on_configuration_changed(on_config_change)

function on_player_respawned(event)
    --Player was respawned, re-add GUI.
    local player = game.players[event.player_index]
    --Add HW GUI button
    add_button(player)
end
script.on_event(defines.events.on_player_respawned, on_player_respawned)

function toggle_gui(event)
    if event.element.name == "Asteroid_Mining" then
        if Homeworld.state.gui[event.player_index] then
            Homeworld:hide_gui(event.player_index)
        else
            Homeworld:show_gui(event.player_index)
        end
    end
end

script.on_event(defines.events.on_gui_click,toggle_gui)




function Homeworld:show_gui( player_index )
    if self.state.gui[player_index] then
        return
    end

    GUI.push_left_section(player_index)
    self.state.gui[player_index] = GUI.push_parent(GUI.frame("homeworld", "Homeworld", GUI.VERTICAL))
    GUI.label_data("tier", "Tier:", "1 / 6")
    GUI.label_data("population", {"population"}, "0 / 0 [0]")
    GUI.progress_bar("population_bar", 0)
    self:show_needs_gui(player_index)
    GUI.pop_all()
    self:update_gui(player_index)
end

function Homeworld:show_needs_gui( player_index )
   local my_gui = self.state.gui[player_index]
   if my_gui.needs then
      my_gui.needs.destroy()
   end
   GUI.push_parent(my_gui)
   GUI.push_parent(GUI.flow("needs", GUI.VERTICAL))
   for index, need in ipairs(self:get_needs()) do
      GUI.push_parent(GUI.flow("need_"..index, GUI.VERTICAL))
         GUI.push_parent(GUI.flow("label_icon", GUI.HORIZONTAL))
            GUI.icon("icon", need.item)
            GUI.push_parent(GUI.flow("labels", GUI.VERTICAL))
					GUI.label_data("item", game.item_prototypes[need.item].localised_name, "[0]")
               if need.consume_once then
                  GUI.label("consumption", "Target: "..PrettyNumber(need.count))
               else
                  local per_day = self:get_need_item_count(need, GAME_DAY)
                  GUI.label("consumption", "Consumption per day: "..PrettyNumber(per_day))
               end
            GUI.pop_parent()
         GUI.pop_parent()
         if need.consume_once then
            GUI.progress_bar("satisfaction", 1, 0, "homeworld_need_all_progressbar_style")
         else
            GUI.progress_bar("satisfaction", 1, 0, "homeworld_need_progressbar_style")
         end
      GUI.pop_parent()
   end
   GUI.pop_parent()
   GUI.pop_parent()
end

function Homeworld:update_gui( player_index )
   local my_gui = self.state.gui[player_index]
   local state = self.state
   local pop = state.population
   local pop_delta = state.population_delta
   local upgrade_pop = self:get_tier().upgrade_population
   local downgrade_pop = self:get_tier().downgrade_population
   local pop_bar_value = (pop - downgrade_pop) / (upgrade_pop - downgrade_pop)
   if math.floor(pop_delta) > 0 then
      pop_delta = string.format("+%i", math.floor(pop_delta))
   else
      pop_delta = string.format("%i", math.floor(pop_delta))
   end
   my_gui.tier.data.caption = string.format("%i / %i", self.state.tier, #config.tiers)
   my_gui.population.data.caption = string.format("%s / %s [%s]", PrettyNumber(pop), PrettyNumber(upgrade_pop), pop_delta)
   my_gui.population_bar.value = pop_bar_value
   local needs_gui = my_gui.needs
   for index, need in ipairs(self:get_needs()) do
      local need_gui = needs_gui["need_"..index]
      if need_gui then
         local labels = need_gui.label_icon.labels
         if not need.consume_once then
            local per_day = self:get_need_item_count(need, GAME_DAY)
            labels.consumption.caption = string.format("Consumption per day: %s", PrettyNumber(per_day))
         end
         local in_stock = self:count_item(need.item)
         labels.item.label.caption = game.item_prototypes[need.item].localised_name
         labels.item.data.caption = string.format("[%s]", PrettyNumber(in_stock))
         need_gui.satisfaction.value = self:get_average_satisfaction_for_need(need)
      end
   end
end

function Homeworld:hide_gui( player_index )
    --Hides the GUI for a given player
   if self.state.gui[player_index] == nil then
      return
   end
   self.state.gui[player_index].destroy()
   self.state.gui[player_index] = nil
end
