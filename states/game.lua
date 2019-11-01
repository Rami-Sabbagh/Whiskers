local gamera = require("libraries.gamera")
local gamestate = require("libraries.gamestate")
local tween = require("libraries.tween")

local Kitten = require("whiskers.kitten")
local Pellet = require("whiskers.pellet")
local Powerup = require("whiskers.powerup")

local screenWidth, screenHeight = love.graphics.getDimensions()

local gameState = {}

gameState.PTM = 32
gameState.kittenScale = 20*gameState.PTM
gameState.pelletGrowScale = 1.44
gameState.pelletStartTime = 15
gameState.pelletTime = 10

gameState.powerupStartTime = 15
gameState.powerupTime = 10
gameState.powerupTestID = nil

gameState.lightningShrinkScale = gameState.pelletGrowScale
gameState.lightningGrowScale = 1.68

gameState.bulletScale = 1.03

gameState.lightningDuration = 0.45
gameState.lightningColorSpeed = 16

gameState.keyControls = {
	z = 1,
	x = 2,
	c = 3,
	v = 4
}

gameState.touchControls = {}

function gameState:init()
	for i=1, 4 do
		local btn = {}
		btn.image = _image["button"..i]
		
		btn.imageSize = btn.image:getDimensions()
		btn.size = 85
		btn.scale = btn.size / btn.imageSize
		
		btn.down = false
		btn.enabled = true
		
		if i == 1 then  --Bottom Left
			btn.x1, btn.y1 = 0, screenHeight-btn.size
			btn.x2, btn.y2 = btn.size, screenHeight
		elseif i == 2 then --Bottom Right
			btn.x1, btn.y1 = screenWidth-btn.size, screenHeight-btn.size
			btn.x2, btn.y2 = screenWidth, screenHeight
		elseif i == 3 then --Top Right
			btn.x1, btn.y1 = screenWidth-btn.size, 0
			btn.x2, btn.y2 = screenWidth, btn.size
		else --Top Left
			btn.x1, btn.y1 = 0, 0
			btn.x2, btn.y2 = btn.size, btn.size
		end
		
		self.touchControls[i] = btn
	end
	
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

function gameState:enter()
	print("--==Game State Entered==--")
	
	love.graphics.setBackgroundColor(70/255,70/255,70/255, 1)
	
	love.physics.setMeter(self.PTM)
	
	self.world = love.physics.newWorld(0, 0)
	self.worldWidth = self.kittenScale
	self.worldHeight = screenHeight/(screenWidth/self.kittenScale)
	
	self.winSize = 7.8 * self.PTM
	
	self.world:setCallbacks(self.beginContact, self.endContact, self.preSolve, self.postSolve)
	
	self.camera = gamera.new(0,0,self.worldWidth, self.worldHeight)
	self.camera:setScale(screenWidth/self.kittenScale)
	
	self.kittens = {}
	self.pellets = {}
	self.powerups = {}
	self:spawnKittens()
	
	self:playMusic()
	
	self.pelletTimer = self.pelletStartTime
	self.powerupTimer = self.powerupStartTime
	
	self.lightningTween, self.lightningTween2 = nil, nil
end

function gameState:leave()
	love.audio.stop() --Stop all the audio which is being played by this state
end

function gameState:showLightning()
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

function gameState:draw(vx,vy,vw,vh)
	self.camera:enable()
	
	self:drawPellets()
	self:drawPowerUps()
	self:drawKittens()
	
	self.camera:disable()
	
	self:drawLightning()
	
	self:drawButtons()
end

function gameState:drawKittens()
	for k,v in ipairs(self.kittens) do
		if v.drawTraces then v:drawTraces() end
	end
	
	for k,v in ipairs(self.kittens) do
		if v.drawBody then v:drawBody() end
	end
	
	for k,v in ipairs(self.kittens) do
		if v.drawMoustach then v:drawMoustach() end
	end
end

function gameState:drawPellets()
	for k,v in ipairs(self.pellets) do
		if v.draw then v:draw() end
	end
end

function gameState:drawPowerUps()
	for k,v in ipairs(self.powerups) do
		if v.draw then v:draw() end
	end
end

function gameState:drawLightning()
	if not self.lightningTween then return end
	
	local colorid = math.floor(self.lightningColor % #self.kittenColors) +1
	local r, g, b = unpack(self.kittenColors[colorid])
	
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

function gameState:drawButtons()
	
	for id,btn in pairs(self.touchControls) do
		
		if btn.down then
			love.graphics.setColor(170/255,170/255,170/255,200/255)
		else
			love.graphics.setColor(1,1,1,200/255)
		end
		
		love.graphics.draw(
			btn.image,
			btn.x1,
			btn.y1,
			0,
			btn.scale,
			btn.scale
		)
	end
	
end

function gameState:update(dt)
	
	self.world:update(dt)
	self:updateKittens(dt)
	self:updatePellets(dt)
	self:updatePowerUps(dt)
	self:updateLightning(dt)
	
	--Check scales
	for i=1,4 do
		if self.kittens[i].size >= self.winSize then
			for j=1,4 do
				self.kittens[j].imageScale = self.kittens[j].size/self.kittens[j].imageSize
			end
			gamestate.switch(_states["score"])
			return
		end
	end
	
	--Pellet Timer
	self.pelletTimer = self.pelletTimer - dt
	if self.pelletTimer <= 0 then
		self.pelletTimer = self.pelletTime
		self:spawnPellet()
	end
	
	--Powerup Timer
	self.powerupTimer = self.powerupTimer - dt
	if self.powerupTimer <= 0 then
		self.powerupTimer = self.powerupTime
		self:spawnPowerUp()
	end
end

function gameState:updateKittens(dt)
	for k,v in ipairs(self.kittens) do
		if v.update then v:update(dt) end
	end
end

function gameState:updatePellets(dt)
	for k,v in ipairs(self.pellets) do
		if v.update then v:update(dt) end
	end
end

function gameState:updatePowerUps(dt)
	for k,v in ipairs(self.powerups) do
		if v.update then v:update(dt) end
	end
end

function gameState:updateLightning(dt)
	if not self.lightningTween then return end
	local done = self.lightningTween:update(dt)
	if done then
		self.lightningTween = self.lightningTween2
		self.lightningTween2 = nil
	end
	self.lightningColor = self.lightningColor+self.lightningColorSpeed*dt
end

function gameState:keypressed(key,scancode,isrepeat)
	local id = self.keyControls[key]
	if id then
		if self.kittens[id] then
			self.kittens[id]:turn()
			self.touchControls[id].down = true
		end
	end
end

function gameState:keyreleased(key,scancode,isrepeat)
	local id = self.keyControls[key]
	if id then
		if self.kittens[id] then
			self.touchControls[id].down = false
		end
	end
end

function gameState:spawnKittens()
	for i=1,4 do
		self.kittens[i] = Kitten(self,i)
	end
end

function gameState:spawnPellet()
	local size = self.PTM/4
	local extra = self.PTM*4
	local pan = self.PTM
	
	for i=1,5 do
		local x, y = love.math.random()*(self.worldWidth-pan*2) + pan, love.math.random()*(self.worldHeight-pan*2) + pan
		
		local flag = true
		
		if i < 5 then
			local brad = (size+extra)/2
			self.world:queryBoundingBox(x-brad,y-brad,x+brad,y+brad, function(fixture)
				flag = false
				return false
			end)
		end
		
		if flag then
			
			self:newPellet(x,y)
			return
			
		end
		
		extra = extra*0.75
	end
end

function gameState:spawnPowerUp()
	local size = self.PTM*0.60
	local extra = self.PTM*4
	local pan = self.PTM
	
	for i=1,5 do
		local x, y = love.math.random()*(self.worldWidth-pan*2) + pan, love.math.random()*(self.worldHeight-pan*2) + pan
		
		local flag = true
		
		if i < 5 then
			local brad = (size+extra)/2
			self.world:queryBoundingBox(x-brad,y-brad,x+brad,y+brad, function(fixture)
				flag = false
				return false
			end)
		end
		
		if flag then
			
			self:newPowerUp(x,y,self.powerupTestID)
			return
			
		end
		
		extra = extra*0.75
	end
end

function gameState:newPellet(x,y)
	table.insert(self.pellets, Pellet(self,x,y))
end

function gameState:newPowerUp(x,y,id)
	table.insert(self.powerups, Powerup(self,x,y,id))
end

function gameState:playMusic()
	if not _DEBUG then
		Resources.Music["mapleLeafRag"]:play()
	end
end

function gameState:mousepressed(x,y,button,istouch)
	if istouch then return end
	self:newPellet(self.camera:toWorld(x,y))
end

function gameState:touchpressed(id,x,y,dx,dy,pressure)
	for id,btn in pairs(self.touchControls) do
		if not btn.touchid then
			if btn.x1 <= x and btn.y1 <= y and btn.x2 >= x and btn.y2 >= y then
				btn.touchid = id
				btn.down = true
				self.kittens[id]:turn()
				break
			end
		end
	end
end

function gameState:touchreleased(id,x,y,dx,dy,pressure)
	for id,btn in pairs(self.touchControls) do
		if btn.touchid and btn.touchid == id then
			if btn.x1 <= x and btn.y1 <= y and btn.x2 >= x and btn.y2 >= y then
				btn.touchid = nil
				btn.down = false
				break
			end
		end
	end
end

function gameState.beginContact(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	
	if type(userdataA) == "table" and userdataA.beginContact then
		userdataA:beginContact(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	
	if type(userdataB) == "table" and userdataB.beginContact then
		userdataB:beginContact(fixtureB, fixtureA, contact)
	end
end

function gameState.endContact(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	
	if type(userdataA) == "table" and userdataA.endContact then
		userdataA:endContact(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	
	if type(userdataB) == "table" and userdataB.endContact then
		userdataB:endContact(fixtureB, fixtureA, contact)
	end
end

function gameState.preSolve(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	
	if type(userdataA) == "table" and userdataA.preSolve then
		userdataA:preSolve(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	
	if type(userdataB) == "table" and userdataB.preSolve then
		userdataB:preSolve(fixtureB, fixtureA, contact)
	end
end

function gameState.postSolve(fixtureA, fixtureB, contact)
	local userdataA = fixtureA:getBody():getUserData()
	
	if type(userdataA) == "table" and userdataA.postSolve then
		userdataA:postSolve(fixtureA, fixtureB, contact)
	end
	
	local userdataB = fixtureB:getBody():getUserData()
	
	if type(userdataB) == "table" and userdataB.postSolve then
		userdataB:postSolve(fixtureB, fixtureA, contact)
	end
end

return gameState