--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameObject = Class{}

function GameObject:init(def, x, y)
    
    -- string identifying this object type
    self.type = def.type

    self.texture = def.texture
    self.frame = def.frame or 1

    -- whether it acts as an obstacle or not
    self.solid = def.solid

    self.defaultState = def.defaultState
    self.state = self.defaultState
    self.states = def.states

    -- dimensions
    self.x = x
    self.y = y
    self.width = def.width
    self.height = def.height

    -- default empty collision callback
    self.onCollide = function() end

    -- flag for lifting objects
    self.inPosition = false

    -- direction in witch the object travels when thrown
    self.direction = nil
    self.travelX = 0
    self.travelY = 0

    -- flags for flashing the object when broken
    self.brokenDuration = 1
    self.brokenTimer = 0

    -- timer for turning transparency on and off, flashing
    self.flashTimer = 0
end

function GameObject:update(dt)

    -- when thrown the object travels on the direction the player is turned
    if self.state == 'onAir' then
        self.solid = true

        if self.direction == 'up' then
            if self.y > self.travelY - 80 then
                self.y = self.y - 2 * PLAYER_WALK_SPEED * dt
            else
                self.state = 'broken'
            end
        elseif self.direction == 'down' then
            if self.y < self.travelY + 80 then
                self.y = self.y + 2 * PLAYER_WALK_SPEED * dt
            else
                self.state = 'broken'
            end
        elseif self.direction == 'left' then
            if self.x > self.travelX - 80 then
                self.x = self.x - 2 * PLAYER_WALK_SPEED * dt
            else
                self.state = 'broken'
            end
        elseif self.direction == 'right' then
            if self.x < self.travelX + 80 then
                self.x = self.x + 2 * PLAYER_WALK_SPEED * dt
            else
                self.state = 'broken'
            end
        end

    end

    -- make the object collide with the walls
    if self.direction == 'left' then
        if self.x <= MAP_RENDER_OFFSET_X + TILE_SIZE then 
            self.x = MAP_RENDER_OFFSET_X + TILE_SIZE
            self.state = 'broken'
        end
    elseif self.direction == 'right' then
        if self.x + self.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 then
            self.x = VIRTUAL_WIDTH - TILE_SIZE * 2 - self.width
            self.state = 'broken'
        end
    elseif self.direction == 'up' then
        if self.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2 then 
            self.y = MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2
            self.state = 'broken'
        end
    elseif self.direction == 'down' then
        local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
            + MAP_RENDER_OFFSET_Y - TILE_SIZE

        if self.y + self.height >= bottomEdge then
            self.y = bottomEdge - self.height
            self.state = 'broken'
        end
    end

    -- on collision the object get broken and disapears while flashing
    if self.state == 'broken' then
        self.x = self.x
        self.y = self.y
        self.flashTimer = self.flashTimer + dt
        self.brokenTimer = self.brokenTimer + dt

        if self.brokenTimer > self.brokenDuration then
            self.state = 'used'
            self.brokenTimer = 0
            self.brokenDuration = 0
            self.flashTimer = 0
        end
    end
end

function GameObject:render(adjacentOffsetX, adjacentOffsetY)
    -- draw sprite slightly transparent if invulnerable every 0.04 seconds
    if self.state == 'broken' and self.flashTimer > 0.06 then
        self.flashTimer = 0
        love.graphics.setColor(1, 1, 1, 64/255)
    end

    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.states[self.state].frame or self.frame],
        self.x + adjacentOffsetX, self.y + adjacentOffsetY)
        love.graphics.setColor(1, 1, 1, 255/255)
end