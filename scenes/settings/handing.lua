-- scenes/settings/handing.lua
local HandingScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")

local currentSettings = nil
local selected = 1

-- 手感参数列表
local handingItems = {
    { name = "DAS", key = "das", min = 0, max = 20, step = 0.1, value = 10, inverse = true, unit = "F" },
    { name = "ARR", key = "arr", min = 0, max = 5, step = 0.1, value = 2, inverse = true, unit = "F" },
    { name = "SDF", key = "sdf", min = 1, max = 41, step = 1, value = 10, unit = "X" },
}

local startX = 500
local startY = 20
local lineHeight = 60
local sliderWidth = 250
local sliderHeight = 6
local handleSize = 12

local draggingItem = nil

-- 保留小数点后1位
local function roundToOne(val)
    return math.floor(val * 10 + 0.5) / 10
end

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
        local x = startX
        
        
        love.graphics.setColor(1, 1, 1, 1)
        if item.key == "sdf" and val == 41 then
            love.graphics.print(item.name .. ": INF", x, y)
        else
            -- 显示数值和单位
            local displayText = item.name .. ": " .. val
            if item.unit and item.unit ~= "" then
                displayText = displayText .. item.unit
            end
            love.graphics.print(displayText, x, y)
        end
        
        local sliderX = x + 200
        local sliderY = y + (mediumFont:getHeight() - sliderHeight) / 2
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
        love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, sliderHeight, 3)
        
        -- 对于 inverse 项，滑块位置反转（值越小，滑块越靠右）
        local t
        if item.inverse then
            t = 1 - (val - item.min) / (item.max - item.min)
        else
            t = (val - item.min) / (item.max - item.min)
        end
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
        local val = currentSettings[item.key] or item.value
        local newVal
        if item.inverse then
            -- 向左是增大数值（更慢）
            newVal = roundToOne(val + item.step)
        else
            -- 向左是减小数值
            newVal = roundToOne(val - item.step)
        end
        newVal = math.max(item.min, math.min(item.max, newVal))
        currentSettings[item.key] = newVal
        Settings.save(currentSettings)
        SFX.play("move")
    elseif key == "right" then
        local item = handingItems[selected]
        local val = currentSettings[item.key] or item.value
        local newVal
        if item.inverse then
            -- 向右是减小数值（更快）
            newVal = roundToOne(val - item.step)
        else
            -- 向右是增大数值
            newVal = roundToOne(val + item.step)
        end
        newVal = math.max(item.min, math.min(item.max, newVal))
        currentSettings[item.key] = newVal
        Settings.save(currentSettings)
        SFX.play("move")
    elseif key == "escape" then
        Scene.switch("settings")
        SFX.play("back")
    end
end

function HandingScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local yPos = startY
    for i, item in ipairs(handingItems) do
        if y >= yPos and y <= yPos + lineHeight then
            selected = i
            local sliderX = startX + 200
            local t = (x - sliderX) / sliderWidth
            t = math.max(0, math.min(1, t))
            
            local newVal
            if item.inverse then
                -- 滑块位置反转：t=0 对应最大值，t=1 对应最小值
                newVal = item.max - t * (item.max - item.min)
            else
                newVal = item.min + t * (item.max - item.min)
            end
            
            if item.key == "sdf" then
                newVal = math.floor(newVal + 0.5)
            else
                newVal = roundToOne(newVal)
            end
            newVal = math.max(item.min, math.min(item.max, newVal))
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
        local sliderX = startX + 200
        local t = (x - sliderX) / sliderWidth
        t = math.max(0, math.min(1, t))
        
        local newVal
        if item.inverse then
            newVal = item.max - t * (item.max - item.min)
        else
            newVal = item.min + t * (item.max - item.min)
        end
        
        if item.key == "sdf" then
            newVal = math.floor(newVal + 0.5)
        else
            newVal = roundToOne(newVal)
        end
        newVal = math.max(item.min, math.min(item.max, newVal))
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