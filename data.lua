local copyPrototype = require "__FARL__/lib"

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

require("__FARL__/prototypes/item/item")
require("__FARL__/prototypes/recipe/recipe")
require("__FARL__/prototypes/styles")

local player_name = mods.base < '0.17.35' and "player" or "character" --TODO remove in a while
local player = copyPrototype(player_name, player_name, "farl_player")
player.healing_per_tick = 100
player.collision_mask = {"ghost-layer"}
player.inventory_size = 0
player.build_distance = 0
player.drop_item_distance = 0
player.reach_distance = 0
player.reach_resource_distance = 0
player.ticks_to_keep_gun = 0
player.ticks_to_keep_aiming_direction = 0
player.running_speed = 0
player.distance_per_frame = 0
player.mining_speed = 0
data:extend({player})

if not data.raw["custom-input"] or not data.raw["custom-input"]["toggle-train-control"] then
    data:extend({
        {
            type = "custom-input",
            name = "toggle-train-control",
            key_sequence = "J"
        }
    })
end
