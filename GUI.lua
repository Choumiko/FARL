function startsWith(haystack,needle)
  return string.sub(haystack,1,string.len(needle))==needle
end

function endsWith(haystack,needle)
  return needle=='' or string.sub(haystack,-string.len(needle))==needle
end

GUI = {

    ccWires = {
      {"stg-ccNetWire-red"},
      {"stg-ccNetWire-green"},
      {"stg-ccNetWire-both"}
    },

    styleprefix = "farl_",

    defaultStyles = {
      label = "label",
      button = "button",
      checkbox = "checkbox"
    },

    bindings = {},

    new = function(index, player)
      local new = {}
      setmetatable(new, {__index=GUI})
      return new
    end,

    onNotify = function(self, entity, event)

    end,

    init = function(player)
      local settings = Settings.loadByPlayer(player)
      GUI.bindings = {
        signals = settings.signals,
        poles = settings.poles,
        medium = settings.medium,
        ccNet = settings.ccNet,
        bridge = settings.bridge,
        collectWood = settings.collectWood,
        dropWood = settings.dropWood,
      }
    end,

    add = function(parent, e, bind)
      local gtype, name = e.type, e.name
      if not e.style and GUI.defaultStyles[gtype] then
        e.style = GUI.styleprefix..gtype
      end
      if bind then
        if e.type == "checkbox" then
          if e.state == nil then
            e.state = false
          end
          if type(bind) == "string" then
            e.state = Settings.loadByPlayer(parent.gui.player)[e.name]
          else
            e.state = false
            GUI.callbacks[e.name] = bind
          end
        end
      end
      if e.type == "checkbox" and not e.state then
        e.state = false
      end
      local ret = parent.add(e)
      if bind and e.type == "textfield" then
        ret.text = bind
      end
      if e.type == "checkbox" and e.state == nil then
        e.state = false
      end
      return ret
    end,

    addButton = function(parent, e, bind)
      e.type = "button"
      if bind then
        GUI.callbacks[e.name] = bind
      end
      return GUI.add(parent, e, bind)
    end,

    addLabel = function(parent, e, bind)
      if type(e) == "string" or type(e) == "number" or (type(e) == "table" and e[1]) then
        e = {caption=e}
      end
      e.type="label"
      return GUI.add(parent,e,bind)
    end,

    addTextfield = function(parent, e, bind)
      e.type="textfield"
      return GUI.add(parent, e, bind)
    end,

    addPlaceHolder = function(parent, count)
      local c = count or 1
      for i=1,c do
        GUI.add(parent, {type="label", caption=""})
      end
    end,

    createGui = function(player)
      if player.gui.left.farl ~= nil then return end
      local psettings = Settings.loadByPlayer(player)
      --GUI.init(player)
      local farl = GUI.add(player.gui.left, {type="frame", direction="vertical", name="farl"})
      local rows = GUI.add(farl, {type="table", name="rows", colspan=1})
      local span = 3
      if debugButton then
        span = span+1
      end
      local buttons = GUI.add(rows, {type="table", name="buttons", colspan=span})
      GUI.addButton(buttons, {name="start"}, GUI.toggleStart)
      GUI.addButton(buttons, {name="cc"}, GUI.toggleCC)
      GUI.addButton(buttons, {name="settings", caption={"text-settings"}}, GUI.toggleSettingsWindow)
      if debugButton then
        GUI.addButton(buttons,{name="debug", caption="D"},GUI.debugInfo)
      end
      GUI.add(rows, {type="checkbox", name="signals", caption={"tgl-signal"}}, "signals")
      GUI.add(rows, {type="checkbox", name="poles", caption={"tgl-poles"}}, "poles")
      GUI.add(rows, {type="checkbox", name="concrete", caption={"tgl-concrete"}}, "concrete")
      GUI.add(rows,{type="checkbox", name="bulldozer", caption={"tgl-bulldozer"}, state=psettings.bulldozer},GUI.toggleBulldozer)
      GUI.add(rows,{type="checkbox", name="maintenance", caption={"tgl-maintenance"}, state=psettings.maintenance},GUI.toggleMaintenance)
      GUI.add(rows, {type="checkbox", name="bridge", caption={"tgl-bridge"}}, "bridge")
    end,

    destroyGui = function(player)
      if player.valid then
        if player.gui.left.farl == nil then return end
        player.gui.left.farl.destroy()
      end
    end,

    onGuiClick = function(event, farl, player)
      local name = event.element.name
      if GUI.callbacks[name] then
        return GUI.callbacks[name](event, farl, player)
      end
      local psettings = Settings.loadByPlayer(player)
      if name == "debug" then
        saveVar(global,"debug")
        farl:debugInfo()
      elseif startsWith(event.element.name,"load_bp_") then
        local i = event.element.name:match("load_bp_(%w*)")
        GUI.load_bp(event,farl, player,tonumber(i))
      elseif startsWith(event.element.name,"save_bp_") then
        local i = event.element.name:match("save_bp_(%w*)")
        GUI.save_bp(event,farl, player,tonumber(i))
      elseif name == "signals" or name == "poles" or name == "ccNet" or name == "flipPoles" or name == "collectWood" or name == "dropWood"
        or name == "poleEntities" or name == "parallelTracks" or name == "concrete" or name == "railEntities" or name == "mirrorConcrete" then
        psettings[name] = not psettings[name]
        if name == "poles" then
          if psettings[name] and farl.active then
            farl:findLastPole()
          end
        end
      elseif name == "bridge" then
        psettings.bridge = not psettings.bridge
      elseif name == "poweredRails" then
        if not global.electricInstalled then
          psettings.rail = rails.basic
          return
        end
        psettings.electric = not psettings.electric
        if psettings.electric then
          psettings.rail = rails.electric
        else
          psettings.rail = rails.basic
        end
        farl.lastrail = false
      end
    end,

    toggleStart = function(event, farl, player)
      farl:toggleActive()
    end,

    debugInfo = function(event, farl, player)
      farl:debugInfo()
    end,

    toggleBulldozer = function(event, farl, player)
      farl:toggleBulldozer()
      GUI.updateGui(farl)
    end,

    toggleMaintenance = function(event, farl, player)
      farl:toggleMaintenance()
      GUI.updateGui(farl)
    end,

    load_bp = function(event, farl, player, i)
      local index = player.index
      if global.savedBlueprints[index][i] then
        local bps = global.savedBlueprints[index][i]
        local psettings = Settings.loadByPlayer(player)
        local lanes = #bps.straight.lanes + 1
        local pole = game.entity_prototypes[bps.straight.pole.name].localised_name
        psettings.activeBP = table.deepcopy(global.savedBlueprints[index][i])
        if farl.active then
          farl:deactivate()
          farl:activate()
        end
        player.print({"", {"text-blueprint-loaded"}, " ",{"text-blueprint-description", lanes, pole}})
        GUI.toggleSettingsWindow(event,farl,player)
      end
    end,

    save_bp = function(event, farl, player, i)
      local index = player.index
      local psettings = Settings.loadByPlayer(player)
      global.savedBlueprints[index][i] = table.deepcopy(psettings.activeBP)
      player.print({"text-blueprint-saved"})
      GUI.toggleSettingsWindow(event,farl,player)
      GUI.toggleSettingsWindow(event,farl,player)
    end,

    toggleSide = function(event, farl, player)
      local psettings = Settings.loadByPlayer(player)
      if psettings.poleSide == 1 then
        psettings.poleSide = -1
        event.element.caption = {"stg-side-left"}
        return
      else
        psettings.poleSide = 1
        event.element.caption = {"stg-side-right"}
        return
      end
    end,

    toggleWires = function(event,farl, player)
      local psettings = Settings.loadByPlayer(player)
      psettings.ccWires = psettings.ccWires % 3 + 1
      event.element.caption = GUI.ccWires[psettings.ccWires]
    end,

    toggleCC = function(event, farl, player)
      farl:toggleCruiseControl()
    end,

    toggleSettingsWindow = function(event, farl, player)
      local row = player.gui.left.farl.rows
      local psettings = Settings.loadByPlayer(player)
      if row.settings ~= nil then
        local s = row.settings
        local sDistance = tonumber(s.signalDistance.text) or psettings.signalDistance
        sDistance = sDistance < 0 and 0 or sDistance
        player.gui.left.farl.rows.buttons.settings.caption={"text-settings"}
        GUI.saveSettings({signalDistance = sDistance}, player)
        row.settings.destroy()
      else
        local settings = row.add({type="table", name="settings", colspan=2})
        player.gui.left.farl.rows.buttons.settings.caption={"text-save"}

        GUI.add(settings,{type="checkbox", name="dropWood", caption={"stg-dropWood"}}, "dropWood")
        GUI.add(settings,{type="checkbox", name="collectWood", caption={"stg-collectWood"}}, "collectWood")

        GUI.add(settings, {type="label", caption={"stg-signalDistance"}})
        GUI.add(settings, {type="textfield", name="signalDistance", style="farl_textfield_small"}, psettings.signalDistance)

        if remote.interfaces.dim_trains then
          GUI.add(settings,{type="checkbox", name="poweredRails", caption="use powered rails", state=psettings.electric})
          GUI.add(settings, {type="label", caption=""})
        end

        GUI.add(settings, {type="label", caption={"stg-poleSide"}})
        GUI.add(settings, {type="checkbox", name="flipPoles", caption={"stg-flipPoles"}, state=psettings.flipPoles})

        GUI.add(settings,{type="checkbox", name="poleEntities", caption={"stg-poleEntities"}},"poleEntities")
        GUI.addPlaceHolder(settings)

        GUI.add(settings,{type="checkbox", name="railEntities", caption={"stg-rail-entities"}}, "railEntities")
        GUI.addPlaceHolder(settings)

        GUI.add(settings, {type="checkbox", name="mirrorConcrete", caption="Mirror concrete"}, "mirrorConcrete")
        GUI.addPlaceHolder(settings)

        --GUI.add(settings,{type="checkbox", name="parallelTracks", caption={"stg-parallel-tracks"}}, "parallelTracks")
        --GUI.addPlaceHolder(settings)

        GUI.add(settings, {type="checkbox", name="ccNet", caption={"stg-ccNet"}, state=psettings.ccNet})
        local row2 = GUI.add(settings, {type="table", name="row3", colspan=2})
        GUI.add(row2, {type="label", caption={"stg-ccNetWire"}})
        GUI.addButton(row2, {name="ccNetWires", caption=GUI.ccWires[psettings.ccWires]}, GUI.toggleWires)

        GUI.addLabel(settings, {caption={"stg-stored-blueprints"}})
        local stored_bp = GUI.add(settings,{type="table", colspan=3})

        local bps = global.savedBlueprints[player.index]
        for i=1,3 do
          if bps and bps[i] then
            local lanes = #bps[i].straight.lanes + 1
            local pole = game.entity_prototypes[bps[i].straight.pole.name].localised_name
            GUI.addButton(stored_bp,{name="load_bp_"..i, caption="L"})
            GUI.addButton(stored_bp,{name="save_bp_"..i, caption="S"})
            GUI.addLabel(stored_bp, {caption={"text-blueprint-description", lanes, pole}})
          else
            GUI.addLabel(stored_bp,{caption="L"})
            GUI.addButton(stored_bp,{name="save_bp_"..i, caption="S"})
            GUI.addLabel(stored_bp, {caption="--"})
          end
        end

        GUI.add(settings, {type="label", caption={"stg-blueprint"}})
        local row3 = GUI.add(settings, {type="table", name="row4", colspan=2})
        GUI.addButton(row3, {name="blueprint", caption={"stg-blueprint-read"}}, GUI.readBlueprint)
        GUI.addButton(row3, {name="bpClear", caption={"stg-blueprint-clear"}}, GUI.clearBlueprints)
        GUI.add(settings, {type="label", caption={"stg-blueprint-write"}})
        local row4 = GUI.add(settings, {type="flow", name="row5", direction="horizontal"})
        GUI.addButton(row4, {name="blueprint_concrete_vertical", caption={"stg-blueprint-vertical"}}, GUI.create_concrete_vertical)
        GUI.addButton(row4,{name="blueprint_concrete_diagonal", caption={"stg-blueprint-diagonal"}},GUI.create_concrete_diagonal)
        local row6 = GUI.add(settings, {type="flow", name="row6", direction="horizontal"})
        GUI.addButton(row6,{name="print_statistics", caption={"stg-statistics"}}, GUI.print_statistics)
      end
    end,

    findBlueprintsInHotbar = function(player)
      local blueprints = {}
      if player ~= nil then
        local hotbar = player.get_inventory(defines.inventory.player_quickbar) --TODO 0.13 use inventory.god_quickbar 
        if hotbar ~= nil then
          local i = 1
          while (i < 30) do
            local itemStack
            if pcall(function () itemStack = hotbar[i] end) then
              if itemStack ~= nil and itemStack.valid_for_read and itemStack.type == "blueprint" then
                table.insert(blueprints, itemStack)
              end
              i = i + 1
            else
              i = 100
            end
          end
        end
      end
      return blueprints
    end,

    findSetupBlueprintsInHotbar = function(player)
      local blueprints = GUI.findBlueprintsInHotbar(player)
      if blueprints ~= nil then
        local ret = {}
        for i, blueprint in pairs(blueprints) do
          if blueprint.is_blueprint_setup() then
            table.insert(ret, blueprint)
          end
        end
        return ret
      end
    end,

    readBlueprint = function(event, farl, player)
      local status, err = pcall(function()
        local bp = GUI.findSetupBlueprintsInHotbar(player)
        if bp then
          local was_active = farl.active
          farl:deactivate()
          farl:parseBlueprints(bp)
          GUI.destroyGui(player)
          GUI.createGui(player)
          if was_active then
            farl:activate()
          end
          return
        end
      end)
      if not status then
        debugDump("Error: "..err,true)
      end
    end,

    clearBlueprints = function(event, farl, player)
      local psettings = Settings.loadByPlayer(player)
      psettings.bp = {diagonal=defaultsDiagonal, straight=defaultsStraight}
      psettings.activeBP = psettings.bp
      farl:print({"msg-bp-cleared"})
      GUI.destroyGui(player)
      GUI.createGui(player)
    end,

    create_concrete_vertical = function(event, farl, player)
      GUI.createBlueprint(defaults_concrete_vert,farl,player)
    end,

    create_concrete_diagonal = function(event, farl, player)
      GUI.createBlueprint(defaults_concrete_diag,farl,player)
    end,

    print_statistics = function(event, farl, player)
      if player.valid then
        local stats = global.statistics[player.force.name]
        player.print({"stg-statistics"})
        player.print({"text-created-entities"})
        for n,c in pairs(stats.created) do
          local proto = game.entity_prototypes[n] or game.item_prototypes[n] or false
          if proto then
            player.print({"",proto.localised_name, ": "..c})
          else
            player.print(n..": "..c)
          end
        end
        player.print({"text-removed-entities"})
        for n,c in pairs(stats.removed) do
          local proto = game.entity_prototypes[n] or game.item_prototypes[n] or false
          if proto then
            player.print({"",proto.localised_name, ": "..c})
          else
            player.print(n..": "..c)
          end
        end
        GUI.toggleSettingsWindow(event, farl, player)
      end
    end,

    createBlueprint = function(bp_table, farl, player)
      local blueprints = GUI.findBlueprintsInHotbar(player)
      local bp = false
      if blueprints ~= nil then
        for i, blueprint in pairs(blueprints) do
          if not blueprint.is_blueprint_setup() then
            bp = blueprint
            break
          end
        end
        if bp then
          local icons = {{index = 2, signal={name = "farl", type="item"}},[0] = {index = 1, signal={name = "rail", type="item"}}}
          bp.set_blueprint_entities(util.table.deepcopy(bp_table.entities))
          bp.set_blueprint_tiles(util.table.deepcopy(bp_table.tiles))
          bp.blueprint_icons = icons
        else
          farl:print({"msg-no-empty-blueprint"})
        end
      end
    end,

    saveSettings = function(s, player)
      local psettings = Settings.loadByPlayer(player)
      for i,p in pairs(s) do
        if psettings[i] ~= nil then
          psettings[i] = p
        end
      end
    end,

    updateGui = function(farl)
      if farl.driver.name ~= "farl_player" and farl.driver.gui.left.farl then
        --GUI.init(farl.driver)
        farl.driver.gui.left.farl.rows.buttons.start.caption = farl.active and {"text-stop"} or {"text-start"}
        farl.driver.gui.left.farl.rows.buttons.cc.caption = farl.cruise and {"text-stopCC"} or {"text-startCC"}
        if not farl.settings then
          farl.settings = Settings.loadByPlayer(farl.driver)
        end
        farl.driver.gui.left.farl.rows.bulldozer.state = farl.settings.bulldozer
        farl.driver.gui.left.farl.rows.maintenance.state = farl.settings.maintenance
      end
    end,
}

GUI.callbacks = {
  start = GUI.toggleStart,
  cc = GUI.toggleCC,
  settings = GUI.toggleSettingsWindow,
  debug = GUI.debugInfo,
  bulldozer = GUI.toggleBulldozer,
  maintenance = GUI.toggleMaintenance,
  ccNetWires = GUI.toggleWires,
  blueprint = GUI.readBlueprint,
  bpClear = GUI.clearBlueprints,
  blueprint_concrete_vertical = GUI.create_concrete_vertical,
  blueprint_concrete_diagonal = GUI.create_concrete_diagonal,
  print_statistics = GUI.print_statistics,
}
