reccategory = "crafting" -- Recipe category for asteroid processing to use

-- If ev-refining is installed and crafting category for crushing exists, we'll use that for processing chunks
if settings.startup["astmine-evcrushing"] and data.raw["recipe-category"]["crushing1"] then
    reccategory = "crushing1"
end

-- If Krastorio2 is installed and crafting category for crushing exists, we'll use that for processing chunks
if settings.startup["astmine-k2crushing"].value and data.raw["recipe-category"]["kr-crushing"] then
    reccategory = "kr-crushing"
end

--If Angel's Crushing category exists and setting isn't off, use it for chunk crushing. This overrides K2.
if settings.startup["astmine-crushing"].value and data.raw["recipe-category"]["ore-sorting-t1"] then
    reccategory = "ore-sorting-t1"
end