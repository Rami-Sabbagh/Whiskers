local gamestate = require("libraries.gamestate")
local lovebird = require("libraries.lovebird")

local splashState = require("states.splash")

function love.load(args)
	if args[#args] == "--debug" then
		_DEBUG = true
	end
	
	if _DEBUG then lovebird.init() end
	
	gamestate.registerEvents()
	gamestate.switch(splashstate)
end

function love.update(dt)
	if _DEBUG then lovebird.update(dt) end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
end