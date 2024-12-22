local loader = require "libs.lovease"

local module = {}
local sprite = {}
sprite.__index = sprite

local function new(dir)
    local file = loader(dir)

    -- size
    local width = file.header.width
    local height = file.header.height
    local frames = {}
    local tags = {}
    local active = "" -- active tag
    local index = 1   -- actual frame
    local time = 0    -- current time elapsed
    local position = {
        x = 0,
        y = 0
    }
    local targetPosition = {
        x = 0,
        y = 0
    }

    for _, frame in ipairs(file.header.frames) do
        for _, chunk in ipairs(frame.chunks) do
            -- frame image data
            if chunk.type == 0x2005 then
                local cel = chunk.data
                local buffer = love.data.decompress("data", "zlib", cel.data)
                local data = love.image.newImageData(cel.width, cel.height, "rgba8", buffer)
                local image = love.graphics.newImage(data)
                local canvas = love.graphics.newCanvas(width, height)

                -- you need to draw in a canvas before.
                -- frame images can be of different sizes
                -- but never bigger than the header width and height
                love.graphics.setCanvas(canvas)
                love.graphics.draw(image, cel.x, cel.y)
                love.graphics.setCanvas()

                table.insert(frames, {
                    image = canvas,
                    duration = frame.frame_duration / 1000
                })

                -- tag
            elseif chunk.type == 0x2018 then
                for i, tag in ipairs(chunk.data.tags) do
                    -- first tag as default
                    if i == 1 then
                        active = tag.name
                    end

                    -- aseprite use 0 notation to begin
                    -- but in lua, everthing starts in 1
                    tag.to = tag.to + 1
                    tag.from = tag.from + 1
                    tag.frames = tag.to - tag.from
                    tags[tag.name] = tag
                end
            end
        end
    end
    return setmetatable({
        width = width,
        height = height,
        frames = frames,
        tags = tags,
        active = active,
        index = index,
        time = time,
        position = position,
        targetPosition = targetPosition,
        isMoving = false,
        velocity = { x = 0, y = 0 },
        maxSpeed = 250,
        acceleration = 200,
        friction = 700,
        maxJumps = 3,
        currentJumps = 0,
        jumpForce = -400,
        isFalling = false,
        groundY = GameHeight,
        state = "idle" -- Add state tracking
    }, sprite)
end

function sprite:play(name)
    assert(self.tags[name], "invalid tag: " .. name)

    if self.active ~= name then
        self.index = self.tags[name].from
        self.time = 0
        self.active = name
    end
end

function sprite:checkCollision(obstacle)
    -- Calculate the collision box offset from sprite position
    local collisionWidth = 14  -- narrow center collision width
    local collisionHeight = 30 -- bottom collision height

    -- Center the collision box horizontally
    local collisionX = self.position.x + (self.width - collisionWidth) / 2
    -- Position the collision box at the bottom of the sprite
    local collisionY = self.position.y - collisionHeight

    -- Check collision with adjusted box dimensions
    return collisionX < obstacle.x + obstacle.width and
        collisionX + collisionWidth > obstacle.x and
        collisionY < obstacle.y + obstacle.height and
        collisionY + collisionHeight > obstacle.y
end

function sprite:update(delta)
    assert(self.active, "no tag playing, sure you set this in aseprite?")
    local tag = self.tags[self.active]

    -- Update animation
    if (tag.to - tag.from) ~= 0 then
        self.time = self.time + delta

        if self.time >= self.frames[self.index].duration then
            self.index = self.index + 1
            self.time = 0

            if self.index > tag.to then
                if self.active == "attack" then
                    self.state = "idle"
                    self:play("idle")
                else
                    self.index = tag.from
                end
            end
        end
    end

    -- Store previous position for collision resolution
    local previousX = self.position.x
    local previousY = self.position.y

    -- Movement logic
    if love.keyboard.isDown('left') then
        if self.velocity.x > 0 then
            self.velocity.x = -self.velocity.x
        end
        local speedRatio = math.abs(self.velocity.x) / self.maxSpeed
        local accelerationFactor = 1 - speedRatio
        self.velocity.x = math.max(-self.maxSpeed, self.velocity.x - self.acceleration * accelerationFactor * delta)
        if self.state ~= "jumping" and self.state ~= "falling" and self.state ~= "attack" then
            self.state = "running"
        end
    elseif love.keyboard.isDown("right") then
        if self.velocity.x < 0 then
            self.velocity.x = -self.velocity.x
        end
        local speedRatio = math.abs(self.velocity.x) / self.maxSpeed
        local accelerationFactor = 1 - speedRatio
        self.velocity.x = math.min(self.maxSpeed, self.velocity.x + self.acceleration * accelerationFactor * delta)
        if self.state ~= "jumping" and self.state ~= "falling" and self.state ~= "attack" then
            self.state = "running"
        end
    else
        -- Apply friction
        if self.velocity.x > 0 then
            self.velocity.x = math.max(0, self.velocity.x - self.friction * delta)
        elseif self.velocity.x < 0 then
            self.velocity.x = math.min(0, self.velocity.x + self.friction * delta)
        end
        if math.abs(self.velocity.x) < 10 and self.state ~= "jumping" and self.state ~= "falling" and self.state ~= "attack" then
            self.state = "idle"
        end
    end

    self.velocity.x = math.min(self.maxSpeed, math.max(-self.maxSpeed, self.velocity.x))
    self.position.x = self.position.x + self.velocity.x * delta

    -- Vertical movement
    local gravity = 980
    self.velocity.y = self.velocity.y + gravity * delta
    self.position.y = self.position.y + self.velocity.y * delta

    -- Check collision with obstacles
    for _, obstacle in ipairs(Obstacles) do
        if self:checkCollision(obstacle) then
            -- Calculate collision box position
            local collisionWidth = 14
            local collisionHeight = 30
            local collisionX = previousX + (self.width - collisionWidth) / 2
            local collisionY = previousY - collisionHeight

            -- Handle vertical collision
            if self.velocity.y > 0 and collisionY + collisionHeight <= obstacle.y then
                -- Landing on top of obstacle
                self.position.y = obstacle.y + collisionHeight
                self.velocity.y = 0
                self.currentJumps = 0
                if self.state == "falling" then
                    self.state = "idle"
                end
            elseif self.velocity.y < 0 and collisionY >= obstacle.y + obstacle.height then
                -- Hitting bottom of obstacle
                self.position.y = obstacle.y + obstacle.height + collisionHeight
                self.velocity.y = 0
            end

            -- Handle horizontal collision
            if collisionX + collisionWidth <= obstacle.x then
                -- Collision from left
                self.position.x = obstacle.x - (self.width + collisionWidth) / 2
                self.velocity.x = 0
            elseif collisionX >= obstacle.x + obstacle.width then
                -- Collision from right
                self.position.x = obstacle.x + obstacle.width - (self.width - collisionWidth) / 2
                self.velocity.x = 0
            end
        end
    end

    -- Ground collision
    if self.position.y > self.groundY then
        self.position.y = self.groundY
        self.velocity.y = 0
        self.currentJumps = 0
        if self.state == "falling" then
            self.state = "idle"
        end
    end

    -- Update state based on vertical movement
    if self.velocity.y < 0 then
        self.state = "jumping"
    elseif self.velocity.y > 50 then
        self.state = "falling"
    end

    -- Update animation based on state
    if self.state == "idle" then
        self:play("idle")
    elseif self.state == "running" then
        self:play("run")
    elseif self.state == "jumping" or self.state == "falling" then
        self:play("jump")
    end
end

function sprite:key(key)
    if key == "left" or key == "right" then
        if self.state ~= "attack" then
            self.state = "running"
        end
    elseif key == "up" then
        if self.currentJumps < self.maxJumps then
            self.velocity.y = self.jumpForce
            self.currentJumps = self.currentJumps + 1
            self.state = "jumping"
        end
    elseif key == "space" and self.state ~= "attack" then
        self.state = "attack"
        self:play("attack")
    end
end

function sprite:draw()
    -- Draw the sprite
    love.graphics.draw(self.frames[self.index].image, self.position.x, self.position.y - self.height, 0, 1, 1)

    -- Debug visualization
    if DEBUG then
        if DebugOptions.showCollisions then
            -- Draw collision boxes
            love.graphics.setColor(1, 0, 0, 0.5) -- Semi-transparent red
            local collisionWidth = 14
            local collisionHeight = 30
            local collisionX = self.position.x + (self.width - collisionWidth) / 2
            local collisionY = self.position.y - collisionHeight

            -- Draw collision box
            love.graphics.rectangle("line", collisionX, collisionY, collisionWidth, collisionHeight)

            -- Draw sprite bounds
            love.graphics.setColor(0, 1, 0, 0.5) -- Semi-transparent green
            love.graphics.rectangle("line", self.position.x, self.position.y - self.height, self.width, self.height)

            -- Draw position point
            love.graphics.setColor(0, 0, 1, 1) -- Blue
            love.graphics.circle("fill", self.position.x, self.position.y, 2)
        end

        if DebugOptions.showVelocities then
            -- Draw velocity vectors
            local vectorScale = 0.5 -- Scale factor for velocity vectors

            -- Horizontal velocity (red)
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.line(
                self.position.x,
                self.position.y,
                self.position.x + self.velocity.x * vectorScale,
                self.position.y
            )

            -- Vertical velocity (blue)
            love.graphics.setColor(0, 0, 1, 1)
            love.graphics.line(
                self.position.x,
                self.position.y,
                self.position.x,
                self.position.y + self.velocity.y * vectorScale
            )
        end

        if DebugOptions.showInfo then
            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)

            -- Draw debug info panel
            local debugX = 10
            local debugY = 10
            local lineHeight = 15

            -- Background for debug text
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", debugX - 5, debugY - 5, 200, 130)
            love.graphics.setColor(1, 1, 1, 1)

            -- Debug text information
            love.graphics.print(string.format("Position: %.1f, %.1f", self.position.x, self.position.y),
                debugX, debugY)
            love.graphics.print(string.format("Velocity X: %.1f", self.velocity.x),
                debugX, debugY + lineHeight)
            love.graphics.print(string.format("Velocity Y: %.1f", self.velocity.y),
                debugX, debugY + lineHeight * 2)
            love.graphics.print(string.format("Speed: %.1f", math.sqrt(self.velocity.x ^ 2 + self.velocity.y ^ 2)),
                debugX, debugY + lineHeight * 3)
            love.graphics.print("State: " .. self.state,
                debugX, debugY + lineHeight * 4)
            love.graphics.print(string.format("Jumps: %d/%d", self.currentJumps, self.maxJumps),
                debugX, debugY + lineHeight * 5)
            love.graphics.print(string.format("Max Speed: %.1f", self.maxSpeed),
                debugX, debugY + lineHeight * 6)
            love.graphics.print(string.format("Is Falling: %s", tostring(self.velocity.y > 0)),
                debugX, debugY + lineHeight * 7)
        end

        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

module.new = new

return setmetatable(module, {
    __call = function(_, ...)
        return new(...)
    end
})
