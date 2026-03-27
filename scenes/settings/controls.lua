-- scenes/settings/controls.lua
local ControlsScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")

local currentSettings = nil
local editing = nil

-- 键位列表
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
local startY = 20
local lineHeight = 50

-- 获取按键显示文本（大写）
local function getKeyDisplay(keys, slot)
    local key
    if type(keys) == "table" then
        key = keys[slot]
	end

    if key and key ~= "" then
        return string.upper(key)
    end
    return "无"
end

-- 重置所有键位为默认
local function resetToDefault()
    local defaultSettings = Settings.getDefault()
    currentSettings.keys = {}
    for key, value in pairs(defaultSettings.keys) do
        currentSettings.keys[key] = value
    end
    Settings.save(currentSettings)
    SFX.play("confirm")
end

function ControlsScene.load()
    currentSettings = Settings.load()
    editing = nil
end

function ControlsScene.update(dt)
end

function ControlsScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(keyItems) do
        local x = startX
        local keys = currentSettings.keys[item.key]
        
        -- 键位名称
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.name, x, y)
        
        -- 槽位1
        local slot1X = x + 150
        local key1 = getKeyDisplay(keys, 1)
        
        if editing and editing.key == item.key and editing.slot == 1 then
            love.graphics.setColor(1, 0.8, 0.4, 1)
            love.graphics.print("[按任意键]", slot1X, y)
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(key1, slot1X, y)
        end
        
        -- 槽位2
        local slot2X = slot1X + 120
        local key2 = getKeyDisplay(keys, 2)
        
        if editing and editing.key == item.key and editing.slot == 2 then
            love.graphics.setColor(1, 0.8, 0.4, 1)
            love.graphics.print("[按任意键]", slot2X, y)
        else
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(key2, slot2X, y)
        end
        
        y = y + lineHeight
    end

--[[
    -- 按钮区域（三个按钮：重置、保存、返回）
    local width = WIN_W
    local height = WIN_H
    local btnY = height - 80
    local btnWidth = 150
    local btnHeight = 45
    local spacing = 20
    local totalWidth = btnWidth * 3 + spacing * 2
    local startBtnX = (width - totalWidth) / 2
    
    -- 重置按钮
    love.graphics.setColor(0.6, 0.5, 0.3, 0.8)
    love.graphics.rectangle("fill", startBtnX, btnY, btnWidth, btnHeight, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("重置", startBtnX, btnY + 12, btnWidth, "center")
    
    -- 保存按钮
    love.graphics.setColor(0.3, 0.6, 0.3, 0.8)
    love.graphics.rectangle("fill", startBtnX + btnWidth + spacing, btnY, btnWidth, btnHeight, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("保存", startBtnX + btnWidth + spacing, btnY + 12, btnWidth, "center")
    
    -- 返回按钮
    love.graphics.setColor(0.6, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", startBtnX + (btnWidth + spacing) * 2, btnY, btnWidth, btnHeight, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("返回", startBtnX + (btnWidth + spacing) * 2, btnY + 12, btnWidth, "center")
]]
end

function ControlsScene.keypressed(key)
    if editing then
        if key == "escape" then
            SFX.play("back")
        else
            local keys = currentSettings.keys[editing.key]
            keys[editing.slot] = key
            Settings.save(currentSettings)
            SFX.play("confirm")
        end
		editing = nil
        return true
    end
    return false
end

function ControlsScene.mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    local width = WIN_W
    local height = WIN_H
    
--[[
    -- 检测按钮点击
    local btnY = height - 80
    local btnWidth = 150
    local spacing = 20
    local totalWidth = btnWidth * 3 + spacing * 2
    local startBtnX = (width - totalWidth) / 2
    
    -- 重置按钮
    if x >= startBtnX and x <= startBtnX + btnWidth and y >= btnY and y <= btnY + 45 then
        resetToDefault()
        return true
    end
    
    -- 保存按钮
    if x >= startBtnX + btnWidth + spacing and x <= startBtnX + btnWidth + spacing + btnWidth and y >= btnY and y <= btnY + 45 then
        Settings.save(currentSettings)
        SFX.play("confirm")
        Scene.switch("settings")
        return true
    end
    
    -- 返回按钮
    if x >= startBtnX + (btnWidth + spacing) * 2 and x <= startBtnX + (btnWidth + spacing) * 2 + btnWidth and y >= btnY and y <= btnY + 45 then
        SFX.play("back")
        Scene.switch("settings")
        return true
    end
]]
    
    -- 检测点击键位槽位
    local yPos = startY
    for i, item in ipairs(keyItems) do
        if y >= yPos and y <= yPos + lineHeight then
            local keys = currentSettings.keys[item.key]
            local slot1X = startX + 150
            local slot2X = slot1X + 120
			local using = nil
            if x >= slot1X and x <= slot1X + 80 then
                using = {key = item.key, slot = 1}
            end
            if x >= slot2X and x <= slot2X + 80 then
                using = {key = item.key, slot = 2}
            end
			if using then
				if editing and editing.key == using.key and editing.slot == using.slot then
					local keys = currentSettings.keys[editing.key]
					keys[editing.slot] = ""
					Settings.save(currentSettings)
					SFX.play("select")
					editing = nil
				else
					editing = using
                	SFX.play("select")
				end
				return true
			end
            return false
        end
        yPos = yPos + lineHeight
    end
	return false
end

function ControlsScene.mousemoved(x, y, dx, dy) return false end
function ControlsScene.mousereleased(x, y, button) return false end

return ControlsScene