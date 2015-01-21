require "defines"
require "util"
godmode = false
godmodePoles = false
godmodeSignals = false
removeStone = true

polePlacement = {
    side = 1, -- 1 for right side of travel direction, -1 for left
    distance = 2, -- distance from track in tiles (lower than 2 is still not working correct
    data = {},
    dir = {}
}
signalPlacement = {
    curvedWeight = 4, -- count curved rails as this many straight rails
    distance = 15 -- straight rails between signals 
}