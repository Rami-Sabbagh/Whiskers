local tween = require("Libraries.tween")

local Resources = require("Engine.Resources")

local SWidth, SHeight = love.graphics.getDimensions()

local SState = {}

SState.duration = 0.3

function SState:init()
  
  self.game = require("States.Game")
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
      0
      )
  end
end

function SState:update(dt)
  for i=1, 4 do
    if not self.tweens[i]:update(dt) then break end
  end
end

return SState