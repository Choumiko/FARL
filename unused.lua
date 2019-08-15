local function chiral_direction(prev, next_r, prev_dir)
    return chiral_directions[get_rail_data(prev).chirality == get_rail_data(next_r).chirality][prev_dir]
end

--seg_end is closer to the cardinal direction rail_direction points at
--seg_dir points towards the cardinal direction (or whereever seg_end points at)
--I guess after using this we are doomed to forget about the cardinal direction
--We are now following the tracks like a train and should keep that perspective
local function jump_to_end(rail, rail_direction)--luacheck: no unused
    local seg_end, seg_dir = rail.get_rail_segment_end(rail_direction)
    return seg_end, seg_dir
end

local test_functions = {}

function test_functions.next_rails(selected)
    local c
    local surface = selected.surface
    local pos = selected.position
    local create = {force = selected.force, position = Position.add(pos, {x=0,y=0}), direction = 0, name = false}
    local data = get_rail_data(selected).next_rails
    for _, rdir in pairs(rd) do
        for _, rail in pairs(data[rdir]) do
            if rail then
                create.position = Position.add(pos, rail.position)
                create.name = rail.type
                create.direction = rail.direction
                c = surface.create_entity(create)
                if c then
                    if not Position.equals(create.position, c.position) then
                        game.print("Diff: " .. serpent.line(create.position).. " got: " .. serpent.line(c.position))
                    end
                else
                    game.print("Failed to create: " .. serpent.line(create))
                end
            end
        end
    end
end

function test_functions.get_closest_signal(selected, player)
    rendering.clear("FARL")
    --render.off(true)
    render.on(true)
    local rail = selected
    --determine rail_direction (assuming dead end is selected)
    local raildir = get_rail_direction_from_loco(player.character, selected)
    if raildir then
        local dead_end, de_dir = get_starting_rail(selected, raildir)
        if not dead_end then
            game.print("No dead end. Face in loco direction and try again")
            goto error
        end

        local p = game.create_profiler()
        local signal, dist = get_closest_signal(dead_end, de_dir, true)
        if signal then
            local data = get_rail_data(dead_end)
            log2(serpent.block(data, {keyignore={signal_map = true}}), "Rail data")
            log2(serpent.block(data.signals[de_dir], {keyignore={signal_map = true}}), "Signal data")
            local k = librail.args_to_key(signal.position.x - dead_end.position.x, signal.position.y - dead_end.position.y, signal.direction)
            local tmp = data.signal_map[k]
            log2(serpent.block(tmp), "The one")
        end
        p.stop()
        profiler2.Stop()
        log{"", p}
        log("Length: " .. rail.get_rail_segment_length())
        render.on(true)
        render.mark_rail(dead_end, colors.green, "S")
        render.mark_signal(signal, "C", nil, nil, nil, round(dist,1))
        render.restore()
    else
        game.print("No dead end. Face in loco direction and try again")
    end
    ::error::
end

test_signals = function(args)
        rendering.clear()
        local selected = game.player.selected
        local sel_type = (selected and selected.valid) and selected.type
        if rail_types[sel_type] then
            render.on()
            render.surface = game.player.surface
            print("-----------Test signals----------")
            local card = tonumber(args.parameter or 0)
            local rail_dir = get_rail_data(selected).travel_to_rd[card]
            if not rail_dir then
                card = math.abs(card - 1) % 1
                print("f " .. card)
                rail_dir = get_rail_data(selected).travel_to_rd[card]
                if not rail_dir then
                    return
                end
            end
            print("Card: " .. find_key(dir, card))
            print("Rail_dir: " .. find_key(rd, rail_dir))

            render.mark_rail(selected, colors.blue, "", true)

            --jumps towards cardinal direction (forwards)
            local some_rail, some_dir = selected.get_rail_segment_end(rail_dir)
            render.mark_rail(some_rail, colors.red, "E" .. some_dir)

            --jumps away from the cardinal direction (backwards)
            local seg_start, start_direction = some_rail.get_rail_segment_end(opposite_rail_direction[some_dir])
            render.mark_rail(seg_start, colors.green, "S" .. start_direction)

            --should be the same as some_rail, some_dir
            local seg_end, end_direction = some_rail.get_rail_segment_end(some_dir)
            assert(seg_end == some_rail)
            assert(end_direction, some_dir)
            render.restore()
        end
    end