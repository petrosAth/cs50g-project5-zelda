--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerIdleState = Class{__includes = EntityIdleState}

function PlayerIdleState:init(player, dungeon)
    self.entity = player
    self.dungeon = dungeon
end

function PlayerIdleState:enter(params)
    if self.entity.carryingObject then
        self.entity:changeAnimation('pot-idle-' .. self.entity.direction)
    else
        self.entity:changeAnimation('idle-' .. self.entity.direction)
    end

    -- render offset for spaced character sprite (negated in render function of state)
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerIdleState:update(dt)
    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        if self.entity.carryingObject then
            self.entity:changeState('carry')
        else
            self.entity:changeState('walk')
        end
        self.entity.facingObject = false
    end

    if love.keyboard.wasPressed('space') then
        if not self.entity.carryingObject then
            self.entity:changeState('swing-sword')
        end
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        if self.entity.facingObject and not self.entity.carryingObject then
            self.entity:changeState('lift')

        elseif self.entity.carryingObject then
            for k, object in pairs(self.dungeon.currentRoom.objects) do
                if object.state == 'lifted' then
                    object.state = 'onAir'
                    if self.entity.direction == 'left' then
                        object.direction = 'left'
                    elseif self.entity.direction == 'right' then
                        object.direction = 'right'
                    elseif self.entity.direction == 'up' then
                        object.direction = 'up'
                    elseif self.entity.direction == 'down' then
                        object.direction = 'down'
                    end

                    -- when thrown, the object gets player's position
                    object.x, object.y = self.entity.x, self.entity.y
                    object.travelX, object.travelY = object.x, object.y
                end
            end

            self.entity.carryingObject = false
            self.entity:changeAnimation('idle-' .. self.entity.direction)
        end

    end
end