local copyPrototype = require "__FARL__/lib"
require("__FARL__/prototypes/styles")
require("__FARL__/prototypes/equipment")

local farl = copyPrototype("locomotive", "locomotive", "farl")
farl.icon = "__FARL__/graphics/icons/farl.png"
farl.icon_size = 32
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
    },
    {
        type = "item-with-entity-data",
        name = "farl",
        icon = "__FARL__/graphics/icons/farl.png",
        icon_size = 32,
        subgroup = "transport",
        order = "a[train-system]-fb[locomotive]",
        place_result = "farl",
        stack_size = 5
    },
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

local player = copyPrototype("character", "character", "farl_player")
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

local farl_tool = {
    type = "selection-tool",
    name = "farl_selection_tool",
    icon = "__base__/graphics/icons/upgrade-planner.png",
    icon_size = 32,
    subgroup = "tool",
    order = "c[automated-construction]-d[module-inserter]",
    stack_size = 1,
    stackable = false,
    selection_color = { r = 0, g = 1, b = 0 },
    alt_selection_color = { r = 0, g = 0, b = 1 },
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "entity",
    entity_filter_count = 30,
    tile_filter_count = 30,
    -- entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo", "item-request-proxy"},
    -- entity_filter_mode = "whitelist",
    -- alt_entity_filters = {"item-request-proxy"},
    -- alt_entity_filter_mode = "whitelist",
    show_in_library = true,
    localised_name = {"", "FARL tool"}
}

data:extend{farl_tool}

if not data.raw["custom-input"] or not data.raw["custom-input"]["toggle-train-control"] then
    data:extend({
        {
            type = "custom-input",
            name = "toggle-train-control",
            key_sequence = "J"
        }
    })
end

data:extend({
    {
        type = "custom-input",
        name = "farl_debug_test",
        key_sequence = "KP_MINUS"
    }
})
