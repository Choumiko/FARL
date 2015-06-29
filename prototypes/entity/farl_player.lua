farlEmptyAnimations =       { filename = "__FARL__/graphics/trans1.png",
  priority = "medium",
  width = 0,
  height = 0,
  direction_count = 1,
  frame_count = 1,
  animation_speed = 0.15,
  shift = {0, 0},
  axially_symmetrical = true
}

farlEmptyLevel = {
  idle = farlEmptyAnimations,
  idle_mask = farlEmptyAnimations,
  idle_with_gun = farlEmptyAnimations,
  idle_with_gun_mask = farlEmptyAnimations,
  mining_with_hands = farlEmptyAnimations,
  mining_with_hands_mask = farlEmptyAnimations,
  mining_with_tool = farlEmptyAnimations,
  mining_with_tool_mask = farlEmptyAnimations,
  running_with_gun = farlEmptyAnimations,
  running_with_gun_mask = farlEmptyAnimations,
  running = farlEmptyAnimations,
  running_mask = farlEmptyAnimations
}

farlAnimations =
  {
    level1 = farlEmptyLevel,
    level2addon = farlEmptyLevel,
    level3addon = farlEmptyLevel
  }

local player = copyPrototype("player", "player", "farl_player")
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
player.animations = farlAnimations
player.mining_speed = 0
data:extend({player})