if not settings.startup["farl_enable_module"].value then
    return
end
local copyPrototype = require "__FARL__/lib"
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

local farlRoboport =  copyPrototype("roboport-equipment", "personal-roboport-equipment", "farl-roboport", true)
farlRoboport.energy_consumption = "0W"
--farlRoboport.robot_limit = 50
farlRoboport.robot_limit = 0
farlRoboport.charging_station_count = 0
--farlRoboport.construction_radius = 30
farlRoboport.construction_radius = 0
farlRoboport.categories = {"farl-equipment"}

local farlRoboportRecipe = copyPrototype("recipe", "personal-roboport-equipment", "farl-roboport", true)
farlRoboportRecipe.ingredients = {
    {"iron-gear-wheel", 5},
    {"electronic-circuit", 5},
    {"steel-plate", 5},
}


local farlRoboportItem = copyPrototype("item", "personal-roboport-equipment", "farl-roboport", true)
farlRoboportItem.subgroup = "transport"
farlRoboportItem.order = "a[train-system]-fc[farl]"
farlRoboportItem.icon = "__FARL__/graphics/icons/farl-roboport.png"

data:extend{farlRoboport, farlRoboportItem, farlRoboportRecipe}
