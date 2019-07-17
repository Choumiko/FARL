local render = require("render")
local colors = render.colors

local M = {}

function M.create_rails(test, surface)
    test.created_entities = {rails = {}, signals = {}}
    local create = surface.create_entity
    for c, ents in pairs(test.to_create) do
        for k, ent in pairs(ents) do
            test.created_entities[c][k] = create(ent)
        end
    end
end

function M.setup(test)
    return test.create_rails()
end

function M.teardown(test)
    for _, category in pairs(test.created_entities) do
        for _, ent in pairs(category) do
            if ent and ent.valid then
                ent.destroy()
            end
        end
    end
    test.created_entities = nil
end

local failure_opts = {square = false, ttl = 1200}

local function expect_equal(expected, result, msg)
    if expected == result then
        render.mark_entity(expected, colors.green, "S")
        --log("")
        --log(tostring(expected) .. " == " .. tostring(result))
        return true
    else
        log(msg)
        log("E: " .. serpent.line(expected) .. " " .. tostring(expected))
        log("R: " .. serpent.line(result) .. " " .. tostring(result))
        render.mark_entity(expected, colors.red, "Expected", failure_opts)
        render.mark_entity(result, colors.red, "Got", failure_opts)
        game.print(msg)
        return false
    end
end

function M.test_case(case, fnc)
    --log(serpent.line(case))
    local loco = case.locomotive
    if not loco then
        log("----Loco not created")
        return
    end
    local rail, signal = fnc(loco)
    if M.halt then
        M.halt = nil
        return false
    end
    local success = true
    success = expect_equal(case.e_rail, rail, "Wrong rail") and success
    --log(serpent.block(case))
    if rail then
        success = expect_equal(case.e_signal, signal, "Wrong signal") and success
    else
        success = expect_equal(type(signal), "string", "Expected error message") and success
    end
    render.mark_entity(loco, success and colors.green or colors.red, "")

    return success
end

function M.run(startup, fnc)
    local surface = game.get_surface(1)
    for i, test in pairs(startup) do
        log("---\t" .. test.name .. "\t---")
        test.create_rails(surface)
        log(serpent.block(test.created_entities))
        for j, tc in pairs(test.cases) do
            log("Test case" .. j)
            test.init(j, surface)
            if not M.test_case(tc, fnc) then
                game.print("Failures")
                return
            end
            tc.locomotive.destroy()
        end
        M.teardown(test)
    end
    rendering.clear("FARL")
end

return M
