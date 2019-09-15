for _, force in pairs(game.forces) do
    local recipes = force.recipes
    if recipes["rail-signal"].enabled then
        if settings.startup.farl_enable_module.value then
            recipes["farl-roboport"].enabled = true
        end
        recipes["farl"].enabled = true
    end
end
