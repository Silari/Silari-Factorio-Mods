require("__Asteroid_Mining__.scripts.icons")

amfunc = {}
amfunc.allowprod = settings.startup["astmine-allowprod"].value
amfunc.useminer = settings.startup["astmine-enableminer"].value
amfunc.reccategory = "crafting" -- Recipe category for asteroid processing to use
--Result for processing resource specific chunks
amfunc.normal = { -- Gives 6000 chunks on average
    {
      amount_min = 4,
      amount_max = 8,
      probability = 1
    }
}
amfunc.expensive = { -- Gives 14000 chunks on average
    {
      amount_min = 12,
      amount_max = 16,
      probability = 1
    }
}

--If Krastorio2 is installed and crafting category for crushing exists, we'll use that for processing chunks
if settings.startup["astmine-k2crushing"].value and data.raw["recipe-category"]["crushing"] then
    amfunc.reccategory = "crushing"
end

--If Angel's Crushing category exists and setting isn't off, use it for chunk crushing. This overrides K2.
if settings.startup["astmine-crushing"].value and data.raw["recipe-category"]["ore-sorting-t1"] then
    amfunc.reccategory = "ore-sorting-t1"
end

amfunc.subminer = "intermediate-product"
amfunc.subchunk = "raw-resource"
amfunc.subtarget = "extraction-machine" -- Target is grouped with mining machines

-- This ends up getting run in data and updates and final but that's fine.
if settings.startup["astmine-newgroup"].value then
    amfunc.subminer = "Asteroid-Miners"
    amfunc.subchunk = "ResourceChunks"
    amfunc.subtarget = "Asteroid-Miners"
end


--Adds given recipe to prod modules allowed list
function amfunc.addmodules(name)
    if amfunc.useminer then -- Only add these if we're actually enabled.
        table.insert(data.raw.module["productivity-module"].limitation, name)
        table.insert(data.raw.module["productivity-module-2"].limitation, name)
        table.insert(data.raw.module["productivity-module-3"].limitation, name)
    end
end

function amfunc.addtype(name,atint,desc) --,pictures)
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
      subgroup = amfunc.subchunk,
      type = "item"
    }
    
    --RECIPE Turn resource chunk into 24 of item
    local procreschunk = {
      allow_decomposition = false,
      always_show_products = true,
      category = amfunc.reccategory,
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
      subgroup = amfunc.subchunk,
      type = "item"        
    }
    
    --We need to set the result name to the name of our resource chunk
    mynormal = table.deepcopy(amfunc.normal)
    mynormal[1].name = name .. suffix
    myexpensive = table.deepcopy(amfunc.expensive)
    myexpensive[1].name = name .. suffix
    
    --RECIPE: Processing the asteroid chunks into resource chunks
    local processasteroid = {
      allow_decomposition = false,
      category = amfunc.reccategory,
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
    local minerres = {
        stack_size = 1,
        subgroup = amfunc.subminer,
        type = "item",
        name = "miner-module-" .. name,
        rocket_launch_product = {
            "asteroid-" .. name,
            1000
        },
        order = "n[miner-module" .. name .. "]",
        icons = generateicons(name,atint), --Generate icon layers using given item
        localised_name = {"item-name.miner-module", {"item-name." .. name}},
        localised_description = {"item-description.miner-module", {"item-name." .. name}}
    }
    
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
    if amfunc.useminer then -- Disabled in 1.0 for the new generation system, once in place.
        data:extend{minerres,newminer}
        --This makes the miner module available when rocket silo is researched
        table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "miner-module-" .. name})
    end
    if amfunc.allowprod then -- Setting to enable prod module usage in asteroid processing
        amfunc.addmodules(processasteroid.name)
    end
end

