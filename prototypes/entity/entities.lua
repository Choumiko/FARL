farlBacklight= rolling_stock_back_light()
--table.insert(farlBacklight,
--  {
--    minimum_darkness = 0.1,
--    color = {r = 0.8, g = 0.8},
--    shift = {1.5, 0},
--    size = 2,
--    intensity = 0.6
--  })

data:extend(
  {
    {
      type = "locomotive",
      name = "farl",
      icon = "__FARL__/graphics/icons/farl.png",
      flags = {"placeable-neutral", "player-creation", "placeable-off-grid", "not-on-map"},
      minable = {mining_time = 1, result = "farl"},
      max_health = 1000,
      corpse = "medium-remnants",
      dying_explosion = "huge-explosion",
      collision_box = {{-0.6, -2.6}, {0.6, 2.6}},
      selection_box = {{-0.85, -2.6}, {0.9, 2.5}},
      drawing_box = {{-1, -4}, {1, 3}},
      weight = 2000,
      max_speed = 1.2,
      max_power = "600kW",
      braking_force = 10,
      friction_force = 0.0015,
      -- this is a percentage of current speed that will be subtracted
      air_resistance = 0.002,
      connection_distance = 3.3,
      joint_distance = 4.6,
      energy_per_hit_point = 5,
      resistances =
      {
        {
          type = "fire",
          decrease = 15,
          percent = 50
        },
        {
          type = "physical",
          decrease = 15,
          percent = 30
        },
        {
          type = "impact",
          decrease = 50,
          percent = 60
        },
        {
          type = "explosion",
          decrease = 15,
          percent = 30
        },
        {
          type = "acid",
          decrease = 10,
          percent = 20
        }
      },
      energy_source =
      {
        type = "burner",
        effectivity = 1,
        fuel_inventory_size = 3,
        smoke =
        {
          {
            name = "smoke",
            deviation = {0.1, 0.1},
            frequency = 210,
            position = {0, 0},
            slow_down_factor = 3,
            starting_frame = 1,
            starting_frame_deviation = 5,
            starting_frame_speed = 0,
            starting_frame_speed_deviation = 5,
            height = 2,
            height_deviation = 0.2,
            starting_vertical_speed = 0.2,
            starting_vertical_speed_deviation = 0.06,
          }
        }
      },
      front_light =
      {
        {
          type = "oriented",
          minimum_darkness = 0.3,
          picture =
          {
            filename = "__core__/graphics/light-cone.png",
            priority = "medium",
            scale = 2,
            width = 200,
            height = 200
          },
          shift = {-0.6, -16},
          size = 2,
          intensity = 0.6
        },
        {
          type = "oriented",
          minimum_darkness = 0.3,
          picture =
          {
            filename = "__core__/graphics/light-cone.png",
            priority = "medium",
            scale = 2,
            width = 200,
            height = 200
          },
          shift = {0.6, -16},
          size = 2,
          intensity = 0.6
        }
      },
      back_light = farlBacklight,
      stand_by_light = rolling_stock_stand_by_light(),
      pictures =
      {
        priority = "very-low",
        width = 346,
        height = 248,
        axially_symmetrical = false,
        direction_count = 256,
        filenames =
        {
          "__FARL__/graphics/entity/farl/farl-01.png",
          "__FARL__/graphics/entity/farl/farl-02.png",
          "__FARL__/graphics/entity/farl/farl-03.png",
          "__FARL__/graphics/entity/farl/farl-04.png",
          "__FARL__/graphics/entity/farl/farl-05.png",
          "__FARL__/graphics/entity/farl/farl-06.png",
          "__FARL__/graphics/entity/farl/farl-07.png",
          "__FARL__/graphics/entity/farl/farl-08.png"
        },
        line_length = 4,
        lines_per_file = 8,
        shift = {0.9, -0.45}
      },
      rail_category = "regular",

      stop_trigger =
      {
        -- left side
        {
          type = "create-smoke",
          repeat_count = 125,
          entity_name = "smoke-train-stop",
          initial_height = 0,
          -- smoke goes to the left
          speed = {-0.03, 0},
          speed_multiplier = 0.75,
          speed_multiplier_deviation = 1.1,
          offset_deviation = {{-0.75, -2.7}, {-0.3, 2.7}}
        },
        -- right side
        {
          type = "create-smoke",
          repeat_count = 125,
          entity_name = "smoke-train-stop",
          initial_height = 0,
          -- smoke goes to the right
          speed = {0.03, 0},
          speed_multiplier = 0.75,
          speed_multiplier_deviation = 1.1,
          offset_deviation = {{0.3, -2.7}, {0.75, 2.7}}
        },
        {
          type = "play-sound",
          sound =
          {
            {
              filename = "__base__/sound/train-breaks.ogg",
              volume = 0.6
            },
          }
        },
      },
      drive_over_tie_trigger = drive_over_tie(),
      tie_distance = 50,
      crash_trigger = crash_trigger(),
      working_sound =
      {
        sound =
        {
          filename = "__base__/sound/train-engine.ogg",
          volume = 0.4
        },
        match_speed_to_activity = true,
      },
      open_sound = { filename = "__base__/sound/car-door-open.ogg", volume=0.7 },
      close_sound = { filename = "__base__/sound/car-door-close.ogg", volume = 0.7 },
      sound_minimum_speed = 0.5
    }
  })
