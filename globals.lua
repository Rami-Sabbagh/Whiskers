--Global variables
--Contains the list of all the global variables used in the game, including comments for ones not initialized in this file.

_DEBUG = false --The debug flag, true when the game is ran with `--debug`

_image = {} --Contains all the loaded images
_sfx = {} --Contains all the loaded sfx
_music = {} --Contains all the loaded music

_meowNames = {} --Contains the name of meow sfx
for i = 1, 10 do _meowNames[i] = (i < 10) and "meow-0"..i or "meow-"..i end

--The color palette of the game
_colorPalette = {
	{96/255 , 246/255, 133/255, 1}, --Green
	{246/255, 207/255, 95/255 , 1}, --Yellow
	{95/255 , 134/255, 246/255, 1}, --Blue
	{246/255, 95/255 , 209/255, 1}, --Pink
	{246/255, 132/255, 96/255 , 1}  --Orange
}

for k, stateName in pairs(love.filesystem.getDirectoryItems("/states/")) do
	stateName = stateName:sub(1, -5) --Remove the .lua extension from the filename
	_states[stateName] = require("states."..stateName) --Load each state
