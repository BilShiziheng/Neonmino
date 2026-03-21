-- scenes/menu.lua
local MenuScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Button = require("core.button")

local btnStart, btnSettings, btnExit

function MenuScene.load()
    Button.clear()
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local centerX = width / 2
    local startY = height / 2 - 80
    local btnWidth = 250
    local btnHeight = 60
    local spacing = 30
    
    btnStart = Button.create(centerX - btnWidth/2, startY, btnWidth, btnHeight, "开始游戏", function()
        SFX.play("confirm")
        Scene.switch("select")
    end)
    
    btnSettings = Button.create(centerX - btnWidth/2, startY + btnHeight + spacing, btnWidth, btnHeight, "设置", function()
        SFX.play("select")
        local SettingsScene = require("scenes.settings")
        SettingsScene.setReturnScene("menu")
        Scene.switch("settings")
    end)
    
    btnExit = Button.create(centerX - btnWidth/2, startY + (btnHeight + spacing) * 2, btnWidth, btnHeight, "退出游戏", function()
        SFX.play("back")
        love.event.quit()
    end)
end

function MenuScene.update(dt)
    Button.update()
end

function MenuScene.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- 标题
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.printf("Neonmino", 0, 120, width, "center")
    
    -- 绘制按钮
    Button.drawAll()
end

function MenuScene.keypressed(key)
    if key == "up" then
        -- 键盘导航（可选）
    elseif key == "down" then
        -- 键盘导航（可选）
    elseif key == "return" or key == "space" then
        -- 回车执行第一个按钮（可选）
    elseif key == "escape" then
        love.event.quit()
    end
end

function MenuScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    Button.checkPress(x, y, button)
end

function MenuScene.mousereleased(x, y, button)
    if button ~= 1 then return end
    Button.checkRelease(x, y, button)
end

return MenuScene