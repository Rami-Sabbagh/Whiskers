--Tables to hold the loaded resources.

local R = {}

R.Image = {}
R.Music = {}
R.SFX = {}

R.meowNames = {}

for i = 1, 10 do

  local filename
  
  if i < 10 then
    filename = string.format("meow-0%d",i)
  else
    filename = string.format("meow-%d",i)
  end
  
  table.insert(R.meowNames, filename)
  
end

function R:playMeow()
  local rnd = love.math.random(1,#self.meowNames)
  self.SFX[self.meowNames[rnd]]:play()
end

return R