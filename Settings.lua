require "util"

rails = {
  basic = {curved = "curved-rail", straight = "straight-rail"},
  electric = {curved = "curved-power-rail", straight = "straight-power-rail"}}

--poleDistance = 1, side = right
defaultsDiagonal = {
  direction = 7,
  poleEntities = {{name = "small-lamp", position = {x = -1.5, y = 1.5}}},
  pole = {name = "big-electric-pole", position = {x = 2.5, y = 2.5}},
  rails = {}, signals = {}, lanes = {},
  boundingBox = {br = {x = 2.5, y = 4}, tl = {x = -1, y = 0}}}

defaultsStraight = {
  direction = 0,
  poleEntities = {{name = "small-lamp", position = {x = -0.5, y = 1.5}}},
  pole = {name = "big-electric-pole", position = {x = 3, y = -1}},
  rails = {}, signals = {}, lanes = {},
  boundingBox = {br = {x = 3, y = 0.5}, tl = {x = -0.5, y = -1}}}
  
defaultsCurve = {
  left = {
    direction = 0,
    poleEntities = {{name = "small-lamp", position = {x = -0.5, y = 1.5}}},
    pole = {name = "big-electric-pole", position = {x = 4, y = 2}},
    rails = {}, signals = {}, lanes = {},
    boundingBox = {br = {x=4.5,y=3.5}, tl = {x=-2.5,y=-3.5}}
  },
  
  right = {
    direction = 1,
    poleEntities = {{name = "small-lamp", position = {x = -0.5, y = 1.5}}},
    pole = {name = "big-electric-pole", position = {x = 2, y = 2}},
    rails = {}, signals = {}, lanes = {},
    boundingBox = {br = {x=3.5,y=4.5}, tl = {x=-1.5,y=-3.5}}
  }
}

defaultsMediumDiagonal = {
  direction = 7,
  poleEntities = {{name = "small-lamp", position = {x = -1, y = 1}}},
  pole = {name = "medium-electric-pole", position = {x = 2, y = 2}},
  rails = {}, signals = {}, lanes = {},
  boundingBox = {br = {x = 1, y = 4}, tl = {x = -2, y = 0}}}

defaultsMediumStraight = {
  direction = 0,
  poleEntities = {{name = "small-lamp", position = {x = 0,y = 1}}},
  pole = {name = "medium-electric-pole", position = {x = 2.5,y = -0.5}},
  rails = {}, signals = {}, lanes = {},
  boundingBox = {br = {x = 2.5, y = 0.5}, tl = {x = -1.5, y = -1}}}

defaultsCurveMedium = {
  left = {
    direction = 0,
    poleEntities = {{name = "small-lamp", position = {x = 0, y = 1}}},
    pole = {name = "medium-electric-pole", position = {x = 3.5, y = 1.5}},
    rails = {}, signals = {}, lanes = {},
    boundingBox = {br = {x=3.5,y=3.5}, tl = {x=-2.5,y=-3.5}}
  },
  
  right = {
    direction = 1,
    poleEntities = {{name = "small-lamp", position = {x = 0, y = 1}}},
    pole = {name = "medium-electric-pole", position = {x = 1.5, y = 1.5}},
    rails = {}, signals = {}, lanes = {},
    boundingBox = {br = {x=2.5,y=3.5}, tl = {x=-1.5,y=-3.5}}
  }
}

defaults_concrete_diag = {
  entities = {
    {
      direction = 7,
      entity_number = 1,
      name = "straight-rail",
      position = {x = -1,y = -1}},
    {
      direction = 5,
      entity_number = 2,
      name = "rail-chain-signal",
      position = {x = -0.5,y = -0.5}},
    {
      entity_number = 3,
      name = "big-electric-pole",
      position = {x = 1,y = 0}},
    {
      direction = 7,
      entity_number = 4,
      name = "straight-rail",
      position = {x = 3,y = 3}},
    {
      direction = 1,
      entity_number = 5,
      name = "rail-signal",
      position = {x = 1.5,y = 1.5}}
  },
  tiles = {
    { name = "concrete", position = {x = -3,y = -3}},
    { name = "concrete", position = {x = -2,y = -3}},
    { name = "concrete", position = {x = -2,y = -2}},
    { name = "concrete", position = {x = -1,y = -2}},
    { name = "concrete", position = {x = -1,y = -1}},
    { name = "concrete", position = {x = 0,y = -1}},
    { name = "concrete", position = {x = 0,y = 0}},
    { name = "concrete", position = {x = 1,y = 0}},
    { name = "concrete", position = {x = 1,y = 1}},
    { name = "concrete", position = {x = 2,y = 1}},
    { name = "concrete", position = {x = 2,y = 2}},
    { name = "concrete", position = {x = 3,y = 2}},
    { name = "concrete", position = {x = 3,y = 3}}
  }
}

defaults_concrete_vert = {
  entities = {
    {
      entity_number = 1,
      name = "big-electric-pole",
      position = {x = 0,y = 0}},
    {
      entity_number = 2,
      name = "straight-rail",
      position = {x = -3,y = 1}},
    {
      direction = 4,
      entity_number = 3,
      name = "rail-chain-signal",
      position = {x = -1.5,y = 1.5}},
    {
      entity_number = 4,
      name = "rail-signal",
      position = {x = 1.5,y = 1.5}},
    {
      entity_number = 5,
      name = "straight-rail",
      position = {x = 3,y = 1}}
  },
  tiles = {
    { name = "concrete",
      position = {x = -5,y = 0}},
    { name = "concrete",
      position = {x = -5,y = 1}},
    { name = "concrete",
      position = {x = -4,y = 0}},
    { name = "concrete",
      position = {x = -4,y = 1}},
    { name = "concrete",
      position = {x = -3,y = 0}},
    { name = "concrete",
      position = {x = -3,y = 1}},
    { name = "concrete",
      position = {x = -2,y = 0}},
    { name = "concrete",
      position = {x = -2,y = 1}},
    { name = "concrete",
      position = {x = -1,y = 0}},
    { name = "concrete",
      position = {x = -1,y = 1}},
    { name = "concrete",
      position = {x = 0,y = 0}},
    { name = "concrete",
      position = {x = 0,y = 1}},
    { name = "concrete",
      position = {x = 1,y = 0}},
    { name = "concrete",
      position = {x = 1,y = 1}},
    { name = "concrete",
      position = {x = 2,y = 0}},
    { name = "concrete",
      position = {x = 2,y = 1}},
    { name = "concrete",
      position = {x = 3,y = 0}},
    { name = "concrete",
      position = {x = 3,y = 1}},
    { name = "concrete",
      position = {x = 4,y = 0}},
    { name = "concrete",
      position = {x = 4,y = 1}}
  }
}

defaultSettings =
  {
    activeBP = {},
    bp = {
      medium= {diagonal=defaultsMediumDiagonal, straight=defaultsMediumStraight, curves=defaultsCurveMedium},
      big=    {diagonal=defaultsDiagonal, straight=defaultsStraight, curves=defaultsCurve}},
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
    concrete = true
  }

defaultSettings.activeBP = defaultSettings.bp.big

Settings = {
  loadByPlayer = function(player)
    local name = player.name
    if name and name == "" then
      name = "noname"
    end
    local settings = util.table.deepcopy(defaultSettings)
    if not global.players[name] then
      global.players[name] = settings
    end
    global.players[name].player = player
    setmetatable(global.players[name], Settings)
    return global.players[name]
  end,

  update = function(self, key, value)
    if type(key) == "table" then
      for k,v in pairs(key) do
        self[k] = v
      end
    else
      self.key = value
    end
  end,

  checkMods = function(self)
    if not global.electricInstalled then
      self.electric = false
    end
  end,

  dump = function(self)
    saveVar(self, "dump"..self.player.name)
  end
}
