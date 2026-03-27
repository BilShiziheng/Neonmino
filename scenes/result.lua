-- scenes/result.lua
local ResultScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Music = require("core.music").createEnv("result")
local Button = require("core.button")
local Settings = require("core.settings")
local Background = require("core.background")

Music.setTracklist("result")

local resultData = nil
local btnRetry, btnSelect, btnExit

-- 检查按键是否匹配（支持多键位）
local function isKeyPressed(action, key)
    local settings = Settings.load()
    local keys = settings.keys[action]
    if type(keys) == "table" then
        for _, k in ipairs(keys) do
            if k == key then return true end
        end
        return false
    end
    return keys == key
end

function ResultScene.setResult(data)
    resultData = data
end

local function restartGame()
	if resultData and resultData.modeConfig then
		_G.currentModeConfig = resultData.modeConfig
		Scene.switch("game")
	else
		Scene.switch("select")
	end
end

function ResultScene.load()
	Music.playNext()
    Background.restore()
    
    if resultData and resultData.completed then
        SFX.play("finished")
    else
        SFX.play("gameover")
    end
    
    local width = WIN_W
    local height = WIN_H
    local centerX = width / 2
    local startY = height / 2 + 80
    local btnWidth = 250
    local btnHeight = 60
    local spacing = 30
    
    Button.clear()
    
    btnRetry = Button.create(centerX - btnWidth/2, startY, btnWidth, btnHeight, "重试", restartGame)
    
    btnSelect = Button.create(centerX - btnWidth/2, startY + btnHeight + spacing, btnWidth, btnHeight, "返回模式选择", function()
        Scene.switch("select")
    end)
    
    btnExit = Button.create(centerX - btnWidth/2, startY + (btnHeight + spacing) * 2, btnWidth, btnHeight, "退出游戏", function()
        love.event.quit()
    end)
end

function ResultScene.unload()
	Music.pause()
end

function ResultScene.update(dt)
	Music.update()
    Button.update()
end

function ResultScene.draw()
    Background.draw()
    
    local width = WIN_W
    local height = WIN_H
    
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = 1, 100 do
        local x = (i * 131) % width
        local y = (i * 253) % height
        love.graphics.circle("fill", x, y, 1)
    end
    
    if not resultData then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(largeFont)
        love.graphics.printf("结算信息缺失", 0, height/2 - 100, width, "center")
        return
    end
    
    local title = resultData.completed and "完成！" or "游戏结束"
    local titleColor = resultData.completed and {0.3, 0.8, 0.3} or {0.9, 0.3, 0.3}
    
    love.graphics.setColor(titleColor[1], titleColor[2], titleColor[3], 1)
    love.graphics.setFont(largeFont)
    love.graphics.printf(title, 0, 100, width, "center")
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(mediumFont)
    
    local infoY = 220
    local lineHeight = 50
    
    if resultData.score then
        love.graphics.printf(string.format("分数: %d", resultData.score), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.totalLines then
        love.graphics.printf(string.format("消除行数: %d", resultData.totalLines), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.piecesPlaced then
        love.graphics.printf(string.format("放置方块: %d", resultData.piecesPlaced), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.gameTimer then
        local minutes = math.floor(resultData.gameTimer / 60)
        local seconds = math.floor(resultData.gameTimer % 60)
        local milliseconds = math.floor((resultData.gameTimer * 1000) % 1000)
        local timeText = string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
        love.graphics.printf(string.format("游戏时间: %s", timeText), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.pps and resultData.pps > 0 then
        love.graphics.printf(string.format("PPS: %.2f", resultData.pps), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.maxBtbCount and resultData.maxBtbCount > 0 then
        love.graphics.printf(string.format("最大连击: %d", resultData.maxBtbCount), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.maxCombo and resultData.maxCombo > 0 then
        love.graphics.printf(string.format("最大COMBO: %d", resultData.maxCombo), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    if resultData.modeName and resultData.modeName ~= "" then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.setFont(smallFont)
        love.graphics.printf(string.format("模式: %s", resultData.modeName), 0, infoY + 30, width, "center")
    end
    
    Button.drawAll()
end

function ResultScene.keypressed(key)
    if key == "escape" then
        SFX.play("back")
        Scene.switch("select")
    elseif isKeyPressed("restart", key) then
        SFX.play("confirm")
		restartGame()
	end
end

function ResultScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    Button.checkPress(x, y, button)
end

function ResultScene.mousereleased(x, y, button)
    if button ~= 1 then return end
    Button.checkRelease(x, y, button)
end

return ResultScene