
function reset_recipes(changed)
    --If rocket_silo tech is researched, reset it's effects to ensure they're right
    --If it isn't researched, all of these should be disabled still, unless they were mucking around with commands.
    --log("Resetting recipes")
    for index, force in pairs(game.forces) do
        local technologies = force.technologies
        local recipes = force.recipes

        if technologies["rocket-silo"].researched then
            for nindex, effect in pairs(technologies["rocket-silo"].effects) do
                --Set the recipe as researched.
                if effect.type == "unlock-recipe" then
                    recipes[effect.recipe].enabled = true
                end
            end
        end
    end
end


script.on_configuration_changed(reset_recipes)