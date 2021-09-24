--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerIdleState = Class{__includes = EntityIdleState}

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
        self.entity:changeState('swing-sword')
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
       if self.entity.facingObject and not self.entity.carryingObject then
           self.entity:changeState('lift')
       end
    end
end