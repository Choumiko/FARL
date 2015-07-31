require "defines"
require "Settings"
require "FARL"
require "GUI"
require "migrate"


debugButton = false
godmode = false
removeStone = true

--local direction ={ N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7}
electricInstalled = (game.entity_prototypes["straight-power-rail"] and remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated) and true or false

cargoTypes = { ["straight-rail"] = true, ["curved-rail"] = true,["rail-signal"] = true,
  ["big-electric-pole"] = true, ["medium-electric-pole"] = true, ["small-lamp"] = true,
  ["green-wire"] = true, ["red-wire"] = true
}

if electricInstalled then
  cargoTypes["straight-power-rail"] = true
  cargoTypes["curved-power-rail"] = true
end

rails = {
  basic = {curved = "curved-rail", straight = "straight-rail"},
  electric = {curved = "curved-power-rail", straight = "straight-power-rail"}}

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
clearAreas = {
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
  --poleDistance = 1, side = right
  defaultsDiagonal = {
    direction = 3,
    poleEntities = {{name = "small-lamp", position = {x = -1.5, y = 1.5}}},
    pole = {name = "big-electric-pole", position = {x = 2.5, y = 2.5}}
  }

  defaultsStraight = {
    direction = 0,
    poleEntities = {{name = "small-lamp", position = {x = -0.5, y = 1.5}}},
    pole = {name = "big-electric-pole", position = {x = 3, y = 0}}
  }

  defaultsMediumDiagonal = {
    direction = 7,
    poleEntities = {{name = "small-lamp", position = {x = -1, y = 1}}},
    pole = {name = "medium-electric-pole", position = {x = 2, y = 2}}
  }

  defaultsMediumStraight = {
    direction = 0,
    poleEntities = {{name = "small-lamp", position = {x = 0,y = 1}}},
    pole = {name = "medium-electric-pole", position = {x = 2.5,y = -0.5}}
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

  defaultSettings = {
    activeBP = {},
    bp = {
      medium= {diagonal=defaultsMediumDiagonal, straight=defaultsMediumStraight},
      big=    {diagonal=defaultsDiagonal, straight=defaultsStraight}},
    ccNet = false,
    ccWires = 1,
    collectWood = true,
    curvedWeight = 4,
    cruiseSpeed = 0.4,
    dropWood = true,
    electric = false,
    flipPoles = false,
    flipSignals = false,
    signalDistance = 15,
    medium = false,
    minPoles = true,
    poles = true,
    rail = rails.basic,
    signals = true,
    bridge = false,
    root = false
  }
  defaultSettings.activeBP = defaultSettings.bp.big

  function resetMetatable(o, mt)
    setmetatable(o,{__index=mt})
    return o
  end

  local function onTick(event)
    for i, farl in ipairs(global.farl) do
      farl:update(event)
      if farl.driver and farl.driver.name ~= "farl_player" then
        GUI.updateGui(farl)
      end
    end
  end

  local function initGlob()
    if global.version == nil or global.version < "0.3.0" then
      global = {}
      global.version = "0.0.0"
    end
    global.players = global.players or {}
    global.savedBlueprints = global.savedBlueprints or {}
    global.farl = global.farl or {}
    global.railInfoLast = global.railInfoLast or {}
    if global.godmode == nil then global.godmode = false end
    godmode = global.godmode
    for i,farl in ipairs(global.farl) do
      farl = resetMetatable(farl, FARL)
    end
    for name, s in pairs(global.players) do
      s = resetMetatable(s,Settings)
      s:checkMods()
    end
--    if global.version < "0.3.1" then
--      for _, s in pairs(global.players) do
--        s.signalDistance = s.signalDistance * 2
--        s.curvedWeight = s.curvedWeight * 2
--      end
--      global.version = "0.3.1"
--    end
    global.version = "0.3.0"
  end

  local function oninit() initGlob() end

  local function onload()
    initGlob()
    for i,f in pairs(global.farl) do
      if f.driver and f.driver.gui.left.farl then
        --GUI.destroyGui(f.driver)
        --GUI.createGui(f.driver)
      end
    end
  end

  local function onGuiClick(event)
    local index = event.player_index
    local player = game.players[index]
    if player.gui.left.farl ~= nil then --and player.gui.left.farlAI == nil then
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
      for i=1,#global.farl do
        if global.farl[i].name == ent.backer_name then
          global.farl[i].delete = true
        end
      end
    end
  end

  function onplayermineditem(event)
    if event.item_stack.name == "farl" then
      for i=#global.farl,1,-1 do
        if global.farl[i].delete then
          table.remove(global.farl, i)
        end
      end
    end
  end

  function onentitydied(event)
    local ent = event.entity
    if ent.type == "locomotive" and ent.name == "farl" then
      local i = FARL.findByLocomotive(event.entity)
      if i then
        table.remove(global.farl, i)
      end
    end
  end

  function onPlayerDrivingChangedState(event)
    local player = game.players[event.player_index]
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

  game.on_init(oninit)
  game.on_load(onload)
  game.on_event(defines.events.on_tick, onTick)
  game.on_event(defines.events.on_gui_click, onGuiClick)
  --game.on_event(defines.events.on_train_changed_state, ontrainchangedstate)
  game.on_event(defines.events.on_player_mined_item, onplayermineditem)
  game.on_event(defines.events.on_preplayer_mined_item, onpreplayermineditem)
  --game.onevent(defines.events.on_built_entity, onbuiltentity)
  game.on_event(defines.events.on_entity_died, onentitydied)

  game.on_event(defines.events.on_player_driving_changed_state, onPlayerDrivingChangedState)

  local function onplayercreated(event)
    local player = game.get_player(event.player_index)
    local gui = player.gui
    if gui.top.farl ~= nil then
      gui.top.farl.destroy()
    end
  end

  game.on_event(defines.events.on_player_created, onplayercreated)

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
  end

  --  driverNextDir = 1
  --
  --  function setGhostDriver(locomotive)
  --    local ghost = newGhostDriverEntity(game.player.position)
  --    locomotive.passenger = ghost
  --    return ghost
  --  end
  --
  --  function newGhostDriverEntity(position)
  --    game.createentity({name="farl_player", position=position, force=game.forces.player})
  --    local entities = game.findentitiesfiltered({area={{position.x, position.y},{position.x, position.y}}, name="farl_player"})
  --    if entities[1] ~= nil then
  --      return entities[1]
  --    end
  --  end

  remote.add_interface("farl",
    {
      railInfo = function(rail)
        debugDump(rail.name.."@"..pos2Str(rail.position).." dir:"..rail.direction,true)
        if type(global.railInfoLast) == "table" and global.railInfoLast.valid then
          local pos = global.railInfoLast.position
          local diff={x=rail.position.x-pos.x, y=rail.position.y-pos.y}
          debugDump("Offset from last: x="..diff.x..",y="..diff.y,true)
          debugDump("Distance (util): "..util.distance(pos, rail.position),true)
          if AStar then
            local max = AStar.heuristic(global.railInfoLast, rail)
            debugDump("Distance (heuristic): "..max, true)
          end
          global.railInfoLast = false
        else
          global.railInfoLast = rail
        end
      end,
      debugInfo = function()
        saveVar(glob, "console")
        --saveVar(global.debug, "RailDebug")
      end,
      reset = function()
        global.farl = {}
        if game.forces.player.technologies["rail-signals"].researched then
          game.forces.player.recipes["farl"].enabled = true
        end
        for i,p in ipairs(game.players) do
          if p.gui.left.farl then p.gui.left.farl.destroy() end
          if p.gui.top.farl then p.gui.top.farl.destroy() end
        end
        initGlob()
      end,

      setCurvedWeight = function(weight, player)
        local w = tonumber(weight) or 4
        local s = Settings.loadByPlayer(player)
        s.curvedWeight = weight
      end,

      godmode = function(bool)
        global.godmode = bool
        godmode = bool
      end,
      setSpeed = function(speed)
        for name, s in pairs(global.players) do
          s.cruiseSpeed = speed
        end
      end,

      tileAt = function(x,y)
        debugDump(game.get_tile(x, y).name,true)
      end,

      quickstart = function()
        local items = {"farl", "curved-rail", "straight-rail", "medium-electric-pole", "big-electric-pole",
          "small-lamp", "solid-fuel", "rail-signal", "blueprint", "cargo-wagon"}
        local count = {5,50,50,50,50,50,50,50,10,5}
        for i=1,#items do
          game.player.insert{name=items[i], count=count[i]}
        end
      end,
            quickstart2 = function()
        local items = {"basic-modular-armor", "personal-roboport-equipment", "solar-panel-equipment",
          "blueprint", "deconstruction-planner", "battery-equipment", "construction-robot"}
        local count = {1,1,7,1,1,7,10}
        for i=1,#items do
          game.player.insert{name=items[i], count=count[i]}
        end
      end,

      quickstartElectric = function()
        local items = {"farl", "curved-power-rail", "straight-power-rail", "medium-electric-pole", "big-electric-pole",
          "small-lamp", "solid-fuel", "rail-signal", "blueprint", "electric-locomotive", "solar-panel", "basic-accumulator"}
        local count = {5,50,50,50,50,50,50,50,10,2,50,50}
        for i=1,#items do
          game.player.insert{name=items[i], count=count[i]}
        end
      end,

      wagons = function()
        for i,w in ipairs(game.player.selected.train.carriages) do
          debugDump({i=i,type=w.type},true)
        end
      end
    })
