for _, force in pairs(game.forces) do
  force.resetrecipes()
  force.resettechnologies()

  local techs = force.technologies
  local recipes = force.recipes
  if techs["rail-signals"].researched then
    recipes["farl"].enabled = true
  end
end