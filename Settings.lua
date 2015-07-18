require "util"

Settings = {
  new = function(player)
    local new = {
      activeBP = {},
      bp = {},
      ccNet = false,
      ccWires = 1,
      collectWood = true,
      curvedWeight = 4,
      cruiseSpeed = 0.4,
      diagonal = {},
      dropWood = true,
      electric = false,
      flipPoles = false,
      flipSignals = false,
      signalDistance = 15,
      straight = {},
      medium = false,
      minPoles = true,
      poles = true,
      rail = {},
      signals = true,
      bridge = false,
      root = false
    }
    setmetatable(new, {__index=Settings})
    return new
  end,

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
    if not landfillInstalled then
      self.bridge = false
    end
    if not electricInstalled then
      self.electric = false
    end
  end,

  dump = function(self)
    saveVar(self, "dump"..self.player.name)
  end
}
