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
local startY = 40
local lineHeight = 80
local sliderWidth = 300
local sliderHeight = 8
local handleSize = 16

local draggingItem = nil

function SoundScene.load()
    currentSettings = Settings.load()
    selected = 1
    draggingItem = nil
    
    local musicVol = (currentSettings.musicVolume or 80) / 100
    local sfxVol = (currentSettings.sfxVolume or 80) / 100
    Music.setVolume(musicVol)
    SFX.setVolume(sfxVol)
end

function SoundScene.update(dt)
end

function SoundScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(soundItems) do
        local val = currentSettings[item.key] or item.value
        local x = startX
        
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
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #soundItems end
        SFX.play("select")
    elseif key == "down" then
        selected = selected + 1
        if selected > #soundItems then selected = 1 end
        SFX.play("select")
    elseif key == "left" then
        local item = soundItems[selected]
        local newVal = (currentSettings[item.key] or item.value) - 5
        if newVal >= item.min then
            currentSettings[item.key] = newVal
            Settings.save(currentSettings)
            if item.key == "musicVolume" then
                Music.setVolume(newVal / 100)
            else
                SFX.setVolume(newVal / 100)
                SFX.play("move")
            end
        end
    elseif key == "right" then
        local item = soundItems[selected]
        local newVal = (currentSettings[item.key] or item.value) + 5
        if newVal <= item.max then
            currentSettings[item.key] = newVal
            Settings.save(currentSettings)
            if item.key == "musicVolume" then
                Music.setVolume(newVal / 100)
            else
                SFX.setVolume(newVal / 100)
                SFX.play("move")
            end
        end
    end
end

function SoundScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
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
            return
        end
        yPos = yPos + lineHeight
    end
end

function SoundScene.mousemoved(x, y, dx, dy)
    if draggingItem then
        local item = soundItems[draggingItem]
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
    end
end

function SoundScene.mousereleased(x, y, button)
    if button == 1 then
        draggingItem = nil
    end
end

return SoundScene