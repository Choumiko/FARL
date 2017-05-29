function copyPrototype(type, name, newName, change_results) --luacheck: allow defined top
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
        if p.take_result then
            p.take_result = newName
        end
        if p.placed_as_equipment_result then
            p.placed_as_equipment_result = newName
        end
    end
    return p
end

farl_railpictures = function() --luacheck: allow defined top
    local elems = {{"metals", "metals"}, {"backplates", "backplates"}, {"ties", "ties"}, {"stone_path", "stone-path"}}
    local keys = {
        {"straight_rail", "horizontal", 64, 64},
        {"straight_rail", "vertical", 64, 64},
        {"straight_rail", "diagonal", 64, 64},
        {"curved_rail", "vertical", 128, 256},
        {"curved_rail" ,"horizontal", 256, 128}}
    local res = {}
    for _ , key in ipairs(keys) do
        local part = {}
        local dashkey = key[1]:gsub("_", "-")
        for _ , elem in ipairs(elems) do
            part[elem[1]] = {
                filename = (elem[1] == "metals") and string.format("__FARL__/graphics/entity/rail/%s-%s-%s.png", dashkey, key[2], elem[2])
                or string.format("__FARL__/graphics/entity/rail/%s-%s-blank.png", dashkey, key[2]),
                priority = "extra-high",
                width = key[3],
                height = key[4]
            }
        end
        res[key[1] .. "_" .. key[2]] = part
    end
    res["rail_endings"] = {
        sheet =
        {
            filename = "__FARL__/graphics/entity/rail/rail-endings.png",
            priority = "high",
            width = 88,
            height = 82
        }
    }
    return res
end

return copyPrototype, farl_railpictures
