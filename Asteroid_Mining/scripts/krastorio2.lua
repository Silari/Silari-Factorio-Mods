function addkras()
    if data.raw.item["kr-imersite"] then -- Krastorio 2 Imersite
        addtype("kr-imersite", {a = 0.4, r = 150, g = 0, b = 150})
    end
    if data.raw.item["kr-rare-metal-ore"] then -- Krastorio 2 (gold)
        addtype("kr-rare-metal-ore", {a = 0.4, r = 215, g = 175, b = 0})
    end
end

--KRAS2 Normal
--(enrichment means 1.5 ore plus 0.015 iron ore per plate (-4.16416 ore from dirty water))
--RF  - 1515 iron ore
--    - +3750 coal for light oil liquefaction + cracking for light oil - has 3700 petrol left over but sulfur costs aren't counted
--LDS - 15000 copper ore, 150 iron ore, 800 coal, 6060 iron ore, 2500 coal
--    - 6210 iron ore, 15000 copper ore, 3300 coal.
--    - +7800 coal for light oil liquefaction + cracking for petro
--RCU - 8700 iron ore, 21000 copper ore, 3250 coal, 13866 stone, 2250 rare
--    - +10140 coal for light oil liquefaction + cracking for petro
--Cost of a rocket: 16425 iron ore, 36000 copper ore, 6550/28240 coal, 13866 stone, 2250 rare
--Needed chunks:     684.375 iron chnk, 1500 copper chunk, 272.92/1176.66 coal, 577.75 stone, 93.75 rare
--Total needed chunks: 3128.795/4032.535
--Total chunks expected: not set - 4000 for resource specific miner

--KRAS2 Expensive
--(enrichment means 1.5 ore plus 0.015 iron ore per plate (-4.16416 ore from dirty water))
--RF  - 1515 iron ore
--    - +3750 coal for light oil liquefaction + cracking for light oil - has 3700 petrol left over but sulfur costs aren't counted
--LDS - 15000 copper ore, 150 iron ore, 800 coal, 6060 iron ore, 15000 coal
--    - 6210 iron ore, 15000 copper ore, 15800 coal.
--    - +47369 coal for light oil liquefaction + cracking for petro
--RCU - 45285 iron ore, 105000 copper ore, 5500 coal, 23466 stone, 4500 rare
--    - +17370 coal for light oil liquefaction + cracking for petro
--Cost of a rocket: 53010 iron ore, 120000 copper ore, 21300/89789 coal, 23466 stone, 4500 rare
--Needed chunks:     2208.75 iron chnk, 5000 copper chunk, 887.5/3741.21 coal, 977.75 stone, 187.5 rare
--Total needed chunks: 9261.5/12115.21
--Total chunks expected: not set - 12000 for resource specific miner

--eNrtW1Fv2jAQ/i95xlVYC4G+Tpo0aZWm7XGqkHEu4OHEqe3QMcR/3zkkBVo2QC3p0l6fGvvwfffdcT7HxzJIdTyag7FSZ8F10L0IL/pBJ7DFOOHCaSPBBtc/lkHGU8B5Gyc4K4UXXgZukftB6SDF0UrEaDEDx5ICVLDqBE6mYAVXONUPUUg7v2KA8l+Njgvh/EJ6/BOEW2vKjXbaD+5ZD4HJNFcykRAH184U0NkBgfoM3BXSQDziqS6ycvUYEpnhyHiBctVwp/7nuhuGocep85GCOSqp1hWKW4+0hrm67VQ4R/XU57Xh9eNHrRROeyarBROltfEQviCAx4bWHyvnPHAh81LoVAYEdzDRxlvnZZgp7cVnRJGv0SOmUUXUegS2cH9ba/bSYARkjk+g5KUTpFxMK+iPUc0M29V2KrQpN/FIyVSiExKuLIrfIDS1S9Ry9YT2SupvxKfl9Eis3RtuxG4qY1arzgns61+LCWSHrOMu1TafggGGX44YMstrPGd1wYNeKWrFYJ4BtiVOgQwNnkLMpNEZyxXadshom4JyMpuc1yXgbfbOSAqTcXESqjZyf8g+FEyldedORqUa3GV8KJTZ/XhQLWHdFgpDCgOLCxkT65RnKM9QxB/J+tPKtSJ//4pVGdzdzH8q69jVZuB7fT7wpj2wo2J76HSg9D3zBYd0C4bMoJcKAy9yTti/8vs8MRzPxXa0Gp6cP3HhZyEdK9TDKil2eQqytiUvoXOkh7aO12SfNg8qUqlIpUxDRepbyTMOQFGkN8q50DMim1I6pXRK6VQ6UulIeYbyTBsjHg2zDuNqzOm1QJOlI1PyrgD/0lgejnYtkQ2jBVj7/EzTu4gGw+2/7lV0eTWIulE4iAbRMIr6w95Vv+efhmH/Q++f3vLQjm15eGpGSxym5GTqmIcvDBczD56+K81QPwU+XxD1dMJtYfXT1D2jEcWRXYgo4oxWrMiQjhfsRtxZ9113JR5kgm4Yz3RgzgHPDmmtk4hv7ATxUNGdFPTsXropS1Qh4//XDY9AtsQjPJ7zTPjrXolbA+WhZl9jlLWKznwDMtH/qvTrNNcZ8mPJA01uxFKVpSidHJrh+67gxv0++HMTv4exRCpnmvklxkbVcSfkfQBb4oFJKUjx3tRribKDUPAxFfp0VfDG38EZboCl4BAh+0AppumryC36KeSpVZxaxSnqqfOEOk8o4qnDjfIM5RnKM2/yZv129QcoIeCh   -- Factory planner subfactories for the 3 rocket silo items
function setmixed(processmixed)
    if mods["Krastorio2"] then
        log("Setting Krastorio 2 results")
        normal = { -- Gives 4000 chunks on average
            {
              amount_min = 3,
              amount_max = 5,
              probability = 1,
              type = "item"
            }
        }
        return normal
    end
end