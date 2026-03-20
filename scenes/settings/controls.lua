-- scenes/controls.lua
local SettingsScene = {}
local Scene = require("core.scene")
local Settings = require("core.settings")

local currentSettings = nil

-- 滑块相关变量
local draggingItem = nil          -- 当前正在拖动的数值项索引
local sliderWidth = 200           -- 滑块宽度
local sliderHeight = 20            -- 滑块高度

local settingItems = {
    { type = "header", label = "键位设置" },
    { type = "key", name = "左移", key = "left" },
    { type = "key", name = "右移", key = "right" },
    { type = "key", name = "软降", key = "softDrop" },
    { type = "key", name = "顺时针", key = "rotateCW" },
    { type = "key", name = "逆时针", key = "rotateCCW" },
    { type = "key", name = "180°旋转", key = "rotate180" },
    { type = "key", name = "硬降", key = "hardDrop" },
    { type = "key", name = "暂存", key = "hold" },
    { type = "key", name = "重新开始", key = "restart" },
    { type = "header", label = "DAS/ARR(F为单位)" },
    { type = "number", name = "DAS", key = "das", min = 0, max = 30, isSlider = true },
    { type = "number", name = "ARR", key = "arr", min = 0, max = 20, isSlider = true },
    { type = "action", label = "保存并返回", action = "save" },
    { type = "action", label = "取消", action = "cancel" },
}

local selected = 1
local editing = false
local editingKey = nil

-- 计算绘制位置
local startX = 500
local startY = 150
local lineHeight = 35

function SettingsScene.load()
    currentSettings = Settings.load()
    selected = 1
    editing = false
    editingKey = nil
    draggingItem = nil
end

function SettingsScene.update(dt)
    -- 无需更新
end

function SettingsScene.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(largeFont)
    love.graphics.printf("设置", 0, 50, 1600, "center")
    love.graphics.setFont(mediumFont)

    local y = startY
    for i, item in ipairs(settingItems) do
        local x = startX
        -- 绘制选择指示器（键盘选择）
        if i == selected and not editing then
            love.graphics.setColor(1,1,0.6)
            love.graphics.print(">", x - 30, y)
        else
            love.graphics.setColor(0.8,0.8,0.8)
        end

        if item.type == "header" then
            love.graphics.setColor(1,1,1)
            love.graphics.print(item.label, x, y)
        elseif item.type == "key" then
            local keyStr = currentSettings.keys[item.key] or "无"
            if editing and editingKey == item.key then
                -- 正在等待输入，显示提示
                love.graphics.setColor(1,1,0.6)
                love.graphics.print(item.name .. ": [按任意键]", x, y)
            else
                love.graphics.setColor(1,1,1)
                love.graphics.print(item.name .. ": " .. keyStr, x, y)
            end
        elseif item.type == "number" then
            local val = currentSettings[item.key] or 0
            if item.isSlider then
                -- 绘制数值文本
                love.graphics.setColor(1,1,1)
                love.graphics.print(item.name .. ": " .. val, x, y)
                -- 绘制滑块背景
                local sliderX = x + 250
                local sliderY = y + (mediumFont:getHeight() - sliderHeight) / 2
                love.graphics.setColor(0.3,0.3,0.4)
                love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, sliderHeight, 5)
                -- 绘制滑块手柄
                local t = (val - item.min) / (item.max - item.min)
                local handleX = sliderX + t * sliderWidth
                love.graphics.setColor(1,1,1)
                love.graphics.circle("fill", handleX, sliderY + sliderHeight/2, 10)
            else
                love.graphics.setColor(1,1,1)
                love.graphics.print(item.name .. ": " .. val, x, y)
            end
        elseif item.type == "action" then
            love.graphics.setColor(1,1,1)
            love.graphics.print(item.label, x, y)
        end
        y = y + lineHeight
    end

    -- 提示文字
    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.setFont(smallFont)
    love.graphics.print("ESC 返回主菜单", 10, 850)
    if editing then
        love.graphics.print("正在设置按键，按 ESC 取消", 10, 820)
    end
end

function SettingsScene.keypressed(key)
    -- 如果正在编辑键位
    if editing then
        if key == "escape" then
            -- 取消编辑
            editing = false
            editingKey = nil
        else
            -- 绑定新键
            currentSettings.keys[editingKey] = key
            editing = false
            editingKey = nil
            -- 立即保存
            Settings.save(currentSettings)
        end
        return
    end

    if key == "escape" then
        Scene.switch("menu")
        return
    end

    -- 键盘导航
    if key == "up" then
        selected = selected - 1
        while selected >= 1 and settingItems[selected].type == "header" do
            selected = selected - 1
        end
        if selected < 1 then selected = #settingItems end
    elseif key == "down" then
        selected = selected + 1
        while selected <= #settingItems and settingItems[selected].type == "header" do
            selected = selected + 1
        end
        if selected > #settingItems then selected = 1 end
    elseif key == "return" then
        local item = settingItems[selected]
        if item.type == "key" then
            -- 使用键盘进入编辑模式
            editing = true
            editingKey = item.key
        elseif item.type == "action" then
            if item.action == "save" then
                Settings.save(currentSettings)
                Scene.switch("menu")
            elseif item.action == "cancel" then
                Scene.switch("menu")
            end
        end
    elseif key == "left" then
        local item = settingItems[selected]
        if item.type == "number" and not item.isSlider then
            local newVal = currentSettings[item.key] - 1
            if newVal >= item.min then
                currentSettings[item.key] = newVal
            end
        end
    elseif key == "right" then
        local item = settingItems[selected]
        if item.type == "number" and not item.isSlider then
            local newVal = currentSettings[item.key] + 1
            if newVal <= item.max then
                currentSettings[item.key] = newVal
            end
        end
    end
end

function SettingsScene.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- 先检测是否点击在滑块上（优先级高）
    local yPos = startY
    for i, item in ipairs(settingItems) do
        if item.type == "number" and item.isSlider then
            local sliderX = startX + 250
            local sliderY = yPos + (mediumFont:getHeight() - sliderHeight) / 2
            if x >= sliderX and x <= sliderX + sliderWidth and y >= sliderY and y <= sliderY + sliderHeight then
                -- 开始拖动
                draggingItem = i
                -- 取消编辑状态
                editing = false
                editingKey = nil
                -- 根据点击位置计算数值
                local t = (x - sliderX) / sliderWidth
                t = math.max(0, math.min(1, t))
                local newVal = math.floor(item.min + t * (item.max - item.min))
                currentSettings[item.key] = newVal
                return
            end
        end
        yPos = yPos + lineHeight
    end

    -- 没有点击滑块，则检测是否点击在键位项上
    yPos = startY
    for i, item in ipairs(settingItems) do
        local xPos = startX
        local height = lineHeight
        if y >= yPos and y <= yPos + height then
            if item.type == "key" then
                -- 点击键位项，进入编辑模式
                editing = true
                editingKey = item.key
                selected = i  -- 同步键盘选择
                return
            elseif item.type == "action" then
                -- 点击动作按钮
                if item.action == "save" then
                    Settings.save(currentSettings)
                    Scene.switch("menu")
                elseif item.action == "cancel" then
                    Scene.switch("menu")
                end
                return
            elseif item.type == "header" then
                -- 点击标题，忽略
                return
            else
                -- 点击数值项，可以取消编辑并选中该项
                editing = false
                editingKey = nil
                selected = i
                return
            end
        end
        yPos = yPos + lineHeight
    end

    -- 点击空白区域，取消编辑
    editing = false
    editingKey = nil
end

function SettingsScene.mousemoved(x, y, dx, dy)
    if draggingItem then
        local item = settingItems[draggingItem]
        if item and item.type == "number" and item.isSlider then
            local sliderX = startX + 250
            local t = (x - sliderX) / sliderWidth
            t = math.max(0, math.min(1, t))
            local newVal = math.floor(item.min + t * (item.max - item.min))
            currentSettings[item.key] = newVal
        end
    end
end

function SettingsScene.mousereleased(x, y, button)
    if button == 1 then
        draggingItem = nil
    end
end

return SettingsScene
