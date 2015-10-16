require "defines"
require "Settings"
require "FARL"
require "GUI"
require "migrate"


debugButton = false
godmode = false
removeStone = true

--local direction ={ N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7}

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
    direction = 7,
    poleEntities = {{name = "small-lamp", position = {x = -1.5, y = 1.5}}},
    pole = {name = "big-electric-pole", position = {x = 2.5, y = 2.5}},
    rails = {}, signals = {},
    boundingBox = {br = {x = 2.5, y = 4}, tl = {x = -1, y = 0}}}

  defaultsStraight = {
    direction = 0,
    poleEntities = {{name = "small-lamp", position = {x = -0.5, y = 1.5}}},
    pole = {name = "big-electric-pole", position = {x = 3, y = -1}},
    rails = {}, signals = {},
    boundingBox = {br = {x = 3, y = 0.5}, tl = {x = -0.5, y = -1}}}

  defaultsMediumDiagonal = {
    direction = 7,
    poleEntities = {{name = "small-lamp", position = {x = -1, y = 1}}},
    pole = {name = "medium-electric-pole", position = {x = 2, y = 2}},
    rails = {}, signals = {},
    boundingBox = {br = {x = 1, y = 4}, tl = {x = -2, y = 0}}}

  defaultsMediumStraight = {
    direction = 0,
    poleEntities = {{name = "small-lamp", position = {x = 0,y = 1}}},
    pole = {name = "medium-electric-pole", position = {x = 2.5,y = -0.5}},
    rails = {}, signals = {},
    boundingBox = {br = {x = 2.5, y = 0.5}, tl = {x = -1.5, y = -1}}}


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
    poleEntities = true,
    rail = rails.basic,
    signals = true,
    bridge = false,
    root = false,
    parallelTracks = true,
    parallelLag = 6,
    boundingBoxOffsets = {
      straight = {tl={x=-0.5,y=0},br={x=0,y=0}},
      diagonal = {tl={x=0,y=0},br={x=0.5,y=0.5}}}
  }
  defaultSettings.activeBP = defaultSettings.bp.big

  function resetMetatable(o, mt)
    setmetatable(o,{__index=mt})
    return o
  end

  local function onTick(event)
    local status, err = pcall(function()
      if global.destroyNextTick[event.tick] then
        local pis = global.destroyNextTick[event.tick]
        for _, pi in pairs(pis) do
          GUI.destroyGui(game.players[pi])
          debugDump("Gui destroyed (on tick)")
        end
        global.destroyNextTick[event.tick] = nil
      end
      for i, farl in pairs(global.farl) do
        if not farl.destroy then
          local status, err = pcall(function()
            farl:update(event)
            --            if game.tick % 30 == 0 and farl.train.valid then
            --              farl:flyingText2("FR->"..farl.train.rail_direction_from_front_rail,RED,true, farl.train.front_rail.position)
            --              farl:flyingText2("BR->"..farl.train.rail_direction_from_back_rail,RED,true, farl.train.back_rail.position)
            --              local n = farl.train.front_rail.get_connected_rail{rail_direction=0, rail_connection_direction=1}
            --              local p = farl.train.front_rail.get_connected_rail{rail_direction=1, rail_connection_direction=1}
            --              if n then
            --                farl:flyingText2("NR",RED,true, n.position)
            --              end
            --              if p then
            --                farl:flyingText2("PR",RED,true, p.position)
            --              end
            --            end
            if farl.driver and farl.driver.name ~= "farl_player" then
              GUI.updateGui(farl)
            end
          end)
          if not status then
            if farl and farl.active then
              farl:deactivate("Unexpected error: "..err)
            end
            debugDump("Unexpected error: "..err,true)
          end
        else
          if farl.destroy == event.tick then
            farl.destroy = false
            farl.settings = false
          end
        end
      end
    end)
    if not status then
      debugDump("Unexpected error:",true)
      debugDump(err,true)
    end
  end

  local function initGlob()

    if global.version == nil or global.version < "0.4.3" then
      global = {}
      global.version = "0.4.3"
    end
    global.players = global.players or {}
    global.savedBlueprints = global.savedBlueprints or {}
    global.farl = global.farl or {}
    global.railInfoLast = global.railInfoLast or {}
    global.electricInstalled = false
    if global.godmode == nil then global.godmode = false end
    godmode = global.godmode
    global.destroyNextTick = global.destroyNextTick or {}

    for i,farl in ipairs(global.farl) do
      farl = resetMetatable(farl, FARL)
    end
    for name, s in pairs(global.players) do
      s = resetMetatable(s,Settings)
    end

    global.version = "0.4.3"
  end

  local function oninit() initGlob() end

  local function onload()
    initGlob()
  end

  local function on_configuration_changed(data)
    --debugDump(data,true)
    if data.mod_changes.FARL and data.mod_changes.FARL.new_version == "0.4.3" then
      global.electricInstalled = false
    end
    if data.mod_changes["5dim_trains"] then
      --5dims_trains was added/updated
      if data.mod_changes["5dim_trains"].new_version then
        global.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
      else
        --5dims_trains was removed
        global.electricInstalled = false
      end
    end
    for name,s in pairs(global.players) do
      s:checkMods()
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
      FARL.onPlayerLeave(player, event.tick + 5)
      debugDump("onPlayerLeave (driving state changed)")
      local tick = event.tick + 5
      if not global.destroyNextTick[tick] then
        global.destroyNextTick[tick] = {}
      end
      table.insert(global.destroyNextTick[tick], event.player_index)
    end
  end

  script.on_init(oninit)
  script.on_load(onload)
  script.on_configuration_changed(on_configuration_changed)
  script.on_event(defines.events.on_tick, onTick)
  script.on_event(defines.events.on_gui_click, onGuiClick)
  --script.on_event(defines.events.on_train_changed_state, ontrainchangedstate)
  script.on_event(defines.events.on_player_mined_item, onplayermineditem)
  script.on_event(defines.events.on_preplayer_mined_item, onpreplayermineditem)
  --game.onevent(defines.events.on_built_entity, onbuiltentity)
  script.on_event(defines.events.on_entity_died, onentitydied)

  script.on_event(defines.events.on_player_driving_changed_state, onPlayerDrivingChangedState)

  local function onplayercreated(event)
    local player = game.get_player(event.player_index)
    local gui = player.gui
    if gui.top.farl ~= nil then
      gui.top.farl.destroy()
    end
  end

  script.on_event(defines.events.on_player_created, onplayercreated)

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
    local var = var or global
    local n = name or ""
    game.write_file("farl/farl"..n..".lua", serpent.block(var, {name="glob"}))
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
        saveVar(global, "console")
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
        local items = {"power-armor-mk2", "personal-roboport-equipment", "fusion-reactor-equipment",
          "blueprint", "deconstruction-planner", "construction-robot", "basic-exoskeleton-equipment"}
        local count = {1,5,3,1,1,50,2}
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
      end,

      setBoundingBox = function(type, corner, x,y, player)
        local player = player
        if not player then player = game.players[1] end
        local psettings = Settings.loadByPlayer(player)
        if psettings then
          local bb = psettings.boundingBoxOffsets[type][corner]
          local x = x and x or bb.x
          local y = y and y or bb.y
          psettings.boundingBoxOffsets[type][corner] = {x=x,y=y}
        end
      end,
    })
