local Sprite = require "sprite"

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(position, velocity)
    local self = {
        sprite = Sprite.new("sprites/enemy.ase"),
        position = position,
        velocity = velocity,
        isDead = false,
        state = "idle",
        health = 100,
        deathTimer = 0,
        deathDuration = 1.75,
        width = 28,  -- Will be set after sprite loads
        height = 27, -- Will be set after sprite loads
        damage = 10,
        gravity = 680,
        groundY = GameHeight,
        isGrounded = false
    }
    self.sprite:play("idle")
    return setmetatable(self, Enemy)
end

function Enemy:isOutOfBounds()
    return self.position.x < 0 or
        self.position.x > GameWidth or
        self.position.y < 0 or
        self.position.y > GameHeight
end

function Enemy:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.state = "dead"
        self.velocity.x = 0
        self.velocity.y = 0
        self.sprite:play("dead", false)
    end
end

function Enemy:update(delta)
    -- Store previous position for collision resolution
    local previousX = self.position.x
    local previousY = self.position.y

    -- Apply gravity
    self.velocity.y = self.velocity.y + self.gravity * delta
    self.position.y = self.position.y + self.velocity.y * delta

    -- Update horizontal position
    self.position.x = self.position.x + self.velocity.x * delta

    -- Check collision with obstacles
    for _, obstacle in ipairs(Obstacles) do
        if self:checkCollision(obstacle) then
            -- Calculate collision box position
            local collisionWidth = self.width
            local collisionHeight = self.height
            local collisionX = previousX + (self.width - collisionWidth) / 2
            local collisionY = previousY - collisionHeight

            -- Handle vertical collision
            if self.velocity.y > 0 and collisionY + collisionHeight <= obstacle.y then
                -- Landing on top of obstacle
                self.position.y = obstacle.y
                self.velocity.y = 0
                self.isGrounded = true
            elseif self.velocity.y < 0 and collisionY >= obstacle.y + obstacle.height then
                -- Hitting bottom of obstacle
                self.position.y = obstacle.y + obstacle.height + self.height
                self.velocity.y = 0
            end

            -- Handle horizontal collision
            if collisionX + collisionWidth <= obstacle.x then
                -- Collision from left
                self.position.x = obstacle.x - (self.width + collisionWidth) / 2
                self.velocity.x = -self.velocity.x -- Reverse direction on collision
            elseif collisionX >= obstacle.x + obstacle.width then
                -- Collision from right
                self.position.x = obstacle.x + obstacle.width - (self.width - collisionWidth) / 2
                self.velocity.x = -self.velocity.x -- Reverse direction on collision
            end
        end
    end

    -- Ground collision
    if self.position.y > self.groundY then
        self.position.y = self.groundY
        self.velocity.y = 0
        self.isGrounded = true
    end
end

function Enemy:checkCollision(obstacle)
    -- Calculate the collision box offset from enemy position
    local collisionWidth = self.width
    local collisionHeight = self.height

    -- Center the collision box horizontally
    local collisionX = self.position.x + (self.width - collisionWidth) / 2
    -- Position the collision box at the bottom of the enemy
    local collisionY = self.position.y - collisionHeight

    return collisionX < obstacle.x + obstacle.width and
        collisionX + collisionWidth > obstacle.x and
        collisionY < obstacle.y + obstacle.height and
        collisionY + collisionHeight > obstacle.y
end

function Enemy:draw()
    love.graphics.setColor(1, 1, 1)
    local scale = 1
    self.sprite:draw(self.position.x, self.position.y - self.sprite.height, 0, scale, scale)
end

return Enemy
