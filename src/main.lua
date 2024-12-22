local Sprite = require "sprite"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Set up game resolution and scaling
    GameWidth, GameHeight = 380 * 2, 180 * 2
    local windowWidth, windowHeight = love.window.getDesktopDimensions()

    -- Calculate max integer scale that fits screen
    local scaleX = math.floor(windowWidth / GameWidth)
    local scaleY = math.floor(windowHeight / GameHeight)
    local scale = math.min(scaleX, scaleY)

    -- Create game canvas
    gameCanvas = love.graphics.newCanvas(GameWidth, GameHeight)

    -- Set up window
    love.window.setMode(GameWidth * scale, GameHeight * scale, { fullscreen = true })

    player = Sprite("sprites/player.ase")
    player:play("run")
end

function love.update(delta)
    player:update(delta)
end

function love.keypressed(key)
    player:key(key)
end

function love.draw()
    -- Draw game content to canvas
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()
    player:draw()
    love.graphics.setCanvas()

    -- Draw scaled canvas to screen
    local scale = love.graphics.getHeight() / GameHeight
    love.graphics.draw(gameCanvas, 0, 0, 0, scale, scale)
end
