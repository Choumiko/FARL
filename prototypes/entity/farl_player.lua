local player = copyPrototype("player", "player", "farl_player")
player.healing_per_tick = 100
player.collision_mask = {"ghost-layer"}
player.inventory_size = 0
player.build_distance = 0
player.drop_item_distance = 0
player.reach_distance = 0
player.reach_resource_distance = 0
player.ticks_to_keep_gun = 0
player.ticks_to_keep_aiming_direction = 0
player.running_speed = 0
player.distance_per_frame = 0
player.mining_speed = 0
data:extend({player})
