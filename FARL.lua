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
  if not glob.savedBlueprints[player.name] then
    glob.savedBlueprints[player.name] = {}
  end
  if not glob.savedBlueprints[player.name][poleType] then
    glob.savedBlueprints[player.name][poleType] = {straight = {}, diagonal = {}}
  end
  glob.savedBlueprints[player.name][poleType][type] = util.table.deepcopy(bp)
end

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
  new = function(player)
    local new = {
      locomotive = player.vehicle, train=player.vehicle.train,
      driver=player, active=false, lastrail=false,
      direction = false, input = 1, name = player.vehicle.backername,
      signalCount = 0, cruise = false, cruiseInterrupt = 0,
      lastposition = false, maintenance = false
    }
    new.settings = Settings.loadByPlayer(player)
    setmetatable(new, {__index=FARL})
    return new
  end,

  onPlayerEnter = function(player)
    local i = FARL.findByLocomotive(player.vehicle)
    if i then
      glob.farl[i].driver = player
      glob.farl[i].settings = Settings.loadByPlayer(player)
      if glob.farl[i].settings.root == nil then
        glob.farl[i].settings.root = false
      end
    else
      table.insert(glob.farl, FARL.new(player))
    end
  end,

  onPlayerLeave = function(player)
    for i,f in ipairs(glob.farl) do
      if f.driver and f.driver.name == player.name then
        f:deactivate()
        f.driver = false
        f.settings = false
        break
      end
    end
  end,

  findByLocomotive = function(loco)
    for i,f in ipairs(glob.farl) do
      if f.locomotive.equals(loco) then
        return i
      end
    end
    return false
  end,

  findByPlayer = function(player)
    for i,f in ipairs(glob.farl) do
      if f.locomotive.equals(player.vehicle) then
        f.driver = player
        return f
      end
    end
    return false
  end,

  update = function(self, event)
    if self.driver then
      if not self.train.valid then
        if self.locomotive.valid then
          self.train = self.locomotive.train
        else
          self.deactivate("Error (invalid train)")
        end
      else
        self.frontmover = false
        for i,l in ipairs(self.train.locomotives.frontmovers) do
          if l.equals(self.locomotive) then
            self.frontmover = true
            break
          end
        end
        self.cruiseInterrupt = self.driver.ridingstate.acceleration
        if not self.maintenance then
          if self.active then
          --if self.active and self.settings.root then
            local lastWagon = self.frontmover and self.train.carriages[#self.train.carriages].position or self.train.carriages[1].position
            local firstWagon = not self.frontmover and self.train.carriages[#self.train.carriages].position or self.train.carriages[1].position
            local c = #self.path
            local behind = self.path[c].name
            local dist = distance(lastWagon, self.path[c].position)
            while dist > 10 and distance(firstWagon, self.path[c].position) > dist do
            --if dist >= 6 then 
              --flyingText = function(self, line, color, show, pos)
              --self:flyingText("c", RED, true, self.path[c].position)
              if self.path[c].valid and (self.path[c].name == self.settings.rail.curved or self.path[c].name == self.settings.rail.straight) then
                --self:flyingText(#self.path, GREEN,true, self.path[c].position)
                if self.settings.root then
                  self.path[c].destroy()
                  self:addItemToCargo(behind,1)
                end
                table.remove(self.path, c)
                c = #self.path
                dist = distance(lastWagon, self.path[c].position)
              end                  
            end
          end
          self:layRails()
        else
          self:replaceMode()
        end
      end
    end
  end,

  prepareArea = function(self,pos, area)
    if not area then
      area = {{pos.x - 1.5, pos.y - 1.5}, {pos.x + 1.5, pos.y + 1.5}}
    else
      local tl, lr = fixPos(addPos(pos,area[1])), fixPos(addPos(pos,area[2]))
      area = {{tl[1]-1,tl[2]-1},{lr[1]+1,lr[2]+1}}
    end
    self:removeTrees(pos, area)
    self:pickupItems(pos, area)
    self:removeStone(area)
    self:fillWater(area)
  end,

  removeTrees = function(self, pos, area)
    for _, entity in pairs(game.findentitiesfiltered{area = area, type = "tree"}) do
      entity.die()
      if not godmode and self.settings.collectWood then self:addItemToCargo("raw-wood", 1) end
    end
  end,

  removeStone = function(self, area)
    if removeStone then
      for _, entity in pairs(game.findentitiesfiltered{area = area, name = "stone-rock"}) do
        entity.die()
      end
    end
  end,

  fillWater = function(self, area)
    if landfillInstalled then
      -- check if bridging is turned on in settings
      if self.settings.bridge then
        -- following code mostly pulled from landfill mod itself and adjusted to fit
        local tiles = {}
        local st, ft = area[1],area[2]
        for x = st[1], ft[1], 1 do
          for y = st[2], ft[2], 1 do
            local tileName = game.gettile(x, y).name
            -- check that tile is water, if it is add it to a list of tiles to be changed to grass
            if tileName == "water" or tileName == "deepwater" then
              table.insert(tiles,{name="grass", position={x, y}})
            end
          end
        end
        -- check to make sure water tiles were found
        if #tiles ~= 0 then
          -- if they were calculate the minimum number of landfills to fill them in ( quick and dirty at the moment may need tweeking to prevent overusage)
          local lfills = math.ceil(#tiles/4)
          -- check to make sure there is enough landfill in the FARL and if there is apply the changes, remove landfill.  if not then show error message
          if self:getCargoCount("landfill2by2") >= lfills then
            game.settiles(tiles)
            self:removeItemFromCargo("landfill2by2", lfills)
          else
            self:print("Out of 2 by 2 Landfill")
          end
        end
      end
    end
  end,

  pickupItems = function(self,pos, area)
    for _, entity in ipairs(game.findentitiesfiltered{area = area, name="item-on-ground"}) do
      self:addItemToCargo(entity.stack.name, entity.stack.count)
      entity.destroy()
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
            if travelDir == 1 or travelDir == 5 then mul = -1 end
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
        self.driver.ridingstate = {acceleration = acc, direction = self.driver.ridingstate.direction}
      elseif self.active and self.train.speed > limit + 0.1 then
        self.driver.ridingstate = {acceleration = 2, direction = self.driver.ridingstate.direction}
      else
        self.driver.ridingstate = {acceleration = 0, direction = self.driver.ridingstate.direction}
      end
    end
    if not self.cruise then
      self.driver.ridingstate = {acceleration = self.driver.ridingstate.acceleration, direction = self.driver.ridingstate.direction}
    end
  end,

  layRails = function(self)
    self:cruiseControl()
    if self.active and self.lastrail and self.train then
      self.direction = self.direction or self:calcTrainDir()
      self.acc = self.driver.ridingstate.acceleration
      local firstWagon = self.frontmover and self.train.carriages[1] or self.train.carriages[#self.train.carriages]
      if ((self.acc ~= 3 and self.frontmover) or (self.acc ~=1 and not self.frontmover)) and distance(self.lastrail.position, firstWagon.position) < 6 then
        self.input = self.driver.ridingstate.direction
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
            if not last.position and not last.name then 
              error("Placed rail but no entity returned", 2)
            end
            table.insert(self.path, 1, last)
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
          end
        end
        if self.driver.name == "farl_player" and #self.course == 0 then
          self:deactivate("Course done", true)
        end
      end
    end
  end,

  replaceMode = function(self)
    self:cruiseControl()
    if self.active and self.maintenance and self.train then
      self.oldDirection = self.direction or self:calcTrainDir()
      self.direction = self.direction or self:calcTrainDir()
      self.acc = self.driver.ridingstate.acceleration
      local firstWagon = self.frontmover and self.train.carriages[1] or self.train.carriages[#self.train.carriages]
      local currPosition = firstWagon.position
      if ((self.acc ~= 3 and self.frontmover) or (self.acc ~=1 and not self.frontmover)) and distance(self.lastposition, currPosition) < 6
      then
        local railBelow = self:railBelowTrain(true)
        if railBelow then
          local neighbours = self:findNeighbours(railBelow, self.direction)
          if neighbours then
            for i=0,2 do
              if neighbours[i] and neighbours[i].position.x == railBelow.position.x and neighbours[i].position.y == railBelow.position.y then
              --search signal/pole, remove, replace
              end
            end
          end
        end
        -- self:placePole(self.direction, lastrail, self.oldDirection)
        self.lastposition = currPosition
      end
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
        end
      else
        paths[i] = false
      end
    end
    return found and paths or false
  end,

  findRail = function(self, rail)
    local pos = {rail.position.x, rail.position.y}
    local range = 0.4
    local found = false
    local rails = game.findentitiesfiltered{area={{pos[1]-range,pos[2]-range},{pos[1]+range,pos[2]+range}}, name=rail.name}
    for i,r in pairs(rails) do
      if r.position.x == pos[1] and r.position.y == pos[2] and r.direction == rail.direction then
        found = r
        break
      end
    end
    return found
  end,

  activate = function(self)
    self.lastrail = false
    self.signalCount = 0
    self.recheckRails = {}
    self.lastrail = self:findLastRail()
    self.lastCheckIndex = 1
    if self.lastrail then
      self:findLastPole()
      self.direction = self:calcTrainDir()
      if self.direction and self.lastPole then --and self.lastCheckPole then
        local carriages = #self.train.carriages
        local behind, check = self.lastrail, {[1]={[1] = oppositedirection(self.direction), [2] = self.lastrail, [3]=self.lastrail}}
        local lastSignal, signalCount, signalDir = false, -1, signalOffset[self.direction].dir
        local limit = 1
        local path = {self.lastrail}
        while (check and type(check) == "table" and check[1] and check[1][2]) and limit < carriages*7 do
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
            local area = expandPos(signalPos,range)
            for _, entity in pairs(game.findentitiesfiltered{area = area, name = "rail-signal"}) do
              self:flyingText2("S", GREEN, true, entity.position)
              if entity.direction == signalDir then
                lastSignal = entity
                break
              end
            end
          end
          self.signalCount = signalCount
          --self:flyingText("SignalCount: "..self.signalCount, GREEN, true)
          check = self:findNeighbours(check[1][2], check[1][1])
          if check and type(check) == "table" and check[1] and check[1][2] then
            --debugDump(check[1][2],true)
            table.insert(path, check[1][3])
            behind = check[1][2]
          end
          limit = limit + 1
        end
        self:flyingText2("Behind", RED, true, behind.position)
        self.path = path
        if self.settings.root and not self:rootModeAllowed() then
          self.driver.print("-root mode disabled")
          self.driver.print("-root mode requires FARL at each end of the train")
          self.settings.root = false
        end
        self.active = true
      else
        self:print("Error activating, drive on straight rails and try again")
      end
    else
      self:deactivate("Error (no valid rail found)", true)
    end
  end,

  deactivate = function(self, reason, full)
    self.active = false
    self.input = nil
    self.cruise = false
    self.path = nil
    if reason then
      self:print("Deactivated: "..reason)
    end
    self.lastrail = nil
    self.direction = nil
    self.lastPole, self.lastCheckPole = nil,nil
    self.previousDirection, self.lastCheckDir = nil, nil
    self.recheckRails = {}
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
      if self.driver and self.driver.ridingstate then
        self.cruise = true
        local input = self.input or 1
        self.driver.ridingstate = {acceleration = 1, direction = input}
      end
      return
    else
      if self.driver and self.driver.ridingstate then
        self.cruise = false
        local input = self.input or 1
        self.driver.ridingstate = {acceleration = self.driver.ridingstate.acceleration, direction = input}
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
      self.driver.print("-root mode requires FARL at each end of the train")
      self.settings.root = false
    end
  end,
  
  resetPoleData = function(self)
    self.recheckRails = {}
    self.lastPole, self.lastCheckPole = nil,nil
  end,
  
  findLastRail = function(self, limit)
    local trainDir = self:calcTrainDir()
    local test = self:railBelowTrain()
    local last = test
    table.insert(self.recheckRails, {r=last, dir=trainDir, range={0,1}})
    local limit, count = limit, 1
    while test and test.name ~= self.settings.rail.curved do
      local protoDir, protoRail = self:getRail(last, trainDir,1)
      protoRail = protoRail[1] or protoRail
      local rail = self:findRail(protoRail)
      if rail then
        test = rail
        last = rail
        table.insert(self.recheckRails, {r=last, dir=trainDir, range={0,1}})  
      else
        break
      end
      count = count + 1
    end
    if last then
      self:flyingText2("Last", RED, true, last.position)
    end
    return last
  end,

  addItemToCargo = function(self,item, count)
    local count = count or 1
    local wagon = self.train.carriages
    for _, entity in ipairs(wagon) do
      if entity.type == "cargo-wagon" and entity.name ~= "rail-tanker" then
        if entity.getinventory(1).caninsert({name = item, count = count}) then
          entity.getinventory(1).insert({name = item, count = count})
          return
        end
      end
    end
    if self.settings.dropWood or ((item == self.settings.rail.curved or item == self.settings.rail.straight) and not glob.godmode) then
      local position = game.findnoncollidingposition("item-on-ground", self.driver.position, 100, 0.5)
      game.createentity{name = "item-on-ground", position = position, stack = {name = item, count = count}}
    end
  end,

  removeItemFromCargo = function(self,item, count)
    if godmode then return end
    local count = count or 1
    local wagons = self.train.carriages
    for _,entity in ipairs(wagons) do
      if entity.type == "cargo-wagon" and entity.name ~= "rail-tanker" then
        local inv = entity.getinventory(1).getcontents()
        if inv[item] then
          entity.getinventory(1).remove({name=item, count=count})
        end
      end
    end
  end,

  getCargoCount = function(self, item)
    if godmode then return 9001 end
    local c = 0
    for i, wagon in ipairs(self.train.carriages) do
      if wagon.type == "cargo-wagon"  and wagon.name ~= "rail-tanker" then
        c = c + wagon.getinventory(1).getitemcount(item)
      end
    end
    return c
  end,

  genericCanPlace = function(arg)
    if not arg.position or not arg.position.x or not arg.position.y then
      debugDump(arg,true)
      error("invalid position", 2)
    elseif not arg.name then
      error("no name", 2)
    end
    local name = arg.innername or arg.name
    if not arg.direction then
      return game.canplaceentity{name = name, position = arg.position}
    else
      return game.canplaceentity{name = name, position = arg.position, direction = arg.direction}
    end
  end,

  genericPlace = function(arg, ignore)
    local canPlace
    if not ignore then
      canPlace = FARL.genericCanPlace(arg)
    else
      canPlace = true
    end
    local entity
    if canPlace then
      local direction = arg.direction or 0
      local force = arg.force or game.forces.player
      arg.force = force
      local pos = arg.position
      local area = {{pos.x - 0.4, pos.y - 0.4}, {pos.x + 0.4, pos.y + 0.4}}
      for _,ent in pairs(game.findentitiesfiltered{area=area, name="ghost"}) do
        debugDump(ent.name.." "..pos2Str(ent.position),true)
      end
      entity = game.createentity(arg)
    end
    return canPlace, entity
  end,

  parseBlueprints = function(self, bp)
    for j=1,#bp do
      local e = bp[j].getblueprintentities()
      local offsets = {pole=false, poleEntities={}}
      local rail

      for i=1,#e do
        if e[i].name == "straight-rail" or e[i].name == "big-electric-pole" or e[i].name == "medium-electric-pole" then
          if not rail and e[i].name == "straight-rail" then
            rail = {direction = e[i].direction, name = e[i].name, position = e[i].position}
          end
          if e[i].name == "big-electric-pole" or e[i].name == "medium-electric-pole" then
            offsets.pole = {name = e[i].name, direction = e[i].direction, position = e[i].position}
          end
        else
          table.insert(offsets.poleEntities, {name = e[i].name, direction = e[i].direction, position = e[i].position})
        end
      end
      if rail and offsets.pole then
        local type = rail.direction == 0 and "straight" or "diagonal"
        if type == "diagonal" and not (rail.direction == 3 or rail.direction == 7) then
          self:print("Invalid rail")
          break
        end
        local lamps = {}
        for _, l in ipairs(offsets.poleEntities) do
          table.insert(lamps, {name=l.name, position=subPos(l.position, offsets.pole.position)})
        end
        local poleType = offsets.pole.name == "medium-electric-pole" and "medium" or "big"
        local railPos = rail.position
        if type == "diagonal" then
--          local x,y = 0,0
--          if rail.direction == 3 then
--            x = rail.position.x + 0.5
--            y = rail.position.y + 0.5
--          elseif rail.direction == 7 then
--            x = rail.position.x - 0.5
--            y = rail.position.y - 0.5
--          end
          railPos = self:fixDiagonalPos(rail)
          --railPos = {x=x,y=y}
        end
        offsets.pole.position = subPos(offsets.pole.position,railPos)
        local bp = {direction=rail.direction, pole = offsets.pole, poleEntities = lamps}
        self.settings.bp[poleType][type] = bp
        saveBlueprint(self.driver, poleType, type, bp)
        self:print("Saved blueprint for "..type.." rail with "..poleType.. " pole")
      else
        self:print("No rail in blueprint #"..j)
      end
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
  --self:placeRails(self.previousDirection, self.lastrail, self.direction, nextRail, newTravelDir
  placeRails = function(self, lastInDir, lastRail, newInDir, nextRail, newTravelDir)
    if newTravelDir and nextRail.position then
      local newDir = nextRail.direction
      local newPos = nextRail.position
      local newRail = {name = nextRail.name, position = newPos, direction = newDir}
      local canplace = FARL.genericCanPlace(newRail)
      if not canplace then
        self:prepareArea(newPos)
        if not FARL.genericCanPlace(newRail) then
          if nextRail.name == self.settings.rail.curved then
            local areas = clearAreas[nextRail.direction%4]
            for i=1,6 do
              self:prepareArea(newPos, areas[i])
              if FARL.genericCanPlace(newRail) then
                break
              end
            end
          end
        end
      end
      local hasRail = self:getCargoCount(nextRail.name) > 0
      canplace = FARL.genericCanPlace(newRail)
      if canplace and hasRail then
        newRail.force = game.forces.player
        local _, ent = FARL.genericPlace(newRail)
        if self.settings.electric then
          remote.call("dim_trains", "railCreated", newPos)
        end
        self:removeItemFromCargo(nextRail.name, 1)
        return true, ent
      elseif not canplace then
        return false, "Can't place rail"
      elseif not hasRail then
        return false, "Out of rails"
      end
    else
      error("nooo",2)
      return false, "noooo"
    end
    return true, true
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

  fixDiagonalPos = function(self, rail)
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
    end
    return addPos({x=x,y=y}, rail.position)
  end,

  calcPole = function(self,lastrail, traveldir)
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
          local canplace = FARL.genericCanPlace(entity)
          if not canplace then
            self:prepareArea(pos)
          end
          if FARL.genericCanPlace(entity) then
            FARL.genericPlace{name = poleEntities[i].name, position = pos, direction=0,force = game.forces.player}
            self:removeItemFromCargo(poleEntities[i].name, 1)
          end
        end
      end
    end
  end,

  connectCCNet = function(self, pole)
    if self.settings.ccNet and pole.neighbours[1] and self.ccNetPole then
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
            pole.connectneighbour(self.ccNetPole, c[i])
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
    local area = {{tmp.x-reach,tmp.y-reach},{tmp.x+reach,tmp.y+reach}}
    for i,p in pairs(game.findentitiesfiltered{area=area, name=name}) do
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
    if self.settings.minPoles then
      local locomotive = self.locomotive
      local pos = {locomotive.position.x, locomotive.position.y}
      local poles = game.findentitiesfiltered{area={{pos[1]-reach,pos[2]-reach},{pos[1]+reach,pos[2]+reach}}, name=name}
      local checkpos = lastrail and lastrail.position or locomotive.position
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
      if not FARL.genericCanPlace(pole) then
        self:prepareArea(polePos)
      end
      local canPlace = FARL.genericCanPlace(pole)
      local hasPole = self:getCargoCount(name) > 0
      if canPlace and hasPole then
        local success, pole = FARL.genericPlace{name = name, position = polePos, force = game.forces.player}
        if not pole.neighbours[1] then
          self:flyingText("Placed unconnected pole", RED, true)
        end
        self:placePoleEntities(poleDir, polePos)
        self:removeItemFromCargo(name, 1)
        self:connectCCNet(pole)
        self.lastPole = pole

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
        if not hasPole then
          local rails = nextRail or {}
          self.recheckRails = rails
          self:findLastPole()
          self:flyingText({"","Out of ", "",name}, YELLOW, true, addPos(self.locomotive.position, {x=0,y=0}))
          --self:print({"","Out of ","",name})
          debugDump()
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
      local signal = {name = "rail-signal", position = pos, direction = dir, force = game.forces.player}
      if not FARL.genericCanPlace(signal) then
        self:prepareArea(pos)
      end
      local success, entity = FARL.genericPlace(signal)
      if success then
        self:removeItemFromCargo(signal.name, 1)
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
    local locomotive = self.locomotive
    local pos = {locomotive.position.x, locomotive.position.y}
    local poles = game.findentitiesfiltered{area={{pos[1]-reach,pos[2]-reach},{pos[1]+reach,pos[2]+reach}}, name=name}
    local min, pole = 900, nil
    for i=1, #poles do
      local dist = math.abs(distance(locomotive.position,poles[i].position))
      if min > dist then
        pole = poles[i]
        min = dist
      end
    end
    if not pole then
      local trainDir = self:calcTrainDir()
      local lastrail = self.lastrail or self:findLastRail()
      local offset = self:calcPole(lastrail, trainDir)
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
      --self.lastCheckPole = {x=pole.position.x,y=pole.position.y}
    end
  end,

  debugInfo = function(self)
    self.recheckRails = self.recheckRails or {}
    local locomotive = self.locomotive
    local player = self.driver
    --if not self.active then self:activate() end
    player.print("Train@"..pos2Str(locomotive.position).." dir:"..self:calcTrainDir())
    local rail = self:railBelowTrain()
    if rail then
      --self:flyingText2("B", GREEN, true, rail.position)
      player.print("Rail@"..pos2Str(rail.position).." dir:"..rail.direction)
      local fixed = self:fixDiagonalPos(rail)
      if rail.direction % 2 == 1 then
        self:flyingText2("F", GREEN, true, fixed)
        player.print("Fixed: "..pos2Str(fixed).." dir:"..rail.direction)
      end
    else
      player.print("No rail found")
    end
    local last = self:findLastRail()
    if last then
      player.print("Last@"..pos2Str(last.position).." dir:"..last.direction)
    end
    if self.lastpole then
      player.print("Pole@"..pos2Str(self.lastPole))
    end
    -- player.print("LastCheck@"..pos2Str(self.lastCheckPole))
  end,

  calcTrainDir = function(self)
    return math.floor(self.locomotive.orientation * 8)
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
    local locomotive = self.locomotive
    local pos = {locomotive.position.x, locomotive.position.y}
    local trainDir = self:calcTrainDir()
    --debugDump({dir=trainDir,pos=pos},true)
    --self:flyingText("|", RED, true, pos)
    local range = 0.4
    local rails = game.findentitiesfiltered{area={{pos[1]-range,pos[2]-range},{pos[1]+range,pos[2]+range}}, type="rail"}
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
        self:deactivate("Can't start on curves", true) end
    else
      return curves[1]
    end
    return false
  end,

  print = function(self, msg)
    if self.driver.name ~= "farl_player" then
      self.driver.print(msg)
    else
      self:flyingText(msg, RED, true)
    end
  end,

  flyingText = function(self, line, color, show, pos)
    if show then
      local pos = pos or addPos(self.locomotive.position, {x=0,y=-1})
      color = color or RED
      game.createentity({name="flying-text", position=pos, text=line, color=color})
    end
  end,
  
  flyingText2 = function(self, line, color, show, pos)
    if show then
      local pos = addPos(pos,{x=-0.5,y=-0.5}) or addPos(self.locomotive.position, {x=0,y=-1})
      color = color or RED
      game.createentity({name="flying-text2", position=pos, text=line, color=color})
    end
  end,
}
