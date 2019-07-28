librail.rail_data = {
    ["straight-rail"] = {
        [dir.north] = {chirality = 0,
            length = 2,
            travel_to_rd = {
                [dir.north] = rd.front,
                [dir.south] = rd.back
            },
            signals = {
                    [rd.front] = {
                        {x=1.5, y= 0.5, d=dir.south, stops=-1, starts=0},  -- Train stops 1 unit before this rail begins
                        {x=1.5, y=-0.5, d=dir.south, stops=1, starts=2}
                    },
                    [rd.back] = {
                        {x=-1.5, y=-0.5, d=dir.north, stops=-1, starts=0},
                        {x=-1.5, y= 0.5, d=dir.north, stops=1, starts=2},
                    },
            },
            next_rails = {
                [rd.front] = {
                    [rcd.left] = {type = "curved-rail", direction = dir.north, position = {x = -1, y = -5}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.north, position = {x = 0, y = -2}},
                    [rcd.right] = {type = "curved-rail", direction = dir.northeast, position = {x = 1, y = -5}}
                },
                [rd.back] = {
                    [rcd.left] = {type = "curved-rail", direction = dir.south, position = {x = 1, y = 5}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.north, position = {x = 0, y = 2}},
                    [rcd.right] = {type = "curved-rail", direction = dir.southwest, position = {x = -1, y = 5}}
                }
            },
        },
        [dir.east] = {chirality = 1,
            length = 2,
            travel_to_rd = {
                [dir.east] = rd.front,
                [dir.west] = rd.back
            },
        },
        [dir.northeast] = {chirality = 2,
            length = sqrt2,
            travel_to_rd = {
                [dir.northwest] = rd.front,
                [dir.southeast] = rd.back
            },
            signals = {
                [rd.front] = {{x=1.5, y=-1.5, d=dir.southeast, stops=-1, starts=1}},
                [rd.back] = {{x=-0.5, y=0.5, d=dir.northwest, stops=0, starts=1}},
            },
            next_rails = {
                [rd.front] = {
                    [rcd.left] = {type = "curved-rail", direction = dir.southeast, position = {x = -3, y = -3}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.southwest, position = {x = 0, y = -2}},
                    --?diagonals only have 2 possible connections, not sure how to handle that yet
                    --If we detect a right input, place the next diagonal track AND the curve or only the diagonal
                    --and do the curve in the next tick/step?
                    [rcd.right] = nil--{type = "curved-rail", direction = dir.northeast, position = {x = 1, y = -5}}
                },
                [rd.back] = {
                    [rcd.left] = nil, --{type = "curved-rail", direction = dir.south, position = {x = 1, y = 5}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.southwest, position = {x = 2, y = 0}},
                    [rcd.right] = {type = "curved-rail", direction = dir.north, position = {x = 3, y = 3}}
                }
            },
        },
        [dir.southwest] = {chirality = 1,
            length = sqrt2,
            -- travel_to_rd = {
                -- [dir.northwest] = rd.back,
                -- [dir.southeast] = rd.front
            -- }
        },
        [dir.northwest] = {chirality = 3,
            length = sqrt2,
            -- travel_to_rd = {
                -- [dir.southwest] = rd.front,
                -- [dir.northeast] = rd.back
            -- }
        },
        [dir.southeast] = {chirality = 0,
            length = sqrt2,
            -- travel_to_rd = {
            --     [dir.southwest] = rd.back,
            --     [dir.northeast] = rd.front
            -- }
        },
        --these two don't really exist
        [dir.south] = {chirality = 103,
            length = 2,
            -- travel_to_rd = {
            --     [dir.north] = rd.back,
            --     [dir.south] = rd.front
            -- }
        },
        [dir.west] = {chirality = 105,
            length = 2,
            -- travel_to_rd = {
                -- [dir.east] = rd.back,
                -- [dir.west] = rd.front
            -- }
        },
    },
    ["curved-rail"] = {
        [dir.north] = {chirality = 115,
            length = curve_length,
            travel_to_rd = {
                [dir.northwest] = rd.back,
                [dir.south] = rd.front
            },
            signals = {
                [rd.front] = {
                    {x=-2.5, y=-1.5, d=dir.northwest, stops=-1, starts=0},
                    {x=-0.5, y=3.5, d=dir.north, stops=curve_length-1, starts=curve_length}
                },
                [rd.back] = {
                    {x=2.5, y=3.5, d=dir.south, stops=-1, starts=0},
                    {x=-0.5, y=-3.5, d=dir.southeast, stops=curve_length-1, starts=curve_length}
                },
            },
            next_rails = {
                [rd.front] = {
                    [rcd.left] = {type = "curved-rail", direction = dir.south, position = {x = 2, y = 8}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.north, position = {x = 1, y = 5}},
                    [rcd.right] = {type = "curved-rail", direction = dir.southwest, position = {x = 0, y = 8}}
                },
                [rd.back] = {
                    [rcd.left] = nil, --{type = "curved-rail", direction = dir.south, position = {x = 1, y = 5}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.northeast, position = {x = -3, y = -3}},
                    [rcd.right] = {type = "curved-rail", direction = dir.south, position = {x = -4, y = -6}}
                }
            },
        },
        [dir.northeast] = {chirality = 3,
            length = curve_length,
            travel_to_rd = {
                [dir.northeast] = rd.back,
                [dir.south] = rd.front
            },
            signals = {
                [rd.front] = {
                    {x=0.5, y=-3.5, d=dir.northeast, stops=-1, starts=0},
                    {x=-2.5, y=3.5, d=dir.north, stops=curve_length-1, starts=curve_length},
                },
                [rd.back] = {
                    {x=0.5, y=3.5, d=dir.south, stops=-1, starts=0},
                    {x=2.5, y=-1.5, d=dir.southwest, stops=curve_length-1, starts=curve_length},
                },
            },
            next_rails = {
                [rd.front] = {
                    [rcd.left] = {type = "curved-rail", direction = dir.south, position = {x = 0, y = 8}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.north, position = {x = -1, y = 5}},
                    [rcd.right] = {type = "curved-rail", direction = dir.southwest, position = {x = -2, y = 8}}
                },
                [rd.back] = {
                    [rcd.left] = {type = "curved-rail", direction = dir.southwest, position = {x = 4, y = -6}},
                    [rcd.straight] = {type = "straight-rail", direction = dir.northwest, position = {x = 3, y = -3}},
                    [rcd.right] = nil
                }
            },
        },
        [dir.east] = {chirality = 109,
            length = curve_length,
            -- travel_to_rd = {
                -- [dir.northeast] = rd.back,
                -- [dir.west] = rd.front
            -- }
            },
        [dir.southeast] = {chirality = 2,
            length = curve_length,
            -- travel_to_rd = {
                -- [dir.west] = rd.front,
                -- [dir.southeast] = rd.back
            -- }
            },
        [dir.south] = {chirality = 0,
            length = curve_length,
            -- travel_to_rd = {
            --     [dir.southeast] = rd.back,
            --     [dir.north] = rd.front
            -- }
            },
        [dir.southwest] = {chirality = 0,
            length = curve_length,
            -- travel_to_rd = {
            --     [dir.southwest] = rd.back,
            --     [dir.north] = rd.front
            -- }
        },
        [dir.west] = {chirality = 1,
            length = curve_length,
            -- travel_to_rd = {
            --     [dir.southwest] = rd.back,
            --     [dir.east] = rd.front
            -- }
        },
        [dir.northwest] = {chirality = 1,
            length = curve_length,
            -- travel_to_rd = {
            --     [dir.northwest] = rd.back,
            --     [dir.east] = rd.front
            -- }
        },
    }
}

local function walk_to_branch2(rail, rail_direction)--luacheck:ignore
    rail_direction = rail_direction or rd.front
    local depth = 0
    local visited = {}
    local signals = {}
    --marked = {}
    local seg_length = rail.get_rail_segment_length()
    local length = seg_length
    --?: maybe skip jump_to_end if rail_segment_length == rail length
    local next_seg = jump_to_end(rail, opposite_rail_direction[rail_direction], round(length, 1))
    local next_direction = rail_direction

    local current_seg, out_dir = jump_to_end(next_seg, next_direction)--get the start end, can be the same as exit end
    if render.enabled then
        local test = jump_to_end(next_seg, opposite_rail_direction[next_direction])
        if (test ~= next_seg) then
            log("not equal")
            game.print("not equal")
        end
    end

    local _, s = has_rail_signals(current_seg, out_dir, next_seg, next_direction)--!current is further from the dead end, next_seg closer
    --?adjust length
    if s then
        length = length - s.signal_data.stops
        mark_signal(s.signal, colors.red, length, true)
        draw_line(game.players[1].character, s.signal, colors.black, true, true)
    end


    local get_connected_rail = current_seg.get_connected_rail
    local last = true
    local crs = 1
    for _, con_dir in pairs(rcd) do
        local tmp = get_connected_rail{
            rail_direction = out_dir,
            rail_connection_direction = con_dir
        }
        if tmp then
            local id = tmp.unit_number
            if visited[id] then
                game.print("Cycle detected 2")
                game.print(length)
                draw_line(game.players[1].character, tmp, colors.black, true, true)
                draw_line(game.players[1].character, current_seg, colors.red, true, true)
                return
            else
                visited[id] = true
                last = false
                draw_line(tmp, current_seg, colors.alternate[crs])
                crs = crs + 1
                _recurse(tmp, chiral_direction(current_seg, tmp)[out_dir], visited, depth, length, signals)
            end
        end
    end
    for _, data in pairs(signals) do
        log("Distance: " .. tostring(data.distance))
    end
    if last then
        mark_rail(current_seg, colors.red, round(length, 1))
    end
end


local function walk_to_signal(rail, rail_direction, prefer_straight)--luacheck:ignore
    --local seg_a, seg_a_dir = rail.get_rail_segment_end(rd.front)
    --local seg_b, seg_b_dir = rail.get_rail_segment_end(rd.back)
    --get_connected_rails(rail, rd.front)

    prefer_straight = prefer_straight or true
    local con_dirs = prefer_straight and {a = rcd.straight, b = rcd.left, c = rcd.right} or rcd
    rail_direction = rail_direction or rd.front
    marked = {}
    --profiler.Start()
    render.enabled = true
    mark_rail(rail, colors.green)
    local lps = 0
    local next_seg = jump_to_end(rail, opposite_rail_direction[rail_direction])
    mark_rail(next_seg, colors.green, "S")
    local next_direction = rail_direction
    local current_seg, out_dir
    --local seen_ends = {}
    local last_seen_seg_end
    for i = 1, 200 do
        --found = false
        lps = i
        current_seg, out_dir = jump_to_end(next_seg, next_direction)--get the start end, can be the same as exit end
        if render.enabled then
            local test = jump_to_end(next_seg, opposite_rail_direction[next_direction])
            if (test ~= next_seg) then
                log("not equal")
                game.print("not equal")
            end
        end
        -- if (current_seg == next_seg) then
        --     log("Single rail segment")
        --     draw_line(game.players[1].character, next_seg, colors.green, true, true)
        -- end
        if current_seg == last_seen_seg_end then
            game.print("Cycle detected")
            break
        end
        last_seen_seg_end = current_seg
        --render.enabled = false
        local f, s = has_rail_signals(current_seg, out_dir, next_seg, next_direction,  "s")--!current is further from the dead end, next_seg closer
        --render.enabled = true
        mark_signal(f, colors.green, lps, false)
        mark_signal(s, colors.red, lps, false)
        --render.enabled = false

        if not (current_seg or out_dir) then
            game.print("The impossible happened")
            draw_line(game.players[1].character, rail, colors.red, true)
            mark_rail(next_seg, colors.red, "aaah")
            --break
        end
        next_seg, next_direction = next_segment(current_seg, out_dir, con_dirs)
        if not next_seg then
            break
        end
    end
    profiler.Stop()
    log("Hits: " .. hits .. " Calls: " .. calls)
    log("Signals: " ..table_size(marked))
    log("Loops: " .. lps)
end

local function get_connected_rails(current, current_direction, c)
    c = c or 0
    local length = 0
    local function _recurse(rail, rail_direction, l, m)
        m = m or math.huge
        local tmp

        for _, con_dir in pairs(rcd) do
            tmp = rail.get_connected_rail{
                rail_direction = rail_direction,
                rail_connection_direction = con_dir
            }
            if tmp then
                c = c + 1
                --rails[c] = {rail = t, rd = rail_dir, rcd = con_dir, i = c}
                l = l + get_rail_data(tmp).length
                local next_direction = chiral_direction(rail, tmp)[rail_direction]
                has_rail_signals(tmp, next_direction, "f")
                l = _recurse(tmp, next_direction, l, m)
                c = c - 1
                l = l - get_rail_data(tmp).length
                mark_rail(tmp, colors[rail_direction], round(l, 1), true)
                --log(l)
            end
        end
        --mark_rail(rail, colors[rail_direction], round(l, 1), true)
        return l, m
    end
    --local min
    for _, con_dir in pairs(rcd) do
        local t = current.get_connected_rail{
            rail_direction = current_direction,
            rail_connection_direction = con_dir
        }
        if t then
            c = c + 1
            --rails[c] = {rail = t, rd = rail_dir, rcd = con_dir, i = c}
            local next_direction = chiral_direction(current, t)[current_direction]
            mark_rail(t, colors[current_direction], round(c, 1), true)
            length = _recurse(t, next_direction, get_rail_data(current).length)
            --min = length < min and length or min
            -- log(length)
            -- log(min)
        end
    end
    return c, length
end

local function next_segment(prev_seg_end, rail_direction, con_dirs)
    local crs = 0
    local tmp, found
    local get_connected_rail = prev_seg_end.get_connected_rail
    for _, con_dir in pairs(con_dirs) do
        tmp = get_connected_rail{
            rail_direction = rail_direction,
            rail_connection_direction = con_dir
        }
        if tmp then
            crs = crs + 1
            --mark_entity_text(tmp, "branch")
            draw_line(prev_seg_end, tmp, colors.blue, true, true)
        end
        if tmp and not found then
            if render.enabled then
                --mark_segment(tmp)
                draw_line(prev_seg_end, tmp, colors.green, false, true)
                mark_rail(tmp, colors.red, "S", true)
                mark_entity_text(tmp, find_key(rd, rail_direction, colors.red))
            end
            found = tmp
        end
    end
    if crs > 1 then
        game.print("branch")
        --mark_rail(prev_seg_end, colors.red, "E")
        --draw_line(game.players[1].character, prev_seg_end, colors.green, true)
        --return
    end
    --assert(crs < 2)
    if crs == 0 then
        return
    end
    return found, chiral_direction(prev_seg_end, found)[rail_direction]
end

local function _recurse(next_seg, next_direction, visited, depth, length, signals)
    depth = depth + 1
    local depth_s = string.rep("\t", depth)
    log(depth_s .. depth)
    local seg_length = next_seg.get_rail_segment_length()
    --local ret_signal
    --?next_seg is the closer rail to the dead end, so if that has an attached signal we can already return, without jumping?!
    local current_seg, out_dir = jump_to_end(next_seg, next_direction, round(length, 1))--get the start end, can be the same as exit end

    --[[ if render.enabled then
        local test = jump_to_end(next_seg, opposite_rail_direction[next_direction])
        if (test ~= next_seg) then
            log("not equal")
            game.print("not equal")
        end
    end ]]

    render.enabled = false
    local f, s = has_rail_signals(current_seg, out_dir, next_seg, next_direction)--!current is further from the dead end, next_seg closer
    render.enabled = true
    --?adjust length
    if s then
        local adjusted = length - s.signal_data.stops
        local id = s.signal.unit_number
        render.mark_signal(s.signal, colors.red, adjusted, true)
        --log(serpent.block(s))
        render.draw_line(game.players[1].character, s.signal, colors.black, true, true)
        log(depth_s .. "l0: " .. adjusted)
        if not signals[id] then
            s.distance = adjusted
            signals[id] = s
        else
            s.distance = s.distance < adjusted and s.distance or adjusted
        end
        return
        --return adjusted, s
    end
    length = length + seg_length
    if f then
        local adjusted = length - f.signal_data.starts
        local id = f.signal.unit_number
        render.mark_signal(f and f.signal, colors.green, adjusted, true)
        log(depth_s .. "l1: " .. adjusted)
        if not signals[id] then
            f.distance = adjusted
            signals[id] = f
        else
            f.distance = f.distance < adjusted and f.distance or adjusted
        end
        return
        --return adjusted, f
    end

    local get_connected_rail = current_seg.get_connected_rail
    local last = true
    local crs = 1

    local unvisited = {}
    get_connected_segments(current_seg, out_dir, unvisited)
    log(serpent.block(unvisited))

    for _, con_dir in pairs(rcd) do
        local tmp = get_connected_rail{
            rail_direction = out_dir,
            rail_connection_direction = con_dir
        }
        if tmp then
            local id = tmp.unit_number
            if visited[id] then
                game.print("Cycle detected 2")
                render.draw_line(game.players[1].character, tmp, colors.black, true, true)
                render.draw_line(game.players[1].character, current_seg, colors.red, true, true)
                log("Cycle length:" .. length)
                return-- length, ret_signal
            else
                visited[id] = true
                last = false
                render.draw_line(tmp, current_seg, colors.alternate[crs])
                crs = crs + 1
                --_recurse(tmp, chiral_direction(current_seg, tmp)[out_dir], visited, depth, length)
                log(serpent.line({log_entity(tmp), chiral_direction(current_seg, tmp)[out_dir]}))
                _recurse(tmp, chiral_direction(current_seg, tmp)[out_dir], visited, depth, length, signals)
            end
        end
    end
    --length = ret_signal and length or 0
    if last then
        --log(depth_s .. "last")
        render.mark_rail(current_seg, colors.red, round(length, 1))
    end
    --log(depth_s .. "l2: " .. tostring(length))
    --return length, ret_signal
end

local function get_connected_segments(segment_end, out_dir, unvisited)
    local ret = {}
    local crs = 0
    local get_connected_rail = segment_end.get_connected_rail
    local c = unvisited and #unvisited
    local conn = {
        rail_direction = out_dir,
        rail_connection_direction = false
    }
    local data
    for _, con_dir in pairs(rcd) do
        conn.rail_connection_direction = con_dir
        local tmp = get_connected_rail(conn)
        if tmp then
            data = {rail = log_entity(tmp), out_dir = chiral_direction(segment_end, tmp)[out_dir]}
            crs = crs + 1
            if unvisited then
                unvisited[c + crs] = data
            end
            ret[crs] = data
        end
    end
    return ret
end

local function get_connected_rails_by_id(signal)
    local rails = signal.get_connected_rails()
    local tmp = {}
    for _, r in pairs(rails) do
        tmp[r.unit_number] = r
    end
    return tmp
end

--entrance is a seg_start
--into_seg_dir points into the segment (away from entrance)
local function get_segment(entrance, into_seg_dir, stop_at_signal)
    into_seg_dir = into_seg_dir or rd.front

    local id = entrance.unit_number

    if segments[id] then
        return segments[id]
    end
    local out_dir = opposite_rail_direction[into_seg_dir]
    local segment = new_segment(entrance, out_dir, 0)
    segments[id] = segment
    local neighbours = false
    local seg_length
    local exit, exit_dir
    -- local seen = {}
    -- seen[id] = true
    seg_length = entrance.get_rail_segment_length()
    segment.length = segment.length + seg_length
    exit, exit_dir = jump_to_end(entrance, into_seg_dir)--get the entrance end, can be the same as exit end
    segment.seg_end = {rail = exit, out_dir = exit_dir, rail_data = get_rail_data(exit)}
    render.mark_entity_text(exit, round(seg_length, 1), nil, {alt = true})
    -- DE <- entrance RRRRRR exit <- FARL
    local f, s = has_rail_signals(exit, exit_dir, entrance, out_dir)
    if s then
        assert(not segment.signals)
        --log(serpent.block(s.signal_data))
        segment.signals = {}
        segment.signals[1] = s
        render.mark_signal(s.signal, "s", colors.red)
        --draw_line(game.players[1].character, s.signal, colors.black, true, true)
    end
    if f then
        segment.signals = segment.signals or {}
        assert(not segment.signals[2])
        --log(serpent.block(f.signal_data))
        segment.signals[2] = f
        render.mark_signal(f and f.signal, "f", colors.green)
    end
    if stop_at_signal and (f or s) then
        return segment
    end
    local get_connected_rail = exit.get_connected_rail
    local crs = 0
    local chiral, tmp, tid
    for _, con_dir in pairs(rcd) do
        tmp = get_connected_rail{
            rail_direction = exit_dir,
            rail_connection_direction = con_dir
        }
        if tmp then
            tid = tmp.unit_number
            -- if seen[tid] or segments[tid] then
            --     game.print("Cycle?! " .. tid)
            -- end
            chiral = chiral_direction(exit, tmp, exit_dir)
            neighbours = neighbours or {}
            neighbours[tid] = {tmp, chiral}
            render.draw_line(exit, tmp, colors.alternate[crs+1], true, true)
            crs = crs + 1
        end
    end
    segment.neighbours = neighbours
    return segment
end

local function get_prev_segment(entrance, into_seg_dir, stop_at_signal)
    into_seg_dir = into_seg_dir or rd.front

    local id = entrance.unit_number

    if segments[id] then
        return segments[id]
    end
    local out_dir = opposite_rail_direction[into_seg_dir]
    local segment = new_segment(entrance, out_dir, 0)
    segments[id] = segment
    local neighbours = false
    local seg_length
    local exit, exit_dir
    -- local seen = {}
    -- seen[id] = true
    seg_length = entrance.get_rail_segment_length()
    segment.length = segment.length + seg_length
    exit, exit_dir = jump_to_end(entrance, into_seg_dir)--get the entrance end, can be the same as exit end
    segment.seg_end = {rail = exit, out_dir = exit_dir, rail_data = get_rail_data(exit)}
    render.mark_entity_text(exit, round(seg_length, 1), nil, {alt = true})
    -- DE <- entrance RRRRRR exit <- FARL
    local f, s = has_rail_signals(exit, exit_dir, entrance, out_dir)
    if s then
        assert(not segment.signals)
        --log(serpent.block(s.signal_data))
        segment.signals = {}
        segment.signals[1] = s
        render.mark_signal(s.signal, "s", colors.red, false)
        --draw_line(game.players[1].character, s.signal, colors.black, true, true)
    end
    if f then
        segment.signals = segment.signals or {}
        assert(not segment.signals[2])
        --log(serpent.block(f.signal_data))
        segment.signals[2] = f
        render.mark_signal(f and f.signal, "f", colors.green, false)
    end
    if stop_at_signal and (f or s) then
        return segment
    end
    local get_connected_rail = exit.get_connected_rail
    local crs = 0
    local chiral, tmp, tid
    for _, con_dir in pairs(rcd) do
        tmp = get_connected_rail{
            rail_direction = exit_dir,
            rail_connection_direction = con_dir
        }
        if tmp then
            tid = tmp.unit_number
            -- if seen[tid] or segments[tid] then
            --     game.print("Cycle?! " .. tid)
            -- end
            chiral = chiral_direction(exit, tmp)[exit_dir]
            neighbours = neighbours or {}
            neighbours[tid] = {tmp, chiral}
            render.draw_line(exit, tmp, colors.alternate[crs+1], true, true)
            crs = crs + 1
        end
    end
    segment.neighbours = neighbours
    return segment
end

--returns
local function get_rail_segment_entity2(rail, direction)
    local get_it = rail.get_rail_segment_entity
    local res = get_it(direction, true)
    res = res and res.type ~= "train-stop" and res or nil
    local res2 = get_it(opposite_rail_direction[direction], false)
    res2 = res2 and res2.type ~= "train-stop" and res2 or nil
    return res, res2
end

local function has_rail_signals(seg_start, rail_direction, seg_end, _, txt)
    --local start_direction = rail_direction
    --local s_dir = opposite_rail_direction[rail_direction]
    local data, hit
    local result = {false, false}
    local first, second = get_rail_segment_entity2(seg_start, rail_direction)

    local id = first and first.unit_number
    if first and not marked[id] then
        data, hit = get_signal_data(first, seg_start, seg_end)
        if data then
            result[1] = {signal = first, rail = hit, signal_data = data, id = id}
            marked[id] = data
            if render.enabled then
                render.draw_line(hit, first, colors.white)
                render.mark_signal(first, txt and (txt .. " S"), true)
            end
        else
            if render.enabled then
                game.print("no signal data found S")
                render.draw_line(game.players[1].character, first, colors.red, true, true)
            end
        end
    end

    id = second and second.unit_number
    if second and not marked[id] then
        data, hit = get_signal_data(second, seg_start, seg_end)
        if data then
            result[2] = {signal = second, rail = hit, signal_data = data, id = id}
            marked[id] = data
            if render.enabled then
                render.draw_line(hit, second, colors.white)
                render.mark_signal(second, txt and (txt .. " E"), true)
            end
        else
            if render.enabled then
                game.print("no signal data found E")
                render.draw_line(game.players[1].character, second, colors.red, true, true)
            end
        end
    end
    return result[1], result[2]
end

local function new_segment(seg_start, out_dir, length)
    local pos = seg_start.position
    local k = librail.args_to_key(pos.x, pos.y, seg_start.direction)
    local data, id = get_rail_data(seg_start)
    render.mark_entity_text(seg_start, id, nil, {alt = true})
    local ret = {
        seg_start = {rail = seg_start, out_dir = out_dir, rail_data = data},
        seg_end = {rail = false, out_dir = false},
        length = length,
        neighbours = false,
        parent = false,
        signals = false,
        key = k,
        id = id,
        distance = 0
    }
    return ret, ret.id
end


FARL.removeTrees = function(self, area)

    for _, entity in pairs(self.surface.find_entities_filtered { area = area, type = "tree" }) do
        if proto and proto.minable and proto.products and (not self.cheat_mode) and self.settings.collectWood then
            local products = proto.products
            if products then
                for _, product in pairs(products) do
                    if product.type == "item" then
                        if product.name == "wood" then
                            self:addItemToCargo("wood", 1)
                        else
                            if product.probability then
                                if product.probability == 1 or (product.probability >= random()) then
                                    name = product.name
                                end
                                if name then
                                    if product.amount_max == product.amount_min then
                                        amount = product.amount_max
                                    else
                                        amount = random(product.amount_min, product.amount_max)
                                    end
                                    if amount and amount > 0 then
                                        self:addItemToCargo(name, ceil(amount/2))
                                    end
                                    name = false
                                end
                            elseif product.name and product.amount then
                                name = product.name
                                amount = product.amount
                                if amount and amount > 0 then
                                    self:addItemToCargo(name, ceil(amount/2))
                                end
                                name = false
                            end
                        end
                    end
                end
            end
        end
        entity.die() -- using die() here, because destroy() doesn't leave tree stumps
    end
    --log(game.tick .. ' removeTrees end')
end

FARL.removeStone = function(self, area)
    local amount, name, proto
    local random = math.random
    for _, entity in pairs(self.surface.find_entities_filtered { area = area, type = "simple-entity", force = "neutral" }) do
        proto = entity.prototype.mineable_properties
        if proto and proto.minable and proto.products then
            if entity.destroy() and self.settings.collectWood  and not self.cheat_mode then
                local products = proto.products
                for _, product in pairs(products) do
                    if product.type == "item" then
                        if product.probability then
                            if product.probability == 1 or (product.probability >= random()) then
                                name = product.name
                            end
                            if name then
                                if product.amount_max == product.amount_min then
                                    amount = product.amount_max
                                else
                                    amount = random(product.amount_min, product.amount_max)
                                end
                                if amount and amount > 0 then
                                    --log(string.format("added %s %s", amount, name))
                                    self:addItemToCargo(name, ceil(amount/2))
                                end
                                name = false
                            end
                        elseif product.name and product.amount then
                            name = product.name
                            amount = product.amount
                            if amount and amount > 0 then
                                --log(string.format("added %s %s", amount, name))
                                self:addItemToCargo(name, ceil(amount/2))
                            end
                            name = false
                        end
                    end
                end
            end
        end
    end
end
bp_data = {
    straight = {
    bounding_box = {left_top = {x = -8, y = -1},
                    right_bottom = {x = 10, y = 2}
    },
    main_rail = {name = "straight-rail"},
    rails = {
        {position = {x = 6, 4}, signal_dir = dir.north},
        {position = {x = -10, 6, signal_dir = dir.south}},
    },
    pole = {position = {x = 2, y = 0}, name = "big-electric-pole"},
    walls ={{position = {x = -15, y = 0}, name = "stone-wall"},
            {position = {x = 15, y = 0}, name = "stone-wall"}}},
    diagonal = {...}
}