-- scenes/settings/handing.lua
local HandingScene = {}

local Settings = require("core.settings")
local SFX = require("core.sfx")

local currentSettings = nil
local selected = 1

local handingItems = {
    { name = "DAS (F)", key = "das", min = 0, max = 30, value = 10 },
    { name = "ARR (F)", key = "arr", min = 0, max = 20, value = 2 },
    { name = "SDF (F)", key = "sdf", min = 0, max = 30, value = 10 },
}

local startX = 400
local startY = 40
local lineHeight = 60
local sliderWidth = 300
local sliderHeight = 6
local handleSize = 12


local draggingItem = nil

function HandingScene.load()
    currentSettings = Settings.load()
    selected = 1
    draggingItem = nil
end

function HandingScene.update(dt)
end

function HandingScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(handingItems) do
        local val = currentSettings[item.key] or item.value
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.name .. ": " .. val, startX, y)
        
        local sliderX = startX + 250
        local sliderY = y + (mediumFont:getHeight() - sliderHeight) / 2
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
        love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, sliderHeight, 3)
        
        local t = (val - item.min) / (item.max - item.min)
        local handleX = sliderX + t * sliderWidth
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("fill", handleX, sliderY + sliderHeight/2, handleSize)
        
        y = y + lineHeight
    end
end

function HandingScene.keypressed(key)
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #handingItems end
        SFX.play("select")
    elseif key == "down" then
        selected = selected + 1
        if selected > #handingItems then selected = 1 end
        SFX.play("select")
    elseif key == "left" then
        local item = handingItems[selected]
        local newVal = (currentSettings[item.key] or item.value) - 1
        if newVal >= item.min then
            currentSettings[item.key] = newVal
            Settings.save(currentSettings)
            SFX.play("move")
        end
    elseif key == "right" then
        local item = handingItems[selected]
        local newVal = (currentSettings[item.key] or item.value) + 1
        if newVal <= item.max then
            currentSettings[item.key] = newVal
            Settings.save(currentSettings)
            SFX.play("move")
        end
    end
end

function HandingScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local yPos = startY
    for i, item in ipairs(handingItems) do
        if y >= yPos and y <= yPos + lineHeight then
            selected = i
            local sliderX = startX + 250
            local t = (x - sliderX) / sliderWidth
            t = math.max(0, math.min(1, t))
            local newVal = math.floor(item.min + t * (item.max - item.min))
            currentSettings[item.key] = newVal
            Settings.save(currentSettings)
            draggingItem = i
            SFX.play("select")
            return
        end
        yPos = yPos + lineHeight
    end
end

function HandingScene.mousemoved(x, y, dx, dy)
    if draggingItem then
        local item = handingItems[draggingItem]
        local sliderX = startX + 250
        local t = (x - sliderX) / sliderWidth
        t = math.max(0, math.min(1, t))
        local newVal = math.floor(item.min + t * (item.max - item.min))
        currentSettings[item.key] = newVal
        Settings.save(currentSettings)
    end
end

function HandingScene.mousereleased(x, y, button)
    if button == 1 then
        draggingItem = nil
    end
end

return HandingScene