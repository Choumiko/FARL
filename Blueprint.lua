--- Blueprint parsing
--@module Blueprint

Blueprint = {}--luacheck: allow defined top
local math = math
---Group entities in the blueprint
--@param e entities
--@return Untyped Type of the blueprint
--@return Untyped No of rails
--@return Untyped poles in the blueprint
--@return Untyped boundingbox
--@return Untyped other entities
Blueprint.group_entities = function(bp)
    local e = bp.get_blueprint_entities()
    for i=1, #e do
        if e[i].name == "rail-chain-signal" then
            local dir = e[i].direction or 0
            --local _, name = table.find(defines.direction, function(v, _, direction) return v == direction end, (dir + 4) % 8)
            --game.print("Found chainsignal for driving due " .. tostring(name))
            if not (dir == 4 or dir == 5) then
                local rot = (dir % 2 == 0) and math.abs(4 - dir ) * 45 or math.abs(5 - dir ) * 45
                --game.print(string.format("Rotating blueprint by %d degrees (dir: %d)", rot, dir))
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
    local box = {tl={x=0,y=0}, br={x=0,y=0}}
    for i=1,#e do
        local position = FARL.diagonal_to_real_pos(e[i])
        local prototype = game.entity_prototypes[e[i].name]
        if box.tl.x > position.x then box.tl.x = position.x end
        if box.tl.y > position.y then box.tl.y = position.y end

        if box.br.x < position.x then box.br.x = position.x end
        if box.br.y < position.y then box.br.y = position.y end

        local dir = e[i].direction or 0
        local name = e[i].name

        if name == "rail-chain-signal" and not offsets.chain then
            offsets.chain = {direction = dir, name = e[i].name, position = e[i].position}
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
                table.insert(offsets.rails, {name = name, direction = dir, position = e[i].position, type = game.entity_prototypes[name].type})
            else
                return false, {"msg-bp-rail-direction"}
            end
        elseif name == "rail-signal" then
            table.insert(offsets.signals, {name = name, direction = dir, position = e[i].position})
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
    if offsets.chain then
        local chain_position = offsets.chain.position
        for _, pole in pairs(poles) do
            pole.distance_to_chain = Position.distance_squared(chain_position, pole.position)
        end
    end
    return bpType, rails, poles, box, offsets
end

Blueprint.get_max_pole = function(poles, offsets)
    local max = 0
    local max_index
    local min_distance = math.huge
    for i,p in pairs(poles) do
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

-- rotate a blueprint, return entities, tiles
Blueprint.rotate = function(bp, degree)
    local entities = bp.get_blueprint_entities()
    local tiles = bp.get_blueprint_tiles()
    local rad = math.rad(degree)
    local cos, sin = math.cos(rad), math.sin(rad)
    if degree == 180 then
        sin = 0
        cos = -1
    end
    local rotate = function(pos)
        return { x = cos * pos.x - sin * pos.y, y = sin * pos.x + cos * pos.y }
    end
    --local r = { { x = cos, y = -sin }, { x = sin, y = cos } } --counter clockwise
    local x, y
    for _, entity in pairs(entities) do
        x, y = entity.position.x, entity.position.y
        entity.position.x = cos * x - sin * y
        entity.position.y = sin * x + cos * y
        entity.direction = entity.direction and ( entity.direction - degree / 45 ) % 8 or ( -degree / 45 ) % 8
        entity.pickup_position = entity.pickup_position and rotate(entity.pickup_position) or nil
        entity.drop_position = entity.drop_position and rotate(entity.drop_position) or nil
    end
    bp.set_blueprint_entities(entities)
    if tiles then
        for _, tile in pairs(tiles) do
            --tiles 'center' is the top left corner, rotate the real center of the tile
            x, y = tile.position.x + 0.5, tile.position.y + 0.5
            tile.position.x = (cos * x - sin * y) - 0.5
            tile.position.y = (sin * x + cos * y) - 0.5
        end
        --TODO fix tile position
        bp.set_blueprint_tiles(tiles)
    end
    --game.print("Done rotating")
end
