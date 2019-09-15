local Position = require 'Position'

local M = {}

function M.saveVar(var, name)
    var = var or global
    local n = name or ""
    game.write_file("farl"..n..".lua", serpent.block(var, {name="glob"}))
end

function M.debugDump(var, force)
    if false or force then
        local msg
        if type(var) == "string" then
            msg = var
        else
            msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
        end
        for _,player in pairs(game.players) do
            player.print(msg)
        end
        local tick = game and game.tick or 0
        log(tick .. " " .. msg)
    end
end

function M.log2(v, description)
    if not description then
        local info = debug.getinfo(2, "l")
        description = info and info.currentline
    end
    v = type(v) == "table" and serpent.line(v) or v
    log(string.format("%s: %s", description or "undesc", tostring(v)))
end

function M.debugLog(var, prepend)
    if not global.debug_log then return end
    local str = prepend or ""
    for _,player in pairs(game.players) do
        local msg
        if type(var) == "string" then
            msg = var
        else
            msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
        end
        player.print(str..msg)
        log(str..msg)
    end
end

function M.startsWith(haystack,needle)
    return string.sub(haystack,1,string.len(needle))==needle
end

function M.endsWith(haystack,needle)
    return needle=='' or string.sub(haystack,-string.len(needle))==needle
end

local dir = defines.direction
M._diagonal_data = {
    [dir.northeast] = { x = 0.5, y = -0.5 },
    [dir.southeast] = { x = 0.5, y = 0.5 },
    [dir.southwest] = { x = -0.5, y = 0.5 },
    [dir.northwest] = { x = -0.5, y = -0.5 }
    }

function M.diagonal_to_real_pos(rail)
    if rail.type == "straight-rail" or rail.name == "straight-rail" then
        local off = M._diagonal_data[rail.direction] or { x = 0, y = 0 }
        return Position.add(off, rail.position)
    else
        return {x = rail.position.x, y = rail.position.y}
    end
end

function M.real_to_diagonal_pos(rail)
    if rail.type == "straight-rail" or rail.name == "straight-rail" then
        local off = M._diagonal_data[rail.direction] or { x = 0, y = 0 }
        return Position.subtract(rail.position, off)
    else
        return {x = rail.position.x, y = rail.position.y}
    end
end

local floor = math.floor
function M.round(num, idp)
    local mult = 10 ^ (idp or 0)
    return floor(num * mult + 0.5) / mult
end

function M.round_to_int(num)
    return floor(num + 0.5)
end

function M.find_key(tbl, n)
    for name, v in pairs(tbl) do
        if v == n then return name end
    end
end

function M.position_hash(x, y, d)
    return ((1000000 + x) * 100000000) + ((1000000 + y) * 100) + d
end

function M.position_hash2(ent)
    local pos = ent.position
    return M.position_hash(pos.x, pos.y, ent.direction or 0)
end

function M.create_set(...)
    local t = table.pack(...)
    local ret = {}
    for _, s in pairs(t) do
        ret[s] = true
    end
    return ret
end

-- https://github.com/dewiniaid/BlueprintExtensions/blob/master/modules/snap.lua
local box_rotations = {
    [dir.north] = { 1, 2, 3, 4 },
    [dir.northeast] = { 3, 2, 1, 4 },
    [dir.east] = { 4, 1, 2, 3 },
    [dir.southeast] = { 2, 1, 4, 3 },
    [dir.south] = { 3, 4, 1, 2 },
    [dir.southwest] = { 1, 4, 3, 2 },
    [dir.west] = { 2, 3, 4, 1 },
    [dir.northwest] = { 4, 3, 2, 1 },
}

local function update_bounding_box(box, pos, min_x, min_y, max_x, max_y)--luacheck: no unused
    min_x = pos.x + min_x
    min_y = pos.y + min_y
    max_x = pos.x + max_x
    max_y = pos.y + max_y
    if not box.left_top then
        box.left_top = {x = min_x, y = min_y}
        box.right_bottom = {x = max_x, y = max_y}
        return
    end
    local lt = box.left_top
    local rb = box.right_bottom

    lt.x = min_x < lt.x and min_x or lt.x
    lt.y = min_y < lt.y and min_y or lt.y

    rb.x = max_x > rb.x and max_x or rb.x
    rb.y = max_y > rb.y and max_y or rb.y
end

function M.rotate_bounding_box(sel_box, direction, box, pos)
    if not sel_box then return end
    local rot = box_rotations[direction or 0]
    local rect = {false, false, false, false}
    rect[1] = sel_box.left_top.x
    rect[2] = sel_box.left_top.y
    rect[3] = sel_box.right_bottom.x
    rect[4] = sel_box.right_bottom.y
    -- print("\n")
    -- log2(sel_box, "Sel_box")
    -- log2(direction, "dir")
    local x1, y1 = rect[rot[1]], rect[rot[2]]
    local x2, y2 = rect[rot[3]], rect[rot[4]]
    -- log2({x1,y1,x2,y2}, "rotated")
    --swap tl and rb
    if x1 > x2 then
        x1, x2 = -x1, -x2
    end
    sel_box.left_top.x = x1
    sel_box.right_bottom.x = x2
    if y1 > y2 then
        y1, y2 = -y1, -y2
    end
    -- log2({x1,y1,x2,y2}, "rotated2")
    sel_box.left_top.y = y1
    sel_box.right_bottom.y = y2
    if pos then
        update_bounding_box(box, pos, x1, y1, x2, y2)
    end
    return sel_box
end

return M