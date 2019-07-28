local Blueprint = {}
local Position = require 'Position'
local librail = require 'librail'
local lib = require 'lib_control'
local log2 = lib.log2
local math = math

local _rotations = {
    [-1] = { sin = -1, cos = 0},
    [1] = { sin = 1, cos = 0},
    [2] = { sin = 0, cos = -1},
}
_rotations[-2] = _rotations[2]
local function rotate_position(pos, _t)
    return {x = _t.cos * pos.x - _t.sin * pos.y, y = _t.sin * pos.x + _t.cos * pos.y}
end

local function rotate_entity(ent, rotations, rot)
    ent.direction = ent.direction or 0
    if rotations and rot then
        ent.position = rotate_position(ent.position, rot)
        ent.direction = ((ent.direction) + 2 * rotations) % 8
        ent.pickup_position = ent.pickup_position and rotate_position(ent.pickup_position, rot) or nil
        ent.drop_position = ent.drop_position and rotate_position(ent.drop_position, rot) or nil
    end
    return ent
end

Blueprint.rotate = function(bp, signal_types)
    local ents = bp.get_blueprint_entities()
    local tiles = bp.get_blueprint_tiles()

    local rotations
    local chain_signal
    local is_diagonal = false
    for i, ent in pairs(ents) do
        if ent.name == "rail-chain-signal" then
            ent.direction = ent.direction or 0
            if ent.direction % 2 == 0 then
                rotations = (4 - ent.direction) / 2
            else
                rotations = (5 - ent.direction) / 2
                is_diagonal = true
            end
            ent.chain = true
            chain_signal = ent
            break
        end
    end
    if not chain_signal then
        return
    end
    local rot = _rotations[rotations]
    if tiles and rotations ~= 0 then
        log(serpent.block(tiles))
        for _, tile in pairs(tiles) do
            --tiles 'center' is the top left corner, rotate the real center of the tile
            local x, y = tile.position.x + 0.5, tile.position.y + 0.5
            tile.position = rotate_position({x = x, y = y}, rot)
            -- tile.position.x = (cos * x - sin * y) - 0.5
            -- tile.position.y = (sin * x + cos * y) - 0.5
        end
        --? TODO fix tile position
        bp.set_blueprint_tiles(tiles)
    end

    local proto
    local bp_data = {signals = {}, lanes = {}}
    for i, ent in pairs(ents) do
        proto = game.entity_prototypes[ent.name].type
        ent.type = proto
        ents[i] = rotate_entity(ent, rotations, rot)
        if signal_types[proto] then
            bp_data.signals[ent.entity_number] = ent
        else
            bp_data[proto] = bp_data[proto] or {}
            bp_data[proto][ent.entity_number] = ent
        end
    end
    return ents, bp_data, chain_signal, is_diagonal
end

function Blueprint.parse(bp_data, chain_signal, is_diagonal, ents)
    local main_rail, main_pole

    --pair signals with rails
    local offset, k, rail_data
    for _s, signal in pairs(bp_data.signals) do
        for _, rail in pairs(bp_data["straight-rail"]) do
            rail_data = librail.rail_data[rail.type][rail.direction]
            offset = Position.subtract(signal.position, rail.position)
            k = librail.args_to_key(offset.x, offset.y, signal.direction)
            if rail_data.signal_map[k] then
                if signal == chain_signal then
                    rail.main = true
                    main_rail = rail
                end
                rail.travel_dir = (signal.direction + 4) % 8
                --rail.signals = rail_data.signals[rail_data.travel_to_rd[rail.travel_dir]]
                signal.rail = rail.entity_number
                rail.signal = signal
            end
        end
        if not signal.rail then
            game.print("Lone signal")
        end
    end
    bp_data.main_rail = main_rail
    assert(main_rail)
    assert(chain_signal)

    local p0 = lib.diagonal_to_real_pos(main_rail)
    local b = 1
    local div = math.sqrt(2)
    if not is_diagonal then
        b, div = 0, 1
    end
    local c = -(p0.x + b * p0.y)
    local dist, wire_dist, abs_dist, r_pos
    local max_distance, min_to_chain = 0, math.huge
    local box = {}
    for _, ent in pairs(ents) do
        r_pos = lib.diagonal_to_real_pos(ent)
        --distance to the line through the rail, left/right offset basically
        dist = (r_pos.x + b * r_pos.y + c)
        ent.distance = is_diagonal and dist / 2 or dist
        if ent.type == "straight-rail" then
            ent.track_distance = dist / 2
            table.insert(bp_data.lanes, ent)
        end
        dist = dist / div
        if not is_diagonal then
            lib.rotate_bounding_box(game.entity_prototypes[ent.name].collision_box, ent.direction, box, r_pos)
        end

        if ent.type == "electric-pole" then
            abs_dist = math.abs(dist)
            wire_dist = game.entity_prototypes[ent.name].max_wire_distance
            if wire_dist == max_distance and abs_dist < min_to_chain then
                min_to_chain = abs_dist
                main_pole = ent
            end
            if wire_dist > max_distance then
                max_distance = wire_dist
                main_pole = ent
                min_to_chain = abs_dist
            end
        end
    end

    table.sort(bp_data.lanes, function(A, B) return A.track_distance < B.track_distance end)

    if main_pole then
        bp_data.main_pole = main_pole
        main_pole.main = true
        main_pole.signal_offsets = {}
        --for "place signals with every Xth pole" mode
        for _, signal in pairs(bp_data.signals) do
            table.insert(main_pole.signal_offsets, Position.subtract(signal.position, main_pole.position))
        end
    end


    if is_diagonal then
        box = {}
        local real_pos = main_rail.position
        local pos
        for _, ent in pairs(ents) do
            if ent.type == "straight-rail" and not ent.main then
                ent.position.y = main_rail.position.y
                ent.position.x = 2 * ent.track_distance + main_rail.position.x
                ent.direction = main_rail.direction
                lib.rotate_bounding_box(game.entity_prototypes[ent.name].collision_box, ent.direction, box, lib.diagonal_to_real_pos(ent))
                if ent.signal then
                    local data = librail.rail_data[ent.type][ent.direction]
                    local _rd = data.travel_to_rd[ent.travel_dir]
                    pos = data.signals[_rd][1]
                    ent.signal.position = Position.add(ent.position, pos)
                    lib.rotate_bounding_box(game.entity_prototypes[ent.signal.name].collision_box, ent.signal.direction, box, ent.signal.position)
                end

            elseif not (ent.type == "rail-signal" or ent.type == "rail-chain-signal") then
                pos = Position.subtract(ent.position, real_pos)
                log2(pos, "Pos")
                ent.position.x = ent.position.x + pos.y
                ent.position.y = ent.position.y - pos.y
                lib.rotate_bounding_box(game.entity_prototypes[ent.name].collision_box, ent.direction, box, lib.diagonal_to_real_pos(ent))
            end
        end
    end
    box.left_top = Position.subtract(box.left_top, p0)
    box.right_bottom = Position.subtract(box.right_bottom, p0)
    box.left_top.x = math.floor(box.left_top.x - 0.5)
    box.left_top.y = math.floor(box.left_top.y)
    box.right_bottom.x = math.ceil(box.right_bottom.x + 0.5)
    box.right_bottom.y = is_diagonal and math.floor(box.right_bottom.y) or math.ceil(box.right_bottom.y)
    box.h = math.abs(box.right_bottom.y - box.left_top.y)

    bp_data.bounding_box = box

    return main_rail
end

return Blueprint
