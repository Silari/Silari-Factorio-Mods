require("__Asteroid_Mining__.scripts.icons")

amfunc = {}
amfunc.allowprod = settings.startup["astmine-allowprod"].value
amfunc.useminer = settings.startup["astmine-enableminer"].value
amfunc.hiderec = not settings.startup["astmine-hiderecipes"].value
amfunc.reccategory = "crafting" -- Recipe category for asteroid processing to use
recenabled = false

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

function amfunc.addtype(name,atint,desc,resourcetype) --,pictures)
    -- Make a new item with the given name+"-chunk" and recipe to turn into name
    -- eg addtype('iron-ore') makes iron-ore-chunk and recipe for iron-ore-chunk->100 iron-ore
    -- atint is used to tint the various miners/asteroid/chunks/etc to differentiate them.
    -- resourcetype should be either "item" or "fluid" at this time. Defaults to "item"
    --log("Making new items for " .. name)
    
    -- If no description is provided, we use a blank one.
    -- This gets appended to the end of the asteroid description. 
    if desc == nil then
        desc = ""
    end

    -- These add support for fluids. Default is "item" type, which most things are.
    resourcetype = (resourcetype or "item")
    
    -- Fluids are basically 10 to a unit with how the math works.
    resamount = 24
    if resourcetype == "fluid" then resamount = 240 end
    
    local suffix = "-chunk"
    -- Sometimes we need to override the default suffix because the item name already exists.
    -- TODO - change this so it automatically detects name-chunk item exists and change suffix - BUT
    --  that would cause issues if 'name' is in more than one module - eg angels/bobs overlap, bob+bzlead, etc.
    --  Maybe add in something that tracks what 'name's have been added and skip it if it has.
    if string.find(name,"angels-ore",1,true) then
        suffix = "-chunk-am"
    end
    --log(name .. " name:suffix " .. suffix)
    
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
      localised_name = {"item-name.resource-chunk", {resourcetype .. "-name." .. name}},
      localised_description = {"item-description.resource-chunk", {resourcetype .. "-name." .. name}},
      order = "d[asteroidchunk-" .. name .. "]",
      stack_size = 25,
      subgroup = amfunc.subchunk,
      type = "item"
    }
    
    --RECIPE Turn resource chunk into 24 of item
    local procreschunk = {
      allow_decomposition = false,
      allow_productivity = amfunc.allowprod,
      always_show_products = true,
      auto_recycle = false, -- We don't want this to be reversible, messes with scrap recycling specifically.
      category = amfunc.reccategory,
      enabled = amfunc.hiderec,
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
      localised_name = {"recipe-name.resource-chunk", {resourcetype .. "-name." .. name}},
      localised_description = {"recipe-description.resource-chunk", {resourcetype .. "-name." .. name}},
      results = {{name=name,amount=resamount,type=resourcetype}},
      type = "recipe"
    }
    if resourcetype == "fluid" then
        procreschunk.category = "advanced-crafting"
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
      localised_name = {"item-name.asteroid-chunk", {resourcetype .. "-name." .. name}},
      localised_description = {"item-description.asteroid-chunk", {resourcetype .. "-name." .. name}, desc},
      order = "k[zasteroid-" .. name .. "]",
      stack_size = 1000,
      subgroup = amfunc.subchunk,
      type = "item"        
    }
    
    --We need to set the result name to the name of our resource chunk
    mynormal = table.deepcopy(amfunc.normal)
    mynormal[1].name = name .. suffix
    mynormal[1].type = "item"
    
    --RECIPE: Processing the asteroid chunks into resource chunks
    local processasteroid = {
      allow_decomposition = false,
      allow_productivity = amfunc.allowprod,
      category = amfunc.reccategory,
      enabled = amfunc.hiderec,
      name = "asteroid-" .. name,
      localised_name = {"recipe-name.asteroid-chunk", {resourcetype .. "-name." .. name}},
      localised_description = {"recipe-description.asteroid-chunk", {resourcetype .. "-name." .. name}},
      order = "k[zasteroid-" .. name .. "]",
      ingredients = {{name="asteroid-" .. name,amount=1,type="item"}},
      results = mynormal,
      always_show_products = true,
      energy_required = 10,
      --subgroup = subchunk,
      type = "recipe"
    }

    local generatedicons = generateicons(name,atint) --Generate icon layers using given item
    if generatedicons == false then
        log("Generated icons failed. Item could not be added.")
        return
    end
    
    
    --ITEM Miner module to get resource specific asteroids.
    local minerres = {
        stack_size = 1,
        --subgroup = amfunc.subminer,
        type = "item",
        name = "miner-module-" .. name,
        rocket_launch_products = {{
            name="asteroid-" .. name,
            amount=chunkamount,
            type="item"
        }},
        order = "n[miner-module" .. name .. "]",
        icons = generatedicons,
        localised_name = {"item-name.miner-module", {resourcetype .. "-name." .. name}},
        localised_description = {"item-description.miner-module", {resourcetype .. "-name." .. name}}
    }
    
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
              amount=math.ceil(resamount/5),
              type=resourcetype
            }
        },
        name = "miner-module-" .. name,
        results = {{name="miner-module-" .. name,amount=1,type="item"}},
        type = "recipe"        
    }
    if resourcetype == "fluid" then
        newminer.category = "advanced-crafting"
    end
    
    data:extend{reschunk,procreschunk,newasteroid}
    if amfunc.useminer then -- Basic mode toggle.
        data:extend{minerres,newminer,processasteroid}
        --This makes the miner module available when rocket silo is researched
        table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "miner-module-" .. name})
        if not amfunc.hiderec then
            table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = "asteroid-" .. name})
            table.insert(data.raw.technology["rocket-silo"].effects, {type = "unlock-recipe", recipe = name .. suffix})
        end
    end
end

