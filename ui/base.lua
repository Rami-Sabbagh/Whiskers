--UI objects base class

local class = require("libraries.middleclass")
local base = class("ui.Base")

function base:initialize() end

function base:draw() end
function base:update(dt) end

function base:keypressed(key, scancode, isRepeat) end
function base:keyreleased(key, scancode) end

function base:mousepressed(x, y, button, isTouch) end
function base:mousemoved(x, y, dx, dy, isTouch) end
function base:mousereleased(x, y, button, isTouch) end

function base:touchpressed(id, x,y, dx,dy, pressure) end
function base:touchmoved(id, x,y, dx,dy, pressure) end
function base:touchreleased(id, x,y, dx,dy, pressure) end

return base