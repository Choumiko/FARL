local lib = require 'lib_control'
local diagonal_to_real_pos = lib.diagonal_to_real_pos
--local find_key = lib.find_key
local Position = require 'Position'
local round = lib.round

local colors = {
    red = {r = 1, g = 0, b = 0},
    green = {r = 0, g = 1, b = 0},
    orange = {r = 1, g = 0.63, b = 0.259 },
    blue = {r = 0, g = 0, b = 1},
    white = {r = 1, g = 1, b = 1},
    black = {r = 0, g = 0, b = 0},
}
local rd = defines.rail_direction
colors[rd.front] = colors.green
colors[rd.back] = colors.red
colors.alternate = {colors.green, colors.blue, colors.white}

local render = {
    player_index = nil,
    surface = nil,
    colors = colors,
    defaults = {
        alt = false,
        square = false,
        color = colors.white
    },
    old_render = false,
}

function render.on(save)
    if save then render.old_render = render.enabled end
    render.enabled = true
end

function render.off(save)
    if save then render.old_render = render.enabled end
    render.enabled = false
end

function render.save()
    render.old_render = render.enabled
end

function render.restore()
    render.enabled = render.old_render
end


local function not_nil_defaults(opts)--luacheck: no unused
    if not opts then
        return render.defaults
    end
    for k, v in pairs(render.defaults) do
        if opts[k] == nil then
            opts[k] = v
        end
    end
    return opts
end
local _opts = {
    square = true
}
not_nil_defaults(_opts)
--print(serpent.block(_opts))

function render.mark_entity(entity, color, text, opts)
    if not (render.enabled and entity and entity.valid) then return end
    opts = not_nil_defaults(opts)
    local ret = {}
    text = tostring(text)
    if not opts.square then
        ret[rendering.draw_circle{
            color = color or opts.color,
            radius = 0.25,
            filled = true,
            target = entity,
            target_offset = opts.target_offset or nil,--and {opts.target_offset.x, opts.target_offset.y}
            surface = render.surface or entity.surface,
            time_to_live = opts.ttl or render.ttl,
            only_in_alt_mode = opts.alt,
            players = render.player_index
        }] = true
    else
        ret[rendering.draw_rectangle{
            color = color or opts.color,
            width = 1,
            filled = false,
            left_top = entity,
            left_top_offset = {-0.25, -0.25},
            right_bottom = entity,
            right_bottom_offset = {0.25, 0.25},
            surface = render.surface or entity.surface,
            time_to_live = opts.ttl or render.ttl,
            only_in_alt_mode = opts.alt,
            players = render.player_index
        }] = true
    end
    if text and text ~= "" then
        ret[rendering.draw_text{
            text = text,
            color = colors.orange,
            target = entity,
            target_offset = {0, -0.3},
            alignment = "center",
            surface = render.surface or entity.surface,
            time_to_live = opts.ttl or render.ttl,
            only_in_alt_mode = opts.alt,
            players = render.player_index
        }] = true
    end
    return ret
end

-- function render.mark_segment(rail, color, ttl)--luacheck: no unused
--     if not (render.enabled and rail and rail.valid) then return end
--     local to, to_dir = rail.get_rail_segment_end(rd.back)
--     to_dir = find_key(rd, to_dir)
--     to = diagonal_to_real_pos(to)
--     local from, from_dir = rail.get_rail_segment_end(rd.front)
--     from_dir = find_key(rd, from_dir)
--     from = diagonal_to_real_pos(from)
--     local off = {x = 0.5, y = 0}
--     local surface = rail.surface
--     local ret = {}
--     ret[rendering.draw_line{
--     color = color or colors.white,
--     width = 2,
--     from = from,
--     to = to,
--     surface = render.surface or surface,
--     players = render.player_index
--     }] = true
--     ret[rendering.draw_text{
--         text = from_dir,
--         color = colors.orange,
--         target = Position.add(from, off),
--         alignment = "center",
--         surface = render.surface or surface,
--         time_to_live = render.ttl or ttl,
--         players = render.player_index
--     }] = true
--     ret[rendering.draw_text{
--         text = to_dir,
--         color = colors.orange,
--         target = Position.add(to, off),
--         alignment = "center",
--         surface = render.surface or surface,
--         time_to_live = render.ttl or ttl,
--         players = render.player_index
--     }] = true
--     return ret
-- end

function render.mark_rail(rail, color, text, square, opts)
    opts = not_nil_defaults(opts)
    if not (render.enabled and rail and rail.valid) then return end
    local lt, rb = {-0.25, -0.25, x = -0.25, y = -0.25}, {0.25, 0.25, x = 0.25, y = 0.25}
    local text_offset = {0, -0.3, x = 0, y = -0.3}
    local offset
    local default = {
        color = color or colors.white,
        surface = render.surface or rail.surface,
        time_to_live = render.ttl or opts.ttl,
        players = render.player_index,
        only_in_alt_mode = opts.alt,
    }
    if rail.type == "straight-rail" and rail.direction % 2 == 1 then
        local fix = lib._diagonal_data[rail.direction]
        offset = {fix.x, fix.y}
        lt = Position.add(fix, lt)
        rb = Position.add(fix, rb)
        text_offset = Position.add(text_offset, fix)
        text_offset = {text_offset.x, text_offset.y}
    end
    if not square then
        default.radius = 0.25
        default.filled = true
        default.target = rail
        default.target_offset = offset
        rendering.draw_circle(default)
    else
        default.width = 1
        default.filled = false
        default.left_top = rail
        default.left_top_offset = lt
        default.right_bottom = rail
        default.right_bottom_offset = rb
        rendering.draw_rectangle(default)
    end
    default.text = text
    default.color = colors.orange
    default.target = rail
    default.target_offset = text_offset
    default.alignment = "center"
    if text then
        rendering.draw_text(default)
    end
end

function render.mark_entity_text(entity, text, color, opts)
    opts = not_nil_defaults(opts)
    if not(render.enabled and entity and entity.valid and type(text) ~= "boolean") then return end
    local offset = opts.top and {x = 0, y = -0.85} or {x = 0, y = 0.15}
    if entity.type == "straight-rail" and entity.direction % 2 == 1 then
        entity = diagonal_to_real_pos(entity)
        entity = Position.add(entity, offset)
    end
    return rendering.draw_text{
            text = text,
            color = color or colors.orange,
            target = entity,
            target_offset = offset,
            alignment = "center",
            surface = render.surface or entity.surface,
            only_in_alt_mode = opts.alt,
            time_to_live = render.ttl or opts.ttl,
            players = render.player_index
        }
end

function render.mark_signal(signal, text, color, square, opts, distance)
    if not (render.enabled and signal and signal.valid) then return end
    opts = not_nil_defaults(opts)
    opts.square = square
    local ret = render.mark_entity(signal, color, text or signal.direction, opts)
    if distance then
        if type(distance) == "number" then
            distance = round(distance, 1)
        end
        ret[render.mark_entity_text(signal, distance, colors.orange, opts)] = true
    end
    return ret
end

function render.draw_line(from, to, color, alt, dash, opts)
    if not (render.enabled and from and (from.valid or from.x) and to and (to.valid or to.x)) then return end
    opts = not_nil_defaults(opts)
    if from.valid and from.is_player() then from = from.character end
    if from.type == "straight-rail" and from.direction % 2 == 1 then
        from = diagonal_to_real_pos(from)
    end
    if to.type == "straight-rail" and to.direction % 2 == 1 then
        to = diagonal_to_real_pos(to)
    end
    if opts.id and rendering.is_valid(opts.id) then
        rendering.set_from(opts.id, from, opts.from_offset or {x = 0, y = 0})
        rendering.set_to(opts.id, to, opts.to_offset or {x = 0, y = 0})
        return opts.id
    else
        return rendering.draw_line{
            color = color or colors.black,
            width = 2,
            from = from,
            from_offset = opts.from_offset,
            to = to,
            to_offset = opts.to_offset,
            gap_length = dash and 0.5 or nil,
            dash_length = dash and 0.5 or nil,
            surface = render.surface or from.surface,
            time_to_live = render.ttl or opts.ttl,
            players = render.player_index,
            only_in_alt_mode = alt
        }
    end
end

function render.draw_rectangle(from, to, color, alt, opts)
    if not (render.enabled and from and (from.valid or from.x) and to and (to.valid or to.x)) then return end
    opts = not_nil_defaults(opts)
    if from.valid and from.is_player() then from = from.character end
    if opts.id and rendering.is_valid(opts.id) then
        rendering.set_left_top(opts.id, from, opts.left_top_offset or {x = 0, y = 0})
        rendering.set_right_bottom(opts.id, to, opts.right_bottom_offset or {x = 0, y = 0})
        return opts.id
    else
        return rendering.draw_rectangle{
            color = color or colors.orange,
            width = opts.width or 2,
            left_top = from,
            left_top_offset = opts.left_top_offset,
            right_bottom = to,
            right_bottom_offset = opts.right_bottom_offset,
            surface = render.surface or from.surface,
            time_to_live = render.ttl or opts.ttl,
            players = render.player_index,
            only_in_alt_mode = alt
        }
    end
end

function render.draw_area(area, color, opts)
    opts = not_nil_defaults(opts)
    return render.draw_rectangle(area.left_top, area.right_bottom, color, opts.alt, opts)
end

function render.draw_circle(center, radius, color, alt, opts)
    opts = not_nil_defaults(opts)
    return rendering.draw_circle{
        color = color or opts.color or colors.orange,
        radius = radius or 0.25,
        filled = true,
        target = center,
        target_offset = opts.target_offset or nil,--and {opts.target_offset.x, opts.target_offset.y}
        surface = render.surface or center.surface,
        time_to_live = opts.ttl or render.ttl,
        only_in_alt_mode = alt or opts.alt,
        players = render.player_index
    }
end

function render.line_to_player(player, to, color, alt, dash)
    if player.is_player() then player = player.character end
    return render.draw_line(player, to, color, alt, dash)
end

return render