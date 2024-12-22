local Sprite = require "sprite"
DEBUG = false

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
        { x = 100, y = 365, width = 30, height = 50 },
        { x = 200, y = 355, width = 30, height = 50 },
        { x = 300, y = 345, width = 30, height = 50 },
        { x = 400, y = 335, width = 30, height = 50 },
        { x = 500, y = 325, width = 30, height = 50 },
        { x = 600, y = 315, width = 30, height = 50 },
        { x = 700, y = 305, width = 30, height = 50 },
    }

    player = Sprite("sprites/player.ase")
    player:play("run")
end

function love.update(delta)
    player:update(delta)
end

function love.keypressed(key)
    player:key(key)

    -- Debug controls
    if key == "f1" then
        DEBUG = not DEBUG -- Toggle debug visualization
    end
end

function love.draw()
    -- Draw game content to canvas
    love.graphics.setCanvas(GameCanvas)
    love.graphics.clear()

    -- Draw obstacles
    for _, obstacle in ipairs(Obstacles) do
        -- Draw obstacle fill
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", obstacle.x, obstacle.y,
            obstacle.width, obstacle.height)

        -- Debug visualization for obstacles
        if DEBUG then
            love.graphics.setColor(1, 1, 0, 0.5) -- Semi-transparent yellow
            love.graphics.rectangle("line", obstacle.x, obstacle.y,
                obstacle.width, obstacle.height)

            -- Draw obstacle coordinates
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(string.format("x:%.0f y:%.0f", obstacle.x, obstacle.y),
                obstacle.x, obstacle.y - 20)
        end
    end

    -- Reset color and draw player
    love.graphics.setColor(1, 1, 1)
    player:draw()
    love.graphics.setCanvas()

    -- Draw scaled canvas to screen
    local scale = love.graphics.getHeight() / GameHeight
    love.graphics.draw(GameCanvas, 0, 0, 0, scale, scale)
end
