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
farlRoboport.energy_consumption = nil
--farlRoboport.robot_limit = 50
farlRoboport.robot_limit = 0
farlRoboport.charging_station_count = 0
--farlRoboport.construction_radius = 30
farlRoboport.construction_radius = 0
farlRoboport.categories = {"farl-equipment"}

local farlRoboportRecipe = copyPrototype("recipe", "personal-roboport-equipment", "farl-roboport", true)

if not mods["IndustrialRevolution"] then
    farlRoboportRecipe.ingredients = {
        {"iron-gear-wheel", 5},
        {"electronic-circuit", 5},
        {"steel-plate", 5},
    }
else
    farlRoboportRecipe.ingredients = {
        {"iron-gear-wheel", 5},
        {"electronic-circuit", 5},
        {"iron-plate-heavy", 5},
    }
end


local farlRoboportItem = copyPrototype("item", "personal-roboport-equipment", "farl-roboport", true)
farlRoboportItem.subgroup = "train-transport"
farlRoboportItem.order = "a[train-system]-j[farl]"
farlRoboportItem.icon = "__FARL__/graphics/icons/farl-roboport.png"
farlRoboportItem.icon_size = 32
farlRoboportItem.icon_mipmaps = 0

data:extend{farlRoboport, farlRoboportItem, farlRoboportRecipe}
