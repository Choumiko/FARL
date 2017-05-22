# FARL
(Fully Automated Rail Layer)

- places rails, signals, electric poles, concrete, etc. while driving
- customizable placement of poles, multiple parallel tracks, lamps, turrets etc. with blueprints
- Bulldozer mode: removes rails,signals, poles, lamps, walls behind the train
- Maintenance mode: removes rails,signals, poles, lamps, walls in front of the train, places new layout
- removes trees and stone rocks that are in the way (and adds 1 wood/tree, 15stone/rock to cargo)
- place rails on water if the train has concrete loaded
- connects poles with red/green wires
- Cruise control: keeps the speed at ~87km/h (full speed when not placing rails) without pressing W, deactivate by pressing S
- For modders: Support for modded "compound" entities (Modders take a look at Mod support below)
- Support for modded rails, changeable via the settings
![Rail types](http://imgur.com/zGHNyGK.png "Rail types")

###Usage
[Look at the forums](https://forums.factorio.com/viewforum.php?f=61)  
[FARL Autopilot](https://www.twitch.tv/choumiko/v/99457468)

###Hotkeys

- Press J (default) to toggle trains between automatic and manual mode when inside a train

###Mod support

Modded rails should work out of the box, as soon as updating FARL to at least 1.0.6

There are 2 remote functions to tell FARL whether it should raise on_robot_built_entity/on_robot_pre_mined events for a specific entity:

- remote.call("farl", "add_entity_to_trigger", "entity-name")

If FARL should no longer keep on raising the events use this command (probably never):
- remote.call("farl", "remove_entity_from_trigger", "entity-name")
 
To make it work just add FARL as an optional dependency in your info.json and do the remote.call in on_configuration_changed.
FARL stores the names in global and only removes them if the interface is used or the entity doesn't exist anymore (checked in on_configuration_changed)


#Changelog
1.0.7

 - fixed errors when opening the settings 
 
1.0.6

 - added support for modded rails in the FARL settings

1.0.5

 - fixed crash when a locomotive or cargo wagon where destroyed

1.0.4

 - fixed cruise control not working when driving the "backwards" locomotive in double headers
 - fixed FARL freezing the game when creating a loop with rail ghosts and using the Autopilot

1.0.2

 - fixed gui not being destroyed when mining the FARL the player is in

1.0.1

 - fixed error with invalid item name

1.0.0

 - version for Factorio 0.15.x
 - added error messages when reading invalid/too many blueprints

0.7.5

 - FARL gets the same equipment grid as the vanilla locomotive, if FARL doesn't already have another grid assigned

0.7.4

 - fixed a load order issue with [VehiclesEquipement](https://mods.factorio.com/mods/Y.Petremann/VehiclesEquipement)
 - fixed FARLs with an equipment grid loosing the equipment when mined

0.7.3

 - fixed FARL looking for blueprints in the main inventory instead of the quickbar when in Sandbox scenario / god controller

0.7.2

 - fixed error when FARL was the only mod that added a hotkey
 
0.7.1
 
 - added hotkey to toggle between automatic/manual mode when inside a train (Hotkey is only added when [Honk](https://mods.factorio.com/mods/GotLag/Honk) isn't installed)
 - fixed FARL only reading blueprints in the first 3 quickbar rows
 - fixed error when removing trees that don't drop an item when mined

0.7.0
 
 - FARL scans for ghost tracks in front of it when activating and follows them
 - FARL can follow ghost tracks on its own (Select "Drive without me" once FARL has detected ghost tracks)
 - added equipment grids to locomotives. Any locomotive with a FARL-Roboport equipped will now work like FARL
 - fixed blueprints for entites with direction/recipe (e.g. Flamethrower)
 - FARL raises on_robot_built_entity/on_robot_pre_mined events whenever an electric pole is created/destroyed
  
0.6.0

 - version for Factorio 0.14.x

0.5.37

 - collect/drop wood option now also affects stone from rocks
 - if game.player.cheat_mode is set to true, FARL doesn't use items
 - cheat_mode/godmode does not drop wood/stone if the train is full 
 
0.5.36

 - added support for [Bio Industries](https://mods.factorio.com/mods/TheSAguy/Bio_Industries) wooden rails
 - fixed parallel tracks always having the force of the first player

0.5.35

 - fixed signals not being found in blueprints if placed in the wrong tile
 - fixed error with hazard-concrete

0.5.34

- fixed bulldozer mode eating rails when removing curved track

0.5.33
 
-  removed workaround for [Factorio bug](https://forums.factorio.com/viewtopic.php?f=11&t=27188)

0.5.32

 - fixed signal distance on vertical tracks

0.5.31

- fixed bulldozer mode not working
- fixed error when creating default blueprints