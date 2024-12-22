local Sprite = require "sprite"
DEBUG = false
DebugOptions = {
    showCollisions = true,
    showVelocities = true,
    showInfo = true
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Set up game resolution and scaling
    GameWidth, GameHeight = 380, 180
    WindowWidth, WindowHeight = love.window.getDesktopDimensions()

    -- Calculate max integer scale that fits screen
    local scaleX = math.floor(WindowWidth / GameWidth)
    local scaleY = math.floor(WindowHeight / GameHeight)
    Scale = math.min(scaleX, scaleY)

    -- Create game canvas
    GameCanvas = love.graphics.newCanvas(GameWidth, GameHeight)

    -- Create window-sized canvas
    WindowCanvas = love.graphics.newCanvas(WindowWidth, WindowHeight)

    -- Set up window
    love.window.setMode(WindowWidth, WindowHeight, { fullscreen = true })

    -- Create obstacles
    Obstacles = {
        { x = 50,  y = 182.5, width = 15, height = 25 },
        { x = 100, y = 177.5, width = 15, height = 25 },
        { x = 150, y = 172.5, width = 15, height = 25 },
        { x = 200, y = 167.5, width = 15, height = 25 },
        { x = 250, y = 162.5, width = 15, height = 25 },
        { x = 300, y = 157.5, width = 15, height = 25 },
        { x = 350, y = 152.5, width = 15, height = 25 },
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
        DEBUG = not DEBUG -- Toggle all debug visualization
    elseif key == "f2" then
        DebugOptions.showCollisions = not DebugOptions.showCollisions
    elseif key == "f3" then
        DebugOptions.showVelocities = not DebugOptions.showVelocities
    elseif key == "f4" then
        DebugOptions.showInfo = not DebugOptions.showInfo
    end
end

function love.draw()
    -- Draw game content to game canvas
    love.graphics.setCanvas(GameCanvas)
    love.graphics.clear()

    -- Draw obstacles
    for _, obstacle in ipairs(Obstacles) do
        -- Draw obstacle fill
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", obstacle.x, obstacle.y,
            obstacle.width, obstacle.height)

        -- Debug visualization for obstacles
        if DEBUG and DebugOptions.showCollisions then
            love.graphics.setColor(1, 1, 0, 0.5) -- Semi-transparent yellow
            love.graphics.rectangle("line", obstacle.x, obstacle.y,
                obstacle.width, obstacle.height)

            -- Draw obstacle coordinates
            if DebugOptions.showInfo then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(string.format("x:%.0f y:%.0f", obstacle.x, obstacle.y),
                    obstacle.x, obstacle.y - 20)
            end
        end
    end

    -- Reset color and draw player
    love.graphics.setColor(1, 1, 1)
    player:draw()

    -- Draw option indicator circles in top right
    if DEBUG then
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("fill", (GameWidth * Scale) / 2 - 12, 20, 10)
        if DebugOptions.showCollisions then
            love.graphics.setColor(1, 1, 0, 0.5) -- Semi-transparent yellow
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (GameWidth * Scale) / 2 - 12, 20, 8)

        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("fill", (GameWidth * Scale) / 2 - 12, 40, 10)
        if DebugOptions.showVelocities then
            love.graphics.setColor(1, 0, 0, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (GameWidth * Scale) / 2 - 12, 40, 8)

        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("fill", (GameWidth * Scale) / 2 - 12, 60, 10)
        if DebugOptions.showInfo then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (GameWidth * Scale) / 2 - 12, 60, 8)
    end

    -- Draw game canvas to window canvas
    love.graphics.setCanvas(WindowCanvas)
    love.graphics.clear()

    -- Calculate position to center the game canvas
    local x = (WindowWidth - (GameWidth * Scale)) / 2
    local y = (WindowHeight - (GameHeight * Scale)) / 2

    -- Draw scaled game canvas centered
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(GameCanvas, x, y, 0, Scale, Scale)

    -- Draw window canvas to screen
    love.graphics.setCanvas()
    love.graphics.draw(WindowCanvas, 0, 0)
end
