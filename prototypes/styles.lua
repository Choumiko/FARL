data:extend(
    {
        {
            type = "font",
            name = "farl-small",
            from = "default",
            size = 13
        },
        {
            type ="font",
            name = "farl-small-bold",
            from = "default-bold",
            size = 13
        }
    }
)

data.raw["gui-style"].default["farl_label"] =
    {
        type = "label_style",
        font = "farl-small",
        font_color = {r=1, g=1, b=1},
        top_padding = 0,
        bottom_padding = 0
    }

data.raw["gui-style"].default["farl_textfield"] =
    {
        type = "textbox_style",
        left_padding = 3,
        right_padding = 2,
        minimal_width = 60,
        font = "farl-small"
    }

data.raw["gui-style"].default["farl_textfield_small"] =
    {
        type = "textbox_style",
        left_padding = 3,
        right_padding = 2,
        minimal_width = 30,
        font = "farl-small"
    }
data.raw["gui-style"].default["farl_button"] =
    {
        type = "button_style",
        parent = "button",
        font = "farl-small-bold",
        minimal_height = 33,
        minimal_width = 33,
    }
data.raw["gui-style"].default["farl_checkbox"] =
    {
        type = "checkbox_style",
        parent = "checkbox",
        font = "farl-small",
    }

data:extend({
    {
        type="sprite",
        name="farl_settings",
        filename = "__FARL__/graphics/icons/settings.png",
        priority = "extra-high",
        width = 64,
        height = 64,
        scale = 0.5
    },
})
