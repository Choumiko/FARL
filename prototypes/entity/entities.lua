local farl = copyPrototype("locomotive", "diesel-locomotive", "farl")
farl.icon = "__FARL__/graphics/icons/farl.png"
farl.max_speed = 0.8
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