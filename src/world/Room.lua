--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class{}

function Room:init(player)
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT

    self.tiles = {}
    self:generateWallsAndFloors()

    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- game objects in the room
    self.objects = {}
    self:generateObjects('switch')
    self:generateObjects('pot')

    -- doorways that lead to other dungeon rooms
    self.doorways = {}
    table.insert(self.doorways, Doorway('top', false, self))
    table.insert(self.doorways, Doorway('bottom', false, self))
    table.insert(self.doorways, Doorway('left', false, self))
    table.insert(self.doorways, Doorway('right', false, self))

    -- reference to player for collisions, etc.
    self.player = player

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0
end

--[[
    Randomly creates an assortment of enemies for the player to fight.
]]
function Room:generateEntities()
    local types = {'skeleton', 'slime', 'bat', 'ghost', 'spider'}

    for i = 1, 10 do
        local type = types[math.random(#types)]

        table.insert(self.entities, Entity {
            animations = ENTITY_DEFS[type].animations,
            walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,

            -- ensure X and Y are within bounds of the map
            x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),
            
            width = 16,
            height = 16,

            health = 1,

            dropChance = ENTITY_DEFS[type].heartDropChance or 0
        })

        self.entities[i].stateMachine = StateMachine {
            ['walk'] = function() return EntityWalkState(self.entities[i]) end,
            ['idle'] = function() return EntityIdleState(self.entities[i]) end
        }

        self.entities[i]:changeState('walk')
    end
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateObjects(object, entity)
    if object == 'switch' then
        local switch = GameObject(
            GAME_OBJECT_DEFS['switch'],
            math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                        VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
            math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                        VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
        )

        -- define a function for the switch that will open all doors in the room
        switch.onCollide = function()
            if switch.state == 'unpressed' then
                switch.state = 'pressed'
                
                -- open every door in the room if we press the switch
                for k, doorway in pairs(self.doorways) do
                    doorway.open = true
                end

                gSounds['door']:play()
            end
        end

        -- add to list of objects in scene
        table.insert(self.objects, switch)

    elseif object == 'drop' then
        if entity.dropChance < math.random(5) then
            local drop = GameObject(
                GAME_OBJECT_DEFS['heartDrop'],
                entity.x,
                entity.y
            )

            drop.onCollide = function()
                drop.state = 'used'
                if self.player.health == 5 then
                    self.player.health = self.player.health + 1
                elseif self.player.health <= 4 then
                    self.player.health = self.player.health + 2
                end

            end

            if drop ~= nil then
                -- add to list of objects in scene
                table.insert(self.objects, drop)
            end
        end
    elseif object == 'pot' then
        for y = 1, math.random(5) do
            local pot = GameObject(
                GAME_OBJECT_DEFS['pot'],
                math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                            VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
                math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                            VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
            )

            -- define a function for the switch that will open all doors in the room
            pot.onCollide = function(object, direction)

                local tempDirection = direction

                if tempDirection == self.player.direction then
                    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
                        object.x = object.x + 5
                    end
                end
            end

            -- add to list of objects in scene
            table.insert(self.objects, pot)
        end
    end
end

--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function Room:update(dt)

    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- remove entity from the table if health is <= 0
        if entity.health <= 0 and not entity.looted then
            entity.dead = true
            entity.looted = true
            Event.dispatch('entityDeath', entity)
        elseif not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end
    end

    for k, object in pairs(self.objects) do
        object:update(dt)

        if self.player.x > object.x + object.width + 1
        or self.player.x + self.player.width < object.x - 1
        or self.player.y + self.player.height / 2 > object.y + object.height + 1
        or self.player.y + self.player.height < object.y - 1 then
            object.inRange = false
        end

        -- trigger collision callback on object
        if self.player:collides(object) then
            object:onCollide(self.player.direction)

            if object.solid then
                self.player:onCollide(object)
                object.inRange = true

                if self.player.direction == 'left' then
                    self.player.x = self.player.x + self.player.walkSpeed * dt
                elseif self.player.direction == 'right' then
                    self.player.x = self.player.x - self.player.walkSpeed * dt
                elseif self.player.direction == 'up' then
                    self.player.y = self.player.y + self.player.walkSpeed * dt
                elseif self.player.direction == 'down' then
                    self.player.y = self.player.y - self.player.walkSpeed * dt
                end
            end
        end

        for l, entity in pairs(self.entities) do
            if entity:collides(object) and object.solid then
                if entity.direction == 'left' then
                    entity.x = object.x + object.width + entity.walkSpeed * dt

                elseif entity.direction == 'right' then
                    entity.x = object.x - entity.width - entity.walkSpeed * dt

                elseif entity.direction == 'up' then
                    entity.y = object.y + object.height + entity.walkSpeed * dt

                elseif entity.direction == 'down' then
                    entity.y = object.y - entity.height - entity.walkSpeed * dt

                end

            end
        end

        if object.state == 'used' then
            table.remove(self.objects, k)
        end
    end
end

function Room:render()
    for y = 1, self.height do
        for x = 1, self.width do
            local tile = self.tiles[y][x]
            love.graphics.draw(gTextures['tiles'], gFrames['tiles'][tile.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY)
        end
    end

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly
    for k, doorway in pairs(self.doorways) do
        doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
        object:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, entity in pairs(self.entities) do
        if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)
    
    if self.player then
        self.player:render()
    end

    love.graphics.setStencilTest()

    --
    -- DEBUG DRAWING OF STENCIL RECTANGLES
    --

    -- love.graphics.setColor(255, 0, 0, 100)
    
    -- -- left
    -- love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
    -- TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- right
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
    --     MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- top
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- --bottom
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    
    -- love.graphics.setColor(255, 255, 255, 255)

    for k, object in pairs(self.objects) do
        
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.print('object.inRange: ' .. tostring(object.inRange), object.x, object.y - 30)
        love.graphics.print('object.x: ' .. tostring(object.x), object.x, object.y - 20)
        love.graphics.print('object.y: ' .. tostring(object.y), object.x, object.y - 10)
        love.graphics.rectangle('line', object.x, object.y, object.width, object.height)
        love.graphics.setColor(1, 1, 1, 1)
    end
end