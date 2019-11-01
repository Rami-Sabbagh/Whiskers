--Powerup class, makes special game effects.

local tween = require("libraries.tween")
local class = require("libraries.middleclass")

local Kitten = require("whiskers.kitten")
local Pellet = require("whiskers.pellet")

local Powerup = class("whiskers.Powerup")

Powerup.types = {
	--"bomb",
	"bullet",
	"lightning",
	--"star"
}

Powerup.typesCalls = {
	--"gotBomb",
	"gotTurret",
	"gotLightning",
	--"gotStar"
}

--The duration of the lightning (scale) powerup overlay
Powerup.scaleDuration = 0.5

function Powerup:initialize( game, x, y, id )
	
	self.game = game
	
	self.world = self.game.world
	self.worldWidth, self.worldHeight = self.game.worldWidth, self.game.worldHeight
	
	self.id = id or love.math.random(1,#self.types)
	self.name = self.types[self.id]
	
	self.size = self.game.PTM*0.60
	
	self.image = _image[self.name.."Icon"]
	self.imageWidth, self.imageHeight = self.image:getDimensions()
	self.imageScale = self.size/self.imageWidth
	self.imageScale1 = self.imageScale
	self.imageScale2 = (self.game.PTM*0.68)/self.imageWidth
	
	self.imageOX, self.imageOY = self.imageWidth/2, self.imageHeight/2
	
	self.body = love.physics.newBody(self.world, x, y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size,self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	
	self.body:setUserData(self)
	
	self.tween1 = tween.new(self.scaleDuration, self, {imageScale = self.imageScale2})
	self.tween2 = tween.new(self.scaleDuration, self, {imageScale = self.imageScale1})
end

--Draw the powerup
function Powerup:draw()
	if self.dead then return end
	
	local bx, by = self.body:getPosition() --The current location of the powerup body
	local rot = self.body:getAngle() --The current angle of the powerup body
	
	love.graphics.setColor(1, 1, 1, 1) --We don't want to tint the image
	love.graphics.draw(self.image, bx,by, rot, self.imageScale, self.imageScale, self.imageOX,self.imageOY) --Draw the powerup
end

function Powerup:update(dt)
	if self.dead then
		
		if self.toApply then
			
			--Apply the powerup
			if self.toApply[self.typesCalls[self.id]] then
				self.toApply[self.typesCalls[self.id]](self.toApply)
			end
			
			self.toApply = nil
			
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
	
	if self.tweenFlag then
		self.tweenFlag = not self.tween2:update(dt)
		if not self.tweenFlag then
			self.tween1:set(0)
		end
	else
		self.tweenFlag = self.tween1:update(dt)
		if self.tweenFlag then
			self.tween2:set(0)
		end
	end
	
end

function Powerup:destroy()
	self.body:destroy()
	self.dead = true
end

function Powerup:preSolve(myFixture, otherFixture, contact)
	local other = otherFixture:getBody():getUserData()
	
	if type(other) ~= "table" then return end
	
	if other:isInstanceOf(Kitten) then
		contact:setEnabled(false)
		self:destroy()
		self.toApply = other
	end
end

return Powerup