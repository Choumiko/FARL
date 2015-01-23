require "defines"
require "util"
godmode = false
godmodePoles = false
godmodeSignals = false
removeStone = true

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

local signalPlacement = {}

local polePlacement = {}
 
polePlacement.data = {
    [0]={x = 2, y = 0},
    [1]={x=3,y=1, [3]={x=2,y=2}, [7]={x=1,y=1}},
    [2]={x = 0, y = 2},
    [3]={x=3,y=1, [1]={x=1,y=1},[5]={x=2,y=2}},
    [4]={x = 2, y = 0},
    [5]={x=3,y=1, [3]={x=1,y=1}, [7]={x=2,y=2}},
    [6]={x = 0, y = 2},
    [7]={x=3,y=1, [1]={x=2,y=2},[5]={x=1,y=1}},
}

--[[
curves from travel dir to travel dir:
0 3 - 4 0 - 7
1 5 - 4 0 - 1
2 5 - 6 2 - 1
3 7 - 6 2 - 3  
4 7 - 0 4 - 3
5 1 - 0 4 - 5
6 1 - 2 6 - 5
7 3 - 2 6 - 7
polePlacement.curveToDirs =
  {
    [0] = {"0347"},
    [1] ={"0145"} ,
    [2] ={"1256"} ,
    [3] ={"2367"} ,
    [4] ={"0347"} ,
    [5] ={"0145"} ,
    [6] ={"1265"} ,
    [7] ={"2367"}
    }
--]]
polePlacement.curves = {
    [0]={x=2,y=0},
    [1]={x=2,y=0},
    [2]={x=0,y=2},
    [3]={x=0,y=2},
    [4]={x=2,y=0},
    [5]={x=2,y=0},
    [6]={x=0,y=2},
    [7]={x=0,y=2}
  }
polePlacement.dir = {
    [0]={x = 1, y = 1},
    [1]={x = 1, y = 1},
    [2]={x = 1, y = 1},
    [3]={x = -1, y = 1},
    [4]={x = -1, y = 1},
    [5]={x = -1, y = -1},
    [6]={x = 1, y = -1},
    [7]={x = 1, y = -1}
}  

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
  local p2 = p2 or {x=0,y=0}
  return {x=p1.x+p2.x, y=p1.y+p2.y}
end

local function subPos(p1,p2)
  local p2 = p2 or {x=0,y=0}
  return {x=p1.x-p2.x, y=p1.y-p2.y}
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
    if not godmode then self:addItemToCargo("raw-wood", 1) end
  end
  self:pickupItems(pos, area)
  if removeStone then
    for _, entity in ipairs(game.findentitiesfiltered{area = area, name = "stone-rock"}) do
      entity.die()
    end
  end
end

function FARL:pickupItems(pos, area)
  for _, entity in ipairs(game.findentitiesfiltered{area = area, name="item-on-ground"}) do
    self:addItemToCargo(entity.stack.name, entity.stack.count)
    entity.destroy()
  end
end

function FARL:getRail(lastRail, travelDir, input)
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
end

function FARL:cruiseControl()
  if self.cruise then
    if self.train.speed < glob.cruiseSpeed then
      self.driver.ridingstate = {acceleration = 1, direction = self.driver.ridingstate.direction}
    else
      self.driver.ridingstate = {acceleration = 0, direction = self.driver.ridingstate.direction}
    end
  end
  if not self.cruise then
    self.driver.ridingstate = {acceleration = self.driver.ridingstate.acceleration, direction = self.driver.ridingstate.direction}
  end
end

function FARL:layRails()
  if self.active and self.lastrail and self.train then
    self.direction = self.direction or self:calcTrainDir()
    self:cruiseControl()
    self.acc = self.driver.ridingstate.acceleration
    if self.acc ~= 3 and util.distance(self.lastrail.position, self.locomotive.position) < 6 then
      self.input = self.driver.ridingstate.direction
      local dir, last = self:placeRails(self.lastrail, self.direction, self.input)
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
end

local function onTick(event)
  for i, farl in pairs(glob.farl) do
    if not farl.train.valid then
      farl.train = farl.locomotive.train
      farl:updateCargo()
      if not farl.train.valid then
        farl.driver.print("Invalid train")
        farl.deactivate()
      end
    else
      if event.tick % 60 == 0 then
        farl:updateCargo()
      end
      farl:layRails()
    end
  end
  if event.tick%10==9  then
    for pi, player in ipairs(game.players) do
      if (player.vehicle ~= nil and player.vehicle.name == "farl") then
        --if player.gui.left.farl and not player.gui.left.farl.rows then FARL.destroyGui(pi,player) end
        if player.gui.left.farl == nil then
          FARL.create(pi, player)
        end
      end
      if player.vehicle == nil and player.gui.left.farl ~= nil then
        FARL.remove(pi,player)
      end
    end
  end
end

local function initGlob()
  if glob.version == nil or glob.version < "0.1.1" then
    glob = {}
    if game.forces.player.technologies["rail-signals"].researched then
      game.forces.player.recipes["farl"].enabled = true
      glob.signals = true
      glob.poles = true
    end
    glob.settings = {}
    glob.version = "0.1.1"
  end
  glob.settings = glob.settings or {}
  glob.settings.poleDistance = glob.settings.poleDistance or 1
  glob.settings.poleSide = glob.settings.poleSide or 1
  glob.settings.signalDistance = glob.settings.signalDistance or 15
  glob.settings.curvedWeight = glob.settings.curvedWeight or 4
  if glob.signals == nil then
    glob.signals = true
  end
  if glob.poles == nil then
    glob.poles = true
  end
  glob.farl = glob.farl or {}
  glob.railInfoLast = glob.railInfoLast or {}
  glob.debug = glob.debug or {}
  glob.action = glob.action or {}
  glob.cruiseSpeed = glob.cruiseSpeed or 0.4
  for i,farl in pairs(glob.farl) do
    farl = resetMetatable(farl)
  end
  glob.version = "0.1.2"
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
    signalCount = 0, cruise = false, placeSignals = glob.signals,
    placePoles = glob.poles, curvedWeight = glob.settings.curvedWeight
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
  if player.gui.left.farl ~= nil then
    FARL.destroyGui(index,player)
  end
end

function FARL:activate()
  if self.active then self:deactivate() end
  self.lastrail = self:findLastRail()
  if self.lastrail then
    self:findLastPole()
    self:updateCargo()
    self.direction = self:calcTrainDir()
    if self.direction and self.lastPole and self.lastCheckPole then
      self.active = true
      self.driver.gui.left.farl.rows.buttons.start.caption="Stop"
    else
      self:deactivate()
      self.driver.print("Error activating, drive on straight rails and try again")
    end
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
  self.cruise = false
  self.driver.gui.left.farl.rows.buttons.start.caption="Start"
  self.driver.gui.left.farl.rows.buttons.cc.caption="Cruise"
end

function FARL.createGui(index, player)
  if player.gui.left.farl ~= nil then return end
  local f = findByPlayer(player)
  local caption = f.active and "Stop" or "Start"
  local captioncc = f.cruise and "Stop cruise" or "Cruise"
  local farl = player.gui.left.add({type="frame", direction="vertical", name="farl"})
  --farl.add({type="button", name="debug", caption="Debug Info"})
  local rows = farl.add({type="table", name="rows", colspan=1})
  local buttons = rows.add({type="table", name="buttons", colspan=3})
  buttons.add({type="button", name="start", caption=caption, style="farl_button"})
  buttons.add({type="button", name="cc", caption=captioncc, style="farl_button"})
  buttons.add({type="button", name="settings", caption="S", style="farl_button"})
  rows.add({type="checkbox", name="signals", caption="Place signals", state=glob.signals})
  rows.add({type="checkbox", name="poles", caption="Place poles", state=glob.poles})
end

function FARL.destroyGui(index,player)
  if player.gui.left.farl == nil then return end
  player.gui.left.farl.destroy()
end

function FARL:toggleSettingsWindow(index,player)
  local row = player.gui.left.farl.rows
  local captionSide
  if glob.settings.poleSide == 1 then
    captionSide = "right"
  else
    captionSide = "left"
  end
  if row.settings ~= nil then
    local s = row.settings
    local pDistance = tonumber(s.poleDistance.text) or glob.settings.poleDistance
    pDistance = pDistance < 0 and 1 or pDistance
    pDistance = pDistance >= 5 and 5 or pDistance
    local sDistance = tonumber(s.signalDistance.text) or glob.settings.signalDistance
    sDistance = sDistance < 0 and 0 or sDistance
    local weight = tonumber(s.curvedWeight.text) or glob.settings.curvedWeight
    weight = weight < 0 and 1 or weight
    self:saveSettings({poleDistance=pDistance, signalDistance=sDistance, curvedWeight=weight})
    player.gui.left.farl.rows.buttons.settings.caption="S"
    row.settings.destroy()
  else 
    local settings = row.add({type="table", name="settings", colspan=2})
    player.gui.left.farl.rows.buttons.settings.caption="Save settings"
    settings.add({type="label", caption="Distance between pole and rail", style="farl_label"})
    local pDistance = settings.add({type="textfield", name="poleDistance", style="farl_textfield_small"})
    settings.add({type="label", caption="Side of pole:", style="farl_label"})
    settings.add({type="button", name="side", caption=captionSide, style="farl_button"})
    settings.add({type="label", caption="Distance between rail signals", style="farl_label"})
    local sDistance = settings.add({type="textfield", name="signalDistance", style="farl_textfield_small"})
    settings.add({type="label", caption="Weight for curved rails", style="farl_label"})
    local weight = settings.add({type="textfield", name="curvedWeight", style="farl_textfield_small"})
    pDistance.text = glob.settings.poleDistance
    sDistance.text = glob.settings.signalDistance
    weight.text = glob.settings.curvedWeight
  end
end
function FARL.updateSettings(s)
  for i, farl in pairs(glob.farl) do
    farl.placePoles = glob.poles
    farl.placeSignals = glob.signals
    if s then
      farl.curvedWeight = s.curvedWeight
    end
  end 
end
function FARL:saveSettings(s)
  for i,p in pairs(s) do
    if glob.settings[i] then
      glob.settings[i] = p
    end
  end
  FARL.updateSettings(s)
end

function FARL.onGuiClick(event)
  local index = event.playerindex or event.name
  local player = game.players[index]
  if glob.version < "0.1.3" then
    FARL.destroyGui(index,player) 
    FARL.createGui(index,player)
    glob.version = "0.1.3"
    return
  end
  if player.gui.left.farl ~= nil then
    --local train = player.opened or player.vehicle
    local farl = findByPlayer(player)
    local name = event.element.name
    if farl then
      if name == "debug" then
        saveVar(glob,"debug")
        --glob.debug = {}
        --glob.action = {}
        farl:debugInfo()
      elseif name == "start" then
        if event.element.caption == "Start" then
          farl:activate()
          --FARL.debugInfo(player, farl.locomotive)
        else
          if player.vehicle.name == "farl" then
            farl:deactivate()
          end
        end
      elseif name == "settings" then
        farl:toggleSettingsWindow(index,player)
      elseif name == "side" then
        if event.element.caption == "right" then
          glob.settings.poleSide = -1
          event.element.caption = "left"
          return
        else
          glob.settings.poleSide = 1
          event.element.caption = "right"
          return
        end
      elseif name == "cc" then
        if event.element.caption == "Cruise" then
          if farl.driver and farl.driver.ridingstate then
            farl.cruise = true
            event.element.caption = "Stop cruise"
            local input = farl.input or 1
            farl.driver.ridingstate = {acceleration = 1, direction = input}
          end
          return
        else
          if farl.driver and farl.driver.ridingstate then
            farl.cruise = false
            event.element.caption = "Cruise"
            local input = farl.input or 1
            farl.driver.ridingstate = {acceleration = farl.driver.ridingstate.acceleration, direction = input}
          end
          return
        end
      elseif name == "signals" or name == "poles" then
        glob[name] = not glob[name]
        FARL.updateSettings()
      end
    else
      player.print("Gui without train, wrooong!")
      FARL.destroyGui(index,player)
    end
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
  if last.name == "curved-rail" then
    self.driver.print("Can't start on curved rails")
    return false
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
  local types = {"straight-rail", "curved-rail", "big-electric-pole", "rail-signal", "small-lamp"}
  for _,type in pairs(types) do
    self[type] = 0
    for i, wagon in ipairs(self.train.carriages) do
      if wagon.type == "cargo-wagon" then
        self[type] = self[type] + wagon.getinventory(1).getitemcount(type)      
      end
    end
  end  
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
        if self.placePoles then
          if godmodePoles or self["big-electric-pole"] > 0 then
            self:placePole(newTravelDir, nextRail)
          end
        end 
        if self.placeSignals then
          local signalWeight = nextRail.name == "curved-rail" and self.curvedWeight or 1
          self.signalCount = self.signalCount + signalWeight
          if godmodeSignals or self["rail-signal"] > 0 then
            if self:placeSignal(newTravelDir,nextRail) then self.signalCount = 0 end
          end
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

function FARL:calcPole(lastrail, traveldir)
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
end

function FARL:placeLamp(traveldir,pole)
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
end

function FARL:placePole(traveldir, lastrail)
  local tmp = {x=self.lastCheckPole.x,y=self.lastCheckPole.y}
  local area = {{tmp.x-30,tmp.y-30},{tmp.x+30,tmp.y+30}}
  local minDist, minPos = util.distance(tmp, self.lastPole), false
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
end

function FARL:placeSignal(traveldir, rail)
  if self.signalCount > glob.settings.signalDistance and rail.name ~= "curved-rail" then
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
      --self.driver.print("Can't place signal@"..pos2Str(pos))
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
    local offset = self:calcPole(self.lastrail, self:calcTrainDir())
    self.lastCheckPole = addPos(self.lastrail.position, offset)
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
local function onplayercreated(event)
  local player = game.getplayer(event.playerindex)
  local gui = player.gui
  if gui.top.farl ~= nil then
    gui.top.farl.destroy()
  end
end

game.onevent(defines.events.onplayercreated, onplayercreated)

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
    pos = pos
    color = color or RED
    game.createentity({name="flying-text", position=pos, text=line, color=color})
  end
end

--function setGhostDriver(locomotive)
--  local ghost = newGhostDriverEntity(game.player.position)
--  locomotive.passenger = ghost
--  return ghost
--end
--
--function newGhostDriverEntity(position)
--  game.createentity({name="farl_player", position=position, force=game.forces.player})
--  local entities = game.findentitiesfiltered({area={{position.x, position.y},{position.x, position.y}}, name="farl_player"})
--  if entities[1] ~= nil then
--    return entities[1]
--  end
--end
remote.addinterface("farl",
  {
    railInfo = function(rail)
      debugDump(rail.name.."@"..pos2Str(rail.position).." dir:"..rail.direction,true)
      if glob.railInfoLast.valid then
        local pos = glob.railInfoLast.position
        local diff={x=rail.position.x-pos.x, y=rail.position.y-pos.y}
        debugDump("Offset from last: x="..diff.x..",y="..diff.y,true)
      end
      glob.railInfoLast = rail
    end,
    debugInfo = function()
      saveVar(glob, "console")
      --saveVar(glob.debug, "RailDebug")
    end,
    reset = function()
      glob.farl = {}
      if game.forces.player.technologies["rail-signals"].researched then
        game.forces.player.recipes["farl"].enabled = true
      end
      for i,p in pairs(game.players) do
        if p.gui.left.farl then p.gui.left.farl.destroy() end
        if p.gui.top.farl then p.gui.top.farl.destroy() end
      end
      initGlob()
    end,
    godmode = function(bool)
      godmode = bool
      godmodePoles = bool
      godmodeSignals = bool
    end,
    setSpeed = function(speed)
      glob.cruiseSpeed = speed
    end
--    setDriver = function(loco)
--      if loco.name == "farl" then
--        driver = setGhostDriver(loco)
--        driver.ridingstate = {acceleration=1,direction=1}
--      end
--    end
  })
