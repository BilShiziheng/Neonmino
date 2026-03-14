local RS = require("core.RS_data")
local Bag = require("core.bag_data")
local SFX = require("core.sfx")
local Music = require("core.music")
local surgeBgAngle = 0  -- 背景旋转角度
local surgeScale = 1.0  -- 缩放比例，1.0 为正常大小
local surgeBgAngle = 0          -- 背景旋转角度
local surgeBgImage = love.graphics.newImage("assets/images/surge_bg.png")  -- 请确保图片存在
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
-- 常量
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

-- 游戏变量
local board = {}
local currentPiece, currentX, currentY, currentRot
local nextPieces = {}
local holdPiece = nil
local canHold = true
local gameOver = false
-- 上次移动方式
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
local shake = {
    timer = 0,
    duration = 0,
    maxX = 0,
    maxY = 0,
    maxRot = 0,
}
local btbCount = 0
local surgeValue = 0
local isBtbActive = false
local lastWasSpecial = false

local lastMusicTrack = nil
local musicDisplayTime = 0
local musicDisplayDuration = 5
local fadeTime = 0.5


-- local errorFile = io.open("error.log", "w")
-- --	错误日志
-- function logError(text)
-- 	errorFile:write(text)
-- end

function startShake(x, y, rot, duration)
    shake.maxX = x
    shake.maxY = y
    shake.maxRot = rot
    shake.duration = duration
    shake.timer = duration
end

function love.load()
    math.randomseed(os.time())
    math.random() math.random() math.random()

    Music.init()
    Music.play()

    for i = 1, 200 do
        table.insert(stars, {
            x = math.random(0, WIN_W),
            y = math.random(0, WIN_H),
            size = math.random(1, 3),
            alpha = math.random(50, 100) / 100
        })
    end

    SFX.load()

    love.window.setMode(WIN_W, WIN_H, {resizable = false, vsync = true})
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

    local fontPath = "font.ttf"
    smallFont = love.graphics.newFont(fontPath, 18)
    mediumFont = love.graphics.newFont(fontPath, 24)
    largeFont = love.graphics.newFont(fontPath, 36)

    resetGame()
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
    softDropPressed = false
    isLockPending = false
    lockTimer = 0
    btbCount = 0
    surgeValue = 0
    isBtbActive = false
    lastWasSpecial = false
    shake.timer = 0
    shake.maxX, shake.maxY, shake.maxRot = 0, 0, 0
    spawnNextPiece()
end

--	简化代码：生成块
function spawnPiece()
	local shape = RS.getShape(currentPiece, 0)
	local minX, maxX = 10, 0
	for _, cell in ipairs(shape) do
		if cell[1] < minX then minX = cell[1] end
		if cell[1] > maxX then maxX = cell[1] end
	end
	local width = maxX - minX + 1
	currentX = math.floor((BOARD_WIDTH - width) / 2) - minX + 1
	--	x 坐标忘记了 +1
	currentY = BOARD_HEIGHT + 1
	--	y 坐标反转
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
    currentPiece = table.remove(nextPieces, 1)   -- 改为 1
	if #nextPieces < 10 then
		--	限制 next 数组长度（性能隐患）
	    table.insert(nextPieces, Bag.next())
	end

	spawnPiece()
end

function isValid(piece, rot, x, y)
    local shape = RS.getShape(piece, rot)
    for _, cell in ipairs(shape) do
        local bx = x + cell[1]
        local by = y + cell[2]
        if bx < 1 or bx > BOARD_WIDTH then return false end
        if by < 1 then return false end
		--	Q: 是否考虑板面更上方有块的情况
        if by <= BOARD_HEIGHT and board[by][bx] ~= nil then return false end
    end
    return true
end

function movePiece(dx, dy, playMoveSound)
    if isValid(currentPiece, currentRot, currentX + dx, currentY + dy) then
        currentX = currentX + dx
        currentY = currentY + dy
		lastMoveType = "move:" .. tostring(dx) .. ":" tostring(dy)
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
    local newRot = (currentRot + dir) % 4   -- dir: 1顺时针, -1逆时针, 2翻转
    local kicks = RS.getKicks(currentPiece, currentRot, newRot)

    for kickid, offset in ipairs(kicks) do
        local dx, dy = offset[1], offset[2]
        if isValid(currentPiece, newRot, currentX + dx, currentY + dy) then
            currentRot = newRot
            currentX = currentX + dx
            currentY = currentY + dy
			lastMoveType = "rotate:" .. tostring(dir) .. ":" tostring(kickid)
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
	--	板面上方不应被视为堵住了
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
        if newSurge > surgeValue then  -- 数字增大时触发
            surgeScale = 1.5  -- 放大到 1.5 倍
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
		--	Topout
        gameOver = true
        SFX.play("gameover")
        return
    end

	local isSpin = false
	if string.sub(lastMoveType, 1, 6) == "rotate" then
	    if currentPiece == "T" then
			--	没写 mini 判定 但是前置都有了 你可以自己实现一下
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
			--	不可移动判定有问题 应该先枚举移动方式 然后检查重叠
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

	--	移下来 不可移动判定会被自己挡住
	for _, cell in ipairs(shape) do
        local x = currentX + cell[1]
        local y = currentY + cell[2]
        if y >= 1 and y <= BOARD_HEIGHT and x >= 1 and x <= BOARD_WIDTH then
            board[y][x] = currentPiece
        end
    end
    SFX.play("lock")

	--	消行判定 反转 y
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



    local isSpecial = false
    if lines > 0 and (isSpin or lines >= 4) then
        isSpecial = true
    end

    if lines > 0 then
        if isSpecial then
            if not lastWasSpecial then
                btbCount = 0
                surgeValue = 0
                isBtbActive = true
            else
                btbCount = btbCount + 1
                if btbCount == 4 then
                    SFX.play("btb_start")
                end
                if btbCount >= 5 then
                    SFX.play("btbc")
                end
                surgeValue = btbCount >= 4 and btbCount - 3 or 0
            end
        else
            if isBtbActive then
                if surgeValue > 0 then
                    SFX.play("btb_break")
                end
                btbCount = 0
                surgeValue = 0
                isBtbActive = false
            end
        end
        lastWasSpecial = isSpecial
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

	--	为了 Spin0 移出来了
    
    if isSpin then
        messageLine2 = currentPiece .. "-SPIN"
        if lines > 0 then
            SFX.play("spin")
        elseif line == 0 then
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
	--	是否考虑保留 das 和软降
	--	我觉得需要
    --	dasKey = nil
    --	softDropPressed = false
end

function hold()
    if not canHold or gameOver then return end
    if holdPiece == nil then
        holdPiece = currentPiece
        spawnNextPiece()
    else
        holdPiece, currentPiece = currentPiece, holdPiece
		--	简化
		spawnPiece()
    end
    canHold = false
    SFX.play("hold")
    --	dasKey = nil
    --	softDropPressed = false
    isLockPending = false
    lockTimer = 0
end

function love.update(dt)
    Music.update()
    if surgeScale > 1.0 then
        surgeScale = math.max(1.0, surgeScale - dt * 5)  -- 每秒衰减 5，可调整速度
    end
    surgeBgAngle = (surgeBgAngle + dt * 2) % (math.pi * 2)
    if shake.timer > 0 then
        shake.timer = shake.timer - dt
        if shake.timer < 0 then
            shake.timer = 0
            shake.maxX, shake.maxY, shake.maxRot = 0, 0, 0
        end
    end
    local currentTrack = Music.getCurrentTrack()
    if currentTrack ~= lastMusicTrack then
        lastMusicTrack = currentTrack
        musicDisplayTime = currentTrack and musicDisplayDuration or 0
    end
    if musicDisplayTime > 0 then
        musicDisplayTime = musicDisplayTime - dt
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

	--	暂时不考虑 sdf 机制
    if softDropPressed then
        movePiece(0, -1, false)
    end
end

--	改了自己的键位 记得写键位设置
function love.keypressed(key)
    -- 全局退出（优先级最高）
    if key == "escape" then
        love.event.quit()
    end

    if gameOver then
        if key == "r" then  -- 反引号键用于重开
            resetGame()
        end
        return
    end

    if key == "q" or key == "Q" then  -- 处理大小写
        movePiece(-1, 0, true)
        dasKey = "left"
        dasTimer = 0
        dasMoved = false
    elseif key == "e" or key == "E" then
        movePiece(1, 0, true)
        dasKey = "right"
        dasTimer = 0
        dasMoved = false
    elseif key == "w" or key == "W" then
        softDropPressed = true
        -- 软降的实际移动由 update 中的 softDropPressed 处理
    elseif key == "p" or key == "P" then
        rotatePiece(1)   -- 顺时针
    elseif key == "o" or key == "O" then
        rotatePiece(-1)  -- 逆时针
    elseif key == "i" or key == "I" then
        rotatePiece(2)   -- 180°
    elseif key == "space" then
        hardDrop()
    elseif key == "lalt" or key == "ralt" then
        hold()
    end
end

function love.keyreleased(key)
    if key == "q" or key == "Q" then
        if dasKey == "left" then
            dasKey = nil
            dasMoved = false
        end
    elseif key == "e" or key == "E" then
        if dasKey == "right" then
            dasKey = nil
            dasMoved = false
        end
    elseif key == "w" or key == "W" then
        softDropPressed = false
    end
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
        love.graphics.setFont(mediumFont)

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

function love.draw()
    if btbCount > 0 then
        love.graphics.setColor(1, 1, 0.6, 1)
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

            -- 根据 surge 值计算颜色索引（每 5 一个区间）
            local colorIndex = math.floor((surgeValue - 1) / 5) + 1
            colorIndex = math.min(colorIndex, #surgeColors)  -- 不超过表长度
            local bgColor = surgeColors[colorIndex]

            -- 绘制旋转图片背景
            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            love.graphics.rotate(surgeBgAngle)
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.5)

            local imgWidth = surgeBgImage:getWidth()
            local imgHeight = surgeBgImage:getHeight()
            -- 缩放比例：使图片略大于数字
            local scale = math.max(surgeWidth, surgeHeight) * 1.0 / math.min(imgWidth, imgHeight) + 8 / math.min(imgWidth, imgHeight)
            love.graphics.draw(surgeBgImage, 0, 0, 0, scale, scale, imgWidth/2, imgHeight/2)

            love.graphics.pop()

            -- 绘制白色描边和黑色数字（带缩放动画）
            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            love.graphics.scale(surgeScale)
            love.graphics.translate(-centerX, -centerY)

            -- 白色描边
            love.graphics.setColor(1, 1, 1, 1)
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        love.graphics.print(surgeText, surgeX + dx, y + dy)
                    end
                end
            end
            -- 黑色数字
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.print(surgeText, surgeX, y)

            love.graphics.pop()  -- 恢复缩放

            love.graphics.setFont(mediumFont)  -- 恢复字体
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

    -- 星空背景
    for _, s in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, s.alpha)
        love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- ===== 开始抖动区域（如果正在抖动） =====
    if shake.timer > 0 then
        love.graphics.push()
        local t = shake.timer / shake.duration
        local dx = shake.maxX * t
        local dy = shake.maxY * t
        local dr = shake.maxRot * t * math.pi / 180
        -- 以主板中心为原点旋转和平移
        love.graphics.translate(BOARD_X + BOARD_W/2, BOARD_Y + BOARD_H/2)
        love.graphics.rotate(dr)
        love.graphics.translate(-BOARD_X - BOARD_W/2, -BOARD_Y - BOARD_H/2)
        love.graphics.translate(dx, dy)
    end

    -- ===== 受抖动影响的元素 =====
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

    -- 影子（反转后 y 坐标计算已适配）
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

    -- 当前方块（反转）
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

    local blockAreaX = NEXT_X - 5 + (HOLD_WIDTH + 10 - PREVIEW_SIZE) / 2

    for i = 1, math.min(NEXT_ROWS, #nextPieces) do
        local piece = nextPieces[i]
        local areaY = NEXT_Y + (i - 1) * PREVIEW_SIZE
        drawShapeInArea(blockAreaX, areaY, PREVIEW_SIZE, piece, 0.6)
    end

    -- 消行消息
    drawAnimatedMessage()

    -- ===== 结束抖动区域 =====
    if shake.timer > 0 then
        love.graphics.pop()
    end

    -- ===== 游戏结束和帧率（不受抖动影响） =====
    if gameOver then
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(largeFont)
        local text = "GAME OVER"
        local textW = largeFont:getWidth(text)
        love.graphics.print(text, (WIN_W - textW)/2, WIN_H/2 - 50)
        love.graphics.setFont(mediumFont)
        local restart = "Press R to restart"
        local restartW = mediumFont:getWidth(restart)
        love.graphics.print(restart, (WIN_W - restartW)/2, WIN_H/2 + 10)
    end

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(smallFont)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, WIN_H - 30)
    love.graphics.setColor(1, 1, 1)
end

function drawBlock(x, y, pieceType, alpha)
    alpha = alpha or 1
    if pieceType then
        local r, g, b = pieceColors[pieceType][1], pieceColors[pieceType][2], pieceColors[pieceType][3]
        love.graphics.setColor(r, g, b, alpha)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, alpha)
    end
    love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)  -- 改为 BLOCK_SIZE
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
		--	上下反转
        local x = startX + (cell[1] - minX) * BLOCK_SIZE * scale
        local y = startY + (maxY - cell[2]) * BLOCK_SIZE * scale
        love.graphics.rectangle("fill", x, y, BLOCK_SIZE * scale, BLOCK_SIZE * scale)
    end
end
