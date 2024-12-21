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
    local speed = 800   -- pixels per second
    local isMoving = false
    local easing = 0.15 -- easing factor

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
        speed = speed,
        isMoving = isMoving,
        easing = easing
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
                self.index = tag.from
            end
        end
    end

    -- Smooth movement towards target position with easing
    local dx = self.targetPosition.x - self.position.x
    local dy = self.targetPosition.y - self.position.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > 0.2 then
        self.isMoving = true
        self.position.x = self.position.x + dx * self.easing
        self.position.y = self.position.y + dy * self.easing
    else
        self.isMoving = false
        self.position.x = self.targetPosition.x
        self.position.y = self.targetPosition.y
    end

    -- If not moving, switch to idle animation
    if not self.isMoving then
        self:play("idle")
    end
end

function sprite:key(key)
    -- handle arrow keys
    if key == "left" then
        self.targetPosition.x = self.targetPosition.x - 100
        self:play("run")
    elseif key == "right" then
        self.targetPosition.x = self.targetPosition.x + 100
        self:play("run")
    elseif key == "up" then
        self.targetPosition.y = self.targetPosition.y - 100
        self:play("run")
    elseif key == "down" then
        self.targetPosition.y = self.targetPosition.y + 100
        self:play("run")
    end
end

function sprite:draw(angle, sx, sy)
    love.graphics.draw(self.frames[self.index].image, self.position.x, self.position.y, angle, sx, sy)
end

module.new = new

return setmetatable(module, {
    __call = function(_, ...)
        return new(...)
    end
})
