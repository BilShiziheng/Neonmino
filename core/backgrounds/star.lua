-- core/backgrounds/star.lua
local star = {}

local stars = {}
local starCount = 200

function star.load()
    stars = {}
    for i = 1, starCount do
        stars[i] = {
            x = math.random(0, WIN_W),
            y = math.random(0, WIN_H),
            size = math.random(1, 3),
            speed = math.random(10, 50) / 100,
        }
    end
end

function star.update(dt)
    for _, s in ipairs(stars) do
        s.y = s.y + s.speed * dt * 30
        if s.y > WIN_H then
            s.y = 0
            s.x = math.random(0, WIN_W)
        end
    end
end

function star.draw()
    love.graphics.setColor(1, 1, 1, 1)
    for _, s in ipairs(stars) do
        love.graphics.circle("fill", s.x, s.y, s.size)
    end
end

function star.unload()
    stars = {}
end

return star