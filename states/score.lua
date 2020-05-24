--The score state, displays the kittens ranks
local tween = require("libraries.tween")
local gamestate = require("libraries.gamestate")

local ImageButton = require("ui.imageButton")

local scoreState = {}

--Please check the ScoreScreenLayout.pdf document for how those numbers are being calculated
-- Edit note: in the (4.1) section, the top padding has been removed

local screenWidth, screenHeight = love.graphics.getDimensions()

function scoreState:enter(previousState, kittens)
    self.kittens = kittens
    table.sort(self.kittens, function(t1, t2) return t1.size > t2.size end)

    --==## (1) The score screen ##==--

    --== (2) The winner section ==--

    self.winnerSectionWidth = screenWidth
    self.winnerSectionHeight = screenHeight * (1/6)

    --(2.2) Winner Image
    self.winnerImage = _image[self.kittens[1]:getName() .. "Wins"] --The image object
    self.winnerImageWidth, self.winnerImageHeight = self.winnerImage:getDimensions()
    self.winnerImageColor = _colorPalette[self.kittens[1]:getPlayerID()]

    --(2.1) Winner Box
    self.winnerBoxPaddingTop = self.winnerImageHeight * 1/2 --1/3 top padding, 2/3 winner image
    self.winnerBoxPaddingBottom = 0
    self.winnerBoxPaddingSide = self.winnerBoxPaddingTop

    self.winnerBoxWidth = self.winnerImageWidth + self.winnerBoxPaddingSide*2
    self.winnerBoxHeight = self.winnerBoxPaddingTop + self.winnerImageHeight + self.winnerBoxPaddingBottom

    --(2) Winner section - Post calculations
    
    if self.winnerSectionWidth/self.winnerSectionHeight > self.winnerBoxWidth/self.winnerSectionHeight then
        --The winner box would have the same winner section height, but with left and right padding
        self.winnerBoxScale = self.winnerSectionHeight/self.winnerBoxHeight
        self.winnerBoxMarginTopDown = 0
        self.winnerBoxMarginLeftRight = (self.winnerSectionWidth - self.winnerBoxWidth*self.winnerBoxScale)/2
    else
        --The winner box would have the winner section width, but with top and bottom padding
        self.winnerBoxScale = self.winnerSectionWidth/self.winnerBoxWidth
        self.winnerBoxMarginTopDown = (self.winnerSectionHeight - self.winnerBoxHeight*self.winnerBoxScale)/2
        self.winnerBoxMarginLeftRight = 0
    end

    --Final winner image coordinations
    self.winnerImageX = self.winnerBoxMarginLeftRight + self.winnerBoxPaddingSide*self.winnerBoxScale
    self.winnerImageY = self.winnerBoxMarginTopDown + self.winnerBoxPaddingTop*self.winnerBoxScale

    --== (3) The whiskers section ==--

    self.whiskersSectionWidth = screenWidth
    self.whiskersSectionHeight = screenHeight * (4/6)

    

    --== (4) The buttons section ==--

    self.buttonsSectionWidth = screenWidth
    self.buttonsSectionHeight = screenHeight * (1/6)

    --(4.3.2) Home image
    self.buttonsHomeImage = _image["homeButton"]
    self.buttonsHomeImageWidth, self.buttonsHomeImageHeight = self.buttonsHomeImage:getDimensions()

    --(4.2.2) Rematch image
    self.buttonsRematchImage = _image["rematchButton"]
    self.buttonsRematchImageWidth, self.buttonsRematchImageHeight = self.buttonsRematchImage:getDimensions()

    --(4.2.1) Home button
    self.buttonsHomeImageScale = math.max(self.buttonsRematchImageHeight, self.buttonsHomeImageHeight) / self.buttonsHomeImageHeight
    self.buttonsHomeButtonWidth = self.buttonsHomeImageWidth * self.buttonsHomeImageScale
    self.buttonsHomeButtonHeight = self.buttonsHomeImageHeight * self.buttonsHomeImageScale

    --(4.2.1) Rematch button
    self.buttonsRematchImageScale = math.max(self.buttonsRematchImageHeight, self.buttonsHomeImageHeight) / self.buttonsRematchImageHeight
    self.buttonsRematchButtonWidth = self.buttonsRematchImageWidth * self.buttonsRematchImageScale
    self.buttonsRematchButtonHeight = self.buttonsRematchImageHeight * self.buttonsRematchImageScale

    --(4.1) Buttons box
    self.buttonsBoxPadding = self.buttonsSectionHeight * (1/4)

    self.buttonsBoxWidth = self.buttonsBoxPadding*3 + self.buttonsRematchButtonWidth + self.buttonsHomeButtonWidth
    self.buttonsBoxHeight = self.buttonsRematchButtonHeight + self.buttonsBoxPadding

    --(4) Buttons section - Post calculations

    if self.buttonsSectionWidth/self.buttonsSectionHeight > self.buttonsBoxWidth/self.buttonsBoxHeight then
        --The buttons box would have the same buttons section height, but with left and right padding
        self.buttonsBoxScale = self.buttonsSectionHeight/self.buttonsBoxHeight
        self.buttonsBoxMarginTopDown = 0
        self.buttonsBoxMarginLeftRight = (self.buttonsSectionWidth - self.buttonsBoxWidth*self.buttonsBoxScale)/2
    else
        --The buttons box would have the buttons section width, but with top and bottom padding
        self.buttonsBoxScale = self.buttonsSectionWidth/self.buttonsBoxWidth
        self.buttonsBoxMarginTopDown = (self.buttonsSectionHeight - self.buttonsBoxHeight*self.buttonsBoxScale)/2
        self.buttonsBoxMarginLeftRight = 0
    end

    self.buttonsRematchButtonX = self.buttonsBoxMarginLeftRight + self.buttonsBoxPadding*self.buttonsBoxScale
    self.buttonsRematchButtonY = screenHeight * (5/6) + self.buttonsBoxMarginTopDown
    self.buttonsRematchButtonScale = self.buttonsRematchImageScale * self.buttonsBoxScale
    self.buttonsRematchButton = ImageButton(self.buttonsRematchImage, self.buttonsRematchButtonX, self.buttonsRematchButtonY, self.buttonsRematchButtonScale)

    self.buttonsHomeButtonX = self.buttonsRematchButtonX + self.buttonsRematchButtonWidth*self.buttonsBoxScale + self.buttonsBoxPadding*self.buttonsBoxScale
    self.buttonsHomeButtonY = self.buttonsRematchButtonY
    self.buttonsHomeButtonScale = self.buttonsHomeImageScale * self.buttonsBoxScale
    self.buttonsHomeButton = ImageButton(self.buttonsHomeImage, self.buttonsHomeButtonX, self.buttonsHomeButtonY, self.buttonsHomeButtonScale)
end

function scoreState:draw()
    --Draw the (2.2) winner image
    love.graphics.setColor(self.winnerImageColor)
    love.graphics.draw(self.winnerImage, self.winnerImageX, self.winnerImageY, 0, self.winnerBoxScale, self.winnerBoxScale)

    --Draw the (4.2.1) and (4.3.1) buttons
    self.buttonsRematchButton:draw()
    self.buttonsHomeButton:draw()
end

return scoreState