require "__FARL__/lib"

--local fake_item = copyPrototype("item", "rail-signal", "fake-signal")
--table.insert(fake_item.flags, "hidden")

--local fake_signal = copyPrototype("rail-signal", "rail-signal", "fake-signal")
--fake_signal.minable.result = nil
--fake_signal.order = "a"
--fake_signal.collision_box = {{-0.0, -0.0}, {0.0, 0.0}}
--fake_signal.building_collision_box = {{-0.0, -0.0}, {0.0, 0.0}}
--fake_signal.animation.filename = "__FARL__/graphics/trans1.png"
--fake_signal.animation.width=0
--fake_signal.animation.height=0
--fake_signal.green_light=nil
--fake_signal.orange_light=nil
--fake_signal.red_light=nil

--data:extend({fake_item, fake_signal})
require("__FARL__/prototypes/equipment")
require("__FARL__/prototypes/entity/entities")
require("__FARL__/prototypes/entity/farl_player")
require("__FARL__/prototypes/item/item")
require("__FARL__/prototypes/recipe/recipe")
require("__FARL__/prototypes/styles")

if not data.raw["custom-input"] or not data.raw["custom-input"]["toggle-train-control"] then
    data:extend({
        {
            type = "custom-input",
            name = "toggle-train-control",
            key_sequence = "J"
        }
    })
end
