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

local Position = {}
function Position.add(pos1, pos2)
    return { x = pos1.x + pos2.x, y = pos1.y + pos2.y}
end

function Position.subtract(pos1, pos2)
    return { x = pos1.x - pos2.x, y = pos1.y - pos2.y}
end

function Position.equals(pos1, pos2)
    return pos1.x == pos2.x and pos1.y == pos2.y
end

function Position.expand_to_area(pos, radius)
    if #pos == 2 then
        return { left_top = { x = pos[1] - radius, y = pos[2] - radius }, right_bottom = { x = pos[1] + radius, y = pos[2] + radius } }
    end
    return { left_top = { x = pos.x - radius, y = pos.y - radius}, right_bottom = { x = pos.x + radius, y = pos.y + radius } }
end

function Position.distance_squared(pos1, pos2)
    local axbx = pos1.x - pos2.x
    local ayby = pos1.y - pos2.y
    return axbx * axbx + ayby * ayby
end

function M.diagonal_to_real_pos(rail)
    if rail.type == "straight-rail" then
        local off = M._diagonal_data[rail.direction] or { x = 0, y = 0 }
        return Position.add(off, rail.position)
    else
        return rail.position
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

M.Position = Position
return M