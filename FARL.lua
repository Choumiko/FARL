require "util"

function addPos(p1,p2)
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
  local cos, sin = rot[rad].cos, rot[rad].sin
  local r = {{x=cos,y=-sin},{x=sin,y=cos}}
  local ret = {x=0,y=0}
  ret.x = pos.x * r[1].x + pos.y * r[1].y
  ret.y = pos.x * r[2].x + pos.y * r[2].y
  return ret
end

function pos2Str(pos)
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

local RED = {r = 0.9}
local GREEN = {g = 0.7}
local YELLOW = {r = 0.8, g = 0.8}

FARL = {
  new = function(player)
    local new = {
      locomotive = player.vehicle, train=player.vehicle.train,
      driver=player, active=false, lastrail=false,
      direction = false, input = 1, name = player.vehicle.backername,
      signalCount = 0, cruise = false, cruiseInterrupt = 0
    }
    setmetatable(new, {__index=FARL})
    return new
  end,

  onPlayerEnter = function(player)
    local i = FARL.findByLocomotive(player.vehicle)
    if i then
      glob.farl[i].driver = player
    else
      table.insert(glob.farl, FARL.new(player))
    end
  end,

  onPlayerLeave = function(player)
    for i,f in ipairs(glob.farl) do
      if f.driver and f.driver.name == player.name then
        f:deactivate()
        f.driver = false
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
        self.train = self.locomotive.train
        if self.train.valid then
          self:updateCargo()
        else
          self.deactivate("Error (invalid train)")
        end
      else
        if event.tick % 60 == 0 then
          self:updateCargo()
        end
        self.frontmover = false
        for i,l in ipairs(self.train.locomotives.frontmovers) do
          if l.equals(self.locomotive) then
            self.frontmover = true
            break
          end        
        end
        self.cruiseInterrupt = self.driver.ridingstate.acceleration
        self:layRails()
      end
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
    self:fillWater(area)
  end,
  
  fillWater = function(self, area)
    if landfillInstalled then
    -- check if bridging is turned on in settings
      if glob.bridge then
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
          if godmode or self["landfill2by2"] > lfills then
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

  getRail = function(lastRail, travelDir, input)
    local lastRail, travelDir, input = lastRail, travelDir, input
    if travelDir > 7 or travelDir < 0 then return false,false end
    if input > 2 or input < 0 then return false, false end
    local data = inputToNewDir[travelDir][input]
    local input2dir = {[0]=-1,[1]=0,[2]=1}
    local newTravelDir = (travelDir + input2dir[input]) % 8
    local name = data.curve and glob.rail.curved or glob.rail.straight
    local retDir, retRail
    if input == 1 then --straight
      local newDir, pos = data.direction, data.pos
      if travelDir % 2 == 1 then --diagonal travel
        if lastRail.name == glob.rail.straight then      --diagonal after diagonal
          if data.direction == lastRail.direction then
            local mul = 1
            if travelDir == 1 or travelDir == 5 then mul = -1 end
            newDir = (data.direction+4) % 8
            pos = {x=data.pos.y*mul, y=data.pos.x*mul}
        end
        pos = addPos(lastRail.position, pos)
      elseif lastRail.name == glob.rail.curved then --diagonal after curve
        pos = addPos(lastRail.position, data.connect.pos)
        newDir = data.connect.direction[lastRail.direction]
      end
      else -- N/E/S/W travel
        local shift = ""
        if lastRail.name == glob.rail.curved then --straight after curve
          pos = data.shift[lastRail.direction]
          shift = pos2Str(data.shift[lastRail.direction])
        end
        pos = addPos(lastRail.position, pos)
      end
      retDir, retRail = newTravelDir, {name=name, position=pos, direction=newDir}
    end
    if input ~= 1 then --left or right
      local s = "Changing direction from "..travelDir.." to "..newTravelDir
      if travelDir % 2 == 0 and lastRail.name == glob.rail.straight then --curve after N/S, E/W tracks
        local pos = addPos(lastRail.position,data.pos)
        retDir, retRail = newTravelDir, {name=name, position=pos, direction=data.direction}
      elseif travelDir % 2 == 1 and lastRail.name == glob.rail.straight then --curve after diagonal
        local pos = {x=0,y=0}
        local last = lastRail
        if lastRail.direction ~= data.lastDir then -- need extra diagonal rail to connect
          local testD, testR = FARL.getRail(lastRail,travelDir,1)
          local d2, r2 = FARL.getRail(testR,testD,input)
          --debugDump({testD, testR},true)
          --debugDump({d2, r2},true)
          retDir = {testD, d2}
          retRail = {testR, r2}
          --retDir, retRail = false, "extra"
        else
          pos = addPos(lastRail.position, data.pos)
          retDir, retRail = newTravelDir, {name=name, position=pos, direction=data.direction}
        end
      elseif lastRail.name == glob.rail.curved and name == glob.rail.curved then
        local pos
        if not data.curve[lastRail.direction].diag then -- curves connect directly
          pos = addPos(lastRail.position, data.curve[lastRail.direction].pos)
          retDir, retRail = newTravelDir, {name=name, position=pos, direction=data.direction}
        else
          local testD, testR = FARL.getRail(lastRail,travelDir,1)
          local d2, r2 = FARL.getRail(testR,testD,input)
          --debugDump({testD, testR},true)
          --debugDump({d2, r2},true)
          retDir = {testD, d2}
          retRail = {testR, r2}
          --retDir, retRail = false, "extra"
        end
      end
    end
    return retDir, retRail
  end,

  cruiseControl = function(self)
    local acc = self.frontmover and defines.riding.acceleration.accelerating or defines.riding.acceleration.reversing 
    if self.cruise then
      local limit = self.active and glob.cruiseSpeed or 0.9
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
      if ((self.acc ~= 3 and self.frontmover) or (self.acc ~=1 and not self.frontmover)) and util.distance(self.lastrail.position, firstWagon.position) < 6 then
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
        local dir, last = self:placeRails(self.lastrail, self.direction, self.input, count)
        if dir then
          self.direction, self.lastrail = dir, last
        else
          self:deactivate()
        end
        if self.driver.name == "farl_player" and #self.course == 0 then
          self:deactivate("Course done", true)
        end
      end
    end
  end,

  activate = function(self)
    self.lastrail = false
    self.signalCount = 0
    self.lastrail = self:findLastRail()
    if self.lastrail then
      self:findLastPole()
      self:updateCargo()
      self.direction = self:calcTrainDir()
      if self.direction and self.lastPole and self.lastCheckPole then
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
    if reason then
      self:print("Deactivated: "..reason)
    end
    self.lastrail = nil
    self.direction = nil
    self.lastPole, self.lastCheckPole = nil,nil
    self:updateCargo()
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

  findLastRail = function(self, limit)
    local trainDir = self:calcTrainDir()
    local test = self:railBelowTrain()
    local last = test
    local limit, count = limit, 1
    local ret = last
    while test and test.name ~= glob.rail.curved do
      last = test
      ret = last
      if limit and count == limit then
        return last
      end
      local _, next = FARL.getRail(last,trainDir,1)
      next = next[1] or next
      local pos = fixPos(next.position)
      local area = {{pos[1]-0.4,pos[2]-0.4},{pos[1]+0.4,pos[2]+0.4}}
      local found = false
      for i,rail in ipairs(game.findentitiesfiltered{area=area, name=glob.rail.straight}) do
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
      count = count + 1
      if not found then break end
    end
    if type(ret) == "table" then
      self:flyingText("Last", RED, true, ret.position)
    end
    return ret
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
    local position = game.findnoncollidingposition("item-on-ground", self.driver.position, 100, 0.5)
    game.createentity{name = "item-on-ground", position = position, stack = {name = item, count = count}}
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
          if self[item] and self[item] >= count then self[item] = self[item] - count end
          return
        end
      end
    end
  end,

  updateCargo = function(self)
    local types = { "straight-rail", "curved-rail","rail-signal",
      "big-electric-pole", "medium-electric-pole", "small-lamp",
      "green-wire", "red-wire"
    }
    if remote.interfaces.dim_trains then
      table.insert(types, "straight-power-rail")
      table.insert(types, "curved-power-rail")
    else
      self["straight-power-rail"] = nil
      self["curved-power-rail"] = nil
    end
    if landfillInstalled then
      table.insert(types, "landfill2by2")
    end
    for _,type in pairs(types) do
      self[type] = 0
      for i, wagon in ipairs(self.train.carriages) do
        if wagon.type == "cargo-wagon"  and wagon.name ~= "rail-tanker" then
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

  genericPlace = function(arg, ignore)
    local canPlace = FARL.genericCanPlace(arg)
    local entity
    if canPlace or ignore then
      local direction = arg.direction or 0
      local force = arg.force or game.forces.player
      arg.force = force
      entity = game.createentity(arg)
    end
    return canPlace, entity
  end,

  parseBlueprints = function(self, bp)
    for j=1,#bp do
      local e = bp[j].getblueprintentities()
      local offsets = {pole=false, lamps={}}
      local rail

      for i=1,#e do
        if not rail and e[i].name == "straight-rail" then
          rail = {direction = e[i].direction, name = e[i].name, position = e[i].position}
        end
        if e[i].name == "big-electric-pole" or e[i].name == "medium-electric-pole" then
          offsets.pole = {name = e[i].name, direction = e[i].direction, position = e[i].position}
        end
        if e[i].name == "small-lamp" then
          table.insert(offsets.lamps, {name = e[i].name, direction = e[i].direction, position = e[i].position})
        end
      end
      if rail and offsets.pole then
        local type = rail.direction == 0 and "straight" or "diagonal"
        local lamps = {}
        for _, l in ipairs(offsets.lamps) do
          table.insert(lamps, subPos(l.position, offsets.pole.position))
        end
        local poleType = offsets.pole.name == "medium-electric-pole" and "medium" or "big"
        local railPos = rail.position
        if type == "diagonal" then
          local x,y = 0,0
          if rail.direction == 3 then
            x = rail.position.x + 0.5
            y = rail.position.y + 0.5
          elseif rail.direction == 7 then
            x = rail.position.x - 0.5
            y = rail.position.y - 0.5
          end
          railPos = {x=x,y=y}
        end
        offsets.pole.position = subPos(offsets.pole.position,railPos)
        glob.settings.bp[poleType][type] = {direction=rail.direction, pole = offsets.pole, lamps = lamps}
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

  placeRails = function(self,lastRail, travelDir, input)
    local lastRail = lastRail
    local newTravelDirs, nextRails
    newTravelDirs, nextRails = FARL.getRail(lastRail,travelDir,input)
    if type(newTravelDirs) == "number" then
      newTravelDirs = {newTravelDirs}
      nextRails = {nextRails}
    end
    local retDir, retRail = newTravelDirs[1], nextRails[1]
    for i=1,#newTravelDirs do
      local newTravelDir, nextRail = newTravelDirs[i], nextRails[i]
      if newTravelDir and nextRail.position then
        local newDir = nextRail.direction
        local newPos = nextRail.position
        self:removeTrees(newPos)
        if nextRail.name == glob.rail.curved then
          local areas = clearAreas[nextRail.direction%4]
          for i=1,6 do
            self:removeTrees(newPos, areas[i])
          end
        end
        local canplace = game.canplaceentity{name = nextRail.name, position = newPos, direction = newDir}
        local hasRail = self[nextRail.name] > 0 or godmode
        if canplace and hasRail then
          game.createentity{name = nextRail.name, position = newPos, direction = newDir, force = game.forces.player}
          if glob.settings.electric then
            remote.call("dim_trains", "railCreated", newPos)
          end
          self:removeItemFromCargo(nextRail.name, 1)
          if glob.poles then
            if godmodePoles or self["big-electric-pole"] > 0 or self["medium-electric-pole"] > 0 then
              self:placePole(newTravelDir, nextRail, travelDir)
            end
          end
          if glob.signals then
            local signalWeight = nextRail.name == glob.rail.curved and glob.settings.curvedWeight or 1
            self.signalCount = self.signalCount + signalWeight
            if godmodeSignals or self["rail-signal"] > 0 then
              if self:placeSignal(newTravelDir,nextRail) then self.signalCount = 0 end
            end
          end
          retDir, retRail = newTravelDir, nextRail
        elseif not canplace then
          self:deactivate("Can't place rail", true)
          return false, false
        elseif not hasRail then
          self:deactivate("Out of rails")
          return false, false
        end
      else
        if nextRail == "extra" then
          return travelDir, nextRail
        else
          self:deactivate("Error with: traveldir="..travelDir.." input:"..input)
          debugDump(lastRail,true)
          return false, false
        end
      end
    end
    return retDir, retRail
  end,

  calcPole = function(self,lastrail, traveldir, oldDir)
    local offset
    local curvePositions = {
      [0] = {straight={dir=0, off={x=1,y=3}}, diagonal = {dir=5, off={x=-1,y=-3}}},
      [1] = {straight={dir=0, off={x=-1,y=3}}, diagonal = {dir=3, off={x=1,y=-3}}},
      [2] = {straight={dir=2, off={x=-3,y=1}}, diagonal = {dir=7, off={x=3,y=-1}}},
      [3] = {straight={dir=2, off={x=-3,y=-1}}, diagonal = {dir=5, off={x=3,y=1}}},
      [4] = {straight={dir=0, off={x=-1,y=-3}}, diagonal = {dir=1, off={x=1,y=3}}},
      [5] = {straight={dir=0, off={x=1,y=-3}}, diagonal = {dir=7, off={x=-1,y=3}}},
      [6] = {straight={dir=2, off={x=3,y=-1}}, diagonal = {dir=3, off={x=-3,y=1}}},
      [7] = {straight={dir=2, off={x=3,y=1}}, diagonal = {dir=1, off={x=-3,y=-1}}}
    }

    if lastrail.name ~= glob.rail.curved then
      local diagonal = traveldir % 2 == 1 and true or false
      local pole = not diagonal and glob.activeBP.straight.pole or glob.activeBP.diagonal.pole
      local pos = addPos(pole.position)
      local diff = not diagonal and traveldir or traveldir-1
      local rad = diff * (math.pi/4)
      offset = rotate(pos, rad)
      if glob.settings.flipPoles then
        offset = rotate(offset, math.pi)
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
      local tracks = curvePositions[lastrail.direction]
      offset = {}
      local d = {name=glob.rail.straight, direction=tracks.diagonal.dir, position=addPos(lastrail.position,tracks.diagonal.off)}
      local s = {name=glob.rail.straight, direction=tracks.straight.dir, position=addPos(lastrail.position,tracks.straight.off)}

      local dDir = traveldir % 2 == 1 and traveldir or oldDir
      local sDir = traveldir % 2 == 0 and traveldir or oldDir
      offset[1] = {rail=d, dir = dDir}
      offset[2] = {rail=s, dir = sDir}
    end
    return offset
  end,

  placeLamp = function(self,traveldir,pole)
    local lamps = traveldir % 2 == 0 and glob.activeBP.straight.lamps or glob.activeBP.diagonal.lamps
    local diff = traveldir % 2 == 0 and traveldir or traveldir-1
    local rad = diff * (math.pi/4)
    for i=1,#lamps do
      local offset = rotate(lamps[i], rad)
      local pos = addPos(pole, offset)
      --debugDump(pos, true)
      local canplace = game.canplaceentity{name = "small-lamp", position = pos}
      if canplace and (self["small-lamp"] > 1 or godmode) then
        game.createentity{name = "small-lamp", position = pos, direction=0,force = game.forces.player}
        self:removeItemFromCargo("small-lamp", 1)
      end
    end
  end,

  connectCCNet = function(self, pole)
    if glob.settings.ccNet and pole.neighbours[1] and self.ccNetPole then
      if godmode  or (glob.settings.ccWires == 1 and self["red-wire"] > 0)
        or (glob.settings.ccWires == 2 and self["green-wire"] > 0)
        or (glob.settings.ccWires == 3 and (self["red-wire"] > 0 or self["green-wire"] > 0)) then
        local c = {}
        local items = {}
        if glob.settings.ccWires == 1 then
          c = {defines.circuitconnector.red}
          items = {"red-wire"}
        elseif glob.settings.ccWires == 2 then
          c = {defines.circuitconnector.green}
          items = {"green-wire"}
        else
          c = {defines.circuitconnector.red, defines.circuitconnector.green}
          items = {"red-wire", "green-wire"}
        end
        for i=1,#c do
          if self[items[i]] > 0 or godmode then
            pole.connectneighbour(self.ccNetPole, c[i])
            self:removeItemFromCargo(items[i], 1)
          end
        end
      end
    end
    self.ccNetPole = pole
  end,

  placePole = function(self,traveldir, lastrail, oldDir)
    local name = glob.medium and "medium-electric-pole" or "big-electric-pole"
    local reach = glob.medium and 9 or 30
    local tmp = {x=self.lastCheckPole.x,y=self.lastCheckPole.y}
    local area = {{tmp.x-reach,tmp.y-reach},{tmp.x+reach,tmp.y+reach}}
    local minDist, minPos = util.distance(tmp, self.lastPole), false
    --debugDump("Distance to last:"..minDist,true)
    if not glob.settings.ccNet and glob.minPoles then
      for i,p in ipairs(game.findentitiesfiltered{area=area, name=name}) do
        local dist = util.distance(p.position, tmp)
        local diff = subPos(p.position,self.lastPole.position)
        if dist < minDist then
          --if dist < minDist and diff.x == 0 and diff.y == 0 then
          minDist = dist
          minPos = p.position
        end
      end
    end
    if minPos then self.lastPole = minPos end
    local offset = self:calcPole(lastrail, traveldir, oldDir)
    if not offset.x then
      local d1 = util.distance(offset[1].rail.position,self.lastPole)
      local d2 = util.distance(offset[2].rail.position,self.lastPole)
      local first = d1 < d2 and offset[1] or offset[2]
      local second = d1 < d2 and offset[2] or offset[1]

      self:placePole(first.dir, first.rail)
      self:placePole(second.dir, second.rail)
      return
    end

    self.lastCheckPole = addPos(lastrail.position, offset)
    local distance = util.distance(self.lastPole, self.lastCheckPole)
    if distance > reach then
      if name ~= "big-electric-pole" and traveldir % 2 == 0 and lastrail.name ~= glob.rail.curved then
        if not self.switch then
          local fix = util.moveposition({tmp.x, tmp.y}, traveldir, 1)
          if util.distance(self.lastPole, {x=fix[1],y=fix[2]}) > reach then
            fix = {tmp.x,tmp.y}
            self.switch = not self.switch
          end
          tmp = {x=fix[1], y=fix[2]}
        end
        self.switch = not self.switch
      end
      --debugDump({dist=distance, lr=lastrail, dir=traveldir, offset=offset},true)
      self:removeTrees(tmp)
      self[name] = self[name] or 0
      local canplace = game.canplaceentity{name = name, position = tmp}
      if canplace and (self[name] > 0 or godmode or godmodePoles) then
        local pole = game.createentity{name = name, position = tmp, force = game.forces.player}
        if not pole.neighbours[1] then
          self:flyingText("Placed unconnected pole", RED, true)
        end
        if godmode or self["small-lamp"] > 0 then
          self:placeLamp(traveldir, tmp)
        end
        self:removeItemFromCargo(name, 1)
        self:connectCCNet(pole)
        self.lastPole = tmp
        self[name] = self[name] - 1
        return true
      else
      --self:print("Can`t place pole@"..pos2Str(tmp))
      --debugDump(glob.lastCheckRail,true)
      end
    end
  end,

  placeSignal = function(self,traveldir, rail)
    if self.signalCount > glob.settings.signalDistance and rail.name ~= glob.rail.curved then
      local rail = rail
      local data = signalOffset[traveldir]
      local offset = data[rail.direction] or data.pos
      local dir = data.dir
      if glob.flipSignals then
        local off = offset
        if traveldir % 2 == 1 then
          off = data[(rail.direction+4)%8] or data.pos
        end
        offset = {x=off.x*-1, y=off.y*-1}
        dir = (dir + 4) % 8
      end
      local pos = addPos(rail.position, offset)
      self:removeTrees(pos)
      local success, entity = FARL.genericPlace{name = "rail-signal", position = pos, direction = dir, force = game.forces.player}
      if success then
        self:removeItemFromCargo("rail-signal", 1)
        self["rail-signal"] = self["rail-signal"] - 1
        return success, entity
      else
        --self:print("Can't place signal@"..pos2Str(pos))
        return success, entity
      end
    end
    return nil
  end,

  findLastPole = function(self)
    local name = glob.medium and "medium-electric-pole" or "big-electric-pole"
    local reach = glob.medium and 9 or 30
    local locomotive = self.locomotive
    local pos = {locomotive.position.x, locomotive.position.y}
    local poles = game.findentitiesfiltered{area={{pos[1]-reach,pos[2]-reach},{pos[1]+reach,pos[2]+reach}}, name=name}
    local min, pole = 900, nil
    for i=1, #poles do
      local dist = math.abs(util.distance(locomotive.position,poles[i].position))
      if min > dist then
        pole = poles[i]
        min = dist
      end
    end
    if not pole then
      self.lastPole = addPos(self.lastrail.position, {x=-100,y=-100})
      local offset = self:calcPole(self.lastrail, self:calcTrainDir())
      self.lastCheckPole = addPos(self.lastrail.position, offset)
    else
      self.ccNetPole = pole
      self.lastPole = pole.position
      self.lastCheckPole = {x=pole.position.x,y=pole.position.y}
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
      if rails[i].name == glob.rail.curved then
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
    if curves[1] then self:deactivate("Can't start on curves", true) end
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
}
