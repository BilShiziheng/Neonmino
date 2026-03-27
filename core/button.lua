-- core/button.lua
local button = {}

local buttons = {}      -- 所有按钮的集合
local nextId = 1        -- 下一个按钮ID
local hoverId = nil     -- 当前悬停的按钮ID
local pressId = nil     -- 当前按下的按钮ID

-- 创建按钮
function button.create(x, y, w, h, text, action)
    local id = nextId
    nextId = nextId + 1
    buttons[id] = {
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        action = action,
        enabled = true,
        onHover = nil,
        onLeave = nil,
        onPress = nil,
        onRelease = nil,
    }
    return id
end

-- 更新按钮位置
function button.setPos(id, x, y)
    if buttons[id] then
        buttons[id].x = x
        buttons[id].y = y
    end
end

-- 更新按钮文字
function button.setText(id, text)
    if buttons[id] then
        buttons[id].text = text
    end
end

-- 获取按钮
function button.get(id)
    return buttons[id]
end

-- 启用/禁用按钮
function button.setEnabled(id, enabled)
    if buttons[id] then
        buttons[id].enabled = enabled
    end
end

-- 设置按钮回调
function button.setOnHover(id, callback)
    if buttons[id] then
        buttons[id].onHover = callback
    end
end

function button.setOnLeave(id, callback)
    if buttons[id] then
        buttons[id].onLeave = callback
    end
end

function button.setOnPress(id, callback)
    if buttons[id] then
        buttons[id].onPress = callback
    end
end

function button.setOnRelease(id, callback)
    if buttons[id] then
        buttons[id].onRelease = callback
    end
end

-- 更新悬停状态（每帧调用）
function button.update()
    local mx, my = getMousePosition()
    local newHoverId = nil
    
    for _, btn in pairs(buttons) do
        if btn.enabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            newHoverId = btn.id
            break
        end
    end
    
    if newHoverId ~= hoverId then
        -- 离开旧按钮
        if hoverId and buttons[hoverId] and buttons[hoverId].onLeave then
            buttons[hoverId].onLeave()
        end
        -- 进入新按钮
        if newHoverId and buttons[newHoverId] and buttons[newHoverId].onHover then
            buttons[newHoverId].onHover()
        end
        hoverId = newHoverId
    end
end

-- 绘制所有按钮
function button.drawAll()
    for _, btn in pairs(buttons) do
        if btn.enabled then
            -- 根据状态设置颜色
            local r, g, b
            if pressId == btn.id then
                -- 按下状态
                r, g, b = 0.4, 0.4, 0.6
            elseif hoverId == btn.id then
                -- 悬停状态
                r, g, b = 0.6, 0.6, 0.8
            else
                -- 正常状态
                r, g, b = 0.5, 0.5, 0.7
            end
            love.graphics.setColor(r, g, b, 0.9)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10)
            
            -- 悬停时添加白色描边
            if hoverId == btn.id then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10)
            end
            
            -- 按钮文字
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(mediumFont)
            love.graphics.printf(btn.text, btn.x, btn.y + (btn.h - mediumFont:getHeight()) / 2, btn.w, "center")
        end
    end
end

-- 检测按下（在 mousepressed 中调用）
function button.checkPress(x, y, mouseButton)
    if mouseButton ~= 1 then return false end
    
    for _, btn in pairs(buttons) do
        if btn.enabled and x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            pressId = btn.id
            if btn.onPress then
                btn.onPress()
            end
            return true
        end
    end
    return false
end

-- 检测释放（在 mousereleased 中调用）
function button.checkRelease(x, y, mouseButton)
    if mouseButton ~= 1 then return false end
    
    if pressId then
        local btn = buttons[pressId]
        if btn and btn.enabled then
            -- 检查释放时是否还在按钮内
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                if btn.action then
                    btn.action()
                end
                if btn.onRelease then
                    btn.onRelease()
                end
            end
        end
        pressId = nil
        return true
    end
    return false
end

-- 清空所有按钮
function button.clear()
    buttons = {}
    nextId = 1
    hoverId = nil
    pressId = nil
end

-- 删除按钮
function button.remove(id)
    buttons[id] = nil
    if hoverId == id then hoverId = nil end
    if pressId == id then pressId = nil end
end

-- 获取所有按钮（用于调试）
function button.getAll()
    return buttons
end

return button