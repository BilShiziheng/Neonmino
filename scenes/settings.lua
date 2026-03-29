-- scenes/settings.lua
local SettingsScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")
local Button = require("core.button")
local Background = require("core.background")

local returnScene = nil
local currentPanel = 1

local controlsScene = require("scenes.settings.controls")
local handlingScene = require("scenes.settings.handling")
local miscScene = require("scenes.settings.misc")
local soundScene = require("scenes.settings.sound")
local videoScene = require("scenes.settings.video")

local panels = {
    { name = "键位设置", scene = controlsScene },
    { name = "手感设置", scene = handlingScene },
    { name = "杂项", scene = miscScene },
    { name = "声音设置", scene = soundScene },
    { name = "画面设置", scene = videoScene },
}

local function getInnerScene()
	return panels[currentPanel].scene
end

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
    
    for _, panel in ipairs(panels) do
		panel.scene.load()
	end
    
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
    local mx, my = getMousePosition()
    Button.update(mx, my)
	getInnerScene().update(dt)
end

function SettingsScene.draw()
    Background.draw()
    
    local width = WIN_W
    local height = WIN_H
    
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
	getInnerScene().draw()
    love.graphics.pop()
end

function SettingsScene.keypressed(key)
	if getInnerScene().keypressed(key) then
		return true
	elseif key == "left" then
        Button.get(btnLeft).action()
		return true
    elseif key == "right" then
        Button.get(btnRight).action()
		return true
    elseif key == "escape" then
        Button.get(btnBack).action()
		return true
    end
	return false
end

function SettingsScene.mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    if Button.checkPress(x, y, button) then
        return true
    end
    
    local adjustedY = y - 220
    if adjustedY >= 0 then
		return getInnerScene().mousepressed(x, adjustedY, button)
    end
	return false
end

function SettingsScene.mousereleased(x, y, button)
    if button ~= 1 then return false end
    
    if Button.checkRelease(x, y, button) then
        return true
    end
    
    local adjustedY = y - 220
    if adjustedY >= 0 then
		return getInnerScene().mousereleased(x, adjustedY, button)
    end
	return false
end

function SettingsScene.mousemoved(x, y, dx, dy)
    local adjustedY = y - 220
    if adjustedY >= 0 then
		return getInnerScene().mousemoved(x, adjustedY, dx, dy)
    end
	return false
end

return SettingsScene