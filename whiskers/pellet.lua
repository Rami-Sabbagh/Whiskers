--Pellet class, grows the kittens when eaten.
local class = require("libraries.middleclass")
local Pellet = class("whiskers.Pellet")

local Kitten = require("whiskers.kitten")

--Default fields
Pellet.color = _colorPalette[5] --The default color of the pellet.
Pellet.size = 0.25 * _pixelsToMeterFactor --The size of a pellet is 0.25 meters
Pellet.growthFactor = 1.44 --The growth factor of the kitten when a pellet is eaten.

--Spawn at a new location
-- world: The whiskers world instance
-- x, y: (optional) The specific position to spawn the pellet in.
--
-- Note: world:spawnPellet() is better because it accounts for nearby objects when spawning.
function Pellet:initialize(world, x, y)
	self.world = world --The whiskers world
	self.worldWidth, self.worldHeight = self.world:getDimensions() --The dimensions of the world
	
	--Either be spawned at a specific position, or at a random one.
	x = x or self.size + love.math.random()*(self.worldWidth - self.size*2)
	y = y or self.size + love.math.random()*(self.worldHeight - self.size*2)
	
	--Create the physics body, shape and fixture (bring the object into existance)
	self.body = love.physics.newBody(self.world:getB2World(), x,y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	
	self.body:setUserData(self) --Set the userdata to be the class instance itself.
end

--Draw the pellet
function Pellet:draw()
	if self.consumed then return end

	local bodyX, bodyY = self.body:getPosition() --Get the current position of the pellet
	local bodyAngle = self.body:getAngle() --Get the current angle of the pellet

	love.graphics.push() --Push the matrix
	love.graphics.setColor(self.color) --Set the color of the pellet
	
	love.graphics.translate(bodyX, bodyY) --Translate the camera into the pellet location
	love.graphics.rotate(bodyAngle) --Rotate the camera to the pellet angle
	
	--Draw the pellet, which is a rectangle with rounded corners
	love.graphics.rectangle("fill", -self.size/2, -self.size/2, self.size, self.size, self.size/4)
	
	love.graphics.pop() --Pop the matrix
end

--Grow the kitten which ate the pellet, and wrap the pellet around the world edges.
function Pellet:update(dt)
	if self.consumed then
		if self.toGrow then
			self.toGrow:growByFactor(self.growthFactor)
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
	self.consumed = true
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
		
		--Play the munch sound
		_sfx["munch"]:stop()
		_sfx["munch"]:play()
	end
end

return Pellet