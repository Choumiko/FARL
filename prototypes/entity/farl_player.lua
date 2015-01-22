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


data:extend({

    {
      type = "player",
      name = "farl_player",
      icon = "__base__/graphics/icons/player.png",
      flags = {"pushable", "placeable-player", "placeable-off-grid", "not-repairable", "not-on-map"},
      max_health = 100,
      healing_per_tick = 100,
      collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
      collision_mask = {"ghost-layer"},
      --selection_box = {{-0.4, -1.4}, {0.4, 0.2}},
      crafting_categories = {"crafting"},
      mining_categories = {"basic-solid"},
      inventory_size = 0,
      running_speed = 0,
      distance_per_frame = 0,
      maximum_corner_sliding_distance = 0.7,
      subgroup = "creatures",
      order="z",
      eat =
      {
        {
          filename = "__base__/sound/eat.ogg",
          volume = 1
        }
      },
      heartbeat =
      {
        {
          filename = "__base__/sound/heartbeat.ogg"
        }
      },
      animations = farlAnimations,
      mining_speed = 0,
      mining_with_hands_particles_animation_positions = {0, 0},
      mining_with_tool_particles_animation_positions = {0},
      running_sound_animation_positions = {0, 0}
    }
})
