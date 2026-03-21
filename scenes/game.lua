-- scenes/game.lua
local GameScene = {}

-- 引入必要的模块
local RS = require("core.RS_data")
local Bag = require("core.bag_data")
local SFX = require("core.sfx")
local Music = require("core.music")
local Settings = require("core.settings")
local Scene = require("core.scene")
local Button = require("core.button")

-- 将所有变量放入一个表 G 中
local G = {}
local returnFromSettings = false  -- 标记是否从设置返回

-- 常量定义
G.BOARD_WIDTH = 10
G.BOARD_HEIGHT = 20
G.BLOCK_SIZE = 36
G.HOLD_WIDTH = 130
G.NEXT_ROWS = 5
G.PREVIEW_SIZE = 90
G.WIN_W, G.WIN_H = 1600, 900

-- 布局
G.BOARD_W = G.BOARD_WIDTH * G.BLOCK_SIZE
G.BOARD_H = G.BOARD_HEIGHT * G.BLOCK_SIZE
G.BOARD_X = (G.WIN_W - G.BOARD_W) / 2
G.BOARD_Y = (G.WIN_H - G.BOARD_H) / 2
G.HOLD_X = G.BOARD_X - G.HOLD_WIDTH - 30
G.HOLD_Y = G.BOARD_Y
G.NEXT_X = G.BOARD_X + G.BOARD_W + 30
G.NEXT_Y = G.BOARD_Y

-- 闪电相关
G.lightningFrames = {}
G.lightningLoaded = false
do
    local success, img1 = pcall(love.graphics.newImage, "assets/images/spark1.png")
    local success2, img2 = pcall(love.graphics.newImage, "assets/images/spark2.png")
    local success3, img3 = pcall(love.graphics.newImage, "assets/images/spark3.png")
    if success and success2 and success3 then
        G.lightningFrames = {img1, img2, img3}
        G.lightningLoaded = true
    end
end

G.boardFrameImage = nil
G.frameLoaded = false
do
    local success, img = pcall(love.graphics.newImage, "assets/images/board_frame.png")
    if success then
        G.boardFrameImage = img
        G.frameLoaded = true
    end
end

G.lightningActive = false
G.lightningFrameTimer = 0
G.lightningAlpha = 0
G.lightningFrame = 1
G.flashState = 0
G.flashAlpha = 0
G.flashTimer = 0
G.flashCount = 0
G.flashFrame = 1
G.flashFrameTimer = 0
G.flashNextTimer = 0

-- 暂停相关
G.paused = false

-- 完成界面
G.completed = false

-- 倒计时
G.countdown = false
G.countdownTimer = 0
G.countdownStep = 0
G.countdownGo = false

-- 游戏变量
G.board = {}
G.currentPiece = nil
G.currentX = nil
G.currentY = nil
G.currentRot = nil
G.nextPieces = {}
G.holdPiece = nil
G.canHold = true
G.gameOver = false
G.lastMoveType = ""

G.messageLine1 = ""
G.messageLine2 = nil
G.messageColor1 = {1,1,1}
G.messageColor2 = {1,1,1}
G.messageTimer = 0
G.messageMaxTime = 1.5
G.messageStartTime = 0

G.fallTimer = 0
G.fallInterval = 0.5
G.lockTimer = 0
G.lockDelay = 0.5
G.isLockPending = false

G.DAS_DELAY = 10 / 60
G.DAS_INTERVAL = 2 / 60
G.dasTimer = 0
G.dasKey = nil
G.dasMoved = false
G.SOFTDROP_FACTOR = 10  -- 还没用上
G.softDropPressed = false

G.pieceColors = {
    I = {0, 1, 1}, O = {1, 1, 0}, T = {0.8, 0.2, 1},
    L = {1, 0.5, 0}, J = {0, 0, 1}, S = {0, 1, 0}, Z = {1, 0, 0}
}

G.stars = {}
G.shake = { timer = 0, duration = 0, maxX = 0, maxY = 0, maxRot = 0 }
G.btbCount = 0
G.surgeValue = 0
G.isBtbActive = false
G.lastWasSpecial = false

G.lastMusicTrack = nil
G.musicDisplayTime = 0
G.musicDisplayDuration = 5
G.fadeTime = 0.5

-- surge 相关
G.surgeBgAngle = 0
G.surgeBgImage = love.graphics.newImage("assets/images/surge_bg.png")
G.surgeColors = {
    [1] = {0.5, 0.5, 0.3}, [2] = {1, 0, 0}, [3] = {1, 0.5, 0},
    [4] = {1, 1, 0}, [5] = {0, 1, 0}, [6] = {0, 1, 1},
    [7] = {0, 0, 1}, [8] = {0.8, 0.2, 1}, [9] = {1, 0, 1},
    [10] = {1, 0.5, 1}, [11] = {0.5, 1, 0.5}, [12] = {0.5, 0.5, 1},
    [13] = {1, 1, 0.5}, [14] = {1, 0.8, 0.5}, [15] = {0.8, 0.8, 0.8},
    [16] = {0.2, 0.8, 0.2}, [17] = {0.2, 0.2, 0.8}, [18] = {0.8, 0.2, 0.2},
    [19] = {0.8, 0.8, 0.2}, [20] = {0.2, 0.8, 0.8}, [21] = {1, 1, 1},
}
G.surgeScale = 1.0
G.lastSurgeValue = 0

-- 计时相关
G.gameTimer = 0
G.piecesPlaced = 0
G.ppsTimer = 0
G.pps = 0
G.score = 0

-- 模式数据
G.modeConfig = nil
G.totalLines = 0
G.modeName = ""

-- 目标系统相关
G.goalFunction = nil
G.customUpdate = nil
G.customDraw = nil
G.modeCustomState = {}

-- Combo 相关
G.combo = 0
G.maxCombo = 0
G.lastCombo = 0

-- ===== 辅助函数 =====
function startShake(x, y, rot, duration)
    G.shake.maxX = x
    G.shake.maxY = y
    G.shake.maxRot = rot
    G.shake.duration = duration
    G.shake.timer = duration
end

-- 重新创建暂停按钮
function recreatePauseButtons()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local btnWidth = 300
    local btnHeight = 60
    local spacing = 20
    local totalHeight = 4 * (btnHeight + spacing) - spacing
    local startY = (height - totalHeight) / 2
    
    Button.clear()
    
    Button.create((width - btnWidth)/2, startY, btnWidth, btnHeight, "继续", function()
        G.paused = false
    end)
    
    Button.create((width - btnWidth)/2, startY + btnHeight + spacing, btnWidth, btnHeight, "重试", function()
        resetGame()
        G.paused = false
    end)
    
    Button.create((width - btnWidth)/2, startY + (btnHeight + spacing) * 2, btnWidth, btnHeight, "设置", function()
        returnFromSettings = true
        local SettingsScene = require("scenes.settings")
        SettingsScene.setReturnScene("game")
        Scene.switch("settings")
    end)
    
    Button.create((width - btnWidth)/2, startY + (btnHeight + spacing) * 3, btnWidth, btnHeight, "返回选择", function()
        Scene.switch("select")
    end)
end

function spawnPiece()
    local shape = RS.getShape(G.currentPiece, 0)
    local minX, maxX = 10, 0
    for _, cell in ipairs(shape) do
        if cell[1] < minX then minX = cell[1] end
        if cell[1] > maxX then maxX = cell[1] end
    end
    local width = maxX - minX + 1
    G.currentX = math.floor((G.BOARD_WIDTH - width) / 2) - minX + 1
    G.currentY = G.BOARD_HEIGHT + 1
    G.currentRot = 0
    G.lastMoveType = "spawn"
    
    -- 根据方块类型播放不同音效
    local pieceType = string.lower(G.currentPiece)
    SFX.play("spawn_" .. pieceType)

    if not isValid(G.currentPiece, G.currentRot, G.currentX, G.currentY) then
        local ResultScene = require("scenes.result")
        ResultScene.setResult({
            completed = false,
            score = G.score,
            totalLines = G.totalLines,
            piecesPlaced = G.piecesPlaced,
            gameTimer = G.gameTimer,
            pps = G.pps,
            maxBtbCount = G.btbCount,
            maxCombo = G.maxCombo,
            modeName = G.modeName,
            modeConfig = G.modeConfig,
        })
        Scene.switch("result")
        SFX.play("gameover")
    end
end

function spawnNextPiece()
    if #G.nextPieces == 0 then
        local ResultScene = require("scenes.result")
        ResultScene.setResult({
            completed = false,
            score = G.score,
            totalLines = G.totalLines,
            piecesPlaced = G.piecesPlaced,
            gameTimer = G.gameTimer,
            pps = G.pps,
            maxBtbCount = G.btbCount,
            maxCombo = G.maxCombo,
            modeName = G.modeName,
            modeConfig = G.modeConfig,
        })
        Scene.switch("result")
        SFX.play("gameover")
        return
    end
    G.currentPiece = table.remove(G.nextPieces, 1)
    if #G.nextPieces < 10 then
        local newPiece = Bag.next()
        table.insert(G.nextPieces, newPiece)
    end
    spawnPiece()
end

function isValid(piece, rot, x, y)
    local shape = RS.getShape(piece, rot)
    for _, cell in ipairs(shape) do
        local bx = x + cell[1]
        local by = y + cell[2]
        if bx < 1 or bx > G.BOARD_WIDTH then return false end
        if by < 1 then return false end
        if by <= G.BOARD_HEIGHT and G.board[by][bx] ~= nil then return false end
    end
    return true
end

function movePiece(dx, dy, playMoveSound)
    if G.countdown or G.currentPiece == nil or G.currentX == nil or G.currentY == nil or G.currentRot == nil then
        return false
    end
    if isValid(G.currentPiece, G.currentRot, G.currentX + dx, G.currentY + dy) then
        G.currentX = G.currentX + dx
        G.currentY = G.currentY + dy
        G.lastMoveType = "move:" .. tostring(dx) .. ":" .. tostring(dy)
        if G.isLockPending then
            G.isLockPending = false
            G.lockTimer = 0
        end
        if playMoveSound then
            SFX.play("move", true)
        end
        return true
    end
    return false
end

function rotatePiece(dir)
    if G.currentPiece == nil or G.currentX == nil or G.currentY == nil or G.currentRot == nil then
        return false
    end
    dir = dir % 4
    local newRot = (G.currentRot + dir) % 4
    local kicks = RS.getKicks(G.currentPiece, G.currentRot, newRot)

    for kickid, offset in ipairs(kicks) do
        local dx, dy = offset[1], offset[2]
        if isValid(G.currentPiece, newRot, G.currentX + dx, G.currentY + dy) then
            G.currentRot = newRot
            G.currentX = G.currentX + dx
            G.currentY = G.currentY + dy
            G.lastMoveType = "rotate:" .. tostring(dir) .. ":" .. tostring(kickid)
            if G.isLockPending then
                G.isLockPending = false
                G.lockTimer = 0
            end
            SFX.play("rotate", true)
            return true
        end
    end
    return false
end

function isBlocked(x, y)
    if x < 1 or x > G.BOARD_WIDTH or y < 1 then
        return true
    end
    if y > G.BOARD_HEIGHT then
        return false
    end
    return G.board[y][x] ~= nil
end

function lockPiece()
    local shape = RS.getShape(G.currentPiece, G.currentRot)
    if G.btbCount >= 4 then
        local newSurge = G.btbCount - 3
        if newSurge > G.surgeValue then
        end
        G.surgeValue = newSurge
    else
        G.surgeValue = 0
    end
    
    -- 计算落点位置决定倾斜方向
    local minX, maxX = 10, 0
    for _, cell in ipairs(shape) do
        if cell[1] < minX then minX = cell[1] end
        if cell[1] > maxX then maxX = cell[1] end
    end
    local pieceCenterX = G.currentX + (minX + maxX) / 2
    
    local tiltX = 0
    if pieceCenterX <= 4 then
        tiltX = -2
    elseif pieceCenterX >= 7 then
        tiltX = 2
    end
    startShake(tiltX, 2, tiltX * 0.3, 0.4)

    local allAboveCeiling = true
    for _, cell in ipairs(shape) do
        if G.currentY + cell[2] <= G.BOARD_HEIGHT then
            allAboveCeiling = false
            break
        end
    end
    if allAboveCeiling then
        local ResultScene = require("scenes.result")
        ResultScene.setResult({
            completed = false,
            score = G.score,
            totalLines = G.totalLines,
            piecesPlaced = G.piecesPlaced,
            gameTimer = G.gameTimer,
            pps = G.pps,
            maxBtbCount = G.btbCount,
            maxCombo = G.maxCombo,
            modeName = G.modeName,
            modeConfig = G.modeConfig,
        })
        Scene.switch("result")
        SFX.play("gameover")
        return
    end

    G.piecesPlaced = G.piecesPlaced + 1

    local spinType = "none"
    if string.sub(G.lastMoveType, 1, 6) == "rotate" then
        if G.currentPiece == "T" then
            local majorcorners, minorcorners = 0, 0
            local cornersPos = {
                {G.currentX-1, G.currentY+1}, {G.currentX-1, G.currentY-1},
                {G.currentX+1, G.currentY-1}, {G.currentX+1, G.currentY+1},
            }
            for idx, pos in ipairs(cornersPos) do
                local x, y = pos[1], pos[2]
                if isBlocked(x, y) then
                    if (G.currentRot + idx) % 4 < 2 then
                        majorcorners = majorcorners + 1
                    else
                        minorcorners = minorcorners + 1
                    end
                end
            end
            if majorcorners + minorcorners >= 3 then
                local kickMatch = string.match(G.lastMoveType, "rotate:%d+:(%d+)")
                if majorcorners >= 2 or (kickMatch and kickMatch == "5") then
                    spinType = "spin"
                else
                    spinType = "mini"
                end
            else
                spinType = "none"
            end
        end
        if spinType == "none" then
            local offsets = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} }
            spinType = G.currentPiece == "T" and "mini" or "spin"
            for _, offset in ipairs(offsets) do
                local blocked = false
                for _, cell in ipairs(shape) do
                    if isBlocked(G.currentX + cell[1] + offset[1], G.currentY + cell[2] + offset[2]) then
                        blocked = true
                    end
                end
                if not blocked then
                    spinType = "none"
                end
            end
        end
    end

    for _, cell in ipairs(shape) do
        local x = G.currentX + cell[1]
        local y = G.currentY + cell[2]
        if y >= 1 and y <= G.BOARD_HEIGHT and x >= 1 and x <= G.BOARD_WIDTH then
            G.board[y][x] = G.currentPiece
        end
    end
    SFX.play("lock")

    local lines = 0
    local y = 1
    while y <= G.BOARD_HEIGHT do
        local full = true
        for x = 1, G.BOARD_WIDTH do
            if not G.board[y][x] then
                full = false
                break
            end
        end
        if full then
            lines = lines + 1
            for yy = y, G.BOARD_HEIGHT - 1 do
                for x = 1, G.BOARD_WIDTH do
                    G.board[yy][x] = G.board[yy + 1][x]
                end
            end
            for x = 1, G.BOARD_WIDTH do
                G.board[G.BOARD_HEIGHT][x] = nil
            end
        else
            y = y + 1
        end
    end

    G.totalLines = G.totalLines + lines

    local isSpecial = false
    if lines > 0 and (spinType ~= "none" or lines >= 4) then
        isSpecial = true
    end

    -- 分数计算
    local baseScore = 0
    if spinType == "spin" then
        if lines <= 4 then
            baseScore = ({400, 800, 1200, 1600, 2600})[lines + 1]
        end
    elseif spinType == "mini" then
        if lines <= 4 then
            baseScore = ({100, 200, 400, 800, 1600})[lines + 1]
        end
    else
        if lines > 0 and lines <= 4 then
            baseScore = ({0, 100, 300, 500, 800})[lines + 1]
        end
    end
    G.score = G.score + baseScore

    -- Combo 逻辑
    if lines > 0 then
        G.combo = G.combo + 1
        if G.combo > G.maxCombo then
            G.maxCombo = G.combo
        end
        local comboNum = math.min(G.combo, 16)
        SFX.play("combo_" .. comboNum)
        
        if isSpecial then
            if not G.lastWasSpecial then
                G.btbCount = 0
                G.surgeValue = 0
                G.isBtbActive = true
            else
                G.btbCount = G.btbCount + 1
                if G.btbCount == 4 then
                    SFX.play("btb_start")
                end
                if G.btbCount >= 5 then
                    SFX.play("btbc")
                end
                G.surgeValue = G.btbCount >= 4 and G.btbCount - 3 or 0
            end
        else
            if G.combo > 1 then
                SFX.play("combo_break")
            end
            G.combo = 0
            if G.isBtbActive then
                if G.surgeValue > 0 then
                    SFX.play("btb_break")
                end
                G.btbCount = 0
                G.surgeValue = 0
                G.isBtbActive = false
            end
        end
        G.lastWasSpecial = isSpecial
    else
        if G.combo > 0 then
            SFX.play("combo_break")
        end
        G.combo = 0
    end

    G.lightningActive = (G.btbCount > 3)

    local messageWillChange = lines > 0 or spinType ~= "none"

    if lines > 0 then
        if lines == 4 then
            SFX.play("clear4")
            startShake(0, 6, 0, 0.35)
        else
            SFX.play("clear1")
            startShake(0, 2, 0, 0.3)
        end

        if lines == 1 then G.messageLine1 = "SINGLE"
        elseif lines == 2 then G.messageLine1 = "DOUBLE"
        elseif lines == 3 then G.messageLine1 = "TRIPLE"
        else G.messageLine1 = "QUAD" end
        G.messageColor1 = {1,1,1}
    elseif messageWillChange then
        G.messageLine1 = ""
    end

    if spinType ~= "none" then
        if spinType == "spin" then
            G.messageLine2 = G.currentPiece .. "-SPIN"
        else
            G.messageLine2 = "MINI " .. G.currentPiece .. "-SPIN"
        end
        if lines > 0 then
            SFX.play("spin")
        elseif lines == 0 then
            SFX.play("spin0")
        end
        G.messageColor2 = G.pieceColors[G.currentPiece] or {1,1,1}
    elseif messageWillChange then
        G.messageLine2 = nil
    end

    if messageWillChange then
        G.messageTimer = G.messageMaxTime
        G.messageStartTime = love.timer.getTime()
    end

    G.canHold = true
    G.isLockPending = false
    G.lockTimer = 0
    spawnNextPiece()
end

function hardDrop()
    while movePiece(0, -1, false) do end
    SFX.play("harddrop")
    lockPiece()
end

function hold()
    if not G.canHold or G.gameOver then return end
    if G.holdPiece == nil then
        G.holdPiece = G.currentPiece
        spawnNextPiece()
    else
        G.holdPiece, G.currentPiece = G.currentPiece, G.holdPiece
        spawnPiece()
    end
    G.canHold = false
    SFX.play("hold")
    G.isLockPending = false
    G.lockTimer = 0
end

function resetGame()
    G.board = {}
    for y = 1, G.BOARD_HEIGHT do
        G.board[y] = {}
        for x = 1, G.BOARD_WIDTH do
            G.board[y][x] = nil
        end
    end

    Bag.init()
    G.nextPieces = {}
    for i = 1, G.NEXT_ROWS do
        table.insert(G.nextPieces, Bag.next())
    end

    local settings = Settings.load()
    G.DAS_DELAY = settings.das / 60
    G.DAS_INTERVAL = settings.arr / 60
    G.SOFTDROP_FACTOR = settings.sdf

    G.lightningActive = false
    G.lightningFrameTimer = 0
    G.lightningAlpha = 0
    G.holdPiece = nil
    G.canHold = true
    G.gameOver = false
    G.messageLine1 = ""
    G.messageLine2 = nil
    G.messageColor1 = {1,1,1}
    G.messageColor2 = {1,1,1}
    G.messageTimer = 0
    G.flashState = 0
    G.flashAlpha = 0
    G.flashTimer = 0
    G.flashCount = 0
    G.flashNextTimer = 0
    G.flashFrame = 1
    G.dasKey = nil
    G.dasTimer = 0
    G.score = 0
    G.softDropPressed = false
    G.isLockPending = false
    G.lockTimer = 0
    G.btbCount = 0
    G.surgeValue = 0
    G.isBtbActive = false
    G.lastWasSpecial = false
    G.totalLines = 0
    G.completed = false
    G.gameTimer = 0
    G.piecesPlaced = 0
    G.pps = 0
    G.shake.timer = 0
    G.shake.maxX, G.shake.maxY, G.shake.maxRot = 0, 0, 0
    G.combo = 0
    G.maxCombo = 0
    G.lastCombo = 0
    G.modeCustomState = {}

    G.currentPiece = nil
    G.currentX = nil
    G.currentY = nil
    G.currentRot = nil

    G.countdown = true
    G.countdownGo = false
    G.countdownTimer = 1
    G.countdownStep = 3
    
    -- 创建暂停按钮
    recreatePauseButtons()
end

function drawAnimatedMessage()
    if G.messageTimer <= 0 then return end

    local elapsed = love.timer.getTime() - G.messageStartTime
    local progress = math.min(elapsed / G.messageMaxTime, 1.0)
    local spacing = progress * 15
    local alpha = 1 - progress

    if G.messageLine1 and G.messageLine1 ~= "" then
        love.graphics.setColor(G.messageColor1[1], G.messageColor1[2], G.messageColor1[3], alpha)
        love.graphics.setFont(largeFont)

        local chars = {}
        local totalWidth = 0
        for i = 1, #G.messageLine1 do
            local ch = G.messageLine1:sub(i, i)
            local w = largeFont:getWidth(ch)
            table.insert(chars, {ch = ch, w = w})
            totalWidth = totalWidth + w
        end
        totalWidth = totalWidth + spacing * (#chars - 1)

        local startX = G.BOARD_X + (G.BOARD_W - totalWidth) / 2
        local curX = startX
        local y = G.BOARD_Y + G.BOARD_H + 10
        for _, c in ipairs(chars) do
            love.graphics.print(c.ch, curX, y)
            curX = curX + c.w + spacing
        end
    end

    if G.messageLine2 then
        love.graphics.setColor(G.messageColor2[1], G.messageColor2[2], G.messageColor2[3], alpha)
        love.graphics.setFont(largeFont)

        local chars = {}
        local totalWidth = 0
        for i = 1, #G.messageLine2 do
            local ch = G.messageLine2:sub(i, i)
            local w = largeFont:getWidth(ch)
            table.insert(chars, {ch = ch, w = w})
            totalWidth = totalWidth + w
        end
        totalWidth = totalWidth + spacing * (#chars - 1)

        local startX = G.BOARD_X + (G.BOARD_W - totalWidth) / 2
        local curX = startX
        local y = G.BOARD_Y + G.BOARD_H + 40
        for _, c in ipairs(chars) do
            love.graphics.print(c.ch, curX, y)
            curX = curX + c.w + spacing
        end
    end
end

function drawBlock(x, y, pieceType, alpha)
    alpha = alpha or 1
    if pieceType then
        local r, g, b = G.pieceColors[pieceType][1], G.pieceColors[pieceType][2], G.pieceColors[pieceType][3]
        love.graphics.setColor(r, g, b, alpha)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, alpha)
    end
    love.graphics.rectangle("fill", x, y, G.BLOCK_SIZE, G.BLOCK_SIZE)
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
    local shapeW = (maxX - minX + 1) * G.BLOCK_SIZE * scale
    local shapeH = (maxY - minY + 1) * G.BLOCK_SIZE * scale
    local startX = areaX + (areaSize - shapeW) / 2
    local startY = areaY + (areaSize - shapeH) / 2

    love.graphics.setColor(G.pieceColors[pieceType])
    for _, cell in ipairs(shape) do
        local x = startX + (cell[1] - minX) * G.BLOCK_SIZE * scale
        local y = startY + (maxY - cell[2]) * G.BLOCK_SIZE * scale
        love.graphics.rectangle("fill", x, y, G.BLOCK_SIZE * scale, G.BLOCK_SIZE * scale)
    end
end

-- ===== 场景回调 =====
function GameScene.load()
    if returnFromSettings then
        returnFromSettings = false
        G.paused = true
        recreatePauseButtons()
        return
    end

    SFX.load()

    G.modeConfig = _G.currentModeConfig or { start_speed = 0.5, name = "未知模式" }
    -- _G.currentModeConfig = nil
    if G.modeConfig.start_speed then
        G.fallInterval = G.modeConfig.start_speed
    end
    G.modeName = G.modeConfig.name or "未知模式"

    if type(G.modeConfig.goal) == "function" then
        G.goalFunction = G.modeConfig.goal
    elseif type(G.modeConfig.goal) == "table" and G.modeConfig.goal.type then
        local target = require("core.target_data")
        local generator = target[G.modeConfig.goal.type]
        if generator then
            G.goalFunction = generator(G.modeConfig.goal.value)
        else
            print("警告：未知的目标类型 " .. tostring(G.modeConfig.goal.type))
            G.goalFunction = nil
        end
    end

    if type(G.modeConfig.customUpdate) == "function" then
        G.customUpdate = G.modeConfig.customUpdate
    else
        G.customUpdate = nil
    end
    if type(G.modeConfig.customDraw) == "function" then
        G.customDraw = G.modeConfig.customDraw
    else
        G.customDraw = nil
    end

    G.stars = {}
    for i = 1, 200 do
        table.insert(G.stars, {
            x = math.random(0, G.WIN_W),
            y = math.random(0, G.WIN_H),
            size = math.random(1, 3),
            alpha = math.random(50, 100) / 100
        })
    end

    Music.init()
    Music.play()

    G.paused = false
    G.completed = false
    G.countdown = false
    resetGame()
end

function GameScene.unload()
    Music.stop()
end

function GameScene.update(dt)
    -- 从设置返回后恢复暂停状态
    if returnFromSettings then
        returnFromSettings = false
        G.paused = true
        recreatePauseButtons()
        return
    end
    SFX.update()
    Button.update()
    Music.update()
    local currentTrack = Music.getCurrentTrack()
    if currentTrack ~= G.lastMusicTrack then
        G.lastMusicTrack = currentTrack
        G.musicDisplayTime = currentTrack and G.musicDisplayDuration or 0
    end
    if G.musicDisplayTime > 0 then
        G.musicDisplayTime = G.musicDisplayTime - dt
    end

    if G.dasKey then
        if not G.dasMoved then
            G.dasTimer = G.dasTimer + dt
            if G.dasTimer >= G.DAS_DELAY then
                if G.dasKey == "left" then 
                    local moved = movePiece(-1, 0, true)
                    if not moved then
                        startShake(-3, 0, 0, 0.15)
                    end
                elseif G.dasKey == "right" then 
                    local moved = movePiece(1, 0, true)
                    if not moved then
                        startShake(3, 0, 0, 0.15)
                    end
                end
                G.dasTimer = G.dasTimer - G.DAS_DELAY
                G.dasMoved = true
            end
        else
            G.dasTimer = G.dasTimer + dt
			local moveable = true
            while G.dasTimer >= G.DAS_INTERVAL and moveable do
                G.dasTimer = G.dasTimer - G.DAS_INTERVAL
                if G.dasKey == "left" then 
                    local moved = movePiece(-1, 0, true)
                    if not moved then
						moveable = false;
                        startShake(-3, 0, 0, 0.15)
                    end
                elseif G.dasKey == "right" then 
                    local moved = movePiece(1, 0, true)
                    if not moved then
						moveable = false;
                        startShake(3, 0, 0, 0.15)
                    end
                end
            end
        end
    else
        G.dasMoved = false
        G.dasTimer = 0
    end

    if G.softDropPressed then
        movePiece(0, -1, false)
    end

    if not G.paused and (G.countdown or G.countdownGo) then
        G.countdownTimer = G.countdownTimer - dt
        if G.countdownTimer <= 0 then
            if G.countdownStep > 1 then
                G.countdownStep = G.countdownStep - 1
                G.countdownTimer = G.countdownTimer + 1
                SFX.play("countdown" .. G.countdownStep)
            elseif G.countdownStep == 1 then
                G.countdown = false
                G.countdownGo = true
                G.countdownStep = G.countdownStep - 1
                G.countdownTimer = G.countdownTimer + 1
                SFX.play("go")
                if G.currentPiece == nil then
                    spawnNextPiece()
                end
                G.isLockPending = false
                G.lockTimer = 0
                G.fallTimer = 0
            else
                G.countdownGo = false
            end
        end
        Music.update()
        if G.musicDisplayTime > 0 then
            G.musicDisplayTime = G.musicDisplayTime - dt
        end
        if G.countdown then
            return
        end
    end

    if G.paused or G.completed then
        Music.update()
        if G.musicDisplayTime > 0 then
            G.musicDisplayTime = G.musicDisplayTime - dt
        end
        return
    end

    if G.surgeScale > 1.0 then
        G.surgeScale = math.max(1.0, G.surgeScale - dt * 5)
    end
    G.surgeBgAngle = (G.surgeBgAngle + dt * 2) % (math.pi * 2)

    if G.btbCount > 3 then
        if G.flashState == 0 then
            G.flashNextTimer = G.flashNextTimer - dt
            if G.flashNextTimer <= 0 then
                G.flashState = 1
                G.flashAlpha = 0
                G.flashTimer = 0
                G.flashCount = 0
                G.flashNextTimer = math.random(15, 30) / 10
            end
        else
            G.flashTimer = G.flashTimer + dt
            local phase = G.flashTimer / 0.3
            if phase < 0.15 then
                G.flashAlpha = phase / 0.15
            elseif phase < 0.25 then
                G.flashAlpha = 1
            elseif phase < 0.4 then
                G.flashAlpha = 1 - (phase - 0.25) / 0.15
            else
                G.flashCount = G.flashCount + 1
                if G.flashCount >= 2 then
                    G.flashState = 0
                    G.flashAlpha = 0
                else
                    G.flashTimer = 0
                end
                G.flashFrame = (G.flashFrame % 3) + 1
            end
        end
    else
        G.flashState = 0
        G.flashAlpha = 0
        G.flashNextTimer = 0
    end

    if G.shake.timer > 0 then
        G.shake.timer = G.shake.timer - dt
        if G.shake.timer < 0 then
            G.shake.timer = 0
            G.shake.maxX, G.shake.maxY, G.shake.maxRot = 0, 0, 0
        end
    end

    if not G.completed and not G.gameOver and not G.paused and not G.countdown and G.customUpdate then
        G.customUpdate(dt, {
            totalLines = G.totalLines,
            gameTimer = G.gameTimer,
            piecesPlaced = G.piecesPlaced,
            board = G.board,
            currentPiece = G.currentPiece,
            currentX = G.currentX,
            currentY = G.currentY,
            currentRot = G.currentRot,
            custom = G.modeCustomState,
        })
    end

    if not G.completed and G.goalFunction then
        local state = {
            totalLines = G.totalLines,
            gameTimer = G.gameTimer,
            piecesPlaced = G.piecesPlaced,
            custom = G.modeCustomState,
        }
        if G.goalFunction(state) then
            local ResultScene = require("scenes.result")
            ResultScene.setResult({
                completed = true,
                score = G.score,
                totalLines = G.totalLines,
                piecesPlaced = G.piecesPlaced,
                gameTimer = G.gameTimer,
                pps = G.pps,
                maxBtbCount = G.btbCount,
                maxCombo = G.maxCombo,
                modeName = G.modeName,
                modeConfig = G.modeConfig,
            })
            Scene.switch("result")
            SFX.play("finished")
            return
        end
    end

    if G.gameOver then
        G.dasKey = nil
        G.softDropPressed = false
        return
    end

    G.gameTimer = G.gameTimer + dt
    G.ppsTimer = G.ppsTimer + dt
    if G.ppsTimer >= 0.008 then
        G.pps = G.piecesPlaced / G.gameTimer
        G.ppsTimer = 0
    end

    if G.messageTimer > 0 then
        G.messageTimer = G.messageTimer - dt
        if G.messageTimer <= 0 then
            G.messageLine1 = ""
            G.messageLine2 = nil
        end
    end

    G.fallTimer = G.fallTimer + dt
    while G.fallTimer >= G.fallInterval do
        G.fallTimer = G.fallTimer - G.fallInterval
        if not movePiece(0, -1, false) then
            if not G.isLockPending then
                G.isLockPending = true
                G.lockTimer = 0
            end
        end
    end

    if G.isLockPending then
        G.lockTimer = G.lockTimer + dt
        if G.lockTimer >= G.lockDelay then
            lockPiece()
            return
        end
    end
end

function GameScene.keypressed(key)
    local settings = Settings.load()
    local keys = settings.keys

    if key == keys.restart then
		G.paused = false
        resetGame()
        return
    end

    if key == "escape" then
        if G.gameOver or G.completed then
            Scene.switch("select")
        else
            G.paused = not G.paused
        end
        return
    end

    if G.countdown then
        if key == keys.left then
            G.dasKey = "left"
            G.dasTimer = 0
            G.dasMoved = false
        elseif key == keys.right then
            G.dasKey = "right"
            G.dasTimer = 0
            G.dasMoved = false
        elseif key == keys.softDrop then
            G.softDropPressed = true
        end
        return
    end

    if G.paused or G.completed or G.gameOver then return end

    if key == keys.left then
        local moved = movePiece(-1, 0, true)
        if not moved then
            startShake(-3, 0, 0, 0.15)
        end
        G.dasKey = "left"
        G.dasTimer = 0
        G.dasMoved = false
    elseif key == keys.right then
        local moved = movePiece(1, 0, true)
        if not moved then
            startShake(3, 0, 0, 0.15)
        end
        G.dasKey = "right"
        G.dasTimer = 0
        G.dasMoved = false
    elseif key == keys.softDrop then
        G.softDropPressed = true
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

    if key == keys.left and G.dasKey == "left" then
        G.dasKey = nil
        G.dasMoved = false
    elseif key == keys.right and G.dasKey == "right" then
        G.dasKey = nil
        G.dasMoved = false
    elseif key == keys.softDrop then
        G.softDropPressed = false
    end
end

function GameScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    if G.paused then
        Button.checkPress(x, y, button)
        return
    end
    
    if G.completed then
        return
    elseif G.gameOver then
        local buttonWidth = 200
        local buttonHeight = 50
        local buttonSpacing = 30
        local startX = (G.WIN_W - buttonWidth * 2 - buttonSpacing) / 2
        local buttonY = G.WIN_H/2 + 80

        local bx1 = startX
        local by1 = buttonY
        if x >= bx1 and x <= bx1 + buttonWidth and y >= by1 and y <= by1 + buttonHeight then
            resetGame()
            return
        end

        local bx2 = startX + buttonWidth + buttonSpacing
        local by2 = buttonY
        if x >= bx2 and x <= bx2 + buttonWidth and y >= by2 and y <= by2 + buttonHeight then
            Scene.switch("select")
            return
        end
    end
end

function GameScene.mousereleased(x, y, button)
    if button ~= 1 then return end
    
    if G.paused then
        Button.checkRelease(x, y, button)
        return
    end
end

function GameScene.draw()
    -- BTB 显示
    if G.btbCount > 0 then
        local prefixColor = {1, 1, 0.6}
        local bgColor
        if G.btbCount > 3 then
            if G.surgeValue and G.surgeValue >= 1 then
                local colorIndex = math.floor((G.surgeValue - 1) / 5) + 1
                colorIndex = math.max(1, math.min(colorIndex, #G.surgeColors))
                bgColor = G.surgeColors[colorIndex] or {1, 1, 0.6}
            else
                bgColor = {1, 1, 0.6}
            end
            prefixColor = bgColor
        end
        love.graphics.setColor(prefixColor[1], prefixColor[2], prefixColor[3], 1)
        love.graphics.setFont(mediumFont)
        local prefix = string.format("B2B x%d", G.btbCount)
        local x = G.HOLD_X
        local y = G.HOLD_Y + G.HOLD_WIDTH + 15
        love.graphics.print(prefix, x, y)

        if G.btbCount > 3 then
            local surgeText = tostring(G.surgeValue)
            local prefixWidth = mediumFont:getWidth(prefix)
            love.graphics.setFont(largeFont)
            local surgeWidth = largeFont:getWidth(surgeText)
            local surgeHeight = largeFont:getHeight()
            local space = 10
            local surgeX = x + prefixWidth + space
            local centerX = surgeX + surgeWidth / 2
            local centerY = y + surgeHeight / 2

            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            love.graphics.rotate(G.surgeBgAngle)
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.5)
            local imgWidth = G.surgeBgImage:getWidth()
            local imgHeight = G.surgeBgImage:getHeight()
            local scale = math.max(surgeWidth, surgeHeight) * 1.0 / math.min(imgWidth, imgHeight) + 8 / math.min(imgWidth, imgHeight)
            love.graphics.draw(G.surgeBgImage, 0, 0, 0, scale, scale, imgWidth/2, imgHeight/2)
            love.graphics.pop()

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

            if G.flashState == 1 and G.lightningLoaded and G.flashAlpha > 0 then
                local frame = G.lightningFrames[G.flashFrame]
                if frame then
                    local fw, fh = frame:getWidth(), frame:getHeight()
                    local fx = surgeX + surgeWidth/2
                    local fy = y + surgeHeight/2 - fh/2
                    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], G.flashAlpha * 0.8)
                    love.graphics.draw(frame, fx, fy, 0, 1, 1, fw/2, fh/2)
                end
            end

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

            love.graphics.setFont(mediumFont)
        end
    end

    -- Combo 显示
    if G.combo > 0 then
        local comboColor
        if G.combo >= 10 then
            comboColor = {1, 0.5, 0}
        elseif G.combo >= 5 then
            comboColor = {1, 0.8, 0}
        else
            comboColor = {1, 1, 1}
        end
        love.graphics.setColor(comboColor[1], comboColor[2], comboColor[3], 1)
        love.graphics.setFont(mediumFont)
        local comboText = string.format("%d COMBO", G.combo)
        local x = G.HOLD_X
        local y = G.HOLD_Y + G.HOLD_WIDTH + 60
        love.graphics.print(comboText, x, y)
    end

    -- 音乐信息
    if G.musicDisplayTime > 0 then
        local track = Music.getCurrentTrack()
        if track then
            local progress = G.musicDisplayTime / G.musicDisplayDuration
            local alpha
            if progress > 1 - G.fadeTime / G.musicDisplayDuration then
                alpha = (G.musicDisplayDuration - G.musicDisplayTime) / G.fadeTime
            elseif progress < G.fadeTime / G.musicDisplayDuration then
                alpha = G.musicDisplayTime / G.fadeTime
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
            local x1 = (G.WIN_W - w1) / 2
            local x2 = (G.WIN_W - w2) / 2
            local y = G.BOARD_Y + G.BOARD_H + 20
            love.graphics.print(line1, x1, y)
            love.graphics.print(line2, x2, y + 25)
        end
    end

    -- 星空
    for _, s in ipairs(G.stars) do
        love.graphics.setColor(1, 1, 1, s.alpha)
        love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- 抖动开始
    if G.shake.timer > 0 then
        love.graphics.push()
        local t = G.shake.timer / G.shake.duration
        local easeOut = 1 - (1 - t) * (1 - t)
        local dx = G.shake.maxX * easeOut
        local dy = G.shake.maxY * easeOut
        local dr = G.shake.maxRot * easeOut * math.pi / 180
        love.graphics.translate(G.BOARD_X + G.BOARD_W/2, G.BOARD_Y + G.BOARD_H/2)
        love.graphics.rotate(dr)
        love.graphics.translate(-G.BOARD_X - G.BOARD_W/2, -G.BOARD_Y - G.BOARD_H/2)
        love.graphics.translate(dx, dy)
    end

    -- 主板背景
    love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", G.BOARD_X - 2, G.BOARD_Y - 2, G.BOARD_W + 4, G.BOARD_H + 4)
    
    -- 绘制边框
    if G.frameLoaded and G.boardFrameImage then
        local frameWidth = G.BOARD_W + 8
        local frameHeight = G.BOARD_H + 8
        local frameX = G.BOARD_X - 4
        local frameY = G.BOARD_Y - 4
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(G.boardFrameImage, frameX, frameY, 0, 
                          frameWidth / G.boardFrameImage:getWidth(), 
                          frameHeight / G.boardFrameImage:getHeight())
    else
        love.graphics.setColor(0.8, 0.8, 0.9, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", G.BOARD_X - 2, G.BOARD_Y - 2, G.BOARD_W + 4, G.BOARD_H + 4)
        love.graphics.setLineWidth(1)
    end
    
    -- 分数显示
    if not G.countdown and not G.paused and not G.completed and not G.gameOver then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(mediumFont)
        local scoreText = "" .. G.score
        local w = mediumFont:getWidth(scoreText)
        local x = G.BOARD_X + (G.BOARD_W - w) / 2
        local y = G.BOARD_Y + 50
        love.graphics.print(scoreText, x, y)
    end

    -- 固定格子
    for y = 1, G.BOARD_HEIGHT do
        for x = 1, G.BOARD_WIDTH do
            local piece = G.board[y][x]
            local xpos = G.BOARD_X + (x - 1) * G.BLOCK_SIZE
            local ypos = G.BOARD_Y + (G.BOARD_HEIGHT - y) * G.BLOCK_SIZE
            if piece then
                drawBlock(xpos, ypos, piece)
            else
                love.graphics.setColor(0.3, 0.3, 0.35, 0.5)
                love.graphics.rectangle("line", xpos, ypos, G.BLOCK_SIZE, G.BLOCK_SIZE)
            end
        end
    end

    -- 影子
    if G.currentPiece then
        local shadowY = G.currentY
        while isValid(G.currentPiece, G.currentRot, G.currentX, shadowY - 1) do
            shadowY = shadowY - 1
        end
        if shadowY < G.currentY then
            local shape = RS.getShape(G.currentPiece, G.currentRot)
            for _, cell in ipairs(shape) do
                local x = G.BOARD_X + (G.currentX + cell[1] - 1) * G.BLOCK_SIZE
                local y = G.BOARD_Y + (G.BOARD_HEIGHT - shadowY - cell[2]) * G.BLOCK_SIZE
                drawBlock(x, y, G.currentPiece, 0.3)
            end
        end
    end

    -- 当前方块
    if G.currentPiece then
        local shape = RS.getShape(G.currentPiece, G.currentRot)
        for _, cell in ipairs(shape) do
            local x = G.BOARD_X + (G.currentX + cell[1] - 1) * G.BLOCK_SIZE
            local y = G.BOARD_Y + (G.BOARD_HEIGHT - G.currentY - cell[2]) * G.BLOCK_SIZE
            drawBlock(x, y, G.currentPiece)
        end
    end

    -- HOLD 区域
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", G.HOLD_X - 5, G.HOLD_Y - 5, G.HOLD_WIDTH + 10, G.HOLD_WIDTH + 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mediumFont)
    love.graphics.print("HOLD", G.HOLD_X, G.HOLD_Y - 35)
    if G.holdPiece then
        drawShapeInArea(G.HOLD_X, G.HOLD_Y, G.HOLD_WIDTH, G.holdPiece)
    end

    -- NEXT 区域
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", G.NEXT_X - 5, G.NEXT_Y - 5, G.HOLD_WIDTH + 10, G.PREVIEW_SIZE * G.NEXT_ROWS + 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("NEXT", G.NEXT_X, G.NEXT_Y - 35)

    if G.modeName ~= "" then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(G.modeName, G.NEXT_X, G.NEXT_Y - 60)
    end

    local blockAreaX = G.NEXT_X - 5 + (G.HOLD_WIDTH + 10 - G.PREVIEW_SIZE) / 2
    for i = 1, math.min(G.NEXT_ROWS, #G.nextPieces) do
        local piece = G.nextPieces[i]
        local areaY = G.NEXT_Y + (i - 1) * G.PREVIEW_SIZE
        drawShapeInArea(blockAreaX, areaY, G.PREVIEW_SIZE, piece, 0.6)
    end

    drawAnimatedMessage()

    if G.shake.timer > 0 then
        love.graphics.pop()
    end

    -- 剩余行数显示
    if G.modeConfig and G.modeConfig.goal and G.modeConfig.goal.type == "lines" and G.modeConfig.goal.value then
        local remaining = math.max(0, G.modeConfig.goal.value - G.totalLines)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(largeFont)
        local text = tostring(remaining)
        local w = largeFont:getWidth(text)
        local x = G.BOARD_X - w - 40
        local y = G.BOARD_Y + (G.BOARD_H - largeFont:getHeight()) / 2
        love.graphics.print(text, x, y)
    end

    -- 帧率和计时器
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(mediumFont)
    local minutes = math.floor(G.gameTimer / 60)
    local seconds = math.floor(G.gameTimer % 60)
    local milliseconds = math.floor((G.gameTimer * 1000) % 1000)
    local timerText = string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
    love.graphics.print(timerText, G.BOARD_X - 180, G.BOARD_Y + G.BOARD_H - 30)
    local ppsText = string.format("PPS: %.2f", G.pps)
    love.graphics.print(ppsText, G.BOARD_X - 180, G.BOARD_Y + G.BOARD_H - 55)

    if G.gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, G.WIN_W, G.WIN_H)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(largeFont)
        local text = "游戏结束"
        local textW = largeFont:getWidth(text)
        love.graphics.print(text, (G.WIN_W - textW)/2, G.WIN_H/2 - 100)

        love.graphics.setFont(mediumFont)
        local linesText = "Lines: " .. G.totalLines
        local scoreText = "分数: " .. G.score
        local linesW = mediumFont:getWidth(linesText)
        local scoreW = mediumFont:getWidth(scoreText)
        local centerX = G.WIN_W / 2
        love.graphics.print(linesText, centerX - linesW/2, G.WIN_H/2 - 30)
        love.graphics.print(scoreText, centerX - scoreW/2, G.WIN_H/2 + 0)

        local buttonWidth = 200
        local buttonHeight = 50
        local buttonSpacing = 30
        local startX = (G.WIN_W - buttonWidth * 2 - buttonSpacing) / 2
        local buttonY = G.WIN_H/2 + 80

        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", startX, buttonY, buttonWidth, buttonHeight, 10)
        love.graphics.setColor(1, 1, 1)
        local retryText = "重试"
        local retryW = mediumFont:getWidth(retryText)
        love.graphics.print(retryText, startX + (buttonWidth - retryW)/2, buttonY + (buttonHeight - mediumFont:getHeight())/2)

        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", startX + buttonWidth + buttonSpacing, buttonY, buttonWidth, buttonHeight, 10)
        love.graphics.setColor(1, 1, 1)
        local selectText = "返回模式选择"
        local selectW = mediumFont:getWidth(selectText)
        love.graphics.print(selectText, startX + buttonWidth + buttonSpacing + (buttonWidth - selectW)/2, buttonY + (buttonHeight - mediumFont:getHeight())/2)
    end

    if not G.paused and not G.completed and not G.countdown and G.customDraw then
        G.customDraw({
            totalLines = G.totalLines,
            gameTimer = G.gameTimer,
            piecesPlaced = G.piecesPlaced,
            board = G.board,
            currentPiece = G.currentPiece,
            custom = G.modeCustomState,
        })
    end

    if G.countdown or G.countdownGo then
        local opacity = 1
        if G.countdown or G.countdownGo then
            local t = 1 - G.countdownTimer
            opacity = 1 - t * t * t
        end
        love.graphics.setColor(1, 1, 1, opacity)
        love.graphics.setFont(largeFont)
        local text = G.countdownGo and "GO!" or tostring(G.countdownStep)
        local w = largeFont:getWidth(text)
        love.graphics.print(text, (G.WIN_W - w)/2, G.WIN_H/2 - 50)
    end

    if G.paused then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, G.WIN_W, G.WIN_H)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(largeFont)
        love.graphics.printf("暂停", 0, 200, G.WIN_W, "center")
        
        Button.drawAll()
    end

    if G.completed then
        -- 完成界面由 result 场景处理
    end

    love.graphics.setColor(1, 1, 1)
end

return GameScene