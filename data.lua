local copyPrototype = require "__FARL__/lib"

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
