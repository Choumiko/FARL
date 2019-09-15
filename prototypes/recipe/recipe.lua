if not mods["IndustrialRevolution"] then
    data:extend(
        {
            {
                type = "recipe",
                name = "farl",
                enabled = "false",
                ingredients =
                {
                    {"locomotive", 1},
                    {"long-handed-inserter", 2},
                    {"steel-plate", 5},
                },
                result = "farl"
            }
        })
else
    data:extend(
        {
            {
                type = "recipe",
                name = "farl",
                enabled = "false",
                ingredients =
                {
                    {"locomotive", 1},
                    {"long-handed-inserter", 2},
                    {"iron-plate-heavy", 5},
                },
                result = "farl"
            }
        })
end
