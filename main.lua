local gamestate = require("libraries.gamestate")
local lovebird = require("libraries.lovebird")

require("globals") --Load the game's globals

function love.load(args)
	if args[#args] == "--debug" then
		_DEBUG = true
	end
	
	if _DEBUG then lovebird.init() end
	
	gamestate.registerEvents()
	gamestate.switch(_states["splash"])
end

function love.update(dt)
	if _DEBUG then lovebird.update(dt) end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
end