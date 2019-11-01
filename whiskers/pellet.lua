--Pellet class, grows the kittens when eaten.

local Kitten = require("whiskers.kitten")

local class = require("libraries.middleclass")
local Pellet = class("whiskers.Pellet")

--Static variables
Pellet.growScale = 1.44 --The scale factor of the kittens when a pellet is eaten.
Pellet.color = _colorPalette[5] --The default color of the pellet.

--Spawn at a new location
-- game: The game state to spawn the pllet in.
-- x, y: (optional) The specific position to spawn the pellet in.
function Pellet:initialize(game, x, y)
	self.game = game
	
	self.size = self.game.PTM/4 --The size of the pellet
	
	self.world = self.game.world --The physics world of the game
	self.worldWidth, self.worldHeight = self.game.worldWidth, self.game.worldHeight --The dimensions of the world
	
	--Either be spawned at a specific position, or at a random one.
	x = x or self.size + love.math.random()*(self.worldWidth - self.size*2)
	y = y or self.size + love.math.random()*(self.worldHeight - self.size*2)
	
	--Create the physics body, shape and fixture (bring the object into existance)
	self.body = love.physics.newBody(self.world, x,y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	
	self.body:setUserData(self) --Set the userdata to be the class instance itself.
end

--Draw the pellet
function Pellet:draw()
	if self.dead then return end

	local dx, dy = self.body:getPosition() --Get the current position of the pellet
	local dr = self.body:getAngle() --Get the current angle of the pellet

	love.graphics.push() --Push the matrix
	love.graphics.setColor(self.color) --Set the color of the pellet
	
	love.graphics.translate(dx,dy) --Translate the camera into the pellet location
	love.graphics.rotate(dr) --Rotate the camera to the pellet angle
	
	--Draw the pellet, which is a rectangle with rounded corners
	love.graphics.rectangle("fill", -self.size/2, -self.size/2, self.size, self.size, self.size/4)
	
	love.graphics.pop() --Pop the matrix
end

--Grow the kitten which ate the pellet, and wrap the pellet around the world edges.
function Pellet:update(dt)
	if self.dead then
		if self.toGrow then
			self.toGrow:growByScale(self.growScale)
			self.toGrow = nil --We don't want to keep growing that kitten xd
		end
		
		return
	end
	
	--Teleport/Wrap the pellet at the world borders

	local bx, by = self.body:getPosition()
	if bx < 0 then
		self.body:setX(self.worldWidth)
	elseif bx > self.worldWidth then
		self.body:setX(0)
	end
	
	if by < 0 then
		self.body:setY(self.worldHeight)
	elseif by > self.worldHeight then
		self.body:setY(0)
	end
end

--Destroy the pellet's body and no longer draw the pellet.
function Pellet:destroy()
	self.body:destroy()
	self.dead = true
end

--When a kitten collides with the pellet, destroy the pellet, and make the kitten grow at the next update tick.
function Pellet:preSolve(myFixture, otherFixture, contact)
	local other = otherFixture:getBody():getUserData()
	if type(other) ~= "table" then return end
	
	--If the pellet has collided with a kitten
	if other:isInstanceOf(Kitten) then
		contact:setEnabled(false) --Disable the contact, so the kitten doesn't lose it's momentum
		self:destroy() --Destroy the pellet
		self.toGrow = other --Set the kitten to be grown at the next update tick
		_sfx["munch"]:play() --Play the munch sound
	end
end

return Pellet