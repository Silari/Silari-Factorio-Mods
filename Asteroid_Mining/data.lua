--TO FIX:
--Maybe redo how the addition works so there's no chance of adding a resource twice
--For example, both bobs ores and angels smelting add lead. As is I think it gets added twice, the second overwriting
--the first. This isn't an error or anything, but is a waste of time. Maybe add the commands to run to a table that
--gets added to if the item isn't already there. Would save needing code in each section for (if module doesn't exist)
--If I make this a table I can just have the add stuff insert their items into the table. A dupe would just replace the
--item, which wouldn't matter since I copy/paste those anyway. BONUS: I can use that table to set the mixed asteroid if
--an option for random results is selected - # of expected chunks/# of chunk types = average for each type.

--Crafting machine tints? Not sure that's really used with the current setup

--NEW rocket cost : 34100 iron ore, 60000 copper ore, 4500 coal, (97500 petro (175213 oil)
--Needed chunks:     1421 iron chk,  2500 copper chk,  188 coal
--Expected return:  36000 iron ore, 64800 copper ore, 5040 coal


--Cost of a rocket: 49100 iron ore, 92500 copper ore,  9500 coal, (197500 petro (219444 oil, or 993750 oil))
--Needed chunks:     2046 iron chnk, 3855 copper chunk, 396 coal
--Expected return:  50880 iron ore, 93600 copper ore, 10800 coal
--Expected chunks:   2120 iron chnk, 3900 copper chunk, 450 coal
--Cost with prod3s: 14655 iron ore, 24668 copper ore, 2784 coal
--Needs 240 iron and 60 copper for asteroid miner
--Total chunks expected: 6470 - 6000 for resource specific miner

--Cost with Prod Mods: 35071 io, 66071 co, 6785 coal
-- 1798.809 ore per minute.
-- 592.527 ore per minute with everything prod3'd as high as possible. NOT counting mining productivity.
-- So just above an hour ROI. Not bad.

require("scripts/icons.lua") -- Has generateicons function

require("scripts/groups.lua") -- Handles setting our recipe groups
require("scripts/category.lua") -- Sets our asteroid processing category based on settings and installed mods

allowprod = settings.startup["astmine-allowprod"].value
useminer = settings.startup["astmine-enableminer"].value
hiderec = not settings.startup["astmine-hiderecipes"].value
recenabled = false
-- if mods["space-age"] then 
    -- recenabled = true 
    -- hiderec = true
-- end

local chunkstacksize = 1000
if mods["space-exploration"] then
    chunkstacksize = 200
end

--Adds given recipe to prod modules allowed list
function addmodules(name)
    if useminer then -- Only add these if we're actually enabled.
        table.insert(data.raw.module["productivity-module"].limitation, name)
        table.insert(data.raw.module["productivity-module-2"].limitation, name)
        table.insert(data.raw.module["productivity-module-3"].limitation, name)
    end
end

--Result for processing resource specific chunks
normal = { -- Gives 4000 chunks on average
    {
      amount_min = 3,
      amount_max = 5,
      probability = 1
    }
}
chunkamount = 1000

-- Space age makes rockets cost 1/20th as much. Give less materials, same ratio.
if mods["space-age"] then 
    chunkamount = 50
end

expensive = { -- Gives 14000 chunks on average. No longer used.
    {
      amount_min = 12,
      amount_max = 16,
      probability = 1
    }
}

--ITEM: Miner-module, which is what we send into space to get the asteroid-mixed item
local minermodule = {
    icon = "__Asteroid_Mining__/graphics/mining-sat.png",
    icon_mipmaps = 4,
    icon_size = 64,
    name = "miner-module",
    localised_name = {"item-name.miner-module", "Mixed"},
    localised_description = {"item-description.miner-module", "mixed"},
    order = "n[miner-module]",
    rocket_launch_products = {{
        name="asteroid-mixed",
        amount=chunkamount,
        type="item"
    }},
    send_to_orbit_mode = "automated",
    stack_size = 1,
    subgroup = subminer,
    type = "item"
}

--RECIPE: Creating the module to send in the rocket
local minermodulerecipe = {
  enabled = recenabled,
  ingredients = {
    {
      name="electric-mining-drill",
      amount=5,
      type="item"
    },
    {
      name="radar",
      amount=5,
      type="item"
    }
  },
  name = "miner-module",
  results = {{name="miner-module",amount=1,type="item"}},
  type = "recipe"
}

-- ITEM: The normal result of sending an asteroid mining mission
local asteroidmixed = {
  icons = {
    {
      icon = "__Asteroid_Mining__/graphics/asteroid-chunk.png",
      icon_mipmaps = 4,
      icon_size = 64
    }
  },
  name = "asteroid-mixed",
  localised_name = {"item-name.asteroid-chunk", "Mixed"},
  localised_description = {"item-description.asteroid-chunk", "mixed", ""},
  order = "d[zasteroid-mixed]",
  stack_size = chunkstacksize,
  subgroup = subchunk,
  type = "item",
  enabled = true
}

-- RECIPE: Processing the mixed chunks into resource chunks
local processmixed = {
  allow_decomposition = false,
  allow_productivity = allowprod,
  category = reccategory,
  icon = "__Asteroid_Mining__/graphics/asteroid-chunk.png",
  icon_size = 64,
  name = "asteroid-mixed",
  localised_name = {"recipe-name.asteroid-chunk", "Mixed"},
  localised_description = {"recipe-description.asteroid-chunk", "mixed"},
  order = "k[yasteroid-mixed]",
  enabled = hiderec,
  energy_required = 10,
  ingredients = {
      {
        name="asteroid-mixed",
        amount=1,
        type="item"
      }
  },
  results = {
        {
          amount = 4,
          name = "iron-ore-chunk",
          probability = 0.5,
          type="item"
        },
        {
          amount = 6,
          name = "copper-ore-chunk",
          probability = 0.45,
          type="item"
        },
        {
          amount = 3,
          name = "coal-chunk",
          probability = 0.07,
          type="item"
        }
  },
  subgroup = subchunk,
  type = "recipe"
}

function addtype(name,atint,desc) --,pictures)
    --Make a new item with the given name+"-chunk" and recipe to turn into name
    --eg addtype('iron-ore') makes iron-ore-chunk and recipe for iron-ore-chunk->100 iron-ore
    --log("Making new items for " .. name)
    
    local suffix = "-chunk"
    -- Sometimes we need to override the default suffix because the item name already exists.
    -- TODO - change this so it automatically detects name-chunk item exists and change suffix - BUT
    --  that would cause issues if 'name' is in more than one module - eg angels/bobs overlap, bob+bzlead, etc.
    --  Maybe add in something that tracks what 'name's have been added and skip it if it has.
    if string.find(name,"angels-ore",1,true) then
        suffix = "-chunk-am"
    end
    --log(name .. " name:suffix " .. suffix)
    
    if name == "iron-ore" or name == "copper-ore" or name == "coal" then
        hidesignal = false
    end
    
    --ITEM Resource chunk for this item
    local reschunk = {
      icons = {
        {
          icon = "__Asteroid_Mining__/graphics/resource-chunk.png",
          icon_mipmaps = 4,
          icon_size = 64
        },
        {
          icon = "__Asteroid_Mining__/graphics/resource-chunk-mask.png",
          icon_mipmaps = 4,
          icon_size = 64,
          tint = atint
        }
      },
      name = name .. suffix,
      localised_name = {"item-name.resource-chunk", {"item-name." .. name}},
      localised_description = {"item-description.resource-chunk", {"item-name." .. name}},
      order = "d[asteroidchunk-" .. name .. "]",
      stack_size = 25,
      subgroup = subchunk,
      type = "item"
    }
    
    --RECIPE Turn resource chunk into 24 of item
    local procreschunk = {
      allow_decomposition = false,
      allow_productivity = allowprod,
      always_show_products = true,
      auto_recycle = false, -- We don't want this to be reversible, messes with scrap recycling specifically.
      category = reccategory,
      enabled = hiderec,
      energy_required = 5,
      ingredients = {
        {
          name=name .. suffix,
          amount=1,
          type="item"
        }
      },
      name = name .. suffix,
      order = "d[asteroidchunk-" .. name .. "]",
      localised_name = {"recipe-name.resource-chunk", {"item-name." .. name}},
      localised_description = {"recipe-description.resource-chunk", {"item-name." .. name}},
      results = {{name=name,amount=24,type="item"}},
      type = "recipe",
      -- Recipe gets productivity if enabled. 
      astmineresource = {ignore=true,} -- ignore=true means this won't show up as an unused entry
    }
    if desc == nil then
        desc = ""
    end
    
    --ITEM Resource specific asteroid chunk.
    local newasteroid = {
      icons = {
        {
          icon = "__Asteroid_Mining__/graphics/asteroid-chunk.png",
          icon_mipmaps = 4,
          icon_size = 64
        },
        {
          icon = "__Asteroid_Mining__/graphics/asteroid-chunk-mask.png",
          icon_mipmaps = 4,
          icon_size = 64,
          tint = atint
        }
      },
      name = "asteroid-" .. name,
      localised_name = {"item-name.asteroid-chunk", {"item-name." .. name}},
      localised_description = {"item-description.asteroid-chunk", {"item-name." .. name}, desc},
      order = "k[zasteroid-" .. name .. "]",
      stack_size = chunkstacksize,
      subgroup = subchunk,
      type = "item"        
    }
    --log(serpent.block(newasteroid))
    --We need to set the result name to the name of our resource chunk
    mynormal = table.deepcopy(normal)
    mynormal[1].name = name .. suffix
    mynormal[1].type = "item"
    --Expensive mode is gone.
    --myexpensive = table.deepcopy(expensive)
    --myexpensive[1].name = name .. suffix
    
    --RECIPE: Processing the asteroid chunks into resource chunks
    local processasteroid = {
      allow_decomposition = false,
      allow_productivity = allowprod,
      category = reccategory,
      name = "asteroid-" .. name,
      localised_name = {"recipe-name.asteroid-chunk", {"item-name." .. name}},
      localised_description = {"recipe-description.asteroid-chunk", {"item-name." .. name}},
      order = "k[zasteroid-" .. name .. "]",
      ingredients = {{name="asteroid-" .. name,amount=1,type="item"}},
      hide_from_signal_gui = hidesignal,
      results = mynormal,
      always_show_products = true,
      enabled = hiderec,
      energy_required = 10,
      --subgroup = subchunk,
      type = "recipe"
    }

    --ITEM Miner module to get resource specific asteroids.
    local minerres = table.deepcopy(minermodule)
    minerres.name = "miner-module-" .. name
    minerres.rocket_launch_products = {{
        name="asteroid-" .. name,
        amount=chunkamount,
        type="item"
    }}
    minerres.order = "n[miner-module" .. name .. "]"
    minerres.icons = generateicons(name,atint) --Generate icon layers using given item
    minerres.localised_name = {"item-name.miner-module", {"item-name." .. name}}
    minerres.localised_description = {"item-description.miner-module", {"item-name." .. name}}
    
    --RECIPE: Recipe to make miner module to get resource specific asteroids. Always the default category
    local newminer = {
        enabled = recenabled,
        ingredients = {
            {
              name="electric-mining-drill",
              amount=5,
              type="item"
            },
            {
              name="radar",
              amount=5,
              type="item"
            },
            {
              name=name,
              amount=5,
              type="item"
            }
        },
        name = "miner-module-" .. name,
        results = {{name="miner-module-" .. name,amount=1,type="item"}},
        type = "recipe"        
    }
    data:extend{reschunk,procreschunk,newasteroid,processasteroid}
    if useminer then -- Basic mode toggle.
        data:extend{minerres,newminer}
        --This makes the miner module available when rocket silo is researched
        table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "miner-module-" .. name})
        if not hiderec then
            table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "asteroid-" .. name})
            table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = name .. suffix})
        end
    end
    hidesignal = nil
end

require("scripts/bobs.lua")
--These will be nil if none of the supported bobs mods are installed
bobnormal = setmixed(processmixed)


require("scripts/simple.lua")
--These will be nil if Simple Silicon isn't installed
simpnormal, simpexpensive = setmixed(processmixed)

--We don't rebalance the mixed chunks, but we DO adjust the amount from resource specific modules
require("scripts/krastorio2.lua")
krasnormal = setmixed(processmixed)


if krasnormal then
    normal = krasnormal
elseif bobnormal then
    normal = bobnormal
elseif simpnormal then
    normal = simpnormal 
end

require("scripts/angels.lua")
--We don't currently rebalance mixed asteroid for angels

require("scripts/singles.lua")
--Also no rebalancing needed for singles

--We don't actually add anything at all unless the option to use the basic mining modules is enabled.
if useminer then
    --Add our vanilla ores
    addtype("coal", {a = 0.6,r = 0,g = 0,b = 0})
    addtype("copper-ore", {a = .8,r = 255,g = 60,b = 0})
    addtype("iron-ore", {a = .8,r = 0,g = 140,b = 255})
    addtype("stone", {a = 0,r = 0,g = 0,b = 0})
    addtype("uranium-ore", {a = .8,r = 100,g = 180,b = 0})

    -- add space-age ores
    if mods["space-age"] then 
        addtype("calcite", {a = 0,r = 180,g = 179,b = 179})
        -- this might be a little OP...
        addtype("tungsten-ore", {a = 0,r = 60,g = 57,b = 118})
        -- Scrap, not holminite. We're trying to replace miner's with our results.
        addtype("scrap", {a = 0, r = 180, g = 10, b = 10})
        log(serpent.block(data.raw.recipe["asteroid-scrap"].results[1]))
        data.raw.recipe["asteroid-scrap"].results[1]["amount_max"] = 4
        log(serpent.block(data.raw.recipe["asteroid-scrap"].results[1]))
    end

    --Add Bobs ores if present
    addbobs()

    --Add Simple Silicon quartz if present
    addsimple()

    --Add Angels ores if present
    addangels()

    --add various single ores from mods
    addsingles()

    --Add Krastorio 2 ores if present
    addkras()

    --add new items
    data:extend{asteroidmixed,processmixed}
    --Add recipe to rocket tech
    table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "miner-module"})
    if not hiderec then
        table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "asteroid-mixed"})
    end
    data:extend{minermodule,minermodulerecipe}
end

-- We aren't including advanced mode items.
if settings.startup["astmine-makerockets"].value then
    require("prototypes/advanced.lua")
end
