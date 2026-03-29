-- scenes/settings/handling.lua
local HandlingScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")

local currentSettings = nil
local selected = 1

-- 手感参数列表
local handlingItems = {
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

function HandlingScene.load()
    currentSettings = Settings.load()
    selected = 0
	--	0 表示不在任何一项
    draggingItem = nil
end

function HandlingScene.update(dt)
end

function HandlingScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(handlingItems) do
        local val = currentSettings[item.key] or item.value
        local x = startX
		
        if i == selected then
            love.graphics.setColor(1, 1, 0.6, 1)
            love.graphics.print(">", x - 30, y)
        end
        
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

function HandlingScene.keypressed(key)
    if key == "up" or key == "down" then
		local dir = key == "up" and -1 or 1
        selected = selected + dir
        if selected < 0 then selected = #handlingItems end
        if selected > #handlingItems then selected = 0 end
        SFX.play("select")
		return true
    elseif selected ~= 0 and (key == "left" or key == "right") then
        local item = handlingItems[selected]
		local dir = (not not item.inverse) ~= (key == "left") and -1 or 1
        local val = currentSettings[item.key] or item.value
        local newVal = roundToOne(val + item.step * dir)
		local toVal = math.max(item.min, math.min(item.max, newVal))
		if currentSettings[item.key] ~= toVal then
        	SFX.play("move")
		end
        currentSettings[item.key] = toVal
        Settings.save()
		return true
    end
	return false
end

function HandlingScene.mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    local yPos = startY
    for i, item in ipairs(handlingItems) do
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
            draggingItem = i
            SFX.play("select")
            return true
        end
        yPos = yPos + lineHeight
    end
	return false
end

function HandlingScene.mousemoved(x, y, dx, dy)
    if draggingItem then
        local item = handlingItems[draggingItem]
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
        return true
    end
	return false
end

function HandlingScene.mousereleased(x, y, button)
    if button == 1 then
        Settings.save()
        draggingItem = nil
		return true
    end
	return false
end

return HandlingScene