local loader = require("libraries.love-loader")
local gamestate = require("libraries.gamestate")

local splashState = {}

local screenWidth, screenHeight = love.graphics.getDimensions()

function splashState:init()
	--Load the RL4G Logo
	self.logoImage = love.graphics.newImage("assets/miscellaneous/RL4G_LOGO.png")
	self.logoX = math.floor((screenWidth - self.logoImage:getWidth())/2)
	self.logoY = math.floor((screenHeight - self.logoImage:getHeight())/2)
	
	--Queue resources to load
	self:queueImages()
	self:queueSFX()
	self:queueMusic()
end

function splashState:enter()
	print("--==Entered Spash State==--")
	
	love.graphics.setBackgroundColor(70/255,70/255,70/255,1)
	
	self.finishedLoading = false
	self.loadedPercentage = 0 --The loading percentage
	
	loader.start(
		--Finished Loading
		function()
			print("Finished Loading")
			self.finishedLoading = true
			gamestate.switch(_states["game"])
		end,
		
		--Item Loaded
		function(kind, holder, key)
			self.loadedPercentage = loader.loadedCount/loader.resourceCount
			print("Loaded", math.floor((self.loadedPercentage)*100) .. "%", kind, key)
			
			if kind == "stream" then
				holder[key]:setLooping(true)
				holder[key]:setVolume(0.9)
			end
		end
	)
	
	print("Loader Started")
	print("Resources to load:", loader.resourceCount)
end

function splashState:draw()
	--Draw RamiLego4Game's logo
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(self.logoImage, self.logoX, self.logoY)
	
	--Loading bar
	love.graphics.setColor(1,1,1, 0.5)
	love.graphics.rectangle("fill", 0, 0, screenWidth*self.loadedPercentage, screenHeight*0.01)
end

function splashState:update(dt)
	--Update the loader
	if not self.finishedLoading then
		loader.update(dt)
	end
end

function splashState:queueImages(path)
	local path = path or "/assets/images/"
	local items = love.filesystem.getDirectoryItems(path)
	
	for id, item in ipairs(items) do
		local itemPath = path..item
		
		if love.filesystem.getInfo(itemPath, "directory") then
			self:queueImages(itemPath.."/")
		else
			local _, fileName, fileExtension = self:splitFilePath(itemPath)

			if fileExtension == "png" then
				loader.newImage(_image, fileName, itemPath)
			end
		end
	end
end

function splashState:queueSFX(path)
	local path = path or "/assets/sfx/"
	local items = love.filesystem.getDirectoryItems(path)
	
	for id, item in ipairs(items) do
		local itemPath = path..item
		
		if love.filesystem.getInfo(itemPath, "directory") then
			self:queueSFX(itemPath.."/")
		else
			local _, fileName, fileExtension = self:splitFilePath(itemPath)
			
			if fileExtension == "wav" then
				loader.newSource(_sfx, fileName, itemPath)
			end
		end
	end
end

function splashState:queueMusic(path)
	local path = path or "/assets/music/"
	local items = love.filesystem.getDirectoryItems(path)
	
	for id, item in ipairs(items) do
		local itemPath = path..item
		
		if love.filesystem.getInfo(itemPath, "directory") then
			self:queueMusic(itemPath.."/")
		else
			local _, fileName, fileExtension = self:splitFilePath(itemPath)
			
			if fileExtension == "mp3" then
				loader.newSource(_music, fileName, itemPath, "stream")
			end
		end
	end
end

--Extra functions

function splashState:splitFilePath(path)
	local p, n, e = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
	return p, n:sub(1, -e:len()-2), e
end

return splashState