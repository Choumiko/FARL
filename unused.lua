local function chiral_direction(prev, next_r, prev_dir)
    return chiral_directions[get_rail_data(prev).chirality == get_rail_data(next_r).chirality][prev_dir]
end

--seg_end is closer to the cardinal direction rail_direction points at
--seg_dir points towards the cardinal direction (or whereever seg_end points at)
--I guess after using this we are doomed to forget about the cardinal direction
--We are now following the tracks like a train and should keep that perspective
local function jump_to_end(rail, rail_direction)--luacheck: no unused
    local seg_end, seg_dir = rail.get_rail_segment_end(rail_direction)
    return seg_end, seg_dir
end