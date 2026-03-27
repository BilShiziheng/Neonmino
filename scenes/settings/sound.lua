-- scenes/settings/sound.lua
local SoundScene = {}

local Settings = require("core.settings")
local SFX = require("core.sfx")
local Music = require("core.music")

local currentSettings = nil
local selected = 1

local soundItems = {
    { name = "音乐音量", key = "musicVolume", min = 0, max = 100, value = 80 },
    { name = "音效音量", key = "sfxVolume", min = 0, max = 100, value = 80 },
}

local startX = 500
local startY = 20
local lineHeight = 80
local sliderWidth = 300
local sliderHeight = 8
local handleSize = 16

local draggingItem = nil

function SoundScene.load()
    currentSettings = Settings.load()
    selected = 0
    draggingItem = nil
end

function SoundScene.update(dt)
end

function SoundScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(soundItems) do
        local val = currentSettings[item.key] or item.value
        local x = startX
        
        if i == selected then
            love.graphics.setColor(1, 1, 0.6, 1)
            love.graphics.print(">", x - 30, y)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.name .. ": " .. val .. "%", x, y)
        
        local sliderX = x + 200
        local sliderY = y + (mediumFont:getHeight() - sliderHeight) / 2
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
        love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, sliderHeight, 4)
        
        local t = val / 100
        local fillWidth = t * sliderWidth
        love.graphics.setColor(0.6, 0.8, 1, 1)
        love.graphics.rectangle("fill", sliderX, sliderY, fillWidth, sliderHeight, 4)
        
        local handleX = sliderX + t * sliderWidth
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", handleX, sliderY + sliderHeight/2, handleSize)
        
        y = y + lineHeight
    end
end

function SoundScene.keypressed(key)
    if key == "up" or key == "down" then
		local dir = key == "up" and -1 or 1
        selected = selected + dir
        if selected < 0 then selected = #soundItems end
        if selected > #soundItems then selected = 0 end
        SFX.play("select")
		return true
    elseif selected ~= 0 and (key == "left" or key == "right") then
        local item = soundItems[selected]
		local dir = key == "left" and -1 or 1
        local newVal = (currentSettings[item.key] or item.value) + 5 * dir
		local toVal = math.max(item.min, math.min(item.max, newVal))
		if currentSettings[item.key] ~= toVal then
            SFX.play("move")
        end
        currentSettings[item.key] = toVal
		if item.key == "musicVolume" then
			Music.setVolume(newVal / 100)
		else
			SFX.setVolume(newVal / 100)
		end
        Settings.save(currentSettings)
		return true
    end
	return false
end

function SoundScene.mousepressed(x, y, button)
    if button ~= 1 then return true end
    
    local yPos = startY
    for i, item in ipairs(soundItems) do
        if y >= yPos and y <= yPos + lineHeight then
            selected = i
            local sliderX = startX + 200
            local t = (x - sliderX) / sliderWidth
            t = math.max(0, math.min(1, t))
            local newVal = math.floor(t * 100)
            currentSettings[item.key] = newVal
            Settings.save(currentSettings)
            if item.key == "musicVolume" then
                Music.setVolume(newVal / 100)
            else
                SFX.setVolume(newVal / 100)
            end
            draggingItem = i
            SFX.play("select")
            return true
        end
        yPos = yPos + lineHeight
    end

	return false
end

function SoundScene.mousemoved(x, y, dx, dy)
    if draggingItem then
        local item = soundItems[draggingItem]
        local sliderX = startX + 200
        local t = (x - sliderX) / sliderWidth
        t = math.max(0, math.min(1, t))
        local newVal = math.floor(t * 100)
        currentSettings[item.key] = newVal
        if item.key == "musicVolume" then
            Music.setVolume(newVal / 100)
        else
            SFX.setVolume(newVal / 100)
        end
		return true
    end
	return false
end

function SoundScene.mousereleased(x, y, button)
    if button == 1 then
        Settings.save(currentSettings)
        draggingItem = nil
		return true
    end
	return false
end

return SoundScene