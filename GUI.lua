Observer = {
  onNotify = function(self, entity, event)

  end
}

GUI = {
  new = function(index, player)
    local new = {}
    setmetatable(new, {__index=GUI})
    return new
  end,

  onNotify = function(self, entity, event)

  end,

  add = function(parent, e, bind)
    local type, name = e.type, e.name
    if not e.style and (type == "button" or type == "label") then
      e.style = "farl_"..type
    end
    if bind then
      if type == "checkbox" then
        e.state = glob[bind]
      end
    end 
    return parent.add(e)
  end,
  
  createGui = function(player)
    if player.gui.left.farl ~= nil then return end
    local farl = GUI.add(player.gui.left, {type="frame", direction="vertical", name="farl"})
    local rows = GUI.add(farl, {type="table", name="rows", colspan=1})
    local buttons = GUI.add(rows, {type="table", name="buttons", colspan=3})
    GUI.add(buttons, {type="button", name="start"})
    GUI.add(buttons, {type="button", name="cc"})
    GUI.add(buttons, {type="button", name="settings", caption="S"})
    --local stgsSignals = GUI.add(rows,{type="table", name="stgsSignals", colspan=2})
    GUI.add(rows, {type="checkbox", name="signals", caption="Place signals"}, "signals")
    --GUI.add(stgsSignals,{type="checkbox", name="flipSignals", caption="reverse"}, "flipSignals")
    GUI.add(rows, {type="checkbox", name="poles", caption="Place poles"}, "poles")
    --local buttons2 = GUI.add(rows,{type="table", name="junctions", colspan=3})
    --GUI.add(buttons2, {type="label", caption="Junction"})
    --GUI.add(buttons2, {type="button", name="junctionLeft", caption="left"})
    --GUI.add(buttons2, {type="button", name="junctionRight", caption="right"})
  end,

  destroyGui = function(player)
    if player.gui.left.farl == nil then return end
    player.gui.left.farl.destroy()
  end,

  onGuiClick = function(event, farl, player)
    local name = event.element.name
    if name == "debug" then
      saveVar(glob,"debug")
      --glob.debug = {}
      --glob.action = {}
      farl:debugInfo()
    elseif name == "start" then
      farl:toggleActive()
    elseif name == "settings" then
      GUI.toggleSettingsWindow(player)
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
      farl:toggleCruiseControl()
    elseif name == "signals" or name == "poles" or name == "flipSignals" or name == "medium" then
      glob[name] = not glob[name]
    elseif name == "junctionLeft" then
      farl:createJunction(0)
    elseif name == "junctionRight" then
      farl:createJunction(2)
    end
  end,

  toggleSettingsWindow = function(player)
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
      player.gui.left.farl.rows.buttons.settings.caption="S"
      GUI.saveSettings{poleDistance=pDistance, signalDistance=sDistance, curvedWeight=weight}
      row.settings.destroy()
    else
      local settings = row.add({type="table", name="settings", colspan=2})
      player.gui.left.farl.rows.buttons.settings.caption="Save settings"
      settings.add({type="label", caption="Distance between pole and rail", style="farl_label"})
      local pDistance = settings.add({type="textfield", name="poleDistance", style="farl_textfield_small"})
      local row1 = GUI.add(settings,{type="table", name="row2", colspan=2})
      GUI.add(row1, {type="label", caption="Side of pole:", style="farl_label"})
      GUI.add(row1, {type="button", name="side", caption=captionSide, style="farl_button"})
      GUI.add(settings, {type="checkbox", name="medium", caption="use medium Poles"},"medium")
      settings.add({type="label", caption="Distance between rail signals", style="farl_label"})
      local sDistance = settings.add({type="textfield", name="signalDistance", style="farl_textfield_small"})
      settings.add({type="label", caption="Weight for curved rails", style="farl_label"})
      local weight = settings.add({type="textfield", name="curvedWeight", style="farl_textfield_small"})
      pDistance.text = glob.settings.poleDistance
      sDistance.text = glob.settings.signalDistance
      weight.text = glob.settings.curvedWeight
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
    if farl.driver.name ~= "farl_player" then
      farl.driver.gui.left.farl.rows.buttons.start.caption = farl.active and "Stop" or "Start"
      farl.driver.gui.left.farl.rows.buttons.cc.caption = farl.cruise and "Stop cruise" or "Cruise"
    end
  end,
}
