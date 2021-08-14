--TO FIX:

--Maybe redo how the addition works so there's no chance of adding a resource twice
--For example, both bobs ores and angels smelting add lead. As is I think it gets added twice, the second overwriting
--the first. This isn't an error or anything, but is a waste of time. Maybe add the commands to run to a table that
--gets added to if the item isn't already there. Would save needing code in each section for (if module doesn't exist)
--If I make this a table I can just have the add stuff insert their items into the table. A dupe would just replace the
--item, which wouldn't matter since I copy/paste those anyway. BONUS: I can use that table to set the mixed asteroid if
--an option for random results is selected - # of expected chunks/# of chunk types = average for each type.

--Crafting machine tints? Not sure that's really used with the current setup

--Later version will instead have a single building - the asteroid catcher, which generates the chunks. Send up miner
--module, get building. It has a set of recipes for generating the mixed or specific chunks. Send up a Miner Linking 
--module (made up of 4 buildings plus parts) get a 2nd tier asteroid catcher. Send up 4 of those plus parts, get highest
--tier asteroid catcher.
--Possibly first need a research which requires sending an asteroid slinger into orbit that's responsible for catching
--the shipped asteroids and deorbiting them. Similar to how seablock locks researches behind crafting an item

--Cost of a rocket: 49100 iron ore, 92500 copper ore,  9500 coal, (197500 petro (219444 oil, or 993750 oil))
--Needed chunks:     2046 iron chnk, 3855 copper chunk, 396 coal
--Expected return:  50880 iron ore, 93600 copper ore, 10800 coal
--Expected chunks:   2120 iron chnk, 3900 copper chunk, 450 coal
--Cost with prod3s: 14655 iron ore, 24668 copper ore, 2784 coal
--Needs 240 iron and 60 copper for asteroid miner
--Total chunks expected: 6470 - 6000 for resource specific miner

-- Expensive mode:
--Cost of a rocket: 98200 iron ore, 204000 copper ore, 29000 coal
--Needed chunks:     4092 iron chnk, 8500 copper chunk, 1209 coal
--Expected return: 101760 iron ore, 216000 copper ore, 31680 coal
--Expected chunks:   4240 iron chnk, 9000 copper chunk, 1320 coal
--Cost with prod3s: 70143 iron ore, 145715 copper ore, 20715 coal
--Needs 550 iron and 200 copper for asteroid miner
--Total chunks expected: 14560 - 14000 for resource specific miner


--Bobs mods - Assembling, Electronics, Logistics, Metals, Mining, Modules, Ores, defaultish settings
--Cost of a rocket: 1000 Quartz, 500 Stone, 24250 Copper, 6325 Coal, 2595 tin, 954.5 Galena, 1800 Gold, 2265 Iron Ore, 5000 Bauxite
--Really only Modules (Speed Module) and Electronics (Proc Unit). NO WAIT ALSO METALS.
--Without Modules : 1900 Quartz, 1400 stone, 40800 Copper, 10400 Coal, 12048 tin, 3818 Galena, 1000 Gold, 2140 Iron Ore, 0 Bauxite
--Without Electron: 0 Quartz, 0 stone, 75050 Copper, 9375 Coal, 1250 tin, 0 Galena, 800 Gold, 32225 Iron Ore, 5000 Bauxite
--Without Either  : 0 Quartz, 0 stone, 92500 Copper, 9500 Coal, 0 tin, 0 Galena, 0 Gold, 41100 Iron Ore
--Without Metals  : 0 Quartz, 0 stone, 27250 Copper, 5600 Coal, 0 tin, 0 Galena, 0 Gold, 15265 iron ore

--Bobs Expensive
--Cost of a rocket: 1750 Quartz, 1250 Stone, 26833 Copper, 23562 Coal, 4045 Tin, 954.5 Galena, 2333 Gold, 4350 Iron Ore, 10000 Bauxite
--Without Modules : 4000 Quartz, 3500 Stone, 50500 Copper, 33125 Coal, 18515 Tin, 3818 Galena, 1000 Gold, 4700 Iron Ore, 
--Without Electron: 0 Quartz, 0 stone, 174833 Copper, 30750 Coal, 1500 tin, 0 Galena, 1333 Gold, 70350 Iron, 10000 Bauxite
--Without Either  : 0 Quartz, 0 stone, 204000 Copper, 29000 Coal, 0 tin, 0 galena, 0 Gold, 82200 iron
--Without Metals  : 0 quartz, 0 stone, 32833 copper, 22000 coal, 0 tin, 0 galena, 0 gold, 30350 iron

--The default category. May be changed if certain mods are installed.

require("scripts/icons.lua") -- Has generateicons function

require("scripts/groups.lua") -- Handles setting our recipe groups
require("scripts/category.lua") -- Sets our asteroid processing category based on settings and installed mods

allowprod = settings.startup["astmine-allowprod"].value
useminer = settings.startup["astmine-enableminer"].value

--Adds given recipe to prod modules allowed list
function addmodules(name)
    if useminer then -- Only add these if we're actually enabled.
        table.insert(data.raw.module["productivity-module"].limitation, name)
        table.insert(data.raw.module["productivity-module-2"].limitation, name)
        table.insert(data.raw.module["productivity-module-3"].limitation, name)
    end
end

--Result for processing resource specific chunks
normal = { -- Gives 6000 chunks on average
    {
      amount_min = 4,
      amount_max = 8,
      probability = 1
    }
}
expensive = { -- Gives 14000 chunks on average
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
    rocket_launch_product = {
        "asteroid-mixed",
        1000
    },
    stack_size = 1,
    subgroup = subminer,
    type = "item"
}

--RECIPE: Creating the module to send in the rocket
local minermodulerecipe = {
  enabled = false,
  ingredients = {
    {
      "electric-mining-drill",
      5
    },
    {
      "radar",
      5
    }
  },
  name = "miner-module",
  result = "miner-module",
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
  stack_size = 1000,
  subgroup = subchunk,
  type = "item",
  enabled = true
}

-- RECIPE: Processing the mixed chunks into resource chunks
local processmixed = {
  allow_decomposition = false,
  category = reccategory,
  icon = "__Asteroid_Mining__/graphics/asteroid-chunk.png",
  icon_size = 64,
  name = "asteroid-mixed",
  localised_name = {"recipe-name.asteroid-chunk", "Mixed"},
  localised_description = {"recipe-description.asteroid-chunk", "mixed"},
  order = "k[yasteroid-mixed]",
  expensive = {
    enabled = true,
    energy_required = 10,
    ingredients = {
      {
        "asteroid-mixed",
        1
      }
    },
    results = {
        {
          amount = 8,
          name = "iron-ore-chunk",
          probability = 0.53
        },
        {
          amount = 9,
          name = "copper-ore-chunk",
          probability = 1
        },
        {
          amount = 6,
          name = "coal-chunk",
          probability = 0.22
        }
    },
  },
  normal = {
    enabled = true,
    energy_required = 10,
    ingredients = {
      {
        "asteroid-mixed",
        1
      }
    },
    results = {
        {
          amount = 4,
          name = "iron-ore-chunk",
          probability = 0.53
        },
        {
          amount = 6,
          name = "copper-ore-chunk",
          probability = 0.65
        },
        {
          amount = 2,
          name = "coal-chunk",
          probability = 0.21
        }
    },
  },
  subgroup = "raw-material",
  type = "recipe"
}
if allowprod then
    addmodules(processmixed.name)
end

function addtype(name,atint,desc) --,pictures)
    --Make a new item with the given name+"-chunk" and recipe to turn into name
    --eg addtype('iron-ore') makes iron-ore-chunk and recipe for iron-ore-chunk->100 iron-ore
    --log("Making new items for " .. name)
    --ITEM Resource chunk for this item
    
    local suffix = "-chunk"
    -- Sometimes we need to override the default suffix because the item name already exists.
    -- TODO - change this so it automatically detects name-chunk item exists and change suffix - BUT
    --  that would cause issues if 'name' is in more than one module - eg angels/bobs overlap, bob+bzlead, etc.
    --  Maybe add in something that tracks what 'name's have been added and skip it if it has.
    if string.find(name,"angels-ore",1,true) then
        suffix = "-chunk-am"
    end
    --log(name .. " name:suffix " .. suffix)
    
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
      always_show_products = true,
      category = reccategory,
      enabled = true,
      energy_required = 5,
      ingredients = {
        {
          name .. suffix,
          1
        }
      },
      name = name .. suffix,
      order = "d[asteroidchunk-" .. name .. "]",
      localised_name = {"recipe-name.resource-chunk", {"item-name." .. name}},
      localised_description = {"recipe-description.resource-chunk", {"item-name." .. name}},
      result = name,
      result_count = 24,
      type = "recipe"
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
      stack_size = 1000,
      subgroup = subchunk,
      type = "item"        
    }
    
    --We need to set the result name to the name of our resource chunk
    mynormal = table.deepcopy(normal)
    mynormal[1].name = name .. suffix
    myexpensive = table.deepcopy(expensive)
    myexpensive[1].name = name .. suffix
    
    --RECIPE: Processing the asteroid chunks into resource chunks
    local processasteroid = {
      allow_decomposition = false,
      category = reccategory,
      enabled = true,
      name = "asteroid-" .. name,
      localised_name = {"recipe-name.asteroid-chunk", {"item-name." .. name}},
      localised_description = {"recipe-description.asteroid-chunk", {"item-name." .. name}},
      order = "k[zasteroid-" .. name .. "]",
      expensive = {
        allow_decomposition = false,
        always_show_products = true,
        enabled = true,
        energy_required = 10,
        ingredients = {
          {
            "asteroid-" .. name,
            1
          }
        },
        results = myexpensive
      },
      normal = {
        allow_decomposition = false,
        always_show_products = true,
        enabled = true,
        energy_required = 10,
        ingredients = {
          {
            "asteroid-" .. name,
            1
          }
        },
        results = mynormal
      },
      --subgroup = subchunk,
      type = "recipe"
    }

    --ITEM Miner module to get resource specific asteroids.
    local minerres = table.deepcopy(minermodule)
    minerres.name = "miner-module-" .. name
    minerres.rocket_launch_product = {
        "asteroid-" .. name,
        1000
    }
    minerres.order = "n[miner-module" .. name .. "]"
    minerres.icons = generateicons(name,atint) --Generate icon layers using given item
    minerres.localised_name = {"item-name.miner-module", {"item-name." .. name}}
    minerres.localised_description = {"item-description.miner-module", {"item-name." .. name}}
    
    --RECIPE: Recipe to make miner module to get resource specific asteroids. Always the default category
    local newminer = {
        enabled = false,
        ingredients = {
            {
              "electric-mining-drill",
              5
            },
            {
              "radar",
              5
            },
            {
                name,
                5
            }
        },
        name = "miner-module-" .. name,
        result = "miner-module-" .. name,
        type = "recipe"        
    }
    data:extend{reschunk,procreschunk,newasteroid,processasteroid}
    if useminer then -- Disabled in 1.0 for the new generation system, once in place.
        data:extend{minerres,newminer}
        --This makes the miner module available when rocket silo is researched
        table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "miner-module-" .. name})
    end
    if allowprod then -- Setting to enable prod module usage in asteroid processing
        addmodules(processasteroid.name)
    end
end

require("scripts/bobs.lua")
--These will be nil if neither Ores or Plates are installed
bobnormal, bobexpensive = setmixed(processmixed)

require("scripts/simple.lua")
--These will be nill if Simple Silicon isn't installed
simpnormal, simpexpensive = setmixed(processmixed)

--We don't rebalance the mixed chunks, but we DO adjust the amount from resource specific modules
require("scripts/krastorio2.lua")
krasnormal, krasexpensive = setmixed(processmixed)

--Krastorio overrides bobs/simple silicon
--If bobs is present, it's normal/expensive results should overwrite simplesilicons
--If it's not present, then overwrite normal/expensive with simplesilicon's if present
if krasnormal then
    normal = krasnormal
elseif bobnormal then
    normal = bobnormal
elseif simpnormal then
    normal = simpnormal 
end
if krasexpensive then
    expensive = krasexpensive
elseif bobexpensive then
    expensive = bobexpensive
elseif simpexpensive then
    expensive = simpexpensive 
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
    addtype("stone", {a = 0,b = 0,g = 0,b = 0})
    addtype("uranium-ore", {a = .8,b = 100,g = 180,b = 0})

    --Add Bobs ores if present
    addbobs()

    --Add Simple Silicon quartz if present
    addsimple()

    --Add Angels ores if present
    addangels()

    --Add Krastorio 2 ores if present
    addkras()

    --add various single ores from mods
    addsingles()

    --add new items
    data:extend{asteroidmixed,processmixed}
    --Add recipe to rocket tech
    table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "miner-module"})

    data:extend{minermodule,minermodulerecipe}
end

require("prototypes/advanced.lua")