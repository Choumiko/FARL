local farl = copyPrototype("locomotive", "diesel-locomotive", "farl")
farl.icon = "__FARL__/graphics/icons/farl.png"
farl.max_speed = 0.8
farl.energy_source.fuel_inventory_size = 4
farl.pictures.filenames =
  {
    "__FARL__/graphics/entity/farl/farl-01.png",
    "__FARL__/graphics/entity/farl/farl-02.png",
    "__FARL__/graphics/entity/farl/farl-03.png",
    "__FARL__/graphics/entity/farl/farl-04.png",
    "__FARL__/graphics/entity/farl/farl-05.png",
    "__FARL__/graphics/entity/farl/farl-06.png",
    "__FARL__/graphics/entity/farl/farl-07.png",
    "__FARL__/graphics/entity/farl/farl-08.png"
  }
data:extend({farl})

--local c_i = copyPrototype("item", "curved-rail", "farl-curved-rail", true)
--c_i.hidden = true
--local s_i = copyPrototype("item", "straight-rail", "farl-straight-rail", true)
--s_i.hidden = true
--data:extend({c_i, s_i})
--
--local straight_rail = copyPrototype("straight-rail", "straight-rail", "farl-straight-rail")
--table.insert(straight_rail.flags, "not-repairable")
--straight_rail.pictures = farl_railpictures()
--straight_rail.minable = {mining_time = 0}
--
--local curved_rail = copyPrototype("curved-rail", "curved-rail", "farl-curved-rail")
--table.insert(curved_rail.flags, "not-repairable")
--curved_rail.pictures = farl_railpictures()
--curved_rail.minable = {mining_time = 0}
--data:extend({curved_rail, straight_rail})


data:extend({
  {
    type = "flying-text",
    name = "flying-text2",
    flags = {"not-on-map"},
    time_to_live = 150,
    speed = 0.0
  }})
  
  data:extend({{
  type = "container",
  name = "farl_overlay",
  icon = "__FARL__/graphics/rm_Overlay.png",
  flags = {"placeable-neutral", "player-creation"},
  minable = {mining_time = 1, result = "raw-wood"},
  order = "b[rm_overlay]",
  collision_mask = {"resource-layer"},
  max_health = 100,
  corpse = "small-remnants",
  resistances ={{type = "fire",percent = 80}},
  collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  inventory_size = 1,
  picture =
  {
    filename = "__FARL__/graphics/rm_Overlay.png",
    priority = "extra-high",
    width = 32,
    height = 32,
    shift = {0.0, 0.0}
  }
}})
