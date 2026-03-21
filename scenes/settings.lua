-- scenes/settings.lua
local SettingsScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")
local Button = require("core.button")

local returnScene = nil
local currentPanel = 1

local panels = {
    { name = "键位设置" },
    { name = "控制设置" },
    { name = "声音设置" },
    { name = "画面设置" },
}

local controlsScene = require("scenes.settings.controls")
local handingScene = require("scenes.settings.handing")
local soundScene = require("scenes.settings.sound")
local videoScene = require("scenes.settings.video")

local currentSettings = nil
local btnLeft, btnRight, btnBack

function SettingsScene.setReturnScene(scene)
    returnScene = scene
end

function SettingsScene.load()
    currentSettings = Settings.load()
    currentPanel = 1
    
    if not returnScene then
        returnScene = "menu"
    end
    
    controlsScene.load()
    handingScene.load()
    soundScene.load()
    videoScene.load()
    
    Button.clear()
    
    btnLeft = Button.create(0, 150, 150, 50, "", function()
        SFX.play("select")
        currentPanel = currentPanel - 1
        if currentPanel < 1 then currentPanel = #panels end
    end)
    
    btnRight = Button.create(0, 150, 150, 50, "", function()
        SFX.play("select")
        currentPanel = currentPanel + 1
        if currentPanel > #panels then currentPanel = 1 end
    end)
    
    btnBack = Button.create(0, 0, 180, 45, "返回", function()
        SFX.play("back")
        local backScene = returnScene or "menu"
        Scene.switch(backScene)
        returnScene = nil
    end)
end

function SettingsScene.update(dt)
    local mx, my = love.mouse.getX(), love.mouse.getY()
    Button.update(mx, my)
    
    if currentPanel == 1 then
        controlsScene.update(dt)
    elseif currentPanel == 2 then
        handingScene.update(dt)
    elseif currentPanel == 3 then
        soundScene.update(dt)
    elseif currentPanel == 4 then
        videoScene.update(dt)
    end
end

function SettingsScene.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.printf("设置", 0, 60, width, "center")
    
    local leftX = width / 2 - 300
    local rightX = width / 2 + 150
    local backX = (width - 180) / 2
    local backY = height - 70
    
    Button.setPos(btnLeft, leftX, 150)
    Button.setPos(btnRight, rightX, 150)
    Button.setPos(btnBack, backX, backY)
    
    local leftPanel = currentPanel - 1
    if leftPanel < 1 then leftPanel = #panels end
    local rightPanel = currentPanel + 1
    if rightPanel > #panels then rightPanel = 1 end
    
    Button.setText(btnLeft, "< " .. panels[leftPanel].name)
    Button.setText(btnRight, panels[rightPanel].name .. " >")
    
    Button.drawAll()
    
    love.graphics.setFont(largeFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(panels[currentPanel].name, 0, 158, width, "center")
    
    love.graphics.push()
    love.graphics.translate(0, 220)
    if currentPanel == 1 then
        controlsScene.draw()
    elseif currentPanel == 2 then
        handingScene.draw()
    elseif currentPanel == 3 then
        soundScene.draw()
    elseif currentPanel == 4 then
        videoScene.draw()
    end
    love.graphics.pop()
end

function SettingsScene.keypressed(key)
    if key == "left" then
        Button.get(btnLeft).action()
    elseif key == "right" then
        Button.get(btnRight).action()
    elseif key == "escape" then
        Button.get(btnBack).action()
    end
    
    if currentPanel == 1 then
        controlsScene.keypressed(key)
    elseif currentPanel == 2 then
        handingScene.keypressed(key)
    elseif currentPanel == 3 then
        soundScene.keypressed(key)
    elseif currentPanel == 4 then
        videoScene.keypressed(key)
    end
end

function SettingsScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    if Button.checkPress(x, y, button) then
        return
    end
    
    local adjustedY = y - 220
    if adjustedY >= 0 then
        if currentPanel == 1 then
            controlsScene.mousepressed(x, adjustedY, button)
        elseif currentPanel == 2 then
            handingScene.mousepressed(x, adjustedY, button)
        elseif currentPanel == 3 then
            soundScene.mousepressed(x, adjustedY, button)
        elseif currentPanel == 4 then
            videoScene.mousepressed(x, adjustedY, button)
        end
    end
end

function SettingsScene.mousereleased(x, y, button)
    if button ~= 1 then return end
    
    if Button.checkRelease(x, y, button) then
        return
    end
    
    local adjustedY = y - 220
    if adjustedY >= 0 then
        if currentPanel == 1 then
            controlsScene.mousereleased(x, adjustedY, button)
        elseif currentPanel == 2 then
            handingScene.mousereleased(x, adjustedY, button)
        elseif currentPanel == 3 then
            soundScene.mousereleased(x, adjustedY, button)
        elseif currentPanel == 4 then
            videoScene.mousereleased(x, adjustedY, button)
        end
    end
end

function SettingsScene.mousemoved(x, y, dx, dy)
    local adjustedY = y - 220
    if adjustedY >= 0 then
        if currentPanel == 1 then
            controlsScene.mousemoved(x, adjustedY, dx, dy)
        elseif currentPanel == 2 then
            handingScene.mousemoved(x, adjustedY, dx, dy)
        elseif currentPanel == 3 then
            soundScene.mousemoved(x, adjustedY, dx, dy)
        elseif currentPanel == 4 then
            videoScene.mousemoved(x, adjustedY, dx, dy)
        end
    end
end

return SettingsScene