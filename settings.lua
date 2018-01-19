local prefix = "farl_"
data:extend({
    {
        type = "bool-setting",
        name = prefix .. "display_messages",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "a"
    }
})
