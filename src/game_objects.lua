--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GAME_OBJECT_DEFS = {
    ['switch'] = {
        type = 'switch',
        texture = 'switches',
        frame = 2,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unpressed',
        states = {
            ['unpressed'] = {
                frame = 2
            },
            ['pressed'] = {
                frame = 1
            }
        }
    },
    ['pot'] = {
        type = 'pot',
        texture = 'tiles',
        frame = 33,
        width = 16,
        height = 16,
        solid = true,
        defaultState = 'onGround',
        states = {
            ['onGround'] = {
                frame = 33
            },
            ['lifted'] = {
                frame = 14
            },
            ['onAir'] = {
                frame = 14
            },
            ['broken'] = {
                frame = 52
            },
            ['used'] = {
                frame = 52
            }
        }
    },
    ['heartDrop'] = {
        type = 'heartDrop',
        texture = 'hearts',
        frame = 5,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unused',
        states = {
            ['unused'] = {
                frame = 5
            },
            ['used'] = {
                frame = 5
            }
        }
    }
}