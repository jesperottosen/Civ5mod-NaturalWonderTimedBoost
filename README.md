# Civ5mod-NaturalWonderVictoryBooster
![Updated Natural Wonders](https://github.com/jesperottosen/Civ5mod-NaturalWonderTimedBoost/blob/main/Steam%20description/NWTB%20both.png?raw=true)

## Installation
Installation via Steam:
Or by downloading the most recent civ5mod-files from the Build folder.

## Mod design
First I removed the existing El Dorado and Fountain of Youth wonders using a small mod developed by Erik Taurus.
Then I add them back in with new names and wonder placement. Definition inspired by Natural Wonders Enhanced by Leo.
The core LUA file and functions are inspired by the Fortress With Borders mod by conan.morris.

Discovering one of the updated natural wonders trickers a turn timer being counted down each turn. When the time is up a reward is given and the timer starts over. 
The timer restarting after the reward makes the player wait around before triggering the reward again.

### GameEvents.UnitSetXY.Add( doUnitPositionChanged )
When a unit changes position, check if the plot is one of the wonders - exit as fast as possible if not.
check for a timer in the database, if no timer is set, then set a timer (remaining turns, position, owner).
if there is a timer notify how long time there is left.

### GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)
When the turns end (and it does for every player human, minor Civ etc), check if there is a timer for either of the wonders.
if there is an active timer, count it one down. If the time is up give a reward if the timer belongs to a player.
After rewarding the player, clear the ownership of the surrounding plots. 
If the timer belongs to no player (-1), release the timer for recapture.
