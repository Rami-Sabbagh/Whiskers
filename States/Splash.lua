local Loader = require("Libraries.love-loader")
local GameState = require("Libraries.gamestate")
local Resources = require("Engine.Resources")

local SState = {}

local SWidth, SHeight = love.graphics.getDimensions()

function SState:init()
  --Load the RL4G Logo
  self.logoImage = love.graphics.newImage("Assets/Misc/RL4G_LOGO.png")
  self.logoX = math.floor((SWidth - self.logoImage:getWidth())/2)
  self.logoY = math.floor((SHeight - self.logoImage:getHeight())/2)
  
  --Add resources to load
  self:AddImages()
  self:AddSFX()
  self:AddMusic()
end

function SState:enter()
  
  print("--==Entered Spash State==--")
  
  love.graphics.setBackgroundColor(70,70,70,255)
  
  self.finishedLoading = false
  
  Loader.start(
    
    --Finished Loading
    function()
      print("Finished Loading")
      self.finishedLoading = true
      GameState.switch( require("States.Game") )
    end,
    
    --Item Loaded
    function(kind, holder, key)
      print("Loaded", math.floor((Loader.loadedCount/Loader.resourceCount)*100) .. "%",kind, key)
      
      if kind == "stream" then
        holder[key]:setLooping(true)
        holder[key]:setVolume(0.9)
      end
    end
    
    )
  
  print("Loader Started")
  
  print("Resources to load:", Loader.resourceCount)
  
end

function SState:leave()
  
end

function SState:draw()
  
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(self.logoImage, self.logoX, self.logoY)
  
end

function SState:update(dt)
  
  if not self.finishedLoading then
    Loader.update(dt)
  end
  
end

function SState:keypressed(key, scancode, isRepeat)
  
end

function SState:touchpressed(id, x,y, dx,dy, pressure)
  
end

function SState:AddImages(path)
  local path = path or "/Assets/Images/"
  local Items = love.filesystem.getDirectoryItems(path)
  
  for id, item in ipairs(Items) do
    
    local ItemPath = path..item
    
    if love.filesystem.isDirectory(ItemPath) then
      
      self:AddImages(ItemPath.."/")
      
    else
      
      local _, FileName, FileExtension = self:SplitFilePath(ItemPath)
      
      if FileExtension == "png" then
        
        Loader.newImage(Resources.Image, FileName, ItemPath)
        
      end
      
    end
    
  end
end

function SState:AddSFX(path)
  local path = path or "/Assets/SFX/"
  local Items = love.filesystem.getDirectoryItems(path)
  
  for id, item in ipairs(Items) do
    
    local ItemPath = path..item
    
    if love.filesystem.isDirectory(ItemPath) then
      
      self:AddImages(ItemPath.."/")
      
    else
      
      local _, FileName, FileExtension = self:SplitFilePath(ItemPath)
      
      if FileExtension == "wav" then
        
        Loader.newSource(Resources.SFX, FileName, ItemPath)
        
      end
      
    end
    
  end
end

function SState:AddMusic(path)
  local path = path or "/Assets/Music/"
  local Items = love.filesystem.getDirectoryItems(path)
  
  for id, item in ipairs(Items) do
    
    local ItemPath = path..item
    
    if love.filesystem.isDirectory(ItemPath) then
      
      self:AddImages(ItemPath.."/")
      
    else
      
      local _, FileName, FileExtension = self:SplitFilePath(ItemPath)
      
      if FileExtension == "mp3" then
        
        Loader.newSource(Resources.Music, FileName, ItemPath, "stream")
        
      end
      
    end
    
  end
end

--Extra functions

function SState:SplitFilePath(path)
  local p, n, e = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
  return p, n:sub(1, -e:len()-2), e
end

return SState