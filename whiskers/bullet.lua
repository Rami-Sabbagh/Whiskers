--Bullet class, the kitten eye which is being shot at other kitties.

local class = require("libraries.middleclass")
local Bullet = class("whiskers.Bullet")

local Kitten --The kitten class, loaded in initialize to avoid stack overflows

Bullet.sizeRatio = 84/504 --Used for calculating the bullet size by multiplying this factor by the kitten size.
Bullet.speed = (32*32)/3

function Bullet:initialize(kitten)
	Kitten = Kitten or require("whiskers.kitten") --Load the kitten class if not loaded
	
	self.game = kitten.game --The game state which the bullet is running in.
	self.world = kitten.game.world --The physics world of the game.
	self.worldWidth, self.worldHeight = self.game.worldWidth, self.game.worldHeight --The dimensions of the physics world
	
	self.kitten = kitten --The parent kitten which is shooting the bullets
	self.id = self.kitten.id --The id of the kitten which is shooting the bullets
	self.color = self.kitten.color --The color of the kitten which is shooting the bullets
	
	self.size = self.kitten.size * self.sizeRatio --The size of the bullet
	
	self.image = _image["eyeBullet2"] --The image of bullet
	self.imageWidth, self.imageHeight = self.image:getDimensions() --The dimensions of the bullet image
	self.imageScale = self.size/self.imageWidth --The scale factor to draw the image with
	
	self.imageOX, self.imageOY = self.imageWidth/2, self.imageHeight/2 --The origin of the image, calculated to be the center.
	
	local kittenScale = self.kitten.size/self.game.PTM
	local kittenX, kittenY = self.kitten.body:getPosition()
	local kittenRot = self.kitten.body:getAngle()
	
	local spawnX = kittenX + (math.cos(kittenRot)*125 + math.sin(kittenRot)*155)*self.imageScale
	local spawnY = kittenY - (math.cos(kittenRot)*155 - math.sin(kittenRot)*125)*self.imageScale
	
	self.body = love.physics.newBody(self.world, spawnX, spawnY, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape)
	
	self.body:setUserData(self)
	self.body:setAngle(kittenRot)
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(9)
	
	self.fixture:setFriction(0)
	self.fixture:setRestitution(0)
	self.fixture:setGroupIndex(-self.id)
	
	if love.math.random(1,4) % 2 == 0 then
		kittenRot = kittenRot + love.math.random()*math.rad(3)
	else
		kittenRot = kittenRot - love.math.random()*math.rad(3)
	end
	
	local vx = math.cos(kittenRot)*self.speed
	local vy = math.sin(kittenRot)*self.speed
	
	self.body:setLinearVelocity(vx,vy)
end

function Bullet:draw()
	if self.dead then return end
	
	local bx, by = self.body:getPosition()
	local rot = self.body:getAngle()
	
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, bx, by, rot, self.imageScale, self.imageScale, self.imageOX, self.imageOY)
end

function Bullet:update(dt)
	if self.dead then
		
		if self.toShrink then
			self.toShrink:shrinkByScale(self.game.bulletScale)
			self.kitten:growByScale(self.game.bulletScale)
			
			self.toShrink = nil
		end
		
		return
	end
	
	local bx, by = self.body:getPosition()
	
	if bx+self.size/2 <= 0 or by+self.size/2 <= 0 or bx-self.size/2 >= self.worldWidth or by-self.size/2 >= self.worldHeight then
		self:destroy()
	end
end

function Bullet:destroy()
	self.fixture:destroy()
	self.body:destroy()
	
	self.dead = true
end

function Bullet:beginContact( myFixture, otherFixture, contact )
	local other = otherFixture:getBody():getUserData()
	
	self:destroy()
	
	if type(other) ~= "table" or not other:isInstanceOf(Kitten) then return end
	
	contact:setEnabled(false)
	self.toShrink = other
end

return Bullet