require "defines"
require "Settings"
require "FARL"
require "GUI"

MOD_NAME = "FARL"
debugButton = false
godmode = false
removeStone = true

function resetMetatable(o, mt)
  setmetatable(o,{__index=mt})
  return o
end

function setMetatables()
  for i,farl in pairs(global.farl) do
    farl = resetMetatable(farl, FARL)
  end
  for name, s in pairs(global.players) do
    s = resetMetatable(s,Settings)
  end
end

local function getMetaItemData()
  game.forces.player.recipes["farl-meta"].reload()
  local metaitem = game.forces.player.recipes["farl-meta"].ingredients
  global.electric_poles = {}
  for i, ent in pairs(metaitem) do
    global.electric_poles[ent.name] = ent.amount/10
  end
end

local function on_tick(event)
  local status, err = pcall(function()
    if global.overlayStack and global.overlayStack[event.tick] then
      local tick = event.tick
      for _, overlay in pairs(global.overlayStack[tick]) do
        if overlay.valid then
          overlay.destroy()
        end
      end
      global.overlayStack[event.tick] = nil
    end
    if global.destroyNextTick[event.tick] then
      local pis = global.destroyNextTick[event.tick]
      for _, pi in pairs(pis) do
        GUI.destroyGui(game.players[pi])
        debugDump("Gui destroyed (on tick)")
      end
      global.destroyNextTick[event.tick] = nil
    end
    for i, farl in pairs(global.farl) do
      if not farl.destroy and farl.driver and farl.driver.valid then
        local status, err = pcall(function()
          farl:update(event)
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

local function init_global()
  global.players =  global.players or {}
  global.savedBlueprints = global.savedBlueprints or {}
  global.farl = global.farl or {}
  global.railInfoLast = global.railInfoLast or {}
  global.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
  global.godmode = false
  godmode = global.godmode
  global.destroyNextTick = global.destroyNextTick or {}
  global.overlayStack = global.overlayStack or {}
  global.statistics = global.statistics or {}
  global.electric_poles = global.electric_poles or {}
  global.version = global.version or "0.4.41"
  setMetatables()
end

local function init_player(player)
  Settings.loadByPlayer(player)
  global.savedBlueprints[player.name] = global.savedBlueprints[player.name] or {} 
end

local function init_players()
  for i,player in pairs(game.players) do
    init_player(player)
  end
end

local function init_force(force)
  global.statistics[force.name] = global.statistics[force.name] or {created={}, removed={}} 
end

local function init_forces()
  for _, f in pairs(game.forces) do
    init_force(f)
  end
end

local function on_init()
  init_global()
  init_forces()
  init_players()
end

local function on_load()
  setMetatables()
  godmode = global.godmode
  global.overlayStack = global.overlayStack or {}
end

local function on_configuration_changed(data)
  if not data or not data.mod_changes then
    return
  end
  if data.mod_changes[MOD_NAME] then
    local newVersion = data.mod_changes[MOD_NAME].new_version
    local oldVersion = data.mod_changes[MOD_NAME].old_version
    if oldVersion then
      debugDump("FARL version changed from "..oldVersion.." to "..newVersion,true)
      if oldVersion > newVersion then
        debugDump("Downgrading FARL, reset settings",true)
        global = {}
      end
    else
      debugDump("FARL version: "..newVersion,true)
    end
    if oldVersion and oldVersion < "0.5.11" then
      global = {}
    end
    on_init()
    global.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
    global.version = "0.5.11"
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
  --some mod changed, readd poles
  getMetaItemData()
  setMetatables()
  for name,s in pairs(global.players) do
    s:checkMods()
  end
end

local function on_player_created(event)
  init_player(game.players[event.player_index])
end

local function on_force_created(event)
  init_force(event.force)
end

local function on_gui_click(event)
  local status, err = pcall(function()
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
  end)
  if not status then
    debugDump("Unexpected error:",true)
    debugDump(err,true)
  end
end

function on_preplayer_mined_item(event)
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

function on_player_mined_item(event)
  if event.item_stack.name == "farl" then
    for i=#global.farl,1,-1 do
      if global.farl[i].delete then
        table.remove(global.farl, i)
      end
    end
  end
end

function on_entity_died(event)
  local ent = event.entity
  if ent.type == "locomotive" and ent.name == "farl" then
    local i = FARL.findByLocomotive(event.entity)
    if i then
      table.remove(global.farl, i)
    end
  end
end

function on_player_driving_changed_state(event)
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

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_force_created, on_force_created)

script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_gui_click, on_gui_click)
--script.on_event(defines.events.on_train_changed_state, ontrainchangedstate)
script.on_event(defines.events.on_player_mined_item, on_player_mined_item)
script.on_event(defines.events.on_preplayer_mined_item, on_preplayer_mined_item)
--script.on_event(defines.events.on_built_entity, onbuiltentity)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

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
      debugDump(rail.name.."@"..pos2Str(rail.position).." dir:"..rail.direction.." realPos:"..pos2Str(diagonal_to_real_pos(rail)),true)
      if type(global.railInfoLast) == "table" and global.railInfoLast.valid then
        local pos = global.railInfoLast.position
        local diff=subPos(rail.position,pos)
        local rdiff = subPos(diagonal_to_real_pos(rail),diagonal_to_real_pos(global.railInfoLast))
        debugDump("Offset from last: x="..diff.x..",y="..diff.y,true)
        debugDump("real Offset: x="..rdiff.x..",y="..rdiff.y,true)
        debugDump("Distance (util): "..util.distance(pos, rail.position),true)
        --debugDump("lag for diag: "..(diff.x-diff.y),true)
        --debugDump("lag for straight: "..(diff.y+diff.x),true)
        if AStar then
          local max = AStar.heuristic(global.railInfoLast, rail)
          debugDump("Distance (heuristic): "..max, true)
        end
        global.railInfoLast = false
      else
        global.railInfoLast = rail
      end
    end,
    --/c remote.call("farl", "debugInfo")
    debugInfo = function()
      saveVar(global, "console")
      --saveVar(global.debug, "RailDebug")
    end,
    reset = function()
      global = {}
      if game.forces.player.technologies["rail-signals"].researched then
        game.forces.player.recipes["farl"].enabled = true
      end
      for i,p in ipairs(game.players) do
        if p.gui.left.farl then p.gui.left.farl.destroy() end
        if p.gui.top.farl then p.gui.top.farl.destroy() end
      end
      init_global()
      init_forces()
      init_players()
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

    createCurve = function(direction, input, curve, s_lane, d_lane)
      local player = game.players[1]
      local surface = player.surface

      local original_dir = direction
      -- invert direction, input, distances for diagonal rails
      if direction%2 == 1 then
        local input2dir = {[0]=-1,[1]=0,[2]=1}
        direction = oppositedirection((direction+input2dir[input]) % 8)
        input = input == 2 and 0 or 2
        s_lane = -1*s_lane
        d_lane = -1*d_lane
      end

      local new_curve = {name=curve.name, type=curve.type, direction=curve.direction, force=curve.force}
      local right = s_lane*2

      --left hand turns need to go back, moving right already moves the diagonal rail part
      local forward = input == 2 and (s_lane-d_lane)*2 or (d_lane-s_lane)*2
      debugDump("r:"..right.."f:"..forward,true)
      new_curve.position = move_right_forward(curve.position, direction, right, forward)
      local s_lag = forward/2
      local d_lag = original_dir % 2 == 0 and forward+right or (forward+right)/2
      local data = {s_lag=s_lag, d_lag=d_lag}
      debugDump(data,true)
      local ent = surface.create_entity(new_curve)
      local diff = subPos(ent.position,new_curve.position)
      if diff.x~=0 or diff.y~=0 then
        debugDump("Placement mismatch:",true)
        debugDump(diff,true)
      end
    end,
    
    timing = function(player)
      local area_large = expandPos(player.position,50)
      local area_small = expandPos(player.position,10)
      log("find_entities large")
      for i=1,1000 do
        player.surface.find_entities_filtered{area = area_large, type = "tree"}
      end
      log("large finished")
      log("find_entities small")
      for i=1,1000 do
        player.surface.find_entities_filtered{area = area_small, type = "tree"}
      end
      log("small finished")
    end,
    
    place_signal = function(rail, travel_dir, end_of_rail)
      local signal = get_signal_for_rail(rail, travel_dir, end_of_rail)
      signal.force  = rail.force
      rail.surface.create_entity(signal)
    end
  })
