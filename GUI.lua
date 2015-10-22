Observer = {
  onNotify = function(self, entity, event)

  end
}

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
        flipSignals = settings.flipSignals,
        medium = settings.medium,
        minPoles = settings.minPoles,
        ccNet = settings.ccNet,
        bridge = settings.bridge,
        collectWood = settings.collectWood,
        dropWood = settings.dropWood,
        root = settings.root

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
      local e = e
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
        span = 4
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
      GUI.add(rows, {type="checkbox", name="root", caption={"tgl-root"}, state=psettings.root}, GUI.toggleRootMode)
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
        saveVar(glob,"debug")
        farl:debugInfo()
      elseif name == "signals" or name == "poles" or name == "flipSignals" or name == "minPoles"
        or name == "ccNet" or name == "flipPoles" or name == "collectWood" or name == "dropWood"
        or name == "poleEntities" or name == "parallelTracks" then
        psettings[name] = not psettings[name]
        if name == "poles" then
          if not psettings[name] then
            farl:resetPoleData()
          else
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
      elseif name == "junctionLeft" then
        farl:createJunction(0)
      elseif name == "junctionRight" then
        farl:createJunction(2)
      end
    end,

    toggleStart = function(event, farl, player)
      farl:toggleActive()
    end,

    debugInfo = function(event, farl, player)
      farl:debugInfo()
    end,

    toggleMaintenance = function(event, farl, player)
      farl:toggleMaintenance()
    end,

    togglePole = function(event, farl, player)
      local psettings = Settings.loadByPlayer(player)
      psettings.medium = not psettings.medium
      if psettings.medium then
        psettings.activeBP = psettings.bp.medium
        event.element.caption = {"stg-poleMedium"}
      else
        psettings.activeBP = psettings.bp.big
        event.element.caption = {"stg-poleBig"}
      end
      farl:resetPoleData()
      farl:findLastPole()
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

    toggleRootMode = function(event, farl, player)
      farl:toggleRootMode()
      GUI.updateGui(farl)
    end,

    toggleSettingsWindow = function(event, farl, player)
      local row = player.gui.left.farl.rows
      local psettings = Settings.loadByPlayer(player)
      if row.settings ~= nil then
        local s = row.settings
        local sDistance = tonumber(s.signalDistance.text) or psettings.signalDistance
        sDistance = sDistance < 0 and 0 or sDistance
        local pLag = tonumber(s.parallelLag.text) or psettings.signalDistance
        pLag = pLag < 1 and 1 or pLag
        pLag = pLag > 20 and 20 or pLag
        player.gui.left.farl.rows.buttons.settings.caption={"text-settings"}
        GUI.saveSettings({signalDistance = sDistance, parallelLag = pLag}, player)
        row.settings.destroy()
      else
        local captionPole = psettings.medium and {"stg-poleMedium"} or {"stg-poleBig"}
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

        GUI.add(settings, {type="label", caption={"stg-poleType"}})
        GUI.addButton(settings, {name="poleType", caption=captionPole}, GUI.togglePole)

        GUI.add(settings, {type="label", caption={"stg-poleSide"}})
        GUI.add(settings, {type="checkbox", name="flipPoles", caption={"stg-flipPoles"}, state=psettings.flipPoles})

        GUI.add(settings, {type="checkbox", name="minPoles", caption={"stg-minPoles"}}, "minPoles")
        GUI.addPlaceHolder(settings)

        GUI.add(settings,{type="checkbox", name="poleEntities", caption={"stg-poleEntities"}},"poleEntities")
        GUI.addPlaceHolder(settings)

        GUI.add(settings,{type="checkbox", name="parallelTracks", caption={"stg-parallel-tracks"}}, "parallelTracks")
        GUI.addPlaceHolder(settings)

        GUI.add(settings, {type="label", caption={"stg-parallel-lag"}})
        GUI.add(settings,{type="textfield", name="parallelLag", style="farl_textfield_small"}, psettings.parallelLag)

        GUI.add(settings, {type="checkbox", name="ccNet", caption={"stg-ccNet"}, state=psettings.ccNet})
        local row2 = GUI.add(settings, {type="table", name="row3", colspan=2})
        GUI.add(row2, {type="label", caption={"stg-ccNetWire"}})
        GUI.addButton(row2, {name="ccNetWires", caption=GUI.ccWires[psettings.ccWires]}, GUI.toggleWires)

        GUI.add(settings, {type="label", caption={"stg-blueprint"}})
        local row3 = GUI.add(settings, {type="table", name="row4", colspan=2})
        GUI.addButton(row3, {name="blueprint", caption={"stg-blueprint-read"}}, GUI.readBlueprint)
        GUI.addButton(row3, {name="bpClear", caption={"stg-blueprint-clear"}}, GUI.clearBlueprints)
      end
    end,

    findBlueprintsInHotbar = function(player)
      local blueprints = {}
      if player ~= nil then
        local hotbar = player.get_inventory(defines.inventory.player_quickbar)
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
        for i, blueprint in ipairs(blueprints) do
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
          farl:parseBlueprints2(bp)
          GUI.destroyGui(player)
          GUI.createGui(player)
          return
        end
      end)
      if not status then
        debugDump("Error: "..err,true)
      end
    end,

    clearBlueprints = function(event, farl, player)
      local psettings = Settings.loadByPlayer(player)
      psettings.bp = {
        medium= {diagonal=defaultsMediumDiagonal, straight=defaultsMediumStraight},
        big=    {diagonal=defaultsDiagonal, straight=defaultsStraight}}
      psettings.activeBP = psettings.medium and psettings.bp.medium or psettings.bp.big
      if global.savedBlueprints[player.name] then
        global.savedBlueprints[player.name] = nil
      end
      farl:print("Cleared blueprints")
      GUI.destroyGui(player)
      GUI.createGui(player)
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
        farl.driver.gui.left.farl.rows.root.state = farl.settings.root
        if not farl.driver.gui.left.farl.rows.maintenance then
          GUI.destroyGui(farl.driver)
          GUI.createGui(farl.driver)
        end
        farl.driver.gui.left.farl.rows.maintenance.state = farl.maintenance
      end
    end,
}

GUI.callbacks = {
  start = GUI.toggleStart,
  cc = GUI.toggleCC,
  settings = GUI.toggleSettingsWindow,
  debug = GUI.debugInfo,
  root = GUI.toggleRootMode,
  maintenance = GUI.toggleMaintenance,
  poleType = GUI.togglePole,
  ccNetWires = GUI.toggleWires,
  blueprint = GUI.readBlueprint,
  bpClear = GUI.clearBlueprints
}
