local tween = require("Libraries.tween")
local GameState = require("Libraries.gamestate")

local Resources = require("Engine.Resources")

local SWidth, SHeight = love.graphics.getDimensions()

local SState = {}

SState.duration = 0.3
SState.kittenNames = {
  "clarenceWins",
  "helenWins",
  "johnrWins",
  "margieWins"
}

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
  
  self.rematchX1, self.rematchY1 = self.rematchX, self.rematchY
  self.rematchX2 = self.rematchX1 + self.rematchWidth*self.rematchScale
  self.rematchY2 = self.rematchY1 + (self.rematchHeight-17)*self.rematchScale
  
  self.rematchX = self.rematchX + self.rematchWidth*self.rematchScale*0.5
  self.rematchY = self.rematchY + self.rematchHeight*self.rematchScale*0.5
  
  self.homeX = self.homeX + self.homeWidth*self.rematchScale*self.homeScale*0.5
  self.homeY = self.homeY + self.homeHeight*self.rematchScale*self.homeScale*0.5
  
  self.rematchOX, self.rematchOY = self.rematchWidth/2, self.rematchHeight/2
  self.homeOX, self.homeOY = self.homeWidth/2, self.homeHeight/2
  
  self.rematchScaleDown = self.rematchScale*0.95
  self.rematchDown = false
  self.rematchTID = nil
  
  --WinnerName Height 93 + 17 padding
  self.winnerX, self.winnerY = SWidth/2, 17*self.rematchScale
  
  self.biggestSize = (SHeight - self.rematchHeight*self.rematchScale*2) - 100*self.rematchScale
  self.firstX = self.rematchHeight*self.rematchScale + self.biggestSize/2
  
end

function SState:enter()

  love.audio.stop()
  
  self:calculateKittens()
  
  --Calculate Winner Variables
  self.winnerImage = Resources.Image[self.kittenNames[self.kittens[1].id]]
  self.winnerColor = self.game.kittenColors[self.kittens[1].id]
  
  self.winnerWidth, self.winnerHeight = self.winnerImage:getDimensions()
  
  self.winnerScale = (self.winnerHeight/self.rematchHeight) * self.rematchScale
  
  self.winnerOX = self.winnerWidth/2
  
end

function SState:calculateKittens()
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

function SState:rematch()
  GameState.switch(self.game)
end

function SState:draw()
  self:drawKittens()
  self:drawButtons()
  self:drawWinnerName()
end

function SState:drawWinnerName()
  love.graphics.setColor(self.winnerColor)
  love.graphics.draw(self.winnerImage,
    self.winnerX,
    self.winnerY,
    0,
    self.winnerScale,
    self.winnerScale,
    self.winnerOX,
    0)
end

function SState:drawButtons()
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(self.rematchImage,
    self.rematchX,
    self.rematchY,
    0,
    self.rematchDown and self.rematchScaleDown or self.rematchScale,
    self.rematchDown and self.rematchScaleDown or self.rematchScale,
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
    
    love.graphics.setColor(1,1,1,1)
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

function SState:touchpressed(id,x,y,dx,dy,pressure)
  
  if not self.rematchTID then
    
    if self.rematchX1 <= x and self.rematchY1 <= y and self.rematchX2 >= x and self.rematchY2 >= y then
      self.rematchDown = true
      self.rematchTID = id
    end
    
  end
  
end

function SState:touchmoved(id,x,y,dx,dy,pressure)
  
  if self.rematchTID and self.rematchTID == id then
    
    if self.rematchX1 <= x and self.rematchY1 <= y and self.rematchX2 >= x and self.rematchY2 >= y then
      self.rematchDown = true
    else
      self.rematchDown = false
    end
    
  end
  
end

function SState:touchreleased(id,x,y,dx,dy,pressure)
  
  if self.rematchTID and self.rematchTID == id then
    
    if self.rematchX1 <= x and self.rematchY1 <= y and self.rematchX2 >= x and self.rematchY2 >= y then
      Resources:playMeow()
      self:rematch()
    end
    
    self.rematchDown = false
    self.rematchTID = nil
  end
  
end

function SState:mousepressed(x,y,button,istouch)
  if istouch then return end
  self:touchpressed(0,x,y,0,0,1)
end

function SState:mousemoved(x,y,dx,dy,istouch)
  if istouch then return end
  self:touchmoved(0,x,y,dx,dy,1)
end

function SState:mousereleased(x,y,button,istouch)
  if istouch then return end
  self:touchreleased(0,x,y,0,0,1)
end

return SState