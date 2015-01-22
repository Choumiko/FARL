require "defines"
require "util"
godmode = false
godmodePoles = false
godmodeSignals = false
removeStone = true

polePlacement = {
    side = 1, -- 1 for right side of travel direction, -1 for left
    distance = 1, -- distance from track in tiles
    data = {},
    dir = {}
}
signalPlacement = {
    curvedWeight = 4, -- count curved rails as this many straight rails
    distance = 15 -- straight rails between signals 
}