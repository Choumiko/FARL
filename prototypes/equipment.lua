data:extend
  {
    {
      type = "equipment-category",
      name = "farl-equipment"
    },
    {
      type = "equipment-grid",
      name = "farl-equipment-grid",
      width = 2,
      height = 2,
      equipment_categories = {"farl-equipment"},
    },--[[
    {
      type = "equipment-grid",
      name = "farl-equipment-grid-wagon",
      width = 8,
      height = 8,
      equipment_categories = {"farl-equipment", "armor"},
    },]]--
}

if not data.raw["item-subgroup"]["electric-vehicles-equipment"] then
  data:extend
    {
      {
        type = "item-subgroup",
        name = "electric-vehicles-equipment",
        group = "combat",
        order = "g"
      },
  }
end

local farlRoboport =  copyPrototype("roboport-equipment", "personal-roboport-equipment", "farl-roboport", true)
farlRoboport.energy_consumption = "0W"
--farlRoboport.robot_limit = 50
farlRoboport.robot_limit = 0
--farlRoboport.charging_station_count = 10
--farlRoboport.construction_radius = 30
farlRoboport.construction_radius = 0
farlRoboport.categories = {"farl-equipment"}

local farlRoboportRecipe = copyPrototype("recipe", "personal-roboport-equipment", "farl-roboport", true)


local farlRoboportItem = copyPrototype("item", "personal-roboport-equipment", "farl-roboport", true)
farlRoboportItem.subgroup = "electric-vehicles-equipment"
farlRoboportItem.order = "f"
farlRoboportItem.icon = "__FARL__/graphics/icons/farl-roboport.png"

data:extend{farlRoboport, farlRoboportItem, farlRoboportRecipe}
