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
            local _, name = table.find(defines.direction, function(v, _, direction) return v == direction end, (dir + 4) % 8)
            game.print("Found chainsignal for driving due " .. tostring(name))
            if not (dir == 4 or dir == 5) then
                local rot = (dir % 2 == 0) and math.abs(4 - dir ) * 45 or math.abs(5 - dir ) * 45
                game.print(string.format("Rotating blueprint by %d degrees (dir: %d)", rot, dir))
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
            table.insert(poles, {name = name, direction = dir, position = e[i].position})
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
    return bpType, rails, poles, box, offsets
end

Blueprint.get_max_pole = function(poles, offsets)
    local max = 0
    local max_index
    for i,p in pairs(poles) do
        if game.entity_prototypes[p.name].max_wire_distance > max then
            max = game.entity_prototypes[p.name].max_wire_distance
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
    --local r = { { x = cos, y = -sin }, { x = sin, y = cos } } --counter clockwise
    local x, y
    for _, entity in pairs(entities) do
        x, y = entity.position.x, entity.position.y
        entity.position.x = cos * x - sin * y
        entity.position.y = sin * x + cos * y
        entity.direction = entity.direction and ( entity.direction - degree / 45 ) % 8 or ( -degree / 45 ) % 8
    end
    bp.set_blueprint_entities(entities)
    if tiles then
        for _, tile in pairs(tiles) do
            x, y = tile.position.x, tile.position.y
            tile.position.x = cos * x - sin * y
            tile.position.y = sin * x + cos * y
        end
        --TODO fix tile position
        bp.set_blueprint_tiles(tiles)
    end
    game.print("Done rotating")
end

Blueprint.compare = function()
    local function rotate(pos, degree)
        local rad = math.rad(degree)
        local cos, sin = math.cos(rad), math.sin(rad)
        local r = { { x = cos, y = -sin }, { x = sin, y = cos } } --counter clockwise
        local ret = { x = 0, y = 0 }
        ret.x = pos.x * r[1].x + pos.y * r[1].y
        ret.y = pos.x * r[2].x + pos.y * r[2].y
        return ret
    end
    --local diff = dir % 2 == 0 and dir or dir - 1
    --local rad = diff * (math.pi / 4)
    --rotate({x=0,y=0}, rad)

    local blueprints = GUI.findSetupBlueprintsInHotbar(game.player)
    local entities1 = blueprints[1].get_blueprint_entities()
    local entities2 = blueprints[2].get_blueprint_entities()
    game.write_file('farl_blueprints', serpent.block(entities1, {comment=false, sparse=false, name = blueprints[1].label}))
    game.write_file('farl_blueprints', serpent.block(entities2, {comment=false, sparse=false, name = blueprints[2].label}), true)
    local ents = table.deepcopy(entities2)
    for i, entity in pairs(ents) do
        ents[i].position = rotate(entity.position, -90)
        local dir = entity.direction or 0
        ents[i].direction = ( dir - 2 ) % 8
    end
    game.write_file('farl_blueprints', serpent.block(ents, {comment=false, sparse=false, name = "rotated"}), true)
    blueprints = GUI.findBlueprintsInHotbar(game.player)
    local bp = false
    if blueprints ~= nil then
        for _, blueprint in pairs(blueprints) do
            if not blueprint.is_blueprint_setup() then
                bp = blueprint
                break
            end
        end
        if bp then
            bp.set_blueprint_entities(ents)
            local icons = {[1]={index = 1, signal={name = "rail", type="item"}},[2]={index = 2, signal={name = "farl", type="item"}}}
            --TODO fix error
            bp.blueprint_icons = icons
            game.write_file('farl_blueprints', serpent.block(bp.get_blueprint_entities(), {comment=false, sparse=false, name = 'written'}), true)
        else
            game.print('no empty blueprint')
        end
    end
    --game.write_file('farl_blueprints', serpent.block(rot, {comment=false, sparse=false, name = "rot"}), true)
    game.print("Done")
end
