
--CHANGE TO BOBS PLATES. Ores alone isn't enough, none of the new ones are used without bobs metals
--Actually, if Ores OR Plates are installed the ores exist. They're not spawned without ores installed though
--And ores won't spawn them if nothing is set to use them, like Plates. So if EITHER is there lets make them.
function addbobs()
    if mods["bobores"] or mods["bobplates"] then
        --addtype("", {a = 0.4, r = 0, g = 0, b = 0})
        addtype("bauxite-ore", {a = 0.4, r = 255, g = 255, b = 0})
        addtype("cobalt-ore", {a = 0.4, r = 0, g = 0, b = 240})
        addtype("gold-ore", {a = 0.4, r=255, g=215, b=0})
        addtype("lead-ore", {a = 0.4, r = 10, g = 10, b = 10})
        addtype("nickel-ore", {a = 0.4, r=46,g=139,b=100})
        addtype("quartz", {a = 0.4, r = 250, g = 250, b = 250})
        addtype("rutile-ore", {a = 0.4, r=90, g=0, b=90})
        addtype("silver-ore", {a = 0.4, r = 128, g = 128, b = 144})
        addtype("thorium-ore", {a = 0.4, r = 222, g = 255, b = 0})
        addtype("tin-ore", {a = 0.4, r = 60, g = 60, b = 60})
        addtype("tungsten-ore", {a = 0.4, r = 101, g = 67, b = 33})
        addtype("zinc-ore", {a = 0.4, r=0,g=255,b=255})

        --Gem ores - may remove the mixed gems since it's much less useful
        --addtype("gem-ore", {a = 0.4, r = 0, g = 0, b = 0})
        addtype("ruby-ore", {a = 0.4, r=255,g=105,b=180}) --r = 240, g = 10, b = 10})
        addtype("sapphire-ore", {a = 0.4, r = 20, g = 20, b = 200})
        addtype("emerald-ore", {a = 0.4, r=124,g=252,b=0}) --r = 20, g = 240, b = 20})
        addtype("amethyst-ore", {a = 0.4, r=255,g=0,b=255})
        addtype("topaz-ore", {a = 0.4, r = 200, g = 150, b = 0})
        addtype("diamond-ore", {a = 0.4, r = 160, g = 160, b = 220})
    end
end

function setmixed(processmixed)
    if mods["bobmodules"] or mods["bobplates"] then
        log("Setting bobs mixed results")
    end
    --Cost of a rocket: 1000 Quartz, 500 Stone, 24250 Copper, 6325 Coal, 2595 tin, 954.5 Galena, 1800 Gold, 2265 Iron Ore, 5000 Bauxite
    --Cost of a rocket: 1750 Quartz, 1250 Stone, 26833 Copper, 23562 Coal, 4045 Tin, 954.5 Galena, 2333 Gold, 4350 Iron Ore, 10000 Bauxite
    if mods["bobplates"] and mods["bobmodules"] and mods["bobelectronics"] then
        processmixed.normal.results = { -- 2330 chunks expected
            {
              amount = 1,
              name = "iron-ore-chunk",
              probability = 0.1
            },
            {
              amount = 2,
              name = "copper-ore-chunk",
              probability = 0.55
            },
            {
              amount = 3,
              name = "coal-chunk",
              probability = 0.1
            },
            {
              amount = 1,
              name = "stone-chunk",
              probability = 0.03
            },
            {
              amount = 1,
              name = "quartz-chunk",
              probability = 0.05
            },
            {
              amount = 1,
              name = "tin-ore-chunk",
              probability = 0.13
            },
            {
              amount = 1,
              name = "lead-ore-chunk",
              probability = 0.45
            },
            {
              amount = 1,
              name = "gold-ore-chunk",
              probability = 0.05
            },
            {
              amount = 2,
              name = "bauxite-ore-chunk",
              probability = 0.06
            }
        }
        processmixed.expensive.results = { -- 3305 chunks expected
            {
              amount = 2,
              name = "iron-ore-chunk",
              probability = 0.1
            },
            {
              amount = 2,
              name = "copper-ore-chunk",
              probability = 0.6
            },
            {
              amount = 1,
              name = "coal-chunk",
              probability = 1
            },
            {
              amount = 2,
              name = "stone-chunk",
              probability = 0.03
            },
            {
              amount = 1,
              name = "quartz-chunk",
              probability = 0.08
            },
            {
              amount = 1,
              name = "tin-ore-chunk",
              probability = 0.18
            },
            {
              amount = 1,
              name = "lead-ore-chunk",
              probability = 0.045
            },
            {
              amount = 1,
              name = "gold-ore-chunk",
              probability = 0.1
            },
            {
              amount = 2,
              name = "bauxite-ore-chunk",
              probability = 0.22
            }
        }
        normal = { -- Gives 2100 chunks on average
            {
              amount = 3,
              probability = 0.7
            }
        }
        expensive = { -- Gives 3000 chunks on average
            {
              amount_min = 2,
              amount_max = 4,
              probability = 1
            }
        }
        return normal, expensive
    --Without Modules : 1900 Quartz, 1400 stone, 40800 Copper, 10400 Coal, 12048 tin, 3818 Galena, 1000 Gold, 2140 Iron Ore, 0 Bauxite
    --Without Modules : 4000 Quartz, 3500 Stone, 50500 Copper, 33125 Coal, 18515 Tin, 3818 Galena, 1000 Gold, 4700 Iron Ore, 
    elseif mods["bobplates"] and mods["bobelectronics"] then
        processmixed.normal.results = { -- 3350 chunks expected
            {
              amount = 1,
              name = "iron-ore-chunk",
              probability = 0.1
            },
            {
              amount = 4,
              name = "copper-ore-chunk",
              probability = 0.45
            },
            {
              amount = 2,
              name = "coal-chunk",
              probability = 0.25
            },
            {
              amount = 1,
              name = "stone-chunk",
              probability = 0.08
            },
            {
              amount = 1,
              name = "quartz-chunk",
              probability = 0.09
            },
            {
              amount = 1,
              name = "tin-ore-chunk",
              probability = 0.55
            },
            {
              amount = 1,
              name = "lead-ore-chunk",
              probability = 0.18
            },
            {
              amount = 1,
              name = "gold-ore-chunk",
              probability = 0.05
            }
        }
        processmixed.expensive.results = { -- 5580 chunks expected
            {
              amount = 2,
              name = "iron-ore-chunk",
              probability = 0.1
            },
            {
              amount_min = 1,
              amount_max = 4,
              name = "copper-ore-chunk",
              probability = 1
            },
            {
              amount_min = 1,
              amount_max = 2,
              name = "coal-chunk",
              probability = 1
            },
            {
              amount = 1,
              name = "stone-chunk",
              probability = 0.16
            },
            {
              amount = 2,
              name = "quartz-chunk",
              probability = 0.09
            },
            {
              amount = 3,
              name = "tin-ore-chunk",
              probability = 0.27
            },
            {
              amount = 1,
              name = "lead-ore-chunk",
              probability = 0.18
            },
            {
              amount = 1,
              name = "gold-ore-chunk",
              probability = 0.05
            }
        }
        normal = { -- Gives 3000 chunks on average
            {
              amount_min = 1,
              amount_max = 5,
              probability = 1
            }
        }
        expensive = { -- Gives 5400 chunks on average
            {
              amount_min = 5,
              amount_max = 7,
              probability = 0.9
            }
        }
        return normal, expensive
    --Without Electron: 0 Quartz, 0 stone, 75050 Copper, 9375 Coal, 1250 tin, 0 Galena, 800 Gold, 32225 Iron Ore, 5000 Bauxite
    --Without Electron: 0 Quartz, 0 stone, 174833 Copper, 30750 Coal, 1500 tin, 0 Galena, 1333 Gold, 70350 Iron, 10000 Bauxite
    elseif mods["bobplates"] and mods["bobmodules"] then
        processmixed.normal.results = { -- 6050 chunks expected
            {
              amount = 4,
              name = "iron-ore-chunk",
              probability = 0.4
            },
            {
              amount = 6,
              name = "copper-ore-chunk",
              probability = 0.6
            },
            {
              amount = 2,
              name = "coal-chunk",
              probability = 0.25
            },
            {
              amount = 1,
              name = "tin-ore-chunk",
              probability = 0.07
            },
            {
              amount = 1,
              name = "gold-ore-chunk",
              probability = 0.04
            },
            {
              amount = 2,
              name = "bauxite-ore-chunk",
              probability = 0.12
            }
        }
        processmixed.expensive.results = { -- 12570 chunks expected
            {
              amount = 3,
              name = "iron-ore-chunk",
              probability = 1
            },
            {
              amount_min = 6,
              amount_max = 9,
              name = "copper-ore-chunk",
              probability = 1
            },
            {
              amount = 12,
              name = "coal-chunk",
              probability = 0.12
            },
            {
              amount = 1,
              name = "tin-ore-chunk",
              probability = 0.08
            },
            {
              amount = 1,
              name = "gold-ore-chunk",
              probability = 0.07
            },
            {
              amount = 4,
              name = "bauxite-ore-chunk",
              probability = 0.12
            }
        }
        normal = { -- Gives 5500 chunks on average
            {
              amount_min = 4,
              amount_max = 7,
              probability = 1
            }
        }
        expensive = { -- Gives 12000 chunks on average
            {
              amount_min = 10,
              amount_max = 14,
              probability = 1
            }
        }
        return normal, expensive
    --Without Metals  : 0 Quartz, 0 stone, 27250 Copper, 5600 Coal, 0 tin, 0 Galena, 0 Gold, 15265 iron ore
    --Without Metals  : 0 quartz, 0 stone, 32833 copper, 22000 coal, 0 tin, 0 galena, 0 gold, 30350 iron
    elseif mods["bobmodules"] and mods["bobelectronics"] then
        processmixed.normal.results = { -- 2600 chunks expected
            {
              amount = 4,
              name = "iron-ore-chunk",
              probability = 0.2
            },
            {
              amount = 6,
              name = "copper-ore-chunk",
              probability = 0.25
            },
            {
              amount = 2,
              name = "coal-chunk",
              probability = 0.15
            }
        }
        processmixed.expensive.results = { -- 4000 chunks expected
            {
              amount_min = 0,
              amount_max = 3,
              name = "iron-ore-chunk",
              probability = 1
            },
            {
              amount_min = 0,
              amount_max = 3,
              name = "copper-ore-chunk",
              probability = 1
            },
            {
              amount = 1,
              name = "coal-chunk",
              probability = 1
            }
        }
        normal = { -- Gives 2500 chunks on average
            {
              amount_min = 2,
              amount_max = 3,
              probability = 1
            }
        }
        expensive = { -- Gives 3600 chunks on average
            {
              amount_min = 3,
              amount_max = 5,
              probability = 0.9
            }
        }
        return normal, expensive
    --Without Either  : 0 Quartz, 0 stone, 92500 Copper, 9500 Coal, 0 tin, 0 Galena, 0 Gold, 41100 Iron Ore
    --Without Either  : 0 Quartz, 0 stone, 204000 Copper, 29000 Coal, 0 tin, 0 galena, 0 Gold, 82200 iron
    elseif mods["bobplates"] then
        processmixed.normal.results = { -- 6110 chunks expected
            {
              amount = 4,
              name = "iron-ore-chunk",
              probability = 0.45
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
        }
        processmixed.expensive.results = { -- 14000 chunks expected
            {
              amount_min = 3,
              amount_max = 4,
              name = "iron-ore-chunk",
              probability = 1
            },
            {
              amount = 9,
              name = "copper-ore-chunk",
              probability = 1
            },
            {
              amount_min = 0,
              amount_max = 3,
              name = "coal-chunk",
              probability = 1
            }
        }
        normal = { -- Gives 6000 chunks on average
            {
              amount_min = 5,
              amount_max = 7,
              probability = 1
            }
        }
        expensive = { -- Gives 13000 chunks on average
            {
              amount_min = 11,
              amount_max = 15,
              probability = 1
            }
        }
        return normal, expensive
    end
end
