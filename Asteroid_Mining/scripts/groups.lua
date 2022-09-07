subminer = "intermediate-product"
subchunk = "raw-resource"
subtarget = "extraction-machine" -- Target is grouped with mining machines

-- This ends up getting run in data and updates and final but that's fine.
if settings.startup["astmine-newgroup"].value then
    biggroup = {
        icon = "__Asteroid_Mining__/graphics/mining-sat.png",
        icon_mipmaps = 4,
        icon_size = 64,
        name = "AsteroidMining",
        order = "bz",
        type = "item-group"        
    }
    astgroup = {
        name = "Asteroid-Miners",
        group = "AsteroidMining",
        type = "item-subgroup"
    }
    chunkgroup = {
        name = "ResourceChunks",
        group = "AsteroidMining",
        type = "item-subgroup"
    }
    data:extend{biggroup, astgroup, chunkgroup}
    subminer = "Asteroid-Miners"
    subchunk = "ResourceChunks"
    subtarget = "Asteroid-Miners"
end