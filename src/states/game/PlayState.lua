--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.player = Player {
        animations = ENTITY_DEFS['player'].animations,
        walkSpeed = ENTITY_DEFS['player'].walkSpeed,
        
        x = VIRTUAL_WIDTH / 2 - 8,
        y = VIRTUAL_HEIGHT / 2 - 11,
        
        width = 16,
        height = 22,

        -- one heart == 2 health
        health = 6,

        -- rendering and collision offset for spaced sprites
        offsetY = 5
    }

    self.dungeon = Dungeon(self.player)
    self.currentRoom = Room(self.player)
    
    self.player.stateMachine = StateMachine {
        ['walk'] = function() return PlayerWalkState(self.player, self.dungeon) end,
        ['idle'] = function() return PlayerIdleState(self.player, self.dungeon) end,
        ['swing-sword'] = function() return PlayerSwingSwordState(self.player, self.dungeon) end,
        ['lift'] = function() return PlayerLiftState(self.player, self.dungeon) end,
        ['carry'] = function() return PlayerCarryState(self.player, self.dungeon) end
    }
    self.player:changeState('idle')
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    self.dungeon:update(dt)
end

function PlayState:render()
    -- render dungeon and all entities separate from hearts GUI
    love.graphics.push()
    self.dungeon:render()
    love.graphics.pop()

    -- draw player hearts, top of screen
    local healthLeft = self.player.health
    local heartFrame = 1

    for i = 1, 3 do
        if healthLeft > 1 then
            heartFrame = 5
        elseif healthLeft == 1 then
            heartFrame = 3
        else
            heartFrame = 1
        end

        love.graphics.draw(gTextures['hearts'], gFrames['hearts'][heartFrame],
            (i - 1) * (TILE_SIZE + 1), 2)
        
        healthLeft = healthLeft - 2
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('x: ' .. tostring(math.floor(self.player.x)), 55, 2)
    love.graphics.print('y: ' .. tostring(math.floor(self.player.y)), 55, 11)
    -- love.graphics.print('offset_x: ' .. tostring(MAP_RENDER_OFFSET_X), 205, 2)
    -- love.graphics.print('offset_y: ' .. tostring(MAP_RENDER_OFFSET_Y), 205, 9)
    love.graphics.print('facingObject: ' .. tostring(self.player.facingObject), 205, 2)
    love.graphics.print('carryingObject: ' .. tostring(self.player.carryingObject), 205, 11)
end