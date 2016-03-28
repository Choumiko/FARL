function copyPrototype(type, name, newName, change_results)
  if not data.raw[type][name] then error("type "..type.." "..name.." doesn't exist") end
  local p = table.deepcopy(data.raw[type][name])
  p.name = newName
  if p.minable and p.minable.result then
    p.minable.result = newName
  end
  if change_results then
    if p.place_result then
      p.place_result = newName
    end
    if p.result then
      p.result = newName
    end
  end
  return p
end