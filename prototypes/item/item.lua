data:extend(
  {
    {
      type = "item",
      name = "farl",
      icon = "__FARL__/graphics/icons/farl.png",
      flags = {"goes-to-quickbar"},
      subgroup = "transport",
      order = "a[train-system]-e[farl]",
      place_result = "farl",
      stack_size = 5
    },
    {
      type = "item",
      name = "farl-rail",
      icon = "__FARL__/graphics/icons/straight-rail.png",
      flags = {"goes-to-quickbar"},
      subgroup = "transport",
      order = "a[train-system]-b[farl-rail]",
      place_result = "farl-rail",
      stack_size = 50
    },
  })
