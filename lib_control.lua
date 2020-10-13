local Position = require '__FARL__/stdlib/area/position'

local M = {}

function M.saveVar(var, name)
    var = var or global
    local n = name or ""
    game.write_file("farl/farl"..n..".lua", serpent.block(var, {name="glob"}))
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

M.diagonal_data = {
    [1] = { x = 0.5, y = -0.5 },
    [3] = { x = 0.5, y = 0.5 },
    [5] = { x = -0.5, y = 0.5 },
    [7] = { x = -0.5, y = -0.5 }
}

function M.diagonal_to_real_pos(rail)
    local data = M.diagonal_data
    if rail.type and rail.type == "straight-rail" then
        local off = data[rail.direction] and data[rail.direction] or { x = 0, y = 0 } --fix for diagonal rails??!
        return Position.add(off, rail.position)
    else
        return rail.position
    end
end

return M