require "Settings"
require "FARL"
require "GUI"

MOD_NAME = "FARL"
debugButton = false
godmode = false

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

local concrete_lookup = {["stone-brick"] = "stone-path"}

local function getMetaItemData()
  game.forces.player.recipes["farl-meta"].reload()
  local metaitem = game.forces.player.recipes["farl-meta"].ingredients
  global.electric_poles = {}
  for i, ent in pairs(metaitem) do
    global.electric_poles[ent.name] = ent.amount/10
  end
end

function isFARLLocomotive(loco)
  if not loco or not loco.valid or not loco.type == "locomotive" then
    return false
  end
  if loco.name == "farl" then
    return true
  end
  if loco.grid then
    for _, equipment in pairs(loco.grid.equipment) do
      if equipment.name == "farl-roboport" then
        return true
      end
    end
  end
  return false
end

local function on_player_opened(entity, player)
  if isFARLLocomotive(entity) then
    if player.gui.left.farl == nil then
      local farl = FARL.findByLocomotive(entity)
      farl.openedBy = player
      FARL.onPlayerEnter(player, entity)
      GUI.createGui(player, entity)
    end
  end
end

local function on_player_closed(entity, player)
  if player.vehicle == nil and player.gui.left.farl ~= nil then
    local farl = FARL.findByLocomotive(entity)
    if farl then
      if farl.openedBy == player then
        farl.openedBy = nil
      end
      if farl.driver == player then
        farl.driver = false
      end
    end
    GUI.destroyGui(player, entity)
  end
end

local function on_tick(event)
  local status, err = pcall(function()
    --    if event.tick % 10 == 8  then
    --      global.player_opened = global.player_opened or {}
    --      for _, player in pairs(game.connected_players) do
    --        if player.opened ~= nil and player.opened.type == "locomotive" and not global.player_opened[player.index] then
    --          on_player_opened(player.opened, player)
    --          global.player_opened[player.index] = player.opened
    --        end
    --        if global.player_opened[player.index] and player.opened == nil then
    --          on_player_closed(global.player_opened[player.index], player)
    --          global.player_opened[player.index] = nil
    --        end
    --      end
    --    end

    if global.overlayStack and global.overlayStack[event.tick] then
      for _, overlay in pairs(global.overlayStack[event.tick]) do
        if overlay.valid then
          overlay.destroy()
        end
      end
      global.overlayStack[event.tick] = nil
    end

    for i, farl in pairs(global.farl) do
      if farl.driver and farl.driver.valid then
        local status, err = pcall(function()
          if farl:update(event) then
            GUI.updateGui(farl)
          end
        end)
        if not status then
          if farl and farl.active then
            farl:deactivate("Unexpected error: "..err)
          end
          debugDump("Unexpected error: "..err,true)
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
  global = global or {}
  global.players =  global.players or {}
  global.savedBlueprints = global.savedBlueprints or {}
  global.farl = global.farl or {}
  global.activeFarls = global.activeFarls or {}
  global.railInfoLast = global.railInfoLast or {}
  global.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
  global.godmode = false
  godmode = global.godmode
  global.overlayStack = global.overlayStack or {}
  global.statistics = global.statistics or {}
  global.electric_poles = global.electric_poles or {}
  global.trigger_events = global.trigger_events or {}
  global.version = global.version or "0.5.35"
  if global.debug_log == nil then
    global.debug_log = false
  end
  setMetatables()
end

local function init_player(player)
  Settings.loadByPlayer(player)
  global.savedBlueprints[player.index] = global.savedBlueprints[player.index] or {}
end

local function init_players()
  for i,player in pairs(game.players) do
    init_player(player)
  end
end

local function init_force(force)
  if not global.statistics then
    init_global()
  end
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
  setMetatables()
  getMetaItemData()
end

local function on_load()
  setMetatables()
  godmode = global.godmode
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
        on_init()
      else
        if oldVersion < "0.5.13" then
          debugDump("Reset settings",true)
          global = {}
        end
        on_init()
        if oldVersion > "0.5.13" then
          if oldVersion < "0.5.19" then
            for name, p_settings in pairs(global.players) do
              if p_settings.bulldozer == nil then p_settings.bulldozer = false end
              if p_settings.maintenance == nil then p_settings.maintenance = false end
              if p_settings.root ~= nil then p_settings.root = nil end
              if p_settings.flipSignals ~= nil then p_settings.flipSignals = nil end
            end
            for i, farl in pairs(global.farl) do
              if farl.bulldozer ~= nil then farl.bulldozer = nil end
              if farl.maintenance ~= nil then farl.maintenance = nil end
              farl.protected_tiles = {}
              farl.curveBP = nil
              farl.name = nil
              farl:deactivate()
              if farl.driver and farl.driver.valid then
                GUI.destroyGui(farl.driver)
                GUI.createGui(farl.driver)
              end
            end
          end
          if oldVersion < "0.5.21" then
            local tmp = {}
            local tmpBps = {}
            for i,player in pairs(game.players) do
              if global.players[player.name] then
                tmp[player.index] = global.players[player.name]
                global.players[player.name] = nil
              end
              if global.savedBlueprints[player.name] then
                tmpBps[player.index] = global.savedBlueprints[player.name]
                global.savedBlueprints[player.name] = nil
              end
            end
            global.players = tmp
            global.savedBlueprints = tmpBps
          end

          if oldVersion < "0.5.24" then
            global.overlayStack = global.overlayStack or {}
            for i=#global.farl, 1, -1 do
              local farl = global.farl[i]
              if not farl.train or (farl.train and not farl.train.valid) then
                if farl.driver and farl.driver.valid then
                  GUI.destroyGui(farl.driver)
                end
                farl:deactivate()
                table.remove(global.farl, i)
              end
            end
          end

          if oldVersion < "0.5.26" then
            for _, psettings in pairs(global.players) do
              if psettings.mirrorConcrete == nil then
                psettings.mirrorConcrete = true
              end
            end
          end

          if oldVersion < "0.5.35" then
            global.concrete = nil
            global.tiles = nil
          end

          if oldVersion < "0.5.36" then
            for _, psettings in pairs(global.players) do
              if psettings.wooden == nil then
                psettings.wooden = false
              end
            end
          end

          if oldVersion < "0.6.1" then
            local newFarls = {}
            if global.farl then
              for _, farl in pairs(global.farl) do
                farl = resetMetatable(farl, FARL)
                if farl.active then
                  farl:deactivate("Updating FARL")
                end
                if farl.locomotive and farl.locomotive.valid then
                  newFarls[farl.locomotive.unit_number] = farl
                end
              end
              global.farl = newFarls
            end
          end

          if oldVersion < "0.7.1" then
            if global.destroyNextTick then
              for _, pis in pairs(global.destroyNextTick) do
                for _, pi in pairs(pis) do
                  GUI.destroyGui(game.players[pi])
                end
              end
              global.destroyNextTick = nil
            end
            init_global()
            if global.farl then
              for id, farl in pairs(global.farl) do
                if not farl.driver then
                  farl.settings = false
                end
                farl.openedBy = nil
                farl.destroy = nil
                if farl.active or farl.driver then
                  global.activeFarls[id] = farl
                end
                saveVar(global)
              end
            end
          end
        end
      end
    else
      debugDump("FARL version: "..newVersion,true)
    end
    on_init()
    global.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
    global.version = newVersion
  end
  for name, _ in pairs(global.trigger_events) do
    if not game.entity_prototypes[name] then
      global.trigger_events[name] = nil
    end
  end
  --  if remote.interfaces["satellite-uplink"] and remote.interfaces["satellite-uplink"].add_allowed_item then
  --    log("registered")
  --    remote.call("satellite-uplink", "add_allowed_item", "rail")
  --    remote.call("satellite-uplink", "add_item", "rail", 1)
  --  end
  if data.mod_changes["5dim_trains"] then
    --5dims_trains was added/updated
    if data.mod_changes["5dim_trains"].new_version then
      global.electricInstalled = remote.interfaces.dim_trains and remote.interfaces.dim_trains.railCreated
    else
      --5dims_trains was removed
      global.electricInstalled = false
    end
  end
  --some mod changed, readd poles, concrete
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
    if player.gui.left.farl ~= nil then
      local farl = FARL.findByPlayer(player)
      if farl then
        GUI.onGuiClick(event, farl, player)
        GUI.updateGui(farl)
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
  if ent.type == "locomotive" or ent.type == "cargo-wagon" then
    for i, farl in pairs(global.farl) do
      if not farl.train or (farl.train.valid and farl.train == ent.train) or not farl.train.valid then
        global.farl[i]:deactivate()
        global.farl[i] = nil
      end
    end
  end
end

function on_entity_died(event)
  on_preplayer_mined_item(event)
end

function on_player_driving_changed_state(event)
  local player = game.players[event.player_index]
  if isFARLLocomotive(player.vehicle) then
    if player.gui.left.farl == nil then
      local farl = FARL.onPlayerEnter(player)
      GUI.createGui(player)
      if farl then
        GUI.updateGui(farl)
      end
    end
  end
  if player.vehicle == nil and player.gui.left.farl ~= nil then
    FARL.onPlayerLeave(player)
    debugDump("onPlayerLeave (driving state changed)")
    GUI.destroyGui(player)
  end
end

--function on_player_placed_equipment(event)
--  local player = game.players[event.player_index]
--  if event.equipment.name == "farl-roboport" and isFARLLocomotive(player.vehicle) then
--    if player.gui.left.farl == nil then
--      FARL.onPlayerEnter(player)
--      GUI.createGui(player)
--    end
--  end
--end
--
--function on_player_removed_equipment(event)
--  local player = game.players[event.player_index]
--  if event.equipment.name == "farl-roboport" and player.gui.left.farl and player.vehicle then
--    if not isFARLLocomotive(player.vehicle) then
--      FARL.onPlayerLeave(player, event.tick + 5)
--      log("onPlayerLeave (equipment changed)")
--      local tick = event.tick + 5
--      if not global.destroyNextTick[tick] then
--        global.destroyNextTick[tick] = {}
--      end
--      table.insert(global.destroyNextTick[tick], event.player_index)
--    end
--  end
--end

function debugDump(var, force)
  if false or force then
    local msg
    if type(var) == "string" then
      msg = var
    else
      msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
    end
    for i,player in pairs(game.players) do
      player.print(msg)
    end
    local tick = game and game.tick or 0
    log(tick .. " " .. msg)
  end
end

function debugLog(var, prepend)
  if not global.debug_log then return end
  local str = prepend or ""
  for i,player in pairs(game.players) do
    local msg
    if type(var) == "string" then
      msg = var
    else
      msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
    end
    player.print(str..msg)
    log(str..msg)
  end
end

function saveVar(var, name)
  var = var or global
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

script.on_event(defines.events.on_preplayer_mined_item, on_preplayer_mined_item)
script.on_event(defines.events.on_entity_died, on_entity_died)

script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)

--script.on_event(defines.events.on_player_placed_equipment, on_player_placed_equipment)
--script.on_event(defines.events.on_player_removed_equipment, on_player_removed_equipment)

script.on_event("toggle-train-control", function(event)
  if not game.active_mods["Honk"] then
    local vehicle = game.players[event.player_index].vehicle
    if vehicle and vehicle.type == "locomotive" then
      vehicle.train.manual_mode = not vehicle.train.manual_mode
    end
  end
end)

--when Player is in a FARL and used FatController to switch to another train
function on_player_switched(event)
  local status, err = pcall(function()
    if isFARLLocomotive(event.carriage) then
      local farl = FARL.findByLocomotive(event.carriage)
      if farl then
        farl:deactivate()
      end
    end
  end)
  if not status then
    debugDump("Unexpected error:",true)
    debugDump(err,true)
  end
end

if remote.interfaces.fat and remote.interfaces.fat.get_player_switched_event then
  script.on_event(remote.call("fat", "get_player_switched_event"), on_player_switched)
end

remote.add_interface("farl",
  {
    railInfo = function(rail)
      rail = rail or game.player.selected
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
        game.forces.player.recipes["farl-roboport"].enabled = true
      end
      for i,p in pairs(game.players) do
        if p.gui.left.farl then p.gui.left.farl.destroy() end
        if p.gui.top.farl then p.gui.top.farl.destroy() end
      end
      on_init()
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

    quickstart = function(player)
      local items = {"farl", "straight-rail", "medium-electric-pole", "big-electric-pole",
        "small-lamp", "solid-fuel", "rail-signal", "blueprint", "cargo-wagon"}
      local count = {5,100,50,50,50,50,50,10,5}
      player = player or game.player
      for i=1,#items do
        player.insert{name=items[i], count=count[i]}
      end
    end,
    quickstart2 = function(player)
      local items = {"power-armor-mk2", "personal-roboport-equipment", "fusion-reactor-equipment",
        "blueprint", "deconstruction-planner", "construction-robot", "exoskeleton-equipment"}
      local count = {1,5,3,1,1,50,2}
      player = player or game.player
      for i=1,#items do
        player.insert{name=items[i], count=count[i]}
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

    place_signal = function(rail, travel_dir, end_of_rail)
      local signal = get_signal_for_rail(rail, travel_dir, end_of_rail)
      signal.force  = rail.force
      rail.surface.create_entity(signal)
    end,

    debuglog = function()
      global.debug_log = not global.debug_log
      local state = global.debug_log and "on" or "off"
      debugDump("Debug: "..state,true)
    end,

    revive = function(player)
      for _, entity in pairs(player.surface.find_entities_filtered{area = expandPos(player.position,50), type = "entity-ghost"}) do
        entity.revive()
      end
    end,

    tile_properties = function(player)
      local x = player.position.x
      local y = player.position.y
      local tile = player.surface.get_tile(x,y)
      local tprops = player.surface.get_tileproperties(x,y)
      player.print(tile.name)
      local properties = {
        tierFromStart = tprops.tier_from_start,
        roughness = tprops.roughness,
        elevation = tprops.elevation,
        availableWater = tprops.available_water,
        temperature = tprops.temperature
      }
      for k,v in pairs(properties) do
        player.print(k.." "..v)
      end
    end,

    fake_signals = function(bool)
      global.fake_signals = bool
    end,

    init_players = function()
      for _, psettings in pairs(global.players) do
        if psettings.mirrorConcrete == nil then
          psettings.mirrorConcrete = true
        end
      end
    end,

    tiles = function()
      for tileName, prototype in pairs(game.tile_prototypes) do
        if prototype.items_to_place_this then
          log("Tile: " .. tileName .." item: " .. next(prototype.items_to_place_this))
        end
      end
    end,

    add_entity_to_trigger = function(name)
      global.trigger_events = global.trigger_events or {}
      if game.entity_prototypes[name] then
        global.trigger_events[name] = true
        return true
      end
    end,

    remove_entity_from_trigger = function(name)
      global.trigger_events = global.trigger_events or {}
      if global.trigger_events[name] then
        global.trigger_events[name] = nil
        return true
      end
    end,

    get_trigger_list = function()
      global.trigger_events = global.trigger_events or {}
      return global.trigger_events
    end
  })
