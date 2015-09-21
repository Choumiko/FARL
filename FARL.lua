require "util"

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

function oppositedirection(direction)
  local opp = util.oppositedirection(direction)
  if not opp then
    if direction == defines.direction.northeast then
      return defines.direction.southwest
    end
    if direction == defines.direction.southeast then
      return defines.direction.northwest
    end
    if direction == defines.direction.southwest then
      return defines.direction.northeast
    end
    if direction == defines.direction.northwest then
      return defines.direction.southeast
    end
  else
    return opp
  end
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

local RED = {r = 0.9}
local GREEN = {g = 0.7}
local YELLOW = {r = 0.8, g = 0.8}
apiCalls = {find=0,canplace=0,create=0,count=0}
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
    if i then
      global.farl[i].driver = player
      global.farl[i].settings = Settings.loadByPlayer(player)
      global.farl[i].destroy = false
    else
      table.insert(global.farl, FARL.new(player))
    end
  end,

  onPlayerLeave = function(player, tick)
    for i,f in ipairs(global.farl) do
      if f.driver and f.driver.name == player.name then
        --debugDump(f.protectedCount,true)
        f:deactivate()
        f.driver = false
        f.destroy = tick
        --f.settings = false
        break
      end
    end
    --debugDump(apiCalls,true)
    apiCalls = {find=0,canplace=0,create=0,count=0}
  end,

  findByLocomotive = function(loco)
    for i,f in ipairs(global.farl) do
      if f.locomotive == loco then
        return i
      end
    end
    return false
  end,

  findByPlayer = function(player)
    for i,f in ipairs(global.farl) do
      if f.locomotive == player.vehicle then
        f.driver = player
        return f
      end
    end
    return false
  end,

  update = function(self, event)
    if self.driver and self.driver.valid then
      if not self.train.valid then
        if self.locomotive.valid then
          self.train = self.locomotive.train
        else
          self.deactivate("Error (invalid train)")
        end
      else
        self.frontmover = false
        for i,l in ipairs(self.train.locomotives.front_movers) do
          if l == self.locomotive then
            self.frontmover = true
            break
          end
        end
        self.cruiseInterrupt = self.driver.riding_state.acceleration
        if self.active then
          local lastWagon = self.frontmover and self.train.carriages[#self.train.carriages].position or self.train.carriages[1].position
          local firstWagon = not self.frontmover and self.train.carriages[#self.train.carriages].position or self.train.carriages[1].position
          if (self.frontmover and self.train.speed >= 0) or (not self.frontmover and self.train.speed <= 0) then
            --debugDump(distance(firstWagon, self.path[1].position),true)
            local c = #self.path
            while not self.path[c].rail.valid do
              table.remove(self.path, c)
              c = #self.path
            end
            local behind = self.path[c].rail.name
            local dist = distance(lastWagon, self.path[c].rail.position)
            while dist > 10 and distance(firstWagon, self.path[c].rail.position) >= dist do
              if c <= 20 then
                break
              else
                if self.path[c].rail.valid and (self.path[c].rail.name == self.settings.rail.curved or self.path[c].rail.name == self.settings.rail.straight) then
                  --self:flyingText(#self.path, GREEN,true, self.path[c].rail.position)
                  if self.settings.root then
                    if self.path[c].rail.destroy() then
                      self:addItemToCargo(behind,1)
                    else
                      self:deactivate({"msg-cant-remove"})
                      return
                    end
                  end
                  table.remove(self.path, c)
                  c = #self.path
                  dist = distance(lastWagon, self.path[c].rail.position)
                end
              end
            end
          end
        end
        self:layRails()
      end
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
    if not self:genericCanPlace(entity) then
      self:fillWater(area)
    end
    return self:genericCanPlace(entity)
  end,

  removeTrees = function(self, area)
    apiCalls.count = apiCalls.count + 1
    if self.surface.count_entities_filtered{area = area, type = "tree"} > 0 then
      apiCalls.find = apiCalls.find + 1
      for _, entity in pairs(self.surface.find_entities_filtered{area = area, type = "tree"}) do
        entity.die()
        if not godmode and self.settings.collectWood then self:addItemToCargo("raw-wood", 1) end
      end
    end
  end,

  removeStone = function(self, area)
    apiCalls.count = apiCalls.count + 1
    if removeStone and self.surface.count_entities_filtered{area = area, name = "stone-rock"} > 0 then
      apiCalls.find = apiCalls.find + 1
      for _, entity in pairs(self.surface.find_entities_filtered{area = area, name = "stone-rock"}) do
        entity.die()
      end
    end
  end,

  -- args = {area=area, name="name"} or {area=area,type="type"}
  -- exclude: table with entities as keys
  removeEntitiesFiltered = function(self, args, exclude)
    apiCalls.count = apiCalls.count + 1
    local exclude = exclude or {}
    if self.surface.count_entities_filtered(args) > 0 then
      apiCalls.find = apiCalls.find + 1
      for _, entity in pairs(self.surface.find_entities_filtered(args)) do
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
    end
  end,

  fillWater = function(self, area)
    -- check if bridging is turned on in settings
    if self.settings.bridge then
      -- following code mostly pulled from landfill mod itself and adjusted to fit
      local tiles = {}
      local st, ft = area[1],area[2]
      local dw, w = 0, 0
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
    end
  end,

  pickupItems = function(self, area)
    apiCalls.count = apiCalls.count + 1
    if self.surface.count_entities_filtered{area = area, name = "item-on-ground"} > 0 then
      apiCalls.find = apiCalls.find + 1
      for _, entity in ipairs(self.surface.find_entities_filtered{area = area, name="item-on-ground"}) do
        self:addItemToCargo(entity.stack.name, entity.stack.count, entity.stack.prototype.place_result)
        entity.destroy()
      end
    end
  end,

  getRail = function(self, lastRail, travelDir, input)
    local lastRail, travelDir, input = lastRail, travelDir, input
    if travelDir > 7 or travelDir < 0 then return false,false end
    if input > 2 or input < 0 then return false, false end
    local data = inputToNewDir[travelDir][input]
    local input2dir = {[0]=-1,[1]=0,[2]=1}
    local newTravelDir = (travelDir + input2dir[input]) % 8
    local name = data.curve and self.settings.rail.curved or self.settings.rail.straight
    local retDir, retRail
    if input == 1 then --straight
      local newDir, pos = data.direction, data.pos
      if travelDir % 2 == 1 then --diagonal travel
        if lastRail.name == self.settings.rail.straight then      --diagonal after diagonal
          if data.direction == lastRail.direction then
            local mul = 1
            if travelDir == 1 or travelDir == 5 then
              mul = -1
            end
            newDir = (data.direction+4) % 8
            pos = {x=data.pos.y*mul, y=data.pos.x*mul}
        end
        pos = addPos(lastRail.position, pos)
      elseif lastRail.name == self.settings.rail.curved then --diagonal after curve
        pos = addPos(lastRail.position, data.connect.pos)
        newDir = data.connect.direction[lastRail.direction]
      end
      else -- N/E/S/W travel
        if lastRail.name == self.settings.rail.curved then --straight after curve
          pos = data.shift[lastRail.direction]
      end
      pos = addPos(lastRail.position, pos)
      end
      retDir, retRail = newTravelDir, {name=name, position=pos, direction=newDir}
    end
    if input ~= 1 then --left or right
      local s = "Changing direction from "..travelDir.." to "..newTravelDir
      if travelDir % 2 == 0 and lastRail.name == self.settings.rail.straight then --curve after N/S, E/W tracks
        local pos = addPos(lastRail.position,data.pos)
        retDir, retRail = newTravelDir, {name=name, position=pos, direction=data.direction}
      elseif travelDir % 2 == 1 and lastRail.name == self.settings.rail.straight then --curve after diagonal
        local pos = {x=0,y=0}
        local last = lastRail
        if lastRail.direction ~= data.lastDir then -- need extra diagonal rail to connect
          local testD, testR = self:getRail(lastRail,travelDir,1)
          local d2, r2 = self:getRail(testR,testD,input)
          retDir = {testD, d2}
          retRail = {testR, r2}
        else
          pos = addPos(lastRail.position, data.pos)
          retDir, retRail = newTravelDir, {name=name, position=pos, direction=data.direction}
        end
      elseif lastRail.name == self.settings.rail.curved and name == self.settings.rail.curved then
        local pos
        if not data.curve[lastRail.direction] then error("maintenance1", 4) end
        if not data.curve[lastRail.direction].diag then -- curves connect directly
          pos = addPos(lastRail.position, data.curve[lastRail.direction].pos)
          retDir, retRail = newTravelDir, {name=name, position=pos, direction=data.direction}
        else
          local testD, testR = self:getRail(lastRail,travelDir,1)
          local d2, r2 = self:getRail(testR,testD,input)
          retDir = {testD, d2}
          retRail = {testR, r2}
        end
      end
    end
    return retDir, retRail
  end,

  cruiseControl = function(self)
    local acc = self.frontmover and defines.riding.acceleration.accelerating or defines.riding.acceleration.reversing
    if self.cruise then
      local limit = self.active and self.settings.cruiseSpeed or 0.9
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

  layRails = function(self)
    self:cruiseControl()
    if self.active and self.lastrail and self.train then
      self.direction = self.direction or self:calcTrainDir()
      self.acc = self.driver.riding_state.acceleration
      local firstWagon = self.frontmover and self.train.carriages[1] or self.train.carriages[#self.train.carriages]
      if ((self.acc ~= 3 and self.frontmover) or (self.acc ~=1 and not self.frontmover)) and distance(self.lastrail.position, firstWagon.position) < 6 then
        --debugDump(#self.path, true)
        --self:flyingText2("L", RED, true, self.lastrail.position)
        if type(self.path == "table") and self.path[1] then
        --self:flyingText2("B", RED, true, self.path[#self.path].rail.position)
        end
        self.input = self.driver.riding_state.direction
        if self.driver.name == "farl_player" then
          if self.course and self.course[1] then
            local diff = subPos(self.lastrail.position, self.course[1].pos)
            if diff.x == 0 and diff.y == 0 then
              self.input = self.course[1].input
              table.remove(self.course, 1)
            end
          end
        end
        local count = (self.input == 1 and self.direction%2==1) and 1 or 1
        local newTravelDirs, nextRails = self:getRail(self.lastrail,self.direction, self.input)
        if type(newTravelDirs) == "number" then
          newTravelDirs = {newTravelDirs}
          nextRails = {nextRails}
        end
        self.previousDirection = self.previousDirection or self.direction
        for i=1, #newTravelDirs do
          local nextRail = nextRails[i]
          local newTravelDir = newTravelDirs[i]
          local dir, last = self:placeRails(self.previousDirection, self.lastrail, self.direction, nextRail, newTravelDir)
          if dir then
            if self.maintenance and type(dir) == "number" then
              newTravelDir = dir
              nextRail = last
            end
            if not last.position and not last.name then
              self:deactivate({"msg-no-entity"})
              return
            end
            if self.active then
              table.insert(self.path, 1, {rail = last, traveldir = newTravelDir})
            else
              return
            end
            self:protect(last)
            if self.settings.poles then
              if self:getCargoCount("big-electric-pole") > 0 or self:getCargoCount("medium-electric-pole") > 0 then
                local poleRails = self:getPoleRails(self.lastrail, self.previousDirection, self.direction)
                local nextPoleRails = self:getPoleRails(nextRail, newTravelDir, self.direction)
                local placed, foundBest = self:placePole(poleRails, nextPoleRails)
              end
            end
            if self.settings.signals and not self.settings.root then
              local signalWeight = nextRail.name == self.settings.rail.curved and self.settings.curvedWeight or 1
              self.signalCount = self.signalCount + signalWeight
              --self:print(self.signalCount)
              if self:getCargoCount("rail-signal") > 0 then
                if self:placeSignal(newTravelDir,nextRail) then self.signalCount = 0 end
              else
                self:flyingText({"", "Out of ","rail-signal"}, YELLOW, true)
              end
            end
            self.previousDirection = self.direction
            self.direction, self.lastrail = newTravelDir, nextRail
          else
            self:deactivate(last)
            return
          end
        end
        if self.driver.name == "farl_player" and #self.course == 0 then
          self:deactivate("Course done", true)
        end
      end
    end
  end,

  --  replaceMode = function(self)
  --    self:cruiseControl()
  --    if self.active and self.maintenance and self.train then
  --      self.oldDirection = self.direction or self:calcTrainDir()
  --      self.direction = self.direction or self:calcTrainDir()
  --      self.acc = self.driver.riding_state.acceleration
  --      local firstWagon = self.frontmover and self.train.carriages[1] or self.train.carriages[#self.train.carriages]
  --      local currPosition = firstWagon.position
  --      if ((self.acc ~= 3 and self.frontmover) or (self.acc ~=1 and not self.frontmover)) and distance(self.lastposition, currPosition) < 6
  --      then
  --        local railBelow = self:railBelowTrain(true)
  --        if railBelow then
  --          local neighbours = self:findNeighbours(railBelow, self.direction)
  --          if neighbours then
  --            for i=0,2 do
  --              if neighbours[i] and neighbours[i].position.x == railBelow.position.x and neighbours[i].position.y == railBelow.position.y then
  --              --search signal/pole, remove, replace
  --              end
  --            end
  --          end
  --        end
  --        -- self:placePole(self.direction, lastrail, self.oldDirection)
  --        self.lastposition = currPosition
  --      end
  --    end
  --  end,

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
    if type(newTravel) == "number" then
      local railEnt = self:findRail(nrail)
      if railEnt then
        neighbour = {newTravel, nrail, railEnt}
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
      local maintenance = self.maintenance and 10 or false
      self.lastrail = self:findLastRail(maintenance)
      self.lastCheckIndex = 1
      if self.lastrail then
        self:findLastPole()
        self.direction = self:calcTrainDir()
        if self.direction and self.lastPole then --and self.lastCheckPole then
          local carriages = #self.train.carriages
          local behind, check = self.lastrail, {[1]={[1] = oppositedirection(self.direction), [2] = self.lastrail, [3]=self.lastrail}}
          local lastSignal, signalCount, signalDir = false, -1, signalOffset[self.direction].dir
          local limit = 1
          local path = {{rail = self.lastrail, traveldir = self.direction}}
          self:protect(self.lastrail)
          while (check and type(check) == "table" and check[1] and check[1][2])
            and ((not self.maintenance and limit < carriages*7) or (self.maintenance and limit < math.max(16,carriages*7))) do
            if not lastSignal then
              signalCount = signalCount + 1
              local signalOffset = signalOffset[self.direction]
              if self.direction % 2 == 1 then
                signalOffset = signalOffset[check[1][3].direction]
              else
                signalOffset = signalOffset.pos
              end
              local signalPos = addPos(check[1][3].position, signalOffset)
              --self:flyingText2("s",RED,true,signalPos)
              local range = (self.direction % 2 == 0) and 1 or 0.5
              for _, entity in pairs(self.surface.find_entities_filtered{area = expandPos(signalPos,range), name = "rail-signal"}) do
                if entity.direction == signalDir then
                  lastSignal = entity
                  break
                end
              end
              if not lastSignal then
                for _, entity in pairs(self.surface.find_entities_filtered{area = expandPos(signalPos,range), name = "rail-chain-signal"}) do
                  self:flyingText2("S", GREEN, true, entity.position)
                  if entity.direction == signalDir then
                    lastSignal = entity
                    break
                  end
                end
              end
            end
            self.signalCount = signalCount
            --self:print("SignalCount: "..self.signalCount, GREEN, true)
            check = self:findNeighbours(check[1][2], check[1][1])
            if check and type(check) == "table" and check[1] and check[1][2] then
              --debugDump(check[1][2],true)
              table.insert(path, {rail=check[1][3], traveldir=(check[1][1]+4)%8})
              self:protect(check[1][3])

              behind = check[1][2]
            end
            limit = limit + 1
          end
          if lastSignal and lastSignal.valid then
            self:flyingText2("S", GREEN, true, lastSignal.position)
            if self.maintenance then
              self:protect(lastSignal)
            end
          end
          self:flyingText2( {"text-behind"}, RED, true, behind.position)
          self.path = path
          self.lastCurve = #self.path
          if self.maintenance and type(self.path) == "table" and #self.path >= 10 then
            local lag = 8
            self.maintenanceRail = self.path[1].rail
            self.maintenanceDir = self.path[1].traveldir
            self.lastrail = self.path[lag].rail
            --self.direction = (self.path[lag].traveldir +4) % 8
            self.direction = self.path[lag].traveldir
            self:protect(self.lastPole)
            self:flyingText2( "L", RED, true, self.lastrail.position)
          else
            if self.maintenance then
              self:deactivate("No path for maintenance found")
              self.maintenanceRail = nil
              self.maintenanceDir = nil
              self.protected = {}
              self.active = false
            end
          end
          if self.settings.root and not self:rootModeAllowed() then
            self:print({"msg-root-disabled"})
            self:print({"msg-root-error"})
            self.settings.root = false
          end
          self.active = true
        else
          self:print({"msg-error-activating"})
        end
      else
        self:deactivate({"msg-error-2"}, true)
      end
    end)
    if not status then
      self:deactivate({"", {"msg-error-activating"}, err})
    end
  end,

  deactivate = function(self, reason, full)
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
    self.ccNetPole = nil
    self.previousDirection, self.lastCheckDir = nil, nil
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
      self.settings.root = not self.settings.root
    else
      self:print({"msg-root-error"})
      self.settings.root = false
    end
  end,

  toggleMaintenance = function(self)
    if self.active then
      self:deactivate("Changing modes")
    end
    self.maintenance = not self.maintenance
  end,

  resetPoleData = function(self)
    self.recheckRails = {}
    self.lastPole, self.lastCheckPole = nil,nil
  end,

  findLastRail = function(self, limit)
    local trainDir = self:calcTrainDir()
    local test = self:railBelowTrain()
    local last = test
    self.recheckRails = self.recheckRails or {}
    table.insert(self.recheckRails, {r=last, dir=trainDir, range={0,1}})
    local limit, count = limit, 1
    if not limit then limit = 5 end
    while test and test.name ~= self.settings.rail.curved do
      local protoDir, protoRail = self:getRail(last, trainDir,1)
      protoRail = protoRail[1] or protoRail
      local rail = self:findRail(protoRail)
      if rail and (not self.maintenance or (self.maintenance and count < limit)) then
        test = rail
        last = rail
        table.insert(self.recheckRails, {r=last, dir=trainDir, range={0,1}})
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
    local wagon = self.train.carriages
    for _, entity in ipairs(wagon) do
      if entity.type == "cargo-wagon" and entity.name ~= "rail-tanker" then
        if entity.get_inventory(1).can_insert({name = item, count = count}) then
          entity.get_inventory(1).insert({name = item, count = count})
          return
        end
      end
    end
    if self.settings.dropWood or place_result then
      local position = self.surface.find_non_colliding_position("item-on-ground", self.driver.position, 100, 0.5)
      self.surface.create_entity{name = "item-on-ground", position = position, stack = {name = item, count = count}}
    end
  end,

  removeItemFromCargo = function(self,item, count)
    if godmode then return end
    local count = count or 1
    local wagons = self.train.carriages
    for _,entity in ipairs(wagons) do
      if entity.type == "cargo-wagon" and entity.name ~= "rail-tanker" then
        local inv = entity.get_inventory(1).get_contents()
        if inv[item] then
          entity.get_inventory(1).remove({name=item, count=count})
        end
      end
    end
  end,

  getCargoCount = function(self, item)
    if godmode then return 9001 end
    local c = 0
    for i, wagon in ipairs(self.train.carriages) do
      if wagon.type == "cargo-wagon"  and wagon.name ~= "rail-tanker" then
        c = c + wagon.get_inventory(1).get_item_count(item)
      end
    end
    return c
  end,

  genericCanPlace = function(self, arg)
    if not arg.position or not arg.position.x or not arg.position.y then
      error("invalid position", 2)
    elseif not arg.name then
      error("no name", 2)
    end
    local name = arg.innername or arg.name
    apiCalls.canplace = apiCalls.canplace + 1
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
      apiCalls.create = apiCalls.create + 1
    end
    return canPlace, entity
  end,

  --parese blueprints
  -- chain signal: needs direction == 4, defines track that FARL drives on
  --normal signals: define signal position for other tracks
  parseBlueprints2 = function(self, bp)
    for j=1,#bp do
      local vertSignal = signalOffset[0]
      local diagSignal = signalOffset[1]
      local e = bp[j].get_blueprint_entities()
      local offsets = {pole=false, chain=false, poleEntities={}, rails={}, signals={}}
      local bpType = false
      local rails = 0
      for i=1,#e do
        if e[i].name == "straight-rail" then
          rails = rails + 1
        end
      end
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
        for i,rail in pairs(offsets.rails) do
          local traveldir = (bpType == "straight") and 0 or 1
          local signalOff = signalOffset[traveldir]
          local signalDir = signalOff.dir
          signalOff = (traveldir == 0) and signalOff.pos or signalOff[rail.direction]
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
            end
            offsets.mainRail = rail
          end
        end
        if mainRail then
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

          local bp = {mainRail = mainRail, direction=mainRail.direction, pole = offsets.pole, poleEntities = lamps, rails = rails, signals = signals}
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
          self:parseBlueprint(e)
        elseif not bpType then
          self:print({"msg-bp-rail-direction"})
        elseif not offsets.chain then
          self:print({"msg-bp-chain-missing"})
        else --if not offsets.pole then
          self:print({"msg-bp-pole-missing"})
        end
      end
    end
  end,

  parseBlueprint = function(self, bpEntities)
    local e = bpEntities
    local offsets = {pole=false, poleEntities={}}
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

  createJunction = function(self, input)
    self:activate()
    self.last = self:findLastRail(3)
    local dir, last = self:placeRails(self.last, self.direction, input)
    if dir and last == "extra" and self.active then
      dir, last = self:placeRails(self.lastrail, self.direction, 1)
      if dir and last then
        dir, last = self:placeRails(last, dir, input)
      end
    end
    if dir then
      self.direction, self.lastrail = dir, last
    else
      self:print("Couldn't create junction")
    end
  end,

  placeRails = function(self, lastInDir, lastRail, newInDir, nextRail, newTravelDir)
    if newTravelDir and nextRail.position then
      local newDir = nextRail.direction
      local newPos = nextRail.position
      local newRail = {name = nextRail.name, position = newPos, direction = newDir}
      if not self.maintenance then
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
              if self.settings.parallelTracks and self.lastCurve > self.settings.parallelLag and not self.settings.root then
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
        --maintenance mode
      else
        local ent = self:findRail(newRail)
        local retDir, retEnt
        if ent then
          if ent.name ~= self.settings.rail.curved then
            self.lastCurve = self.lastCurve + 1
            if self.settings.parallelTracks and self.lastCurve > self.settings.parallelLag and not self.settings.root then
              self:placeParallelTracks(newTravelDir, ent)
            end
          else
            self.lastCurve = 0
          end
          retDir = true
          retEnt = ent
        else
          local paths = self:findNeighbours(lastRail, self.previousDirection)
          --debugDump(paths,true)
          --saveVar(paths)
          if paths then
            for i=0,2 do
              local path = paths[i]
              if type(path) == "table" then
                if path[3].name ~= self.settings.rail.curved then
                  self.lastCurve = self.lastCurve + 1
                  if self.settings.parallelTracks and self.lastCurve > self.settings.parallelLag and not self.settings.root then
                    self:placeParallelTracks(path[1], path[3])
                  end
                else
                  self.lastCurve = 0
                end
                retDir = path[1]
                retEnt = path[3]
                break
              end
            end
          end
        end

        local tmp = self:findNextMaintenanceRail()
        if tmp then
          self:prepareMaintenance(self.maintenanceDir, self.maintenanceRail)
        else
          retDir = false
        end
        if retDir then
          return retDir, retEnt
        else
          return false, "Maintenance end"
        end
      end
    else
      error("nooo",2)
      return false, "noooo"
    end
    return true, true
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
        debugDump(self.protectedCount,true)
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
        debugDump(self.protectedCount,true)
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

      local types = {"rail", "rail-signal", "rail-chain-signal", "electric-pole", "lamp"}
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
      if type(lastrail)~="table" then error("no table", 2) end
      if not lastrail.name then error("calcPole: no name", 2) end
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
      else
        error("calcPole called with curved", 2)
      end
      return offset
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
      debugDump({dist=dist, minPos=minPos, p=p.position},true)
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
    local min, max = 100, -1
    local minPole, maxPole, maxIndex
    local points = {}
    if not rails then error("no rail",2) end
    if type(rails)~="table" then error("no table3", 3)end
    if not lastPole then error("nil pole", 3) end
    for j, rail in pairs(rails) do
      local polePoints = self:getPolePoints(rail)
      for i,pole in pairs(polePoints) do
        local pos = {x=pole.pos[1],y=pole.pos[2]}
        --if foo then self:flyingText(foo, RED, true, pos) end
        local dist = distance(lastPole.position, pos)
        table.insert(points, {d=dist, p=pos, dir=pole.dir})
        if dist >= max and dist <= reach then
          max = dist
          maxIndex = j
          maxPole =  {d=dist,p=pos, dir=pole.dir}
        end
      end
    end
    return maxPole, maxIndex
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

  placePole = function(self, lastrail, nextRail)
    local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
    local reach = self.settings.medium and 9+1 or 30+1
    if self.settings.minPoles and self.lastPole.valid and (not self.settings.ccNet and not self.maintenance) then
      local poles = self.surface.find_entities_filtered{area=expandPos(self.locomotive.position,reach), name=name}
      local checkpos = lastrail and lastrail.position or self.locomotive.position
      local min, pole = math.abs(distance(self.lastPole.position, checkpos)), nil
      for i=1, #poles do
        local dist = math.abs(distance(checkpos,poles[i].position))
        if min > dist then
          pole = poles[i]
          min = dist
        end
      end
      if pole then
        self.lastPole = pole
      end
    end
    local rails = lastrail -- {{r=lastrail, dir=traveldir}}
    local polePos, poleDir, bestPole, index
    local lastPole = self.lastPole
    if not self.recheckRails then self.recheckRails = {} end
    for i,r in pairs(lastrail) do
      table.insert(self.recheckRails, r)
    end
    bestPole, index = self:getBestPole(lastPole, self.recheckRails, ".")
    if bestPole then
      self.lastCheckPole = bestPole.p
      self.lastCheckDir = bestPole.dir
      self.lastCheckIndex = index
      index = index > 1 and index-1 or 1
      for i=index,1,-1 do
        table.remove(self.recheckRails, i)
      end
      --self:flyingText("B", GREEN, true, self.lastCheckPole)
      return false, index
    else
      polePos = self.lastCheckPole
      poleDir = self.lastCheckDir

      local diff = subPos(self.lastPole.position, polePos)
      if diff.x == 0 and diff.y == 0 then
      --debugDump("Placing on last pole!",true)
      --self:deactivate()
      --return
      end
      local pole = {name = name, position = polePos}
      --debugDump(util.distance(pole.position, self.lastPole.position),true)
      local canPlace = self:prepareArea(pole)
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
          bestPole, index = self:getBestPole(pole, self.recheckRails, "O")
          if bestPole then
            self.lastCheckPole = bestPole.p
            self.lastCheckDir = bestPole.dir
            for i=self.lastCheckIndex,1,-1 do
              table.remove(self.recheckRails, i)
            end
            self.lastCheckIndex = index
            --self:flyingText("B", YELLOW, true, self.lastCheckPole)
          else
            debugDump("not found",true)
            if nextRail then
              self:placePole(nextRail)
            end
          end
          return true, index
        else
          debugDump("Can`t place pole@"..pos2Str(polePos),true)
          local rails = nextRail or {}
          self.recheckRails = rails
          self:findLastPole()
        end
      else
        if not hasPole then
          local rails = nextRail or {}
          self.recheckRails = rails
          self:findLastPole()
          self:flyingText({"","Out of ", "",name}, YELLOW, true, addPos(self.locomotive.position, {x=0,y=0}))
          --self:print({"","Out of ","",name})
        end
        if not canPlace then
          debugDump("Can`t place pole@"..pos2Str(polePos),true)
          local rails = nextRail or {}
          self.recheckRails = rails
          self:findLastPole()
        end
      end
    end
  end,

  placeSignal = function(self,traveldir, rail)
    if self.signalCount > self.settings.signalDistance and rail.name ~= self.settings.rail.curved then
      local rail = rail
      local data = signalOffset[traveldir]
      local offset = data[rail.direction] or data.pos
      local dir = data.dir
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

  findLastPole = function(self)
    local name = self.settings.medium and "medium-electric-pole" or "big-electric-pole"
    local reach = self.settings.medium and 9 or 30
    local poles = self.surface.find_entities_filtered{area=expandPos(self.locomotive.position, reach), name=name}
    local min, pole = 900, nil
    for i=1, #poles do
      local dist = math.abs(distance(self.locomotive.position,poles[i].position))
      if min > dist then
        pole = poles[i]
        min = dist
      end
    end
    local lastrail = self.lastrail or self:findLastRail()
    local trainDir = self:calcTrainDir()
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
      self.lastCheckIndex = 1
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
    end
  end,

  debugInfo = function(self)
    self.recheckRails = self.recheckRails or {}
    local locomotive = self.locomotive
    local player = self.driver
    --if not self.active then self:activate() end
    self:print("Train@"..pos2Str(locomotive.position).." dir:"..self:calcTrainDir().." orient:"..locomotive.orientation)
    self:print("calcDir: "..self.locomotive.orientation * 8)
    local rail = self:railBelowTrain()
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

  --    curve  traindirs
  --        0   3   7
  --        1   0   4
  --        2   1   5
  --        3   2   6
  --        4   3   7
  --        5   0   4
  --        6   1   5
  --        7   2   6
  railBelowTrain = function(self, ignore)
    local trainDir = self:calcTrainDir()
    --debugDump({dir=trainDir,pos=pos},true)
    --self:flyingText("|", RED, true, pos)
    local rails = self.surface.find_entities_filtered{area=expandPos(self.locomotive.position, 0.4), type="rail"}
    local curves ={}
    --debugDump(#rails,true)
    for i=1, #rails do
      if rails[i].name == self.settings.rail.curved then
        table.insert(curves, rails[i])
      else
        if trainDir % 2 == 0 then
          if rails[i].direction == trainDir or (rails[i].direction + 4) % 8 == trainDir then
            --self:flyingText(".", RED, true, rails[i].position)
            return rails[i]
          end
        else
          local dir = (trainDir+2)%8
          if rails[i].direction == dir or rails[i].direction == (dir+4)%8 then
            --self:flyingText(".", RED, true, rails[i].position)
            return rails[i]
          end
        end
      end
    end
    if curves[1] then
      if not ignore then
        self:deactivate({"msg-error-curves"}, true) end
    else
      return curves[1]
    end
    return false
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
