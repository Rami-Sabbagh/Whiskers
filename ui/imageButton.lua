--Image button class

local class = require("libraries.middleclass")
local base = require("ui.base")
local ImageButton = class("ui.ImageButton", base)

function ImageButton:initialize(image, x,y, scale)
    self.image = image
    self.imageWidth, self.imageHeight = self.image:getDimensions()

    self.imageScale = scale or 1
    self.width, self.height = self.imageWidth*self.imageScale, self.imageHeight*self.imageScale

    self.x, self.y = x or 0, y or 0
end

function ImageButton:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, self.imageScale, self.imageScale)
end

--== Getter methods ==--

function ImageButton:getImageDimensions() return self.imageWidth, self.imageHeight end

--== Setter methods ==--

function ImageButton:setPosition(x, y) self.x, self.y = x or self.x, y or self.y end
function ImageButton:setImageScale(scale)
    self.imageScale = scale or self.imageScale
    self.width, self.height = self.imageWidth*self.imageScale, self.imageHeight*self.imageScale
end

return ImageButton