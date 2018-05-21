local Gamera = require("Libraries.gamera")
local GameState = require("Libraries.gamestate")
local tween = require("Libraries.tween")

local ScoreState = require("States.Score")

local Kitten = require("Engine.Kitten")
local Pellet = require("Engine.Pellet")
local PowerUp = require("Engine.PowerUp")
local Resources = require("Engine.Resources")

local SWidth, SHeight = love.graphics.getDimensions()

local GState = {}

GState.PTM = 32
GState.kittenScale = 20*GState.PTM
GState.kittenColors = {
  {96/255 , 246/255, 133/255, 1}, --Green
  {246/255, 207/255, 95/255 , 1}, --Yellow
  {95/255 , 134/255, 246/255, 1}, --Blue
  {246/255, 95/255 , 209/255, 1}, --Pink
  {246/255, 132/255, 96/255 , 1}  --Orange
}
GState.pelletGrowScale = 1.44
GState.pelletStartTime = 15
GState.pelletTime = 10

GState.powerupStartTime = 15
GState.powerupTime = 10
GState.powerupTestID = nil

GState.lightningShrinkScale = GState.pelletGrowScale
GState.lightningGrowScale = 1.68

GState.bulletScale = 1.03

GState.lightningDuration = 0.45
GState.lightningColorSpeed = 16

GState.keyControls = {
  z = 1,
  x = 2,
  c = 3,
  v = 4
}

GState.touchControls = {}

function GState:init()
  
  for i=1, 4 do
  
    local btn = {}
    btn.image = Resources.Image["button"..i]
    
    btn.imageSize = btn.image:getDimensions()
    btn.size = 85
    btn.scale = btn.size / btn.imageSize
    
    btn.down = false
    btn.enabled = true
    
    if i == 1 then  --Bottom Left
      btn.x1, btn.y1 = 0, SHeight-btn.size
      btn.x2, btn.y2 = btn.size, SHeight
    elseif i == 2 then --Bottom Right
      btn.x1, btn.y1 = SWidth-btn.size, SHeight-btn.size
      btn.x2, btn.y2 = SWidth, SHeight
    elseif i == 3 then --Top Right
      btn.x1, btn.y1 = SWidth-btn.size, 0
      btn.x2, btn.y2 = SWidth, btn.size
    else --Top Left
      btn.x1, btn.y1 = 0, 0
      btn.x2, btn.y2 = btn.size, btn.size
    end
    
    self.touchControls[i] = btn
  end
  
  self.lightningImage = Resources.Image["bigWhiteLightning"]
  self.lightningWidth, self.lightningHeight = self.lightningImage:getDimensions()
  
  self.lightningSmallScale = (SWidth/6)/self.lightningWidth
  self.lightningBigScale = (SWidth/4)/self.lightningWidth
  
  self.lightningOX = self.lightningWidth/2
  self.lightningX = SWidth/2
  
  self.lightningStartY = -SWidth/6
  self.lightningMidY = SHeight/2 - SWidth/8
  self.lightningEndY = SHeight
  
end

function GState:enter()
  
  print("--==Game State Entered==--")
  
  love.audio.stop()
  
  love.graphics.setBackgroundColor(70/255,70/255,70/255, 1)
  
  love.physics.setMeter(self.PTM)
  
  self.world = love.physics.newWorld(0,0,true)
  self.worldWidth = self.kittenScale
  self.worldHeight = SHeight/(SWidth/self.kittenScale)
  
  self.winSize = 7.8 * self.PTM--self.worldHeight
  
  self.world:setCallbacks(self.beginContact, self.endContact, self.preSolve, self.postSolve)
  
  self.camera = Gamera.new(0,0,self.worldWidth, self.worldHeight)
  self.camera:setScale(SWidth/self.kittenScale)
  
  self.kittens = {}
  self.pellets = {}
  self.powerups = {}
  self:spawnKittens()
  
  self:playMusic()
  
  self.pelletTimer = self.pelletStartTime
  self.powerupTimer = self.powerupStartTime
  
  self.lightningTween, self.lightningTween2 = nil, nil
end

function GState:leave()
  
end

function GState:showLightning()
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

function GState:draw(vx,vy,vw,vh)
  self.camera:enable()
  
  self:drawPellets()
  self:drawPowerUps()
  self:drawKittens()
  
  self.camera:disable()
  
  self:drawLightning()
  
  self:drawButtons()
end

function GState:drawKittens()
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

function GState:drawPellets()
  for k,v in ipairs(self.pellets) do
    if v.draw then v:draw() end
  end
end

function GState:drawPowerUps()
  for k,v in ipairs(self.powerups) do
    if v.draw then v:draw() end
  end
end

function GState:drawLightning()
  if not self.lightningTween then return end
  
  local colorid = math.floor(self.lightningColor % #self.kittenColors) +1
  local r, g, b = unpack(self.kittenColors[colorid])
  
  love.graphics.setColor(r, g, b, 125/255)
  love.graphics.rectangle("fill", 0,0, SWidth, SHeight)
  
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

function GState:drawButtons()
  
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

function GState:update(dt)
  
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
      GameState.switch(ScoreState)
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

function GState:updateKittens(dt)
  for k,v in ipairs(self.kittens) do
    if v.update then v:update(dt) end
  end
end

function GState:updatePellets(dt)
  for k,v in ipairs(self.pellets) do
    if v.update then v:update(dt) end
  end
end

function GState:updatePowerUps(dt)
  for k,v in ipairs(self.powerups) do
    if v.update then v:update(dt) end
  end
end

function GState:updateLightning(dt)
  if not self.lightningTween then return end
  local done = self.lightningTween:update(dt)
  if done then
    self.lightningTween = self.lightningTween2
    self.lightningTween2 = nil
  end
  self.lightningColor = self.lightningColor+self.lightningColorSpeed*dt
end

function GState:keypressed(key,scancode,isrepeat)
  local id = self.keyControls[key]
  if id then
    if self.kittens[id] then
      self.kittens[id]:turn()
      self.touchControls[id].down = true
    end
  end
end

function GState:keyreleased(key,scancode,isrepeat)
  local id = self.keyControls[key]
  if id then
    if self.kittens[id] then
      self.touchControls[id].down = false
    end
  end
end

function GState:spawnKittens()
  for i=1,4 do
    self.kittens[i] = Kitten(self,i)
  end
end

function GState:spawnPellet()
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

function GState:spawnPowerUp()
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

function GState:newPellet(x,y)
  table.insert(self.pellets, Pellet(self,x,y))
end

function GState:newPowerUp(x,y,id)
  table.insert(self.powerups, PowerUp(self,x,y,id))
end

function GState:playMusic()
  if not _DEBUG then
    Resources.Music["mapleLeafRag"]:play()
  end
end

function GState:mousepressed(x,y,button,istouch)
  if istouch then return end
  self:newPellet(self.camera:toWorld(x,y))
end

function GState:touchpressed(id,x,y,dx,dy,pressure)
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

function GState:touchreleased(id,x,y,dx,dy,pressure)
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

--beginContact, endContact, preSolve, postSolve

function GState.beginContact(fixtureA, fixtureB, contact)
  local userdataA = fixtureA:getBody():getUserData()
  
  if type(userdataA) == "table" and userdataA.beginContact then
    userdataA:beginContact(fixtureA, fixtureB, contact)
  end
  
  local userdataB = fixtureB:getBody():getUserData()
  
  if type(userdataB) == "table" and userdataB.beginContact then
    userdataB:beginContact(fixtureB, fixtureA, contact)
  end
end

function GState.endContact(fixtureA, fixtureB, contact)
  local userdataA = fixtureA:getBody():getUserData()
  
  if type(userdataA) == "table" and userdataA.endContact then
    userdataA:endContact(fixtureA, fixtureB, contact)
  end
  
  local userdataB = fixtureB:getBody():getUserData()
  
  if type(userdataB) == "table" and userdataB.endContact then
    userdataB:endContact(fixtureB, fixtureA, contact)
  end
end

function GState.preSolve(fixtureA, fixtureB, contact)
  local userdataA = fixtureA:getBody():getUserData()
  
  if type(userdataA) == "table" and userdataA.preSolve then
    userdataA:preSolve(fixtureA, fixtureB, contact)
  end
  
  local userdataB = fixtureB:getBody():getUserData()
  
  if type(userdataB) == "table" and userdataB.preSolve then
    userdataB:preSolve(fixtureB, fixtureA, contact)
  end
end

function GState.postSolve(fixtureA, fixtureB, contact)
  local userdataA = fixtureA:getBody():getUserData()
  
  if type(userdataA) == "table" and userdataA.postSolve then
    userdataA:postSolve(fixtureA, fixtureB, contact)
  end
  
  local userdataB = fixtureB:getBody():getUserData()
  
  if type(userdataB) == "table" and userdataB.postSolve then
    userdataB:postSolve(fixtureB, fixtureA, contact)
  end
end

return GState