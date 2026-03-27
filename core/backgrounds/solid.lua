-- core/backgrounds/solid.lua
local solid = {}

local color = {0.1, 0.1, 0.15}

function solid.load()
    -- 可选：从设置读取颜色
end

function solid.update(dt)
end

function solid.draw()
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", 0, 0, WIN_W, WIN_H)
end

function solid.unload()
end

return solid