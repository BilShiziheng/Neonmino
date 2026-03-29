-- core/ticker.lua
local ticker = {}

-- 字幕列表
local messages = {
    "欢迎来到**n块**！！11",
    "时间碎片[**01**]本项目于2026/3/13立项",
    "时间碎片[**02**]手感优化于Alpha0.6.0版本",
    "redTips:greenTIPs:yellowTips:",
    "redGOT DAMMITED **OSK**",
    "garbo大手子blue发力了",
    "这个Tips条其实是来自于**Techmino**的（",
    "三⭐倍⭐**Ice⭐Cream**!!!",
    "All Perfect yellowPlus+white!!!!111",
    "时间碎片[**03**]这个条加入于Alpha0.3.5版本",
    "不要问这个结算音乐是red何意味white，因为**purplevividwhite/cyanstasiswhite**好玩!!!",
    "不好，**捣蛋来袭**！",
    "让我看看块序是什么... orangeL redZ greenS purpleTwhite....等等，cyanI5?!",
    "您**md**了",
    "Last **redStand**",
    "旋转，消行，到顶就**撤**",
    "This is your red**Last Wish**",
    "眼睛瞎在**Neonmino**上，手也粘在**tetr.io**上，脑子用在**全隐**上，颈椎疼在**Techmino**上，后面忘了",
    "冷知识：由于作者在本块测试blue**SDPC**white定式的成功率较高，所以才有了purple**SDPC全清训练**",
}

-- 打乱数组顺序（Fisher-Yates 洗牌算法）
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- 颜色映射
-- 颜色映射（添加更多）
local colorMap = {
    -- 基础色
    red = {1, 0, 0},
    green = {0, 1, 0},
    blue = {0, 0, 1},
    yellow = {1, 1, 0},
    cyan = {0, 1, 1},
    magenta = {1, 0, 1},
    orange = {1, 0.5, 0},
    purple = {0.7, 0.3, 1},
    pink = {1, 0.6, 0.8},
    brown = {0.6, 0.3, 0},
    
    -- 亮色系
    lightred = {1, 0.5, 0.5},
    lightgreen = {0.6, 1, 0.6},
    lightblue = {0.6, 0.8, 1},
    lightyellow = {1, 1, 0.6},
    lightcyan = {0.6, 1, 1},
    lightpurple = {0.9, 0.6, 1},
    lightpink = {1, 0.8, 0.9},
    
    -- 深色系
    darkred = {0.6, 0, 0},
    darkgreen = {0, 0.6, 0},
    darkblue = {0, 0, 0.6},
    darkorange = {0.6, 0.3, 0},
    darkpurple = {0.4, 0.2, 0.6},
    
    -- 金属色
    gold = {1, 0.85, 0},
    silver = {0.75, 0.75, 0.75},
    bronze = {0.8, 0.5, 0.2},
    
    -- 其他
    gray = {0.5, 0.5, 0.5},
    white = {1, 1, 1},
    black = {0, 0, 0},
    teal = {0, 0.8, 0.8},
    lime = {0.6, 1, 0.2},
    coral = {1, 0.5, 0.4},
    lavender = {0.8, 0.6, 1},
    mint = {0.6, 1, 0.7},
    peach = {1, 0.7, 0.5},
    sky = {0.4, 0.7, 1},
}

-- 使用项目根目录的字体文件
local baseFont = love.graphics.newFont("font.ttf", 36)

-- 获取字体
function ticker.getFont()
    return baseFont
end

-- 获取字体高度
function ticker.getFontHeight()
    return baseFont:getHeight()
end

-- 解析器
local function parseText(text)
    local segments = {}
    local i = 1
    local len = #text
    local currentColor = {1, 1, 1}
    local inBold = false
    
    while i <= len do
        if i <= len - 1 and text:sub(i, i+1) == "**" then
            inBold = not inBold
            i = i + 2
        else
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
                local start = i
                while i <= len do
                    if i <= len - 1 and text:sub(i, i+1) == "**" then
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
        w = w + 1
    end
    return w
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
local shuffledMessages = {}  -- 打乱后的消息列表
local msgIndex = 1

-- 重新打乱消息列表
local function reshuffle()
    shuffledMessages = {}
    for _, msg in ipairs(messages) do
        table.insert(shuffledMessages, msg)
    end
    shuffle(shuffledMessages)
    msgIndex = 1
end

-- 获取下一条消息（按打乱后的顺序）
local function nextMessage()
    if msgIndex > #shuffledMessages then
        reshuffle()
    end
    local msg = shuffledMessages[msgIndex]
    msgIndex = msgIndex + 1
    return msg
end

local function loadMessage()
    local rawText = nextMessage()
    currentSegments = parseText(rawText)
    textWidth = getRichTextWidth(currentSegments)
    scrollX = containerWidth
    waiting = false
    waitTimer = 0
end

function ticker.init(containerW, containerLeftX)
    containerWidth = containerW
    containerX = containerLeftX
    reshuffle()  -- 初始打乱
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