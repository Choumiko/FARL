local Position = require 'stdlib/area/position'
local Area = require 'stdlib/area/area'
require "util"
require "Blueprint"

trigger_events = {} --luacheck: allow defined top

local math = math
local random, floor, ceil = math.random, math.floor, math.ceil
local abs, min, max = math.abs, math.min, math.max

local function round(num, idp)
  local mult = 10 ^ (idp or 0)
  return floor(num * mult + 0.5) / mult
end

local function get_signal_weight(rail, settings)
  local weight = rail.name == settings.rail.curved and 3 or 1
  if rail.name ~= settings.rail.curved and rail.direction % 2 == 1 then
    return 0.75
  end
  return weight
end

local rot = {}
for i = 0, 7 do
  local rad = i * (math.pi / 4)
  rot[rad] = { cos = math.cos(rad), sin = math.sin(rad) }
end

local function rotate(pos, rad)
  if not rot[rad] then error("rot[" .. rad .. "]", 2) end
  local cos, sin = rot[rad].cos, rot[rad].sin
  local r = { { x = cos, y = -sin }, { x = sin, y = cos } }
  local ret = { x = 0, y = 0 }
  ret.x = pos.x * r[1].x + pos.y * r[1].y
  ret.y = pos.x * r[2].x + pos.y * r[2].y
  return ret
end

local function get_fake_rail(rail, position)
  return {name = rail.name, type = rail.type, direction = rail.direction, position = position or Position.copy(rail.position)}
end

local function move_right_forward(pos, direction, right, forward)
  local dir = (direction + 2) % 8
  return Position.translate(Position.translate(pos, dir, right), direction, forward)
end

local function protectedKey(ent)
  if ent.valid then
    return ent.name .. ":" .. ent.position.x .. ":" .. ent.position.y .. ":" .. ent.direction
end
return false
end

local function get_item_name(some_name)
  local name = false
  local count = 1
  if game.item_prototypes[some_name] then
    name = game.item_prototypes[some_name].name
  elseif game.entity_prototypes[some_name] then
    local entityProto = game.entity_prototypes[some_name]
    local items = entityProto.items_to_place_this
    local _, item = next(items)
    name = item.name
    if entityProto.mineable_properties and entityProto.mineable_properties.minable and entityProto.mineable_properties.products then
      for _, item1 in pairs(entityProto.mineable_properties.products) do
        if item1.name == name then
          count = item1.amount or item1.amount_max
        end
      end
    end
  elseif game.tile_prototypes[some_name] then
    name = game.tile_prototypes[some_name].items_to_place_this and next(game.tile_prototypes[some_name].items_to_place_this)
    if name == "landfill" then
      name = false
    end
  end
  return name, count
end

--apiCalls = {find={item=0,tree=0,stone=0,other=0},canplace=0,create=0,count={item=0,tree=0,stone=0,other=0}}
local RED = { r = 0.9 }
local GREEN = { g = 0.7 }
local YELLOW = { r = 0.8, g = 0.8 }
FARL = {}--luacheck: allow defined top
FARL.curvePositions = {
  [0] = { straight = { dir = 0, off = { x = 1, y = 3 } }, diagonal = { dir = 5, off = { x = -1, y = -3 } } },
  [1] = { straight = { dir = 0, off = { x = -1, y = 3 } }, diagonal = { dir = 3, off = { x = 1, y = -3 } } },
  [2] = { straight = { dir = 2, off = { x = -3, y = 1 } }, diagonal = { dir = 7, off = { x = 3, y = -1 } } },
  [3] = { straight = { dir = 2, off = { x = -3, y = -1 } }, diagonal = { dir = 5, off = { x = 3, y = 1 } } },
  [4] = { straight = { dir = 0, off = { x = -1, y = -3 } }, diagonal = { dir = 1, off = { x = 1, y = 3 } } },
  [5] = { straight = { dir = 0, off = { x = 1, y = -3 } }, diagonal = { dir = 7, off = { x = -1, y = 3 } } },
  [6] = { straight = { dir = 2, off = { x = 3, y = -1 } }, diagonal = { dir = 3, off = { x = -3, y = 1 } } },
  [7] = { straight = { dir = 2, off = { x = 3, y = 1 } }, diagonal = { dir = 1, off = { x = -3, y = -1 } } }
}
--local direction ={ N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7}
FARL.input2dir = { [0] = -1, [1] = 0, [2] = 1 }

--[traveldir] ={[raildir]
FARL.signalOffset =
  {
    [0] = {
      [0] = { pos = { x = 1.5, y = 0.5 }, dir = 4 }
    },
    [1] = {
      [3] = { pos = { x = 1.5, y = 1.5 }, dir = 5 },
      [7] = { pos = { x = 0.5, y = 0.5 }, dir = 5 }
    },
    [2] = {
      [2] = { pos = { x = -0.5, y = 1.5 }, dir = 6 }
    },
    [3] = {
      [1] = { pos = { x = -0.5, y = 0.5 }, dir = 7 },
      [5] = { pos = { x = -1.5, y = 1.5 }, dir = 7 }
    },
    [4] = {
      [0] = { pos = { x = -1.5, y = -0.5 }, dir = 0 }
    },
    [5] = {
      [3] = { pos = { x = -0.5, y = -0.5 }, dir = 1 },
      [7] = { pos = { x = -1.5, y = -1.5 }, dir = 1 }
    },
    [6] = {
      [2] = { pos = { x = 0.5, y = -1.5 }, dir = 2 }
    },
    [7] = {
      [1] = { pos = { x = 1.5, y = -1.5 }, dir = 3 },
      [5] = { pos = { x = 0.5, y = -0.5 }, dir = 3 }
    },
  }

FARL.real_signalOffset =
  {
    [0] = {
      [0] = { x = 1.5, y = 0.5 }
    },
    [1] = {
      [3] = { x = 1, y = 1 },
      [7] = { x = 1, y = 1 }
    },
    [2] = {
      [2] = { x = -0.5, y = 1.5 }
    },
    [3] = {
      [1] = { x = -1, y = 1 },
      [5] = { x = -1, y = 1 }
    },
    [4] = {
      [0] = { x = -1.5, y = -0.5 }
    },
    [5] = {
      [3] = { x = -1, y = -1 },
      [7] = { x = -1, y = -1 }
    },
    [6] = {
      [2] = { x = 0.5, y = -1.5 }
    },
    [7] = {
      [1] = { x = 1, y = -1 },
      [5] = { x = 1, y = -1 }
    },
  }

FARL.diagonal_data =
  {
    [1] = { x = 0.5, y = -0.5 },
    [3] = { x = 0.5, y = 0.5 },
    [5] = { x = -0.5, y = 0.5 },
    [7] = { x = -0.5, y = -0.5 }
  }

FARL.diagonal_to_real_pos = function(rail)--luacheck: allow defined top
  local data = FARL.diagonal_data
  if rail.type and rail.type == "straight-rail" then
    local off = data[rail.direction] and data[rail.direction] or { x = 0, y = 0 } --fix for diagonal rails??!
    return Position.add(off, rail.position)
  else
    return rail.position
  end
end

local function moveRail(rail, direction, distance)
  local data = FARL.diagonal_data
  distance = (rail.type == "straight-rail" and rail.direction % 2 == 1) and distance or distance * 2
  local off = data[rail.direction] and data[rail.direction] or { x = 0, y = 0 }
  local pos = Position.add(off, rail.position)
  pos = Position.translate(pos, direction, distance)
  local newRail = get_fake_rail(rail, pos)
  if rail.type == "straight-rail" and rail.direction % 2 == 1 and distance % 2 == 1 then
    newRail.direction = (rail.direction + 4) % 8
  end
  off = data[newRail.direction] or { x = 0, y = 0 }
  pos = Position.subtract(pos, off)
  newRail.position = pos
  return newRail
end

local function get_signal_for_rail(rail, traveldir, end_of_rail)
  local rail_pos = FARL.diagonal_to_real_pos(rail)
  local offset = FARL.real_signalOffset[traveldir][rail.direction]
  local pos = Position.add(rail_pos, offset)
  local dir = (traveldir + 4) % 8
  local signal = { name = "rail-signal", position = pos, direction = dir }
  if rail.force then
    signal.force = rail.force
  end
  if end_of_rail and rail.direction % 2 == 0 then
    signal.position = move_right_forward(signal.position, traveldir, 0, 1)
  end
  return signal
end

FARL.find_entities_filtered = function(self, args, from)

  log(game.tick .. " " .. from .. " " .. serpent.line(args, {comment=false}) .. " found: " .. self.surface.count_entities_filtered(args))

  return self.surface.find_entities_filtered(args)
end

FARL.getIdFromTrain = function(train)
  if train and train.valid and train.locomotives then
    return #train.locomotives.front_movers > 0 and train.locomotives.front_movers[1].unit_number or train.locomotives.back_movers[1].unit_number
  end
end

FARL.newByLocomotive = function(loco)
  local new = {
    locomotive = loco,
    train = loco.train,
    driver = false,
    active = false,
    lastrail = false,
    direction = false,
    input = 1,
    signalCount = { main = 0 },
    cruise = false,
    cruiseInterrupt = 0,
    lastposition = false,
    surface = loco.surface,
    concrete_queue = {},
    rail_queue = {},
  }
  setmetatable(new, { __index = FARL })
  local idLoco = FARL.getIdFromTrain(loco.train)
  global.farl[idLoco] = new
  return new
end

FARL.new = function(player)
  local farl = FARL.newByLocomotive(player.vehicle)
  farl.driver = player
  farl.cheat_mode = player.cheat_mode
  farl.settings = Settings.loadByPlayer(player)
  return farl
end

FARL.setup = function(loco)
  local farl = FARL.findByLocomotive(loco)
  if farl and not farl.active then
    farl.train = loco.train
    farl.frontmover = false
    farl.locomotive = loco
    for _, l in pairs(farl.train.locomotives.front_movers) do
      if l == loco then
        farl.frontmover = true
        break
      end
    end
  end
  return farl
end

FARL.onPlayerEnter = function(player, loco)
  local farl = FARL.setup(loco or player.vehicle)
  if farl and not farl.active then
    farl.driver = player
    farl.settings = Settings.loadByPlayer(player)
    farl.cheat_mode = player.cheat_mode

    if farl.settings.bulldozer and not farl:bulldozerModeAllowed() then
      farl.settings.bulldozer = false
      farl:print({ "msg-bulldozer-error" })
      farl:print({ "msg-bulldozer-disabled" })
    end
    if remote.interfaces.YARM and remote.interfaces.YARM.hide_expando and player.name ~= "farl_player" then
      farl.settings.YARM_old_expando = remote.call("YARM", "hide_expando", player.index)
    end
    global.activeFarls[FARL.getIdFromTrain(farl.train)] = farl
    return farl
  end
end

FARL.onPlayerLeave = function(player)
  for _, f in pairs(global.farl) do
    if f.driver and f.driver == player then
      f:deactivate()
      global.activeFarls[FARL.getIdFromTrain(f.train)] = nil
      f.driver = false
      f.lastMove = nil
      f.railBelow = nil
      f.next_rail = nil

      if remote.interfaces.YARM and remote.interfaces.YARM.show_expando and f.settings.YARM_old_expando and player.name ~= "farl_player" then
        remote.call("YARM", "show_expando", player.index)
      end
      --f.settings = false
      break
    end
  end
  --debugDump(apiCalls,true)
  --apiCalls = {find={item=0,tree=0,stone=0,other=0},canplace=0,create=0,count={item=0,tree=0,stone=0,other=0}}
end

FARL.findByLocomotive = function(loco)
  local idLoco = FARL.getIdFromTrain(loco.train)
  return global.farl[idLoco] or FARL.newByLocomotive(loco)
end

FARL.findByPlayer = function(player)
  local farl
  if player.vehicle then
    local id = FARL.getIdFromTrain(player.vehicle.train)
    farl = global.farl[id]
    if farl and farl.locomotive == player.vehicle then
      farl.driver = player
      return farl
    else
      return FARL.new(player)
    end
  else
    if player.opened and isFARLLocomotive(player.opened) then
      farl = global.farl[player.opened.unit_number]
      if farl and farl.locomotive == player.opened then
        return farl
      else
        return FARL.newByLocomotive(player.opened)
      end
    end
  end
  return false
end

FARL.update = function(self, _)
  if not self.driver then
    return
  end
  if not self.train.valid then
    if self.locomotive.valid then
      self.train = self.locomotive.train
    else
      self:deactivate("Error (invalid train)")
      return true
    end
  end
  if self.active and not self.train.manual_mode then
    self:deactivate()
    self.train.manual_mode = true
    return true
  end

  self.cruiseInterrupt = self.driver.riding_state.acceleration
  self:cruiseControl()
  if self.active then
    self.input = self.driver.riding_state.direction
    --local next_rail = self:findNeighbour(below, self.direction, self.input) or self:get_connected_rail(below, false, self.direction)
    --if not next_rail then
    if not self.lastrail.valid then
      self:deactivate({ "msg-error-2" })
      return true
    end
    local firstWagon = self.frontmover and self.train.carriages[1] or self.train.carriages[#self.train.carriages]
    if Position.distance(self.lastrail.position, firstWagon.position) < 6 then
      --log("start update")
      --debugDump(#self.path, true)
      --if not self.last_moved then self.last_moved = game.tick end
      --local diff = game.tick - self.last_moved
      --self:print(diff.."@"..game.tick)
      --self.last_moved = game.tick
      self.acc = self.driver.riding_state.acceleration
      if ((self.acc ~= 3 and self.frontmover) or (self.acc ~= 1 and not self.frontmover)) then

        --autopilot
        if self.ghostPath then
          local data = self.ghostPath[#self.ghostPath]
          self.input = data.input
          self.ghostPath[#self.ghostPath] = nil
        end

        --check if previous curve is far enough behind if input is the same
        if self.lastCurve and self.lastCurve.input == self.input and self.settings.parallelTracks
          and #self.settings.activeBP.straight.lanes > 0 and not self.settings.bulldozer then
          --self:print("curveblock:"..self.lastCurve.curveblock.."dist:"..self.lastCurve.dist)
          if self.lastCurve.dist < self.lastCurve.curveblock then
            self.input = 1
            --deactivate if it's a scripted player, as the path gets messed up
            if self.ghostPath or self.driver.name == "farl_player" then
              self:deactivate("Curves to close to each other.")
              return true
            end
          end
        end

        local newTravelDir, nextRail = self:getRail(self.lastrail, self.direction, self.input)
        if not nextRail then
          --log("Need extra rail "..serpent.block(self.lastrail))
          newTravelDir, nextRail = self:getRail(self.lastrail, self.direction, 1)
          if not nextRail then
            --self:print("What happened?")
            return true
          end
        end
        --TODO add preview for direction change

        --          for i, pi in pairs( {0, 2} ) do
        --            if self.previews[i] then
        --              for _, r in pairs(self.previews[i]) do
        --                if r and r.valid then
        --                  r.destroy()
        --                end
        --              end
        --            end
        --            self.previews[i] = {}
        --            local d, r = self:getRail(nextRail, newTravelDir, pi)
        --            if r.name == self.settings.rail.straight then
        --              d, r = self:getRail(r, newTravelDir, pi)
        --            end
        --            local entity = r
        --            local new_entity = {
        --              name = "entity-ghost",
        --              inner_name = "farl-" .. entity.name,
        --              position = entity.position,
        --              direction = entity.direction,
        --              force = self.locomotive.force
        --            }
        --            r = self.surface.create_entity(new_entity)
        --            if r.valid then
        --              r.time_to_live = 60 * 5
        --              table.insert(self.previews[i], r)
        --            end
        --          end

        --log("start placeRails")
        local dir_, last = self:placeRails(nextRail, newTravelDir)
        --log("end placeRails")
        if dir_ then
          if not last.position and not last.name then
            self:deactivate({ "msg-no-entity" })
            return true
          end
          if self.ghostPath then
            self.ghostProgress = self.ghostProgress + 1
          end
          self.protected_index = self.protected_index + 1
          if self.protected_index == 7 then
            self.protected_index = 1
            self.protected[self.protected_index] = {}
            self.protected_tiles[self.protected_index] = {}
          end
          --debugDump(self.protected_index,true)
          -- add created rail to path
          table.insert(self.path, { rail = last, travel_dir = newTravelDir, input = self.input })
          -- remove rails behind train from path
          local behind = self:rail_behind_train()
          local found = false
          local max_path = #self.path
          for i = max_path, 1, -1 do
            if self.path[i].rail == behind and i > 1 then
              found = i
            end
            if found and found > i then
              local name = self.path[i].rail.name
              local rail = self.path[i].rail
              self:protect(rail)
              if self.settings.bulldozer then
                self:bulldoze_area(rail, self.path[i].travel_dir)
                local addAmount = self.path[i].rail.type == "straight-rail" and 1 or 4
                if trigger_events[name] then
                  script.raise_event(defines.events.on_robot_pre_mined, { entity = self.path[i].rail })
                end
                if self.path[i].rail.destroy() then
                  self:addItemToCargo(name, addAmount, true) --TODO addAmount shouldn't be needed
                else
                  self:deactivate({ "msg-cant-remove" })
                  return true
                end
              end
              table.remove(self.path, i)
            end
          end
          --self:flyingText2("X", RED, true,self.path[1].rail.position)

          if last.type == "curved-rail" then
            self.lastCurve = { dist = -1, input = self.input, direction = self.direction, blocked = {}, curveblock = 0 }
          else
            self.lastCurve.dist = self.lastCurve.dist + 1
          end

          if not self.settings.bulldozer then
            --add concrete to the queue to be placed in a tick without track placement (probably the next one)
            if self.settings.concrete then
              table.insert(self.concrete_queue, {
                travelDir = newTravelDir,
                rail = get_fake_rail(last)
              })
            end

            --place rail entities (only walls for now), place on the mainrail euqal to the furthest lagging parallel track
            if self.settings.railEntities and #self.settings.activeBP.straight.lanes == 0 then
              local c = #self.path - 1
              if c > 0 and self.path[c] and self.path[c].rail.type ~= "curved-rail" then
                local rail = self.path[c].rail
                table.insert(self.rail_queue, { travelDir = self.path[c].travel_dir, rail = get_fake_rail(rail) })
              end
            end

            --debugLog("Path length: "..#self.path)
            if self.settings.poles and #self.path > 2 then
              local c = #self.path
              local rail = self.path[c - 1].rail
              local dir = self.path[c - 1].travel_dir
              --debugLog("calculating pole for rail@"..Position.tostring(self.path[c-1].rail.position))
              local rails = self:getPoleRails(rail, dir, self.path[c - 2].travel_dir)
              if self.path[c - 2].rail.type == "curved-rail" and #rails > 0 then
                rails[1].range[1] = -1
              end
              local bestpole, bestrail = self:getBestPole(self.lastPole, rails, "o")
              if bestpole then
                --debugLog("--pole: "..Position.tostring(bestpole.p))
                self.lastCheckPole = bestpole.p
                self.lastCheckDir = bestpole.dir
                self.lastCheckRail = bestrail
                --if global.debug_log then
                --self:flyingText2("bp", RED, true, bestpole.p)
                --self:flyingText2("br", RED, true, bestrail.position)
                --end
              else
                --self:print("should place pole")
                --self:flyingText2("sp", RED, true, self.lastCheckPole)
                if self.lastCheckPole.x then
                  --debugLog("--Should be placing pole @"..Position.tostring(self.lastCheckPole))
                  local status, err = pcall(function() self:placePole(self.lastCheckPole, self.lastCheckDir) end)
                  if not status then
                    error(err, 2)
                  end
                end
              end
            end

            if self.settings.signals then
              self.signalCount.main = self.signalCount.main + get_signal_weight(last, self.settings)
              if last.type == "curved-rail" then
                self.signalCount.main = self.signalCount.main - self.lanes.max_lag[newTravelDir % 2] - get_signal_weight(last, self.settings)
              end
              if self:getCargoCount("rail-signal") > 0 then
                if self:placeSignal(newTravelDir, nextRail) then
                  self.signalCount.main = 0
                end
              else
                self:flyingText({ "", "Out of ", "rail-signal" }, YELLOW, true)
              end
            end

            if self.settings.parallelTracks and #self.settings.activeBP.straight.lanes > 0 then
              max_path = -1
              local all_placed = 0
              for i, _ in pairs(self.settings.activeBP.straight.lanes) do
                if last.type == "curved-rail" then
                  local traveldir = newTravelDir
                  local block = self:placeParallelCurve(newTravelDir, last, i)
                  if block then
                    local lag = abs(self.lanes["d" .. traveldir % 2]["i" .. self.input]["l" .. i].lag) + block - 1
                    max_path = lag > max_path and lag or max_path
                    self.lastCurve.curveblock = max_path
                  end
                else
                  local placed = self:placeParallelTrack(newTravelDir, last, i)
                  if placed then
                    self.lanerails[i] = placed
                    all_placed = self.lanerails[i] and all_placed + 1 or all_placed
                  end
                end
              end
              if self.settings.railEntities and all_placed == #self.settings.activeBP.straight.lanes then
                local lag = self.lanes.max_lag[newTravelDir % 2]
                local c = #self.path - lag
                if c > 0 and self.path[c] and self.lastCurve.dist > lag then
                  local rail = self.path[c].rail
                  rail = get_fake_rail(rail)
                  table.insert(self.rail_queue, { travelDir = self.path[c].travel_dir, rail = rail })
                end
              end
            end
          end
          self.direction = newTravelDir
          self.lastrail = last
          --log("end update success")
          return true
        else
          self:deactivate(last)
          --log("end update fail:"..last)
          return true
        end
      end
    else
      -- if bulldoze mode is on, prepare the area for the next rail after self.lastrail according to input
      if self.settings.bulldozer or self.settings.maintenance then
        local _, next = self:getRail(self.lastrail, self.direction, 1)
        if next and self.already_prepared ~= Position.tostring(next.position) then
          --self:flyingText2("R", RED,true, next.position)
          self.already_prepared = Position.tostring(next.position)
          self:bulldoze_area(next, self.direction)
        end
      end

      if self.settings.concrete and #self.concrete_queue > 0 then
        for _, queue in pairs(self.concrete_queue) do
          self:placeConcrete(queue.travelDir, queue.rail)
        end
        self.concrete_queue = {}
      end
      if self.settings.railEntities and #self.rail_queue > 0 then
        for _, queue in pairs(self.rail_queue) do
          self:placeRailEntities(queue.travelDir, queue.rail)
        end
        self.rail_queue = {}
      end
    end
    if self.ghostPath then
      if #self.ghostPath == 0 then
        self:deactivate("Finished path")
        return true
      end
    end
  end
end

FARL.show_path = function(self)
  for i = 1, #self.path do
    self:flyingText2(i, RED, true, FARL.diagonal_to_real_pos(self.path[i].rail))
    --self:flyingText(i..":"..self.path[i].travel_dir, RED, true, self.path[i].rail.position)
    --debugDump(path[i].rail.position,true)
  end
end

FARL.createBoundingBox = function(self, rail, direction)
  local bb = direction % 2 == 1 and self.settings.activeBP.diagonal.boundingBox or self.settings.activeBP.straight.boundingBox
  local realpos = FARL.diagonal_to_real_pos(rail)
  local area = {
    move_right_forward(realpos, direction, bb.tl.x, bb.tl.y),
    move_right_forward(realpos, direction, bb.br.x, bb.br.y)
  }
  local tl = { x = min(area[1].x, area[2].x), y = min(area[1].y, area[2].y) }
  local br = { x = max(area[1].x, area[2].x), y = max(area[1].y, area[2].y) }
  return { left_top = tl, right_bottom = br }
end

--prepare an area for entity so it can be placed
FARL.prepareArea = function(self, entity, rangeOrArea)
  local pos = entity.position
  local area = (type(rangeOrArea) == "table") and rangeOrArea or false
  local range = (type(rangeOrArea) ~= "number") and 1.5 or 0.5
  area = area and area or Position.expand_to_area(pos, range)
  --if force or not self:genericCanPlace(entity) then
  --debugDump(area,true)
  --self:showArea2(area)
  --log(game.tick.." prepArea")
  self:removeTrees(area)
  self:pickupItems(area)
  self:removeStone(area)
  --log(game.tick.." prepArea done")
  --else
  --return true
  --end
  if entity and entity.name and not self:genericCanPlace(entity) then
    self:fillWater(area)
  end
  return self:genericCanPlace(entity)
end

FARL.prepareAreaForCurve = function(self, newRail)
  local areas = FARL.clearAreas[newRail.direction % 4]
  for i = 1, 2 do
    local area = areas[i]
    local tl, lr = Position.add(newRail.position, area[1]), Position.add(newRail.position, area[2])
    area = { left_top = { x = tl.x - 1, y = tl.y - 1 }, right_bottom = { x = lr.x + 1, y = lr.y + 1 } }
    self:removeTrees(area)
    self:pickupItems(area)
    self:removeStone(area)
    if self.settings.bulldozer or self.settings.maintenance then
      local types = { "straight-rail", "curved-rail", "rail-signal", "rail-chain-signal", "electric-pole", "lamp", "wall" }
      for _, t in pairs(types) do
        self:removeEntitiesFiltered({ area = area, type = t }, self.protected)
      end
    end
    if not self:genericCanPlace(newRail) then
      self:fillWater(area)
    end
  end
end

FARL.removeTrees = function(self, area)
  --apiCalls.count.tree = apiCalls.count.tree + 1
  local amount, name, proto
  for _, entity in pairs(self.surface.find_entities_filtered { area = area, type = "tree" }) do
    --for _, entity in pairs(self:find_entities_filtered({ area = area, type = "tree" }, "removeTrees")) do
    local stat = global.statistics[self.locomotive.force.name].removed["tree-01"] or 0
    global.statistics[self.locomotive.force.name].removed["tree-01"] = stat + 1
    proto = entity.prototype.mineable_properties
    if proto and proto.minable and proto.products and not(godmode or self.cheat_mode) and self.settings.collectWood then
      local products = proto.products
      if products then
        for _, product in pairs(products) do
          if product.type == "item" then
            if product.name == "raw-wood" then
              self:addItemToCargo("raw-wood", 1)
            else
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
            end
          end
        end
      end
    end
    entity.die() -- using die() here, because destroy() doesn't leave tree stumps
  end
end

FARL.removeStone = function(self, area)
  local amount, name, proto
  for _, entity in pairs(self.surface.find_entities_filtered { area = area, type = "simple-entity", force = "neutral" }) do
    proto = entity.prototype.mineable_properties
    if proto and proto.minable and proto.products then
      if entity.destroy() and not(godmode or self.cheat_mode) and self.settings.collectWood then
        local products = proto.products
        for _, product in pairs(products) do
          log(serpent.block(product))
          if product.type == "item" then
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
                log(string.format("added %s %s", amount, name))
                self:addItemToCargo(name, ceil(amount/2))
              end
              name = false
            end
          end
        end
        local stat = global.statistics[self.locomotive.force.name].removed["stone-rock"] or 0
        global.statistics[self.locomotive.force.name].removed["stone-rock"] = stat + 1
      end
    end
  end
end

-- args = {area=area, name="name"} or {area=area,type="type"}
-- exclude: table with entities as keys
FARL.removeEntitiesFiltered = function(self, args)
  local force = self.locomotive.force
  local neutral_force = game.forces.neutral
  local count
  for _, entity in pairs(self.surface.find_entities_filtered(args)) do
    count = 1
    --for _, entity in pairs(self:find_entities_filtered(args, "removeEntitiesFiltered")) do
    if not self:isProtected(entity) and (entity.force == force or entity.force == neutral_force) then
      local item = false
      local name = entity.name
      if entity.type == "straight-rail" or entity.type == "curved-rail" then
        item = entity.name
      else
        if entity.prototype.items_to_place_this then
          local k, _ = next(entity.prototype.items_to_place_this)
          item = k
        end
      end
      if trigger_events[name] or entity.type == "electric-pole" then
        script.raise_event(defines.events.on_robot_pre_mined, { entity = entity })
      end
      if not entity.destroy() then
        self:deactivate({ "msg-cant-remove" })
        return
      else
        if item and name ~= "concrete-lamp" then
          self:addItemToCargo(item, count)
          local stat = global.statistics[self.locomotive.force.name].removed[item] or 0
          global.statistics[self.locomotive.force.name].removed[item] = stat + 1
        end
      end
    end
  end
end

FARL.fillWater = function(self, area)
  local status, err = pcall(function()
    -- check if bridging is turned on in settings
    if self.settings.bridge then
      -- following code mostly pulled from landfill mod itself and adjusted to fit
      local tiles = {}
      area = Area.to_table(area)
      local st, ft = area.left_top, area.right_bottom
      local dw, w = 0, 0
      for x = st.x, ft.x, 1 do
        for y = st.y, ft.y, 1 do
          local tileName = self.surface.get_tile(x, y).name
          -- check that tile is water, if it is add it to a list of tiles to be changed to grass
          if tileName == "water" or tileName == "deepwater" then
            if tileName == "water" then
              w = w + 1
            else
              dw = dw + 1
            end
            table.insert(tiles, { name = "grass", position = { x, y } })
          end
        end
      end
      self:replaceWater(tiles, w, dw)
    end
  end)
  if not status then
    debugDump(area, true)
    error(err, 3)
  end
end

FARL.replaceWater = function(self, tiles, w, dw)
  -- check to make sure water tiles were found
  if #tiles ~= 0 then
    -- if they were calculate the minimum number of landfills to fill them in ( quick and dirty at the moment may need tweeking to prevent overusage)
    local lfills = ceil(w / 2 + dw * 1.5)
    lfills = lfills > 20 and 20 or lfills
    -- check to make sure there is enough landfill in the FARL and if there is apply the changes, remove landfill.  if not then show error message
    if self:getCargoCount("landfill") >= lfills then
      self.surface.set_tiles(tiles)
      self:removeItemFromCargo("landfill", lfills)
    else
      self:print({ "msg-not-enough-concrete", { "item-name.landfill" } })
    end
  end
end

FARL.placeConcrete = function(self, dir, rail)
  if rail.type == "curved-rail" then return end
  local type = rail.direction % 2 == 1 and "diagonal" or "straight"
  local concrete = self.settings.activeBP[type].concrete
  if not concrete then return end
  local diff = dir % 2 == 0 and dir or dir - 1
  local rad = diff * (math.pi / 4)

  local tiles = {}
  local pave = {}
  local w, dw = 0, 0
  local railpos = FARL.diagonal_to_real_pos(rail)

  --mirror directional concrete from color-coding
  local textured = {}
  textured["concrete-hazard-left"] = "concrete-hazard-right"
  textured["concrete-hazard-right"] = "concrete-hazard-left"
  textured["concrete-fire-left"] = "concrete-fire-right"
  textured["concrete-fire-right"] = "concrete-fire-left"
  --vanilla hazard concrete
  textured["hazard-concrete-left"] = "hazard-concrete-right"
  textured["hazard-concrete-right"] = "hazard-concrete-left"

  for _, c in pairs(concrete) do
    local name = c.name
    if self.settings.mirrorConcrete and endsWith(name, "-left") or endsWith(name, "-right") then
      if (type == "straight" and dir % 4 == 2) or (type == "diagonal" and (dir == 3 or dir == 7)) then
        name = textured[name] or name
      end
    end

    local entity = { name = name }
    local offset = c.position
    offset = rotate(offset, rad)
    local pos = Position.add(railpos, offset)
    self:protect_tile({ x = pos.x, y = pos.y })
    entity.position = pos
    pave[name] = pave[name] or {}
    --self:flyingText2(".", GREEN,true,entity.position)
    local tileName = self.surface.get_tile(pos.x, pos.y).name
    -- check that tile is water, if it is add it to a list of tiles to be changed to grass
    if tileName == "water" or tileName == "deepwater" then
      if self.settings.bridge then
        if tileName == "water" then
          w = w + 1
        else
          dw = dw + 1
        end
        table.insert(tiles, { name = "grass", position = { pos.x, pos.y } })
        table.insert(pave[name], entity)
      end
    elseif tileName ~= name and tileName ~= "out-of-map" then
      table.insert(pave[name], entity)
    end
  end
  if self.settings.bridge then
    self:replaceWater(tiles, w, dw)
  end

  for name, p in pairs(pave) do
    local c = #p
    if self:getCargoCount(name) > c then
      if c > 0 then
        self.surface.set_tiles(p)
        self:removeItemFromCargo(name, c)
        local stat = global.statistics[self.locomotive.force.name].created[name] or 0
        global.statistics[self.locomotive.force.name].created[name] = stat + c
      end
    else
      self:print({ "msg-not-enough-concrete", { "item-name." .. get_item_name(name) } })
    end
  end
end

FARL.removeConcrete = function(self, area)
  local status, err = pcall(function()
    local tiles = {}
    Area.to_table(area)
    local st, ft = area.left_top, area.right_bottom

    local counts = {}
    for x = st.x, ft.x, 1 do
      for y = st.y, ft.y, 1 do
        local tileName = self.surface.get_tile(x, y).name
        -- check that tile is placeable by the player
        local itemsToPlace = game.tile_prototypes[tileName].items_to_place_this
        local toPlace = itemsToPlace and next(itemsToPlace)
        if (toPlace and toPlace ~= "landfill" and toPlace ~= "bi-adv-fertiliser" and not string.starts_with(toPlace, 'dect-base')) and not self:is_protected_tile({ x = x, y = y }) then
          counts[tileName] = counts[tileName] or 0
          table.insert(tiles, { name = self.replace_tile, position = { x, y } })
          counts[tileName] = counts[tileName] + 1
        end
      end
    end
    self.surface.set_tiles(tiles)

    for name, c in pairs(counts) do
      local item = get_item_name(name)
      self:addItemToCargo(item, c, true)
      local stat = global.statistics[self.locomotive.force.name].removed[item] or 0
      global.statistics[self.locomotive.force.name].removed[item] = stat + c
    end
  end)
  if not status then
    debugDump(area, true)
    error(err, 3)
  end
end

FARL.pickupItems = function(self, area)
  --apiCalls.count.item = apiCalls.count.item + 1
  if self.surface.count_entities_filtered { area = area, name = "item-on-ground" } > 0 then
    --apiCalls.find.item = apiCalls.find.item + 1
    for _, entity in pairs(self.surface.find_entities_filtered { area = area, name = "item-on-ground" }) do
      --for _, entity in pairs(self:find_entities_filtered( { area = area, name = "item-on-ground" },"pickUpItems")) do
      self:addItemToCargo(entity.stack.name, entity.stack.count, entity.stack.prototype.place_result)
      entity.destroy()
    end
  end
end

FARL.find_tile = function(self, sarea1, sarea2, travel_dir)
  log(serpent.block({sarea1, sarea2}))
  local tpos1 = move_right_forward(sarea1, travel_dir, -1, 0)
  local tpos2 = move_right_forward(sarea2, travel_dir, 1, 0)
  local tile1 = self.surface.get_tile(tpos1.x, tpos1.y)
  local tile2 = self.surface.get_tile(tpos2.x, tpos2.y)
  local found = false
  local count = 0
  while count < 20 and not found do
    --self:flyingText2("1", RED,true,tpos1)
    --self:flyingText2("2", RED,true,tpos2)
    if not string.find(tile1.name, "water") and tile1.name ~= "out-of-map" and not get_item_name(tile1.name) then
      return tile1.name
    end
    if not string.find(tile2.name, "water") and tile2.name ~= "out-of-map" and not get_item_name(tile2.name) then
      return tile2.name
    end
    tpos1 = move_right_forward(tpos1, travel_dir, -1, 0)
    tpos2 = move_right_forward(tpos2, travel_dir, 1, 0)
    tile1 = self.surface.get_tile(tpos1.x, tpos1.y)
    tile2 = self.surface.get_tile(tpos2.x, tpos2.y)
    count = count + 1
  end
  return found
end

FARL.bulldoze_area = function(self, rail, travel_dir)
  if rail.type == "curved-rail" then
    self:prepareAreaForCurve(rail)
    return
  end
  local types = { "straight-rail", "curved-rail", "rail-signal", "rail-chain-signal", "electric-pole", "lamp", "wall" }
  local rtype = travel_dir % 2 == 0 and "straight" or "diagonal"
  local bp = self.settings.activeBP[rtype]

  if rtype == "straight" then
    local area = self:createBoundingBox(rail, travel_dir)
    local sarea1 = (travel_dir == 0 or travel_dir == 2) and area.left_top or area.right_bottom
    local sarea2 = (travel_dir == 0 or travel_dir == 2) and area.right_bottom or area.left_top
    local found = self:find_tile(sarea1, sarea2, travel_dir)
    if found then
      self.replace_tile = found
    end
    self:prepareArea(rail, area)
    self:removeConcrete(area)
    local area2 = Position.expand_to_area(FARL.diagonal_to_real_pos(rail), 1.5)
    for _, t in pairs(types) do
      self:removeEntitiesFiltered({ area = area, type = t }, self.protected)
      self:removeEntitiesFiltered({ area = area2, type = t }, self.protected)
    end
  else
    local lastPoint = bp.clearance_points[#bp.clearance_points]
    for i, p in pairs(bp.clearance_points) do
      local pos = move_right_forward(rail.position, travel_dir, p.x, 0)
      local area = Position.expand_to_area(pos, 1.5)
      if i == 1 then
        --local tpos = move_right_forward(pos12toXY(area[1]),travel_dir,-1,0)
        local sarea1 = area.left_top
        local sarea2 = Position.expand_to_area(move_right_forward(rail.position, travel_dir, lastPoint.x, 0), 0.5).right_bottom
        local found = self:find_tile(sarea1, sarea2, travel_dir)
        if found then
          self.replace_tile = found
        end
      end

      self:removeTrees(area)
      self:pickupItems(area)
      self:removeStone(area)
      self:removeConcrete(area)
      for _, t in pairs(types) do
        self:removeEntitiesFiltered({ area = area, type = t }, self.protected)
      end
    end
  end
end

FARL.getRail = function(self, lastRail, travelDir, input)
  if not travelDir or not input then error("no traveldir or input", 2) end
  if travelDir > 7 or travelDir < 0 then
    self:deactivate("Traveldir wrong: " .. travelDir)
    return false, false
  end
  if input > 2 or input < 0 then
    self:deactivate("Input wrong: " .. input)
    return travelDir, false
  end
  if not lastRail then error("no lastRail", 2) end
  local data = FARL.input_to_next_rail[travelDir][lastRail.type]
  if not data then error("no data", 2) end
  if not data[lastRail.direction] or not data[lastRail.direction][input] then
    if not data[lastRail.direction] then
      return travelDir, false
    end
    input = 1
  end
  data = data[lastRail.direction][input]

  local name = data.type == "straight-rail" and self.settings.rail.straight or self.settings.rail.curved
  local newTravelDir = (travelDir + FARL.input2dir[input]) % 8
  return newTravelDir, { name = name, position = Position.add(lastRail.position, data.offset), direction = data.direction, type = data.type }
end

FARL.getGhostRail = function(self, lastRail, travelDir, input)
  if not travelDir or not input then error("no traveldir or input", 2) end
  if travelDir > 7 or travelDir < 0 then
    self:deactivate("Traveldir wrong: " .. travelDir)
    return false, false
  end
  if input > 2 or input < 0 then
    self:deactivate("Input wrong: " .. input)
    return travelDir, false
  end
  if not lastRail then error("no lastRail", 2) end
  local data = FARL.input_to_next_rail[travelDir][lastRail.ghost_type]
  if not data then error("no data", 2) end
  if not data[lastRail.direction] or not data[lastRail.direction][input] then
    if not data[lastRail.direction] then
      return travelDir, false
    end
    input = 1
  end
  data = data[lastRail.direction][input]

  local name = data.type == "straight-rail" and self.settings.rail.straight or self.settings.rail.curved
  local newTravelDir = (travelDir + FARL.input2dir[input]) % 8
  return newTravelDir, { name = "entity-ghost", ghost_name = name, ghost_type = data.type, position = Position.add(lastRail.position, data.offset), direction = data.direction, type = "entity-ghost" }
end

FARL.cruiseControl = function(self)
  local acc = self.frontmover and defines.riding.acceleration.accelerating or defines.riding.acceleration.reversing
  local decc = self.frontmover and defines.riding.acceleration.reversing or defines.riding.acceleration.accelerating
  local speed = abs(self.train.speed)
  local limit = self.active and self.settings.cruiseSpeed or 0.9
  if self.cruise then
    if self.cruiseInterrupt == 2 then
      self:toggleCruiseControl()
      return
    end
    if speed < limit then
      self.driver.riding_state = { acceleration = acc, direction = self.driver.riding_state.direction }
    elseif self.active and speed > limit + 0.1 then
      self.driver.riding_state = { acceleration = decc, direction = self.driver.riding_state.direction }
    else
      self.driver.riding_state = { acceleration = defines.riding.acceleration.nothing, direction = self.driver.riding_state.direction }
    end
  else
    self.driver.riding_state = { acceleration = self.driver.riding_state.acceleration, direction = self.driver.riding_state.direction }
  end
end

FARL.findNeighbours = function(self, rail, travelDir)
  local paths = {}
  local found = false
  if not travelDir then error("no travelDir", 2) end
  for i = 0, 2 do
    local newTravel, nrail = self:getRail(rail, travelDir, i)
    if type(newTravel) == "number" then
      local railEnt = self:findRail(nrail)
      if railEnt then
        --self:flyingText2("N", GREEN, true, railEnt.position)
        paths[i] = { newTravel, nrail, railEnt }
        found = true
      else
        paths[i] = false
      end
    else
      paths[i] = false
    end
  end

  return found and paths or false
end

FARL.findNeighbour = function(self, rail, travelDir, input)
  local neighbour = false
  local _, nrail = self:getRail(rail, travelDir, input)
  if nrail then
    local railEnt = self:findRail(nrail)
    if railEnt then
      neighbour = railEnt
    end
  end
  return neighbour
end

FARL.findRail = function(self, rail)
  local area = Position.expand_to_area(rail.position, 0.4)
  local found = false
  for _, r in pairs(self.surface.find_entities_filtered { area = area, type = rail.type }) do
    if r.position.x == rail.position.x and r.position.y == rail.position.y and r.direction == rail.direction then
      found = r
      break
    end
  end
  return found
end

FARL.findGhostRail = function(self, rail)
  local area = Position.expand_to_area(rail.position, 0.4)
  --local found = self.surface.find_entity(rail.name, rail.position)
  for _, r in pairs(self.surface.find_entities_filtered { area = area, name = rail.name }) do
    if r.position.x == rail.position.x and r.position.y == rail.position.y and r.direction == rail.direction then
      return r
    end
  end
end

FARL.calculate_rail_data = function(self)
  local curves = {
    [0] = {
      [0] = { name = "curved-rail", type = "curved-rail", direction = 0, position = { x = 0, y = 0 } },
      [2] = { name = "curved-rail", type = "curved-rail", direction = 1, position = { x = 2, y = 2 } }
    },
    [1] = {
      [0] = { name = "curved-rail", type = "curved-rail", direction = 3, position = { x = 1, y = 1 } },
      [2] = { name = "curved-rail", type = "curved-rail", direction = 3, position = { x = 1, y = 1 } }
    }
  }
  self.lanes.max_lag = { [0] = 0, [1] = 0 }
  self.lanes.min_block = { [0] = 0, [1] = 0 }
  for _, direction_self in pairs({ 0, 1 }) do
    self.lanes["d" .. direction_self] = {}
    for _, input_self in pairs({ 0, 2 }) do
      self.lanes["d" .. direction_self]["i" .. input_self] = {}
      local rail = curves[direction_self][input_self]
      local straight_lanes = self.settings.activeBP.straight.lanes
      for lane_index, _ in pairs(straight_lanes) do
        local direction = direction_self
        local original_dir = direction
        local s_lane = self.settings.activeBP.straight.lanes[lane_index]
        local d_lane = self.settings.activeBP.diagonal.lanes[lane_index]
        local input = input_self
        -- invert direction, input, distances for diagonal rails
        if direction % 2 == 1 then
          direction = Position.opposite_direction((direction + FARL.input2dir[input]) % 8)
          input = input == 2 and 0 or 2
          s_lane = -1 * s_lane
          d_lane = -1 * d_lane
        end

        local new_curve = { name = rail.name, type = rail.type, direction = rail.direction, force = rail.force } --luacheck: ignore
        local right = original_dir % 2 == 0 and s_lane * 2 or s_lane
        --left hand turns need to go back, moving right already moves the diagonal rail part
        local forward = input == 2 and (s_lane - d_lane) * 2 or (d_lane - s_lane) * 2

        new_curve.position = move_right_forward(rail.position, direction, right, forward)
        local lag = forward / 2
        local catchup
        local l, f = lag, forward
        local r

        if original_dir == 1 then
          right = -1 * right
          lag = 2 * right + d_lane
          lag = input == 2 and lag or -1 * lag
          forward = -1 * forward

          forward = forward / 2
          l, f, r = lag, -1 * s_lane, forward
          if input_self == 2 then
            f = -1 * f
          end
          catchup = l + f + r
        else
          catchup = l < 0 and l or f
        end
        catchup = catchup > 0 and catchup or 0

        local block
        if original_dir == 0 then
          block = forward / 2
        else
          block = -1 * forward / 2
        end

        local data = { forward = forward, right = right, lag = lag, catchup = catchup, block = block }
        self.lanes["d" .. direction_self]["i" .. input_self]["l" .. lane_index] = data
        self.lanes.max_lag[direction_self] = self.lanes.max_lag[direction_self] < abs(lag) and abs(lag) or self.lanes.max_lag[direction_self]
        --debugDump(self.lanes.max_lag,true)
      end
    end
  end
end

FARL.activate = function(self, scanForGhosts)
  local status, err = pcall(function()
    self.lastrail = false
    self.signalCount = { main = 0 }
    self.protected = {}
    self.protected_index = 1
    self.protected[self.protected_index] = {}
    self.protected_tiles = {}
    self.protected_tiles[self.protected_index] = {}
    self.frontmover = false
    --self.previews = {}
    --      self.last_signal = {}
    --      self.fake_signal_in = false
    --      self.fake_signalCount = {main=0}
    self.replace_tile = "grass"
    self.lastCurve = { dist = 20, input = false, direction = 0, blocked = {}, curveblock = 0 }
    for _, l in pairs(self.train.locomotives.front_movers) do
      if l == self.locomotive then
        self.frontmover = true
        break
      end
    end
    self.direction = self:calcTrainDir()
    self.lastrail = self:findLastRail()
    if scanForGhosts then
      self.ghostPath = self:getGhostPath()
    end
    if self.ghostPath then
      if self.confirmed == nil then
        GUI.createPopup(self.driver)
        return
      end
      if self.confirmed == true then
        self.ghostProgressStart = #self.ghostPath
        self.ghostProgress = 0
        for _, data in pairs(self.ghostPath) do
          local position = data.rail.position
          local direction = data.rail.direction
          local name = data.rail.name
          local ghost_name = data.rail.ghost_name
          local ttl = data.rail.time_to_live
          data.rail.destroy()
          data.rail = {position = position, name=name, inner_name = ghost_name, direction=direction, timeToLive = ttl}
        end
        self.destroyedGhosts = true
      end
    end

    if not self.lastrail then
      self:deactivate({ "msg-error-2" }, true)
      return
    end
    if self.lastrail.type == "curved-rail" then
      self:deactivate({ "msg-error-curves" }, true)
      return
    end
    if debugButton then
      self:print("TrainDir: " .. self.direction)
    end

    local first_carriage, bulldoze_rail
    local same_orientation = false

    first_carriage = not self.frontmover and self.train.carriages[#self.train.carriages] or self.train.carriages[1]
    local orientation = first_carriage.orientation
    for _, carriage in pairs(self.train.carriages) do
      if carriage.orientation == orientation or (carriage.orientation + 0.5) % 1 == orientation then
        same_orientation = orientation
      else
        same_orientation = false
        break
      end
    end

    local _
    self.path, _ = self:get_rails_below_train(same_orientation)
    --debugDump(#self.path,true)
    if self.settings.bulldozer then
      bulldoze_rail = self.frontmover and self.train.back_rail or self.train.front_rail
      if not same_orientation or bulldoze_rail.type == "curved-rail" then
        debugDump("Train is on a curve somewhere, train doesn't like!", true)
        self:deactivate()
        return
      end
    end
    --self:flyingText("FR", YELLOW, true, self:rail_below_train().position)
    --self:show_path()
    for i = #self.path - 1, #self.path - 3, -1 do
      if self.settings.railEntities and not self.settings.bulldozer then
        local c = i
        if c > 0 and self.path[c] and self.path[c].rail.type ~= "curved-rail" then
          local rail = self.path[c].rail
          table.insert(self.rail_queue, { travelDir = self.path[c].travel_dir, rail = get_fake_rail(rail) })
        end
      end
    end
    debugLog("--Path length:" .. #self.path)
    --self:show_path()

    self:findLastPole(self.lastrail)
    self:protect(self.lastPole)
    --self:show_path()
    local last_signal, signal_rail = false, false
    local signal_index = false
    for i = #self.path, 1, -1 do
      local rail = self.path[i].rail
      local dir = self.path[i].travel_dir
      last_signal, signal_rail = self:find_signal_rail(rail, dir)
      if last_signal then
        self.signalCount = { main = 0 }
        self:flyingText2("S", GREEN, true, last_signal.position)
        signal_index = i
        break
      end
    end

    if not signal_index then
      self.signalCount.main = self.settings.signalDistance
    end
    --debugDump(signal_index,true)

    if signal_index and self.settings.signals and not self.settings.bulldozer then
      --local c = self.settings.maintenance and front_rail_index+1 or #self.path
      local c = #self.path
      for i = signal_index + 1, c do
        local rail = self.path[i].rail
        local dir = self.path[i].travel_dir
        if self:getCargoCount("rail-signal") > 0 then
          if self:placeSignal(dir, rail) then self.signalCount.main = 0 end
        else
          self:flyingText({ "", "Out of ", "rail-signal" }, YELLOW, true)
        end
        self.signalCount.main = self.signalCount.main + get_signal_weight(rail, self.settings)
      end
    end
    --debugDump(self.signalCount,true)
    if last_signal and signal_rail then
      self:protect(last_signal)
      --self:flyingText2( "SR", GREEN, true, signal_rail.position)
    end
    --self:flyingText2( {"text-behind"}, RED, true, self:rail_behind_train().position)
    local bps = self.settings.activeBP
    local diag_lanes = bps.diagonal.lanes
    local straight_lanes = bps.straight.lanes
    --debugLog("--Lanes: vert: "..#straight_lanes.." diag: "..#diag_lanes)
    --debugLog("Poles: vert: "..bps.straight.pole.name.." diag: "..bps.diagonal.pole.name)
    self.lanes = {}
    if diag_lanes and straight_lanes and #diag_lanes ~= #straight_lanes then
      self:deactivate({ "msg-error-track-mismatch" })
      return
    end

    -- lane lag, curve calculations
    if diag_lanes and straight_lanes then
      self:calculate_rail_data()
    end
    self.signal_in = {}
    local mainCount = get_signal_weight(self.lastrail, self.settings)
    for i, _ in pairs(straight_lanes) do
      local lane_data = self.lanes["d" .. self.direction % 2]["i0"]["l" .. i]
      local lag = abs(lane_data.lag)
      if self.direction % 2 == 1 and lane_data.right > 0 then
        lag = lag * mainCount
      end
      self.signalCount[i] = self.signalCount.main - lag --+ mainCount
      --self.signal_in[i] = lag
    end
    debugLog(self.signalCount, "--Signal count: ")
    debugLog(self.signal_in, "--Signals_in: ")

    self.lanerails = {}
    if self.settings.bulldozer and self.settings.concrete then
      local d = self.path[#self.path]
      --self:flyingText2(self.direction, RED,true,d.rail.position)
      self:placeConcrete(self.direction, d.rail)
    end
    self.active = true
  end)
  if not status then
    self:deactivate({ "", { "msg-error-activating" }, err })
    log(debug.traceback())
  end
end

FARL.find_signal_rail = function(self, rail, travel_dir)
  local signal = get_signal_for_rail(rail, travel_dir)
  if not signal then return end
  local signal_dir = signal.direction
  local signal_pos = signal.position
  local range = (travel_dir % 2 == 0) and 1 or 0.5
  for _, name in pairs({ "rail-signal", "rail-chain-signal" }) do
    for _, entity in pairs(self.surface.find_entities_filtered { area = Position.expand_to_area(signal_pos, range), name = name }) do
      if entity.direction == signal_dir then
        return entity, rail
      end
    end
  end
end

FARL.get_rails_below_train = function(self, no_limit)
  local behind = self:rail_behind_train()
  local front = self:rail_below_train()
  local front_rail_index = 0
  local next, dir = self.lastrail, self.direction
  local path = {}
  --self:flyingText2("f", RED, true, Position.add(front.position,{x=0,y=-1}))
  --self:flyingText2("b", RED, true, behind.position)
  --self:flyingText2("n", RED, true, self.lastrail.position)
  local count = 0
  dir = Position.opposite_direction(dir)
  local limit = no_limit and 1000 or 30
  while next and (count < limit) do
    --self:flyingText2(count, RED, true, next.position)
    table.insert(path, { rail = next, travel_dir = Position.opposite_direction(dir) })
    self:protect(next)
    if next == behind then
      break
    end
    next, dir = self:get_connected_rail(next, true, dir)
    count = count + 1
  end
  --    if no_limit and next == behind then
  --      table.insert(path, {rail = next, travel_dir = Position.opposite_direction(dir)})
  --      self:protect(next)
  --    end
  local path2 = {}
  for i = #path, 1, -1 do
    table.insert(path2, path[i])
    if front == path[i] then
      front_rail_index = #path2
    end
  end
  --debugDump("front index "..front_rail_index,true)
  return path2, front_rail_index
end

FARL.deactivate = function(self, reason)
  self.active = false
  self.input = nil
  if self.cruise then
    self:toggleCruiseControl()
  end
  self.cruise = false
  self.path = nil
  self.ghostProgress = nil
  if self.ghostPath and #self.ghostPath > 0 and self.destroyedGhosts then
    --log(serpent.block(self.ghostPath,{comment=false}))
    local force = self.locomotive.force
    local status, err = pcall(function()
      for _, data in pairs(self.ghostPath) do
        local ghost = data.rail
        ghost.force = force
        local ent =
          self.surface.create_entity(ghost)
        if ent then
          ent.time_to_live = data.rail.timeToLive
        end
      end
    end)
    if not status then
      self:print({ "", "Error deactivating: ", err })
    end
  end
  if self.driver and self.driver.name == "farl_player" then
    self.driver.destroy()
    self.driver = false
  end

  self.ghostPath = nil
  self.confirmed = nil
  --    if self.last_signal then
  --      for i, signal in pairs(self.last_signal) do
  --        if signal and signal.valid then
  --          signal.destroy()
  --        end
  --      end
  --      self.last_signal = nil
  --    end
  if reason then
    self:print({ "", { "msg-deactivated" }, ": ", reason })
  end
  self.lastrail = nil
  self.already_prepared = nil
  self.lastCurve = 0
  self.direction = nil
  self.lastPole, self.lastCheckPole = nil, nil
  self.lastCheckRail = nil
  self.ccNetPole = nil
  self.protected = {}
  self.protected_tiles = {}
  self.protected_index = {}
  self.concrete_queue = {}
  self.rail_queue = {}
  self.startedBy = nil
  --    self.previews = self.previews or {}
  --    for _, p in pairs(self.previews) do
  --      if p then
  --        for _, r in pairs(p) do
  --          if r and r.valid then
  --            r.destroy()
  --          end
  --        end
  --      end
  --    end
  --    self.previews = {}
end

FARL.toggleActive = function(self, scanForGhosts)
  if not self.active then
    self:activate(scanForGhosts)
    return
  else
    self:deactivate()
  end
end

FARL.toggleCruiseControl = function(self)
  if not self.cruise then
    if self.driver and self.driver.riding_state then
      self.cruise = true
      local input = self.input or defines.riding.direction.straight
      self.driver.riding_state = { acceleration = defines.riding.acceleration.accelerating, direction = input }
      GUI.updateGui(self)
    end
    return
  else
    if self.driver and self.driver.riding_state then
      self.cruise = false
      local input = self.input or defines.riding.direction.straight
      self.driver.riding_state = { acceleration = defines.riding.acceleration.nothing, direction = input }
      GUI.updateGui(self)
    end
    return
  end
end

FARL.bulldozerModeAllowed = function(self)
  return (isFARLLocomotive(self.train.carriages[1]) and isFARLLocomotive(self.train.carriages[#self.train.carriages]))
end

FARL.toggleBulldozer = function(self)
  if self.active then
    self:deactivate({ "msg-changing-modes" })
  end
  self.settings.bulldozer = not self.settings.bulldozer
  if self.settings.bulldozer and not self:bulldozerModeAllowed() then
    self.settings.bulldozer = false
    self:print({ "msg-bulldozer-error" })
  end
  self.settings.maintenance = false
end

FARL.toggleMaintenance = function(self)
  if self.active then
    self:deactivate({ "msg-changing-modes" })
  end
  self.settings.maintenance = not self.settings.maintenance
  self.settings.bulldozer = false
end

FARL.findLastRail = function(self)
  local test = self:rail_below_train()
  local last = test
  local count = 1
  local limit = (self.settings.maintenance or self.settings.bulldozer) and 5 or 20
  while test and count <= limit do --and test.name ~= self.settings.rail.curved do
    local rail = self:get_connected_rail(test, true, self.direction)
    if rail and count < limit then
      test = rail
      last = rail
    else
      break
    end
    count = count + 1
  end
  if last then
    self:flyingText2({ "text-front" }, RED, true, last.position)
  end
  return last
end

FARL.getGhostPath = function(self)
  local next = {name = "entity-ghost", ghost_name = self.lastrail.name, ghost_type = self.lastrail.type, position = self.lastrail.position, direction=self.lastrail.direction}
  local dir = self.direction
  local count = 0
  local ghostPath = {}
  local input
  local already_on_path = {}
  while next do --and count < limit do
    next, dir, input = self:getConnectedGhostRail(next, dir)
    if next then
      if not already_on_path[next.unit_number] then
        --self:flyingText(count, YELLOW, true, next.position)
        table.insert(ghostPath, 1, {dir = dir, rail = next, input = input})
        already_on_path[next.unit_number] = true
      else
        break
      end
    end
    count = count + 1
  end
  return #ghostPath > 0 and ghostPath or false
end

FARL.addItemToCargo = function(self, item, count, place_result)
  local item2, count2 = get_item_name(item)
  count = count or 1
  if not game.item_prototypes[item] then
    item = item2
    count = count2
  end

  local itemStack = {name = item, count = count}
  local remaining = count - self.train.insert(itemStack)

  if remaining > 0 and (self.settings.dropWood or place_result) then
    local position = self.surface.find_non_colliding_position("item-on-ground", self.driver.position, 100, 0.5)
    self.surface.create_entity { name = "item-on-ground", position = position, stack = { name = itemStack.name, count = remaining } }
  end
end

FARL.removeItemFromCargo = function(self, item, count)
  count = count or 1
  if godmode or self.cheat_mode then
    return count
  end
  if count == 0 then return 0 end
  return self.train.remove_item({ name = get_item_name(item), count = count })
end

FARL.getCargoCount = function(self, item)
  local name = get_item_name(item)
  if godmode or self.cheat_mode then return 9001 end
  if not name then
    self:print("No item found for: " .. item)
  end
  return name and self.train.get_item_count(name) or 0
end

FARL.genericCanPlace = function(self, arg)
  if not arg.position or not arg.position.x or not arg.position.y then
    error("invalid position", 2)
  elseif not arg.name then
    error("no name", 2)
  end
  local name = arg.type == "entity-ghost" and arg.ghost_name or arg.name
  --apiCalls.canplace = apiCalls.canplace + 1
  if not arg.direction then
    return self.surface.can_place_entity { name = name, position = arg.position }
      --return self.surface.can_place_entity { name = name, position = arg.position, inner_name = arg.inner_name }
  else
    return self.surface.can_place_entity { name = name, position = arg.position, direction = arg.direction }
      --return self.surface.can_place_entity { name = name, position = arg.position, direction = arg.direction, inner_name = arg.inner_name }
  end
end

FARL.genericPlace = function(self, arg, ignore)
  local canPlace
  if not ignore then
    canPlace = self:genericCanPlace(arg)
  else
    canPlace = true
  end
  local entity
  if canPlace then
    local force = arg.force or self.locomotive.force
    arg.force = force
    entity = self.surface.create_entity(arg)
    --apiCalls.create = apiCalls.create + 1
  end
  if entity then
    if trigger_events[entity.name] or entity.type == "electric-pole" then
      script.raise_event(defines.events.on_robot_built_entity, { created_entity = entity })
    end
    local stat = global.statistics[entity.force.name].created[entity.name] or 0
    global.statistics[entity.force.name].created[entity.name] = stat + 1
    self:protect(entity)
    --local diff = Position.subtract(arg.position, entity.position)
    --if diff.x ~= 0 or diff.y~= 0 then
    --self:flyingText2(serpent.line(canPlace, {comment=false}), RED,true,entity.position)
    --self:print("Misplaced entity: "..entity.name)
    --self:print("arg:"..Position.tostring(arg.position).." ent:"..Position.tostring(entity.position))
    --end
  end
  return canPlace, entity
end
--[[
FARL.genericPlaceGhost = function(self, arg, ignore)
  local ghostEntity = util.table.deepcopy(arg)
  ghostEntity.inner_name = arg.name
  ghostEntity.name = "entity-ghost"
  return self:genericPlace(ghostEntity, true)
end]]--

--parse blueprints
-- chain signal: needs direction == 4, defines track that FARL drives on
--normal signals: define signal position for other tracks
FARL.parseBlueprints = function(self, bp)
  for j = 1, #bp do
    local e = bp[j].get_blueprint_entities()
    if e then
      local bpType, rails, poles, box, offsets = Blueprint.group_entities(e)
      if not bpType then
        --self:print(rails)
        return
      end
      if #poles > 0 then
        Blueprint.get_max_pole(poles, offsets)
      end
      if rails == 1 and not offsets.chain then
        local rail = offsets.rails[1]
        local traveldir = bpType == "straight" and 0 or 1
        local c = FARL.signalOffset[traveldir][rail.direction]
        offsets.chain = { direction = c.dir, name = "rail-chain-signal", position = Position.add(rail.position, c.pos) }
      end
      if offsets.chain and offsets.pole and bpType then
        local mainRail = false
        for _, rail in pairs(offsets.rails) do
          local traveldir = bpType == "straight" and 0 or 1
          local signalPositions = {get_signal_for_rail(rail, traveldir, false), get_signal_for_rail(rail, traveldir, true)}
          for _, signal in pairs(signalPositions) do
            if not mainRail and signal.position.x == offsets.chain.position.x and signal.position.y == offsets.chain.position.y and
              signal.direction == offsets.chain.direction then
              rail.main = true
              mainRail = rail
              if rail.direction == 3 then
                rail = self:getRail(mainRail, 1, 1)
              end
              offsets.mainRail = rail
            end
          end
        end
        if mainRail then
          local lamps = {}
          for _, l in pairs(offsets.poleEntities) do
            if l.name ~= "wooden-chest" then
              table.insert(lamps, {name = l.name, position = Position.subtract(l.position, offsets.pole.position), direction = l.direction, pickup_position = l.pickup_position,
                drop_position = l.drop_position, request_filters = l.request_filters, recipe = l.recipe })
            end
          end
          local railPos = mainRail.position
          if bpType == "diagonal" then
            railPos = FARL.diagonal_to_real_pos(mainRail)
          end
          offsets.pole.position = Position.subtract(offsets.pole.position, railPos)
          local railEntities = {}
          for _, re in pairs(offsets.railEntities) do
            table.insert(railEntities, { name = re.name, position = Position.subtract(re.position, railPos), direction = re.direction })
          end
          local concrete = bp[j].get_blueprint_tiles()
          if concrete then
            local off = { x = 0.5, y = 0.5 }
            local pos = Position.subtract(railPos, off)
            for _, c in pairs(concrete) do
              table.insert(offsets.concrete, { name = c.name, position = Position.subtract(c.position, pos) })
              local position = c.position
              if box.tl.x > position.x then box.tl.x = position.x end
              if box.tl.y > position.y then box.tl.y = position.y end

              if box.br.x < position.x then box.br.x = position.x end
              if box.br.y < position.y then box.br.y = position.y end
            end
          end
          local bp_rails = {}
          local lanes = {}
          local known_rails = {}
          for _, l in pairs(offsets.rails) do
            if not l.main then
              local lane_distance
              local tmp =
                {
                  name = l.name,
                  position = Position.subtract(l.position, mainRail.position),
                  direction = l.direction,
                  type = game.entity_prototypes[l.name].type
                }
              local move_dir = tmp.position.y < 0 and 1 or 5
              if bpType == "diagonal" then
                lane_distance = Position.subtract(FARL.diagonal_to_real_pos(l), FARL.diagonal_to_real_pos(mainRail))
                lane_distance = lane_distance.x + lane_distance.y
              else
                lane_distance = tmp.position.x
              end
              lane_distance = lane_distance / 2
              if not known_rails[lane_distance] and lane_distance ~= 0 then
                table.insert(lanes, lane_distance)
                known_rails[lane_distance] = true
              end
              local altRail, _
              if l.direction % 2 == 1 and mainRail.direction == l.direction then
                _, altRail = self:getRail(tmp, move_dir, 1)
                tmp = altRail
              end
              table.insert(bp_rails, tmp)
            end
            table.sort(lanes)
          end
          local signals = {}
          for _, l in pairs(offsets.signals) do
            local pos = Position.subtract(l.position, offsets.chain.position)
            local reverse = (l.direction ~= offsets.chain.direction)
            if bpType == "straight" then
              if pos.x % 2 == 0 then
                reverse = false
              else
                reverse = true
              end
            end
            table.insert(signals,
              {
                name = l.name,
                position = pos,
                direction = l.direction,
                reverse = reverse
              })
          end
          local tl = Position.subtract(box.tl, FARL.diagonal_to_real_pos(mainRail))
          local br = Position.subtract(box.br, FARL.diagonal_to_real_pos(mainRail))
          --forward
          tl.y = tl.y < -1.5 and tl.y or -1.5
          br.y = br.y > 1.5 and br.y or 1.5
          if bpType == "curve" then
            tl.y = tl.y < -3.5 and tl.y or -3.5
            br.y = br.y > 3.5 and br.y or 3.5
          end
          --right
          tl.x = tl.x < 0 and tl.x or -0.5
          br.x = br.x > 0 and br.x or 0.5
          --br.x = br.x + 1
          local clearance_points = {}
          if bpType == "diagonal" then
            tl.x = tl.x - 1.5
            tl.y = tl.y - 1.5

            br.x = br.x + 1.5
            br.y = br.y + 1.5

            local tl2 = { x = tl.x + 1.5, y = tl.y + 1.5 }
            local br2 = { x = br.x - 1.5, y = br.y - 1.5 }
            for i = tl2.x, br2.x, 1.5 do
              table.insert(clearance_points, { x = i, y = i })
            end
          end
          --debugDump({tl=tl,br=br},true)
          local blueprint = {
            mainRail = mainRail,
            direction = mainRail.direction,
            pole = offsets.pole,
            poleEntities = lamps,
            rails = bp_rails,
            signals = signals,
            concrete = offsets.concrete,
            lanes = lanes,
            clearance_points = clearance_points,
            railEntities = railEntities
          }
          blueprint.boundingBox = {
            tl = tl,
            br = br
          }
          self.settings.activeBP[bpType] = blueprint
          if #bp_rails > 0 then
            self.settings.flipPoles = false
          end
          self:print({ "msg-bp-saved", bpType, { "entity-name." .. blueprint.pole.name } })
        else
          self:print({ "msg-bp-chain-direction" })
        end
      else
        if not bpType then
          self:print({ "msg-bp-rail-direction" })
        elseif not offsets.chain then
          self:print({ "msg-bp-chain-missing" })
        else --if not offsets.pole then
          self:print({ "msg-bp-pole-missing" })
        end
      end
    end
  end
end

FARL.placeRails = function(self, nextRail, newTravelDir)
  local newDir = nextRail.direction
  local newRail = get_fake_rail(nextRail)

  if newRail.type == "curved-rail" then
    self:prepareAreaForCurve(newRail)
  end
  local rtype = newDir % 2 == 0 and "straight" or "diagonal"
  local bp = self.settings.activeBP[rtype]
  local canplace
  if self.settings.bulldozer and newRail.type ~= "curved-rail" then
    self:bulldoze_area(newRail, newTravelDir)
  end
  if newRail.direction % 2 == 0 and newRail.type ~= "curved-rail" then
    local area = self:createBoundingBox(newRail, newTravelDir)
    canplace = self:prepareArea(newRail, area)
    if not canplace then
      canplace = self:prepareArea(newRail)
    end
    --self:showArea(newRail, newTravelDir, area, 2)
  else
    canplace = self:prepareArea(newRail)
  end

  if newRail.direction % 2 == 1 and newRail.name == self.settings.rail.straight then
    for _, p in pairs(bp.clearance_points) do
      local pos = move_right_forward(newRail.position, newTravelDir, p.x, 0)
      local area = Position.expand_to_area(pos, 1.5)
      self:removeTrees(area)
      self:pickupItems(area)
      self:removeStone(area)
    end
  end

  local removeAmount = newRail.type == "curved-rail" and 4 or 1
  local removeItem = self.settings.rail.straight
  local hasRail = self:getCargoCount(newRail.name) >= removeAmount

  if canplace and hasRail then
    newRail.force = self.locomotive.force
    local _, ent = self:genericPlace(newRail)
    if ent then
      self:removeItemFromCargo(removeItem, removeAmount)
    else
      self:deactivate({ "msg-no-entity" })
      return false
    end
    return true, ent
  elseif not canplace then
    return false, { "msg-cant-place" }
  elseif not hasRail then
    return false, { "msg-out-of-rails" }
  end
end

FARL.protect = function(self, ent)
  if self.settings.maintenance or self.settings.bulldozer then
    self.protected = self.protected or {}
    self.protected[self.protected_index] = self.protected[self.protected_index] or {}
    self.protected[self.protected_index][protectedKey(ent)] = ent
  end
end

FARL.protect_tile = function(self, pos_)
  if self.settings.maintenance or self.settings.bulldozer then
    local pos = { x = pos_.x, y = pos_.y }
    if pos.x - round(pos.x) == 0 then
      pos.x = pos.x + 0.5
    end
    if pos.y - round(pos.y) == 0 then
      pos.y = pos.y + 0.5
    end
    self.protected_tiles = self.protected_tiles or {}
    self.protected_tiles[self.protected_index] = self.protected_tiles[self.protected_index] or {}
    self.protected_tiles[self.protected_index][pos.x .. ":" .. pos.y] = true
  end
end

FARL.isProtected = function(self, ent)
  local key = protectedKey(ent)
  if not self.protected then return false end
  for _, protected in pairs(self.protected) do
    if protected[key] == ent then
      return true
    end
  end
  for _, r in pairs(self.path) do
    if r.rail == ent then
      return true
    end
  end
  return false
end

FARL.is_protected_tile = function(self, pos_)
  local pos = { x = pos_.x, y = pos_.y }
  if pos.x - round(pos.x) == 0 then
    pos.x = pos.x + 0.5
  end
  if pos.y - round(pos.y) == 0 then
    pos.y = pos.y + 0.5
  end
  local k = pos.x .. ":" .. pos.y
  for _, protected in pairs(self.protected_tiles) do
    if protected[k] then
      return true
    end
  end
  return false
end

FARL.protectRails = function(self, last_, dir_, limit)
  local last, dir = last_, dir_
  local found, c = 0, 0
  while found and c < limit do
    found = 0
    local paths = self:findNeighbours(last, dir)
    if paths then
      for i = 0, 2 do
        local path = paths[i]
        if type(path) == "table" then
          if found == 0 then
            self:protect(path[3])
            last = path[3]
            dir = path[1]
          end
          found = found + 1
        end
      end
    end
    if found > 1 then
      self:deactivate("Junction detected")
      return false
    else
      if found == 0 then
        return false
      end
    end
    c = c + 1
  end
  return true
end

FARL.placeParallelCurve = function(self, traveldir, rail, lane_index)
  local direction = self.direction
  local input = self.input
  local s_lane = self.settings.activeBP.straight.lanes[lane_index]
  local d_lane = self.settings.activeBP.diagonal.lanes[lane_index]
  local catchup = self.lanes["d" .. direction % 2]["i" .. input]["l" .. lane_index].catchup
  local bi = self.input == 0 and 2 or 0

  if catchup > 0 then
    local dir, last = direction, self.lanerails[lane_index]
    if last then
      for _ = 1, catchup do
        dir, last = self:getRail(last, dir, 1)
        if not last then break end
        if self:getCargoCount(last.name) > 0 then
          self:prepareArea(last)
          --local _, ent = self:genericPlaceGhost(last)
          local _, ent = self:genericPlace(last)
          self.signalCount[lane_index] = self.signalCount[lane_index] + get_signal_weight(last, self.settings)
          if self.signal_in[lane_index] then
            self.signal_in[lane_index] = self.signal_in[lane_index] - 1
          end
          --          if self.fake_signal_in and self.fake_signal_in[lane_index] then
          --            self.fake_signal_in[lane_index] = self.fake_signal_in[lane_index] - 1
          --          end
          if self.settings.signals then
            if self:getCargoCount("rail-signal") > 0 then
              if self:placeParallelSignals(dir, last, lane_index) then self.signalCount[lane_index] = 0 end
            else
              self:flyingText({ "", "Out of ", "rail-signal" }, YELLOW, true)
            end
          end
          --          if global.fake_signals then
          --            if self.fake_signal_in and self.fake_signal_in[lane_index] and self.fake_signal_in[lane_index] < 1 and rail.name ~= self.settings.rail.curved then
          --              if self:place_fake_signal(dir, last, lane_index) then self.fake_signalCount[lane_index] = 0 end
          --            end
          --          end
          if not ent then
            self:print("Failed to create track @" .. Position.tostring(last.position))
            self:flyingText2("E", RED, true, last.position)
          else
            self:removeItemFromCargo(ent.name, 1)
          end
        else
          self:deactivate({ "msg-out-of-rails" })
          return false
        end
      end
    end
  end

  -- invert direction, input, distances for diagonal rails
  if direction % 2 == 1 then
    direction = Position.opposite_direction((direction + FARL.input2dir[input]) % 8)
    input = input == 2 and 0 or 2
    s_lane = -1 * s_lane
    d_lane = -1 * d_lane
  end

  local new_curve = { name = rail.name, type = rail.type, direction = rail.direction, force = rail.force }
  local right = s_lane * 2
  --left hand turns need to go back, moving right already moves the diagonal rail part
  local forward = input == 2 and (s_lane - d_lane) * 2 or (d_lane - s_lane) * 2

  --debugDump("l"..lane_index.." c:"..catchup.." b:"..block,true)

  new_curve.position = move_right_forward(rail.position, direction, right, forward)
  self.lastCurve.blocked[lane_index] = self.lanes["d" .. traveldir % 2]["i" .. bi]["l" .. lane_index].lag

  local remove_item, remove_amount = self.settings.rail.straight, 4
  local hasRail = self:getCargoCount(self.settings.rail.straight) >= remove_amount

  if not hasRail then
    self:deactivate({ "msg-out-of-rails" })
    return false
  end

  self:prepareAreaForCurve(new_curve)
  --local _, ent = self:genericPlaceGhost(new_curve)
  local _, ent = self:genericPlace(new_curve)
  if not ent then
    self:print("Failed to create curve @" .. Position.tostring(new_curve.position))
  else
    self.signalCount[lane_index] = self.signalCount[lane_index] + get_signal_weight(ent, self.settings)
    self:removeItemFromCargo(remove_item, remove_amount)
  end
  return self.lastCurve.blocked[lane_index]
end

FARL.placeParallelTrack = function(self, traveldir, lastRail, lane_index)
  local s_lane = self.settings.activeBP.straight.lanes[lane_index]
  local d_lane = self.settings.activeBP.diagonal.lanes[lane_index]
  local new_rail = get_fake_rail(lastRail)
  local lane = self.lanes["d" .. traveldir % 2]["i0"]["l" .. lane_index]
  local right = traveldir % 2 == 1 and d_lane or s_lane
  local lag = min(lane.lag, self.lanes["d" .. traveldir % 2]["i2"]["l" .. lane_index].lag)

  new_rail = moveRail(new_rail, traveldir, lag)
  new_rail = moveRail(new_rail, (traveldir + 2) % 8, right)

  local hasRail = self:getCargoCount(new_rail.name) > 0
  local blocked = false
  local block
  if not hasRail then
    self:deactivate({ "msg-out-of-rails" })
    return false
  end
  if self.lastCurve.input then
    block = self.lastCurve.blocked[lane_index] + abs(lag)
    blocked = self.lastCurve.dist < block
  end
  --self:flyingText2(self.lastCurve.dist.."<"..block,RED,true,new_rail.position)
  if self.signal_in[lane_index] then
    self.signal_in[lane_index] = self.signal_in[lane_index] - 1
  end
  --    if self.fake_signal_in and self.fake_signal_in[lane_index] then
  --      self.fake_signal_in[lane_index] = self.fake_signal_in[lane_index] - 1
  --    end
  if not blocked and hasRail then
    self:prepareArea(new_rail)
    --local _, ent = self:genericPlaceGhost(new_rail)
    local _, ent = self:genericPlace(new_rail)
    self.signalCount[lane_index] = self.signalCount[lane_index] + get_signal_weight(new_rail, self.settings)
    --self.lanes[lane_index].lastrail = ent or new_rail
    if self.settings.signals then
      if self:getCargoCount("rail-signal") > 0 then
        if self:placeParallelSignals(traveldir, new_rail, lane_index) then self.signalCount[lane_index] = 0 end
      else
        self:flyingText({ "", "Out of ", "rail-signal" }, YELLOW, true)
      end
    end
    --      if global.fake_signals then
    --        if self.fake_signal_in and self.fake_signal_in[lane_index] and self.fake_signal_in[lane_index] < 1 and rail.name ~= self.settings.rail.curved then
    --          if self:place_fake_signal(traveldir, new_rail, lane_index) then self.fake_signalCount[lane_index] = 0 end
    --        end
    --      end
    if not ent then
      self:print("Failed to create track @" .. Position.tostring(new_rail.position))
      log("failed")
      log(serpent.line(new_rail, {comment=false}))
      self:flyingText2("E", RED, true, new_rail.position)
      return new_rail
    else
      self:removeItemFromCargo(ent.name, 1)
      return ent
    end
  end
end

FARL.placeParallelSignals = function(self, traveldir, rail, lane_index)
  --if self.signalCount[lane_index] > self.settings.signalDistance and rail.name ~= self.settings.rail.curved then
  if self.signal_in[lane_index] and self.signal_in[lane_index] < 1 and rail.type ~= "curved-rail" then
    local signals = traveldir % 2 == 0 and self.settings.activeBP.straight.signals or self.settings.activeBP.diagonal.signals
    if signals and type(signals) == "table" and signals[lane_index] then
      local signal_data = signals[lane_index]
      local end_of_rail = signal_data.reverse
      local signal_traveldir = signal_data.reverse and Position.opposite_direction(traveldir) or traveldir
      local signal = get_signal_for_rail(rail, signal_traveldir, end_of_rail)
      signal.force = self.locomotive.force

      self:prepareArea(signal)
      --local success, entity = self:genericPlaceGhost(signal)
      local success, entity = self:genericPlace(signal)
      if entity then
        self:protect(entity)
        self:removeItemFromCargo(signal.name, 1)
        self.signal_in[lane_index] = false
        return success, entity
      else
        --self:print("Can't place signal@"..Position.tostring(pos))
        return success, entity
      end
    end
  end
end

FARL.mirrorEntity = function(pos, traveldir)
  local deg = 0
  if traveldir == 0 then deg = 90
  elseif traveldir == 1 then deg = -45
  elseif traveldir == 2 then deg = 0
  elseif traveldir == 3 then deg = 45
  elseif traveldir == 4 then deg = -90
  elseif traveldir == 5 then deg = -45
  elseif traveldir == 6 then deg = 180
  elseif traveldir == 7 then deg = 45
  end
  local rad = (deg % 360) * math.pi / 180
  local cos, sin = math.cos(2 * rad), math.sin(2 * rad)
  local r = { { x = cos, y = sin }, { x = sin, y = -cos } }
  local ret = { x = 0, y = 0 }
  ret.x = pos.x * r[1].x + pos.y * r[1].y
  ret.y = pos.x * r[2].x + pos.y * r[2].y
  return ret
end

FARL.calcPole = function(self, lastrail, traveldir)
  local status, err = pcall(function()
    local offset
    if not lastrail then error("no rail", 2) end
    if not lastrail.name or not lastrail.type then error("calcPole: invalid rail", 2) end
    if lastrail.type ~= "curved-rail" then
      local diagonal = traveldir % 2 == 1 and true or false
      local pole = not diagonal and self.settings.activeBP.straight.pole or self.settings.activeBP.diagonal.pole
      local pos = Position.copy(pole.position)
      local diff = not diagonal and traveldir or traveldir - 1
      local rad = diff * (math.pi / 4)
      offset = rotate(pos, rad)
      if self.settings.flipPoles then
        offset = FARL.mirrorEntity(offset, traveldir)
      end
      if diagonal then
        local railPos = FARL.diagonal_data[lastrail.direction] or { x = 0, y = 0 }
        offset = Position.add(railPos, offset)
      end
      return offset
    else
      --error("calcPole called with curved", 2)
      return false
    end
  end)
  if not status then
    self:deactivate("Error with calcPole: " .. serpent.dump({ lr = lastrail, tdir = traveldir }, { name = "args", comment = false, sparse = false, sortkeys = true }))
    return false
  else
    return err
  end
end

FARL.placePoleEntities = function(self, traveldir, pole)
  local poleEntities = traveldir % 2 == 0 and self.settings.activeBP.straight.poleEntities or self.settings.activeBP.diagonal.poleEntities
  local diff = traveldir % 2 == 0 and traveldir or traveldir - 1
  local rad = diff * (math.pi / 4)
  if type(poleEntities) == "table" then
    for i = 1, #poleEntities do
      if self:getCargoCount(poleEntities[i].name) > 0 then
        local offset = poleEntities[i].position
        offset = rotate(offset, rad)
        local direction = poleEntities[i].direction and (poleEntities[i].direction + diff) % 8 or 0
        local pickup_position = poleEntities[i].pickup_position and rotate(poleEntities[i].pickup_position, rad) or nil
        local drop_position = poleEntities[i].drop_position and rotate(poleEntities[i].drop_position, rad) or nil
        if self.settings.flipPoles then
          offset = FARL.mirrorEntity(offset, traveldir)
        end
        local pos = Position.add(pole, offset)
        --debugDump(pos, true)
        local entity = { name = poleEntities[i].name, position = pos }
        if self:prepareArea(entity) then
          local _, ent = self:genericPlace{
            name = poleEntities[i].name, position = pos, direction = direction, pickup_position = pickup_position,
            drop_position = drop_position, request_filters = poleEntities[i].request_filters, recipe  = poleEntities[i].recipe, force = self.locomotive.force
          }
          --local _, ent = self:genericPlaceGhost {
          --name = poleEntities[i].name, position = pos, direction = direction, pickup_position = pickup_position, drop_position = drop_position,
          --request_filters = poleEntities[i].request_filters, recipe  = poleEntities[i].recipe, force = self.locomotive.force }
          if ent then
            self:protect(ent)
            self:removeItemFromCargo(poleEntities[i].name, 1)
          else
            self:deactivate("Trying to place " .. poleEntities[i].name .. " failed")
          end
        end
      end
    end
  end
end

FARL.placeRailEntities = function(self, traveldir, rail)
  local railEntities = traveldir % 2 == 0 and self.settings.activeBP.straight.railEntities or self.settings.activeBP.diagonal.railEntities
  local diff = traveldir % 2 == 0 and traveldir or traveldir - 1
  local rad = diff * (math.pi / 4)
  if type(railEntities) == "table" then
    for i = 1, #railEntities do
      if self:getCargoCount(railEntities[i].name) > 0 then
        local offset = railEntities[i].position
        offset = rotate(offset, rad)
        local pos = Position.add(FARL.diagonal_to_real_pos(rail), offset)
        --debugDump(pos, true)
        local entity = { name = railEntities[i].name, position = pos }
        if self:prepareArea(entity) then
          local _, ent = self:genericPlace { name = railEntities[i].name, position = pos, direction = 0, force = self.locomotive.force }
          --local _, ent = self:genericPlaceGhost { name = railEntities[i].name, position = pos, direction = 0, force = self.locomotive.force }
          if ent then
            self:protect(ent)
            self:removeItemFromCargo(railEntities[i].name, 1)
          else
            self:deactivate("Trying to place " .. railEntities[i].name .. " failed")
          end
        end
      end
    end
  end
end

FARL.connectCCNet = function(self, pole)
  if self.settings.ccNet and pole.neighbours.copper[1] and self.ccNetPole then
    if (self.settings.ccWires == 1 and self:getCargoCount("red-wire") > 0)
      or (self.settings.ccWires == 2 and self:getCargoCount("green-wire") > 0)
      or (self.settings.ccWires == 3 and (self:getCargoCount("red-wire") > 0 or self:getCargoCount("green-wire") > 0)) then
      local c
      local items
      if self.settings.ccWires == 1 then
        c = { defines.wire_type.red }
        items = { "red-wire" }
      elseif self.settings.ccWires == 2 then
        c = { defines.wire_type.green }
        items = { "green-wire" }
      else
        c = { defines.wire_type.red, defines.wire_type.green }
        items = { "red-wire", "green-wire" }
      end
      for i = 1, #c do
        if self:getCargoCount(items[i]) > 0 then
          pole.connect_neighbour({ target_entity = self.ccNetPole, wire = c[i] })
          self:removeItemFromCargo(items[i], 1)
        end
      end
    end
  end
  self.ccNetPole = pole
end

FARL.findClosestPole = function(self, minPos)
  local name = self.settings.activeBP.diagonal.pole.name
  local reach = game.entity_prototypes[name].max_wire_distance
  local tmp, ret, minDist = minPos, false, 100
  for _, p in pairs(self.surface.find_entities_filtered { area = Position.expand_to_area(tmp, reach), name = name }) do
    local dist = Position.distance(p.position, tmp)
    --debugDump({dist=dist, minPos=minPos, p=p.position},true)
    if dist < minDist and (p.position.x ~= minPos.x and p.position.y ~= minPos.y) then
      minDist = dist
      ret = p
    end
  end
  return ret
end

FARL.getPolePoints = function(self, rail)
  if not rail then error("no rail", 2) end
  if not rail.r then error("no r", 3) end
  local checks = {}
  local offset = self:calcPole(rail.r, rail.dir)
  local polePos = Position.add(rail.r.position, offset)
  if type(rail.range[1]) ~= "number" then error("no table2", 4) end
  for j = rail.range[1], rail.range[2] do
    table.insert(checks, { dir = rail.dir, pos = Position.translate(polePos, rail.dir, j) })
  end
  return checks
end

FARL.getBestPole = function(self, lastPole, rails)
  local name = self.settings.activeBP.diagonal.pole.name
  local reach = game.entity_prototypes[name].max_wire_distance
  local max_distance = -1
  local maxPole, maxRail
  local points = {}
  if not rails then error("no rail", 2) end
  if type(rails) ~= "table" then error("no table3", 3) end
  if not lastPole then error("nil pole", 3) end
  for _, rail in pairs(rails) do
    local polePoints = self:getPolePoints(rail)
    for _, pole in pairs(polePoints) do
      local pos = pole.pos
      --if foo then self:flyingText2(foo, RED, true, pos) end
      local dist = Position.distance(lastPole.position, pos)
      table.insert(points, { d = dist, p = pos, dir = pole.dir })
      if dist >= max_distance and dist <= reach then
        max_distance = dist
        maxRail = rail.r
        maxPole = { d = dist, p = pos, dir = pole.dir }
      end
    end
  end
  return maxPole, maxRail
end

FARL.getPoleRails = function(self, rail, newDir, oldDir)
  local rails
  if rail.type == "curved-rail" then
    --range[1][2] = 0
    --debugDump({old=ptraveldir,new=pnewDir},true)
    local tracks, tmp = FARL.curvePositions[rail.direction], {}
    tmp.d = { name = self.settings.rail.straight, direction = tracks.diagonal.dir, position = Position.add(rail.position, tracks.diagonal.off), type = "straight-rail" }
    tmp.s = { name = self.settings.rail.straight, direction = tracks.straight.dir, position = Position.add(rail.position, tracks.straight.off), type = "straight-rail" }
    local dDir, sDir
    if oldDir % 2 == 1 then
      sDir = newDir
      dDir = oldDir
      rails = { [1] = { r = tmp.s, dir = sDir, range = { 0, 2 } }, [2] = { r = tmp.d, dir = dDir, range = { -1, 1 } } }
    else
      sDir = oldDir
      dDir = newDir
      rails = { [1] = { r = tmp.d, dir = dDir, range = { 0, 2 } }, [2] = { r = tmp.s, dir = sDir, range = { -1, 1 } } }
    end
  else
    rails = { { r = rail, dir = newDir, range = { 0, 1 } } }
  end
  return rails
end

FARL.placePole = function(self, polePos, poleDir)
  local name = self.settings.activeBP.diagonal.pole.name
  --local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
  --debugDump(Position.distance(pole.position, self.lastPole.position),true)
  local canPlace = self:prepareArea({ name = name, position = polePos })
  if not canPlace and self.surface.count_entities_filtered { area = Position.expand_to_area(polePos, 0.6), name = name } > 1 then
    canPlace = true
    debugLog("--found pole@" .. Position.tostring(polePos))
  end
  local hasPole = self:getCargoCount(name) > 0
  if canPlace and hasPole then
    local _, pole = self:genericPlace { name = name, position = polePos, force = self.locomotive.force }
    if pole then
      debugLog("--Placed pole@" .. Position.tostring(polePos))
      if not pole.neighbours.copper[1] then
        self:flyingText({ "msg-unconnected-pole" }, RED, true)
      end
      if self.settings.poleEntities then
        self:placePoleEntities(poleDir, polePos)
      end
      self:removeItemFromCargo(name, 1)
      self:connectCCNet(pole)
      local s_pole = { name = pole.name, position = pole.position }
      self.lastPole = s_pole
      self:protect(pole)
      return true
    else
      if not canPlace then
        debugDump("Can`t place pole@" .. Position.tostring(polePos), true)
      else
        self.lastPole = { name = name, position = polePos }
      end
    end
  else
    if not hasPole then
      self:flyingText({ "", "Out of ", "", name }, YELLOW, true, Position.add(self.locomotive.position, { x = 0, y = 0 }))
    end
    if not canPlace then
      debugDump("Can`t place pole@" .. Position.tostring(polePos), true)
    end
  end
end

FARL.placeSignal = function(self, traveldir, rail)
  if self.signalCount.main > self.settings.signalDistance and rail.type ~= "curved-rail" then
    --debugDump(self.signalCount,true)
    local signal = get_signal_for_rail(rail, traveldir)
    signal.force = self.locomotive.force
    self:prepareArea(signal)
    local success, entity = self:genericPlace(signal)
    if entity then
      self:protect(entity)
      self:removeItemFromCargo(signal.name, 1)

      --reset lane counter, so that it lines up
      self.signal_in = self.signal_in or {}
      local bptype = rail.direction % 2 == 1 and "diagonal" or "straight"
      for i, _ in pairs(self.settings.activeBP[bptype].lanes) do
        local lane_data = self.lanes["d" .. self.direction % 2]["i0"]["l" .. i]
        self.signal_in[i] = abs(lane_data.lag) + 1
      end
      return success, entity
    else
      --self:print("Can't place signal@"..Position.tostring(pos))
      return success, entity
    end
  end
  return nil
end

FARL.place_fake_signal = function(self, traveldir, rail, lane_index)
  if lane_index then
    local signals = traveldir % 2 == 0 and self.settings.activeBP.straight.signals or self.settings.activeBP.diagonal.signals
    if signals and type(signals) == "table" and signals[lane_index] then
      local signal_data = signals[lane_index]
      traveldir = signal_data.reverse and (traveldir + 4) % 8 or traveldir
    end
  end
  local li = lane_index and lane_index or "main"
  local signal = get_signal_for_rail(rail, traveldir)
  signal.name = "fake-signal"
  signal.force = self.locomotive.force
  local success, entity = self:genericPlace(signal)
  if entity then
    if lane_index and self.fake_signal_in then
      self.fake_signal_in[lane_index] = false
    end
    if self.last_signal[li] and self.last_signal[li].valid then
      self.last_signal[li].destroy()
    end
    self.last_signal[li] = entity
    return success, entity
  end
end

FARL.findLastPole = function(self, rail)
  local name = self.settings.activeBP.diagonal.pole.name
  local reach = game.entity_prototypes[name].max_wire_distance
  local min_distance, pole = 900, nil
  local pos = rail and rail.position or self.locomotive.position
  for _, p in pairs(self.surface.find_entities_filtered { area = Position.expand_to_area(pos, reach), name = name }) do
    local dist = abs(Position.distance(pos, p.position))
    if min_distance > dist then
      pole = p
      min_distance = dist
    end
  end
  local lastrail = self.lastrail or self:findLastRail()
  local trainDir = self.direction or self:calcTrainDir()
  if not pole then
    local offset = { x = 1, y = 1 }
    if lastrail.type ~= "curved-rail" then
      offset = self:calcPole(lastrail, trainDir)
    else
      self:print("calcPole with curved2")
    end
    local tmp = Position.translate(offset, trainDir, reach + 20)
    self.lastPole = { position = Position.add(lastrail.position, tmp), name = name }
    self.lastCheckDir = trainDir
    self.lastCheckPole = Position.add(lastrail.position, offset)
    self.lastCheckRail = lastrail
    debugLog("No pole found, using " .. Position.tostring(self.lastPole.position) .. ", from rail@" .. Position.tostring(lastrail.position))
    --self:placePole(self.lastrail, trainDir)
  else
    debugLog("--Found pole: " .. Position.tostring(pole.position))
    self.ccNetPole = pole
    local s_pole = { name = pole.name, position = pole.position }
    self.lastPole = s_pole
    self:flyingText2("p", GREEN, true, pole.position)
    local calcP = self:calcPole(lastrail, trainDir)
    if not calcP then
      return
    end
    local tmp = Position.translate(calcP, trainDir, -1)
    self.lastCheckPole = Position.add(lastrail.position, tmp)
    self:flyingText2("cp", GREEN, true, self.lastCheckPole)
    self.lastCheckDir = trainDir
    self.lastCheckRail = lastrail
  end
end

FARL.debugInfo = function(self)
  local locomotive = self.locomotive
  log(serpent.block(self, {comment=false}))
  log(self.driver.name)
  log(self.cheat_mode)
  log(self.settings.player.name)
  local foo = nil
  if foo then
    --if not self.active then self:activate() end
    self:print("Train@" .. Position.tostring(locomotive.position) .. " dir:" .. self:calcTrainDir() .. " orient:" .. locomotive.orientation)
    self:print("Frontmover: " .. tostring(self.frontmover))
    self:print("calcDir: " .. self.locomotive.orientation * 8)
    self:print("calcDirRound: " .. round(self.locomotive.orientation * 8, 0))
    --self:show_path()
    local bulldoze_rail = self.frontmover and self.train.back_rail or self.train.front_rail
    self:flyingText("B", GREEN, true, bulldoze_rail.position)
    local rail = self.train.front_rail
    if rail then
      --self:flyingText2("B", GREEN, true, rail.position)
      self:print("Rail@" .. Position.tostring(rail.position) .. " dir:" .. rail.direction)
      local fixed = FARL.diagonal_to_real_pos(rail)
      if rail.direction % 2 == 1 then
        --self:flyingText2("F", GREEN, true, fixed)
        self:print("Fixed: " .. Position.tostring(fixed) .. " dir:" .. rail.direction)
      end
    else
      self:print({ "msg-no-rail" })
    end
    local last = self:findLastRail()
    if last then
      self:print("Last@" .. Position.tostring(last.position) .. " dir:" .. last.direction)
    end
    if self.lastpole then
      self:print("Pole@" .. Position.tostring(self.lastPole))
    end
  end
end

FARL.calcTrainDir = function(self, ent)
  --local r = (self.locomotive.orientation > 0.99 and self.locomotive.orientation < 1) and 0 or self.locomotive.orientation
  if not ent then
    return round(self.locomotive.orientation * 8, 0) --math.floor(r * 8)
  else
    return round(ent.orientation * 8, 0) --math.floor(r * 8)
  end
end

FARL.rail_below_train = function(self)
  return self.frontmover and self.train.front_rail or self.train.back_rail
end

FARL.rail_behind_train = function(self)
  return self.frontmover and self.train.back_rail or self.train.front_rail
end

FARL.get_connected_rail = function(self, rail, straight_only, travelDir)
  local dirs = { 1, 0, 2 }
  local ret = false
  if straight_only then
    dirs = { 1 }
  end
  for _, i in pairs(dirs) do
    local newTravel, nrail = self:getRail(rail, travelDir, i)
    if nrail and newTravel then
      ret = self:findRail(nrail)
      if ret then
        return ret, newTravel
      end
    end
  end
  return ret
end

FARL.getConnectedGhostRail = function(self, rail, travelDir, straight_only)
  local dirs = { 1, 0, 2 }
  local ret = false
  if straight_only then
    dirs = { 1 }
  end
  local newTravel, nrail
  --log("Searching neighbours for " .. rail.ghost_name .. "@" .. serpent.line(rail.position,{comment=false}))
  for _, i in pairs(dirs) do
    --log("input: " .. i)
    newTravel, nrail = self:getGhostRail(rail, travelDir, i)
    --self:flyingText2("C"..i, RED, true, nrail.position)
    if nrail and newTravel then
      --log("searching: " .. nrail.ghost_name .. "@" .. serpent.line(nrail.position,{comment=false}))
      ret = self:findGhostRail(nrail)
      if ret then
        --log("found: " .. ret.ghost_name .. "@" .. serpent.line(ret.position,{comment=false}))
        --self:flyingText2("C"..i.."F", RED, true, ret.position)
        return ret, newTravel, i
      end
    end
  end
  return ret
end

FARL.print = function(self, msg)
  if self.driver and self.driver.name ~= "farl_player" then
    self.driver.print(msg)
  elseif self.startedBy and self.startedBy.valid then
    self.startedBy.print({"", "FARL '", self.locomotive.backer_name,"': ",msg})
  else
    self:flyingText(msg, RED, true)
  end
end

FARL.flyingText = function(self, line, color, show, pos)
  if show then
    pos = pos or Position.add(self.locomotive.position, { x = 0, y = -1 })
    color = color or RED
    self.surface.create_entity({ name = "flying-text", position = pos, text = line, color = color })
  end
end

FARL.flyingText2 = function(self, line, color, show, pos)
  if show then
    pos = pos and Position.add(pos, { x = -0.5, y = -0.5 }) or Position.add(self.locomotive.position, { x = 0, y = -1 })
    color = color or RED
    self.surface.create_entity({ name = "flying-text2", position = pos, text = line, color = color })
  end
end

FARL.create_overlay = function(self, position, duration)
  local tick = game.tick + 60 * duration
  global.overlayStack[tick] = global.overlayStack[tick] or {}
  local overlay = self.surface.create_entity { name = "farl_overlay", position = position }
  overlay.minable = false
  overlay.destructible = false
  table.insert(global.overlayStack[tick], overlay)
end

FARL.showArea = function(self, rail, direction, area, duration)
  local bb = { tl = area[1], br = area[2] }
  local min_x = min(bb.tl.x, bb.br.x)
  local max_x = max(bb.tl.x, bb.br.x)

  local min_y = min(bb.tl.y, bb.br.y)
  local max_y = max(bb.tl.y, bb.br.y)

  min_x = ceil(min_x + 0.5) - 0.5
  min_y = ceil(min_y + 0.5) - 0.5
  max_x = ceil(max_x - 0.5) + 0.5
  max_y = ceil(max_y - 0.5) + 0.5
  for right = min_x, max_x do
    for forward = min_y, max_y do
      local pos = move_right_forward(FARL.diagonal_to_real_pos(rail), direction, right, forward)
      --self:create_overlay({x=right,y=forward},duration)
      self:create_overlay(pos, duration)
    end
  end
  --    for right=min(bb.tl.x,bb.br.x),max(bb.tl.x,bb.br.x) do
  --      for forward=min(bb.tl.y,bb.br.y),max(bb.tl.y,bb.br.y) do
  --        local pos = move_right_forward(FARL.diagonal_to_real_pos(rail),direction,right,forward)
  --        --self:create_overlay({x=right,y=forward},duration)
  --        self:create_overlay(pos, duration)
  --      end
  --    end
end

FARL.showArea2 = function(self, area)
  --area[1] = tl, area[2]=br
  debugDump(area, true)
  for x = area[1].x, area[2].x do
    for y = area[1].y, area[2].y do
      self:create_overlay({ x = x, y = y }, 1)
    end
  end
end

-- [traveldir][rail_type][rail_dir][input] = offset, new rail dir, new rail type
FARL.input_to_next_rail =
  -- 0 to 4, 2 to 6: switch sign
  {
    -- North/South
    [0] = {
      ["straight-rail"] = {
        [0] = {
          [0] = { offset = { x = -1, y = -5 }, direction = 0, type = "curved-rail" },
          [1] = { offset = { x = 0, y = -2 }, direction = 0, type = "straight-rail" },
          [2] = { offset = { x = 1, y = -5 }, direction = 1, type = "curved-rail" }
        }
      },
      ["curved-rail"] = {
        [4] = {
          [0] = { offset = { x = -2, y = -8 }, direction = 0, type = "curved-rail" },
          [1] = { offset = { x = -1, y = -5 }, direction = 0, type = "straight-rail" },
          [2] = { offset = { x = 0, y = -8 }, direction = 1, type = "curved-rail" }
        },
        [5] = {
          [0] = { offset = { x = 0, y = -8 }, direction = 0, type = "curved-rail" },
          [1] = { offset = { x = 1, y = -5 }, direction = 0, type = "straight-rail" },
          [2] = { offset = { x = 2, y = -8 }, direction = 1, type = "curved-rail" }
        },
      }
    },
    [4] = {
      ["straight-rail"] = {
        [0] = {
          [0] = { offset = { x = 1, y = 5 }, direction = 4, type = "curved-rail" },
          [1] = { offset = { x = 0, y = 2 }, direction = 0, type = "straight-rail" },
          [2] = { offset = { x = -1, y = 5 }, direction = 5, type = "curved-rail" }
        }
      },
      ["curved-rail"] = {
        [0] = {
          [0] = { offset = { x = 2, y = 8 }, direction = 4, type = "curved-rail" },
          [1] = { offset = { x = 1, y = 5 }, direction = 0, type = "straight-rail" },
          [2] = { offset = { x = 0, y = 8 }, direction = 5, type = "curved-rail" }
        },
        [1] = {
          [0] = { offset = { x = 0, y = 8 }, direction = 4, type = "curved-rail" },
          [1] = { offset = { x = -1, y = 5 }, direction = 0, type = "straight-rail" },
          [2] = { offset = { x = -2, y = 8 }, direction = 5, type = "curved-rail" }
        },
      }
    },
    -- East/West
    [2] = {
      ["straight-rail"] = {
        [2] = {
          [0] = { offset = { x = 5, y = -1 }, direction = 2, type = "curved-rail" },
          [1] = { offset = { x = 2, y = 0 }, direction = 2, type = "straight-rail" },
          [2] = { offset = { x = 5, y = 1 }, direction = 3, type = "curved-rail" }
        }
      },
      ["curved-rail"] = {
        [6] = {
          [0] = { offset = { x = 8, y = -2 }, direction = 2, type = "curved-rail" },
          [1] = { offset = { x = 5, y = -1 }, direction = 2, type = "straight-rail" },
          [2] = { offset = { x = 8, y = 0 }, direction = 3, type = "curved-rail" }
        },
        [7] = {
          [0] = { offset = { x = 8, y = 0 }, direction = 2, type = "curved-rail" },
          [1] = { offset = { x = 5, y = 1 }, direction = 2, type = "straight-rail" },
          [2] = { offset = { x = 8, y = -2 }, direction = 3, type = "curved-rail" }
        }
      }
    },
    [6] = {
      ["straight-rail"] = {
        [2] = {
          [0] = { offset = { x = -5, y = 1 }, direction = 6, type = "curved-rail" },
          [1] = { offset = { x = -2, y = 0 }, direction = 2, type = "straight-rail" },
          [2] = { offset = { x = -5, y = -1 }, direction = 7, type = "curved-rail" }
        }
      },
      ["curved-rail"] = {
        [2] = {
          [0] = { offset = { x = -8, y = 2 }, direction = 6, type = "curved-rail" },
          [1] = { offset = { x = -5, y = 1 }, direction = 2, type = "straight-rail" },
          [2] = { offset = { x = -8, y = 0 }, direction = 7, type = "curved-rail" }
        },
        [3] = {
          [0] = { offset = { x = -8, y = 0 }, direction = 6, type = "curved-rail" },
          [1] = { offset = { x = -5, y = -1 }, direction = 2, type = "straight-rail" },
          [2] = { offset = { x = -8, y = -2 }, direction = 7, type = "curved-rail" }
        }
      }
    },
    -- NE / SW
    [1] = {
      ["straight-rail"] = {
        [3] = {
          [0] = { offset = { x = 3, y = -3 }, direction = 5, type = "curved-rail" },
          [1] = { offset = { x = 2, y = 0 }, direction = 7, type = "straight-rail" }
        },
        [7] = {
          [1] = { offset = { x = 0, y = -2 }, direction = 3, type = "straight-rail" },
          [2] = { offset = { x = 3, y = -3 }, direction = 6, type = "curved-rail" }
        }
      },
      ["curved-rail"] = {
        [1] = {
          [0] = { offset = { x = 4, y = -6 }, direction = 5, type = "curved-rail" },
          [1] = { offset = { x = 3, y = -3 }, direction = 7, type = "straight-rail" },
        },
        [2] = {
          [1] = { offset = { x = 3, y = -3 }, direction = 3, type = "straight-rail" },
          [2] = { offset = { x = 6, y = -4 }, direction = 6, type = "curved-rail" }
        }
      }
    },
    [5] = {
      ["straight-rail"] = {
        [3] = {
          [1] = { offset = { x = 0, y = 2 }, direction = 7, type = "straight-rail" },
          [2] = { offset = { x = -3, y = 3 }, direction = 2, type = "curved-rail" }
        },
        [7] = {
          [0] = { offset = { x = -3, y = 3 }, direction = 1, type = "curved-rail" },
          [1] = { offset = { x = -2, y = 0 }, direction = 3, type = "straight-rail" },
        }
      },
      ["curved-rail"] = {
        [5] = {
          [0] = { offset = { x = -4, y = 6 }, direction = 1, type = "curved-rail" },
          [1] = { offset = { x = -3, y = 3 }, direction = 3, type = "straight-rail" }
        },
        [6] = {
          [1] = { offset = { x = -3, y = 3 }, direction = 7, type = "straight-rail" },
          [2] = { offset = { x = -6, y = 4 }, direction = 2, type = "curved-rail" }
        }
      }
    },
    -- SE / NW
    [3] = {
      ["straight-rail"] = {
        [1] = {
          [1] = { offset = { x = 2, y = 0 }, direction = 5, type = "straight-rail" },
          [2] = { offset = { x = 3, y = 3 }, direction = 0, type = "curved-rail" }
        },
        [5] = {
          [0] = { offset = { x = 3, y = 3 }, direction = 7, type = "curved-rail" },
          [1] = { offset = { x = 0, y = 2 }, direction = 1, type = "straight-rail" },
        }
      },
      ["curved-rail"] = {
        [3] = {
          [0] = { offset = { x = 6, y = 4 }, direction = 7, type = "curved-rail" },
          [1] = { offset = { x = 3, y = 3 }, direction = 1, type = "straight-rail" }
        },
        [4] = {
          [1] = { offset = { x = 3, y = 3 }, direction = 5, type = "straight-rail" },
          [2] = { offset = { x = 4, y = 6 }, direction = 0, type = "curved-rail" }
        }
      }
    },
    [7] = {
      ["straight-rail"] = {
        [1] = {
          [0] = { offset = { x = -3, y = -3 }, direction = 3, type = "curved-rail" },
          [1] = { offset = { x = 0, y = -2 }, direction = 5, type = "straight-rail" }
        },
        [5] = {
          [1] = { offset = { x = -2, y = 0 }, direction = 1, type = "straight-rail" },
          [2] = { offset = { x = -3, y = -3 }, direction = 4, type = "curved-rail" }
        }
      },
      ["curved-rail"] = {
        [0] = {
          [1] = { offset = { x = -3, y = -3 }, direction = 1, type = "straight-rail" },
          [2] = { offset = { x = -4, y = -6 }, direction = 4, type = "curved-rail" }
        },
        [7] = {
          [0] = { offset = { x = -6, y = -4 }, direction = 3, type = "curved-rail" },
          [1] = { offset = { x = -3, y = -3 }, direction = 5, type = "straight-rail" }
        }
      }
    },
  }

--clearArea[curveDir%4]
FARL.clearAreas =
  {
    [0] = {
      { { x = -2.5, y = -3.5 }, { x = 0.5, y = 0.5 } },
      { { x = -0.5, y = -0.5 }, { x = 2.5, y = 3.5 } }
    },
    [1] = {
      { { x = -2.5, y = -0.5 }, { x = 0.5, y = 3.5 } },
      { { x = -0.5, y = -3.5 }, { x = 2.5, y = 0.5 } }
    },
    [2] = {
      { { x = -3.5, y = -0.5 }, { x = 0.5, y = 2.5 } },
      { { x = -0.5, y = -2.5 }, { x = 3.5, y = 0.5 } }
    },
    [3] = {
      { { x = -3.5, y = -2.5 }, { x = 0.5, y = 0.5 } },
      { { x = -0.5, y = -0.5 }, { x = 3.5, y = 2.5 } },
    }
  }
