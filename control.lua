require "defines"
require "FARL"
require "GUI"

godmode = false
godmodePoles = false
godmodeSignals = false
removeStone = true

--local direction ={ N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7}

input2dir = {[0]=-1,[1]=0,[2]=1}
-- inputToNewDir[oldDir][input] -> rail to new dir
--shift[lastCurveDir]
--connect[].direction[lastCurve]=required diag dir
--curve[lastCurve] -> pos, diag required -> diagDir
inputToNewDir =
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
clearAreas =
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

  polePlacement = {

      data = {
        [0]={x = 2, y = 0},
        [1]={x=3,y=1, [3]={x=2,y=2}, [7]={x=1,y=1}},
        [2]={x = 0, y = 2},
        [3]={x=3,y=1, [1]={x=1,y=1},[5]={x=2,y=2}},
        [4]={x = 2, y = 0},
        [5]={x=3,y=1, [3]={x=1,y=1}, [7]={x=2,y=2}},
        [6]={x = 0, y = 2},
        [7]={x=3,y=1, [1]={x=2,y=2},[5]={x=1,y=1}},
      },

      curves = {
        [0]={x=2,y=0},
        [1]={x=2,y=0},
        [2]={x=0,y=2},
        [3]={x=0,y=2},
        [4]={x=2,y=0},
        [5]={x=2,y=0},
        [6]={x=0,y=2},
        [7]={x=0,y=2}
      },

      dir = {
        [0]={x = 1, y = 1},
        [1]={x = 1, y = 1},
        [2]={x = 1, y = 1},
        [3]={x = -1, y = 1},
        [4]={x = -1, y = 1},
        [5]={x = -1, y = -1},
        [6]={x = 1, y = -1},
        [7]={x = 1, y = -1}
      }
  }
poleMedium = {
      data = {
        [0]={x = 1.5, y = 0.5},
        [1]={x=1.5,y=1.5, [3]={x=1.5,y=1.5}, [7]={x=0.5,y=0.5}},
        [2]={x = 0.5, y = 1.5},
        [3]={x=1.5,y=1.5, [1]={x=0.5,y=0.5},[5]={x=1.5,y=1.5}},
        [4]={x = 1.5, y = 0.5},
        [5]={x=1.5,y=1.5, [3]={x=0.5,y=0.5}, [7]={x=1.5,y=1.5}},
        [6]={x = 0.5, y = 1.5},
        [7]={x=1.5,y=1.5, [1]={x=1.5,y=1.5},[5]={x=0.5,y=0.5}},
      },

      curves = {
        [0]={x=1.5,y=0.5},
        [1]={x=1.5,y=0.5},
        [2]={x=0.5,y=1.5},
        [3]={x=0.5,y=1.5},
        [4]={x=1.5,y=0.5},
        [5]={x=1.5,y=0.5},
        [6]={x=0.5,y=1.5},
        [7]={x=0.5,y=1.5}
      },
      dir = {
        [0]={x = 1, y = -1},
        [1]={x = 1, y = 1},
        [2]={x = 1, y = 1},
        [3]={x = -1, y = 1},
        [4]={x = -1, y = 1},
        [5]={x = -1, y = -1},
        [6]={x = -1, y = -1},
        [7]={x = 1, y = -1}
      }
}  
  
--[traveldir] ={[raildir]
signalOffset =
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

function resetMetatable(o, mt)
  setmetatable(o,{__index=mt})
  return o
end

local function onTick(event)
  if event.tick % 10 == 0  then
    for pi, player in ipairs(game.players) do
      if (player.vehicle ~= nil and player.vehicle.name == "farl") then
        if player.gui.left.farl == nil then
          FARL.onPlayerEnter(player)
          GUI.createGui(player)
        end
      end
      if player.vehicle == nil and player.gui.left.farl ~= nil then
        FARL.onPlayerLeave(player)
        GUI.destroyGui(player)
      end
    end
  end
  for i, farl in ipairs(glob.farl) do
    farl:update(event)
    if farl.driver then
      GUI.updateGui(farl)
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
  if glob.medium == nil then
    glob.medium = false
  end
  if glob.signals == nil then
    glob.signals = true
  end
  if glob.poles == nil then
    glob.poles = true
  end
  if glob.flipSignals == nil then
    glob.flipSignals = false
  end
  glob.farl = glob.farl or {}
  glob.railInfoLast = glob.railInfoLast or {}
  glob.debug = glob.debug or {}
  glob.action = glob.action or {}
  glob.cruiseSpeed = glob.cruiseSpeed or 0.4
  for i,farl in ipairs(glob.farl) do
    farl = resetMetatable(farl, FARL)
    if glob.version < "0.1.4" then
      farl.cruiseInterrupt = 0
    end
    farl.index = nil
  end
  if glob.version < "0.1.4" then
    for i=1,#game.players do
      GUI.destroyGui(game.players[i])
    end
    glob.version = "0.1.4"
  end
  glob.version = "0.1.5"
end

local function oninit() initGlob() end

local function onload()
  initGlob()
end

local function onGuiClick(event)
  local index = event.playerindex or event.name
  local player = game.players[index]
  if player.gui.left.farl ~= nil then
    local farl = FARL.findByPlayer(player)
    if farl then
      GUI.onGuiClick(event, farl, player)
    else
      player.print("Gui without train, wrooong!")
      GUI.destroyGui(player)
    end
  end
end

function onpreplayermineditem(event)
  local ent = event.entity
  local cname = ent.name
  if ent.type == "locomotive" and cname == "farl" then
    for i=1,#glob.farl do
      if glob.farl[i].name == ent.backername then
        glob.farl[i].delete = true
      end
    end
  end  
end

function onplayermineditem(event)
  if event.itemstack.name == "farl" then
    for i=#glob.farl,1,-1 do
      if glob.farl[i].delete then
        table.remove(glob.farl, i)
      end
    end
  end  
end

game.oninit(oninit)
game.onload(onload)
game.onevent(defines.events.ontick, onTick)
game.onevent(defines.events.onguiclick, onGuiClick)
--game.onevent(defines.events.ontrainchangedstate, function(event) ontrainchangedstate(event) end)
game.onevent(defines.events.onplayermineditem, onplayermineditem)
game.onevent(defines.events.onpreplayermineditem, onpreplayermineditem)
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
        debugDump("Dist:"..util.distance(pos, rail.position),true)
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
      for i,p in ipairs(game.players) do
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
    end,
    
--    setDriver = function(loco)
--        if loco.name == "farl" then
--          local i = FARL.findByLocomotive(loco)
--          local farl = glob.farl[i]
--          driver = setGhostDriver(loco)
--          farl.driver = driver
--          godmode = true
--          farl:activate()
--          farl:toggleCruiseControl()
--          driver.ridingstate = {acceleration=1,direction=1}
--        end
--    end,
--    
--    removeDriver = function(loco)
--        if loco.name == "farl" and loco.vehicle.passenger.name == "farl_player" then
--          local i = FARL.findByLocomotive(loco)
--          glob.farl[i].driver = false
--          loco.vehicle.passenger = nil
--          driver.destroy()
--          driver = nil
--        end
--    end
  --/c local radius = 1024;game.forces.player.chart{{-radius, -radius}, {radius, radius}}
  })
