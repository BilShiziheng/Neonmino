-- core/ticker.lua
local ticker = {}

-- 字幕列表
local messages = {
    "欢迎来到**n块**！！11",
    "redTips:greenTIPs:yellowTips:",
    "red==GOT== DAMMITED **OSK**",
    "garbo大手子blue发力了",
    "这个Tips条的灵感其实是来自于**Techmino**的（",
    "三⭐倍⭐**Ice⭐Cream**!!!",
    "All Perfect yellowPlus+white!!!!111",
    "==大字体！==",
}

-- 颜色映射
local colorMap = {
    red = {1, 0, 0},
    green = {0, 1, 0},
    blue = {0, 0, 1},
    yellow = {1, 1, 0},
    cyan = {0, 1, 1},
    orange = {1, 0.5, 0},
    purple = {0.7, 0.3, 1},
    pink = {1, 0.6, 0.8},
    lightblue = {0.6, 0.8, 1},
    lightgreen = {0.6, 1, 0.6},
    gold = {1, 0.85, 0},
    gray = {0.5, 0.5, 0.5},
    white = {1, 1, 1},
}

-- 统一使用 mediumFont
local baseFont = mediumFont

-- 简化的解析器
local function parseText(text)
    local segments = {}
    local i = 1
    local len = #text
    local currentScale = 1
    local currentColor = {1, 1, 1}
    local inBold = false
    local inBig = false
    
    while i <= len do
        -- 检查 ** 粗体
        if i <= len - 1 and text:sub(i, i+1) == "**" then
            inBold = not inBold
            i = i + 2
        -- 检查 == 放大
        elseif i <= len - 1 and text:sub(i, i+1) == "==" then
            inBig = not inBig
            currentScale = inBig and 1.3 or 1
            i = i + 2
        else
            -- 检查颜色名
            local matchedColor = nil
            for colorName, colorValue in pairs(colorMap) do
                local nameLen = #colorName
                if i + nameLen - 1 <= len and text:sub(i, i + nameLen - 1) == colorName then
                    matchedColor = colorValue
                    i = i + nameLen
                    currentColor = matchedColor
                    break
                end
            end
            
            if not matchedColor then
                -- 普通文字
                local start = i
                while i <= len do
                    if i <= len - 1 and (text:sub(i, i+1) == "**" or text:sub(i, i+1) == "==") then
                        break
                    end
                    local isColor = false
                    for colorName, _ in pairs(colorMap) do
                        if i + #colorName - 1 <= len and text:sub(i, i + #colorName - 1) == colorName then
                            isColor = true
                            break
                        end
                    end
                    if isColor then
                        break
                    end
                    i = i + 1
                end
                
                if i > start then
                    local segText = text:sub(start, i - 1)
                    if segText ~= "" then
                        table.insert(segments, {
                            text = segText,
                            scale = currentScale,
                            color = currentColor,
                            bold = inBold
                        })
                    end
                end
            end
        end
    end
    
    return segments
end

-- 获取单个段宽度
local function getSegmentWidth(seg)
    local w = baseFont:getWidth(seg.text)
    if seg.bold then
        w = w + 1  -- 粗体偏移增加宽度
    end
    return w * seg.scale
end

-- 获取总宽度
local function getRichTextWidth(segments)
    local width = 0
    for _, seg in ipairs(segments) do
        width = width + getSegmentWidth(seg)
    end
    return width
end

local scrollX = 0
local speed = 150
local containerWidth = 0
local containerX = 0
local currentSegments = nil
local textWidth = 0
local waitTimer = 0
local waitDuration = 1.5
local waiting = false

local function randomMessage()
    local index = math.random(1, #messages)
    return messages[index]
end

local function loadMessage()
    local rawText = randomMessage()
    currentSegments = parseText(rawText)
    textWidth = getRichTextWidth(currentSegments)
    scrollX = containerWidth
    waiting = false
    waitTimer = 0
end

function ticker.init(containerW, containerLeftX)
    containerWidth = containerW
    containerX = containerLeftX
    loadMessage()
end

function ticker.update(dt)
    if waiting then
        waitTimer = waitTimer + dt
        if waitTimer >= waitDuration then
            loadMessage()
        end
    else
        scrollX = scrollX - speed * dt
        if scrollX + textWidth < 0 then
            waiting = true
            waitTimer = 0
        end
    end
end

function ticker.getCurrentSegments()
    return currentSegments
end

function ticker.getScrollX()
    return scrollX
end

return ticker