--The world class, contains the physics world and some extra fields about it
local class = require("libraries.middleclass")
local World = class("whiskers.World")

local tween = require("libraries.tween")

local Kitten = require("whiskers.kitten")
local Pellet = require("whiskers.pellet")
local Powerup = require("whiskers.powerup")

local screenWidth, screenHeight = love.graphics.getDimensions()

--Animation fields
World.lightningDuration = 0.45
World.lightningColorSpeed = 16

function World:initialize(width, height, headless)
    self.b2world = love.physics.newWorld(0, 0) --A new physics world with 0 gravity.
	self.width, self.height = width, height --The dimensions of the world
	self.headless = headless --Is the world headless (no graphics) ? (Used for training the AI)
	
	self.pellets = {} --The pellets in the world
	self.powerups = {} --The powerups in the world
	self.kittens = {} --The kittens in the world

    --Set the world callbacks
	self.b2world:setCallbacks(self.beginContact, self.endContact, self.preSolve, self.postSolve)
	
	--Initialize the resources if not running in headless mode
	if not self.headless then self:initializeResources() end
end

function World:initializeResources()
	self.headless = false

	--The lightning animation
	self.lightningImage = _image["bigWhiteLightning"]
	self.lightningWidth, self.lightningHeight = self.lightningImage:getDimensions()
	
	self.lightningSmallScale = (screenWidth/6)/self.lightningWidth
	self.lightningBigScale = (screenWidth/4)/self.lightningWidth
	
	self.lightningOX = self.lightningWidth/2
	self.lightningX = screenWidth/2
	
	self.lightningStartY = -screenWidth/6
	self.lightningMidY = screenHeight/2 - screenWidth/8
	self.lightningEndY = screenHeight
end

--== Is Methods ==--

--Is this a headless world (with no graphics) ?
function World:isHeadless() return self.headless end

--== Get Methods ==--

--Returns the Box2D world.
function World:getB2World() return self.b2world end

--Returns the dimensions/width/height of the world.
function World:getWidth() return self.width end
function World:getHeight() return self.height end
function World:getDimensions() return self.width, self.height end

--Returns the kittens table.
function World:getKittens() return self.kittens end

--== Other Methods ==--

--Show the lighting effect
function World:showLightning()
	self.lightningScale = self.lightningSmallScale
	
	self.lightningY = self.lightningStartY
	
	self.lightningColor = 1
	
	self.lightningTween = tween.new(self.lightningDuration/2,self,{
		lightningY = self.lightningMidY,
		lightningScale = self.lightningBigScale
	},"outExpo")
	
	self.lightningTween2 = tween.new(self.lightningDuration/2,self,{
		lightningY = self.lightningEndY,
		lightningScale = self.lightningSmallScale
	},"inExpo")
end

--Spawn a new kitten with a given player id {0, 1, 2, 4}
function World:spawnKitten(playerID) table.insert(self.kittens, Kitten(self, playerID)) end

--Spawn a new pellet at a random location, accounts for nearby objects and world padding
--If x and y are specified, then the pellet is spawned at that location careless.
function World:spawnPellet(x, y)
	if x and y then table.insert(self.pellets, Pellet(self, x, y)) return end

	local size = Pellet.size --The size of the pellet in pixels
	local spawnPadding = Kitten.size * 2 --The require empty space around the pellet spawn area
	local worldPadding = Kitten.size --The padding of the world
	
	--Do 5 attempts to spawn a new pellet, and spawn careless at the last attempt
	for i=5, 1, -1 do
		x, y = love.math.random()*(self.width-worldPadding*2) + worldPadding, love.math.random()*(self.height-worldPadding*2) + worldPadding
		
		local spawn = true --Could we spawn the pellet ?
		
		--Test if there are nearby objects but not when on the last spawn attempt (instead spawn careless).
		if i > 1 then
			self.b2world:queryBoundingBox(x-spawnPadding,y-spawnPadding,x+spawnPadding,y+spawnPadding, function(fixture)
				spawn = false --Something is nearby, don't spawn
				return false --No more need to call for other nearby objects
			end)
		end
		
		--If we could spawn, then do!
		if spawn then table.insert(self.pellets, Pellet(self, x, y)) return end
		
		--Shrink the spawn padding, for a greater chance to spawn in the next attempt
		spawnPadding = spawnPadding*0.75
	end
end

--Spawn a new powerup at a random location, accounts for nearby objects and world padding
--If x and y are specified, then the pellet is spawned at that location careless.
--Ptype could be specified to set the powerup type, defaults to random.
function World:spawnPowerup(x, y, ptype)
	if x and y then table.insert(self.pellets, Powerup(self, x, y, ptype)) return end

	local size = Powerup.size --The size of the powerup in pixels
	local spawnPadding = Kitten.size * 2 --The require empty space around the power spawn area
	local worldPadding = Kitten.size --The padding of the world
	
	--Do 5 attempts to spawn a new powerup, and spawn careless at the last attempt
	for i=5, 1, -1 do
		x, y = love.math.random()*(self.width-worldPadding*2) + worldPadding, love.math.random()*(self.height-worldPadding*2) + worldPadding
		
		local spawn = true --Could we spawn the powerup ?
		
		--Test if there are nearby objects but not when on the last spawn attempt (instead spawn careless).
		if i > 1 then
			self.b2world:queryBoundingBox(x-spawnPadding,y-spawnPadding,x+spawnPadding,y+spawnPadding, function(fixture)
				spawn = false --Something is nearby, don't spawn
				return false --No more need to call for other nearby objects
			end)
		end
		
		--If we could spawn, then do!
		if spawn then table.insert(self.powerups, Powerup(self, x, y, ptype)) return end
		
		--Shrink the spawn padding, for a greater chance to spawn in the next attempt
		spawnPadding = spawnPadding*0.75
	end
end

--== LÖVE Events ==--

--Draw the world
function World:draw()
	for k,v in ipairs(self.pellets) do v:draw() end --Draw pellets
	for k,v in ipairs(self.powerups) do v:draw() end --Draw powerups

	--Draw kittens
	for k,v in ipairs(self.kittens) do v:drawTraces() end
	for k,v in ipairs(self.kittens) do v:drawBody() end
	for k,v in ipairs(self.kittens) do v:drawMoustach() end
end

--Draw the lightning overlay
function World:drawLightning()
	if not self.lightningTween then return end
	
	local colorid = math.floor(self.lightningColor % #_colorPalette) +1
	local r, g, b = unpack(_colorPalette[colorid])
	
	love.graphics.setColor(r, g, b, 125/255)
	love.graphics.rectangle("fill", 0,0, screenWidth, screenHeight)
	
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(self.lightningImage,
		self.lightningX,
		self.lightningY,
		0,
		self.lightningScale,
		self.lightningScale,
		self.lightningOX
	)
end

--Update the world
function World:update(dt)
	self.b2world:update(dt) --Update the physics world

	for k,v in ipairs(self.kittens) do v:update(dt) end --Update the kittens
	for k,v in ipairs(self.pellets) do v:update(dt) end --Update the pellets
	for k,v in ipairs(self.powerups) do v:update(dt) end --Update the powerups

	--Update the lightning overlay
	if not self.headless and self.lightningTween then
		local done = self.lightningTween:update(dt)
		if done then
			self.lightningTween = self.lightningTween2
			self.lightningTween2 = nil
		end
		self.lightningColor = self.lightningColor+self.lightningColorSpeed*dt
	end
end

--== Physics Events ==--

function World.beginContact(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	if type(userdataA) == "table" and userdataA.beginContact then
		userdataA:beginContact(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	if type(userdataB) == "table" and userdataB.beginContact then
		userdataB:beginContact(fixtureB, fixtureA, contact)
	end
end

function World.endContact(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	if type(userdataA) == "table" and userdataA.endContact then
		userdataA:endContact(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	if type(userdataB) == "table" and userdataB.endContact then
		userdataB:endContact(fixtureB, fixtureA, contact)
	end
end

function World.preSolve(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	if type(userdataA) == "table" and userdataA.preSolve then
		userdataA:preSolve(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	if type(userdataB) == "table" and userdataB.preSolve then
		userdataB:preSolve(fixtureB, fixtureA, contact)
	end
end

function World.postSolve(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	if type(userdataA) == "table" and userdataA.postSolve then
		userdataA:postSolve(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	if type(userdataB) == "table" and userdataB.postSolve then
		userdataB:postSolve(fixtureB, fixtureA, contact)
	end
end

return World