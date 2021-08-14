-- Functions useful in the data stage.


--This is to generate the layered icons for the mining module, or whatever else needs it
function advancedicon(name, atint)
    --log("Making " .. name .. " " .. serpent.block(data.raw.item[name]))
    if data.raw.resource[name] then -- EVERYTHING we generate should be a resource
        itempath = data.raw.resource
    elseif data.raw.item[name] then -- We can try an item form.
        itempath = data.raw.item
    else -- Tenemut is a tool so try that?
        itempath = data.raw.tool
    end
    icon = itempath[name].icon
    iconsize = itempath[name].icon_size
    iconmip = itempath[name].icon_mipmaps
    tint = nil --Non-layered doesn't seem to support tints
    --For layered icons, get the first layer for now
    if icon == nil then
        icon = itempath[name].icons[1].icon
        if not iconsize then
            iconsize = itempath[name].icons[1].icon_size
        end
        iconmip = itempath[name].icons[1].icon_mipmaps
        tint = itempath[name].icons[1].tint
    end
    --Do mipmaps need to be equal among all icons? From what I remember of the atlas, probably not
    return {
        {
            icon = "__Asteroid_Mining__/graphics/mining-sat.png",
            icon_mipmaps = 4,
            icon_size = 64
        },
        {
            icon = "__Asteroid_Mining__/graphics/mining-sat-mask2.png",
            icon_mipmaps = 4,
            icon_size = 64,
            tint = atint
        },
        {
            icon = icon,
            --icon_mipmaps = 4, --For now, no mipmaps
            icon_size = iconsize,
            scale = 16/iconsize, --They should be 16 pixels
            shift = {
                -8,
                8
            },
            tint = tint
        }
    }
end

--Makes the needed items/recipes to create a new module to send into space to get resources.
function addadvancedtype(name,atint)
    --log("Making new items for " .. name)

    --ITEM Miner module to send to space.
    local minerres = {}
    minerres.name = "astmin-advmodule-" .. name
    minerres.order = "n[astmin-advmodule-" .. name .. "]"
    minerres.icons = advancedicon(name,atint) --Generate icon layers using given item
    minerres.localised_name = {"item-name.astmin-advmodule", {"item-name." .. name}}
    minerres.localised_description = {"item-description.astmin-advmodule", {"item-name." .. name}}
    minerres.stack_size = 1
    minerres.subgroup = subminer
    minerres.type = "item"

    --RECIPE: Recipe to make miner module to get resource specific asteroids. Always the default category
    --TODO Fix this recipe - multiple energy inputs, inserters, assemblers, roboport, robots, etc.
    local newminer = {
        enabled = false,
        ingredients = {
            {
              "electric-mining-drill",
              20
            },
            {
              "radar",
              10
            },
            {
              "roboport",
              1
            },
            {
              "construction-robot",
              50
            },
            {
              "nuclear-reactor",
              5
            },
            {
              "assembling-machine-3",
              10
            }
        },
        name = "astmin-advmodule-" .. name,
        result = "astmin-advmodule-" .. name,
        type = "recipe"        
    }
    data:extend{minerres,newminer}
    --This makes the miner module available when rocket silo is researched
    table.insert(data.raw.technology["ast-min-resminer"].effects, {type = "unlock-recipe", recipe = "astmin-advmodule-" .. name})
end

-- Checks product table for any fluid products.
function givesfluid(products)
    for _, product in ipairs(products) do
        if product['type'] == 'fluid' then return true end
    end
    return false
end

-- Checks size of resource to avoid oversize items.
function collsize(collision)
    if collision == nil then return false end -- Not sure if I want to ignore ore exclude non-colliding resources. For now let's allow them.
    if math.abs(collision[1][1]) + math.abs(collision[2][1]) > 1 or math.abs(collision[1][2]) + math.abs(collision[2][2]) > 1 then
        return true
    end
    return false
end

function checksignal(resource)
    local name = resource.name
    if data.raw["item"][name] or data.raw["item-with-entity-data"][name] or data.raw["item-with-inventory"][name] or data.raw["item-with-label"][name] or data.raw["item-with-tags"][name] then
        -- An item exists with this name, we don't need to do anything
        -- log("Signal exists for " .. name)
    else
        -- No item with this name, we need to make a virtual signal for this
        -- log("Making signal " .. name)
        newsignal = {
            icons = resource.icons,
            icon = resource.icon,
            icon_mipmaps = resource.icon_mipmaps,
            icon_size = resource.icon_size,
            name = name,
            order = resource.order,
            subgroup = resource.subgroup or "raw-resource",
            type = "virtual-signal",
            localised_name={"virtual-signal-name.resourcesignal",name}
        }
        -- newsignal.icons = resource.icons
        -- newsignal.icon = resource.icon
        -- newsignal.icon_mipmaps = resource.icon_mipmaps
        -- newsignal.icon_size = resource.icon_size
        data:extend{newsignal,}
    end
end

-- Iterates all resources and makes modules for types we want to make available.
function make_resources(makesignal)
    -- This should attempt to find all resources in the game and make the proper modules for them.
    local skipfluid = "Disallow" == settings.startup["astmine-disallowfluid"].value -- Should we skip resources that require fluids?
    local skiplarge = true
    for name, resource in pairs(data.raw['resource']) do
        local tempres = table.deepcopy(resource)
        tempres.autoplace = nil
        -- log(name .. " n:r " .. serpent.block(tempres))
        -- We don't care about the specifics of the results, other than a) there IS a result, and b) none of the results are fluids.
        if data.raw["item"]["astmin-advmodule-" .. name] then
            --log("item already exists for: " .. name)
            if makesignal then
                checksignal(resource)
            end
            goto continue
        end
        if resource.minable == nil then goto continue end -- no mining result so nothing to do.
        local results = resource.minable.results -- Results always takes priority
        if results == nil then -- if there is no results check for a .result
            local item = resource.minable.result
            -- For resources there SHOULD always be one or the other but it's not required.
            if item then -- result is always item type?
                -- We're going to normalize things to a results table for ease.
                results = {{type = 'item', name = item, amount = resource.minable.amount or 1 }}
            end
        end
        -- We skip resources that make nothing, infinite resources, optionally resources requiring fluids, and resources that give fluids
        if results == nil or resource.infinite then 
            log("Skipping resource " .. name)
        elseif skipfluid and resource.minable.fluid_amount > 0 then
            log("Skipping fluid required resource " .. name)
        elseif false and skiplarge and collsize(resource.collision_box) then
            log("Skipping large resource " .. name)
        else
            if givesfluid(results) then -- This should only be non-infinite fluids so maybe keep?
                log("Skipping fluid resource " .. name .. " : " .. serpent.block(products))
            else
                log("make_resources: " .. name)
                addadvancedtype(name)
                if makesignal then
                    checksignal(resource)
                end
            end
        end
        ::continue::
    end
end
