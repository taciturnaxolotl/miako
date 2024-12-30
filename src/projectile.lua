local Sprite = require "sprite"

local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(position, velocity)
    local self = {
        sprite = Sprite.new("sprites/blast.ase"),
        position = position,
        velocity = velocity,
        isDead = false,
        state = "move",
        explosionTimer = 0,
        explosionDuration = 1.5, -- Duration of explosion animation in seconds
        width = 20,              -- Collision box width
        height = 20,             -- Collision box height
        damage = 10
    }
    return setmetatable(self, Projectile)
end

function Projectile:checkCollision(obstacle)
    local x = obstacle.position and obstacle.position.x or obstacle.x
    local y = obstacle.position and obstacle.position.y or obstacle.y
    return self.position.x < x + obstacle.width and
        self.position.x + self.width > x and
        self.position.y < y + obstacle.height and
        self.position.y + self.height > y
end

function Projectile:isOutOfBounds(gameWidth, gameHeight)
    return self.position.x < 0 or
        self.position.x > gameWidth or
        self.position.y < 0 or
        self.position.y > gameHeight
end

function Projectile:update(obstacles, gameWidth, gameHeight, delta)
    self.sprite:update(delta)
    if self.state == "move" then
        -- Update position based on velocity
        self.position.x = self.position.x + self.velocity.x * delta
        self.position.y = self.position.y + self.velocity.y * delta

        -- Check for collisions with obstacles
        local hitObstacle = false
        for _, obstacle in ipairs(obstacles) do
            if self:checkCollision(obstacle) then
                hitObstacle = true
                break
            end
        end

        -- Check for collisions with enemies
        local hitEnemy = false
        for _, enemy in ipairs(Enemies) do
            if self:checkCollision(enemy) then
                hitEnemy = true
                enemy:takeDamage(self.damage)
                self.state = "explosion"
                self.velocity.x = 0
                self.velocity.y = 0
                self.sprite:play("explode", false)
                break
            end
        end

        -- Change state to explosion if hit obstacle/enemy or out of bounds
        if hitObstacle or self:isOutOfBounds(gameWidth, gameHeight) then
            self.state = "explosion"
            self.velocity.x = 0
            self.velocity.y = 0
            self.sprite:play("explode", false)
        end
    elseif self.state == "explosion" then
        self.explosionTimer = self.explosionTimer + delta
        if self.explosionTimer >= self.explosionDuration then
            self.isDead = true
        end
    end
end

function Projectile:draw()
    love.graphics.setColor(1, 1, 1)
    local scale = 1
    if self.state == "explosion" then
        scale = scale * (1 + self.explosionTimer / self.explosionDuration)
        -- Adjust position to keep explosion centered while scaling
        local offsetX = (self.sprite.width * scale - self.sprite.width) / 2
        local offsetY = (self.sprite.height * scale - self.sprite.height) / 2
        self.sprite:draw(self.position.x - offsetX, self.position.y - offsetY, 0, scale, scale)
    else
        self.sprite:draw(self.position.x, self.position.y, 0, scale, scale)
    end
end

return Projectile
