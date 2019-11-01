--Powerup class, makes special game effects.

local tween = require("libraries.tween")
local class = require("libraries.middleclass")

local Kitten = require("whiskers.kitten")
local Pellet = require("whiskers.pellet")

local Powerup = class("whiskers.Powerup")

Powerup.names = {
	--"bomb",
	"bullet",
	"lightning",
	--"star"
}

--Physics Fields
Powerup.size = 0.6 * _pixelsToMeterFactor --A powerup box is 0.6 meters large.

--The duration of powerup up-down scaling
Powerup.scaleDuration = 0.5

--Game Fields

--Lightning powerup
Powerup.lightningShrinkScale = Pellet.growthFactor
Powerup.lightningGrowScale = 1.68

function Powerup:initialize( world, x, y, typeID )
	self.world = world --The whiskers world
	self.worldWidth, self.worldHeight = self.world:getDimensions() --The dimensions of the world
	
	self.typeID = typeID or love.math.random(1, #self.names) --The typeID of the powerup
	self.name = self.names[self.typeID] --The name of the powerup
	
	self.body = love.physics.newBody(self.world:getB2World(), x, y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size,self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	
	self.body:setUserData(self)
	
	self.headless = true
	if not self.world:isHeadless() then self:initializeResources() end
end

--Initialize the graphics & audio sections of the powerup, skipped when running in headless mode.
-- It's safe to call this seperately after being initialized in headless mode, it'll just deactivate the headless mode and bring back graphics
function Powerup:initializeResources()
	self.headless = false

	self.image = _image[self.name.."Icon"]
	self.imageWidth, self.imageHeight = self.image:getDimensions()
	self.imageScale = self.size/self.imageWidth
	self.imageScale1 = self.imageScale
	self.imageScale2 = (_pixelsToMeterFactor*0.68)/self.imageWidth
	
	self.imageOX, self.imageOY = self.imageWidth/2, self.imageHeight/2

	self.tween1 = tween.new(self.scaleDuration, self, {imageScale = self.imageScale2})
	self.tween2 = tween.new(self.scaleDuration, self, {imageScale = self.imageScale1})
end

--Draw the powerup
function Powerup:draw()
	if self.consumed then return end
	
	local bx, by = self.body:getPosition() --The current location of the powerup body
	local rot = self.body:getAngle() --The current angle of the powerup body
	
	love.graphics.setColor(1, 1, 1, 1) --We don't want to tint the image
	love.graphics.draw(self.image, bx,by, rot, self.imageScale, self.imageScale, self.imageOX,self.imageOY) --Draw the powerup
end

function Powerup:update(dt)
	if self.consumed then
		if self.toApply then
			self["consumed"..self.name:sub(1,1):upper()..self.name:sub(2,-1)](self, self.toApply)
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

	if not self.headless then
	
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
end

function Powerup:destroy()
	self.body:destroy()
	self.consumed = true
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

--== Power up effecs ==--

function Powerup:consumedBullet(kitten)
	kitten:gotTurret()
end

function Powerup:consumedLightning(tKitten)
	for id, kitten in ipairs(self.world:getKittens()) do
		if kitten == tKitten then
			kitten:growByFactor(self.lightningGrowScale)
		else
			kitten:shrinkByFactor(self.lightningShrinkScale)
		end
	end
	
	self.world:showLightning()

	if not self.headless then
		_sfx["sirenWhistle"]:stop()
		_sfx["sirenWhistle"]:play()
	end
end

return Powerup