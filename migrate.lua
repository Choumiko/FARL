function migrate()
  if glob.version < "0.1.1" then
    glob = {}
    glob.settings = {}
    glob.version = "0.1.1"
  end
  if glob.version == "0.1.8" then
    glob.settings.bp = nil
    glob.settings.straight = nil
    glob.settings.diagonal = nil
  end
  glob.settings = glob.settings or {}
  glob.settings.signalDistance = glob.settings.signalDistance or 15
  glob.settings.curvedWeight = glob.settings.curvedWeight or 4
  glob.settings.ccNet = glob.settings.ccNet or false
  glob.settings.ccWires = glob.settings.ccWires or 1
  glob.settings.collectWood = glob.settings.collectWood or true
  glob.settings.dropWood = glob.settings.dropWood or false
  if glob.version < "0.2.4" then
    glob.settings.bp = nil
    glob.version = "0.2.4"
  end
  glob.settings.bp = glob.settings.bp or {
    medium= {diagonal=defaultsMediumDiagonal, straight=defaultsMediumStraight},
    big=    {diagonal=defaultsDiagonal, straight=defaultsStraight}}
  glob.rail = glob.rail or rails.basic
  glob.settings.electric = glob.settings.electric or false
  if electricInstalled then
    glob.electricInstalled = true
  else
    glob.electricInstalled = false
    glob.settings.electric = nil
    glob.rail = rails.basic
  end

  if glob.minPoles == nil then
    glob.minPoles = true
  end
  if glob.medium == nil then
    glob.medium = false
  end
  if glob.signals == nil then
    glob.signals = true
  end
  if glob.poles == nil then
    glob.poles = true
  end
  if glob.bridge == nil or not landfillInstalled then
    glob.bridge = false
  end

  if glob.flipSignals == nil then
    glob.flipSignals = false
  end
  if glob.settings.flipPoles == nil then
    glob.settings.flipPoles = false
  end
  glob.activeBP = glob.medium and glob.settings.bp.medium or glob.settings.bp.big
  glob.flipSignals = false
  glob.farl = glob.farl or {}
  glob.railInfoLast = glob.railInfoLast or {}
  glob.debug = glob.debug or {}
  glob.action = glob.action or {}
  glob.cruiseSpeed = glob.cruiseSpeed or 0.4
  for i,farl in ipairs(glob.farl) do
    farl = resetMetatable(farl, FARL)
    if glob.version < "0.1.4" then
      farl.cruiseInterrupt = 0
    end
    farl.index = nil
  end
  if glob.version < "0.1.4" then
    for i=1,#game.players do
      GUI.destroyGui(game.players[i])
    end
    glob.version = "0.1.4"
  end
  if glob.version < "0.1.8" then
    glob.settings.poleDistance = nil
    glob.settings.poleSide = nil
    if glob.medium then
      glob.settings.straight = defaultsMediumStraight
      glob.settings.diagonal = defaultsMediumDiagonal
    else
      glob.settings.straight = defaultsStraight
      glob.settings.diagonal = defaultsDiagonal
    end
    glob.version = "0.1.8"
  end
end
