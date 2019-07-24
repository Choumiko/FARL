local Blueprint = {}
local Position = require 'Position'
local math = math

--[signal_dir] = {[raildir] = {offset (signal - rail)}}
local rails_signals = {
    [0] = {
        [0] = {
            {x = -1.5, y = -0.5, traveldir = 4},
            {x = -1.5, y =  0.5, traveldir = 4},
        }
    },
    [1] = {
        [3] = {
            {x = -0.5, y = -0.5, traveldir = 5}
        },
        [7] = {
            {x = -1.5, y = -1.5, traveldir = 5},

        }
    },
    [2] = {
        [2] = {
            {x =  -0.5, y =  -1.5, traveldir = 6},
            {x =   0.5, y =  -1.5, traveldir = 6},
        }
    },
    [3] = {
        [1] = {
            {x = 1.5, y = -1.5, traveldir = 7},

        },
        [5] = {
            {x = 0.5, y = -0.5, traveldir = 7}
        }
    },
    [4] = {
        [0] = {
            {x =  1.5, y = -0.5, traveldir = 0},
            {x =  1.5, y =  0.5, traveldir = 0},
        }
    },
    [5] = {
        [3] = {
            {x = 1.5, y = 1.5, traveldir = 1}
        },
        [7] = {
            {x = 0.5, y = 0.5, traveldir = 1},

        }
    },
    [6] = {
        [2] = {
            {x =  -0.5, y =  1.5, traveldir = 2},
            {x =   0.5, y =  1.5, traveldir = 2},
        }
    },
    [7] = {
        [1] = {
            {x = -0.5, y = 0.5, traveldir = 3},

        },
        [5] = {
            {x = -1.5, y = 1.5, traveldir = 3}
        }
    },
}

Blueprint.group_entities = function(bp)
    local original_string = bp.export_stack()
    local e = bp.get_blueprint_entities()

    for i=1, #e do
        if e[i].name == "rail-chain-signal" then
            local dir = e[i].direction or 0
            if not (dir == 4 or dir == 5) then
                local rot = (dir % 2 == 0) and (4 - dir ) * 45 or (5 - dir ) * 45
                --log(string.format("Rotating blueprint by %d degrees (dir: %d)", rot, dir))
                Blueprint.rotate(bp,rot)
                e = bp.get_blueprint_entities()
            end
            break
        end
    end

    local offsets = {
        pole=false, chain=false, poleEntities={}, railEntities={},
        rails={}, signals={}, concrete={}, lanes={}}
    local bpType = false
    local rails = 0
    local poles = {}
    local all_signals = {}
    local box = {tl={x=0,y=0}, br={x=0,y=0}}
    for i=1,#e do
        local position = FARL.diagonal_to_real_pos(e[i])--luacheck: ignore
        local prototype = game.entity_prototypes[e[i].name]
        if box.tl.x > position.x then box.tl.x = position.x end
        if box.tl.y > position.y then box.tl.y = position.y end

        if box.br.x < position.x then box.br.x = position.x end
        if box.br.y < position.y then box.br.y = position.y end

        local dir = e[i].direction or 0
        local name = e[i].name

        if name == "rail-chain-signal" and not offsets.chain then
          --game.print(string.format('chain2 dir: %d position: %s', e[i].direction, Position.tostring(e[i].position)))
            offsets.chain = {direction = dir, name = e[i].name, position = e[i].position}
            table.insert(all_signals, {name = "rail-signal", direction = dir, position = e[i].position, entity_number = e[i].entity_number})
            -- collect all poles in bp
        elseif prototype and prototype.type == "electric-pole" then
            table.insert(poles, {name = name, direction = dir, position = e[i].position, distance_to_chain = 0})
        elseif prototype and prototype.type == "straight-rail" then
            rails = rails + 1
            if not bpType then
                bpType = (dir == 0 or dir == 4) and "straight" or "diagonal"
            end
            if  (bpType == "diagonal" and (dir == 3 or dir == 7)) or
                (bpType == "straight" and (dir == 0 or dir == 4)) then
                table.insert(offsets.rails, {name = name, direction = dir, position = e[i].position, type = game.entity_prototypes[name].type, entity_number = e[i].entity_number})
            else
                return false, {"msg-bp-rail-direction"}
            end
        elseif name == "rail-signal" then
            table.insert(offsets.signals, {name = name, direction = dir, position = e[i].position, entity_number = e[i].entity_number})
            table.insert(all_signals, {name = "rail-signal", direction = dir, position = e[i].position, entity_number = e[i].entity_number})
        else
            local e_type = game.entity_prototypes[name].type
            local rail_entities = {["wall"]=true}
            if not rail_entities[e_type] then
                table.insert(offsets.poleEntities, {
                    name = name, direction = dir, position = e[i].position, pickup_position = e[i].pickup_position,
                    drop_position = e[i].drop_position, request_filters = e[i].request_filters, recipe = e[i].recipe
                })
            else
                table.insert(offsets.railEntities, {name = name, direction = dir, position = e[i].position})
            end
        end
    end

    for i, rail in pairs(offsets.rails) do
        for _, signal in pairs(all_signals) do
            for _, data in pairs(rails_signals[signal.direction]) do
                for _, offset in pairs(data) do
                    local pos = Position.subtract(signal.position, rail.position)
                    if Position.equals(pos, offset) then
                        offsets.rails[i].signal_number = signal.entity_number
                        offsets.rails[i].signal = signal
                    end
                end
            end
        end
    end

    if offsets.chain then
        local chain_position = offsets.chain.position
        for _, pole in pairs(poles) do
            pole.distance_to_chain = Position.distance_squared(chain_position, pole.position)
        end
    end
    --log(serpent.block(offsets.rails))
    return bpType, rails, poles, box, offsets, original_string
end

Blueprint.get_max_pole = function(poles, offsets)
    local max = 0
    local max_index
    local min_distance = math.huge
    --local name
    for i,p in pairs(poles) do
        --name = p.name--is_placer_or_base[p.name] and "ret-pole-wire" or p.name
        local wire_distance = game.entity_prototypes[p.name].max_wire_distance
        --choose pole closer to the chainsignal as the main pole in case of a tie
        if wire_distance == max and p.distance_to_chain < min_distance then
            min_distance = p.distance_to_chain
            max_index = i
        end
        if wire_distance > max then
            max = wire_distance
            max_index = i
        end
    end
    offsets.pole = poles[max_index]
    for i,p in pairs(poles) do
        if i ~= max_index then
            table.insert(offsets.poleEntities, p)
        end
    end
end

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

return Blueprint
