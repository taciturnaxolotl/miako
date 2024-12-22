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
    }, sprite)
end

function sprite:play(name)
    assert(self.tags[name], "invalid tag: " .. name)

    -- if arent playing...
    -- prevent indexes bigger than tag to
    if self.active ~= name then
        self.index = self.tags[name].from
    end

    self.active = name
end

function sprite:update(delta)
    assert(self.active, "no tag playing, sure you set this in aseprite?")
    local tag = self.tags[self.active]

    -- time tracker are useless on single frames...
    if (tag.to - tag.from) ~= 0 then
        self.time = self.time + delta

        -- next frame
        if self.time >= self.frames[self.index].duration then
            self.index = self.index + 1
            self.time = 0 -- you can change to "self.time - frame.duration" as well

            -- reach the end, return to begin
            if self.index > tag.to then
                if self.active == "attack" then
                    self:play("idle")
                else
                    self.index = tag.from
                end
            end
        end
    end

    if love.keyboard.isDown('left') then
        if self.velocity.x > 0 then
            self.velocity.x = -self.velocity.x
        end
        local speedRatio = math.abs(self.velocity.x) / self.maxSpeed
        local accelerationFactor = 1 - speedRatio
        self.velocity.x = math.max(-self.maxSpeed, self.velocity.x - self.acceleration * accelerationFactor * delta)
    elseif love.keyboard.isDown("right") then
        if self.velocity.x < 0 then
            self.velocity.x = -self.velocity.x
        end
        local speedRatio = math.abs(self.velocity.x) / self.maxSpeed
        local accelerationFactor = 1 - speedRatio
        self.velocity.x = math.min(self.maxSpeed, self.velocity.x + self.acceleration * accelerationFactor * delta)
    end

    -- Horizontal movement with friction
    if not love.keyboard.isDown('left') and not love.keyboard.isDown('right') then
        -- Apply friction when no movement keys are pressed
        if self.velocity.x > 0 then
            self.velocity.x = math.max(0, self.velocity.x - self.friction * delta)
        elseif self.velocity.x < 0 then
            self.velocity.x = math.min(0, self.velocity.x + self.friction * delta)
        end
    end

    -- Clamp velocity to max speed
    self.velocity.x = math.min(self.maxSpeed, math.max(-self.maxSpeed, self.velocity.x))

    -- Update horizontal position
    self.position.x = self.position.x + self.velocity.x * delta

    -- Vertical movement (jumping)
    local gravity = 980

    -- Apply gravity
    self.velocity.y = self.velocity.y + gravity * delta
    self.position.y = self.position.y + self.velocity.y * delta

    -- Ground collision
    if self.position.y > self.groundY then
        self.position.y = self.groundY
        self.velocity.y = 0
        self.isFalling = false
        self.currentJumps = 0
    end

    -- Update falling state
    if self.velocity.y > 50 then
        self.isFalling = true
    end

    -- Check if moving horizontally
    self.isMoving = math.abs(self.velocity.x) > 10

    -- Animation state management
    print(tag.name)

    if self.velocity.y < 0 then
        self:play("jump")
    elseif self.isFalling then
        self:play("jump")
    end
    if not self.isMoving and self.velocity.y == 0 and not tag.name == "attack" then
        self:play("idle")
    end
end

function sprite:key(key)
    -- handle arrow keys
    if key == "left" then
        if self.velocity.x > 0 then
            self.velocity.x = -self.velocity.x
        end
        local speedRatio = math.abs(self.velocity.x) / self.maxSpeed
        local accelerationFactor = 1 - speedRatio
        self.velocity.x = math.max(-self.maxSpeed, self.velocity.x - self.acceleration * accelerationFactor)
        self:play("run")
    elseif key == "right" then
        if self.velocity.x < 0 then
            self.velocity.x = -self.velocity.x
        end
        local speedRatio = math.abs(self.velocity.x) / self.maxSpeed
        local accelerationFactor = 1 - speedRatio
        self.velocity.x = math.min(self.maxSpeed, self.velocity.x + self.acceleration * accelerationFactor)
        self:play("run")
    elseif key == "up" then
        -- Allow jumping if we haven't exceeded max jumps
        if self.currentJumps < self.maxJumps then
            self.velocity.y = self.jumpForce
            self.currentJumps = self.currentJumps + 1
            self.isFalling = false
            self:play("jump")
        end
    elseif key == "space" then
        self:play("attack")
    end
end

function sprite:draw()
    love.graphics.draw(self.frames[self.index].image, self.position.x, self.position.y - self.height, 0, 1,
        1)
end

module.new = new

return setmetatable(module, {
    __call = function(_, ...)
        return new(...)
    end
})
