function migrate()
  if global.version < "0.1.1" then
    glob = {}
    global.settings = {}
    global.version = "0.1.1"
  end
  if global.version == "0.1.8" then
    global.settings.bp = nil
    global.settings.straight = nil
    global.settings.diagonal = nil
  end
  global.settings = global.settings or {}
  global.settings.signalDistance = global.settings.signalDistance or 15
  global.settings.curvedWeight = global.settings.curvedWeight or 4
  global.settings.ccNet = global.settings.ccNet or false
  global.settings.ccWires = global.settings.ccWires or 1
  global.settings.collectWood = global.settings.collectWood or true
  global.settings.dropWood = global.settings.dropWood or false
  if global.version < "0.2.4" then
    global.settings.bp = nil
    global.version = "0.2.4"
  end
  global.settings.bp = global.settings.bp or {
    medium= {diagonal=defaultsMediumDiagonal, straight=defaultsMediumStraight},
    big=    {diagonal=defaultsDiagonal, straight=defaultsStraight}}
  global.rail = global.rail or rails.basic
  global.settings.electric = global.settings.electric or false
  if electricInstalled then
    global.electricInstalled = true
  else
    global.electricInstalled = false
    global.settings.electric = nil
    global.rail = rails.basic
  end

  if global.minPoles == nil then
    global.minPoles = true
  end
  if global.medium == nil then
    global.medium = false
  end
  if global.signals == nil then
    global.signals = true
  end
  if global.poles == nil then
    global.poles = true
  end
  if global.bridge == nil or not landfillInstalled then
    global.bridge = false
  end

  if global.flipSignals == nil then
    global.flipSignals = false
  end
  if global.settings.flipPoles == nil then
    global.settings.flipPoles = false
  end
  global.activeBP = global.medium and global.settings.bp.medium or global.settings.bp.big
  global.flipSignals = false
  global.farl = global.farl or {}
  global.railInfoLast = global.railInfoLast or {}
  global.debug = global.debug or {}
  global.action = global.action or {}
  global.cruiseSpeed = global.cruiseSpeed or 0.4
  for i,farl in ipairs(global.farl) do
    farl = resetMetatable(farl, FARL)
    if global.version < "0.1.4" then
      farl.cruiseInterrupt = 0
    end
    farl.index = nil
  end
  if global.version < "0.1.4" then
    for i=1,#game.players do
      GUI.destroyGui(game.players[i])
    end
    global.version = "0.1.4"
  end
  if global.version < "0.1.8" then
    global.settings.poleDistance = nil
    global.settings.poleSide = nil
    if global.medium then
      global.settings.straight = defaultsMediumStraight
      global.settings.diagonal = defaultsMediumDiagonal
    else
      global.settings.straight = defaultsStraight
      global.settings.diagonal = defaultsDiagonal
    end
    global.version = "0.1.8"
  end
end
