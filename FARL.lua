require "util"

function addPos(p1,p2)
  local p2 = p2 or {x=0,y=0}
  return {x=p1.x+p2.x, y=p1.y+p2.y}
end

function subPos(p1,p2)
  local p2 = p2 or {x=0,y=0}
  return {x=p1.x-p2.x, y=p1.y-p2.y}
end

function pos2Str(pos)
  return util.positiontostr(pos)
end

function fixPos(pos)
  local ret = {}
  if pos.x then ret[1] = pos.x end
  if pos.y then ret[2] = pos.y end
  return ret
end

FARL = {
  new = function(index, player)
    local new = {
      locomotive = player.vehicle, train=player.vehicle.train,
      driver=player, index = index, active=false, lastrail=false,
      direction = false, input = 1, name = player.vehicle.backername,
      signalCount = 0, cruise = false, cruiseInterrupt = 0
    }
    setmetatable(new, {__index=FARL})
    if not FARL.findByPlayer(player) then
      table.insert(glob.farl, new)
    end
    return new
  end,

  remove = function(index, player)
    for i,f in ipairs(glob.farl) do
      if f.driver.name == player.name then
        glob.farl[i] = nil
        break
      end
    end
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
    if not self.train.valid then
      self.train = self.locomotive.train
      if self.train.valid then
        self:updateCargo()
      else
        self.driver.print("Invalid train")
        self.deactivate()
      end
    else
      if event.tick % 60 == 0 then
        self:updateCargo()
      end
      self.cruiseInterrupt = self.driver.ridingstate.acceleration
      self:layRails()
    end
  end,

  removeTrees = function(self,pos, area)
    if not area then
      area = {{pos.x - 1.5, pos.y - 1.5}, {pos.x + 1.5, pos.y + 1.5}}
    else
      local tl, lr = fixPos(addPos(pos,area[1])), fixPos(addPos(pos,area[2]))
      area = {{tl[1]-1,tl[2]-1},{lr[1]+1,lr[2]+1}}
    end

    for _, entity in ipairs(game.findentitiesfiltered{area = area, type = "tree"}) do
      entity.die()
      if not godmode then self:addItemToCargo("raw-wood", 1) end
    end
    self:pickupItems(pos, area)
    if removeStone then
      for _, entity in ipairs(game.findentitiesfiltered{area = area, name = "stone-rock"}) do
        entity.die()
      end
    end
  end,

  pickupItems = function(self,pos, area)
    for _, entity in ipairs(game.findentitiesfiltered{area = area, name="item-on-ground"}) do
      self:addItemToCargo(entity.stack.name, entity.stack.count)
      entity.destroy()
    end
  end,

  getRail = function(self,lastRail, travelDir, input)
    local lastRail, travelDir, input = lastRail, travelDir, input
    if travelDir > 7 or travelDir < 0 then return false,false end
    if input > 2 or input < 0 then return false, false end
    local data = inputToNewDir[travelDir][input]
    local input2dir = {[0]=-1,[1]=0,[2]=1}
    local newTravelDir = (travelDir + input2dir[input]) % 8
    local name = data.curve and "curved-rail" or "straight-rail"
    if input ~= 1 then --left or right
      local s = "Changing direction from "..travelDir.." to "..newTravelDir
      if travelDir % 2 == 0 and lastRail.name == "straight-rail" then --curve after N/S, E/W tracks
        local pos = addPos(lastRail.position,data.pos)
        return newTravelDir, {name=name, position=pos, direction=data.direction}
      elseif travelDir % 2 == 1 and lastRail.name == "straight-rail" then --curve after diagonal
        local pos = {x=0,y=0}
        local last = lastRail
        if lastRail.direction ~= data.lastDir then -- need extra diagonal rail to connect
          return false, "extra"
        else
          pos = addPos(lastRail.position, data.pos)
          return newTravelDir, {name=name, position=pos, direction=data.direction}
        end
      elseif lastRail.name == "curved-rail" and name == "curved-rail" then
        local pos
        if not data.curve[lastRail.direction].diag then -- curves connect directly
          pos = addPos(lastRail.position, data.curve[lastRail.direction].pos)
          return newTravelDir, {name=name, position=pos, direction=data.direction}
        else
          return false, "extra"
        end
      end
    elseif input == 1 then --straight
      if travelDir % 2 == 1 then --diagonal travel
        local newDir, pos = data.direction, data.pos
        if lastRail.name == "straight-rail" then      --diagonal after diagonal
          if data.direction == lastRail.direction then
            local mul = 1
            if travelDir == 1 or travelDir == 5 then mul = -1 end
            newDir = (data.direction+4) % 8
            pos = {x=data.pos.y*mul, y=data.pos.x*mul}
        end
        pos = addPos(lastRail.position, pos)
        return newTravelDir, {name=name, position=pos, direction=newDir}
        elseif lastRail.name == "curved-rail" then --diagonal after curve
          pos = addPos(lastRail.position, data.connect.pos)
          newDir = data.connect.direction[lastRail.direction]
          return newTravelDir, {name=name, position=pos, direction=newDir}
        end
    else -- N/E/S/W travel
      local pos = data.pos
      local shift = ""
      if lastRail.name == "curved-rail" then --straight after curve
        pos = data.shift[lastRail.direction]
        shift = pos2Str(data.shift[lastRail.direction])
      end
      pos = addPos(lastRail.position, pos)
      return newTravelDir, {name=name, position=pos, direction=data.direction}
    end
    end
  end,

  cruiseControl = function(self)
    if self.cruise then
      local limit = self.active and glob.cruiseSpeed or 0.9
      if self.cruiseInterrupt == 2 then
        self:toggleCruiseControl()
        return
      end
      if self.train.speed < limit then
        self.driver.ridingstate = {acceleration = 1, direction = self.driver.ridingstate.direction}
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
      if self.acc ~= 3 and util.distance(self.lastrail.position, self.locomotive.position) < 6 then
        self.input = self.driver.ridingstate.direction
        local count = (self.input == 1 and self.direction%2==1) and 1 or 1
        local dir, last = self:placeRails(self.lastrail, self.direction, self.input, count)
        if dir and last == "extra" and self.active then
          dir, last = self:placeRails(self.lastrail, self.direction, 1)
          if dir and last then
            dir, last = self:placeRails(last, dir, self.input)
          end
        end
        if dir then
          self.direction, self.lastrail = dir, last
        else
          self:deactivate()
          self.driver.print("Deactivated")
        end
      end
    end
  end,

  activate = function(self)
    self.lastrail = self:findLastRail()
    if self.lastrail then
      self:findLastPole()
      self:updateCargo()
      self.direction = self:calcTrainDir()
      if self.direction and self.lastPole and self.lastCheckPole then
        self.active = true
      else
        self.driver.print("Error activating, drive on straight rails and try again")
      end
    else
      self:deactivate()
    end
  end,

  deactivate = function(self)
    self.active = false
    self.input = nil
    self.lastrail = nil
    self.direction = nil
    self.lastPole, self.lastCheckPole = nil,nil
    self.cruise = false
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

  findLastRail = function(self)
    local trainDir = self:calcTrainDir()
    local test = self:railBelowTrain()
    local limit = 10
    local last = test
    while test and test.name ~= "curved-rail" do
      last = test
      local _, next = self:getRail(last,trainDir,1)
      local pos = fixPos(next.position)
      local area = {{pos[1]-0.4,pos[2]-0.4},{pos[1]+0.4,pos[2]+0.4}}
      local found = false
      for i,rail in ipairs(game.findentitiesfiltered{area=area, name="straight-rail"}) do
        local dirMatch = false
        if trainDir % 2 == 0 then
          dirMatch = rail.direction == trainDir or rail.direction+4%8 == trainDir
        else
          local dir = (trainDir+2)%8
          dirMatch = rail.direction == dir or rail.direction == (dir+4) % 8
        end
        if dirMatch then
          test = rail
          found = true
          break
        end
      end
      if not found then return last end
    end
    if last.name == "curved-rail" then
      self.driver.print("Can't start on curved rails")
      return false
    end
    return last
  end,

  addItemToCargo = function(self,item, count)
    local count = count or 1
    local wagon = self.train.carriages
    for _, entity in ipairs(wagon) do
      if entity.name == "cargo-wagon" then
        if entity.getinventory(1).caninsert({name = item, count = count}) then
          entity.getinventory(1).insert({name = item, count = count})
          return
        end
      end
    end
    local position = game.findnoncollidingposition("item-on-ground", self.driver.position, 100, 0.5)
    game.createentity{name = "item-on-ground", position = position, stack = {name = item, count = count}}
  end,

  removeItemFromCargo = function(self,item, count)
    if godmode then return end
    local count = count or 1
    local wagons = self.train.carriages
    for _,entity in ipairs(wagons) do
      if entity.name == "cargo-wagon" then
        local inv = entity.getinventory(1).getcontents()
        if inv[item] then
          entity.getinventory(1).remove({name=item, count=count})
        end
      end
    end
    if self[item] and self[item] >= count then self[item] = self[item] - count end
  end,

  updateCargo = function(self)
    local types = {"straight-rail", "curved-rail", "big-electric-pole", "rail-signal", "small-lamp"}
    for _,type in pairs(types) do
      self[type] = 0
      for i, wagon in ipairs(self.train.carriages) do
        if wagon.type == "cargo-wagon" then
          self[type] = self[type] + wagon.getinventory(1).getitemcount(type)
        end
      end
    end
  end,

  genericCanPlace = function(arg)
    if not arg.position or not arg.position.x or not arg.position.y then
      error("invalid position")
    elseif not arg.name then
      error("no name")
    end
    if not arg.direction then
      return game.canplaceentity{name = arg.name, position = arg.position}
    else
      return game.canplaceentity{name = arg.name, position = arg.position, direction = arg.direction}
    end
  end,

  genericPlace = function(arg)
    local canPlace = FARL.genericCanPlace(arg)
    local entity
    if canPlace then
      local direction = arg.direction or 0
      local force = arg.force or game.forces.player
      entity = game.createentity(arg)
    end
    return canPlace, entity
  end,

  placeRails = function(self,lastRail, travelDir, input, trackCount)
    local trackCount = trackCount or 1
    local lastRail = lastRail
    local newTravelDir, nextRail
    for i=1,trackCount do
      if i>1 then lastRail = nextRail end
      newTravelDir, nextRail = self:getRail(lastRail,travelDir,input)
      if newTravelDir then
        local newDir = nextRail.direction
        local newPos = nextRail.position
        self:removeTrees(newPos)
        if nextRail.name == "curved-rail" then
          local areas = clearAreas[nextRail.direction%4]
          for i=1,6 do
            self:removeTrees(newPos, areas[i])
          end
        end
        local canplace = game.canplaceentity{name = nextRail.name, position = newPos, direction = newDir}
        local hasRail = self[nextRail.name] > 0 or godmode
        if canplace and hasRail then
          game.createentity{name = nextRail.name, position = newPos, direction = newDir, force = game.forces.player}
          self:removeItemFromCargo(nextRail.name, 1)
          if glob.poles then
            if godmodePoles or self["big-electric-pole"] > 0 then
              self:placePole(newTravelDir, nextRail)
            end
          end
          if glob.signals then
            local signalWeight = nextRail.name == "curved-rail" and glob.settings.curvedWeight or 1
            self.signalCount = self.signalCount + signalWeight
            if godmodeSignals or self["rail-signal"] > 0 then
              if self:placeSignal(newTravelDir,nextRail) then self.signalCount = 0 end
            end
          end
        elseif not canplace then
          self.driver.print("Cant place "..nextRail.name.."@"..pos2Str(newPos).." dir:"..newDir)
          return false, false
        elseif not hasRail then
          self:deactivate()
          self.driver.print("Out of rails")
          return false, false
        end
      else
        if nextRail == "extra" then
          return travelDir, nextRail
        else
          self.driver.print("Error with: traveldir="..travelDir.." input:"..input)
          self:deactivate()
          debugDump(lastRail,true)
          return false, false
        end
      end
    end
    return newTravelDir, nextRail
  end,

  calcPole = function(self,lastrail, traveldir)
    local data = polePlacement.data[traveldir]
    local offset = addPos(data, {x=0,y=0})
    local distance, side, dir = glob.settings.poleDistance, glob.settings.poleSide, polePlacement.dir[traveldir]
    local lookup = lastrail.direction
    if lastrail.name ~= "curved-rail" then
      if data[lastrail.direction] then
        local flip = side == -1 and true or false
        if flip then lookup = (lookup+4)%8 end
        offset = addPos(data[lookup])
      else
        offset = addPos(data)
      end
    else
      offset = addPos(offset,polePlacement.curves[lastrail.direction])
      --dir = polePlacement.dir[lastrail.direction]
      distance = distance > 1 and distance - 1 or 1
    end
    --  if  lastrail.name == "curved-rail" then dir = {x=1,y=1} end
    offset.x = (offset.x + distance) * side * dir.x
    offset.y = (offset.y + distance) * side * dir.y
    if lastrail.name == "curved-rail" then
    --debugDump({lr=lastrail, off=offset, tr=traveldir},true)
    --debugDump({dist=distance,side=side,dir=dir},true)
    --debugDump("Result:"..pos2Str( addPos(lastrail.position, offset)),true)
    end
    return offset
  end,

  placeLamp = function(self,traveldir,pole)
    local offset ={
      [0] = {x=-0.5,y=1.5},
      [1] = {x=-1.5,y=1.5},
      [2] = {x=-1.5,y=-0.5},
      [3] = {x=-1.5,y=-1.5},
      [4] = {x=0.5,y=-1.5},
      [5] = {x=1.5,y=-1.5},
      [6] = {x=1.5,y=0.5},
      [7] = {x=1.5,y=1.5},
    }
    local pos = addPos(pole, offset[traveldir])
    local canplace = game.canplaceentity{name = "small-lamp", position = pos}
    if canplace then
      game.createentity{name = "small-lamp", position = pos, direction=0,force = game.forces.player}
      self:removeItemFromCargo("small-lamp", 1)
    end
  end,

  placePole = function(self,traveldir, lastrail)
    local tmp = {x=self.lastCheckPole.x,y=self.lastCheckPole.y}
    local area = {{tmp.x-30,tmp.y-30},{tmp.x+30,tmp.y+30}}
    local minDist, minPos = util.distance(tmp, self.lastPole), false
    --debugDump("Distance to last:"..minDist,true)
    for i,p in ipairs(game.findentitiesfiltered{area=area, name="big-electric-pole"}) do
      local dist = util.distance(p.position, tmp)
      local diff = subPos(p.position,self.lastPole.position)
      if dist < minDist then
        --if dist < minDist and diff.x == 0 and diff.y == 0 then
        minDist = dist
        minPos = p.position
      end
    end
    if minPos then self.lastPole = minPos end
    local offset = self:calcPole(lastrail, traveldir)
    self.lastCheckPole = addPos(lastrail.position, offset)
    local distance = util.distance(self.lastPole, self.lastCheckPole)
    if distance > 30 then
      self:removeTrees(tmp)
      local canplace = game.canplaceentity{name = "big-electric-pole", position = tmp}
      if canplace then
        game.createentity{name = "big-electric-pole", position = tmp, force = game.forces.player}
        if godmode or self["small-lamp"] > 0 then
          self:placeLamp(traveldir, tmp)
        end
        self:removeItemFromCargo("big-electric-pole", 1)
        self.lastPole = tmp
        self["big-electric-pole"] = self["big-electric-pole"] - 1
        return true
      else
      --self.driver.print("Can`t place pole@"..pos2Str(tmp))
      --debugDump(glob.lastCheckRail,true)
      end
    end
  end,

  placeSignal = function(self,traveldir, rail)
    if self.signalCount > glob.settings.signalDistance and rail.name ~= "curved-rail" then
      local rail = rail
      local data = signalOffset[traveldir]
      local offset = data[rail.direction] or data.pos
      local dir = data.dir
      local pos = addPos(rail.position, offset)
      self:removeTrees(pos)
      local success, entity = FARL.genericPlace{name = "rail-signal", position = pos, direction = dir, force = game.forces.player}
      if success then
        self:removeItemFromCargo("rail-signal", 1)
        self["rail-signal"] = self["rail-signal"] - 1
        return success, entity
      else
        --self.driver.print("Can't place signal@"..pos2Str(pos))
        return success, entity
      end
    end
    return nil
  end,

  findLastPole = function(self)
    local locomotive = self.locomotive
    local pos = {locomotive.position.x, locomotive.position.y}
    local poles = game.findentitiesfiltered{area={{pos[1]-30,pos[2]-30},{pos[1]+30,pos[2]+30}}, name="big-electric-pole"}
    local min, pole = 900, nil
    for i=1, #poles do
      local dist = math.abs(util.distance(locomotive.position,poles[i].position))
      if min > dist then
        pole = poles[i].position
        min = dist
      end
    end
    if not pole then
      self.lastPole = addPos(self.lastrail.position, {x=-100,y=-100})
      local offset = self:calcPole(self.lastrail, self:calcTrainDir())
      self.lastCheckPole = addPos(self.lastrail.position, offset)
    else
      self.lastPole = pole
      self.lastCheckPole = {x=pole.x,y=pole.y}
    end
  end,

  debugInfo = function(self)
    local locomotive = self.locomotive
    local player = self.driver
    if not self.active then self:activate() end
    player.print("Train@"..pos2Str(locomotive.position).." dir:"..self:calcTrainDir())
    local rail = self:railBelowTrain()
    if rail then
      player.print("Rail@"..pos2Str(rail.position).." dir:"..rail.direction)
    else
      player.print("No rail found")
    end
    local last = self:findLastRail()
    player.print("Last@"..pos2Str(last.position).." dir:"..last.direction)
    player.print("Pole@"..pos2Str(self.lastPole))
    player.print("LastCheck@"..pos2Str(self.lastCheckPole))
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
  railBelowTrain = function(self)
    local locomotive = self.locomotive
    local pos = {locomotive.position.x, locomotive.position.y}
    local rails = game.findentitiesfiltered{area={{pos[1]-0.4,pos[2]-0.4},{pos[1]+0.4,pos[2]+0.4}}, type="rail"}
    local trainDir = self:calcTrainDir()
    local curves ={}
    for i=1, #rails do
      if rails[i].name == "curved-rail" then
        table.insert(curves, rails[i])
      end
      if trainDir % 2 == 0 then
        if rails[i].direction == trainDir or (rails[i].direction + 4) % 8 == trainDir then
          return rails[i]
        end
      else
        local dir = (trainDir+2)%8
        if rails[i].direction == dir or rails[i].direction == (dir+4)%8 then
          return rails[i]
        end
      end
    end
    return curves[1]
  end
}
