-- scenes/settings/controls.lua
local ControlsScene = {}

local Settings = require("core.settings")
local SFX = require("core.sfx")

local currentSettings = nil
local selected = 1
local editing = false
local editingKey = nil

local keyItems = {
    { name = "左移", key = "left" },
    { name = "右移", key = "right" },
    { name = "软降", key = "softDrop" },
    { name = "顺时针", key = "rotateCW" },
    { name = "逆时针", key = "rotateCCW" },
    { name = "180°旋转", key = "rotate180" },
    { name = "硬降", key = "hardDrop" },
    { name = "暂存", key = "hold" },
    { name = "重新开始", key = "restart" },
}

local startX = 500
local startY = 40
local lineHeight = 45

function ControlsScene.load()
    currentSettings = Settings.load()
    selected = 1
    editing = false
    editingKey = nil
end

function ControlsScene.update(dt)
end

function ControlsScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(keyItems) do
        local x = startX
        
        -- 去掉黄色的 > 指示器
        
        local keyStr = currentSettings.keys[item.key] or "无"
        -- 转换为大写
        if keyStr ~= "无" then
            keyStr = string.upper(keyStr)
        end
        
        if editing and editingKey == item.key then
            love.graphics.setColor(1, 0.8, 0.4, 1)
            love.graphics.print(item.name .. ": [按任意键]", x, y)
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(item.name .. ": " .. keyStr, x, y)
        end
        
        y = y + lineHeight
    end
end

function ControlsScene.keypressed(key)
    if editing then
        if key == "escape" then
            editing = false
            editingKey = nil
            SFX.play("back")
        else
            currentSettings.keys[editingKey] = key
            editing = false
            editingKey = nil
            Settings.save(currentSettings)
            SFX.play("confirm")
        end
        return
    end
    
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #keyItems end
        SFX.play("select")
    elseif key == "down" then
        selected = selected + 1
        if selected > #keyItems then selected = 1 end
        SFX.play("select")
    elseif key == "return" or key == "space" then
        editing = true
        editingKey = keyItems[selected].key
        SFX.play("select")
    end
end

function ControlsScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local yPos = startY
    for i, item in ipairs(keyItems) do
        if y >= yPos and y <= yPos + lineHeight then
            selected = i
            editing = true
            editingKey = item.key
            SFX.play("select")
            return
        end
        yPos = yPos + lineHeight
    end
end

function ControlsScene.mousemoved(x, y, dx, dy) end
function ControlsScene.mousereleased(x, y, button) end

return ControlsScene