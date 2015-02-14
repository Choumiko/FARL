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
        ccNet = glob.settings.ccNet
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
      elseif name == "signals" or name == "poles" or name == "flipSignals" or name == "medium" or name == "minPoles" then
        glob[name] = not glob[name]
      elseif name == "ccNet" then
        glob.settings.ccNet = not glob.settings.ccNet
      elseif name == "junctionLeft" then
        farl:createJunction(0)
      elseif name == "junctionRight" then
        farl:createJunction(2)
      end
    end,

    toggleStart = function(event, farl, player)
      farl:toggleActive()
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
      local captionSide
      if glob.settings.poleSide == 1 then
        captionSide = {"stg-side-right"}
      else
        captionSide = {"stg-side-left"}
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
        player.gui.left.farl.rows.buttons.settings.caption={"text-settings"}
        GUI.saveSettings{poleDistance=pDistance, signalDistance=sDistance, curvedWeight=weight}
        row.settings.destroy()
      else
        local settings = row.add({type="table", name="settings", colspan=2})
        player.gui.left.farl.rows.buttons.settings.caption={"text-save"}

        GUI.add(settings, {type="label", caption={"stg-poleDistance"}})
        GUI.add(settings, {type="textfield", name="poleDistance", style="farl_textfield_small"}, glob.settings.poleDistance)

        GUI.add(settings, {type="label", caption={"stg-signalDistance"}})
        GUI.add(settings, {type="textfield", name="signalDistance", style="farl_textfield_small"}, glob.settings.signalDistance)

        GUI.add(settings, {type="checkbox", name="medium", caption={"stg-mediumPoles"}},"medium")
        local row1 = GUI.add(settings,{type="table", name="row2", colspan=2})
        GUI.add(row1, {type="label", caption={"stg-poleSide"}})
        GUI.addButton(row1, {name="side", caption=captionSide}, GUI.toggleSide)

        GUI.add(settings, {type="checkbox", name="minPoles", caption={"stg-minPoles"}}, "minPoles")
        GUI.add(settings, {type="label", caption=""})

        GUI.add(settings, {type="checkbox", name="ccNet", caption={"stg-ccNet"}, state=glob.settings.ccNet})
        local row2 = GUI.add(settings, {type="table", name="row3", colspan=2})
        GUI.add(row2, {type="label", caption={"stg-ccNetWire"}})
        GUI.addButton(row2, {name="ccNetWires", caption=GUI.ccWires[glob.settings.ccWires]}, GUI.toggleWires)

        GUI.add(settings, {type="label", caption={"stg-curvedWeight"}})
        GUI.add(settings, {type="textfield", name="curvedWeight", style="farl_textfield_small"}, glob.settings.curvedWeight)

        GUI.add(settings, {type="label", caption={"stg-blueprint"}})
        GUI.addButton(settings, {name="blueprint", caption={"stg-blueprint-empty"}} ,GUI.readBlueprint)
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
        if farl.driver.gui.left.farl.rows.settings ~= nil then
          
        end
      end
    end,
}
