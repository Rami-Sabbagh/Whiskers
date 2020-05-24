--The kitten class, which is the main object of the game
local class = require("libraries.middleclass")
local Kitten = class("whiskers.Kitten")

local tween = require("libraries.tween")
local Bullet = require("whiskers.bullet")

--Game fields
Kitten.maximumSize = 7.8 * _pixelsToMeterFactor --A Kitten has to be 7.8 meters large to win (they start with the size of 1 meter)
Kitten.names = {"clarence", "helen", "johnr", "margie"}

--Physics fields
Kitten.size = _pixelsToMeterFactor --A kitten is 1 meters large
Kitten.speed = (Kitten.size*_pixelsToMeterFactor)/4 --The movement speed of the kitten
Kitten.density = 0.7 --The density of the kitten

--Animations fields
Kitten.traceDuration = 0.5
Kitten.scaleDuration = 0.5
Kitten.turretDuration = 7

function Kitten:initialize(world, playerID)
	self.world = world --The whiskers world
	self.worldWidth, self.worldHeight = self.world:getDimensions() --The dimensions of the whiskers world

	self.playerID = playerID --The kitten ID {1, 2, 3, 4}
	
	self.bullets = {} --The bullets shot by the kitten

	--Physics body creation
	local x = self.size+love.math.random()*(self.worldWidth-self.size*2)
	local y = self.size+love.math.random()*(self.worldHeight-self.size*2)
	local rot = love.math.random(0,3)*math.pi*0.5
	
	self.body = love.physics.newBody(self.world:getB2World(), x, y, "dynamic")
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape, self.density)
	
	self.body:setUserData(self)
	self.body:setAngle(rot)
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(9)
	
	self.fixture:setFriction(0)
	self.fixture:setRestitution(0)
	self.fixture:setGroupIndex(-self.playerID)

	self.headless = true
	if not self.world:isHeadless() then self:initializeResources() end
end

--Initialize the graphics & audio sections of the kitten, skipped when running in headless mode.
-- It's safe to call this seperately after being initialized in headless mode, it'll just deactivate the headless mode and bring back graphics
function Kitten:initializeResources()
	self.headless = false

	self.turretSFX = _sfx["sewingmachine"]

	self.color = _colorPalette[self.playerID]
	self.name = self.names[self.playerID]

	self.image = _image["francineWhite"]
	self.imageSize = self.image:getWidth()
	self.imageScale = self.size/self.imageSize

	self.moustachX, self.moustachY = 307+14-self.imageSize/2, 139+28-self.imageSize/2
	self.moustachID = love.math.random(1,50) --TODO: mustach selection
	self.moustachImage = _image["Layer-"..self.moustachID]
	self.moustachWidth, self.moustachHeight = self.moustachImage:getDimensions()
	self.moustachCenterX = self.moustachWidth/2

	self.traces = {}
	self.traceTweens = {}
	self.traceImage = _image["directionArrow"]
	self.traceSize = self.traceImage:getDimensions()
end

--== Getter methods ==--

function Kitten:getName() return self.name end
function Kitten:getPlayerID() return self.playerID end

--== Kitten size control methods ==--

--Set the size of the kitten
function Kitten:setSize(size, animate)
	local oldsize = self.size
	
	self.size = math.min(size, self.maximumSize)
	self.size = math.max(self.size, _pixelsToMeterFactor)
	
	self.fixture:destroy()
	self.shape = love.physics.newRectangleShape(self.size, self.size)
	self.fixture = love.physics.newFixture(self.body, self.shape, self.density)
	
	self.fixture:setFriction(0)
	self.fixture:setRestitution(0)
	self.fixture:setGroupIndex(-self.playerID)
	
	local ix, iy = self.body:getLinearVelocity()
	self.body:setLinearVelocity(ix*(oldsize/self.size), iy*(oldsize/self.size))
	
	if animate and not self.headless then
		self.scaleTween = tween.new(self.scaleDuration, self, {imageScale = self.size/self.imageSize}, "outExpo")
	end
end

--Grow the kitten by a specific factor
function Kitten:growByFactor(scale) self:setSize(self.size * scale, true) end

--Shrink the kitten by a specific factor
function Kitten:shrinkByFactor(scale) self:setSize(self.size / scale, true) end

--== Kitten movement control methods ==--

--Make the kitten turn right 90 degrees
function Kitten:turn()
	local bx, by = self.body:getPosition()
	local rot = self.body:getAngle()
	
	local quarts = (rot*2)/math.pi
	
	rot = (math.floor(quarts+0.5) + 1) * math.pi * 0.5
	
	if not self.headless then
		local traceStartColor = {unpack(self.color)}; traceStartColor[4] = 1
		local traceEndColor = {unpack(self.color)}; traceEndColor[4] = 0
		table.insert(self.traces,{ cx=bx,cy=by,rot=rot,scale=self.size/self.traceSize,color=traceStartColor })
		table.insert(self.traceTweens,tween.new(self.traceDuration,self.traces[#self.traces],{ color=traceEndColor },"outQuad"))
	end
	
	self.body:setAngle(rot)
	self.body:setAngularVelocity(0)
	
	local ix = (math.cos(rot) * self.speed)/(self.size/_pixelsToMeterFactor)
	local iy = (math.sin(rot) * self.speed)/(self.size/_pixelsToMeterFactor)
	self.body:setLinearVelocity(ix,iy)
end

--== Weapons ==--

function Kitten:gotTurret()
	self.hasTurret = self.turretDuration
	self.bulletTimer = (self.size/_pixelsToMeterFactor)/10
	
	self.turretSFX:stop()
	self.turretSFX:play()
end

--== LÖVE Events ==--

function Kitten:update(dt)
	--Turret update
	for k, bullet in ipairs(self.bullets) do bullet:update(dt) end
	
	if self.hasTurret then
		--Make sure the turret audio is playing
		if not (self.headless or self.turretSFX:isPlaying()) then self.turretSFX:play() end
		
		self.bulletTimer = self.bulletTimer - dt
		if self.bulletTimer <= 0 then
			self.bulletTimer = (self.size/_pixelsToMeterFactor)/10
			
			table.insert(self.bullets, Bullet(self))
		end
		
		self.hasTurret = self.hasTurret - dt
		if self.hasTurret <= 0 then
			if not self.headless then self.turretSFX:stop() end
			self.hasTurret = false
		end
	end
	
	if not self.headless then
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
	end
	
	--Teleport/Wrap the kitten at the world borders
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

--Draw the moustach of the kitten
function Kitten:drawMoustach()
	if self.headless then return error("The kitten is in headless mode!") end
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

--Draw the kitten body and bullets
function Kitten:drawBody()
	if self.headless then return error("The kitten is in headless mode!") end
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

	for k, bullet in ipairs(self.bullets) do bullet:draw() end
end

--Draw the kitten movement traces
function Kitten:drawTraces()
	if self.headless then return error("The kitten is in headless mode!") end
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

return Kitten