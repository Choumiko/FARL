local copyPrototype = require "__FARL__/lib"
local farl = copyPrototype("locomotive", "locomotive", "farl")
farl.icon = "__FARL__/graphics/icons/farl.png"
farl.max_speed = 0.8
farl.burner.fuel_inventory_size = 4

farl.color = {r = 1, g = 0.80, b = 0, a = 0.8}
--farl.color = {r = 0.8, g = 0.40, b = 0, a = 0.8}
data:extend({farl})

data:extend({
    {
        type = "flying-text",
        name = "flying-text2",
        flags = {"not-on-map"},
        time_to_live = 150,
        speed = 0.0
    }})
