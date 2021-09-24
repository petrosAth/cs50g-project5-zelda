--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerLiftState = Class{__includes = BaseState}

function PlayerLiftState:init(player, dungeon)
    self.player = player
    self.dungeon = dungeon

    -- render offset for spaced character sprite; negated in render function of state
    self.player.offsetY = 5
    self.player.offsetX = 0

    self.player:changeAnimation('pot-lift-' .. self.player.direction)
    for k, object in pairs(self.dungeon.currentRoom.objects) do
        if object.inPosition then
            object.solid = false
            object.state = 'lifted'
            object.x = self.player.x
            object.y = self.player.y - object.height + 6
        end
    end
    self.player.carryingObject = true
end

function PlayerLiftState:enter(params)

    -- restart sword swing sound for rapid swinging
    gSounds['hit-player']:stop()
    gSounds['hit-player']:play()

    -- restart sword swing animation
    self.player.currentAnimation:refresh()
end

function PlayerLiftState:update(dt)

    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0
        self.player:changeState('carry')
    end
end

function PlayerLiftState:render()

    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end