local class = require("libraries.middleclass")

local Kitten = require("whiskers.kitten")

local Pellet = class("whiskers.Pellet")

function Pellet:initialize( game, x, y )
	
--Static variables
Pellet.growScale = 1.44 --The scale factor of the kittens when a pellet is eaten.

	self.game = game
	
	self.size = self.game.PTM/4
	
	self.world = self.game.world
	self.worldWidth, self.worldHeight = self.game.worldWidth, self.game.worldHeight
	self.color = self.game.kittenColors[5]
	
	local x = x or self.size+love.math.random()*(self.worldWidth-self.size*2)
	local y = y or self.size+love.math.random()*(self.worldHeight-self.size*2)
	
	self.body = love.physics.newBody(self.world, x,y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	
	self.body:setUserData(self)
end

function Pellet:draw()
	if self.dead then return end
	
	love.graphics.push()
	
	love.graphics.setColor(self.color)
	
	local dx, dy = self.body:getPosition()
	local dr = self.body:getAngle()
	
	love.graphics.translate(dx,dy)
	love.graphics.rotate(dr)
	
	love.graphics.rectangle("fill",-self.size/2, -self.size/2, self.size, self.size, self.size/4, self.size/4)
	
	love.graphics.pop()
end

function Pellet:update(dt)
	if self.dead then
		
		if self.toGrow then
			self.toGrow:growByScale(self.game.pelletGrowScale)
			self.toGrow = nil
		end
		
		return
	end
	
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

function Pellet:destroy()
	self.body:destroy()
	self.dead = true
end

function Pellet:preSolve(myFixture, otherFixture, contact)
	local other = otherFixture:getBody():getUserData()
	
	if type(other) ~= "table" then return end
	
	if other:isInstanceOf(Kitten) then
		contact:setEnabled(false)
		self:destroy()
		self.toGrow = other
		_sfx["munch"]:play()
	end
end

return Pellet