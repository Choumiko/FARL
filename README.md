# FARL
(Fully Automated Rail Layer)

- Places rails, signals, electric poles, concrete, etc. while driving
- Customizable placement of poles, multiple parallel tracks, lamps, turrets etc. with blueprints
- Bulldozer mode: removes rails,signals, poles, lamps, walls behind the train
- Maintenance mode: removes rails,signals, poles, lamps, walls in front of the train, places new layout
- Removes trees and stone rocks that are in the way (and adds 1 wood/tree, 15 stone/rock to cargo)
- Place rails on water if the train has concrete loaded
- Connects poles with red/green wires
- Cruise control: keeps the speed at ~87km/h (full speed when not placing rails) without pressing W, deactivate by pressing S
- For modders: Support for modded "compound" entities (Modders take a look at Mod support below)
- Support for modded rails, changeable via the settings  
![Rail types](http://imgur.com/zGHNyGK.png "Rail types")

### Usage
[Look at the forums](https://forums.factorio.com/viewforum.php?f=61)  
[FARL Autopilot](https://www.twitch.tv/choumiko/v/99457468)

### Hotkeys

- Press J (default) to toggle trains between automatic and manual mode when inside a train

### Console commands

- You have to be in a FARL for them to work
- /farl_read_bp /farl_clear_bp /farl_vertical_bp /farl_diagonal_bp

### Mod support

Modded rails should work out of the box, as soon as updating FARL to at least 1.0.6

There are 2 remote functions to tell FARL whether it should raise on_robot_built_entity/on_robot_pre_mined events for a specific entity:
 - `remote.call("farl", "add_entity_to_trigger", "entity-name")`

If FARL should no longer keep on raising the events use this command (probably never):
 - `remote.call("farl", "remove_entity_from_trigger", "entity-name")`
 
To make it work just add FARL as an optional dependency in your info.json and do the remote.call in on_configuration_changed.
FARL stores the names in global and only removes them if the interface is used or the entity doesn't exist anymore (checked in on_configuration_changed)