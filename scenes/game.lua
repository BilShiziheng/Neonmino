-- scenes/game.lua
local GameScene = {}
local score = 0
-- 引入必要的模块
local RS = require("core.RS_data")
local Bag = require("core.bag_data")
local SFX = require("core.sfx")
local Music = require("core.music")
local Settings = require("core.settings")
local Scene = require("core.scene")
local lightningFrames = {}
local lightningLoaded = false
do
    local success, img1 = pcall(love.graphics.newImage, "assets/images/spark1.png")
    local success2, img2 = pcall(love.graphics.newImage, "assets/images/spark2.png")
    local success3, img3 = pcall(love.graphics.newImage, "assets/images/spark3.png")
    if success and success2 and success3 then
        lightningFrames = {img1, img2, img3}
        lightningLoaded = true
    end
end
local lightningTimer = 0
local lightningAlpha = 0
local lightningFrame = 1
local lightningX, lightningY = 0, 0
-- ===== 常量定义 =====
local BOARD_WIDTH = 10
local BOARD_HEIGHT = 20
local BLOCK_SIZE = 36
local HOLD_WIDTH = 130
local NEXT_ROWS = 5
local PREVIEW_SIZE = 90
local WIN_W, WIN_H = 1600, 900

-- 布局
local BOARD_W = BOARD_WIDTH * BLOCK_SIZE
local BOARD_H = BOARD_HEIGHT * BLOCK_SIZE
local BOARD_X = (WIN_W - BOARD_W) / 2
local BOARD_Y = (WIN_H - BOARD_H) / 2
local HOLD_X = BOARD_X - HOLD_WIDTH - 30
local HOLD_Y = BOARD_Y
local NEXT_X = BOARD_X + BOARD_W + 30
local NEXT_Y = BOARD_Y

-- 暂停相关变量
local paused = false
local pauseButtons = {
    { label = "继续", action = function() paused = false end },
    { label = "重试", action = function() resetGame(); paused = false end },
    { label = "玩玩别的", action = function() Scene.switch("select") end },
}
local pauseButtonWidth = 300
local pauseButtonHeight = 60
local pauseButtonSpacing = 20

-- 完成界面相关变量
local completed = false
local completedButtons = {
    { label = "重试", action = function() resetGame(); completed = false end },
    { label = "玩玩别的", action = function() Scene.switch("select") end },
}

-- 倒计时相关变量
local countdown = false
local countdownTimer = 0
local countdownStep = 0

-- ===== 游戏变量 =====
local board = {}
local currentPiece, currentX, currentY, currentRot
local nextPieces = {}
local holdPiece = nil
local canHold = true
local gameOver = false
local lastMoveType = ""

local messageLine1 = ""
local messageLine2 = nil
local messageColor1 = {1,1,1}
local messageColor2 = {1,1,1}
local messageTimer = 0
local messageMaxTime = 1.5
local messageStartTime = 0

local fallTimer = 0
local fallInterval = 0.5

local lockTimer = 0
local lockDelay = 0.5
local isLockPending = false

local DAS_DELAY = 10 / 60
local DAS_INTERVAL = 2 / 60
local dasTimer = 0
local dasKey = nil
local dasMoved = false

local softDropPressed = false

local pieceColors = {
    I = {0, 1, 1}, O = {1, 1, 0}, T = {0.8, 0.2, 1},
    L = {1, 0.5, 0}, J = {0, 0, 1}, S = {0, 1, 0}, Z = {1, 0, 0}
}

local stars = {}
local shake = { timer = 0, duration = 0, maxX = 0, maxY = 0, maxRot = 0 }
local btbCount = 0
local surgeValue = 0
local isBtbActive = false
local lastWasSpecial = false

local lastMusicTrack = nil
local musicDisplayTime = 0
local musicDisplayDuration = 5
local fadeTime = 0.5

-- surge 相关
local surgeBgAngle = 0
local surgeBgImage = love.graphics.newImage("assets/images/surge_bg.png")  -- 确保图片存在
local surgeColors = {
    [1] = {0.5, 0.5, 0.3},   -- 灰色 (surge 1-4)
    [2] = {1, 0, 0},          -- 红色 (5-9)
    [3] = {1, 0.5, 0},        -- 橙色 (10-14)
    [4] = {1, 1, 0},          -- 黄色 (15-19)
    [5] = {0, 1, 0},          -- 绿色 (20-24)
    [6] = {0, 1, 1},          -- 青色 (25-29)
    [7] = {0, 0, 1},          -- 蓝色 (30-34)
    [8] = {0.8, 0.2, 1},      -- 紫色 (35-39)
    [9] = {1, 0, 1},          -- 粉红 (40-44)
    [10] = {1, 0.5, 1},       -- 浅粉 (45-49)
    [11] = {0.5, 1, 0.5},     -- 浅绿 (50-54)
    [12] = {0.5, 0.5, 1},     -- 浅蓝 (55-59)
    [13] = {1, 1, 0.5},       -- 淡黄 (60-64)
    [14] = {1, 0.8, 0.5},     -- 杏色 (65-69)
    [15] = {0.8, 0.8, 0.8},   -- 亮灰 (70-74)
    [16] = {0.2, 0.8, 0.2},   -- 深绿 (75-79)
    [17] = {0.2, 0.2, 0.8},   -- 深蓝 (80-84)
    [18] = {0.8, 0.2, 0.2},   -- 深红 (85-89)
    [19] = {0.8, 0.8, 0.2},   -- 橄榄 (90-94)
    [20] = {0.2, 0.8, 0.8},   -- 蓝绿 (95-99)
    [21] = {1, 1, 1},         -- 白色 (100+)
}
local surgeScale = 1.0
local lastSurgeValue = 0

-- 计时相关
local gameTimer = 0
local piecesPlaced = 0
local ppsTimer = 0
local pps = 0

-- 模式数据
local modeConfig = nil
local totalLines = 0
local modeName = ""

-- 目标系统相关
local goalFunction = nil          -- 目标检测函数
local customUpdate = nil          -- 模式自定义更新
local customDraw = nil            -- 模式自定义绘制
local modeCustomState = {}        -- 模式自定义状态（可在 customUpdate 中修改）

-- ===== 辅助函数 =====
function startShake(x, y, rot, duration)
    shake.maxX = x
    shake.maxY = y
    shake.maxRot = rot
    shake.duration = duration
    shake.timer = duration
end

function spawnPiece()
    local shape = RS.getShape(currentPiece, 0)
    local minX, maxX = 10, 0
    for _, cell in ipairs(shape) do
        if cell[1] < minX then minX = cell[1] end
        if cell[1] > maxX then maxX = cell[1] end
    end
    local width = maxX - minX + 1
    currentX = math.floor((BOARD_WIDTH - width) / 2) - minX + 1
    currentY = BOARD_HEIGHT + 1
    currentRot = 0
    lastMoveType = "spawn"

    if not isValid(currentPiece, currentRot, currentX, currentY) then
        gameOver = true
        SFX.play("gameover")
    end
end

function spawnNextPiece()
    if #nextPieces == 0 then
        gameOver = true
        return
    end
    currentPiece = table.remove(nextPieces, 1)
    if #nextPieces < 10 then
        local newPiece = Bag.next()
        table.insert(nextPieces, newPiece)
    end
    spawnPiece()
    piecesPlaced = piecesPlaced + 1
end

function isValid(piece, rot, x, y)
    local shape = RS.getShape(piece, rot)
    for _, cell in ipairs(shape) do
        local bx = x + cell[1]
        local by = y + cell[2]
        if bx < 1 or bx > BOARD_WIDTH then return false end
        if by < 1 then return false end
        if by <= BOARD_HEIGHT and board[by][bx] ~= nil then return false end
    end
    return true
end

function movePiece(dx, dy, playMoveSound)
    if currentPiece == nil or currentX == nil or currentY == nil or currentRot == nil then
        return false
    end
    if isValid(currentPiece, currentRot, currentX + dx, currentY + dy) then
        currentX = currentX + dx
        currentY = currentY + dy
        lastMoveType = "move:" .. tostring(dx) .. ":" .. tostring(dy)
        if isLockPending then
            isLockPending = false
            lockTimer = 0
        end
        if playMoveSound then
            SFX.play("move", true)
        end
        return true
    end
    return false
end

function rotatePiece(dir)
    if currentPiece == nil or currentX == nil or currentY == nil or currentRot == nil then
        return false
    end
    local newRot = (currentRot + dir) % 4
    local kicks = RS.getKicks(currentPiece, currentRot, newRot)

    for kickid, offset in ipairs(kicks) do
        local dx, dy = offset[1], offset[2]
        if isValid(currentPiece, newRot, currentX + dx, currentY + dy) then
            currentRot = newRot
            currentX = currentX + dx
            currentY = currentY + dy
            lastMoveType = "rotate:" .. tostring(dir) .. ":" .. tostring(kickid)
            if isLockPending then
                isLockPending = false
                lockTimer = 0
            end
            SFX.play("rotate", true)
            return true
        end
    end
    return false
end

function isBlocked(x, y)
    if x < 1 or x > BOARD_WIDTH or y < 1 then
        return true
    end
    if y > BOARD_HEIGHT then
        return false
    end
    return board[y][x] ~= nil
end

function lockPiece()
    local shape = RS.getShape(currentPiece, currentRot)
    if btbCount >= 4 then
        local newSurge = btbCount - 3
        if newSurge > surgeValue then
            -- surgeScale = 1.5  已移除
            if lightningLoaded then
                lightningTimer = 0.3   -- 动画持续时间
                lightningAlpha = 1
                lightningFrame = 1
            end
        end
        surgeValue = newSurge
    else
        surgeValue = 0
    end
    startShake(0, 2, 0, 0.3)
    
    local allAboveCeiling = true
    for _, cell in ipairs(shape) do
        if currentY + cell[2] <= BOARD_HEIGHT then
            allAboveCeiling = false
            break
        end
    end
    if allAboveCeiling then
        gameOver = true
        SFX.play("gameover")
        return
    end

    local isSpin = false
    if string.sub(lastMoveType, 1, 6) == "rotate" then
        if currentPiece == "T" then
            local corners = 0
            local cornersPos = {
                {currentX-1, currentY-1}, {currentX+1, currentY-1},
                {currentX-1, currentY+1}, {currentX+1, currentY+1}
            }
            for _, pos in ipairs(cornersPos) do
                local x, y = pos[1], pos[2]
                if isBlocked(x, y) then
                    corners = corners + 1
                end
            end
            isSpin = corners >= 3
        else
            local offsets = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} }
            isSpin = true
            for _, offset in ipairs(offsets) do
                local blocked = false
                for _, cell in ipairs(shape) do
                    if isBlocked(currentX + cell[1] + offset[1], currentY + cell[2] + offset[2]) then
                        blocked = true
                    end
                end
                if not blocked then
                    isSpin = false
                end
            end
        end
    end

    for _, cell in ipairs(shape) do
        local x = currentX + cell[1]
        local y = currentY + cell[2]
        if y >= 1 and y <= BOARD_HEIGHT and x >= 1 and x <= BOARD_WIDTH then
            board[y][x] = currentPiece
        end
    end
    SFX.play("lock")

    local lines = 0
    local y = 1
    while y <= BOARD_HEIGHT do
        local full = true
        for x = 1, BOARD_WIDTH do
            if not board[y][x] then
                full = false
                break
            end
        end
        if full then
            lines = lines + 1
            for yy = y, BOARD_HEIGHT - 1 do
                for x = 1, BOARD_WIDTH do
                    board[yy][x] = board[yy + 1][x]
                end
            end
            for x = 1, BOARD_WIDTH do
                board[BOARD_HEIGHT][x] = nil
            end
        else
            y = y + 1
        end
    end

    totalLines = totalLines + lines

    local isSpecial = false
    if lines > 0 and (isSpin or lines >= 4) then
        isSpecial = true
    end

    if lines > 0 then
        -- 基础分数计算
        local baseScore = 0
        local isAdvanced = false  -- 是否为高级消行（可触发B2B）

        if isSpin then
            -- T-Spin 分数
            if lines == 0 then
                baseScore = 400  -- T-Spin 0行（消行前的T旋）
                isAdvanced = true
            elseif lines == 1 then
                if lastMoveType == "rotate" and string.sub(lastMoveType, 1, 6) == "rotate" then
                    -- Mini T-Spin Single 检测（需要更精确的逻辑，这里简化）
                    baseScore = 200
                    isAdvanced = true
                else
                    baseScore = 800  -- T-Spin Single
                    isAdvanced = true
                end
            elseif lines == 2 then
                baseScore = 1200  -- T-Spin Double
                isAdvanced = true
            elseif lines == 3 then
                baseScore = 1600  -- T-Spin Triple
                isAdvanced = true
            end
        else
            -- 普通消行
            if lines == 1 then
                baseScore = 100
            elseif lines == 2 then
                baseScore = 300
            elseif lines == 3 then
                baseScore = 500
            elseif lines >= 4 then
                baseScore = 800  -- Tetris
                isAdvanced = true
            end
        end

        -- B2B 加成 [citation:9]
        if isAdvanced then
            if lastWasSpecial then
                -- 连续高级消行，B2B 生效
                baseScore = baseScore * 1.5
                btbCount = btbCount + 1
            else
                -- 第一次高级消行，无加成但开启 B2B
                btbCount = 0
            end
            lastWasSpecial = true
        else
            -- 非高级消行，打断 B2B
            if lastWasSpecial then
                btbCount = 0
            end
            lastWasSpecial = false
        end

        -- 累加分数
        score = score + baseScore

        -- 原有的音效和震动代码保持不变
        if lines == 4 then
            SFX.play("clear4")
            startShake(0, 8, 0, 0.3)
        else
            SFX.play("clear1")
            startShake(0, 3, 0, 0.4)
        end

        -- 消息设置
        if lines == 1 then messageLine1 = "SINGLE"
        elseif lines == 2 then messageLine1 = "DOUBLE"
        elseif lines == 3 then messageLine1 = "TRIPLE"
        else messageLine1 = "TETRIS" end
        messageColor1 = {1,1,1}
    elseif messageWillChange then
        messageLine1 = ""
    end

    local messageWillChange = lines > 0 or isSpin

    if lines > 0 then
        if lines == 4 then
            SFX.play("clear4")
            startShake(0, 8, 0, 0.3)
        else
            SFX.play("clear1")
            startShake(0, 3, 0, 0.4)
        end

        if lines == 1 then messageLine1 = "SINGLE"
        elseif lines == 2 then messageLine1 = "DOUBLE"
        elseif lines == 3 then messageLine1 = "TRIPLE"
        else messageLine1 = "QUAD" end
        messageColor1 = {1,1,1}
    elseif messageWillChange then
        messageLine1 = ""
    end

    if isSpin then
        messageLine2 = currentPiece .. "-SPIN"
        if lines > 0 then
            SFX.play("spin")
        elseif lines == 0 then
            SFX.play("spin0")
        end
        messageColor2 = pieceColors[currentPiece] or {1,1,1}
    elseif messageWillChange then
        messageLine2 = nil
    end

    if messageWillChange then
        messageTimer = messageMaxTime
        messageStartTime = love.timer.getTime()
    end

    canHold = true
    isLockPending = false
    lockTimer = 0
    spawnNextPiece()
end

function hardDrop()
    while movePiece(0, -1, false) do end
    SFX.play("harddrop")
    lockPiece()
end

function hold()
    if not canHold or gameOver then return end
    if holdPiece == nil then
        holdPiece = currentPiece
        spawnNextPiece()
    else
        holdPiece, currentPiece = currentPiece, holdPiece
        spawnPiece()
    end
    canHold = false
    SFX.play("hold")
    isLockPending = false
    lockTimer = 0
end

function resetGame()
    board = {}
    for y = 1, BOARD_HEIGHT do
        board[y] = {}
        for x = 1, BOARD_WIDTH do
            board[y][x] = nil
        end
    end

    Bag.init()
    nextPieces = {}
    for i = 1, NEXT_ROWS do
        table.insert(nextPieces, Bag.next())
    end
    -- 重置所有数据
    lightningTimer = 0
    lightningAlpha = 0
    holdPiece = nil
    canHold = true
    gameOver = false
    messageLine1 = ""
    messageLine2 = nil
    messageColor1 = {1,1,1}
    messageColor2 = {1,1,1}
    messageTimer = 0
    dasKey = nil
    dasTimer = 0
    score = 0
    softDropPressed = false
    isLockPending = false
    lockTimer = 0
    btbCount = 0
    surgeValue = 0
    isBtbActive = false
    lastWasSpecial = false
    totalLines = 0
    completed = false
    gameTimer = 0
    piecesPlaced = 0
    pps = 0
    shake.timer = 0
    shake.maxX, shake.maxY, shake.maxRot = 0, 0, 0
    modeCustomState = {}

    -- 开始倒计时
    spawnNextPiece()
    countdown = true
    countdownTimer = 3
    countdownStep = 3
end

function drawAnimatedMessage()
    if messageTimer <= 0 then return end

    local elapsed = love.timer.getTime() - messageStartTime
    local progress = math.min(elapsed / messageMaxTime, 1.0)
    local spacing = progress * 15
    local alpha = 1 - progress

    if messageLine1 and messageLine1 ~= "" then
        love.graphics.setColor(messageColor1[1], messageColor1[2], messageColor1[3], alpha)
        love.graphics.setFont(largeFont)

        local chars = {}
        local totalWidth = 0
        for i = 1, #messageLine1 do
            local ch = messageLine1:sub(i, i)
            local w = largeFont:getWidth(ch)
            table.insert(chars, {ch = ch, w = w})
            totalWidth = totalWidth + w
        end
        totalWidth = totalWidth + spacing * (#chars - 1)

        local startX = BOARD_X + (BOARD_W - totalWidth) / 2
        local curX = startX
        local y = BOARD_Y + BOARD_H + 10
        for _, c in ipairs(chars) do
            love.graphics.print(c.ch, curX, y)
            curX = curX + c.w + spacing
        end
    end

    if messageLine2 then
        love.graphics.setColor(messageColor2[1], messageColor2[2], messageColor2[3], alpha)
        love.graphics.setFont(largeFont)

        local chars = {}
        local totalWidth = 0
        for i = 1, #messageLine2 do
            local ch = messageLine2:sub(i, i)
            local w = largeFont:getWidth(ch)
            table.insert(chars, {ch = ch, w = w})
            totalWidth = totalWidth + w
        end
        totalWidth = totalWidth + spacing * (#chars - 1)

        local startX = BOARD_X + (BOARD_W - totalWidth) / 2
        local curX = startX
        local y = BOARD_Y + BOARD_H + 40
        for _, c in ipairs(chars) do
            love.graphics.print(c.ch, curX, y)
            curX = curX + c.w + spacing
        end
    end
end

function drawBlock(x, y, pieceType, alpha)
    alpha = alpha or 1
    if pieceType then
        local r, g, b = pieceColors[pieceType][1], pieceColors[pieceType][2], pieceColors[pieceType][3]
        love.graphics.setColor(r, g, b, alpha)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, alpha)
    end
    love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
end

function drawShapeInArea(areaX, areaY, areaSize, pieceType, scale)
    scale = scale or 1
    local shape = RS.getShape(pieceType, 0)
    local minX, maxX, minY, maxY = 4, -1, 4, -1
    for _, cell in ipairs(shape) do
        if cell[1] < minX then minX = cell[1] end
        if cell[1] > maxX then maxX = cell[1] end
        if cell[2] < minY then minY = cell[2] end
        if cell[2] > maxY then maxY = cell[2] end
    end
    local shapeW = (maxX - minX + 1) * BLOCK_SIZE * scale
    local shapeH = (maxY - minY + 1) * BLOCK_SIZE * scale
    local startX = areaX + (areaSize - shapeW) / 2
    local startY = areaY + (areaSize - shapeH) / 2

    love.graphics.setColor(pieceColors[pieceType])
    for _, cell in ipairs(shape) do
        local x = startX + (cell[1] - minX) * BLOCK_SIZE * scale
        local y = startY + (maxY - cell[2]) * BLOCK_SIZE * scale
        love.graphics.rectangle("fill", x, y, BLOCK_SIZE * scale, BLOCK_SIZE * scale)
    end
end

-- ===== 场景回调 =====
function GameScene.load()
    SFX.load()

    modeConfig = _G.currentModeConfig or { start_speed = 0.5, name = "未知模式" }
    _G.currentModeConfig = nil
    if modeConfig.start_speed then
        fallInterval = modeConfig.start_speed
    end
    modeName = modeConfig.name or "未知模式"

    -- 处理目标函数
    if type(modeConfig.goal) == "function" then
        goalFunction = modeConfig.goal
    elseif type(modeConfig.goal) == "table" and modeConfig.goal.type then
        local target = require("core.target_data")
        print("target_data 已加载，包含类型:", target.lines and "lines" or "无lines")  -- 调试
        local generator = target[modeConfig.goal.type]
        if generator then
            goalFunction = generator(modeConfig.goal.value)
            print("目标函数生成成功")
        else
            print("警告：未知的目标类型 " .. tostring(modeConfig.goal.type))
            goalFunction = nil
        end
    end

    -- 加载自定义钩子
    if type(modeConfig.customUpdate) == "function" then
        customUpdate = modeConfig.customUpdate
    else
        customUpdate = nil
    end
    if type(modeConfig.customDraw) == "function" then
        customDraw = modeConfig.customDraw
    else
        customDraw = nil
    end

    local settings = Settings.load()
    DAS_DELAY = settings.das / 60
    DAS_INTERVAL = settings.arr / 60

    stars = {}
    for i = 1, 200 do
        table.insert(stars, {
            x = math.random(0, WIN_W),
            y = math.random(0, WIN_H),
            size = math.random(1, 3),
            alpha = math.random(50, 100) / 100
        })
    end

    Music.init()
    Music.play()

    paused = false
    completed = false
    countdown = false
    resetGame()
end

function GameScene.unload()
    Music.stop()
end

function GameScene.update(dt)
    -- 倒计时处理
    if countdown then
        countdownTimer = countdownTimer - dt
        if countdownTimer <= 0 then
            if countdownStep > 1 then
                countdownStep = countdownStep - 1
                countdownTimer = 1
                SFX.play("countdown" .. countdownStep)
            else
                countdown = false
                SFX.play("go")
                -- 确保游戏状态就绪（防止意外 nil）
                if currentPiece == nil then
                    print("!!! 倒计时结束但 currentPiece 为 nil，重新生成")
                    print("nextPieces 长度:", #nextPieces)
                    print("Bag.next() 测试:", Bag.next())  -- 注意：这会消耗一个块，仅调试用
                    spawnNextPiece()
                end
                isLockPending = false
                lockTimer = 0
                fallTimer = 0
            end
        end
        Music.update()
        if musicDisplayTime > 0 then
            musicDisplayTime = musicDisplayTime - dt
        end
        return
    end

    if paused or completed then
        Music.update()
        if musicDisplayTime > 0 then
            musicDisplayTime = musicDisplayTime - dt
        end
        return
    end

    -- 计时器更新
    gameTimer = gameTimer + dt
    ppsTimer = ppsTimer + dt
    if ppsTimer >= 0.5 then
        pps = piecesPlaced / gameTimer
        ppsTimer = 0
    end

    -- surge 缩放衰减
    if surgeScale > 1.0 then
        surgeScale = math.max(1.0, surgeScale - dt * 5)
    end
    surgeBgAngle = (surgeBgAngle + dt * 2) % (math.pi * 2)

    -- 闪电动画更新
    if lightningTimer > 0 then
        lightningTimer = lightningTimer - dt
        if lightningTimer <= 0 then
            lightningAlpha = 0
        else
            lightningAlpha = lightningTimer / 0.3   -- 淡出
            lightningFrame = math.floor((0.3 - lightningTimer) / 0.1) % 3 + 1
        end
    end

    -- 震动更新
    if shake.timer > 0 then
        shake.timer = shake.timer - dt
        if shake.timer < 0 then
            shake.timer = 0
            shake.maxX, shake.maxY, shake.maxRot = 0, 0, 0
        end
    end

    Music.update()
    local currentTrack = Music.getCurrentTrack()
    if currentTrack ~= lastMusicTrack then
        lastMusicTrack = currentTrack
        musicDisplayTime = currentTrack and musicDisplayDuration or 0
    end
    if musicDisplayTime > 0 then
        musicDisplayTime = musicDisplayTime - dt
    end

    -- 调用模式自定义更新（如果存在）
    if not completed and not gameOver and not paused and not countdown and customUpdate then
        customUpdate(dt, {
            totalLines = totalLines,
            gameTimer = gameTimer,
            piecesPlaced = piecesPlaced,
            board = board,
            currentPiece = currentPiece,
            currentX = currentX,
            currentY = currentY,
            currentRot = currentRot,
            custom = modeCustomState,
        })
    end

    -- 目标达成检测
    if not completed and goalFunction then
        local state = {
            totalLines = totalLines,
            gameTimer = gameTimer,
            piecesPlaced = piecesPlaced,
            custom = modeCustomState,
        }
        -- 调试输出
        print("Debug: totalLines =", totalLines, "goalFunction(state) =", goalFunction(state))
        if goalFunction(state) then
            completed = true
            SFX.play("finished")
            print(">>> 目标达成！")
        end
    end

    if gameOver then
        dasKey = nil
        softDropPressed = false
        return
    end

    if messageTimer > 0 then
        messageTimer = messageTimer - dt
        if messageTimer <= 0 then
            messageLine1 = ""
            messageLine2 = nil
        end
    end

    fallTimer = fallTimer + dt
    while fallTimer >= fallInterval do
        fallTimer = fallTimer - fallInterval
        if not movePiece(0, -1, false) then
            if not isLockPending then
                isLockPending = true
                lockTimer = 0
            end
        end
    end

    if isLockPending then
        lockTimer = lockTimer + dt
        if lockTimer >= lockDelay then
            lockPiece()
            return
        end
    end

    if dasKey then
        if not dasMoved then
            dasTimer = dasTimer + dt
            if dasTimer >= DAS_DELAY then
                if dasKey == "left" then movePiece(-1, 0, true)
                elseif dasKey == "right" then movePiece(1, 0, true) end
                dasTimer = dasTimer - DAS_DELAY
                dasMoved = true
            end
        else
            dasTimer = dasTimer + dt
            while dasTimer >= DAS_INTERVAL do
                dasTimer = dasTimer - DAS_INTERVAL
                if dasKey == "left" then movePiece(-1, 0, true)
                elseif dasKey == "right" then movePiece(1, 0, true) end
            end
        end
    else
        dasMoved = false
        dasTimer = 0
    end

    if softDropPressed then
        movePiece(0, -1, false)
    end
end

function GameScene.keypressed(key)
    -- 快速重开
    if key == "r" or key == "R" then
        resetGame()
        return
    end

    if key == "escape" then
        if gameOver then
            Scene.switch("select")
        elseif completed then
            Scene.switch("select")
        else
            paused = not paused
        end
        return
    end

    if paused or completed or countdown then return end

    local settings = Settings.load()
    local keys = settings.keys

    if gameOver then
        if key == "r" then resetGame() end
        return
    end

    if key == keys.left then
        movePiece(-1, 0, true)
        dasKey = "left"
        dasTimer = 0
        dasMoved = false
    elseif key == keys.right then
        movePiece(1, 0, true)
        dasKey = "right"
        dasTimer = 0
        dasMoved = false
    elseif key == keys.softDrop then
        softDropPressed = true
    elseif key == keys.rotateCW then
        rotatePiece(1)
    elseif key == keys.rotateCCW then
        rotatePiece(-1)
    elseif key == keys.rotate180 then
        rotatePiece(2)
    elseif key == keys.hardDrop then
        hardDrop()
    elseif key == keys.hold then
        hold()
    end
end

function GameScene.keyreleased(key)
    local settings = Settings.load()
    local keys = settings.keys

    if key == keys.left and dasKey == "left" then
        dasKey = nil
        dasMoved = false
    elseif key == keys.right and dasKey == "right" then
        dasKey = nil
        dasMoved = false
    elseif key == keys.softDrop then
        softDropPressed = false
    end
end

function GameScene.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- 暂停菜单
    if paused then
        local totalHeight = #pauseButtons * (pauseButtonHeight + pauseButtonSpacing) - pauseButtonSpacing
        local startY = (WIN_H - totalHeight) / 2
        for i, btn in ipairs(pauseButtons) do
            local bx = (WIN_W - pauseButtonWidth) / 2
            local by = startY + (i-1) * (pauseButtonHeight + pauseButtonSpacing)
            if x >= bx and x <= bx + pauseButtonWidth and y >= by and y <= by + pauseButtonHeight then
                btn.action()
                return
            end
        end
    elseif completed then
        -- 完成界面（您可能已定义，此处略）
    elseif gameOver then
        -- 游戏结束界面按钮
        local buttonWidth = 200
        local buttonHeight = 50
        local buttonSpacing = 30
        local startX = (WIN_W - buttonWidth * 2 - buttonSpacing) / 2
        local buttonY = WIN_H/2 + 80

        -- 重试按钮
        local bx1 = startX
        local by1 = buttonY
        if x >= bx1 and x <= bx1 + buttonWidth and y >= by1 and y <= by1 + buttonHeight then
            resetGame()
            return
        end

        -- 返回模式选择按钮
        local bx2 = startX + buttonWidth + buttonSpacing
        local by2 = buttonY
        if x >= bx2 and x <= bx2 + buttonWidth and y >= by2 and y <= by2 + buttonHeight then
            Scene.switch("select")
            return
        end
    end
end

function GameScene.draw()
    -- BTB 显示
    if btbCount > 0 then
        -- 确定前缀颜色：当 btbCount>3 时，使用 surge 背景色，否则默认黄色
        local prefixColor = {1, 1, 0.6}
        local bgColor
        if btbCount > 3 then
            local colorIndex = math.floor((surgeValue - 1) / 5) + 1
            colorIndex = math.min(colorIndex, #surgeColors)
            bgColor = surgeColors[colorIndex]
            prefixColor = bgColor
        end
        love.graphics.setColor(prefixColor[1], prefixColor[2], prefixColor[3], 1)
        love.graphics.setFont(mediumFont)
        local prefix = string.format("B2B x%d", btbCount)
        local x = HOLD_X
        local y = HOLD_Y + HOLD_WIDTH + 15
        love.graphics.print(prefix, x, y)

        if btbCount > 3 then
            local surgeText = tostring(surgeValue)
            local prefixWidth = mediumFont:getWidth(prefix)
            love.graphics.setFont(largeFont)
            local surgeWidth = largeFont:getWidth(surgeText)
            local surgeHeight = largeFont:getHeight()
            local space = 10
            local surgeX = x + prefixWidth + space
            local centerX = surgeX + surgeWidth / 2
            local centerY = y + surgeHeight / 2

            -- 旋转背景
            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            love.graphics.rotate(surgeBgAngle)
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.5)
            local imgWidth = surgeBgImage:getWidth()
            local imgHeight = surgeBgImage:getHeight()
            local scale = math.max(surgeWidth, surgeHeight) * 1.0 / math.min(imgWidth, imgHeight) + 8 / math.min(imgWidth, imgHeight)
            love.graphics.draw(surgeBgImage, 0, 0, 0, scale, scale, imgWidth/2, imgHeight/2)
            love.graphics.pop()

            -- 直接绘制数字（无缩放）
            love.graphics.setColor(1, 1, 1, 1)
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        love.graphics.print(surgeText, surgeX + dx, y + dy)
                    end
                end
            end
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.print(surgeText, surgeX, y)

            -- 闪电动画（绘制在数字上方）
            if lightningTimer > 0 and lightningLoaded then
                local frame = lightningFrames[lightningFrame]
                if frame then
                    local fw, fh = frame:getWidth(), frame:getHeight()
                    local fx = surgeX + surgeWidth + 10   -- 显示在 surge 数字右侧
                    local fy = y - fh/2
                    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], lightningAlpha * 0.8)
                    love.graphics.draw(frame, fx, fy, 0, 1, 1, fw/2, fh/2)
                end
            end

            love.graphics.setFont(mediumFont)
        end
    end
    -- 音乐信息
    if musicDisplayTime > 0 then
        local track = Music.getCurrentTrack()
        if track then
            local progress = musicDisplayTime / musicDisplayDuration
            local alpha
            if progress > 1 - fadeTime / musicDisplayDuration then
                alpha = (musicDisplayDuration - musicDisplayTime) / fadeTime
            elseif progress < fadeTime / musicDisplayDuration then
                alpha = musicDisplayTime / fadeTime
            else
                alpha = 1
            end
            alpha = math.max(0, math.min(1, alpha)) * 0.8

            love.graphics.setColor(0.8, 0.8, 0.8, alpha)
            love.graphics.setFont(smallFont)

            local line1 = track.title .. " - " .. track.artist
            local line2 = "from " .. track.source
            local w1 = smallFont:getWidth(line1)
            local w2 = smallFont:getWidth(line2)
            local x1 = (WIN_W - w1) / 2
            local x2 = (WIN_W - w2) / 2
            local y = BOARD_Y + BOARD_H + 20
            love.graphics.print(line1, x1, y)
            love.graphics.print(line2, x2, y + 25)
        end
    end

    -- 星空
    for _, s in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, s.alpha)
        love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- 抖动开始
    if shake.timer > 0 then
        love.graphics.push()
        local t = shake.timer / shake.duration
        local dx = shake.maxX * t
        local dy = shake.maxY * t
        local dr = shake.maxRot * t * math.pi / 180
        love.graphics.translate(BOARD_X + BOARD_W/2, BOARD_Y + BOARD_H/2)
        love.graphics.rotate(dr)
        love.graphics.translate(-BOARD_X - BOARD_W/2, -BOARD_Y - BOARD_H/2)
        love.graphics.translate(dx, dy)
    end

    -- 主板背景
    love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", BOARD_X - 2, BOARD_Y - 2, BOARD_W + 4, BOARD_H + 4)

    -- 固定格子（上下反转）
    for y = 1, BOARD_HEIGHT do
        for x = 1, BOARD_WIDTH do
            local piece = board[y][x]
            local xpos = BOARD_X + (x - 1) * BLOCK_SIZE
            local ypos = BOARD_Y + (BOARD_HEIGHT - y) * BLOCK_SIZE
            if piece then
                drawBlock(xpos, ypos, piece)
            else
                love.graphics.setColor(0.3, 0.3, 0.35, 0.5)
                love.graphics.rectangle("line", xpos, ypos, BLOCK_SIZE, BLOCK_SIZE)
            end
        end
    end

    -- 影子
    if currentPiece then
        local shadowY = currentY
        while isValid(currentPiece, currentRot, currentX, shadowY - 1) do
            shadowY = shadowY - 1
        end
        if shadowY < currentY then
            local shape = RS.getShape(currentPiece, currentRot)
            for _, cell in ipairs(shape) do
                local x = BOARD_X + (currentX + cell[1] - 1) * BLOCK_SIZE
                local y = BOARD_Y + (BOARD_HEIGHT - shadowY - cell[2]) * BLOCK_SIZE
                drawBlock(x, y, currentPiece, 0.3)
            end
        end
    end

    -- 当前方块
    if currentPiece then
        local shape = RS.getShape(currentPiece, currentRot)
        for _, cell in ipairs(shape) do
            local x = BOARD_X + (currentX + cell[1] - 1) * BLOCK_SIZE
            local y = BOARD_Y + (BOARD_HEIGHT - currentY - cell[2]) * BLOCK_SIZE
            drawBlock(x, y, currentPiece)
        end
    end

    -- HOLD 区域
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", HOLD_X - 5, HOLD_Y - 5, HOLD_WIDTH + 10, HOLD_WIDTH + 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mediumFont)
    love.graphics.print("HOLD", HOLD_X, HOLD_Y - 35)
    if holdPiece then
        drawShapeInArea(HOLD_X, HOLD_Y, HOLD_WIDTH, holdPiece)
    end

    -- NEXT 区域
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", NEXT_X - 5, NEXT_Y - 5, HOLD_WIDTH + 10, PREVIEW_SIZE * NEXT_ROWS + 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("NEXT", NEXT_X, NEXT_Y - 35)

    -- 显示模式名称（NEXT 上方）
    if modeName ~= "" then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(modeName, NEXT_X, NEXT_Y - 60)
    end
    -- 分数显示（位于主板背景之上、格子之下）
    if not completed and not gameOver then
        love.graphics.setColor(1, 1, 1, 0.5)  -- 半透明白色
        love.graphics.setFont(largeFont)
        local scoreText = "" .. score
        local w = mediumFont:getWidth(scoreText)
        local x = BOARD_X + (BOARD_W - w) / 2   -- 水平居中
        local y = BOARD_Y + 50
        love.graphics.print(scoreText, x, y)
    end
    local blockAreaX = NEXT_X - 5 + (HOLD_WIDTH + 10 - PREVIEW_SIZE) / 2
    for i = 1, math.min(NEXT_ROWS, #nextPieces) do
        local piece = nextPieces[i]
        local areaY = NEXT_Y + (i - 1) * PREVIEW_SIZE
        drawShapeInArea(blockAreaX, areaY, PREVIEW_SIZE, piece, 0.6)
    end

    -- 消行消息
    drawAnimatedMessage()

    -- 抖动结束
    if shake.timer > 0 then
        love.graphics.pop()
    end

    -- 剩余行数显示（仅当模式目标为行数且 target==40 时显示，但可自定义）
    if modeConfig and modeConfig.goal and modeConfig.goal.type == "lines" and modeConfig.goal.value then
        local remaining = math.max(0, modeConfig.goal.value - totalLines)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(largeFont)
        local text = tostring(remaining)
        local w = largeFont:getWidth(text)
        local x = BOARD_X - w - 40
        local y = BOARD_Y + (BOARD_H - largeFont:getHeight()) / 2
        love.graphics.print(text, x, y)
    end

    -- 游戏结束    
    if gameOver then
        -- 半透明黑色背景
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, WIN_W, WIN_H)

        -- 主标题
        love.graphics.setFont(largeFont)
        love.graphics.setColor(1, 1, 1, 1)
        local text = "游戏结束"
        local textW = largeFont:getWidth(text)
        love.graphics.print(text, (WIN_W - textW)/2, WIN_H/2 - 100)

        -- 统计数据
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(mediumFont)
        local linesText = "Lines: " .. totalLines
        local scoreText = "分数: " .. score

        local linesW = mediumFont:getWidth(linesText)
        local scoreW = mediumFont:getWidth(scoreText)
        local centerX = WIN_W / 2
        love.graphics.print(linesText, centerX - linesW/2, WIN_H/2 - 30)
        love.graphics.print(scoreText, centerX - scoreW/2, WIN_H/2 + 0)

        -- 按钮
        local buttonWidth = 200
        local buttonHeight = 50
        local buttonSpacing = 30
        local startX = (WIN_W - buttonWidth * 2 - buttonSpacing) / 2
        local buttonY = WIN_H/2 + 80

        -- 重试按钮
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", startX, buttonY, buttonWidth, buttonHeight, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(mediumFont)
        local retryText = "重试"
        local retryW = mediumFont:getWidth(retryText)
        love.graphics.print(retryText, startX + (buttonWidth - retryW)/2, buttonY + (buttonHeight - mediumFont:getHeight())/2)

        -- 返回选择按钮
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", startX + buttonWidth + buttonSpacing, buttonY, buttonWidth, buttonHeight, 10)
        love.graphics.setColor(1, 1, 1)
        local selectText = "玩玩别的"
        local selectW = mediumFont:getWidth(selectText)
        love.graphics.print(selectText, startX + buttonWidth + buttonSpacing + (buttonWidth - selectW)/2, buttonY + (buttonHeight - mediumFont:getHeight())/2)

        -- 键盘提示（可选，已移除文本提示）
    end

    -- 帧率和计时器（主板左侧，与底边对齐）
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(mediumFont)

    local minutes = math.floor(gameTimer / 60)
    local seconds = math.floor(gameTimer % 60)
    local milliseconds = math.floor((gameTimer * 1000) % 1000)
    local timerText = string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
    love.graphics.print(timerText, BOARD_X - 180, BOARD_Y + BOARD_H - 30)

    local ppsText = string.format("PPS: %.2f", pps)
    love.graphics.print(ppsText, BOARD_X - 180, BOARD_Y + BOARD_H - 55)

    -- 调用模式自定义绘制
    if not paused and not completed and not countdown and customDraw then
        customDraw({
            totalLines = totalLines,
            gameTimer = gameTimer,
            piecesPlaced = piecesPlaced,
            board = board,
            currentPiece = currentPiece,
            custom = modeCustomState,
        })
    end

    -- 暂停菜单
    if paused then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, WIN_W, WIN_H)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(largeFont)
        love.graphics.printf("暂停", 0, 200, WIN_W, "center")

        local totalHeight = #pauseButtons * (pauseButtonHeight + pauseButtonSpacing) - pauseButtonSpacing
        local startY = (WIN_H - totalHeight) / 2
        for i, btn in ipairs(pauseButtons) do
            local bx = (WIN_W - pauseButtonWidth) / 2
            local by = startY + (i-1) * (pauseButtonHeight + pauseButtonSpacing)
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", bx, by, pauseButtonWidth, pauseButtonHeight, 10)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(mediumFont)
            love.graphics.printf(btn.label, bx, by + (pauseButtonHeight - mediumFont:getHeight())/2, pauseButtonWidth, "center")
        end
    end

    -- 完成界面（中央大号用时）
    if completed then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, WIN_W, WIN_H)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(largeFont)
        love.graphics.printf("完成！", 0, 200, WIN_W, "center")

        -- 大号用时
        love.graphics.setFont(largeFont)
        local minutes = math.floor(gameTimer / 60)
        local seconds = math.floor(gameTimer % 60)
        local milliseconds = math.floor((gameTimer * 1000) % 1000)
        local timeText = string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
        love.graphics.printf(timeText, 0, 280, WIN_W, "center")

        -- 按钮
        local totalHeight = #completedButtons * (pauseButtonHeight + pauseButtonSpacing) - pauseButtonSpacing
        local startY = (WIN_H - totalHeight) / 2 + 100
        for i, btn in ipairs(completedButtons) do
            local bx = (WIN_W - pauseButtonWidth) / 2
            local by = startY + (i-1) * (pauseButtonHeight + pauseButtonSpacing)
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", bx, by, pauseButtonWidth, pauseButtonHeight, 10)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(mediumFont)
            love.graphics.printf(btn.label, bx, by + (pauseButtonHeight - mediumFont:getHeight())/2, pauseButtonWidth, "center")
        end
    end

    -- 倒计时（最上层）
    if countdown then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, WIN_W, WIN_H)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(largeFont)
        local text = tostring(countdownStep)
        if countdownStep == 1 and countdownTimer <= 0.5 then
            text = "GO!"
        end
        local w = largeFont:getWidth(text)
        love.graphics.print(text, (WIN_W - w)/2, WIN_H/2 - 50)
    end

    love.graphics.setColor(1, 1, 1)
end

return GameScene