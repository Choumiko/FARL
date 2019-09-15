local tech_name = "rail-signals"
if mods["IndustrialRevolution"] then
    tech_name = "automated-rail-transportation"
end

table.insert(data.raw["technology"][tech_name].effects,
    {
        type="unlock-recipe",
        recipe = "farl"
    })
if settings.startup["farl_enable_module"].value then
    table.insert(data.raw["technology"][tech_name].effects,
    {
        type="unlock-recipe",
        recipe = "farl-roboport"
    })
end
