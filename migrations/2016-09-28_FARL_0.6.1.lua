for _, force in pairs(game.forces) do
    force.reset_recipes()
    force.reset_technologies()

    local techs = force.technologies
    local recipes = force.recipes
    if techs["rail-signals"].researched then
        recipes["farl-roboport"].enabled = true
    end
end
