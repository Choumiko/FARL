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
- Support for powered rails (5dim's mod)
- Support for [Bio Industries](https://mods.factorio.com/mods/TheSAguy/Bio_Industries) wooden rails

###Usage
[Look at the forums](https://forums.factorio.com/viewforum.php?f=61)

#Changelog
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