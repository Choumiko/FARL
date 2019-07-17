local version = require('version')
local render = require('render')
local colors = render.colors
local util = require('util')
local lib = require 'lib_control'
local round = lib.round
local Position = lib.Position
local profiler = require('profiler')
local profiler2 = require('profiler2')--luacheck: no unused

local test_runner = require 'tests'
local test_cases = require 'tests.startup'

local position_hash = function(x, y, d)
    return ((1000000 + x) * 100000000) + ((1000000 + y) * 100) + d
end

local dir = defines.direction
local rd = defines.rail_direction

local function find_key(tbl, n)
    for name, v in pairs(tbl) do
        if v == n then return name end
    end
end

local function print2(v, desc, block)
    local f = block and serpent.block or serpent.line
    print(string.format("%s: %s", desc or "undesc", type(v) == "table" and f(v) or tostring(v)))
end

local function log2(v, description)
    if not description then
        local info = debug.getinfo(2, "l")
        description = info and info.currentline
    end
    log(string.format("%s: %s", description or "undesc", tostring(v)))
end

--?Stuff to think about
--[[
    Placement modes:
        - classic
        - tileable: blueprints contain multiple rails per lane, should enable grid-like network with farl, with more complex non rail setups:
          (_possibly_ with an alternative blueprint (junction) every X placed tiles)
                ww          ww      |     ww          ww
            wwwwwwwwwwwwwwwwwwwwwww | wwwwwwwwwwwwwwwwwwwwwww
            ======================= | =======================
                PP          PP      |     PP          PP
            ======================= | =======================
    Signal placement options:
        - by distance
        - with every pole
    Blueprints/Layouts:
        - rotate the 2 required blueprints into the needed directions and use them as lookup tables
          enables customizing each and every direction when desired
]]


local rcd = {
    left = defines.rail_connection_direction.left,
    right = defines.rail_connection_direction.right,
    straight = defines.rail_connection_direction.straight
}
local rcd_straight_first = {
    rcd.straight,
    rcd.left,
    rcd.right
}
print("--RCD--")
for k, i in pairs(rcd) do
    if k == "straight" then
        print(k .. "\t" .. i)
    else
        print(k .. "\t\t" .. i)
    end
end

print("\n--RD--")
for k, i in pairs(rd) do
    print(k .. "\t" .. i)
end
local sqrt2 = math.sqrt(2)

--local curve_length = 7.7  -- 7.7288196964265417438549920430937
local curve_length = 7.842081225095 --(get_rail_segment_length() on a curved rail)

local function log_entity(ent, description, short)
    description = description and (description .. ": ") or ""
    if ent and ent.valid then
        local pos = ent.position
        if ent.valid then
            local s = " {x = " .. pos.x .. " y = " .. pos.y .. "}, direction: " .. find_key(dir, ent.direction)
            if short then
                return description .. s
            end
            return description .. "type: " .. ent.type .. s
        else
            log(ent)
            return description .. "Invalid entity"
        end
    end
    return description .. "nil"
end

local function on_tick()

end

local function init_global()

end

local function init_player()

end

local function on_init()
    log("on_init")
    init_global()
    for _, player in pairs(game.players) do
        init_player(player)
    end
end

local function on_load()
    log("on_load")
end

local function on_configuration_changed(data)
    log("on_config_changed")
    if not data then
        return
    end
    log("on_config_changed data: " .. serpent.block(data))
    if data.mod_changes.FARL then
        local oldVersion = data.mod_changes.FARL.old_version
        local newVersion = data.mod_changes.FARL.new_version
        if oldVersion then
            log("FARL version changed from ".. tostring(oldVersion) .." to ".. tostring(newVersion))
            oldVersion = oldVersion and version.parse(oldVersion)
            newVersion = version.parse(newVersion)
            if version.lt(newVersion, oldVersion) then
                log("Downgrading FARL")
                global = {}
                on_init()
            end
        end
    end
end

local function on_player_created(event)
    init_player(game.get_player(event.player_index))
end

local function on_gui_click(event)
    if event.element.name == "farl_code_close" then
        event.element.parent.parent.destroy()
        return
    end
    if event.element.name == "farl_code_ok" then
        local txt = tonumber(event.element.parent.farl_test_index.text)
        global._tests_created = (txt or global._tests_created) + 1
        event.element.parent.parent.destroy()
        return
    end

end

local function on_gui_checked_state_changed()

end

local function on_preplayer_mined_item()

end

local function on_marked_for_deconstruction()
    on_preplayer_mined_item()
end

local function on_entity_died()
    on_preplayer_mined_item()
end

--chirality is "something" taken from https://github.com/dewiniaid/RailTools
local librail = {
    signal_data = {},
    connected_rail_permutations = {},
    cr_straight_first = {},
    all_connected_rail_permutations = {},
}
--- Generates a unique key for a given offset
-- Currently assumes offsets will never be bigger than +/- 10 or so, which satisfies the needs of our library.
-- @param offset The offset to use.  Must be a table with x, y and d elements.
function librail.offset_to_key(offset)
    -- Offsets are no bigger than 10.  Generate a reasonable key based on them for fast lookups.
    -- They're also always directional...
    return librail.args_to_key(offset.x, offset.y, offset.d)
end

--- Generates a unique key for a given x/y/direction
-- Currently assumes offsets will never be bigger than +/- 10 or so, which satisfies the needs of our library.
-- @param x The x coordinate
-- @param y The y coordinate
-- @param d The direction.
function librail.args_to_key(x, y, d)
    -- log("x=" .. x .. "; y=" .. y .. "; d=" .. d .. "; k=" .. x*1000000 + y*1000 + d)
    return (x+5)*1000000 + (y+5)*1000 + d
end

librail.rail_data = {
    ["straight-rail"] = {
        [dir.north] = {
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
        [dir.northeast] = {
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
    },
    ["curved-rail"] = {
        [dir.north] = {
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
        [dir.northeast] = {
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
    }
}

-- Generate permutations of connected rail arguments.
for _, rail_direction in pairs(rd) do
    librail.connected_rail_permutations[rail_direction] = {}
    librail.cr_straight_first[rail_direction] = {}
    for _, rail_connection_direction in pairs(rcd) do
        local t = {rail_direction=rail_direction, rail_connection_direction=rail_connection_direction}
        table.insert(librail.connected_rail_permutations[rail_direction], t)
        table.insert(librail.all_connected_rail_permutations, t)
    end
    for _, rail_connection_direction in pairs(rcd_straight_first) do
        local t = {rail_direction=rail_direction, rail_connection_direction=rail_connection_direction}
        table.insert(librail.cr_straight_first[rail_direction], t)
    end
end

local function rotate_next_rails(src)
    local t = table.deepcopy(src)
    t.position.x, t.position.y = -t.position.y, t.position.x
    t.direction = ((t.direction or 0) + 2) % 8
    return t
end

local pre_rotate, post_rotate
do
-- We supply offsets for north and northeast facings only.  All others are generated by calculating rotations, using
-- this table.
    local _rotations = {
        {dir.north, dir.east},
        {dir.northeast, dir.southeast},
        {dir.east, dir.south},
        {dir.southeast, dir.southwest},
        {dir.south, dir.west},
        {dir.southwest, dir.northwest},
    }

    local function each_rotation()
        local i = 0
        return function()
            i = i + 1
            if _rotations[i] then return unpack(_rotations[i]) end
            return nil
        end
    end


    -- Performs a 90 degree rotation of src
    local function rotate_cw(src)
        local t = table.deepcopy(src)
        t.x, t.y = -t.y, t.x
        if t.d then
            t.d = (t.d + 2) % 8
        end
        return t
        --     return { x=-src.y, y=src.x, d=src.d and (src.d+2)%8 or nil }
    end

    local t
    --Arbitrary number, must be greater than the number of manually-assigned chiralities.
    local number_of_chiralities = 100
    pre_rotate = util.table.deepcopy(librail.rail_data)
    log("\n")
    for entity_type, entity_data in pairs(librail.rail_data) do
        log(entity_type)
        -- Add rotations for directions other than north and northeast.
        -- This could be simplified, but this reads better.  And it's not a performance critical segment of code.
        for source, dest in each_rotation() do
            log("from " .. find_key(dir, source) .. " to " .. find_key(dir, dest))
            t = {
                length = entity_data[source].length,
                signals = {},
                travel_to_rd = {}
            }

            for d, signals in pairs(entity_data[source].signals) do
                t.signals[d] = {}
                for i = 1, #signals do
                    t.signals[d][i] = rotate_cw(signals[i])
                    t.signals[d][i].stops = signals[i].stops
                    t.signals[d][i].starts = signals[i].starts
                end
            end
            entity_data[dest] = t

            local t_rd = entity_data[source].travel_to_rd
            local calc_td--, set_rd
            for td, _rd in pairs(t_rd) do
                calc_td = (td + 2) % 8
                entity_data[dest].travel_to_rd[calc_td] = _rd
            end
            local _t = {}
            for d, connected_rails in pairs(entity_data[source].next_rails) do
                _t[d] = {}
                for conn_dir, rail in pairs(connected_rails) do
                    _t[d][conn_dir] = {}
                    if not rail then
                        _t[d][conn_dir] = false
                    else
                        _t[d][conn_dir] = rotate_next_rails(connected_rails[conn_dir])
                    end
                end
            end
            entity_data[dest].next_rails = _t
        end

        -- Second pass: Create the signal map and determine signal search areas.
        for entity_direction, direction_data in pairs(entity_data) do
            direction_data.chirality = number_of_chiralities
            number_of_chiralities = number_of_chiralities + 1
            direction_data.signal_map = {}
            for rail_direction, signals in pairs(direction_data.signals) do
                for i=1, #signals do
                    local offset = signals[i]
                    offset.index = i

                    -- Generate a map of where our signals are
                    direction_data.signal_map[librail.offset_to_key(offset)] = {
                        rail_direction = rail_direction, x = offset.x, y = offset.y, index = i, d = offset.d,
                        stops=offset.stops, starts=offset.starts
                    }
                    -- Do the same thing in reverse for signals.
                    local signal = librail.signal_data[offset.d]
                    if not signal then
                        signal = { rail_map = {} }
                        librail.signal_data[offset.d] = signal
                    end
                    if not signal.rail_map[entity_type] then
                        signal.rail_map[entity_type] = {}
                    end

                    local k = librail.args_to_key(-offset.x, -offset.y, entity_direction)
                    signal.rail_map[entity_type][k] = {
                        direction = entity_direction,
                        rail_direction = rail_direction, signal_index = i, signal = offset, rail_data = direction_data,
                        x = -offset.x, y = -offset.y, d = entity_direction,
                    }
                end
            end
        end
    end
    librail.rail_data['straight-rail'][dir.north].chirality = 0
    librail.rail_data['curved-rail'][dir.south].chirality = 0
    librail.rail_data['curved-rail'][dir.southwest].chirality = 0
    librail.rail_data['straight-rail'][dir.southeast].chirality = 0

    librail.rail_data['straight-rail'][dir.east].chirality = 1
    librail.rail_data['curved-rail'][dir.west].chirality = 1
    librail.rail_data['curved-rail'][dir.northwest].chirality = 1
    librail.rail_data['straight-rail'][dir.southwest].chirality = 1

    librail.rail_data['straight-rail'][dir.northeast].chirality = 2
    librail.rail_data['curved-rail'][dir.southeast].chirality = 2

    librail.rail_data['straight-rail'][dir.northwest].chirality = 3
    librail.rail_data['curved-rail'][dir.northeast].chirality = 3

    local tmp = {}
    for k, v in pairs(librail) do
        if type(v) ~= "function" then
            tmp[k] = v
        end
    end
    post_rotate = tmp
end

local chiral_directions = {
        [true] = {
            [rd.front] = rd.front,
            [rd.back] = rd.back
        },
        [false] = {
            [rd.front] = rd.back,
            [rd.back] = rd.front
        }
}

local opposite_rail_direction = chiral_directions[false]

local _rail_data = {}
local hits, calls = 0, 0
local function get_rail_data(rail)
    local id = rail.unit_number
    calls = calls + 1
    if not _rail_data[id] then
        _rail_data[id] = librail.rail_data[rail.type][rail.direction]
    else
        hits = hits + 1
    end
    return _rail_data[id], id
end

-- local function get_rail_data(rail)
--     return next_rail_data[rail.type][rail.direction]
-- end
-- local k = librail.args_to_key(signal.position.x - dead_end.position.x, signal.position.y - dead_end.position.y, signal.direction)
--                         local temp = data.signal_map[k]
--                         log2(serpent.block(temp), "The one")
local function get_signal_data2(signal, ent)--luacheck: no unused
    local data = librail.signal_data[signal.direction]
    local k = librail.args_to_key(ent.position.x - signal.position.x, ent.position.y - signal.position.y, ent.direction)
    --print(tostring(k))
    local tmp = data.rail_map[ent.type][k]
    if tmp then
        --print(serpent.block(tmp, {keyignore={rail_data = true}}))
        return tmp
    end
end

local function get_signal_data(signal, rail, rail2)--luacheck: no unused
    local signal_data = get_rail_data(rail).signal_map
    local signal_pos = signal.position
    local signal_dir = signal.direction
    local rail_pos = rail.position
    local rail_dir = rail.direction
    rail_pos = {x = rail_pos.x, y = rail_pos.y}
    local k = librail.args_to_key(signal_pos.x - rail_pos.x, signal_pos.y - rail_pos.y, signal_dir)
    local t = signal_data[k]
    local hit = t and rail
    -- print(tostring(k))
    -- if t then
    --     print(serpent.block(t, {keyignore={rail_data = true}}))
    -- end
    -- local _ = get_signal_data2(signal, rail2)
    --print(serpent.block(test))
    --assert(table.compare(t, test), string.format("%s not equal to %s", tostring(t), tostring(test)))

    if (not t) and rail2 then
        signal_data = get_rail_data(rail2).signal_map
        rail_pos = rail2.position
        rail_pos = {x = rail_pos.x, y = rail_pos.y}
        rail_dir = rail2.direction
        k = librail.args_to_key(signal_pos.x - rail_pos.x, signal_pos.y - rail_pos.y, signal_dir)
        t = signal_data[k]
        hit = t and rail2
    end
    return t, hit, rail_pos, rail_dir
end

local function chiral_direction(prev, next_r, prev_dir)--luacheck: no unused
    return chiral_directions[get_rail_data(prev).chirality == get_rail_data(next_r).chirality][prev_dir]
end

local Rail = {}

function Rail.get_connected_rails(rail, rail_direction)
    local get_rail = rail.get_connected_rail
    local rails, crs = {}, 0
    local tmp, chiral
    for _, con_dir in pairs(rcd) do
        tmp = get_rail{
            rail_direction = rail_direction,
            rail_connection_direction = con_dir
        }
        if tmp then
            crs = crs + 1
            --chiral_direction(rail, tmp, rail_direction)
            chiral = chiral_directions[get_rail_data(rail).chirality == get_rail_data(tmp).chirality][rail_direction]
            rails[crs] = {tmp, chiral, con_dir}
        end
    end
    return rails, crs
end

function Rail.is_dead_end(rail, rail_direction)
    local get_rail = rail.get_connected_rail
    local tmp
    for _, con_dir in pairs(rcd) do
        tmp = get_rail{
            rail_direction = rail_direction,
            rail_connection_direction = con_dir
        }
        if tmp then
            return false
        end
    end
    return rail_direction
end

--walks in rcd.straight direction, until limit is reached or a curved rail or dead end
local _straight_only = {
    [rd.front] = {rail_direction = rd.front, rail_connection_direction = rcd.straight},
    [rd.back] = {rail_direction = rd.back, rail_connection_direction = rcd.straight}
}
local function get_starting_rail(rail, rail_direction, limit)
    limit = limit or 20
    local start_rail
    local test, prev = rail, rail
    local rail_data = get_rail_data(rail)
    local next_data
    local chiral = rail_direction

    local c = 1

    while (test and c <= limit) do
        --test = prev.get_connected_rail{rail_direction = chiral, rail_connection_direction = rcd.straight}
        test = prev.get_connected_rail(_straight_only[chiral])
        if test then
            assert(test.type == "straight-rail", "That shouldn't be a curve")
            next_data = get_rail_data(test)
            chiral = chiral_directions[rail_data.chirality == next_data.chirality][chiral]
            rail_data = next_data
            prev = test
            assert(rail_data)
        end
        c = c + 1
        start_rail = test and test or start_rail
    end
    if not Rail.is_dead_end(prev, chiral) then
        game.print("Don't start before a curve")
        return
    end
    if not start_rail and prev == rail then
        return rail, rail_direction
    end
    return start_rail, chiral
end

local function get_rail_segment_entity(rail, direction, entrance)
    local res = rail.get_rail_segment_entity(direction, entrance)
    return (res and res.type ~= "train-stop") and res or nil
end

--seg_end is closer to the cardinal direction rail_direction points at
--seg_dir points towards the cardinal direction (or whereever seg_end points at)
--I guess after using this we are doomed to forget about the cardinal direction
--We are now following the tracks like a train and should keep that perspective
local function jump_to_end(rail, rail_direction)
    local seg_end, seg_dir = rail.get_rail_segment_end(rail_direction)
    return seg_end, seg_dir
end

local _rail_segment = {--luacheck: no unused
    {
        seg_start = {rail = false, out_dir = false, signals = {}, data = false},
        seg_end = {rail = false, out_dir = false, signals = {}, data = false},
        length = 0,
        neighbours = {}
    }
}

local function log_segment(segment)--luacheck: no unused
    local s, e = segment.seg_start, segment.seg_end
    local ret = segment.id .. "\tlength: " .. segment.length .. "\tneighbours: " .. (segment.neighbours and table_size(segment.neighbours) or "") ..
        "\n\t seg_start:\t" .. log_entity(s.rail, "rail " .. tostring(s.rail and s.rail.unit_number), true) .. "\tout_dir: " .. s.out_dir ..
        "\n\t seg_end:\t" .. log_entity(e.rail, "rail " .. tostring(e.rail and e.rail.unit_number), true) .. "\tout_dir: " .. e.out_dir
        if segment.signals and table_size(segment.signals) > 0 then
            ret = ret .. "\n\t\tsignals:"
            for i, signal in pairs(segment.signals) do
                ret = ret .. log_entity(signal.signal, " "..i, true) .. log_entity(signal.rail, " rail " .. tostring(signal.rail and signal.rail.unit_number), true) .. "\n\t\t\t"
            end
        end
        return ret
end

--returns connected rail, the direction to keep going "forwards" and the end of the segment
--5th param is the rcd used to get the rail
local function each_connected_rail(rail, rail_direction)
    local t = librail.cr_straight_first[rail_direction]
    --local t = rcd_straight_first
    local i, n = 0, #t
    local connected
    local get_rail = rail.get_connected_rail
    local rail_chiral = get_rail_data(rail).chirality
    local function iterator()
        while i < n do
            i = i + 1
            connected = get_rail(t[i])
            if connected then
                local chiral = chiral_directions[rail_chiral == get_rail_data(connected).chirality][rail_direction]
                local seg_end, se_dir = jump_to_end(connected, chiral)
                return  connected, chiral, seg_end, se_dir, t[i].rail_connection_direction
            end
        end
    end
    return iterator
end

local function get_closest_signal(dead_end, de_dir)
    local signal = false
    local best = math.huge
    local child = 0
    local visited = {[dead_end.unit_number] = true}
    local function _recurse(seg_start, s_dir, start_len, d)
        local distance
        local id
        d = d and d + 1 or 0
        render.mark_rail(seg_start, colors.white, child, true)
        render.mark_entity_text(seg_start, d, nil, {top = true})
        for rail, rail_dir, seg_end, se_dir in each_connected_rail(seg_start, s_dir) do
            id = rail.unit_number
            if visited[id] then
                game.print("Cycle detected")
                break
            else
                visited[id] = true
            end

            local seg_len = rail.get_rail_segment_length()
            distance = start_len
            local first_signal = get_rail_segment_entity(rail, opposite_rail_direction[rail_dir], false)
            local second_signal
            child = child+1
            if first_signal then
                --only then we are a node, else we're just an edge that suddenly gets longer..
                if distance < best then
                    best = distance
                    signal = first_signal
                    break
                end
            else
                distance = distance + seg_len
                if distance >= best then
                    --wont get better (we are at least adding this segments length)
                    -- log2(d, "Early return")
                    -- log2(distance, "dist")
                    -- log2(best, "t_best")
                    render.mark_rail(seg_end, colors.red, distance, true)
                    render.mark_entity_text(seg_end, "early", nil, {top = true})
                    break
                end
                second_signal = get_rail_segment_entity(seg_end, se_dir, true)
                if second_signal then
                    --only then we are a node, else we're just an edge that suddenly gets longer..
                    if distance < best then
                        best = distance
                        signal = second_signal
                    end
                end
            end
            render.draw_line(seg_start, rail, colors.white, true, true)
            render.mark_rail(seg_end, colors.red, distance, true, {alt = true})
            _recurse(seg_end, se_dir, distance, d)
            local opts = {alt = true}
            render.mark_signal(first_signal, "de", colors.green, nil, opts, round(distance, 1))
            render.mark_signal(second_signal, "en", colors.red,  nil, opts, round(distance, 1))
        end
    end

    render.on(true)
    render.mark_rail(dead_end, colors.green, de_dir)

    local seg_starta, s_dira = jump_to_end(dead_end, opposite_rail_direction[de_dir])
    render.mark_rail(seg_starta, colors.red, s_dira)

    local seg_length = dead_end.get_rail_segment_length()
    local de_signal = get_rail_segment_entity(dead_end, de_dir, false)
    if de_signal then
        render.mark_signal(de_signal, "de", colors.green, nil, {alt = true})
        signal, best = de_signal, 0
    else
        --that's the most likely case i guess
        local seg_start_signal = get_rail_segment_entity(seg_starta, s_dira, true)
        if seg_start_signal then
            render.mark_signal(seg_start_signal, "en", colors.red)
            signal, best = seg_start_signal, seg_length
        end
    end

    _recurse(seg_starta, s_dira,  seg_length)

    render.line_to_player(game.players[1], signal, colors.white, true, true)
    render.mark_entity(game.players[1].character, colors.black, round(best or math.huge, 1), {square = true, alt = true})
    render.mark_signal(signal, "C", colors.blue, nil, nil, best)
    render.restore()
    --?adjust length according to signal data
    return signal, best
end

local function get_rail_direction_from_loco(entity, front)
    local orientation = entity.orientation
    --log2(orientation, "orientation")
    local abs, floor = math.abs, math.floor

    local rounded = floor(orientation * 8 + 0.5)
    local left = orientation - (rounded - 1) / 8
    local right = orientation - (rounded + 1) / 8

    -- log2(left , "left")
    -- log2(right, "right")

    local adjusted = (abs(left) < 0.11 and rounded - 1) or (abs(right) < 0.11 and rounded + 1)
    --log2(adjusted, "adjust: ")
    local loco_direction = rounded % 8
    --log2(loco_direction, "loco_direction")

    local data = get_rail_data(front).travel_to_rd
    local rail_direction = data[loco_direction]
    --log2(tostring(find_key(rd, data[adjusted]) or "nada"), "adj")
    --only adjust if we are somewhat in range of the probable direction
    if not rail_direction and adjusted and front.type == "curved-rail" then
        adjusted = adjusted % 8
        rail_direction = data[adjusted]--data[left] or data[right]
        if not rail_direction then
            game.print("Loco does sth strange on a curve")
            log(tostring(rail_direction) .. " Loco does sth strange on a curve")
            log("Using adjusted direction")
            log2(adjusted)
            log2(find_key(rd, data[adjusted]), "adj")
            log2(find_key(rd, entity.train.rail_direction_from_front_rail), "api")
            test_runner.halt = true
            entity.train.speed = 0
        end
--        log("Valid direction")
    end
    return rail_direction
end

local function get_rail_direction(rail, direction)
    local rail_dir = get_rail_data(rail).travel_to_rd[direction]
    -- if not rail_dir then
    --     game.print("No direction found for cardinal direction " .. find_key(dir, direction) .. "with rail: " .. rail.type .. " dir: " .. rail.direction)
    -- end
    return rail_dir
end

--[[
To activate FARL we need:
    - The last rail of a (straight) segment:
        - Get the rail under the locomotive, walk straight in the direction until the end (or to a branch?)
        - check for signals along the way? rail_segment_entity/end ?
    - The closest signal in travel direction and the distance to the last rail
--]]

local function get_startup_data(entity)
    local train = entity.train

    local carriages = train.carriages
    local in_front_mover = carriages[1] == entity
    if not in_front_mover and carriages[#carriages] ~= entity then
    --if not ((in_front_mover and carriages[1] or carriages[#carriages]) == entity) then
        return false, "Not in first or last locomotive, or facing the wrong direction"
    end

    --log("Front_mover: " .. tostring(in_front_mover))
    local front = in_front_mover and train.front_rail or train.back_rail
    --log("front rail: " .. front.type .. " " .. front.direction)

    local rail_direction = get_rail_direction_from_loco(entity, front)
    -- log2(find_key(rd, rail_direction), "Calc")
    -- log2(find_key(rd, entity.train.rail_direction_from_front_rail), "api")
    if not rail_direction then
        return false, "Too far from end of curve"
    end

    local dead_end, de_direction = get_starting_rail(front, rail_direction)

    if not dead_end then
        return false, "No starting rail"
    end
    --log2(find_key(rd, de_direction), "de_dir")
    --log(log_entity(dead_end, "Starting rail", true))
    local signal, distance = get_closest_signal(dead_end, de_direction)
    render.on(true)
    render.mark_rail(dead_end, colors.green, "S", true)
    --render.mark_entity_text(dead_end, find_key(rd, de_direction))
    render.mark_signal(signal, "C", colors.green, nil, nil, distance)
    render.restore()
    return dead_end, signal, distance
end

local function on_player_driving_changed_state(event)
    --profiler.Start()
    local entity = event.entity
    local player = game.get_player(event.player_index)
    if player.vehicle then
        render.player_index = {event.player_index}
        render.surface = player.surface
        if entity and entity.name == "farl" then
            local dead_end, signal, distance = get_startup_data(entity)
            if not dead_end then
                game.print(signal)
            end
            render.on(true)
            render.mark_rail(dead_end, colors.green, "S", true)
            render.mark_signal(signal, "C", colors.green, nil, nil, distance)
            render.restore()
        end
    else
        rendering.clear("FARL")
    end
    log2(calls, "Rail data calls")
    log2(hits, "Hits")
    profiler.Stop()
end

local function on_pre_player_removed()

end

local function script_raised_destroy()

end

local function create_set(...)
    local t = table.pack(...)
    local ret = {}
    for _, s in pairs(t) do
        ret[s] = true
    end
    return ret
end

local function on_player_alt_selected_area(event)
    --TODO: save results indexed by the loco the player is in
    --should speed up test creation, since i can create all cases at once
    --when clearing while inside a loco only clear for it
    if not (event.item == "farl_selection_tool") then return end
    local player = game.get_player(event.player_index)
    global._expected = global._expected or {}
    if not player.vehicle then
        if not global._confirm then
            game.print("Get in a train to set/clear expected results")
            global._confirm = true
            return
        else
            game.print("Clearing all expected results")
            global._confirm = nil
            global._expected = {}
            return
        end
    end
    local loco = player.vehicle
    local id = loco.unit_number
    local tc = global._expected[id] or {}
    local loco_str = "{name = %q, position = {x = %s, y = %s}, orientation = %s, force = %q}"
    local pos, d = loco.position, loco.orientation
    tc.loco = string.format(loco_str, loco.name, pos.x, pos.y, round(d, 4), loco.force.name)
    if table_size(event.entities) == 0 then
        tc.rail = nil
        tc.signal = nil
        global._expected[id] = tc
        player.print("Cleared expected results")
        return
    end
    local rail_types = create_set("straight-rail", "curved-rail")
    local signal_types = create_set("rail-signal", "rail-chain-signal")
    for _, ent in pairs(event.entities) do
        pos, d = ent.position, ent.direction or 0
        if signal_types[ent.type] then
            tc.signal =  string.format("%d", position_hash(pos.x, pos.y, d))
            player.print("Selected expected signal")
        end
        if rail_types[ent.type] then
            tc.rail = string.format("%d", position_hash(pos.x, pos.y, d))
            player.print("Selected expected rail")
        end
    end
    global._expected[id] = tc
end
script.on_event(defines.events.on_player_alt_selected_area, on_player_alt_selected_area)

local function on_player_selected_area(event)
    if not (event.item == "farl_selection_tool" and table_size(event.entities) > 0) then return end
    local player = game.get_player(event.player_index)
    local pos, c, ec
    local entities_c = {0, 0, 0, 0}
    global._expected = global._expected or {}
    global._tests_created = global._tests_created or 1
    local def = {
        rails = 1,
        signals = 2,
        rolling_stock = 3,
        other = 4
    }
    local def2 ={}
    for k, v in pairs(def) do
        def2[v] = k
    end

    local rail_types = create_set("straight-rail", "curved-rail")
    local signal_types = create_set("rail-signal", "rail-chain-signal")
    local rolling_stock_types = create_set("locomotive", "cargo-wagon", "artillery-wagon", "fluid-wagon")
    local entities = {{},{},{},{}}
    local format = string.format

    local function interp(s, tab)--luacheck: no unused
        return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
    end
    --http://lua-users.org/wiki/StringInterpolation
    --getmetatable("").__mod = interp
    local table_name = "startup"
    --TODO: turn create_rails into a table, so it's easier to change things
    local src = [[
${tbl}[${i}] = {
    name = "Test${i}",
    test_type = "",
    to_create = {
        rails = {
${rails}
        },
        signals = {
${signals}
        }
    },
    cases = {
${cases}
    }
}
]]

    local returns = {', false', ', false'}
    local create_entity = "            [%d] = {name = %q, position = {x = %s, y = %s}, direction = %d, force = %q},\n"
    local inf = math.huge
    local r_min_x, r_max_x = inf, -inf
    local r_min_y, r_max_y = inf, -inf
    local bottom
    local min_x, max_y = inf, - inf

    --local cases = {}
    for _, entity in pairs(event.entities) do
        c = (rail_types[entity.type] and def.rails) or (signal_types[entity.type] and def.signals) or (rolling_stock_types[entity.type] and def.rolling_stock) or def.other
        ec = entities_c[c] + 1
        pos = {x = entity.position.x, y = entity.position.y}
        table.insert(entities[c], {position_hash(pos.x, pos.y, entity.direction or 0), entity.name, pos.x, pos.y, entity.direction or 0, entity.force.name})
        entities_c[c] = ec
        if c == def.rails then
            if entity.type == "straight-rail" then
                if min_x > pos.x and max_y < pos.y then
                    bottom = entity
                    min_x = pos.x
                    max_y = pos.y
                end
            end
            r_min_x = pos.x < r_min_x and pos.x or r_min_x
            r_max_x = pos.x > r_max_x and pos.x or r_max_x
            r_min_y = pos.y < r_min_y and pos.y or r_min_y
            r_max_y = pos.y > r_max_y and pos.y or r_max_y
        end
        -- if c == def.rails and entity == global._expected.rail then
        --     cases[2] = format("        rail = %d", ec)
        -- end
        -- if c == def.signals and entity == global._expected.signal then
        --     cases[3] = format("        signal = %d", ec)
        -- end
    end

    --cases[1] = cases[1] or (entities[def.rolling_stock][1] and format("loco = ${tbl}[${i}].created_entities.%s[%d]", def2[def.rolling_stock], 1))
    -- if not cases[1] then
    --     game.print("No loco to test.")
    --     return
    -- end
    -- if not cases[2] then
    --     game.print("No rail, assuming false test")
    --     cases[2] = "        rail = false"
    --     cases[3] = "        signal = 'some error'"
    -- end
    -- if not cases[2] and not cases[3] then
    --     game.print("No signal, assuming false test")
    --     cases[3] = "        signal = false"
    -- end
    --print(serpent.block(cases))
    local cases = {}
    local case_str = "{loco = %s, rail = %s, signal = %s}"
    local cc = 1
    for _, case in pairs(global._expected) do
        cases[cc] = {
            [1] = case.loco,
            [2] = case.rail,
            [3] = case.signal
        }

        if not case.rail then
            game.print("No rail, assuming false test")
            cases[cc][2] = "false"
            cases[cc][3] = "'some error'"
        end
        if case.rail and not case.signal then
            game.print("No signal")
            cases[cc][3] = "false"
        end
        cases[cc] = format(case_str, case.loco, cases[cc][2], cases[cc][3])
        cc = cc + 1
    end
    cases = interp(table.concat(cases, ",\n"), {i = global._tests_created, tbl = table_name})
    local offset = {x =(min_x or 1) - 1, y = (max_y or 1) - 1}

    print(serpent.line(offset))

    for i, ents in pairs(entities) do
        for j, ent in pairs(ents) do
            -- ent[4] = ent[4] - offset.x
            -- ent[5] = ent[5] - offset.y
            entities[i][j] = format(create_entity, table.unpack(ent))
        end
    end
    rendering.clear("FARL")
    render.on(true)
    render.mark_entity(bottom, nil, "B")
    -- render.surface = player.surface
    -- render.draw_rectangle({x=r_min_x, y = r_min_y}, {x=r_max_x, y = r_max_y}, nil, nil, {ttl = 600})
    render.restore()

    for i, ents in pairs(entities) do
        entities[i] = table.concat(ents)
    end
    returns = table.concat(returns)
    src = interp(src, {i = global._tests_created, tbl = table_name,
        def_list = table.concat(def2, ", "),
        rails = entities[def.rails],
        signals = entities[def.signals],
        trains = entities[def.rolling_stock],
        returns = returns,
        cases = cases}
        )

    local gui = player.gui.left.farl_code
    local box
    if not (gui and gui.valid) then
        gui = player.gui.left.add{
            name = "farl_code",
            type = "frame",
            direction = "vertical"
        }
        box = gui.add{
            name = "code_text",
            type = "text-box",
            text = src
        }
        --box.read_only = true
        box.style.height = player.display_resolution.height * 0.4 / player.display_scale
        box.style.width = player.display_resolution.width * 0.4 / player.display_scale
        local f = gui.add{
            type = "flow",
            direction = "horizontal"
        }
        f.add{
            name = "farl_code_close",
            type = "button",
            caption = "Close"
        }
        f.add{
            type = "flow",
            direction = "horizontal"
        }.style.horizontally_stretchable = true
        f.add{
            name = "farl_test_index",
            type = "textfield",
            text = global._tests_created
        }
        f.add{
            name = "farl_code_ok",
            type = "button",
            caption = "Ok"
        }
    else
        player.gui.left.farl_code.code_text.text = src
    end
    --box.select_all()
    --box.focus()
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_pre_player_removed, on_pre_player_removed)
-- script.on_event(defines.events.on_player_toggled_map_editor, function(event)
--     log(find_key(defines.controllers, game.get_player(event.player_index).controller_type))
-- end)

script.on_event(defines.events.on_player_selected_area, on_player_selected_area)

script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)

script.on_event(defines.events.on_pre_player_mined_item, on_preplayer_mined_item)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
script.on_event(defines.events.script_raised_destroy, script_raised_destroy)

-- script.on_event(defines.events.on_player_changed_position, function(e)
--     log(e.tick)
-- end)

script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

local function farl_test(event)
    local player = game.get_player(event.player_index)
    if player.character then
        player.character_reach_distance_bonus = 100
        player.character_build_distance_bonus = 100
    end
    render.player_index = {event.player_index}
    render.surface = player.surface
    if player.cursor_stack.valid_for_read then
        local selected = player.cursor_stack
        if selected.type == "blueprint" then
            local ents = selected.get_blueprint_entities()
            local min_x, max_y = math.huge, -math.huge
            local btm, pos
            for _, ent in pairs(ents) do
                log(serpent.line(ent))
                pos = ent.position
                if ent.name == "straight-rail" and min_x >= pos.x and max_y <= pos.y then
                    min_x = pos.x
                    max_y = pos.y
                    btm = ent
                end
            end
            log2(serpent.line(btm), "btm")
            local offset = Position.subtract({x = 0, y = 0}, btm.position)
            log2(serpent.line(offset), "off")
            for i, ent in pairs(ents) do
                ent = rotate_next_rails(ent)
                if ent.name == "straight-rail" and (ent.direction == 6 or ent.direction == 4) then
                    ent.direction = (ent.direction + 4) % 8
                end
                ent.position = Position.add(ent.position, offset)
                log2(serpent.line(ent))
                ents[i] = ent
            end
            selected.set_blueprint_entities(ents)
            log("")
            for _, ent in pairs(selected.get_blueprint_entities()) do
                log(serpent.line(ent))
            end
        end
    end

    if player.selected then
        local selected = player.selected
        local sel_type = player.selected.type
        rendering.clear("FARL")

        log("\n"..log_entity(selected, "Current"))
        if global.selected and global.selected.valid then
            local offset = Position.subtract(selected.position, global.selected.position)
            print2(log_entity(global.selected), "Prev")
            print2(offset, "Diff")
            print2(math.sqrt(Position.distance_squared(selected.position, global.selected.position)), "Dist")
        end
        global.selected = selected

        if sel_type == "locomotive" then
            local p = game.create_profiler()
            selected.set_driver(player)
            p.stop()
            log{"", p}
        elseif sel_type == "straight-rail" or sel_type == "curved-rail" then
            local data = get_rail_data(selected).next_rails

            -- local c
            -- local surface = selected.surface
            -- local pos = selected.position
            -- local create = {force = selected.force, position = Position.add(pos, {x=0,y=0}), direction = 0, name = false}
            -- for _, rdir in pairs(rd) do
            --     for _, rail in pairs(data[rdir]) do
            --         if rail then
            --             create.position = Position.add(pos, rail.position)
            --             create.name = rail.type
            --             create.direction = rail.direction
            --             c = surface.create_entity(create)
            --             if c then
            --                 if not Position.equals(create.position, c.position) then
            --                     game.print("Diff: " .. serpent.line(create.position).. " got: " .. serpent.line(c.position))
            --                 end
            --             else
            --                 game.print("Failed to create: " .. serpent.line(create))
            --             end
            --         end
            --     end
            -- end

            render.on(true)
            for _, rdir in pairs(rd) do
                for rail, rail_dir, _, _, con in each_connected_rail(selected, rdir) do
                    local diff = Position.subtract(rail.position, selected.position)
                    --print(find_key(rcd, con) .. " " .. serpent.line(diff))
                    if not Position.equals(diff, data[rdir][con].position) then
                        game.print("Wrong position, rd: " .. find_key(rd, rdir))
                        game.print("E " .. serpent.line(data[rd.front][con].position))
                        game.print("R " .. serpent.line(diff))
                        render.mark_rail(rail, nil, rail_dir .. " " .. con)
                    end
                end
            end
            render.restore()
            -- rendering.clear("FARL")
            -- --render.off(true)
            -- render.on(true)
            -- local rail = selected
            -- --determine rail_direction (assuming dead end is selected)
            -- local raildir = get_rail_direction_from_loco(player.character, selected)
            -- if raildir then
            --     local dead_end, de_dir = get_starting_rail(selected, raildir)
            --     if not dead_end then
            --         game.print("No dead end. Face in loco direction and try again")
            --         goto error
            --     end
            --     --raildir = opposite_rail_direction[raildir]
            --     --profiler2.Start(false, foo)
            --     local p = game.create_profiler()
            --     local signal, dist = get_closest_signal(dead_end, de_dir, true)
            --     if signal then
            --         local data = get_rail_data(dead_end)
            --         log2(serpent.block(data, {keyignore={signal_map = true}}), "Rail data")
            --         log2(serpent.block(data.signals[de_dir], {keyignore={signal_map = true}}), "Signal data")
            --         local k = librail.args_to_key(signal.position.x - dead_end.position.x, signal.position.y - dead_end.position.y, signal.direction)
            --         local tmp = data.signal_map[k]
            --         log2(serpent.block(tmp), "The one")
            --     end
            --     p.stop()
            --     profiler2.Stop()
            --     log{"", p}
            --     log("Length: " .. rail.get_rail_segment_length())
            --     render.on(true)
            --     render.mark_rail(dead_end, colors.green, "S")
            --     render.mark_signal(signal, "C", nil, nil, nil, round(dist,1))
            --     render.restore()
            -- else
            --     game.print("No dead end. Face in loco direction and try again")
            -- end
            --::error::
            log(log_entity(selected, "Selected"))
            log2(string.format("%d", position_hash(selected.position.x, selected.position.y, selected.direction or 0)), "key")
        end
    elseif player.vehicle then
        player.vehicle.set_driver(nil)
    end
end
script.on_event("farl_debug_test", farl_test)
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event)
    if event.created_entity.name == "farl" then
        event.created_entity.get_fuel_inventory().insert{name = "solid-fuel", count=2}
    end
end)

local function complete(test)
    if test.force then return true end
    local required = {
        locomotive = true,
        ['rail-signal'] = true,
    }
    local one_of = {
        ['straight-rail'] = true,
        ['curved-rail'] = true,
    }
    for k, _ in pairs(required) do
        if not test[k] then return false end
    end
    for k, _ in pairs(one_of) do
        if test[k] then return true end
    end
    return false
end

local function on_nth_tick(event)
    --print(serpent.line(event))
    local i = global._current_test
    --test_runner.run(test_cases, get_startup_data)

    local test = test_cases[i]
    if not test then
        global._current_test = nil
        global._setup = nil
        global._init = nil
        script.on_nth_tick(event.nth_tick, nil)
        return
    end
    if not global._setup then
        print("---\t" .. test.name .. "\t---")
        print("Creating rails")
        test_runner.create_rails(test, game.get_surface(1))
        --test.create_rails(game.get_surface(1))
        global._setup = 1
        rendering.clear("FARL")
        return
    else
        local j = global._setup
        local case = test.cases[j]
        if case then
            if not global._init then
                print("case " .. j)
                test_cases.init(test, j, game.get_surface(1))
                global._init = true
                rendering.clear("FARL")
                return
            else
                if not test_runner.test_case(case, get_startup_data) then
                    game.print("Failures")
                    global._current_test = nil
                    global._setup = nil
                    global._init = nil
                    script.on_nth_tick(event.nth_tick, nil)
                    return
                end
                case.locomotive.destroy()
                global._init = nil
                global._setup = global._setup + 1
            end
        else
            test_runner.teardown(test)
            global._current_test = global._current_test + 1
            global._setup = nil
            global._init = nil
        end
    end
end

local farl_commands = {

    farl_test_run = function(args)
        render.surface = game.player.surface
        render.player_index = {game.player.index}
        global._current_test = tonumber(args.parameter) or 1
        global._setup = nil
        global._init = nil
        script.on_nth_tick(5, on_nth_tick)

        -- render.surface = game.player.surface
        -- if global._tests then
        -- local tests = global._tests
        -- if args.parameter then
        --     local params = util.split_whitespace(args.parameter)
        --     local name = tostring(params[1])
        --     if global._tests[name] then
        --         tests = {[name] = global._tests[name]}
        --     end
        -- end
        --     rendering.clear()
        --     render.off(true)
        --     local rail, signal, loco
        --     local rail_type
        --     local signal_type = "rail-signal"
        --     local pass, fail = 0, 0
        --     render.ttl = 600
        --     local failure_opts = {square = false, ttl = 1200}
        --     for name, test in pairs(tests) do
        --         if complete(test) then
        --             loco = test.locomotive
        --             rail, signal = get_startup_data(loco)
        --             rail_type = (rail and rail.valid) and rail.type
        --             local success = true
        --             render.on()
        --             if rail then
        --                 if test[rail_type] == rail then
        --                     render.draw_line(rail, loco, colors.white, false, true)
        --                     render.mark_entity(rail, colors.green, "SR")
        --                 else
        --                     if (test["straight-rail"] or test["curved-rail"]) then
        --                         render.mark_entity(test["straight-rail"] or test["curved-rail"], colors.red, "Expected", failure_opts)
        --                     end
        --                     game.print("Wrong rail for test " .. name)
        --                     log2(name, "Failed")
        --                     log2(type(rail), "Expected rail, got")
        --                     success = false
        --                     render.line_to_player(game.player, rail, colors.red, true, true)
        --                     render.mark_entity(rail, colors.red, "Got", failure_opts)
        --                     render.mark_entity(test[rail_type], colors.red, "Expected", failure_opts)
        --                     render.draw_line(rail, loco, colors.red, false, true)
        --                 end

        --                 if test[signal_type] == signal then
        --                     render.draw_line(signal, loco, colors.white, false, true)
        --                     render.mark_entity(signal, colors.blue, "C")
        --                 else
        --                     game.print("Wrong signal for test " .. name)
        --                     log2(name, "Failed")
        --                     log2(type(signal), "Expected signal, got")
        --                     success = false
        --                     render.line_to_player(game.player, signal, colors.red, true, true)
        --                     render.mark_entity(signal, colors.red, "Got", failure_opts)
        --                     render.mark_entity(test[signal_type], colors.red, "Expected", failure_opts)
        --                     render.draw_line(signal, loco, colors.red, false, true)
        --                     render.draw_line(test[signal_type], loco, colors.red, false, true)
        --                 end
        --             else

        --                 assert(not test["rail-signal"])
        --                 log2(serpent.block(test), "Test")
        --             end
        --             pass = success and pass + 1 or pass
        --             fail = success and fail or fail + 1
        --             render.mark_entity(loco, success and colors.green or colors.red, "")
        --             render.mark_entity_text(loco, name, nil, {top = true})
        --             render.mark_entity_text(loco, success and "passed" or "failed", success and colors.green or colors.red)
        --             render.restore()
        --         end
        --     end
        --     log2(calls, "Rail data calls")
        --     log2(hits, "Hits")
        --     render.ttl = nil
        --     game.print((pass + fail) .. " tests complete: [color=green]" .. pass .. "[/color]/[color=red]" .. fail .. "[/color]")
        --     render.restore()
        -- end
    end,

    farl_test_create = function(args)
        render.on(true)
        global._tests = global._tests or {}
        global._ids_to_tests = global._ids_to_tests or {}
        --log(serpent.block(args))

        local selected = game.player.selected
        local sel_type = (selected and selected.valid) and selected.type
        if args.parameter then
            local params = util.split_whitespace(args.parameter)
            log(serpent.block(params))

            local name = tostring(params[1])
            if not name then return end
            local test = global._tests[name]
            local new = true
            if not test then
                game.print("New test: " .. name)
                test = {name = name}
                global._tests[name] = test
            else
                new = false
                game.print("Editing test: " .. name)
                if params[2] == "force" then
                    game.print("Force completing test")
                    test.force = true
                    return
                end
            end
            global._tests[name] = test
            if sel_type then
                if not new and test[sel_type] then
                    game.print("Updating " .. sel_type)
                    render.mark_entity(test[sel_type], colors.black, "old")
                end
                test[sel_type] = selected
                if sel_type == "locomotive" then
                    if test.id and global._ids_to_tests[test.id] then
                        global._ids_to_tests[test.id] = nil
                    end
                    global._ids_to_tests[selected.unit_number] = test
                    test.id = selected.unit_number
                end
            end

            if complete(test) then
                game.print("Test complete: " .. name)
                --print(serpent.block(test))
                local ttl = {ttl = 150}
                render.mark_entity(test["rail-signal"], nil, "", ttl)
                render.mark_entity(test["straight-rail"], nil, nil, ttl)
                render.mark_entity(test.locomotive, nil, false, ttl)
            end
        end
        render.restore()
    end,

    farl_test_clear = function()
        local selected = game.player.selected
        local sel_type = (selected and selected.valid) and selected.type
        if global._ids_to_tests then
            if sel_type == "locomotive" then
                local t = global._ids_to_tests[selected.unit_number]
                if t then
                    global._tests[t.name] = nil
                    global._ids_to_tests[selected.unit_number] = nil
                    log2(t.name, "Removed test")
                end
            end
        end
    end,

    farl_test_signals = function(args)
        rendering.clear()
        local selected = game.player.selected
        local sel_type = (selected and selected.valid) and selected.type
        if sel_type == "curved-rail" or sel_type == "straight-rail" then
            render.on()
            render.surface = game.player.surface
            print("-----------Test signals----------")
            local card = tonumber(args.parameter or 0)
            local rail_dir = get_rail_direction(selected, card)
            if not rail_dir then
                card = math.abs(card - 1) % 1
                print("f " .. card)
                rail_dir = get_rail_direction(selected, card)
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
    end,

    farl_save = function()
        lib.saveVar(pre_rotate, "pre")
        lib.saveVar(post_rotate, "post")
    end,

    clear_signals = function()
        rendering.clear()
    end,

    test_rendering = function(args)
        if args.parameter then
            rendering.clear()
        else
            rendering.draw_text{
                target = game.get_player(args.player_index).character,
                surface = game.surfaces[1],
                text = "Test",
                color = {}
            }
        end
    end,

    foo = function()
        --XxxxxxxYyyyyyyD
        --112345691234567
        --(x+5)*1000000 + (y+5)*1000 + d

        -- local positions = {}
        -- log("hash start")
        -- local h
        -- for i = 1999900, 2000000, 0.5 do
        --     for j = 1999900, 2000000, 0.5 do
        --         for d = 0, 7 do
        --             --print(i, j, d)
        --             h = position_hash(i, j, d)
        --             positions[h] = (positions[h] or 0) + 1
        --         end
        --     end
        -- end
        -- local collisions = 0
        -- local c = 0
        -- for _, k in pairs(positions) do
        --     c = c + 1
        --     if k > 1 then
        --         collisions = collisions + 1
        --     end
        -- end
        -- log("hash stop")
        -- --log2(next(positions))
        -- log("c: " .. c)
        -- log("table_size: " ..table_size(positions))
        -- log("Collisions: " .. collisions)
        do
    local c_entities, c_cases
    local rid_to_hash, sid_to_hash
    local h
    local out
    for tci, test_case in pairs(test_cases) do
        rid_to_hash, sid_to_hash = {}, {}
        c_cases, c_entities = {}, {rails = {}, signals = {}}
        out = {"rails = {"}
        if tci < 6 and tci > 1 then
            for rid, rail in pairs(test_case.created_entities.rails) do
                h = position_hash(rail.position.x, rail.position.y, rail.direction or 0)
                c_entities.rails[h] = rail
                rid_to_hash[rid] = h
                table.insert(out, string.format("[%d] = %s,", h, serpent.line(rail)))
            end
            table.insert(out, "},\nsignals = {")
            for sid, signal in pairs(test_case.created_entities.signals) do
                h = position_hash(signal.position.x, signal.position.y, signal.direction or 0)
                c_entities.signals[h] = signal
                sid_to_hash[sid] = h
                table.insert(out, string.format("[%d] = %s,", h, serpent.line(signal)))
            end
            table.insert(out, "},\ncases = {")
            for i, case in pairs(test_case.cases) do
                if case.signal then
                    case.signal = sid_to_hash[case.signal]
                end
                if case.rail then
                    case.rail = rid_to_hash[case.rail]
                end
                c_cases[i] = serpent.line(case) .. ","
                table.insert(out, c_cases[i])
            end
            table.insert(out, "}")
            log(table_size(c_entities))
            game.write_file("Test" .. tci ..".lua", table.concat(out, "\n"))
        end
    end
end
    end,

    farl_test = function()
        --local _fns = fns
        --fns = {}
        -- local mt = {
        --     __index = function(_, f)
        --         print("*access to element " .. tostring(f))
        --         log(type(_fns[f]))
        --         --print(tostring(...))
        --         --_fns[f](...)
        --         log("foo")
        --     end,

        --     __newindex = function(t,k,v)
        --         print("*update of element " .. tostring(k) ..
        --                             " to " .. tostring(v))
        --         t[k] = v
        --     end,
        -- }
        -- setmetatable(fns, mt)
        local fns = {}

        function fns.test(x)
            --print("Got called with " .. tostring(x))
            return fns.recursive(x, 0, 1)
        end

        function fns.testReturns(a, b, c, d)
            return a, b, c, d
        end

        function fns.recursive(n)
            if n <= 1 then
                return n
            end
            return fns.recursive(n - 1) + fns.recursive(n - 2)
        end

        function fns.recursive2(n, a, b)
            if n == 0 then
                return a
            end
            if n == 1 then
                return b
            end
            return fns.recursive2(n - 1, b, a + b)
        end

        local a, b, c, d = 1, 2, nil, 4

        local a1, b1, c1, d1 = fns.testReturns(a, b, c, d)
        assert(a1 == 1)
        assert(b1 == 2)
        assert(c1 == nil)
        assert(d1 == 4)
        print(tostring(fns.test))

        profiler.Start(false, fns)
        local r = fns.test(9)
        log(r)
        profiler.Stop()

        -- profiler.Start()
        -- -- local r = fns.recursive2(9, 0, 1)
        -- -- log(r)
        -- r = fns.recursive(9)
        -- log(r)
        -- profiler.Stop()

        local p = game.create_profiler()
        fns.test(9)
        p.stop()
        log{"", "bare bones ", p}
    end,
}

for name, f in pairs(farl_commands) do
    commands.add_command(name, "", f)
end