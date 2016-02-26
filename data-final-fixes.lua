require "lib"

local metarecipe = copyPrototype("recipe", "deconstruction-planner", "farl-meta")
metarecipe.ingredients = {}
metarecipe.enabled = true
metarecipe.hidden = false
local vanilla = {["small-electric-pole"]=true, ["medium-electric-pole"]=true, ["big-electric-pole"]=true, ["substation"]=true}

for name, _ in pairs(vanilla) do
  table.insert(metarecipe.ingredients, {name, data.raw["electric-pole"][name].maximum_wire_distance*10})
end

for _, ent in pairs(data.raw["electric-pole"]) do
  if ent.maximum_wire_distance and ent.maximum_wire_distance > 0 and not vanilla[ent.name] then
    table.insert(metarecipe.ingredients, {ent.name, ent.maximum_wire_distance*10})
  end
end
data:extend({metarecipe})