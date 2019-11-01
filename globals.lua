--Global variables
--Contains the list of all the global variables used in the game, including comments for ones not initialized in this file.

_DEBUG = false --The debug flag, true when the game is ran with `--debug`

_states = {} --Contains all the loaded states
for k, stateName in pairs(love.filesystem.getDirectoryItems("/states/")) do
	stateName = stateName:sub(1, -5) --Remove the .lua extension from the filename
	_states[stateName] = require("states."..stateName) --Load each state
end

_image = {} --Contains all the loaded images
_sfx = {} --Contains all the loaded sfx
_music = {} --Contains all the loaded music

_meowNames = {} --Contans the name of meow sfx
for i = 1, 10 do _meowNames[i] = (i < 10) and "meow-0"..i or "meow-"..i end