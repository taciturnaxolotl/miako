local Player = require "player"
DEBUG = false
DebugOptions = {
    showCollisions = true,
    showVelocities = true,
    showInfo = true,
    showProjectiles = true
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

    player = Player("sprites/player.ase")
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
    elseif key == "f5" then
        DebugOptions.showProjectiles = not DebugOptions.showProjectiles
    end
end

function love.draw()
    -- Draw game content to game canvas
    love.graphics.setCanvas(GameCanvas)
    love.graphics.clear()

    -- Draw obstacles
    for _, obstacle in ipairs(Obstacles) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", obstacle.x, obstacle.y,
            obstacle.width, obstacle.height)
    end

    -- Reset color and draw player
    love.graphics.setColor(1, 1, 1)
    player:draw()

    -- Draw game canvas to window canvas
    love.graphics.setCanvas(WindowCanvas)
    love.graphics.clear()

    -- Calculate position to center the game canvas
    local x = (WindowWidth - (GameWidth * Scale)) / 2
    local y = (WindowHeight - (GameHeight * Scale)) / 2

    -- Draw scaled game canvas centered
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(GameCanvas, x, y, 0, Scale, Scale)


    -- Draw debug information on window canvas
    if DEBUG then
        -- draw outline of game canvas
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, y, GameWidth * Scale, GameHeight * Scale)

        -- Draw debug visualization for obstacles
        for _, obstacle in ipairs(Obstacles) do
            if DebugOptions.showCollisions then
                love.graphics.setColor(1, 1, 0, 0.5)
                love.graphics.rectangle("line",
                    obstacle.x * Scale + x,
                    obstacle.y * Scale + y,
                    obstacle.width * Scale,
                    obstacle.height * Scale)

                if DebugOptions.showInfo then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(string.format("x:%.0f y:%.0f",
                            obstacle.x, obstacle.y),
                        obstacle.x * Scale + x,
                        obstacle.y * Scale + y - 20 * Scale)
                end
            end
        end

        -- Draw player debug information
        player:drawDebug(x, y, Scale)

        -- Draw debug option indicators
        local debugFont = love.graphics.newFont(24)
        local originalFont = love.graphics.getFont()
        love.graphics.setFont(debugFont)

        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", (WindowWidth) - 12, 20, 10)
        if DebugOptions.showCollisions then
            love.graphics.setColor(1, 1, 0, 0.5) -- Semi-transparent yellow
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (WindowWidth) - 12, 20, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Show Collisions (F2)", WindowWidth - 300, 3)

        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", (WindowWidth) - 12, 50, 10)
        if DebugOptions.showVelocities then
            love.graphics.setColor(1, 0, 0, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (WindowWidth) - 12, 50, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Show Velocities (F3)", WindowWidth - 300, 33)

        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", (WindowWidth) - 12, 80, 10)
        if DebugOptions.showInfo then
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (WindowWidth) - 12, 80, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Show Info (F4)", WindowWidth - 300, 63)

        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", (WindowWidth) - 12, 110, 10)
        if DebugOptions.showProjectiles then
            love.graphics.setColor(0, 1, 0, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.circle("fill", (WindowWidth) - 12, 110, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Show Projectiles (F5)", WindowWidth - 300, 93)

        love.graphics.setFont(originalFont)
    end

    -- Draw window canvas to screen
    love.graphics.setCanvas()
    love.graphics.draw(WindowCanvas, 0, 0)
end
