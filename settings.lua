require "defines"
require "util"
godmode = false
removeStone = true

polePlacement = {
    side = 1, -- 1 for right side of travel direction, -1 for left
    distance = 2, -- distance from track in tiles (lower than 2 is still not working correct
    data = {},
    dir = {}
}