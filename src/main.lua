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
    GameCanvas = love.graphics.newCanvas(GameWidth, GameHeight)

    -- Set up window
    love.window.setMode(GameWidth * scale, GameHeight * scale, { fullscreen = true })

    -- Create obstacles
    Obstacles = {
        { x = 100, y = 220, width = 50, height = 50 },
        { x = 200, y = 380, width = 50, height = 70 },
        { x = 300, y = 90,  width = 50, height = 60 }
    }

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
    love.graphics.setCanvas(GameCanvas)
    love.graphics.clear()

    -- Draw obstacles
    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, obstacle in ipairs(Obstacles) do
        love.graphics.rectangle("fill", obstacle.x, obstacle.y - obstacle.height / 2, obstacle.width, obstacle.height)
    end

    -- Reset color and draw player
    love.graphics.setColor(1, 1, 1)
    player:draw()
    love.graphics.setCanvas()

    -- Draw scaled canvas to screen
    local scale = love.graphics.getHeight() / GameHeight
    love.graphics.draw(GameCanvas, 0, 0, 0, scale, scale)
end
