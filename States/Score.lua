local tween = require("Libraries.tween")

local Resources = require("Engine.Resources")

local SWidth, SHeight = love.graphics.getDimensions()

local SState = {}

SState.duration = 0.3

function SState:init()
  
  --The screen width is devided 12 section, 1 for each side
  
  self.game = require("States.Game")
  
  self.rematchImage = Resources.Image["rematchButton"] --17 Pixel Bottom Padding
  self.homeImage = Resources.Image["homeButton"]
  
  self.rematchWidth, self.rematchHeight = self.rematchImage:getDimensions()
  self.homeWidth, self.homeHeight = self.homeImage:getDimensions()
  
  self.homeScale = self.rematchHeight/self.homeHeight --This is the home button scale required to match the rematch one.
  
  self.rematchScale = ((SWidth/12)*10)/(self.rematchWidth + 17 + self.homeWidth*self.homeScale)
  
  self.rematchX, self.rematchY = SWidth/12, SHeight-self.rematchHeight*self.rematchScale
  self.homeX, self.homeY = self.rematchX+(self.rematchWidth+17)*self.rematchScale, SHeight-self.homeHeight*self.rematchScale*self.homeScale
  
  self.rematchX = self.rematchX + self.rematchWidth*self.rematchScale*0.5
  self.rematchY = self.rematchY + self.rematchHeight*self.rematchScale*0.5
  
  self.homeX = self.homeX + self.homeWidth*self.rematchScale*self.homeScale*0.5
  self.homeY = self.homeY + self.homeHeight*self.rematchScale*self.homeScale*0.5
  
  self.rematchOX, self.rematchOY = self.rematchWidth/2, self.rematchHeight/2
  self.homeOX, self.homeOY = self.homeWidth/2, self.homeHeight/2
  
  
  self.biggestSize = (SHeight/5)*3
  self.firstX = SHeight/5 + self.biggestSize/2
  
  
  
end

function SState:enter()
  
  self.kittens = {}
  self.positions = {}
  self.endPositions = {}
  
  for i=1,4 do
    local kitten = self.game.kittens[i]
    self.kittens[i] = kitten
  end
  
  table.sort(self.kittens, function(i1, i2)
    return i1.size > i2.size
  end)
  
  self.scale = self.biggestSize / self.kittens[1].size
  self.endPositions[1] = {self.firstX, SHeight/2}
  for i=2,4 do
    local prev, x = self.endPositions[i-1]
    x = prev[1]+(self.kittens[i-1].size*self.scale)/2
    local y = SHeight/2 + self.biggestSize/2 - (self.kittens[i].size*self.scale)/2
    self.endPositions[i] = {x,y}
  end
  
  for i=1, 4 do
    local x = (-self.kittens[i].size*self.scale)/2
    local y = self.endPositions[i][2]
    self.positions[i] = {x,y}
  end
  
  self.tweens = {}
  
  for i=1, 4 do
    self.tweens[i] = tween.new(self.duration, self.positions[i], self.endPositions[i], "outExpo")
  end
end

function SState:leave()
  
end

function SState:draw()
  self:drawKittens()
  self:drawButtons()
end

function SState:drawButtons()
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(self.rematchImage,
    self.rematchX,
    self.rematchY,
    0,
    self.rematchScale,
    self.rematchScale,
    self.rematchOX,
    self.rematchOY)
  love.graphics.draw(self.homeImage,
    self.homeX,
    self.homeY,
    0,
    self.rematchScale*self.homeScale,
    self.rematchScale*self.homeScale,
    self.homeOX,
    self.homeOY)
end

function SState:drawKittens()
  for i=1,4 do
    local kitten = self.kittens[i]
    local pos = self.positions[i]
    
    love.graphics.setColor(love.graphics.getBackgroundColor())
    love.graphics.rectangle("fill",
      pos[1]-(kitten.size*self.scale)/2,
      pos[2]-(kitten.size*self.scale)/2,
      kitten.size*self.scale,
      kitten.size*self.scale)
    
    love.graphics.setColor(kitten.color)
    love.graphics.draw(kitten.image,
      pos[1],
      pos[2],
      0,
      kitten.imageScale*self.scale,
      kitten.imageScale*self.scale,
      kitten.imageSize/2,
      kitten.imageSize/2)
    
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(kitten.moustachImage,
      pos[1] + kitten.moustachX*kitten.imageScale*self.scale,
      pos[2] + kitten.moustachY*kitten.imageScale*self.scale,
      0,
      kitten.imageScale*self.scale,
      kitten.imageScale*self.scale,
      kitten.moustachCenterX,
      0)
  end
end

function SState:update(dt)
  for i=1, 4 do
    if not self.tweens[i]:update(dt) then break end
  end
end

return SState