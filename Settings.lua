require "util"

rails = {
  basic = {curved = "curved-rail", straight = "straight-rail"},
  electric = {curved = "curved-power-rail", straight = "straight-power-rail"}}

--poleDistance = 1, side = right
defaultsDiagonal = {
  direction = 7,
  poleEntities = {{name = "small-lamp", position = {x = -1.5, y = 1.5}}},
  pole = {name = "big-electric-pole", position = {x = 2.5, y = 2.5}},
  rails = {}, signals = {},
  boundingBox = {br = {x = 2.5, y = 4}, tl = {x = -1, y = 0}}}

defaultsStraight = {
  direction = 0,
  poleEntities = {{name = "small-lamp", position = {x = -0.5, y = 1.5}}},
  pole = {name = "big-electric-pole", position = {x = 3, y = -1}},
  rails = {}, signals = {},
  boundingBox = {br = {x = 3, y = 0.5}, tl = {x = -0.5, y = -1}}}

defaultsMediumDiagonal = {
  direction = 7,
  poleEntities = {{name = "small-lamp", position = {x = -1, y = 1}}},
  pole = {name = "medium-electric-pole", position = {x = 2, y = 2}},
  rails = {}, signals = {},
  boundingBox = {br = {x = 1, y = 4}, tl = {x = -2, y = 0}}}

defaultsMediumStraight = {
  direction = 0,
  poleEntities = {{name = "small-lamp", position = {x = 0,y = 1}}},
  pole = {name = "medium-electric-pole", position = {x = 2.5,y = -0.5}},
  rails = {}, signals = {},
  boundingBox = {br = {x = 2.5, y = 0.5}, tl = {x = -1.5, y = -1}}}

defaultSettings =
  {
    activeBP = {},
    bp = {
      medium= {diagonal=defaultsMediumDiagonal, straight=defaultsMediumStraight},
      big=    {diagonal=defaultsDiagonal, straight=defaultsStraight}},
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
    parallelLag = 6,
    boundingBoxOffsets = {
      straight = {tl={x=-0.5,y=0},br={x=0,y=0}},
      diagonal = {tl={x=0,y=0},br={x=0.5,y=0.5}}}
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
    if not global.players[name].boundingBoxOffsets then
      global.players[name].boundingBoxOffsets = util.table.deepcopy(settings.boundingBoxOffsets)
    end
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
