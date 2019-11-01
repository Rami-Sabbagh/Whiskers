local class = require("libraries.middleclass")
local tween = require("libraries.tween")

local Bullet = require("whiskers.bullet")

local Kitten = class("Kitten")

Kitten.density = 0.7
Kitten.traceDuration = 0.5
Kitten.scaleDuration = 0.5
Kitten.turretDuration = 7

function Kitten:initialize(game, id)
	self.game = game
	self.id = id
	
	self.traces = {}
	self.traceTweens = {}

	self.turretSFX = _sfx["sewingmachine"]
	
	self.bullets = {}
	
	self.size = self.game.PTM
	self.speed = (self.size*self.game.PTM)/4
	
	self.world = self.game.world
	self.worldWidth, self.worldHeight = self.game.worldWidth, self.game.worldHeight
	self.color = _colorPalette[self.id]
	
	self.image = _image["francineWhite"]
	self.imageSize = self.image:getDimensions()
	self.imageScale = self.size/self.imageSize
	
	self.traceImage = _image["directionArrow"]
	self.traceSize = self.traceImage:getDimensions()
	
	self.moustachX, self.moustachY = 307+14-self.imageSize/2, 139+28-self.imageSize/2
	self.moustachID = love.math.random(1,50)
	self.moustachImage = _image["Layer-"..self.moustachID]
	self.moustachWidth, self.moustachHeight = self.moustachImage:getDimensions()
	self.moustachCenterX = self.moustachWidth/2
	
	local x = self.size+love.math.random()*(self.worldWidth-self.size*2)
	local y = self.size+love.math.random()*(self.worldHeight-self.size*2)
	
	local rot = love.math.random(0,3)*math.pi*0.5
	
	self.body = love.physics.newBody(self.world, x, y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape, self.density)
	
	self.body:setUserData(self)
	self.body:setAngle(rot)
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(9)
	
	self.fixture:setFriction(0)
	self.fixture:setRestitution(0)
	self.fixture:setGroupIndex(-self.id)
end

function Kitten:setSize(size, animate)
	local oldsize = self.size
	
	self.size = math.min(size, self.game.winSize)
	self.size = math.max(self.size, self.game.PTM)
	
	self.fixture:destroy()
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape, self.density)
	
	self.fixture:setFriction(0)
	self.fixture:setRestitution(0)
	self.fixture:setGroupIndex(-self.id)
	
	local ix, iy = self.body:getLinearVelocity()
	self.body:setLinearVelocity(ix*(oldsize/self.size), iy*(oldsize/self.size))
	
	if animate then
		self.scaleTween = tween.new(self.scaleDuration, self, {imageScale = self.size/self.imageSize}, "outExpo")
	end
end

function Kitten:growByScale(scale)
	self:setSize(self.size * scale, true)
end

function Kitten:shrinkByScale(scale)
	self:setSize(self.size / scale, true)
end

function Kitten:drawMoustach()
	local dx, dy = self.body:getPosition()
	local dr = self.body:getAngle()
	
	love.graphics.setColor(1,1,1,1)
	
	love.graphics.push()
	
	love.graphics.translate(dx,dy)
	love.graphics.scale(self.imageScale)
	love.graphics.rotate(dr)
	
	love.graphics.draw(self.moustachImage, self.moustachX, self.moustachY, 0, 1,1, self.moustachCenterX, 0)
	
	love.graphics.pop()
end

function Kitten:drawBullets()
	for k, bullet in ipairs(self.bullets) do
		bullet:draw()
	end
end

function Kitten:drawBody()
	local dx, dy = self.body:getPosition()
	local dr = self.body:getAngle()
	
	love.graphics.push()
	
	love.graphics.translate(dx,dy)
	love.graphics.scale(self.imageScale)
	love.graphics.rotate(dr)
	
	love.graphics.setColor(love.graphics.getBackgroundColor())
	love.graphics.rectangle("fill",-self.imageSize/2,-self.imageSize/2, self.imageSize,self.imageSize)
	
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image,0,0, 0, 1,1, self.imageSize/2, self.imageSize/2)
	
	love.graphics.pop()
	
	self:drawBullets()
end

function Kitten:drawTraces()
	for k,trace in ipairs(self.traces) do
		love.graphics.setColor(trace.color)
		love.graphics.draw(
			self.traceImage,
			trace.cx,
			trace.cy,
			trace.rot,
			trace.scale,
			trace.scale,
			self.traceSize/2,
			self.traceSize/2
			)
	end
end

function Kitten:turn()
	local bx, by = self.body:getPosition()
	local rot = self.body:getAngle()
	
	local quarts = (rot*2)/math.pi
	
	rot = (math.floor(quarts+0.5) + 1) * math.pi * 0.5
	
	local traceStartColor = {unpack(self.color)}; traceStartColor[4] = 1
	local traceEndColor = {unpack(self.color)}; traceEndColor[4] = 0
	table.insert(self.traces,{ cx=bx,cy=by,rot=rot,scale=self.size/self.traceSize,color=traceStartColor })
	table.insert(self.traceTweens,tween.new(self.traceDuration,self.traces[#self.traces],{ color=traceEndColor },"outQuad"))
	
	
	self.body:setAngle(rot)
	self.body:setAngularVelocity(0)
	
	local ix = (math.cos(rot) * self.speed)/(self.size/self.game.PTM)
	local iy = (math.sin(rot) * self.speed)/(self.size/self.game.PTM)
	self.body:setLinearVelocity(ix,iy)
end

function Kitten:impulse()
	local bx, by = self.body:getPosition()
	local rot = self.body:getAngle()
	
	local ix = (math.cos(rot) * self.speed)/(self.size/self.game.PTM)
	local iy = (math.sin(rot) * self.speed)/(self.size/self.game.PTM)
	self.body:setLinearVelocity(ix,iy)
end

function Kitten:updateBullets(dt)
	for k, bullet in ipairs(self.bullets) do
		bullet:update(dt)
	end
end

function Kitten:update(dt)
	
	--Turret update
	self:updateBullets()
	if self.hasTurret then
		if not self.turretSFX:isPlaying() then
			self.turretSFX:play()
		end
		
		self.bulletTimer = self.bulletTimer - dt
		if self.bulletTimer <= 0 then
			self.bulletTimer = (self.size/self.game.PTM)/10
			
			table.insert(self.bullets, Bullet(self))
		end
		
		self.hasTurret = self.hasTurret - dt
		if self.hasTurret <= 0 then
			self.turretSFX:stop()
			self.hasTurret = false
		end
	end
	
	--Traces Update
	local removedTraces = 0
	for k,v in ipairs(self.traceTweens) do
		local done = v:update(dt)
		
		if done then removedTraces = removedTraces + 1 end
		
		self.traceTweens[k] = self.traceTweens[k+removedTraces]
		self.traces[k] = self.traces[k+removedTraces]
	end
	
	--Scale tween
	if self.scaleTween then
		local done = self.scaleTween:update(dt)
		if done then self.scaleTween = nil end
	end
	
	--Body Update
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

function Kitten:gotLightning()
	for id, kitten in ipairs(self.game.kittens) do
		if kitten == self then
			kitten:growByScale(self.game.lightningGrowScale)
		else
			kitten:shrinkByScale(self.game.lightningShrinkScale)
		end
	end
	
	self.game:showLightning()
	_sfx["sirenWhistle"]:stop()
	_sfx["sirenWhistle"]:play()
end

function Kitten:gotTurret()
	self.hasTurret = self.turretDuration
	self.bulletTimer = (self.size/self.game.PTM)/10
	
	self.turretSFX:stop()
	self.turretSFX:play()
end

return Kitten