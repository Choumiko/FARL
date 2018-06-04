local prefix = "farl_"
data:extend({
    {
        type = "bool-setting",
        name = prefix .. "display_messages",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "a"
    },
    {
        type = "bool-setting",
        name = prefix .. "enable_module",
        setting_type = "startup",
        default_value = true,
        order = "a"
    },
    {
        type = "bool-setting",
        name = prefix .. "free_wires",
        setting_type = "runtime-global",
        default_value = false,
        order = "a"
    }
})
