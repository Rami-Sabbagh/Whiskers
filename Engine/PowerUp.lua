local class = require("Libraries.middleclass")

local Resources = require("Engine.Resources")
local Kitten = require("Engine.Kitten")

local PowerUp = class("PowerUp")

PowerUp.types = {
  "bomb",
  "bullet",
  "lightning",
  "star"
}

function PowerUp:initialize( game, x, y, id )
  
  self.game = game
  
  self.world = self.game.world
  self.worldWidth, self.worldHeight = self.game.worldWidth, self.game.worldHeight
  
  self.id = id or love.math.random(1,#self.types)
  self.name = self.types[self.id]
  
  self.size = self.game.PTM/2
  
  self.image = Resources.Image[self.name.."Icon"]
  self.imageWidth, self.imageHeight = self.image:getDimensions()
  self.imageScale = self.size/self.imageWidth
  
  self.imageOX, self.imageOY = self.imageWidth/2, self.imageHeight/2
  
  self.body = love.physics.newBody(self.world, x, y, "dynamic")
  self.shape = love.physics.newRectangleShape(self.size,self.size)
  self.fixture = love.physics.newFixture(self.body, self.shape)
  
  self.body:setUserData(self)
end

function PowerUp:draw()
  if self.dead then return end
  
  local bx, by = self.body:getPosition()
  local rot = self.body:getAngle()
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(self.image, bx,by, rot, self.imageScale,self.imageScale, self.imageOX,self.imageOY)
end

function PowerUp:update(dt)
  if self.dead then
    
    if self.toApply then
      
      --Apply the powerup
      
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
  
end

function PowerUp:destroy()
  self.body:destroy()
  self.dead = true
end

function PowerUp:preSolve(myFixture, otherFixture, contact)
  local other = otherFixture:getBody():getUserData()
  
  if type(other) ~= "table" then return end
  
  if other:isInstanceOf(Kitten) then
    contact:setEnabled(false)
    self:destroy()
    self.toApply = other
  end
end

return PowerUp