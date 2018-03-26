table.insert(data.raw["technology"]["rail-signals"].effects,
    {
        type="unlock-recipe",
        recipe = "farl"
    })
if settings.startup["farl_enable_module"].value then
    table.insert(data.raw["technology"]["rail-signals"].effects,
    {
        type="unlock-recipe",
        recipe = "farl-roboport"
    })
end
