
--CHANGE TO BOBS PLATES. Ores alone isn't enough, none of the new ones are used without bobs metals
--Actually, if Ores OR Plates are installed the ores exist. They're not spawned without ores installed though
--And ores won't spawn them if nothing is set to use them, like Plates. So if EITHER is there lets make them.
function addbobs()
    if mods["bobores"] or mods["bobplates"] then
        --addtype("", {a = 0.4, r = 0, g = 0, b = 0})
        addtype("bob-bauxite-ore", {a = 0.4, r = 255, g = 255, b = 0})
        addtype("bob-cobalt-ore", {a = 0.4, r = 0, g = 0, b = 240})
        addtype("bob-gold-ore", {a = 0.4, r=255, g=215, b=0})
        addtype("bob-lead-ore", {a = 0.4, r = 10, g = 10, b = 10})
        addtype("bob-nickel-ore", {a = 0.4, r=46,g=139,b=100})
        addtype("bob-quartz", {a = 0.4, r = 250, g = 250, b = 250})
        addtype("bob-rutile-ore", {a = 0.4, r=90, g=0, b=90})
        addtype("bob-silver-ore", {a = 0.4, r = 128, g = 128, b = 144})
        addtype("bob-thorium-ore", {a = 0.4, r = 222, g = 255, b = 0})
        addtype("bob-tin-ore", {a = 0.4, r = 60, g = 60, b = 60})
        addtype("bob-tungsten-ore", {a = 0.4, r = 101, g = 67, b = 33})
        addtype("bob-zinc-ore", {a = 0.4, r=0,g=255,b=255})

        --Gem ores - may remove the mixed gems since it's much less useful
        --addtype("gem-ore", {a = 0.4, r = 0, g = 0, b = 0})
        addtype("bob-ruby-ore", {a = 0.4, r=255,g=105,b=180}) --r = 240, g = 10, b = 10})
        addtype("bob-sapphire-ore", {a = 0.4, r = 20, g = 20, b = 200})
        addtype("bob-emerald-ore", {a = 0.4, r=124,g=252,b=0}) --r = 20, g = 240, b = 20})
        addtype("bob-amethyst-ore", {a = 0.4, r=255,g=0,b=255})
        addtype("bob-topaz-ore", {a = 0.4, r = 200, g = 150, b = 0})
        addtype("bob-diamond-ore", {a = 0.4, r = 160, g = 160, b = 220})
    end
end

function setmixed(processmixed)
    if mods["bobrevamp"] or mods["bobplates"] then
        log("Setting bobs mixed results")
    end
    --None of bobtech,bobassembly,bobgreenhouse,boblogistics,bobpower,bobvehicleequipment,mining,module affect cost significantly. Mining has a MINOR effect on copper costs.
    -- NEW 2.0: 20000 bauxite, 13250 stone, 13000 quartz, 10475 coal, 10260 copper, 5879 tin, 3333 gold, 3055 galena, 2500 tungsten, 2000 rutile, 200 iron, 
    if mods["bobrevamp"] then -- DONE Assumes mods["bobplates"] and mods["bobelectronics"] 
        processmixed.results = { -- 3625 chunks expected from 1000 mixed chunks
            { -- 21000 baxuite, 875 chunks
              amount = 5,
              name = "bob-bauxite-ore-chunk",
              probability = 0.175,
              type = "item"
            },
            { -- 14040 stone, 585 chunk
              amount = 5,
              name = "stone-chunk",
              probability = 0.117,
              type = "item"
            },
            { -- 13320 quartz, 555 chunk
              amount = 5,
              name = "bob-quartz-chunk",
              probability = 0.111,
              type = "item"
            },
            { -- 10560 coal, 440 chunk
              amount = 4,
              name = "coal-chunk",
              probability = 0.11,
              type = "item"
            },
            { -- 10560 copper, 440 chunk
              amount = 4,
              name = "copper-ore-chunk",
              probability = 0.11,
              type = "item"
            },
            { -- 6000 tin, 250 chunks
              amount = 5,
              name = "bob-tin-ore-chunk",
              probability = 0.05,
              type = "item"
            }, 
            { -- 3480 gold, 145 chunks
              amount = 5,
              name = "bob-gold-ore-chunk",
              probability = 0.029,
              type = "item"
            },
            { -- 3120 lead, 130 chunks
              amount = 5,
              name = "bob-lead-ore-chunk",
              probability = 0.26,
              type = "item"
            },
            { -- 2640 tungsten, 110 chunks
              amount = 5,
              name = "bob-tungsten-ore-chunk",
              probability = 0.022,
              type = "item"
            },
            { -- 2040 rutile, 85 chunks.
              amount = 5,
              name = "bob-rutile-ore-chunk",
              probability = 0.17,
              type = "item"
            },
            { -- 240 iron, 10 chunk
              amount = 1,
              name = "iron-ore-chunk",
              probability = 0.01,
              type = "item"
            }
        }
        normal = { -- Gives 3260 chunks on average with 1000 chunk base asteroid
            {
              amount = 5,
              probability = 0.652,
              type = "item"
            }
        }
        return normal
    -- NEW 2.0 - 26600 copper, 4897 tin, 4800 coal, 4220 iron, 2036 galena, 1500 quartz, 1000 stone
    elseif mods["bobplates"] and mods["bobelectronics"] then -- DONE
        processmixed.results = { -- 1978 chunks expected
            { -- 4440 iron, 185 chunks
              amount = 5,
              name = "iron-ore-chunk",
              probability = 0.037,
              type = "item"
            },
            { -- 27600 copper, 1150 chunks
              amount = 10,
              name = "copper-ore-chunk",
              probability = 0.115,
              type = "item"
            },
            { -- 5280 coal, 220 chunks
              amount = 2,
              name = "coal-chunk",
              probability = 0.11,
              type = "item"
            },
            { -- 1080 stone, 45 chunks
              amount = 1,
              name = "stone-chunk",
              probability = 0.045,
              type = "item"
            },
            { -- 1632 quartz, 68 chunks
              amount = 4,
              name = "bob-quartz-chunk",
              probability = 0.017,
              type = "item"
            },
            { -- 5280 tin, 220 chunks
              amount = 2,
              name = "bob-tin-ore-chunk",
              probability = 0.11,
              type = "item"
            },
            { -- 2160 galena, 90 chunks
              amount = 5,
              name = "bob-lead-ore-chunk",
              probability = 0.018,
              type = "item"
            }
        }
        normal = { -- Gives 1800 chunks on average
            {
              amount_min = 1,
              amount_max = 3,
              probability = .98,
              type = "item"
            }
        }
        return normal
    --NEW 2.0 : 31600 Copper, 10220 iron ore, 8915 Coal
    elseif mods["bobelectronics"] then -- DONE
        processmixed.results = { -- 2250 chunks expected
            { -- 10800 iron, 450 chunks
              amount = 5,
              name = "iron-ore-chunk",
              probability = 0.09,
              type = "item"
            },
            { -- 33600 copper, 1400 chunks
              amount = 7,
              name = "copper-ore-chunk",
              probability = 0.2,
              type = "item"
            },
            { -- 9600 coal, 400 chunks
              amount = 4,
              name = "coal-chunk",
              probability = 0.1,
              type = "item"
            }
        }
        normal = { -- Gives 2000 chunks on average
            {
              amount_min = 2,
              amount_max = 2,
              probability = 1,
              type = "item"
            }
        }
        return normal
    -- Just plates, no changes  : 60000 Copper, 28100 Iron Ore, 4500 Coal
    elseif mods["bobplates"] then -- done
        -- We can just return the base game ones as it doesn't change the finite resource cost of the rocket
        return normal
    end
end
