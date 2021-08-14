--This shouldn't be necessary as recipes.lua redoes the recipes any time configuration changes
for index, force in pairs(game.forces) do
    local technologies = force.technologies
    local recipes = force.recipes
    for nindex, effect in pairs(technologies["rocket-silo"].effects) do
        --Set the recipe as researched.
        if effect.type == "unlock-recipe" then
            recipes[effect.recipe].enabled = technologies["rocket-silo"].researched
        end
    end
end