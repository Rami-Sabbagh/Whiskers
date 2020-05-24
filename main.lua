--Whiskers game, a 2-4 players tablet's game.
--Originally by johnstoked, ported to LÖVE by Rami Sabbagh (RamiLego4Game)

--[[
Debug mode:
===========

Run the game with --debug to enable the debug mode

The debug mode does the following:
----------------------------------

- Disable the music in the game state.
- Enable lovebird, a browser based Lua debugger.
]]

local gamestate = require("libraries.gamestate")
local lovebird = require("libraries.lovebird")

require("globals") --Load the game's globals

function love.load(args)
	if args[#args] == "--debug" then _DEBUG = true end --Set the debug flag if --debug is passed
	if _DEBUG then lovebird.init() end --Initialize lovebird if running in debug mode

	love.physics.setMeter(_pixelsToMeterFactor) --Set the physics PTM factor

	--Load the states
	for k, stateName in pairs(love.filesystem.getDirectoryItems("/states/")) do
		stateName = stateName:sub(1, -5) --Remove the .lua extension from the filename
		_states[stateName] = require("states."..stateName) --Load each state
	end
	
	gamestate.registerEvents() --Setup the states system
	gamestate.switch(_states["splash"]) --Switch to the splash state
end

function love.update(dt)
	if _DEBUG then lovebird.update(dt) end --Update lovebird if running in debug mode
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit() --Quit if escape (or the back key on mobile) is pressed
	end
end