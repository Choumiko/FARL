require "util"

--local direction ={ N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7}
input2dir = {[0]=-1,[1]=0,[2]=1}
--[traveldir] ={[raildir]
signalOffset =
  {
    [0] = {
      [0] = {pos={x=1.5,y=0.5}, dir=4}
    },
    [1] = {
      [3] = {pos={x=1.5,y=1.5}, dir=5},
      [7] = {pos={x=0.5,y=0.5}, dir=5}
    },
    [2] = {
      [2] = {pos={x=-0.5,y=1.5}, dir=6}
    },
    [3] = {
      [1]={pos={x=-0.5,y=0.5}, dir=7},
      [5]={pos={x=-1.5,y=1.5}, dir=7}
    },
    [4] = {
      [0] = {pos={x=-1.5,y=-0.5}, dir=0}
    },
    [5] = {
      [3]={pos={x=-0.5,y=-0.5}, dir=1},
      [7]={pos={x=-1.5,y=-1.5}, dir=1}
    },
    [6] = {
      [2] = {pos={x=0.5,y=-1.5}, dir=2}
    },
    [7] = {
      [1]={pos={x=1.5,y=-1.5}, dir=3},
      [5]={pos={x=0.5,y=-0.5}, dir=3}
    },
  }
signalOffsetCurves =
  {
    [0] = {
      [0] = {pos={x=2.5,y=3.5}, dir=4},
      [1] = {pos={x=0.5,y=3.5}, dir=4}
    },
  }

function get_signal_weight(rail, settings)
  local weight = rail.name == settings.rail.curved and settings.curvedWeight or 1
  if rail.name ~= settings.rail.curved then
    if rail.direction % 2 == 1 then
      weight = 0.75
    elseif rail.direction == 0 then
      weight = 1.26
    end
  end
  return weight
end

function addPos(p1,p2)
  if not p1.x then
    error("Invalid position", 2)
  end
  if p2 and not p2.x then
    error("Invalid position 2", 2)
  end
  local p2 = p2 or {x=0,y=0}
  return {x=p1.x+p2.x, y=p1.y+p2.y}
end

function subPos(p1,p2)
  local p2 = p2 or {x=0,y=0}
  return {x=p1.x-p2.x, y=p1.y-p2.y}
end

local rot = {}
for i=0,7 do
  local rad = i* (math.pi/4)
  rot[rad] = {cos=math.cos(rad),sin=math.sin(rad)}
end

function rotate(pos, rad)
  if not rot[rad] then error("rot["..rad.."]",2) end
  local cos, sin = rot[rad].cos, rot[rad].sin
  local r = {{x=cos,y=-sin},{x=sin,y=cos}}
  local ret = {x=0,y=0}
  ret.x = pos.x * r[1].x + pos.y * r[1].y
  ret.y = pos.x * r[2].x + pos.y * r[2].y
  return ret
end

function pos2Str(pos)
  if not pos then
    error("Position is nil", 2)
  end
  if not pos.x or not pos.y then
    pos = {x=0,y=0}
  end
  return util.positiontostr(pos)
end

function fixPos(pos)
  local ret = {}
  if not pos then
    error("Position is nil", 2)
  end
  if pos.x then ret[1] = pos.x end
  if pos.y then ret[2] = pos.y end
  return ret
end

function distance(pos1, pos2)
  if not pos1.x then
    error("invalid pos1", 2)
  end
  if not pos2.x then
    error("invalid pos2", 2)
  end
  return util.distance(pos1, pos2)
end

function expandPos(pos, range)
  local range = range or 0.5
  if not pos or not pos.x then error("invalid pos",3) end
  return {{pos.x - range, pos.y - range}, {pos.x + range, pos.y + range}}
end

-- defines a direction as a number from 0 to 7, with its opposite calculateable by adding 4 and modulo 8
function oppositedirection(direction)
  return (direction + 4) % 8
end

function moveposition(pos, direction, distance)
  if not pos then error("Position is nil", 2) end
  if not pos[1] or not pos[2] then
    error("invalid position", 2)
  end
  if direction % 2 == 0 then
    return util.moveposition(pos, direction, distance)
  else
    local dirs = {[1] = {0,2},
      [3] = {2,4},
      [5] = {4,6},
      [7] = {0,6}}
    return util.moveposition(util.moveposition(pos, dirs[direction][1], distance), dirs[direction][2], distance)
  end
end

function saveBlueprint(player, poleType, type, bp)
  if not global.savedBlueprints[player.name] then
    global.savedBlueprints[player.name] = {}
  end
  if not global.savedBlueprints[player.name][poleType] then
    global.savedBlueprints[player.name][poleType] = {straight = {}, diagonal = {}}
  end
  global.savedBlueprints[player.name][poleType][type] = util.table.deepcopy(bp)
end

function protectedKey(ent)
  if ent.valid then
    return ent.name .. ":" .. ent.position.x..":"..ent.position.y..":"..ent.direction
  end
  return false
end
--apiCalls = {find={item=0,tree=0,stone=0,other=0},canplace=0,create=0,count={item=0,tree=0,stone=0,other=0}}
local RED = {r = 0.9}
local GREEN = {g = 0.7}
local YELLOW = {r = 0.8, g = 0.8}
FARL = {
  curvePositions = {
    [0] = {straight={dir=0, off={x=1,y=3}}, diagonal = {dir=5, off={x=-1,y=-3}}},
    [1] = {straight={dir=0, off={x=-1,y=3}}, diagonal = {dir=3, off={x=1,y=-3}}},
    [2] = {straight={dir=2, off={x=-3,y=1}}, diagonal = {dir=7, off={x=3,y=-1}}},
    [3] = {straight={dir=2, off={x=-3,y=-1}}, diagonal = {dir=5, off={x=3,y=1}}},
    [4] = {straight={dir=0, off={x=-1,y=-3}}, diagonal = {dir=1, off={x=1,y=3}}},
    [5] = {straight={dir=0, off={x=1,y=-3}}, diagonal = {dir=7, off={x=-1,y=3}}},
    [6] = {straight={dir=2, off={x=3,y=-1}}, diagonal = {dir=3, off={x=-3,y=1}}},
    [7] = {straight={dir=2, off={x=3,y=1}}, diagonal = {dir=1, off={x=-3,y=-1}}}
  },
  new = function(player, ent)
    local vehicle, driver = nil, false
    if ent then
      vehicle = ent
    else
      vehicle = player.vehicle
      driver = player
    end
    local new = {
      locomotive = vehicle, train=vehicle.train,
      driver=driver, active=false, lastrail=false,
      direction = false, input = 1, name = vehicle.backer_name,
      signalCount = 0, cruise = false, cruiseInterrupt = 0,
      lastposition = false, maintenance = false, surface = vehicle.surface,
      recheckRails = {}, destroy = false
    }
    new.settings = Settings.loadByPlayer(player)
    setmetatable(new, {__index=FARL})
    return new
  end,

  onPlayerEnter = function(player)
    local i = FARL.findByLocomotive(player.vehicle)
    local farl
    if i then
      global.farl[i].driver = player
      global.farl[i].settings = Settings.loadByPlayer(player)
      global.farl[i].destroy = false
      farl = global.farl[i]
    else
      farl = FARL.new(player)
      table.insert(global.farl, farl)
    end
    farl.train = player.vehicle.train
    farl.frontmover = false
    for i,l in pairs(farl.train.locomotives.front_movers) do
      if l == farl.locomotive then
        farl.frontmover = true
        break
      end
    end
    if remote.interfaces.YARM  and remote.interfaces.YARM.hide_expando then
      farl.settings.YARM_old_expando = remote.call("YARM", "hide_expando", player.index)
    end
    --apiCalls = {find={item=0,tree=0,stone=0,other=0},canplace=0,create=0,count={item=0,tree=0,stone=0,other=0}}
  end,

  onPlayerLeave = function(player, tick)
    for i,f in pairs(global.farl) do
      if f.driver and f.driver.name == player.name then
        --debugDump(f.protectedCount,true)
        f:deactivate()
        f.driver = false
        f.destroy = tick
        f.lastMove = nil
        f.railBelow = nil
        f.next_rail = nil
        if remote.interfaces.YARM and remote.interfaces.YARM.show_expando and f.settings.YARM_old_expando then
          remote.call("YARM", "show_expando", player.index)
        end
        --f.settings = false
        break
      end
    end
    --debugDump(apiCalls,true)
    --apiCalls = {find={item=0,tree=0,stone=0,other=0},canplace=0,create=0,count={item=0,tree=0,stone=0,other=0}}
  end,

  findByLocomotive = function(loco)
    for i,f in pairs(global.farl) do
      if f.locomotive == loco then
        return i
      end
    end
    return false
  end,

  findByPlayer = function(player)
    for i,f in pairs(global.farl) do
      if f.locomotive == player.vehicle then
        f.driver = player
        return f
      end
    end
    return false
  end,

  update = function(self, event)
    if not self.driver then
      return
    end
    if not self.train.valid then
      if self.locomotive.valid then
        self.train = self.locomotive.train
      else
        self.deactivate("Error (invalid train)")
        return
      end
    end

    self.cruiseInterrupt = self.driver.riding_state.acceleration
    self:cruiseControl()
    if self.active then
      self.input = self.driver.riding_state.direction
      --local next_rail = self:findNeighbour(below, self.direction, self.input) or self:get_connected_rail(below, false, self.direction)
      --if not next_rail then
      if not self.lastrail.valid then
        self:deactivate({"msg-error-2"})
        return
      end
      local firstWagon = self.frontmover and self.train.carriages[1] or self.train.carriages[#self.train.carriages]
      if distance(self.lastrail.position, firstWagon.position) < 6 then
        --debugDump(#self.path, true)
        --if not self.last_moved then self.last_moved = game.tick end
        --local diff = game.tick - self.last_moved
        --self:print(diff.."@"..game.tick)
        --self.last_moved = game.tick
        self.acc = self.driver.riding_state.acceleration
        if ((self.acc ~= 3 and self.frontmover) or (self.acc ~=1 and not self.frontmover)) then
          local newTravelDir, nextRail = self:getRail(self.lastrail, self.direction, self.input)
          if not nextRail then
            --debugDump({t=self.direction,type=below.type,dir=below.direction,i=self.input},true)
            --self:print("Need extra rail")
            newTravelDir, nextRail = self:getRail(self.lastrail, self.direction, 1)
            if not nextRail then
              --self:print("What happened?")
              return
            end
          end
          local dir, last = self:placeRails(nextRail, newTravelDir)
          if dir then
            if not last.position and not last.name then
              self:deactivate({"msg-no-entity"})
              return
            end
            -- add created rail to path
            table.insert(self.path, {rail=last, travel_dir=newTravelDir})
            -- remove rails behind train from path
            local behind = self:rail_behind_train()
            local tmp = {}
            local found = false
            for i, r in pairs(self.path) do
              if r.rail == behind then
                found = true
              end
              if found then
                table.insert(tmp, r)
              end
            end
            self.path = tmp
            --self:show_path()
            self:placeConcrete(newTravelDir, last)
            if self.settings.poles and #self.path > 2 then
              local c = #self.path
              local rail = self.path[c-1].rail
              local dir = self.path[c-1].travel_dir
              local rails = self:getPoleRails(rail, dir, self.path[c-2].travel_dir)
              if self.path[c-2].rail.name == self.settings.rail.curved and #rails > 0 then
                rails[1].range[1] = -1
              end
              local bestpole, bestrail = self:getBestPole(self.lastPole, rails, "o")
              if bestpole then
                self.lastCheckPole = bestpole.p
                self.lastCheckDir = bestpole.dir
                self.lastCheckRail = bestrail
                self:flyingText2("bp", RED, true, bestpole.p)
                self:flyingText2("br", RED, true, bestrail.position)
              else
                self:print("should place pole")
                self:flyingText2("sp", RED, true, self.lastCheckPole)
                if self.lastCheckPole.x then
                  local status, err = pcall(function() self:placePole(self.lastCheckPole, self.lastCheckDir) end)
                  if not status then
                    error(err, 2)
                  end
                end
              end
            end


            if self.settings.signals and not self.settings.root then
              self.signalCount = self.signalCount + get_signal_weight(last,self.settings)
              if self.getCargoCount("rail-signal") > 0 then
                if self:placeSignal(newTravelDir,nextRail) then self.signalCount = 0 end
              else
                self:flyingText({"", "Out of ","rail-signal"}, YELLOW, true)
              end
            end
            self.direction = newTravelDir
            self.lastrail = last
            return
          else
            self:deactivate(last)
            return
          end
        end
      else

      end
    end
  end,

  show_path = function(self)
    for i=1, #self.path do
      self:flyingText(i..":"..self.path[i].travel_dir, RED, true, self.path[i].rail.position)
      --debugDump(path[i].rail.position,true)
    end
  end,
  --prepare an area for entity so it can be placed
  prepareArea = function(self,entity,range)
    local pos = entity.position
    local area = (type(range) == "table") and range or false
    local range = (type(range) ~= "number") and 1.5 or false
    area = area and area or expandPos(pos,range)
    if not self:genericCanPlace(entity) then
      self:removeTrees(area)
      self:pickupItems(area)
      self:removeStone(area)
    else
      return true
    end
    if entity and not self:genericCanPlace(entity) then
      self:fillWater(area)
    end
    return self:genericCanPlace(entity)
  end,

  removeTrees = function(self, area)
    --apiCalls.count.tree = apiCalls.count.tree + 1
    local found = false
    for _, entity in pairs(self.surface.find_entities_filtered{area = area, type = "tree"}) do
      found = true
      entity.die()
      if not godmode and self.settings.collectWood then
        self:addItemToCargo("raw-wood", 1)
      end
    end

    if found then
    --apiCalls.find.tree = apiCalls.find.tree + 1
    end
  end,

  removeStone = function(self, area)
    --apiCalls.count.stone = apiCalls.count.stone + 1

    if removeStone then
      local found = false

      for _, entity in pairs(self.surface.find_entities_filtered{area = area, name = "stone-rock"}) do
        found = true
        entity.die()
      end

      if found then
      --apiCalls.find.stone = apiCalls.find.stone + 1
      end
    end
  end,

  -- args = {area=area, name="name"} or {area=area,type="type"}
  -- exclude: table with entities as keys
  removeEntitiesFiltered = function(self, args, exclude)
    --apiCalls.count.other = apiCalls.count.other + 1
    local exclude = exclude or {}
    local found = false

    for _, entity in pairs(self.surface.find_entities_filtered(args)) do
      found = true
      if not self:isProtected(entity) then
        if entity.prototype.items_to_place_this then
          local item
          for k, v in pairs(entity.prototype.items_to_place_this) do
            item = k
            break
          end
          self:addItemToCargo(item, 1)
        end
        if not entity.destroy() then
          self:deactivate({"msg-cant-remove"})
          return
        end
      end
    end

    if found then
    --apiCalls.find.other = apiCalls.find.other + 1
    end
  end,

  fillWater = function(self, area)
    local status, err = pcall(function()
      -- check if bridging is turned on in settings
      if self.settings.bridge then
        -- following code mostly pulled from landfill mod itself and adjusted to fit
        local tiles = {}
        local st, ft = area[1],area[2]
        local dw, w = 0, 0
        if not st[1] then
          st = fixPos(st)
          ft = fixPos(ft)
        end
        for x = st[1], ft[1], 1 do
          for y = st[2], ft[2], 1 do
            local tileName = self.surface.get_tile(x, y).name
            -- check that tile is water, if it is add it to a list of tiles to be changed to grass
            if tileName == "water" or tileName == "deepwater" then
              if tileName == "water" then
                w = w+1
              else
                dw = dw+1
              end
              table.insert(tiles,{name="grass", position={x, y}})
            end
          end
        end
        self:replaceWater(tiles, w, dw)
      end
    end)
    if not status then
      debugDump(area,true)
      error(err, 3)
    end
  end,

  replaceWater = function(self, tiles, w, dw)
    -- check to make sure water tiles were found
    if #tiles ~= 0 then
      -- if they were calculate the minimum number of landfills to fill them in ( quick and dirty at the moment may need tweeking to prevent overusage)
      local lfills = math.ceil(w/2 + dw*1.5)
      local lfills = lfills > 20 and 20 or lfills
      -- check to make sure there is enough landfill in the FARL and if there is apply the changes, remove landfill.  if not then show error message
      if self:getCargoCount("concrete") >= lfills then
        self.surface.set_tiles(tiles)
        self:removeItemFromCargo("concrete", lfills)
      else
        self:print({"msg-not-enough-concrete"})
      end
    end
  end,

  placeConcrete = function(self, dir, rail)
    if rail.type == "curved-rail" then
      return
    end
    local diff = dir % 2 == 0 and dir or dir-1
    local rad = diff * (math.pi/4)

    local type = rail.direction % 2 == 1 and "diagonal" or "straight"
    local concrete = self.settings.activeBP[type].concrete
    local tiles = {}
    local pave = {}
    local w,dw = 0,0
    local counts = {}
    local data = {}
    local railpos = rail.position
    data[1] = {[3] = {x=1,y=1}}
    data[3] = {[5] = {x=-1,y=1}}
    data[5] = {[7] = {x=-1,y=-1}}
    data[7] = {[1] = {x=1,y=-1}}
    local off = {x=0,y=0}
    if rail.direction % 2 == 1 then
      off = data[dir][rail.direction] or off
    end
    railpos = addPos(railpos, off)
    if concrete then
      for _, c in pairs(concrete) do
        local entity = {name = c.name}
        local offset = c.position
        counts[c.name] = counts[c.name] or 0
        offset = rotate(offset, rad)
        local pos = addPos(railpos, offset)
        entity.position = pos
        --self:flyingText2(".", GREEN,true,entity.position)
        local tileName = self.surface.get_tile(pos.x, pos.y).name
        -- check that tile is water, if it is add it to a list of tiles to be changed to grass
        if tileName == "water" or tileName == "deepwater" then
          if self.settings.bridge then
            if tileName == "water" then
              w = w+1
            else
              dw = dw+1
            end
            table.insert(tiles,{name="grass", position={pos.x, pos.y}})
            table.insert(pave, entity)
            counts[c.name] = counts[c.name] + 1
          end
        elseif tileName ~= c.name then
          table.insert(pave, entity)
          counts[c.name] = counts[c.name] + 1
        end
      end
      self:replaceWater(tiles, w, dw)
      local enough  = true
      for name, c in pairs(counts) do
        if self:getCargoCount(name) < c then
          enough = false
        end
      end
      if enough then
        self.surface.set_tiles(pave)
        for name, c in pairs(counts) do
          self:removeItemFromCargo(name, c)
        end
      else
        self:print({"msg-not-enough-concrete"})
      end
    end
  end,

  pickupItems = function(self, area)
    --apiCalls.count.item = apiCalls.count.item + 1
    if self.surface.count_entities_filtered{area = area, name = "item-on-ground"} > 0 then
      --apiCalls.find.item = apiCalls.find.item + 1
      for _, entity in pairs(self.surface.find_entities_filtered{area = area, name="item-on-ground"}) do
        self:addItemToCargo(entity.stack.name, entity.stack.count, entity.stack.prototype.place_result)
        entity.destroy()
      end
    end
  end,

  getRail = function(self, lastRail, travelDir, input)
    -- [traveldir][rail_type][rail_dir][input] = offset, new rail dir, new rail type
    --input_to_next_rail =

    local lastRail, travelDir, input = lastRail, travelDir, input
    if travelDir > 7 or travelDir < 0 then
      self:deactivate("Traveldir wrong: "..travelDir)
      return false,false
    end
    if input > 2 or input < 0 then
      self:deactivate("Input wrong: "..input)
      return travelDir, false
    end
    local data = input_to_next_rail[travelDir][lastRail.type]
    if not data[lastRail.direction] or not data[lastRail.direction][input] then
      if not data[lastRail.direction] then
        return travelDir, false
      end
      input = 1
    end
    data = data[lastRail.direction][input]

    local name = data.type == "straight-rail" and self.settings.rail.straight or self.settings.rail.curved
    local newTravelDir = (travelDir + input2dir[input]) % 8
    return newTravelDir, {name = name, position = addPos(lastRail.position, data.offset), direction=data.direction}
  end,

  cruiseControl = function(self)
    local acc = self.frontmover and defines.riding.acceleration.accelerating or defines.riding.acceleration.reversing
    if self.cruise then
      local limit = self.active and self.settings.cruiseSpeed or 0.9
      local limit = self.settings.cruiseSpeed
      if self.cruiseInterrupt == 2 then
        self:toggleCruiseControl()
        return
      end
      if self.train.speed < limit then
        self.driver.riding_state = {acceleration = acc, direction = self.driver.riding_state.direction}
      elseif self.active and self.train.speed > limit + 0.1 then
        self.driver.riding_state = {acceleration = 2, direction = self.driver.riding_state.direction}
      else
        self.driver.riding_state = {acceleration = 0, direction = self.driver.riding_state.direction}
      end
    end
    if not self.cruise then
      self.driver.riding_state = {acceleration = self.driver.riding_state.acceleration, direction = self.driver.riding_state.direction}
    end
  end,

  findNeighbours = function(self, rail, travelDir)
    local paths = {}
    local found = false
    for i=0,2 do
      local newTravel, nrail = self:getRail(rail, travelDir, i)
      if type(newTravel) == "number" then
        local railEnt = self:findRail(nrail)
        if railEnt then
          paths[i] = {newTravel, nrail, railEnt}
          found = true
        else
          paths[i] = false
        end
      else
        paths[i] = false
      end
    end
    return found and paths or false
  end,

  findNeighbour = function(self, rail, travelDir, input)
    local neighbour = false
    local newTravel, nrail = self:getRail(rail, travelDir, input)
    if nrail then
      local railEnt = self:findRail(nrail)
      if railEnt then
        neighbour = railEnt
      end
    end
    return neighbour
  end,

  findRail = function(self, rail)
    local area = expandPos(rail.position,0.4)
    local found = false
    for i,r in pairs(self.surface.find_entities_filtered{area=area, name=rail.name}) do
      if r.position.x == rail.position.x and r.position.y == rail.position.y and r.direction == rail.direction then
        found = r
        break
      end
    end
    return found
  end,

  activate = function(self)
    local status, err = pcall(function()
      self.lastrail = false
      self.signalCount = 0
      self.recheckRails = {}
      self.protected = {}
      self.protectedCount = 0
      self.protectedCalls = {}
      self.frontmover = false
      for i,l in pairs(self.train.locomotives.front_movers) do
        if l == self.locomotive then
          self.frontmover = true
          break
        end
      end
      local maintenance = self.maintenance and 10 or false
      self.direction = self:calcTrainDir()
      self.lastrail = self:findLastRail(maintenance)
      if not self.lastrail then
        self:deactivate({"msg-error-2"}, true)
        return
      end

      self.path = self:get_rails_below_train()
      if self.lastrail.name == self.settings.rail.curved then
        self:deactivate({"msg-error-curves"}, true)
        return
      end
      local prev = self.path[1].rail
      local prev_dir = oppositedirection(self.path[1].travel_dir)
      local count = 0
      local path = {}
      while prev and count < 20 do
        table.insert(path, {rail=prev, travel_dir=oppositedirection(prev_dir)})
        prev, prev_dir = self:get_connected_rail(prev, true, prev_dir)
        count = count + 1
      end
      for i=2,#path do
        table.insert(self.path, 1, path[i])
      end
      self:show_path()
      local last_signal, signal_rail = false, false
      local signalWeight = 1
      local has_signal = self.getCargoCount("rail-signal") > 0
      for i=1,#self.path,1 do
        local rail = self.path[i].rail
        local dir = self.path[i].travel_dir
        last_signal, signal_rail = self:find_signal_rail(rail, dir)
        if last_signal then
          self.signalCount = 0
        end
        if self.settings.signals and not self.settings.root then
          if has_signal then
            if self:placeSignal(dir,rail) then self.signalCount = 0 end
          else
            self:flyingText({"", "Out of ","rail-signal"}, YELLOW, true)
          end
        end
        self.signalCount = self.signalCount + get_signal_weight(rail,self.settings)
      end
      self:findLastPole(self.lastrail)
      if last_signal and signal_rail then
        self:flyingText2( "S", GREEN, true, last_signal.position)
        self:flyingText2( "SR", GREEN, true, signal_rail.position)
        self:print(self.signalCount)
      end
      self:flyingText2( {"text-behind"}, RED, true, self:rail_behind_train().position)
      self.active = true
    end)
    if not status then
      self:deactivate({"", {"msg-error-activating"}, err})
    end
  end,

  find_signal_rail = function(self, rail, travel_dir)
    local data = signalOffset[travel_dir][rail.direction]
    if not data then return end
    local signal_dir = data.dir
    local signal_pos = addPos(data.pos, rail.position)
    local range = (travel_dir % 2 == 0) and 1 or 0.5
    for _1, name in pairs({"rail-signal", "rail-chain-signal"}) do
      for _, entity in pairs(self.surface.find_entities_filtered{area = expandPos(signal_pos,range), name = name}) do
        if entity.direction == signal_dir then
          return entity, rail
        end
      end
    end
  end,

  get_rails_below_train = function(self)
    local behind = self:rail_behind_train()
    local front = self:rail_below_train()
    local next, dir = behind, self.direction
    local path = {}
    --self:flyingText2("b", RED, true, path[1].position)
    local count = 0
    while next and count < 20 and next ~= front do
      --self:flyingText2("n", RED, true, next.position)
      table.insert(path, {rail = next, travel_dir = dir})
      next, dir = self:get_connected_rail(next, true, dir)
      count = count + 1
    end
    count = 0
    while next and count < 20 do
      --self:flyingText2("p", RED, true, next.position)
      table.insert(path, {rail = next, travel_dir = dir})
      next, dir = self:get_connected_rail(next, true, dir)
      count = count + 1
    end
    return path
  end,

  deactivate = function(self, reason)
    self.active = false
    self.input = nil
    self.cruise = false
    self.path = nil
    if reason then
      self:print({"", {"msg-deactivated"}, ": ", reason})
    end
    self.lastrail = nil
    self.lastCurve = 0
    self.direction = nil
    self.lastPole, self.lastCheckPole = nil,nil
    self.lastCheckRail = nil
    self.ccNetPole = nil
    self.recheckRails = {}
    self.maintenanceRail = nil
    self.maintenanceDir = nil
    self.protected = nil
    self.protectedCount = nil
    self.protectedCalls = {}
  end,

  toggleActive = function(self)
    if not self.active then
      self:activate()
      return
    else
      self:deactivate()
    end
  end,

  toggleCruiseControl = function(self)
    if not self.cruise then
      if self.driver and self.driver.riding_state then
        self.cruise = true
        local input = self.input or 1
        self.driver.riding_state = {acceleration = 1, direction = input}
      end
      return
    else
      if self.driver and self.driver.riding_state then
        self.cruise = false
        local input = self.input or 1
        self.driver.riding_state = {acceleration = self.driver.riding_state.acceleration, direction = input}
      end
      return
    end
  end,

  rootModeAllowed = function(self)
    return (self.train.carriages[1].name == "farl" and self.train.carriages[#self.train.carriages].name == "farl")
  end,

  toggleRootMode = function(self)
    if self:rootModeAllowed() then
      if self.active then
        self:deactivate({"msg-changing-modes"})
      end
      self.settings.root = not self.settings.root
      self.maintenance = false
    else
      self:print({"msg-root-error"})
      self.settings.root = false
    end
  end,

  toggleMaintenance = function(self)
    if self.active then
      self:deactivate({"msg-changing-modes"})
    end
    self.maintenance = not self.maintenance
    self.settings.root = false
  end,

  resetPoleData = function(self)
    self.recheckRails = {}
    self.lastPole, self.lastCheckPole = nil,nil
  end,

  findLastRail = function(self, limit)
    local trainDir = self:calcTrainDir()
    local test = self:rail_below_train()
    local last = test
    local limit, count = limit, 1
    limit = limit or 30
    while test do --and test.name ~= self.settings.rail.curved do
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
      self:flyingText2({"text-front"}, RED, true, last.position)
    end
    return last
  end,

  addItemToCargo = function(self,item, count, place_result)
    local count = count or 1
    local remaining = count - self.train.insert({name=item, count=count})

    if remaining > 0 and (self.settings.dropWood or place_result) then
      local position = self.surface.find_non_colliding_position("item-on-ground", self.driver.position, 100, 0.5)
      self.surface.create_entity{name = "item-on-ground", position = position, stack = {name = item, count = remaining}}
    end
  end,

  removeItemFromCargo = function(self,item, count)
    local count = count or 1
    if godmode then
      return count
    end
    return self.train.remove_item({name=item, count=count})
  end,

  getCargoCount = function(self, item)
    if godmode then return 9001 end
    return self.train.get_item_count(item)
  end,

  genericCanPlace = function(self, arg)
    if not arg.position or not arg.position.x or not arg.position.y then
      error("invalid position", 2)
    elseif not arg.name then
      error("no name", 2)
    end
    local name = arg.innername or arg.name
    --apiCalls.canplace = apiCalls.canplace + 1
    if not arg.direction then
      return self.surface.can_place_entity{name = name, position = arg.position}
    else
      return self.surface.can_place_entity{name = name, position = arg.position, direction = arg.direction}
    end
  end,

  genericPlace = function(self, arg, ignore)
    local canPlace
    if not ignore then
      canPlace = self:genericCanPlace(arg)
    else
      canPlace = true
    end
    local entity
    if canPlace then
      local direction = arg.direction or 0
      local force = arg.force or self.locomotive.force
      arg.force = force
      entity = self.surface.create_entity(arg)
      --apiCalls.create = apiCalls.create + 1
    end
    return canPlace, entity
  end,

  mirror_bp = function(self, bp)
    local curve_bp = false
    local offsets = {pole=false, chain=false, rails={}, signals={}}
    for j=1,#bp do
      local e = bp[j].get_blueprint_entities()
      for i=1,#e do
        local name = e[i].name
        local pos = e[i].position
        local dir = e[i].direction or 0
        local ent = {name=name, position=pos, direction=dir}
        if name == "curved-rail" and not curve_bp then
          curve_bp = bp[j]
        end
        if name == "rail-chain-signal" and not offsets.chain then
          offsets.chain = ent
        elseif name == "rail-signal" then
          table.insert(offsets.signals, ent)
        elseif name == "curved-rail" then
          table.insert(offsets.rails, ent)
        end
      end
    end
    if curve_bp then
      --find rail belonging to chainsignal
      for i, r in pairs(offsets.rails) do
        local signalpos = addPos(r.position, signalOffsetCurves[0][r.direction].pos)
        local diff = subPos(signalpos, offsets.chain.position)
        if diff.x == 0 and diff.y == 0 then
          offsets.main = r
        end
      end
      saveVar(offsets, "BPcurve")
    end
  end,

  --parese blueprints
  -- chain signal: needs direction == 4, defines track that FARL drives on
  --normal signals: define signal position for other tracks
  parseBlueprints2 = function(self, bp)
    for j=1,#bp do
      local vertSignal = signalOffset[0]
      local diagSignal = signalOffset[1]
      local e = bp[j].get_blueprint_entities()
      local concrete = bp[j].get_blueprint_tiles()
      if e then
        local offsets = {pole=false, chain=false, poleEntities={}, rails={}, signals={}, concrete={}}
        local bpType = false
        local rails = 0
        local box = {tl={x=0,y=0}, br={x=0,y=0}}
        for i=1,#e do
          if box.tl.x > e[i].position.x then box.tl.x = e[i].position.x end
          if box.tl.y > e[i].position.y then box.tl.y = e[i].position.y end

          if box.br.x < e[i].position.x then box.br.x = e[i].position.x end
          if box.br.y < e[i].position.y then box.br.y = e[i].position.y end

          local dir = e[i].direction or 0
          if e[i].name == "rail-chain-signal" and not offsets.chain then
            offsets.chain = {direction = dir, name = e[i].name, position = e[i].position}
          elseif e[i].name == "big-electric-pole" or e[i].name == "medium-electric-pole" then
            offsets.pole = {name = e[i].name, direction = dir, position = e[i].position}
          elseif e[i].name == "straight-rail" then
            rails = rails + 1
            if not bpType then
              bpType = (dir == 0 or dir == 4) and "straight" or "diagonal"
            end
            if (bpType == "diagonal" and (dir == 3 or dir == 7)) or (bpType == "straight" and (dir == 0 or dir == 4)) then
              table.insert(offsets.rails, {name = e[i].name, direction = dir, position = e[i].position})
            else
              self:print({"msg-bp-rail-direction"})
              break
            end
          elseif e[i].name == "rail-signal" then
            table.insert(offsets.signals, {name = e[i].name, direction = dir, position = e[i].position})
          else
            table.insert(offsets.poleEntities, {name = e[i].name, direction = dir, position = e[i].position})
          end
        end
        if offsets.chain and offsets.pole and bpType then
          box.tl = addPos(box.tl, self.settings.boundingBoxOffsets[bpType].tl)
          box.br = addPos(box.br, self.settings.boundingBoxOffsets[bpType].br)
          local mainRail = false
          local moved_main_rail = false
          for i,rail in pairs(offsets.rails) do
            local traveldir = (bpType == "straight") and 0 or 1
            local signalOff = signalOffset[traveldir][rail.direction]
            local signalDir = signalOff.dir
            signalOff = signalOff.pos
            --local relChain = subPos(offsets.chain.position,rail.position)
            --local mainPos = subPos(relChain, signalOff)
            local pos = addPos(rail.position, signalOff)
            if not mainRail and pos.x == offsets.chain.position.x and pos.y == offsets.chain.position.y and signalDir == offsets.chain.direction then
              --if not mainRail and mainPos.x == 0 and mainPos.y == 0 and signalDir == offsets.chain.direction then
              rail.main = true
              mainRail = rail
              if rail.direction == 3 then
                rail.position.x = rail.position.x + 2
                rail.direction = 7
                moved_main_rail = true
              end
              offsets.mainRail = rail
            end
          end
          if mainRail then
            if concrete then
              local off = {x=0.5,y=0.5}
              off.x = moved_main_rail and -1.5 or off.x
              for _, c in pairs(concrete) do
                table.insert(offsets.concrete, {name=c.name, position=subPos(addPos(c.position, off), mainRail.position)})
              end
            end
            local lamps = {}
            for _, l in ipairs(offsets.poleEntities) do
              if l.name ~= "wooden-chest" then
                table.insert(lamps, {name=l.name, position=subPos(l.position, offsets.pole.position), direction = l.direction})
              end
            end
            local poleType = offsets.pole.name == "medium-electric-pole" and "medium" or "big"
            local railPos = mainRail.position
            if bpType == "diagonal" then
              railPos = self:fixDiagonalPos(mainRail)
            end
            offsets.pole.position = subPos(offsets.pole.position,railPos)

            local rails = {}
            for _, l in pairs(offsets.rails) do
              if not l.main then
                local tmp =
                  {name=l.name, position=subPos(l.position, mainRail.position),
                    direction = l.direction}
                local altRail, dir
                if l.direction % 2 == 1 and mainRail.direction == l.direction then
                  dir, altRail = self:getRail(tmp, 5, 1)
                  tmp = altRail
                end
                table.insert(rails, tmp)
              end
            end
            local signals = {}
            for _, l in pairs(offsets.signals) do
              table.insert(signals,
                {name=l.name, position=subPos(l.position, offsets.chain.position),
                  direction = l.direction, reverse = (l.direction ~= offsets.chain.direction)})
            end

            local bp = {
              mainRail = mainRail, direction=mainRail.direction, pole = offsets.pole, poleEntities = lamps,
              rails = rails, signals = signals, concrete = offsets.concrete}
            bp.boundingBox = {tl = subPos(box.tl, mainRail.position),
              br = subPos(box.br, mainRail.position)}
            self.settings.bp[poleType][bpType] = bp
            if #rails > 0 then
              self.settings.flipPoles = false
            end
            saveBlueprint(self.driver, poleType, bpType, bp)
            self:print({"msg-bp-saved", bpType, {"entity-name."..poleType.."-electric-pole"}})
          else
            self:print({"msg-bp-chain-direction"})
          end
        else
          if rails <= 1 then
            self:parseBlueprint(e, concrete)
          elseif not bpType then
            self:print({"msg-bp-rail-direction"})
          elseif not offsets.chain then
            self:print({"msg-bp-chain-missing"})
          else --if not offsets.pole then
            self:print({"msg-bp-pole-missing"})
          end
        end
      end
    end
  end,

  parseBlueprint = function(self, bpEntities, concrete)
    local e = bpEntities
    local offsets = {pole=false, poleEntities={}, concrete={}}
    local rail

    for i=1,#e do
      if e[i].name == "straight-rail" or e[i].name == "big-electric-pole" or e[i].name == "medium-electric-pole" then
        if not rail and e[i].name == "straight-rail" then
          local dir = e[i].direction or 0
          rail = {direction = dir, name = e[i].name, position = e[i].position}
        end
        if e[i].name == "big-electric-pole" or e[i].name == "medium-electric-pole" then
          offsets.pole = {name = e[i].name, direction = e[i].direction, position = e[i].position}
        end
      else
        table.insert(offsets.poleEntities, {name = e[i].name, direction = e[i].direction, position = e[i].position})
      end
    end
    if rail and offsets.pole then
      local type = (rail.direction == 0 or rail.direction == 4) and "straight" or "diagonal"
      if type == "diagonal" and not (rail.direction == 3 or rail.direction == 7) then
        self:print({"msg-invalid-rail"})
        return
      end
      if concrete then
        local off = {x=0.5,y=0.5}
        for _, c in pairs(concrete) do
          table.insert(offsets.concrete, {name=c.name, position=subPos(subPos(c.position, off), mainRail.position)})
        end
      end
      local lamps = {}
      for _, l in ipairs(offsets.poleEntities) do
        table.insert(lamps, {name=l.name, position=subPos(l.position, offsets.pole.position)})
      end
      local poleType = offsets.pole.name == "medium-electric-pole" and "medium" or "big"
      local railPos = rail.position
      if type == "diagonal" then
        railPos = self:fixDiagonalPos(rail)
      end
      offsets.pole.position = subPos(offsets.pole.position,railPos)
      local bp = {direction=rail.direction, pole = offsets.pole, poleEntities = lamps}
      self.settings.bp[poleType][type] = bp
      saveBlueprint(self.driver, poleType, type, bp)
      self:print("Saved blueprint for "..type.." rail with "..poleType.. " pole")
    else
      self:print({"", {"msg-bp-no-rail"}, " ",j})
    end
  end,

  placeRails = function(self, nextRail, newTravelDir)
    local newDir = nextRail.direction
    local newPos = nextRail.position
    local newRail = {name = nextRail.name, position = newPos, direction = newDir}
    if newRail.name == self.settings.rail.curved then
      local areas = clearAreas[newRail.direction%4]
      for i=1,2 do
        local area = areas[i]
        local tl, lr = fixPos(addPos(newRail.position,area[1])), fixPos(addPos(newRail.position,area[2]))
        area = {{tl[1]-1,tl[2]-1},{lr[1]+1,lr[2]+1}}
        self:removeTrees(area)
        self:pickupItems(area)
        self:removeStone(area)
        if not self:genericCanPlace(newRail) then
          self:fillWater(area)
        end
      end
    end
    local rtype = newDir % 2 == 0 and "straight" or "diagonal"
    local bp =  self.settings.activeBP[rtype]
    local rails = bp.rails
    local mainRail = bp.mainRail
    local bb = bp.boundingBox

    self:prepareArea(newRail, {addPos(bb.tl,newRail.position), addPos(bb.br, newRail.position)})
    local canplace = self:prepareArea(newRail)
    local hasRail = self:getCargoCount(newRail.name) > 0
    if canplace and hasRail then
      newRail.force = self.locomotive.force
      local _, ent = self:genericPlace(newRail)
      if self.settings.electric then
        remote.call("dim_trains", "railCreated", newPos)
      end
      if ent then
        self:removeItemFromCargo(nextRail.name, 1)
        if newRail.name ~= self.settings.rail.curved then
          self.lastCurve = self.lastCurve + 1
          if self.settings.parallelTracks and self.lastCurve > self.settings.parallelLag then
            self:placeParallelTracks(newTravelDir, newRail)
          end
        else
          self.lastCurve = 0
        end
      else
        self:deactivate({"msg-no-entity"})
        return false
      end
      return true, ent
    elseif not canplace then
      return false, {"msg-cant-place"}
    elseif not hasRail then
      return false, {"msg-out-of-rails"}
    end
  end,

  findNextMaintenanceRail = function(self)
    --debugDump({self.maintenanceRail.position,self.maintenanceDir},true)
    local paths = self:findNeighbours(self.maintenanceRail, self.maintenanceDir)
    local found = 0
    if paths then
      for i=0,2 do
        local path = paths[i]
        if type(path) == "table" then
          if found == 0 then
            self.maintenanceRail = path[3]
            self.maintenanceDir = path[1]
            self:protect(path[3])
            --self:flyingText2("M", RED, true, path[3].position)
          end
          found = found + 1
        end
      end
    end
    if found == 1 then
      return self:protectRails(self.maintenanceRail, self.maintenanceDir, 10)
    else
      if found > 0 then
        --debugDump(self.protectedCount,true)
        self:deactivate("Junction detected")
      end
      return false
    end
  end,

  protect = function(self, ent)
    self.protected = self.protected or {}
    self.protectedCount = self.protectedCount or 0
    self.protected[protectedKey(ent)] = ent
    self.protectedCount = self.protectedCount + 1
  end,

  isProtected = function(self, ent)
    local key = protectedKey(ent)
    if self.protected and self.protected[key] == ent then
      self.protectedCalls[key] = self.protectedCalls[key] and self.protectedCalls[key] + 1 or 1
      --debugDump(key.." "..self.protectedCalls[key],true)
      --if self.protectedCalls[key] >= 10 then
      --self.protectedCalls[key] = nil
      --self.protected[key] = nil
      --self.protectedCount = self.protectedCount - 1
      --debugDump(self.protectedCount,true)
      --end
      return true
    end
    return false
  end,

  protectRails = function(self, last, dir, limit)
    local last, dir = last, dir
    local found, c = 0, 0
    while found and c < limit do
      found = 0
      local paths = self:findNeighbours(last, dir)
      if paths then
        for i=0,2 do
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
        --debugDump(self.protectedCount,true)
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
  end,

  prepareMaintenance = function(self, traveldir, lastRail)
    local rtype = traveldir % 2 == 0 and "straight" or "diagonal"
    local bp =  self.settings.activeBP[rtype]
    local rails = bp.rails
    local mainRail = bp.mainRail
    local bb = bp.boundingBox
    local tl, br
    if bb then
      tl = addPos(bb.tl)
      br = addPos(bb.br)
      local tl1, br1 = {x=tl.x,y=tl.y},{x=br.x,y=br.y}
      if traveldir == 2 or traveldir == 3 then
        tl1.x, br1.x = -br.y, -tl.y
        tl1.y, br1.y = tl.x, br.x
      elseif traveldir == 4 or traveldir == 5 then
        tl1, br1 = {x=-br.x,y=-br.y}, {x=-tl.x,y=-tl.y}
      elseif traveldir == 6 or traveldir == 7 then
        tl1.x, br1.x = -br.y, -tl.y
        tl1.y, br1.y = -br.x, -tl.x
      end
      if traveldir == 7 then
        tl1.y = tl1.y-2
        tl1.x = tl1.x+1
        br1.y = br1.y - 2
        br1.x = br1.x + 1
      end
      --debugDump({tl=tl1,br=br1},true)
      tl = addPos(lastRail.position, tl1)
      br = addPos(lastRail.position, br1)

      --      local tiles = {}
      --      for x = tl.x,br.x do
      --        for y = tl.y,br.y do
      --          table.insert(tiles, {name="concrete", position={x,y}})
      --          --table.insert(tiles, {name="stone-path", position={x,y}})
      --        end
      --      end
      --      self.surface.set_tiles(tiles)

      self:removeTrees({tl,br})
      self:pickupItems({tl,br})
      self:removeStone({tl,br})

      local types = {"straight-rail", "curved-rail", "rail-signal", "rail-chain-signal", "electric-pole", "lamp"}
      for _, t in pairs(types) do
        self:removeEntitiesFiltered({area={tl,br}, type=t}, self.protected)
      end
    else

    end
  end,

  placeParallelTracks = function(self, traveldir, lastRail)
    local rtype = traveldir % 2 == 0 and "straight" or "diagonal"
    local bp =  self.settings.activeBP[rtype]
    local rails = bp.rails
    local mainRail = bp.mainRail
    local bb = bp.boundingBox
    local tl, br
    if bb then
      tl = addPos(bb.tl)
      br = addPos(bb.br)
      local tl1, br1 = {x=tl.x,y=tl.y},{x=br.x,y=br.y}
      if traveldir == 2 or traveldir == 3 then
        tl1.x, br1.x = -br.y, -tl.y
        tl1.y, br1.y = tl.x, br.x
      elseif traveldir == 4 or traveldir == 5 then
        tl1, br1 = {x=-br.x,y=-br.y}, {x=-tl.x,y=-tl.y}
      elseif traveldir == 6 or traveldir == 7 then
        tl1.x, br1.x = -br.y, -tl.y
        tl1.y, br1.y = -br.x, -tl.x
      end
      if traveldir == 7 then
        tl1.y = tl1.y-2
        tl1.x = tl1.x+1
        br1.y = br1.y - 2
        br1.x = br1.x + 1
      end
      --debugDump({tl=tl1,br=br1},true)
      tl = addPos(lastRail.position, tl1)
      br = addPos(lastRail.position, br1)

      --      local tiles = {}
      --      for x = tl.x,br.x do
      --        for y = tl.y,br.y do
      --          table.insert(tiles, {name="concrete", position={x,y}})
      --          --table.insert(tiles, {name="stone-path", position={x,y}})
      --        end
      --      end
      --      self.surface.set_tiles(tiles)

      self:removeTrees({tl,br})
      self:pickupItems({tl,br})
      self:removeStone({tl,br})
    else
    --self:print("No bounding box found. Reread blueprints")
    end
    if rails and type(rails) == "table" then
      local diff = traveldir % 2 == 0 and traveldir or traveldir-1
      local rad = diff * (math.pi/4)
      for i=1,#rails do
        if self:getCargoCount(rails[i].name) > 1 then
          local entity = {name = rails[i].name, direction = lastRail.direction, force = self.locomotive.force}
          local offset = rails[i].position
          offset = rotate(offset, rad)
          local pos = addPos(lastRail.position, offset)
          entity.position = pos
          if traveldir % 2 == 1 then
            entity = self:fixDiagonalParallelTracks(entity, traveldir, mainRail.direction)
          end
          local area = bb and {bb.tl, bb.br} or false
          if self:prepareArea(entity) then
            local _, ent = self:genericPlace(entity)
            if ent then
              if self.maintenance then
                self:protect(ent)
              end
              self:removeItemFromCargo(rails[i].name, 1)
              if self.settings.electric then
                remote.call("dim_trains", "railCreated", entity.position)
              end
            else
              self:deactivate("Trying to place "..rails[i].name.." failed")
            end
          end
        end
      end
    end
  end,

  placeParallelSignals = function(self,traveldir, signal)
    local signals = traveldir % 2 == 0 and self.settings.activeBP.straight.signals or self.settings.activeBP.diagonal.signals
    if signals and type(signals) == "table" then
      local diff = traveldir % 2 == 0 and traveldir or traveldir-1
      local rad = diff * (math.pi/4)
      for i=1,#signals do
        if self:getCargoCount(signals[i].name) > 1 then
          local offset = signals[i].position
          offset = rotate(offset, rad)
          local pos = addPos(signal.position, offset)
          --debugDump(pos, true)
          local entity = {name = signals[i].name, position = pos, force = self.locomotive.force}
          entity.direction = signals[i].reverse and ((signal.direction+4)%8)or signal.direction
          if self:prepareArea(entity) then
            local _, ent = self:genericPlace(entity)
            if ent then
              if self.maintenance then
                self:protect(ent)
              end
              self:removeItemFromCargo(signals[i].name, 1)
            else
              self:deactivate("Trying to place "..signals[i].name.." failed")
            end
          end
        end
      end
    end
  end,

  flipEntity = function(self, pos, traveldir)
    local ret = {x=pos.x, y=pos.y}
    if traveldir % 2 == 1 then
      if ret.x == ret.y and ret.x then return ret end
      return {x=ret.x * -1, y=ret.y * -1}
    end
    if traveldir == 0 or traveldir == 4 then
      ret.x = ret.x * -1
    elseif traveldir == 2 or traveldir == 6 then
      ret.y = ret.y * -1
    end
    return ret
  end,

  mirrorEntity = function(self, pos, traveldir)
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
    local rad = (deg%360) * math.pi/180
    local cos, sin = math.cos(2*rad) , math.sin(2*rad)
    local r = {{x=cos,y=sin},{x=sin,y=-cos}}
    local ret = {x=0,y=0}
    ret.x = pos.x * r[1].x + pos.y * r[1].y
    ret.y = pos.x * r[2].x + pos.y * r[2].y
    return ret
  end,

  fixDiagonalPos = function(self, rail, mul)
    local x,y = 0,0
    -- 1 +x -y
    if rail.direction == 1 then
      x, y = 0.5, - 0.5
    elseif rail.direction == 3 then
      x, y = 0.5, 0.5
      -- 5 -x +y
    elseif rail.direction == 5 then
      x, y = - 0.5, 0.5
    elseif rail.direction == 7 then
      x, y = - 0.5, - 0.5
    else
      x, y = 0, 0
    end
    if mul then
      x = x*mul
      y = y*mul
    end
    return addPos({x=x,y=y}, rail.position)
  end,

  fixDiagonalParallelTracks = function(self, rail, dir)
    --debugDump({railDir = rail.direction, tdir = dir},true)
    local x,y = 0,0
    local newDir = rail.direction
    local data = {}
    --data[raildir][traveldir] = {x,y,newDir}
    data[1] = {[7] = {x=2,y=-2}}
    data[3] = {[1] = {x=2,y=2}}
    data[5] = {[3] = {x=-2,y=2}}
    data[7] = {[5] = {x=-2,y=-2}}
    local tmp = util.table.deepcopy(rail)
    tmp.direction = (rail.direction + 4) % 8
    local c = (data[rail.direction] and data[rail.direction][dir]) and data[rail.direction][dir] or {x=0,y=0}
    tmp.position = addPos(c, rail.position)
    return tmp
  end,

  calcPole = function(self,lastrail, traveldir)
    local status, err = pcall(function()
      local offset
      if not lastrail then error("no rail",2) end
      if not lastrail.name then error("calcPole: invalid rail", 2) end
      if lastrail.name ~= self.settings.rail.curved then
        local diagonal = traveldir % 2 == 1 and true or false
        local pole = not diagonal and self.settings.activeBP.straight.pole or self.settings.activeBP.diagonal.pole
        local pos = addPos(pole.position)
        local diff = not diagonal and traveldir or traveldir-1
        local rad = diff * (math.pi/4)
        offset = rotate(pos, rad)
        if self.settings.flipPoles then
          offset = self:mirrorEntity(offset, traveldir)
        end
        if diagonal then
          local x,y = 0,0
          -- 1 +x -y
          if lastrail.direction == 1 then
            x, y = 0.5, - 0.5
          elseif lastrail.direction == 3 then
            x, y = 0.5, 0.5
            -- 5 -x +y
          elseif lastrail.direction == 5 then
            x, y = - 0.5, 0.5
          elseif lastrail.direction == 7 then
            x, y = - 0.5, - 0.5
          end
          local railPos = {x=x,y=y}
          offset = addPos(railPos, offset)
        end
        return offset
      else
        --error("calcPole called with curved", 2)
        return false
      end
    end)
    if not status then
      self:deactivate("Error with calcPole: "..serpent.dump({lr=lastrail, tdir=traveldir}, {name="args", comment=false, sparse=false, sortkeys=true}))
      return false
    else
      return err
    end
  end,

  placePoleEntities = function(self,traveldir,pole)
    local poleEntities = traveldir % 2 == 0 and self.settings.activeBP.straight.poleEntities or self.settings.activeBP.diagonal.poleEntities
    local diff = traveldir % 2 == 0 and traveldir or traveldir-1
    local rad = diff * (math.pi/4)
    if type(poleEntities) == "table" then
      for i=1,#poleEntities do
        if self:getCargoCount(poleEntities[i].name) > 1 then
          local offset = poleEntities[i].position
          offset = rotate(offset, rad)
          if self.settings.flipPoles then
            offset = self:mirrorEntity(offset, traveldir)
          end
          local pos = addPos(pole, offset)
          --debugDump(pos, true)
          local entity = {name = poleEntities[i].name, position = pos}
          if self:prepareArea(entity) then
            local _, ent = self:genericPlace{name = poleEntities[i].name, position = pos, direction=0,force = self.locomotive.force}
            if ent then
              if self.maintenance then
                self:protect(ent)
              end
              self:removeItemFromCargo(poleEntities[i].name, 1)
            else
              self:deactivate("Trying to place "..poleEntities[i].name.." failed")
            end
          end
        end
      end
    end
  end,

  connectCCNet = function(self, pole)
    if self.settings.ccNet and pole.neighbours.copper[1] and self.ccNetPole then
      if (self.settings.ccWires == 1 and self:getCargoCount("red-wire") > 0)
        or (self.settings.ccWires == 2 and self:getCargoCount("green-wire") > 0)
        or (self.settings.ccWires == 3 and (self:getCargoCount("red-wire") > 0 or self:getCargoCount("green-wire") > 0)) then
        local c = {}
        local items = {}
        if self.settings.ccWires == 1 then
          c = {defines.circuitconnector.red}
          items = {"red-wire"}
        elseif self.settings.ccWires == 2 then
          c = {defines.circuitconnector.green}
          items = {"green-wire"}
        else
          c = {defines.circuitconnector.red, defines.circuitconnector.green}
          items = {"red-wire", "green-wire"}
        end
        for i=1,#c do
          if self:getCargoCount(items[i]) > 0 then
            pole.connect_neighbour({target_entity = self.ccNetPole, wire=c[i]})
            self:removeItemFromCargo(items[i], 1)
          end
        end
      end
    end
    self.ccNetPole = pole
  end,

  findClosestPole = function(self, minPos)
    local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
    local tmp, ret, minDist = minPos, false, 100
    local reach = self.settings.medium and 9 or 30
    for i,p in pairs(self.surface.find_entities_filtered{area=expandPos(tmp, reach), name=name}) do
      local dist = distance(p.position, tmp)
      --debugDump({dist=dist, minPos=minPos, p=p.position},true)
      local diff = subPos(p.position,self.lastPole.position)
      if dist < minDist and (p.position.x ~= minPos.x and p.position.y ~= minPos.y) then
        minDist = dist
        ret = p
      end
    end
    return ret
  end,

  getPolePoints = function(self, rail)
    if not rail then error("no rail",2) end
    if not rail.r then error("no r", 3)end
    local checks = {}
    local offset = self:calcPole(rail.r, rail.dir)
    local polePos = addPos(rail.r.position, offset)
    if type(rail.range[1])~="number" then error("no table2", 4)end
    for j=rail.range[1],rail.range[2] do
      table.insert(checks, {dir=rail.dir, pos=moveposition({polePos.x, polePos.y}, rail.dir, j)})
    end
    return checks
  end,

  getBestPole = function(self, lastPole, rails, foo)
    local reach = self.settings.medium and 9 or 30
    local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
    local min, max = 100, -1
    local minPole, maxPole, maxRail
    local points = {}
    if not rails then error("no rail",2) end
    if type(rails)~="table" then error("no table3", 3)end
    if not lastPole then error("nil pole", 3) end
    for j, rail in pairs(rails) do
      local polePoints = self:getPolePoints(rail)
      for i,pole in pairs(polePoints) do
        local pos = {x=pole.pos[1],y=pole.pos[2]}
        if foo then self:flyingText2(foo, RED, true, pos) end
        local dist = distance(lastPole.position, pos)
        table.insert(points, {d=dist, p=pos, dir=pole.dir})
        if dist >= max and dist <= reach then
          max = dist
          maxRail = rail.r
          maxPole =  {d=dist,p=pos, dir=pole.dir}
        end
      end
    end
    return maxPole, maxRail
  end,

  getPoleRails = function(self, rail, newDir, oldDir)
    local rails = {}
    if rail.name == self.settings.rail.curved then
      --range[1][2] = 0
      --debugDump({old=ptraveldir,new=pnewDir},true)
      local tracks, tmp = FARL.curvePositions[rail.direction], {}
      tmp.d = {name=self.settings.rail.straight, direction=tracks.diagonal.dir, position=addPos(rail.position,tracks.diagonal.off)}
      tmp.s = {name=self.settings.rail.straight, direction=tracks.straight.dir, position=addPos(rail.position,tracks.straight.off)}
      local dDir, sDir
      if oldDir % 2 == 1 then
        sDir = newDir
        dDir = oldDir
        rails = {[1] = {r=tmp.s, dir=sDir, range={0,2}}, [2] = {r=tmp.d, dir=dDir, range={-1,1}}}
      else
        sDir = oldDir
        dDir = newDir
        rails = {[1] = {r=tmp.d, dir=dDir, range={0,2}}, [2] = {r=tmp.s, dir=sDir, range={-1,1}}}
      end
    else
      rails = {{r=rail, dir=newDir, range={0,1}}}
    end
    return rails
  end,

  placePole = function(self, polePos, poleDir)
    local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
    local lastPole = self.lastPole
    local pole = {name = name, position = polePos}
    --debugDump(util.distance(pole.position, self.lastPole.position),true)
    local canPlace = self:prepareArea(pole)
    if not canPlace and self.surface.count_entities_filtered{area=expandPos(pos,0.4),name=name} > 1 then
      canPlace = true
    end
    local hasPole = self:getCargoCount(name) > 0
    if canPlace and hasPole then
      local success, pole = self:genericPlace{name = name, position = polePos, force = self.locomotive.force}
      if pole then
        if not pole.neighbours.copper[1] then
          self:flyingText({"msg-unconnected-pole"}, RED, true)
        end
        if self.settings.poleEntities then
          self:placePoleEntities(poleDir, polePos)
        end
        self:removeItemFromCargo(name, 1)
        self:connectCCNet(pole)
        self.lastPole = pole
        if self.maintenance then
          self:protect(pole)
        end
        return true
      else
        if not canPlace then
          debugDump("Can`t place pole@"..pos2Str(polePos),true)
        else
          self.lastPole = {name = name, position=polePos}
        end
      end
    else
      if not hasPole then
        self:flyingText({"","Out of ", "",name}, YELLOW, true, addPos(self.locomotive.position, {x=0,y=0}))
      end
      if not canPlace then
        debugDump("Can`t place pole@"..pos2Str(polePos),true)
      end
    end
  end,

  placeSignal = function(self,traveldir, rail)
    if self.signalCount > self.settings.signalDistance and rail.name ~= self.settings.rail.curved then
      local rail = rail
      local data = signalOffset[traveldir]
      local offset = data[rail.direction].pos
      local dir = data[rail.direction].dir
      if self.settings.flipSignals then
        local off = offset
        if traveldir % 2 == 1 then
          off = data[(rail.direction+4)%8] or data.pos
        end
        offset = {x=off.x*-1, y=off.y*-1}
        dir = (dir + 4) % 8
      end
      local pos = addPos(rail.position, offset)
      local signal = {name = "rail-signal", position = pos, direction = dir, force = self.locomotive.force}

      self:prepareArea(signal)
      local success, entity = self:genericPlace(signal)
      if entity then
        if self.maintenance then
          self:protect(entity)
        end
        self:removeItemFromCargo(signal.name, 1)
        if self.settings.parallelTracks and self.lastCurve > self.settings.parallelLag and not self.settings.root then
          self:placeParallelSignals(traveldir, entity)
        end
        return success, entity
      else
        --self:print("Can't place signal@"..pos2Str(pos))
        return success, entity
      end
    end
    return nil
  end,

  findLastPole = function(self, rail)
    local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
    local reach = self.settings.medium and 9 or 30
    local min, pole = 900, nil
    local pos = rail and rail.position or self.locomotive.position
    for i, p in pairs(self.surface.find_entities_filtered{area=expandPos(pos, reach), name=name}) do
      local dist = math.abs(distance(pos,p.position))
      if min > dist then
        pole = p
        min = dist
      end
    end
    local lastrail = self.lastrail or self:findLastRail()
    local trainDir = self.direction or self:calcTrainDir()
    if not pole then
      local offset = {x=1,y=1}
      if lastrail.name ~= self.settings.rail.curved then
        offset = self:calcPole(lastrail, trainDir)
      else
        self:print("calcPole with curved2")
      end
      local tmp = moveposition(fixPos(offset), trainDir, 50)
      tmp.x, tmp.y = tmp[1],tmp[2]
      self.lastPole = {position=addPos(lastrail.position, tmp)}
      self.lastCheckDir = trainDir
      self.lastCheckPole = addPos(lastrail.position, offset)
      self.lastCheckRail = lastrail
      --self:placePole(self.lastrail, trainDir)
    else
      self.ccNetPole = pole
      self.lastPole = pole
      self:flyingText2("p", GREEN, true, pole.position)
      local calcP = self:calcPole(lastrail,trainDir)
      if not calcP then
        return
      end
      local tmp = moveposition(fixPos(calcP), trainDir, -1)
      tmp.x, tmp.y = tmp[1], tmp[2]
      self.lastCheckPole = addPos(lastrail.position, tmp)
      self:flyingText2("cp", GREEN, true, self.lastCheckPole)
      self.lastCheckDir = trainDir
      self.lastCheckRail = lastrail
    end
  end,

  debugInfo = function(self)
    self.recheckRails = self.recheckRails or {}
    local locomotive = self.locomotive
    local player = self.driver
    --if not self.active then self:activate() end
    self:print("Train@"..pos2Str(locomotive.position).." dir:"..self:calcTrainDir().." orient:"..locomotive.orientation)
    self:print("Frontmover: "..tostring(self.frontmover))
    self:print("calcDir: "..self.locomotive.orientation * 8)
    local rail = self.train.front_rail
    if rail then
      --self:flyingText2("B", GREEN, true, rail.position)
      self:print("Rail@"..pos2Str(rail.position).." dir:"..rail.direction)
      local fixed = self:fixDiagonalPos(rail)
      if rail.direction % 2 == 1 then
        --self:flyingText2("F", GREEN, true, fixed)
        self:print("Fixed: "..pos2Str(fixed).." dir:"..rail.direction)
      end
    else
      self:print({"msg-no-rail"})
    end
    local last = self:findLastRail()
    if last then
      self:print("Last@"..pos2Str(last.position).." dir:"..last.direction)
    end
    if self.lastpole then
      self:print("Pole@"..pos2Str(self.lastPole))
    end
  end,

  calcTrainDir = function(self)
    local r = (self.locomotive.orientation > 0.99 and self.locomotive.orientation < 1) and 0 or self.locomotive.orientation
    return math.floor(r * 8)
  end,

  rail_below_train = function(self)
    return self.frontmover and self.train.front_rail or self.train.back_rail
  end,

  rail_behind_train = function(self)
    return self.frontmover and self.train.back_rail or self.train.front_rail
  end,

  get_connected_rail = function(self, rail, straight_only, travelDir)
    local dir = self.frontmover and self.train.rail_direction_from_front_rail or self.train.rail_direction_from_back_rail
    local dirs = {1,0,2}
    local ret = false
    if straight_only then
      dirs = {1}
    end
    for _, i in pairs(dirs) do
      local newTravel, nrail = self:getRail(rail, travelDir, i)
      if nrail and newTravel then
        ret = self:findRail(nrail)
        if ret then
          return ret, newTravel
        end
      end
      --ret =  rail.get_connected_rail{rail_direction=dir, rail_connection_direction=i}
      --if ret then
      --return ret
      --end
    end
    return ret
  end,

  print = function(self, msg)
    if self.driver and self.driver.name ~= "farl_player" then
      self.driver.print(msg)
    else
      self:flyingText(msg, RED, true)
    end
  end,

  flyingText = function(self, line, color, show, pos)
    if show then
      local pos = pos or addPos(self.locomotive.position, {x=0,y=-1})
      color = color or RED
      self.surface.create_entity({name="flying-text", position=pos, text=line, color=color})
    end
  end,

  flyingText2 = function(self, line, color, show, pos)
    if show then
      local pos = pos and addPos(pos,{x=-0.5,y=-0.5}) or addPos(self.locomotive.position, {x=0,y=-1})
      color = color or RED
      self.surface.create_entity({name="flying-text2", position=pos, text=line, color=color})
    end
  end,
}

-- [traveldir][rail_type][rail_dir][input] = offset, new rail dir, new rail type
input_to_next_rail =
  -- 0 to 4, 2 to 6: switch sign
  {
    -- North/South
    [0] = {
      ["straight-rail"] = {[0] = {
        [0] = {offset={x=-1,y=-5}, direction=0, type="curved-rail"},
        [1] = {offset={x=0, y=-2}, direction=0, type="straight-rail"},
        [2] = {offset={x=1,y=-5}, direction=1, type="curved-rail"}}
      },
      ["curved-rail"] = {
        [4] = {
          [0] = {offset={x=-2,y=-8}, direction=0, type="curved-rail"},
          [1] = {offset={x=-1,y=-5}, direction=0, type="straight-rail"},
          [2] = {offset={x=0,y=-8}, direction=1, type="curved-rail"}
        },
        [5] = {
          [0] = {offset={x=0,y=-8}, direction=0, type="curved-rail"},
          [1] = {offset={x=1,y=-5}, direction=0, type="straight-rail"},
          [2] = {offset={x=2,y=-8}, direction=1, type="curved-rail"}
        },
      }
    },
    [4] = {
      ["straight-rail"] = {[0] = {
        [0] = {offset={x=1,y=5}, direction=4, type="curved-rail"},
        [1] = {offset={x=0, y=2}, direction=0, type="straight-rail"},
        [2] = {offset={x=-1,y=5}, direction=5, type="curved-rail"}}
      },
      ["curved-rail"] = {
        [0] = {
          [0] = {offset={x=2,y=8}, direction=4, type="curved-rail"},
          [1] = {offset={x=1,y=5}, direction=0, type="straight-rail"},
          [2] = {offset={x=0,y=8}, direction=5, type="curved-rail"}
        },
        [1] = {
          [0] = {offset={x=0,y=8}, direction=4, type="curved-rail"},
          [1] = {offset={x=-1,y=5}, direction=0, type="straight-rail"},
          [2] = {offset={x=-2,y=8}, direction=5, type="curved-rail"}
        },
      }
    },
    -- East/West
    [2] = {
      ["straight-rail"] = {[2]={
        [0] = {offset={x=5,y=-1}, direction=2, type="curved-rail"},
        [1] = {offset={x=2, y=0}, direction=2, type="straight-rail"},
        [2] = {offset={x=5,y=1}, direction=3, type="curved-rail"}}
      },
      ["curved-rail"] = {
        [6] = {
          [0] = {offset={x=8,y=-2}, direction=2, type="curved-rail"},
          [1] = {offset={x=5,y=-1}, direction=2, type="straight-rail"},
          [2] = {offset={x=8,y=0}, direction=3, type="curved-rail"}
        },
        [7] = {
          [0] = {offset={x=8,y=0}, direction=2, type="curved-rail"},
          [1] = {offset={x=5,y=1}, direction=2, type="straight-rail"},
          [2] = {offset={x=8,y=-2}, direction=3, type="curved-rail"}
        }
      }
    },
    [6] = {
      ["straight-rail"] = {[2]={
        [0] = {offset={x=-5,y=1}, direction=6, type="curved-rail"},
        [1] = {offset={x=-2, y=0}, direction=2, type="straight-rail"},
        [2] = {offset={x=-5,y=-1}, direction=7, type="curved-rail"}}
      },
      ["curved-rail"] = {
        [2] = {
          [0] = {offset={x=-8,y=2}, direction=6, type="curved-rail"},
          [1] = {offset={x=-5,y=1}, direction=2, type="straight-rail"},
          [2] = {offset={x=-8,y=0}, direction=7, type="curved-rail"}
        },
        [3] = {
          [0] = {offset={x=-8,y=0}, direction=6, type="curved-rail"},
          [1] = {offset={x=-5,y=-1}, direction=2, type="straight-rail"},
          [2] = {offset={x=-8,y=-2}, direction=7, type="curved-rail"}
        }
      }
    },
    -- NE / SW
    [1] = {
      ["straight-rail"] = {
        [3] = {
          [0] = {offset={x=3,y=-3}, direction=5, type="curved-rail"},
          [1] = {offset={x=2,y=0}, direction=7, type="straight-rail"}
        },
        [7] = {
          [1] = {offset={x=0,y=-2}, direction=3, type="straight-rail"},
          [2] = {offset={x=3,y=-3}, direction=6, type="curved-rail"}
        }
      },
      ["curved-rail"] = {
        [1] = {
          [0] = {offset={x=4,y=-6}, direction=5, type="curved-rail"},
          [1] = {offset={x=3,y=-3}, direction=7, type="straight-rail"},
        },
        [2] = {
          [1] = {offset={x=3,y=-3}, direction=3, type="straight-rail"},
          [2] = {offset={x=6,y=-4}, direction=6, type="curved-rail"}
        }
      }
    },
    [5] = {
      ["straight-rail"] = {
        [3] = {
          [1] = {offset={x=0,y=2}, direction=7, type="straight-rail"},
          [2] = {offset={x=-3,y=3}, direction=2, type="curved-rail"}
        },
        [7] = {
          [0] = {offset={x=-3,y=3}, direction=1, type="curved-rail"},
          [1] = {offset={x=-2,y=0}, direction=3, type="straight-rail"},
        }
      },
      ["curved-rail"] = {
        [5] = {
          [0] = {offset={x=-4,y=6}, direction=1, type="curved-rail"},
          [1] = {offset={x=-3,y=3}, direction=3, type="straight-rail"}
        },
        [6] = {
          [1] = {offset={x=-3,y=3}, direction=7, type="straight-rail"},
          [2] = {offset={x=-6,y=4}, direction=2, type="curved-rail"}
        }
      }
    },
    -- SE / NW
    [3] = {
      ["straight-rail"] = {
        [1] = {
          [1] = {offset={x=2,y=0}, direction=5, type="straight-rail"},
          [2] = {offset={x=3,y=3}, direction=0, type="curved-rail"}
        },
        [5] = {
          [0] = {offset={x=3,y=3}, direction=7, type="curved-rail"},
          [1] = {offset={x=0,y=2}, direction=1, type="straight-rail"},
        }
      },
      ["curved-rail"] = {
        [3] = {
          [0] = {offset={x=6,y=4}, direction=7, type="curved-rail"},
          [1] = {offset={x=3,y=3}, direction=1, type="straight-rail"}
        },
        [4] = {
          [1] = {offset={x=3,y=3}, direction=5, type="straight-rail"},
          [2] = {offset={x=4,y=6}, direction=0, type="curved-rail"}
        }
      }
    },
    [7] = {
      ["straight-rail"] = {
        [1] = {
          [0] = {offset={x=-3,y=-3}, direction=3, type="curved-rail"},
          [1] = {offset={x=0,y=-2}, direction=5, type="straight-rail"}
        },
        [5] = {
          [1] = {offset={x=-2,y=0}, direction=1, type="straight-rail"},
          [2] = {offset={x=-3,y=-3}, direction=4, type="curved-rail"}
        }
      },
      ["curved-rail"] = {
        [0] = {
          [1] = {offset={x=-3,y=-3}, direction=1, type="straight-rail"},
          [2] = {offset={x=-4,y=-6}, direction=4, type="curved-rail"}
        },
        [7] = {
          [0] = {offset={x=-6,y=-4}, direction=3, type="curved-rail"},
          [1] = {offset={x=-3,y=-3}, direction=5, type="straight-rail"}
        }
      }
    },
  }

--clearArea[curveDir%4]
clearAreas =
  {
    [0]={
      {{x=-2.5,y=-3.5},{x=0.5,y=0.5}},
      {{x=-0.5,y=-0.5},{x=2.5,y=3.5}}
    },
    [1]={
      {{x=-2.5,y=-0.5},{x=0.5,y=3.5}},
      {{x=-0.5,y=-3.5},{x=2.5,y=0.5}}
    },
    [2]={
      {{x=-3.5,y=-0.5},{x=0.5,y=2.5}},
      {{x=-0.5,y=-2.5},{x=3.5,y=0.5}}
    },
    [3]={
      {{x=-3.5,y=-2.5},{x=0.5,y=0.5}},
      {{x=-0.5,y=-0.5},{x=3.5,y=2.5}},
    }
  }
