makesignals = true
require("data-updates") -- We repeat the process from updates here to catch EVERYTHING.

if settings.startup["astmine-miningprod"].value then     
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.astmineresource then
            log("Setting productivity for " .. recipe.name)
            table.insert(data.raw.technology["mining-productivity-1"].effects, {
              change = 0.01,
              recipe = recipe.name,
              type = "change-recipe-productivity"
            })
            table.insert(data.raw.technology["mining-productivity-2"].effects, {
              change = 0.01,
              recipe = recipe.name,
              type = "change-recipe-productivity"
            })
            table.insert(data.raw.technology["mining-productivity-3"].effects, {
              change = 0.01,
              recipe = recipe.name,
              type = "change-recipe-productivity"
            })
            if data.raw.technology["mining-productivity-4"] then
                table.insert(data.raw.technology["mining-productivity-4"].effects, {
                  change = 0.01,
                  recipe = recipe.name,
                  type = "change-recipe-productivity"
                })
            end
            if data.raw.technology["mining-productivity-6"] then
                log("Adding 6!")
                table.insert(data.raw.technology["mining-productivity-6"].effects, {
                  change = 0.01,
                  recipe = recipe.name,
                  type = "change-recipe-productivity"
                })
            end
            if data.raw.technology["mining-productivity-11"] then
                log("Adding 11!")
                table.insert(data.raw.technology["mining-productivity-11"].effects, {
                  change = 0.01,
                  recipe = recipe.name,
                  type = "change-recipe-productivity"
                })
            end
            if data.raw.technology["mining-productivity-16"] then
                log("Adding 16!")
                table.insert(data.raw.technology["mining-productivity-16"].effects, {
                  change = 0.01,
                  recipe = recipe.name,
                  type = "change-recipe-productivity"
                })
            end
        end
    end
end