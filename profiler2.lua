
local table_sort = table.sort
local string_rep = string.rep
local string_format = string.format
-- local string_len = string.len
-- local string_sub = string.sub
-- local string_gsub = string.gsub


--	Call
--		name (string)
--		calls (int)
--		profiler (LuaProfiler)
--		next (Array of Call)


local Profiler =
{
	--	Call
	CallTree = nil,
	IsRunning = false,
    _originals = nil,
}


local assert_raw = assert
function assert(expr, ...)--luacheck: ignore
	if not expr then
		Profiler.Stop(false, "Assertion failed")
	end
	assert_raw(expr, ...)
end
local error_raw = error
function error(...)--luacheck: ignore
	Profiler.Stop(false, "Error raised")
	error_raw(...)
end

function Profiler.Start(excludeCalledMs, tbl)
	if Profiler.IsRunning then
		return
	end
    Profiler.excludeCalledMs = excludeCalledMs
	Profiler.IsRunning = true
    Profiler._originals = Profiler._originals or {}
    Profiler.original_tbl = tbl

    Profiler.CallWall = {}

    Profiler.CallTree =
	{
		name = "root",
		calls = 1,
		profiler = game.create_profiler(),
		next = { },
	}


    --Array of Call
	local stack = { [0] = Profiler.CallTree  }
	local stack_count = 0

    local cw = Profiler.CallWall
    local activeCalls = {}


    --equivalent to sethook return
    local function _on_return(name, ...)
        --print(tostring(name) .. " returns")
        --print(activeCalls[name])
        if stack_count > 0 then
            stack[stack_count].profiler.stop()
            stack[stack_count] = nil
            stack_count = stack_count - 1
            --end
            if excludeCalledMs then
                stack[stack_count].profiler.restart()
            end
        end
        activeCalls[name] = activeCalls[name] - 1
        --if activeCalls[name] == 0 then
            --print("---------Stopped---------")
        cw[name].profiler.stop()
        return ...
    end

    --equivalent to sethook call
    local function _on_call(name, f)
        return function(...)
            --print("call " .. name)
            local prevCall = stack[stack_count]
			if excludeCalledMs then
				prevCall.profiler.stop()
			end

			local prevCall_next = prevCall.next
			if prevCall_next == nil then
				prevCall_next = { }
				prevCall.next = prevCall_next
			end

            local currCW = cw[name]
            local cwStartFunc
            if currCW == nil then
                currCW = {
                    name = name,
                    calls = 1,
                    profiler = game.create_profiler()
                }
                cw[name] = currCW
                activeCalls[name] = 1
                cwStartFunc = currCW.profiler.reset
            else
                currCW.calls = currCW.calls + 1
                activeCalls[name] = activeCalls[name] + 1
                cwStartFunc = currCW.profiler.restart
            end
			local currCall = prevCall_next[name]
			local profilerStartFunc
			if currCall == nil then
				currCall =
				{
					name = name,
					calls = 1,
					profiler = game.create_profiler(),
				}
				prevCall_next[name] = currCall
				profilerStartFunc = currCall.profiler.reset
			else
				currCall.calls = currCall.calls + 1
				profilerStartFunc = currCall.profiler.restart
			end

			stack_count = stack_count + 1
			stack[stack_count] = currCall

            cwStartFunc()
			profilerStartFunc()

            return _on_return(name, f(...))
        end
    end

    print("Decorating")
    local tbl_type = type(tbl)
    if tbl_type == "table" then
        for k, f in pairs(tbl) do
            if type(f) == "function" then
                local name = type(k) == "string" and k or tostring(f)
                --print(tostring(k) .. " " .. tostring(f))
                Profiler._originals[k] = f
                tbl[k] = _on_call(name, f)
            end
        end
    end
end

local function DumpTree(averageMs)--luacheck: no unused
	local function sort_Call(a, b)
		return a.calls > b.calls
	end
	local fullStr = { "" }
	local str = fullStr
	local line = 1

	local function recurse(curr, depth)

		local sort = { }
		local i = 1
		for k, v in pairs(curr) do
			sort[i] = v
			i = i + 1
		end
		table_sort(sort, sort_Call)

		for i = 1, #sort do--luacheck: ignore
			local call = sort[i]

			if line >= 19 then --Localised string can only have up to 20 parameters
				local newStr = { "" } --So nest them!
				str[line + 1] = newStr
				str = newStr
				line = 1
			end

			if averageMs then
				call.profiler.divide(call.calls)
			end

			str[line + 1] = string_format("\n%s%dx %s. %s ", string_rep("\t", depth), call.calls, call.name, averageMs and "Average" or "Total")
			str[line + 2] = call.profiler
			line = line + 2

			local next = call.next
			if next ~= nil then
				recurse(next, depth + 1)
			end
		end
	end
	if Profiler.CallTree.next ~= nil then
		recurse(Profiler.CallTree.next, 0)
		return fullStr
	end
	return "No calls"
end

function Profiler.Stop(averageMs, message)--luacheck: no unused args
	if not Profiler.IsRunning then
		return
	end
    Profiler.CallTree.profiler.stop()
    for k, f in pairs(Profiler._originals) do
        Profiler.original_tbl[k] = f
    end

    Profiler._originals = nil
    Profiler.original_tbl = nil

	local text = { "", "\n\n----------PROFILER DUMP----------\n", DumpTree(averageMs), "\n\n\n----------PROFILER STOPPED----------\n",
        "excludeCalledMs: ", tostring(Profiler.excludeCalledMs == true), " averageMs: ", tostring(averageMs == true),"\n",
        "Total profiled time: ", Profiler.CallTree.profiler, "\n"
    }
	if message ~= nil then
		text = { "", "Reason: " .. message .. "\n" }
	end
	log(text)
    log{ "", }

    for _, pr in pairs(Profiler.CallWall) do
        if averageMs then
				pr.profiler.divide(pr.calls)
        end
        log{"", string_format("\n%dx %s. %s ", pr.calls, pr.name, averageMs and "Average" or "Total"), pr.profiler}
    end

	Profiler.IsRunning = false
    Profiler.CallTree = nil
    Profiler.CallWall = nil
end

return Profiler