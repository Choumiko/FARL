require "settings"

local math = math
local util = util
--local direction ={ N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7}

local input2dir = {[0]=-1,[1]=0,[2]=1}
-- inputToNewDir[oldDir][input] -> rail to new dir
--shift[lastCurveDir]
--connect[].direction[lastCurve]=required diag dir
--curve[lastCurve] -> pos, diag required -> diagDir
local inputToNewDir =
  {
    [0] = {
      [0]={pos={x=-1,y=-5},direction=0,curve={[4]={pos={x=-2,y=-8}},[5]={pos={x=0,y=-8}}}},
      [1]={pos={x=0,y=-2},direction=0, shift={[4]={x=-1,y=-5},[5]={x=1,y=-5}}},
      [2]={pos={x=1,y=-5},direction=1,curve={[4]={pos={x=0,y=-8}},[5]={pos={x=2,y=-8}}}}},
    [1] = {
      [0]={pos={x=3,y=-3},direction=5,curve={[1]={pos={x=4,y=-6}},[2]={diag=true}}, lastDir=3},
      [1]={pos={x=0,y= -2},direction=3,connect={pos={x=3,y=-3},direction={[1]=7,[2]=3, [7]=5}}},
      [2]={pos={x=3,y=-3},direction=6,curve={[1]={diag=true},[2]={pos={x=6,y=-4}}}, lastDir=7}},
    [2] = {
      [0]={pos={x=5,y=-1},direction=2,curve={[7]={pos={x=8,y=0}},[6]={pos={x=8,y=-2}}}},
      [1]={pos={x=2,y=0},direction=2, shift={[6]={x=5,y=-1},[7]={x=5,y=1}}},
      [2]={pos={x=5,y=1},direction=3,curve={[7]={pos={x=8,y=2}},[6]={pos={x=8,y=0}}}}},
    [3] = {
      [0]={pos={x=3,y=3},direction=7,curve={[4]={diag=true},[3]={pos={x=6,y=4}}}, lastDir=5},
      [1]={pos={x=2,y=0},direction=5,connect={pos={x=3,y=3},direction={[3]=1,[4]=5}}},
      [2]={pos={x=3,y=3},direction=0,curve={[4]={pos={x=4,y=6}},[3]={diag=true}}, lastDir=1}},
    [4] = {
      [0]={pos={x=1,y=5},direction=4,curve={[0]={pos={x=2,y=8}},[1]={pos={x=0,y=8}}}},
      [1]={pos={x=0,y=2},direction=0, shift={[0]={x=1,y=5}, [1]={x=-1,y=5}}},
      [2]={pos={x=-1,y=5},direction=5,curve={[0]={pos={x=0,y=8}},[1]={pos={x=-2,y=8}}}}},
    [5] = {
      [0]={pos={x=-3,y=3},direction=1,curve={[5]={pos={x=-4,y=6}},[6]={diag=true}}, lastDir=7},
      [1]={pos={x= 0,y=2},direction=7,connect={pos={x=-3,y=3},direction={[5]=3,[6]=7, [7]=5}}},
      [2]={pos={x=-3,y=3},direction=2,curve={[5]={diag=true},[6]={pos={x=-6,y=4}}}, lastDir=3}},
    [6] = {
      [0]={pos={x=-5,y=1},direction=6,curve={[3]={pos={x=-8,y=0}},[2]={pos={x=-8,y=2}}}},
      [1]={pos={x=-2,y=0},direction=2, shift={[2]={x=-5,y=1},[3]={x=-5,y=-1}}},
      [2]={pos={x=-5,y=-1},direction=7,curve={[3]={pos={x=-8,y=-2}},[2]={pos={x=-8,y=0}}}}},
    [7] = {
      [0]={pos={x=-3,y=-3},direction=3,curve={[0]={diag=true},[7]={pos={x=-6,y=-4}}}, lastDir=1},
      [1]={pos={x=0,y=-2},direction=5,connect={pos={x=-3,y=-3},direction={[0]=1, [7]=5}}},
      [2]={pos={x=-3,y=-3},direction=4,curve={[0]={pos={x=-4,y=-6}},[7]={diag=true}}, lastDir=5}}
  }--{[]={pos={x=,y=},diag},[]={pos={x=,y=},diag}}

--clearArea[curveDir%4]
local clearAreas =
  {
    [0]={{{x=-3.5,y=-3.5},{x=0.5,y=-2.5}},{{x=-3.5,y=-1.5},{x=1.5,y=-1.5}},
      {{x=-2.5,y=-0.5},{x=1.5,y=-0.5}},{{x=-1.5,y=0.5},{x=2.5,y=0.5}},
      {{x=-1.5,y=1.5}, {x=3.5,y=1.5}},{{x=-0.5,y=2.5},{x=3.5,y=3.5}}},
    [1]={{{x=-0.5,y=-3.5},{x=3.5,y=-2.5}},{{x=-1.5,y=-1.5},{x=3.5,y=-1.5}},
      {{x=-1.5,y=-0.5},{x=2.5,y=-0.5}},{{x=-2.5,y=0.5},{x=1.5,y=0.5}},
      {{x=-3.5,y=1.5},{x=1.5,y=1.5}},{{x=-3.5,y=2.5},{x=0.5,y=3.5}}},
    [2]={{{x=2.5,y=-3,5},{x=3.5,y=0.5}},{{x=1.5,y=-3,5},{x=1.5,y=1.5}},
      {{x=0.5,y=-2.5},{x=0.5,y=1.5}},{{x=-0.5,y=-1.5},{x=-0.5,y=2.5}},
      {{x=-1.5,y=-1.5},{x=-1.5,y=3.5}},{{x=-3.5,y=-0.5},{x=-2.5,y=3.5}}},
    [3]={{{x=2.5,y=-0,5},{x=3.5,y=3.5}},{{x=1.5,y=-1,5},{x=1.5,y=3.5}},
      {{x=0.5,y=-1.5},{x=0.5,y=2.5}},{{x=-0.5,y=-2.5},{x=-0.5,y=1.5}},
      {{x=-1.5,y=-3.5},{x=-1.5,y=1.5}},{{x=-3.5,y=-3.5},{x=-2.5,y=0.5}}}
  }
local polePlacement = polePlacement  
polePlacement.data = {
    [0]={x = 2, y = 0},
    [1]={x = 1.5, y = 1.5},
    [2]={x = 0, y = 2},
    [3]={x = 1.5, y = 1.5},
    [4]={x = 2, y = 0},
    [5]={x = 1.5, y = 1.5},
    [6]={x = 0, y = 2},
    [7]={x = 1.5, y = 1.5},
}
polePlacement.dir = {
    [0]={x = 1, y = 1},
    [7]={x = 1, y = -1},
    [2]={x = 1, y = 1},
    [5]={x = -1, y = -1},

    [4]={x = -1, y = 1},
    [3]={x = -1, y = 1},
    [6]={x = 1, y = -1},
    [1]={x = 1, y = 1}
}  
for i = 0, 7 do
  polePlacement.data[i].x = (polePlacement.data[i].x + polePlacement.distance) * polePlacement.side * polePlacement.dir[i].x
  polePlacement.data[i].y = (polePlacement.data[i].y + polePlacement.distance) * polePlacement.side * polePlacement.dir[i].y
end

--[traveldir] ={[raildir]
local signalOffset =
{
  [0] = {pos={x=1.5,y=0.5}, dir=4},
  [1] = {[3]={x=1.5,y=1.5}, [7]={x=0.5,y=0.5}, dir=5},
  [2] = {pos={x=-0.5,y=1.5}, dir=6},
  [3] = {[1]={x=-0.5,y=0.5},[5]={x=-1.5,y=1.5}, dir=7},
  [4] = {pos={x=-1.5,y=-0.5}, dir=0},
  [5] = {[3]={x=-0.5,y=-0.5},[7]={x=-1.5,y=-1.5}, dir=1},
  [6] = {pos={x=0.5,y=-1.5}, dir=2},
  [7] = {[1]={x=1.5,y=-1.5},[5]={x=0.5,y=-0.5}, dir=3},
}

local function addPos(p1,p2)
  return {x=p1.x+p2.x, y=p1.y+p2.y}
end
local function pos2Str(pos)
  return util.positiontostr(pos)
end
local function fixPos(pos)
  local ret = {}
  if pos.x then ret[1] = pos.x end
  if pos.y then ret[2] = pos.y end
  return ret
end
FARL = {}
function FARL:removeTrees(pos, area)
  if not area then
    area = {{pos.x - 1.5, pos.y - 1.5}, {pos.x + 1.5, pos.y + 1.5}}
  else
    local tl, lr = fixPos(addPos(pos,area[1])), fixPos(addPos(pos,area[2])) 
    area = {{tl[1]-1,tl[2]-1},{lr[1]+1,lr[2]+1}}
  end
  for _, entity in ipairs(game.findentitiesfiltered{area = area, type = "tree"}) do
    entity.die()
    self:addItemToCargo("raw-wood", 1)
  end
  if removeStone then
    for _, entity in ipairs(game.findentitiesfiltered{area = area, name = "stone-rock"}) do
      entity.die()
    end
  end
end

function FARL:getRail(lastRail, travelDir, input)
  local lastRail, travelDir, input = lastRail, travelDir, input
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
        --flyingText("Need extra track!",RED,lastRail.position,true)
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
        --flyingText("Need extra track!",RED,lastRail.position,true)
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
        --debugDump("Diag after curve data["..travelDir.."]["..input.."]",true)
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
      --debugDump("Shift curve"..lastRail.direction..pos2Str(data.shift[lastRail.direction]),true)--,RED,lastRail.position,true)
    end
    pos = addPos(lastRail.position, pos)
    return newTravelDir, {name=name, position=pos, direction=data.direction}
  end
  end
end

function FARL:layRails()
  if self.active and self.lastrail and self.train then
    self.direction = self.direction or self:calcTrainDir()
    if self.train.speed > 0 and util.distance(self.lastrail.position, self.locomotive.position) < 6 then
      self.input = self.driver.ridingstate.direction
      local dir, last = self:placeRails(self.lastrail, self.direction, self.input)
      if dir and last == "extra" and self.active then
        dir, last = self:placeRails(self.lastrail, self.direction, 1)
        dir, last = self:placeRails(last, dir, self.input)
      end
      if dir then
        self.direction, self.lastrail = dir, last
        if self["big-electric-pole"] > 0 or godmodePoles then
          self:placePole()
        end
      else
        self:deactivate()
        self.driver.print("Deactivated")
        self.driver.gui.top.farl.start.caption="Start"
      end
    end
  end
end

local function onTick(event)
  for i, farl in pairs(glob.farl) do
    if event.tick % 60 == 0 then
      farl:updateCargo()
    end
    farl:layRails()
  end
  if event.tick%10==9  then
    for pi, player in ipairs(game.players) do
      if (player.vehicle ~= nil and player.vehicle.name == "farl") then
        if player.gui.top.farl and not player.gui.top.farl.start then FARL.destroyGui(pi,player) end
        if player.gui.top.farl == nil then
          FARL.create(pi, player)
        end
      end
      if player.vehicle == nil and player.gui.top.farl ~= nil then
        FARL.remove(pi,player)
      end
    end
  end
end

local function initGlob()
  if glob.version == nil or glob.version < "0.0.3" then
    glob = {}
    glob.version = "0.0.3"
  end
  glob.farl = glob.farl or {}
  glob.railInfoLast = glob.railInfoLast or {}
  glob.debug = glob.debug or {}
  glob.action = glob.action or {}
  for i,farl in pairs(glob.farl) do
    farl = resetMetatable(farl)
  end
  for _,p in pairs(game.players) do
    p.force.resetrecipes()
    p.force.resettechnologies()
    if game.forces.player.technologies["rail-signals"].researched then
      game.forces.player.recipes["farl"].enabled = true
    end
  end
end

local function oninit() initGlob() end

local function onload()
  initGlob()
end

function findByPlayer(player)
  for i,f in pairs(glob.farl) do
    if f.locomotive.equals(player.vehicle) then
      f.driver = player
      return f
    end
  end
  return false
end

function resetMetatable(o)
  setmetatable(o,{__index=FARL})
  return o
end

function FARL:new(train)
  local o = train or {}
  setmetatable(o, {__index=self})
  return o
end
  
function FARL.create(index, player)
  local new = {
    locomotive = player.vehicle, train=player.vehicle.train,
    driver=player, index = index, active=false, lastrail=false,
    direction = false, input = 1, name = player.vehicle.backername,
    signalCount = 0
  }
  if not findByPlayer(player) then
    local farl = FARL:new(new)
    table.insert(glob.farl, farl)
  end
    FARL.createGui(index,player)
end

function FARL.remove(index, player)
  for i,f in pairs(glob.farl) do
    if f.driver.name == player.name then
      glob.farl[i] = nil
      break
    end
  end
  if player.gui.top.farl ~= nil then
    FARL.destroyGui(index,player)
  end
end
function FARL:activate()
  if self.active then self:deactivate() end
  self.lastrail = self:findLastRail()
  self:findLastPole()
  self:updateCargo()
  self.direction = self:calcTrainDir()
  if self.lastrail and self.direction and self.lastPole and self.lastCheckPole then
    self.active = true
    self.driver.gui.top.farl.start.caption="Stop"
  else
    self:deactivate()
  end
end

function FARL:deactivate()
  self.active = false
  self.input = nil
  self.lastrail = nil
  self.direction = nil
  self.lastPole, self.lastCheckPole = nil,nil
  self.driver.gui.top.farl.start.caption="Start"
end

function FARL.createGui(index, player)
  if player.gui.top.farl ~= nil then return end
  local f = findByPlayer(player)
  local caption = f.active and "Stop" or "Start"
  local farl = player.gui.top.add({type="frame", direction="vertical", name="farl"})
  farl.add({type="button", name="debug", caption="Debug Info"})
  farl.add({type="button", name="start", caption=caption})
end

function FARL.destroyGui(index,player)
  if player.gui.top.farl == nil then return end
  player.gui.top.farl.destroy()
end

function FARL.onGuiClick(event)
  local index = event.playerindex or event.name
  local player = game.players[index]
  --local train = player.opened or player.vehicle
  local farl = findByPlayer(player)
  if farl then
    if event.element.name == "debug" then
      saveVar(glob,"debug")
      --glob.debug = {}
      --glob.action = {}
      farl:debugInfo()
    elseif event.element.name == "start" then
      if event.element.caption == "Start" then
        farl:activate()
        event.element.caption = "Stop"
        --FARL.debugInfo(player, farl.locomotive)
      else
        if player.vehicle.name == "farl" then
          farl:deactivate()
          event.element.caption = "Start"
        end
      end
    end
  else
    player.print("Gui without train, wrooong!")
    FARL.destroyGui(index,player)
  end
end

function FARL:findLastRail()
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
  return last
end

function FARL:addItemToCargo(item, count)
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
end

function FARL:removeItemFromCargo(item, count)
  if godmode then return end
  local count = count or 1
  local wagons = self.train.carriages
  for _,entity in pairs(wagons) do
    if entity.name == "cargo-wagon" then
      local inv = entity.getinventory(1).getcontents()
      if inv[item] then
        entity.getinventory(1).remove({name=item, count=count})
      end
    end
  end
  if self[item] and self[item] >= count then self[item] = self[item] - count end
end

function FARL:updateCargo()
  local types = {"straight-rail", "curved-rail", "big-electric-pole", "rail-signal"}
  local cargo = self:cargoCount()
  for _,type in pairs(types) do
    self[type] = cargo[type] or 0
  end  
end

function FARL:cargoCount()
  local sum = {}
  local train = self.train
  for i, wagon in ipairs(train.carriages) do
    if wagon.type == "cargo-wagon" then
      sum = self:addInventoryContents(sum, wagon.getinventory(1).getcontents())
    end
  end
  return sum
end

function FARL:addInventoryContents(invA, invB)
  local res = {}
  for item, c in pairs(invA) do
    invB[item] = invB[item] or 0
    res[item] = c + invB[item]
    invB[item] = nil
    if res[item] == 0 then res[item] = nil end
  end
  for item,c in pairs(invB) do
    res[item] = c
    if res[item] == 0 then res[item] = nil end
  end
  return res
end

function FARL:placeRails(lastRail, travelDir, input)
  local newTravelDir, nextRail = self:getRail(lastRail,travelDir,input)
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
      local signalWeight = nextRail.name == "curved-rail" and signalPlacement.curvedWeight or 1
      self.signalCount = self.signalCount + signalWeight
        if self["rail-signal"] > 0 or godmodeSignals then
          if self:placeSignal(newTravelDir,nextRail) then self.signalCount = 0 end
        end 
--        local debug = false --set to true when rails get misplaced
--        if debug then
--          local area = {{newPos.x-0.4,newPos.y-0.4},{newPos.x+0.4,newPos.y+0.4}}
--          for i,rail in ipairs(game.findentitiesfiltered{area=area, name=nextRail.name}) do
--            if rail.direction == newDir then
--              if rail.position.x ~= newPos.x or rail.position.y ~= newPos.y then
--                local diff={x=rail.position.x-newPos.x, y=rail.position.y-newPos.y}
--                local debugaction = lastRail.name.."@"..pos2Str(lastRail.position)..":"..lastRail.direction.." travel:"..travelDir.." input:"..input
--                local debugDiff = rail.name.." placed@"..pos2Str(rail.position).." calc@"..pos2Str(newPos).." diff="..pos2Str(diff)
--                table.insert(glob.debug, {debugaction, debugDiff})
--                debugDump({debugaction,debugDiff},true)
--              end
--              return newTravelDir, rail
--            end
--          end
--          self.driver.print("Placed rail not found?!")
--          return false, false
--        else
          return newTravelDir,nextRail
--        end
    elseif not canplace then
      self.driver.print("Cant place "..nextRail.name.."@"..pos2Str(newPos).." dir:"..newDir)
      return false, false
    elseif not hasRail then
      self:deactivate()
      self.driver.print("Out of rails")
    end
  else
    if nextRail == "extra" then
      return travelDir, nextRail
    else
      self.driver.print("Error with: traveldir="..travelDir.." input:"..input)
      debugDump(lastRail,true)
      return false, false
    end
  end
end

function FARL:placePole()
  local tmp = {x=self.lastCheckPole.x,y=self.lastCheckPole.y}
  self.lastCheckPole = addPos(self.lastrail.position, polePlacement.data[self.direction])
  local distance = util.distance(self.lastPole, self.lastCheckPole)
  local basedon = addPos(self.lastrail.position,{x=0,y=0})
  if distance > 30 then
    self:removeTrees(tmp)
    local canplace = game.canplaceentity{name = "big-electric-pole", position = tmp}
    if canplace then
      game.createentity{name = "big-electric-pole", position = tmp, force = game.forces.player}
      local area = {{tmp.x-0.4,tmp.y-0.4},{tmp.x+0.4,tmp.y+0.4}}
      local placed = game.findentitiesfiltered{area=area, name="big-electric-pole"}[1]
      if not placed.neighbours[1] then
        self.driver.print("Placed disconnected pole")
      end
      if placed.position.x ~= tmp.x or placed.position.y ~= tmp.y then
        local diff={x=placed.position.x-tmp.x, y=placed.position.y-tmp.y}
        --self.driver.print("Misplaced pole: placed@"..pos2Str(placed.position).." calc@"..pos2Str(tmp).." diff="..pos2Str(diff))
      end
      self:removeItemFromCargo("big-electric-pole", 1)
      self.lastPole = tmp
      self["big-electric-pole"] = self["big-electric-pole"] - 1
      return true
    else
      self.driver.print("Can`t place pole@"..pos2Str(tmp))
    end
  end
end

function FARL:placeSignal(traveldir, rail)
  if self.signalCount > signalPlacement.distance and rail.name ~= "curved-rail" then
    local rail = rail
    local data = signalOffset[traveldir]
    local offset = data[rail.direction] or data.pos
    local dir = data.dir
    local pos = addPos(rail.position, offset)
    self:removeTrees(pos)
    local canplace = game.canplaceentity{name = "rail-signal", position = pos, direction = dir}
    if canplace then
      game.createentity{name = "rail-signal", position = pos, direction = dir, force = game.forces.player}
      self:removeItemFromCargo("rail-signal", 1)
      self["rail-signal"] = self["rail-signal"] - 1
      return true
    else
      self.driver.print("Can't place signal@"..pos2Str(pos))
      return false
    end
  end
  return false
end

function FARL:findLastPole()
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
    self.lastCheckPole = addPos(self.lastrail.position, polePlacement.data[self:calcTrainDir()%8])
  else
    self.lastPole = pole
    self.lastCheckPole = {x=pole.x,y=pole.y}
  end  
end

function FARL:debugInfo()
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
end

function FARL:calcTrainDir()
  return math.floor(self.locomotive.orientation * 8)
end

--    curve  traindirs
--        0   3   7
--        1   0   4
--        2   1   5
--        3   2   6
--        4   3   7
--        5   0   4
--        6   1   5
--        7   2   6
function FARL:railBelowTrain()
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

game.oninit(oninit)
game.onload(onload)
game.onevent(defines.events.ontick, onTick)
game.onevent(defines.events.onguiclick, FARL.onGuiClick)
--game.onevent(defines.events.ontrainchangedstate, function(event) ontrainchangedstate(event) end)
--game.onevent(defines.events.onplayermineditem, function(event) onplayermineditem(event) end)
--game.onevent(defines.events.onpreplayermineditem, function(event) onpreplayermineditem(event) end)
--game.onevent(defines.events.onbuiltentity, function(event) onbuiltentity(event) end)
--game.onevent(defines.events.onplayercreated, function(event) onplayercreated(event) end)

function debugDump(var, force)
  if false or force then
    for i,player in ipairs(game.players) do
      local msg
      if type(var) == "string" then
        msg = var
      else
        msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
      end
      player.print(msg)
    end
  end
end
function saveVar(var, name)
  local var = var or glob
  local n = name or ""
  game.makefile("farl/farl"..n..".lua", serpent.block(var, {name="glob"}))
  --game.makefile("farl/loco"..n..".lua", serpent.block(findAllEntitiesByType("locomotive")))
end

local RED = {r = 0.9}
local GREEN = {g = 0.7}
local YELLOW = {r = 0.8, g = 0.8}

function flyingText(line, color, pos, show)
  if show then
    pos = pos or game.player.position
    color = color or RED
    game.createentity({name="flying-text", position=pos, text=line, color=color})
  end
end

remote.addinterface("farl",
  {
    railInfo = function(rail)
      game.player.print(rail.name.."@"..pos2Str(rail.position).." dir:"..rail.direction)
      if glob.railInfoLast.valid then
        local pos = glob.railInfoLast.position
        local diff={x=rail.position.x-pos.x, y=rail.position.y-pos.y}
        game.player.print("Offset from last: x="..diff.x..",y="..diff.y)
      end
      glob.railInfoLast = rail
    end,
    debugInfo = function()
      saveVar(glob, "console")
      saveVar(glob.debug, "RailDebug")
    end,
    reset = function()
      glob.farl = {}
      for i,p in pairs(glob.players) do
        if p.gui.top.farl then FARL.destroyGui(i,p) end
      end
    end,
    placePole = function()
      local farl = findByPlayer(game.player)
      farl:activate()
      farl:placePole()
    end,
    cruiseControl = function()
      glob.cc = glob.cc or 0
      if glob.cc == 0 then
        glob.cc = 1
      else
        glob.cc = 0
      end
    end
  })
