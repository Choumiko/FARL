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

    callbacks = {},

    new = function(index, player)
      local new = {}
      setmetatable(new, {__index=GUI})
      return new
    end,

    onNotify = function(self, entity, event)

    end,

    init = function()
      GUI.bindings = {
        signals = glob.signals,
        poles = glob.poles,
        flipSignals = glob.flipSignals,
        medium = glob.medium,
        minPoles = glob.minPoles,
        ccNet = glob.settings.ccNet,
        bridge = glob.bridge,
        collectWood = glob.settings.collectWood,
        dropWood = glob.settings.dropWood
      }
    end,

    add = function(parent, e, bind)
      local type, name = e.type, e.name
      if not e.style and GUI.defaultStyles[type] then
        e.style = GUI.styleprefix..type
      end
      if bind then
        if e.type == "checkbox" then
          e.state = GUI.bindings[e.name]
        end
      end
      local ret = parent.add(e)
      if bind and e.type == "textfield" then
        ret.text = bind
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

    createGui = function(player)
      if player.gui.left.farl ~= nil then return end
      local farl = GUI.add(player.gui.left, {type="frame", direction="vertical", name="farl"})
      local rows = GUI.add(farl, {type="table", name="rows", colspan=1})
      local buttons = GUI.add(rows, {type="table", name="buttons", colspan=3})
      GUI.addButton(buttons, {name="start"}, GUI.toggleStart)
      GUI.addButton(buttons, {name="cc"}, GUI.toggleCC)
      GUI.addButton(buttons, {name="settings", caption={"text-settings"}}, GUI.toggleSettingsWindow)
      GUI.add(rows, {type="checkbox", name="signals", caption={"tgl-signal"}}, "signals")
      GUI.add(rows, {type="checkbox", name="poles", caption={"tgl-poles"}}, "poles")
      if landfillInstalled then
        GUI.add(rows, {type="checkbox", name="bridge", caption={"tgl-bridge"}}, "bridge")
      end
    end,

    destroyGui = function(player)
      if player.gui.left.farl == nil then return end
      player.gui.left.farl.destroy()
    end,

    onGuiClick = function(event, farl, player)
      local name = event.element.name
      if GUI.callbacks[name] then
        return GUI.callbacks[name](event, farl, player)
      end
      if name == "debug" then
        saveVar(glob,"debug")
        --glob.debug = {}
        --glob.action = {}
        farl:debugInfo()
      elseif name == "signals" or name == "poles" or name == "flipSignals" or name == "minPoles" then
        glob[name] = not glob[name]
      elseif name == "ccNet" or name == "flipPoles" or name == "collectWood" or name == "dropWood" then
        glob.settings[name] = not glob.settings[name]
      elseif name == "bridge" then
        if landfillInstalled then
          glob.bridge = not glob.bridge
        else
          glob.bridge = false
        end
      elseif name == "poweredRails" then
        if not remote.interfaces.dim_trains then
          glob.rail = rails.basic
          return
        end
        glob.settings.electric = not glob.settings.electric
        if glob.settings.electric then
          glob.rail = rails.electric
        else
          glob.rail = rails.basic        
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

    togglePole = function(event, farl, player)
      glob.medium = not glob.medium
      if glob.medium then
        glob.activeBP = glob.settings.bp.medium
        event.element.caption = {"stg-poleMedium"}
      else
        glob.activeBP = glob.settings.bp.big
        event.element.caption = {"stg-poleBig"}
      end
    end,

    toggleSide = function(event, farl, player)
      if glob.settings.poleSide == 1 then
        glob.settings.poleSide = -1
        event.element.caption = {"stg-side-left"}
        return
      else
        glob.settings.poleSide = 1
        event.element.caption = {"stg-side-right"}
        return
      end
    end,

    toggleWires = function(event,farl, player)
      glob.settings.ccWires = glob.settings.ccWires % 3 + 1
      event.element.caption = GUI.ccWires[glob.settings.ccWires]
    end,

    toggleCC = function(event, farl, player)
      farl:toggleCruiseControl()
    end,

    toggleSettingsWindow = function(event, farl, player)
      local row = player.gui.left.farl.rows
--      local captionSide
--      if glob.settings.poleSide == 1 then
--        captionSide = {"stg-side-right"}
--      else
--        captionSide = {"stg-side-left"}
--      end

      if row.settings ~= nil then
        local s = row.settings
        local sDistance = tonumber(s.signalDistance.text) or glob.settings.signalDistance
        sDistance = sDistance < 0 and 0 or sDistance
        player.gui.left.farl.rows.buttons.settings.caption={"text-settings"}
        GUI.saveSettings{signalDistance=sDistance}
        row.settings.destroy()
      else
        local captionPole = glob.medium and {"stg-poleMedium"} or {"stg-poleBig"}
        local settings = row.add({type="table", name="settings", colspan=2})
        player.gui.left.farl.rows.buttons.settings.caption={"text-save"}

        GUI.add(settings,{type="checkbox", name="dropWood", caption={"stg-dropWood"}, state = glob.settings.dropWood})
        GUI.add(settings,{type="checkbox", name="collectWood", caption={"stg-collectWood"}}, glob.settings.collectWood)
        
        GUI.add(settings, {type="label", caption={"stg-signalDistance"}})
        GUI.add(settings, {type="textfield", name="signalDistance", style="farl_textfield_small"}, glob.settings.signalDistance)
        
        if remote.interfaces.dim_trains then
          GUI.add(settings,{type="checkbox", name="poweredRails", caption="use powered rails", state=glob.settings.electric})
          GUI.add(settings, {type="label", caption=""})
        end
        
        GUI.add(settings, {type="label", caption={"stg-poleType"}})
        GUI.addButton(settings, {name="poleType", caption=captionPole}, GUI.togglePole)
        
        GUI.add(settings, {type="label", caption={"stg-poleSide"}})
        GUI.add(settings, {type="checkbox", name="flipPoles", caption={"stg-flipPoles"}, state=glob.settings.flipPoles})
--        GUI.addButton(row1, {name="side", caption=captionSide}, GUI.toggleSide)

        GUI.add(settings, {type="checkbox", name="minPoles", caption={"stg-minPoles"}}, "minPoles")
        GUI.add(settings, {type="label", caption=""})

        GUI.add(settings, {type="checkbox", name="ccNet", caption={"stg-ccNet"}, state=glob.settings.ccNet})
        local row2 = GUI.add(settings, {type="table", name="row3", colspan=2})
        GUI.add(row2, {type="label", caption={"stg-ccNetWire"}})
        GUI.addButton(row2, {name="ccNetWires", caption=GUI.ccWires[glob.settings.ccWires]}, GUI.toggleWires)

        GUI.add(settings, {type="label", caption={"stg-blueprint"}})
        local row3 = GUI.add(settings, {type="table", name="row4", colspan=2})
        GUI.addButton(row3, {name="blueprint", caption={"stg-blueprint-read"}}, GUI.readBlueprint)
        GUI.addButton(row3, {name="bpClear", caption={"stg-blueprint-clear"}}, GUI.clearBlueprints)
      end
    end,

    findBlueprintsInHotbar = function(player)
      local blueprints = {}
      if player ~= nil then
        local hotbar = player.getinventory(1)
        if hotbar ~= nil then
          local i = 1
          while (i < 30) do
            local itemStack
            if pcall(function () itemStack = hotbar[i] end) then
              if itemStack ~= nil and itemStack.type == "blueprint" then
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
          if blueprint.isblueprintsetup() then
            table.insert(ret, blueprint)
          end
        end
        return ret
      end
    end,

    readBlueprint = function(event, farl, player)
      local bp = GUI.findSetupBlueprintsInHotbar(player)
      if bp then
        farl:parseBlueprints(bp)
        GUI.destroyGui(player)
        GUI.createGui(player)
        return
      end
    end,

    clearBlueprints = function(event, farl, player)
      glob.settings.bp = {medium= {diagonal=defaultsMediumDiagonal,
                                   straight=defaultsMediumStraight},
                          big=    {diagonal=defaultsDiagonal,
                                   straight=defaultsStraight}}
      glob.activeBP = glob.medium and glob.settings.bp.medium or glob.settings.bp.big                                   
    end,

    saveSettings = function(s)
      for i,p in pairs(s) do
        if glob.settings[i] then
          glob.settings[i] = p
        end
      end
    end,

    updateGui = function(farl)
      GUI.init()
      if farl.driver.name ~= "farl_player" then
        farl.driver.gui.left.farl.rows.buttons.start.caption = farl.active and {"text-stop"} or {"text-start"}
        farl.driver.gui.left.farl.rows.buttons.cc.caption = farl.cruise and {"text-stopCC"} or {"text-startCC"}
      end
    end,
}
