-- scenes/menu.lua
local MenuScene = {}
local Scene = require("core.scene")

local buttons = {
    { label = "开始游戏", action = function() Scene.switch("select") end },
    { label = "设置", action = function() Scene.switch("settings") end },
    { label = "退出", action = function() love.event.quit() end },
}

local buttonWidth = 300
local buttonHeight = 60
local buttonSpacing = 20
local buttonYStart = 400

function MenuScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    for i, btn in ipairs(buttons) do
        local bx = (1600 - buttonWidth) / 2
        local by = buttonYStart + (i-1) * (buttonHeight + buttonSpacing)
        if x >= bx and x <= bx + buttonWidth and y >= by and y <= by + buttonHeight then
            btn.action()
            return
        end
    end
end

function MenuScene.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(largeFont)
    love.graphics.printf("Neonmino", 0, 150, 1600, "center")

    love.graphics.setFont(mediumFont)
    for i, btn in ipairs(buttons) do
        local bx = (1600 - buttonWidth) / 2
        local by = buttonYStart + (i-1) * (buttonHeight + buttonSpacing)
        love.graphics.setColor(0.3,0.3,0.4)
        love.graphics.rectangle("fill", bx, by, buttonWidth, buttonHeight, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(btn.label, bx, by + (buttonHeight - mediumFont:getHeight())/2, buttonWidth, "center")
    end
end

function MenuScene.keypressed(key)
    if key == "escape" then love.event.quit() end
end

function MenuScene.update(dt) end

return MenuScene