local function saveVar(var, name)
    var = var or global
    local n = name or ""
    game.write_file("farl/farl"..n..".lua", serpent.block(var, {name="glob"}))
end

local function debugDump(var, force)
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
        log(debug.traceback())
        log(tick .. " " .. msg)
    end
end

local function debugLog(var, prepend)
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

local M = {
    saveVar = saveVar,
    debugDump = debugDump,
    debugLog = debugLog,
}

return M