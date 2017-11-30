local GameState = require("Libraries.gamestate")
local lovebird = require("Libraries.lovebird")

local SplashState = require("States.Splash")

function love.load(args)
  if args[#args] == "-debug" then
    _DEBUG = true
  end
  
  if _DEBUG then lovebird.init() end
  
  GameState.registerEvents()
  GameState.switch(SplashState)
end

function love.update(dt)
  if _DEBUG then lovebird.update(dt) end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  end
end