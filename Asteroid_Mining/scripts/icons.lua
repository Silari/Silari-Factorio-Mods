function generateicons(name,atint)
    --This is to generate the layered icons for the mining module, or whatever else needs it
    --log("Making " .. name .. " " .. serpent.block(data.raw.item[name]))
    if data.raw.item[name] then -- MOST things we generate are items
        itempath = data.raw.item
    else -- tenemut isn't, it's a tool. A big tool.
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