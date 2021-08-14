function addsimple()
    if data.raw.item["SiSi-quartz"] then -- Simple Silicon Quartz
        addtype("SiSi-quartz", {a = 0.4, r = 200, g = 180, b = 200})
    end
end

function setmixed(processmixed)
    --Cost of a rocket: 49100 iron ore, 92500 copper ore,  9500 coal, 9000 quartz (18000 stone)
    --Cost of a rocket: 98200 iron ore, 204000 copper ore, 29000 coal, 14400 quartz (28800 stone)
    if mods["SimpleSilicon"] then
        log("Setting Si-Si mixed results")
        -- Since simple silicon just adds a single resource, we simply insert the needed materials to the
        -- results of mixed chunks. This lets it be used with other mods without crazy coding.
        -- 6910 total chunks expected with vanilla, adds 800 chunks
        table.insert(processmixed.normal.results, { 
          amount = 2,
          name = "stone-chunk",
          probability = 0.4
        })
        -- 15300 total chunks expected, adds 1300 chunks
        table.insert(processmixed.expensive.results, { 
          amount = 2,
          name = "stone-chunk",
          probability = 0.65
        })
        normal = { -- Gives 6500 chunks on average
            {
              amount_min = 5,
              amount_max = 8,
              probability = 1
            }
        }
        expensive = { -- Gives 14000 chunks on average
            {
              amount_min = 11,
              amount_max = 17,
              probability = 1
            }
        }
        return normal, expensive
    end
end