-- scenes/result.lua
local ResultScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Music = require("core.music")
local Button = require("core.button")

local resultData = nil
local btnRetry, btnSelect

function ResultScene.setResult(data)
    resultData = data
end

function ResultScene.load()
    Music.stop()
    
    if resultData and resultData.completed then
        SFX.play("finished")
    else
        SFX.play("gameover")
    end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local centerX = width / 2
    local startY = height / 2 + 80
    local btnWidth = 250
    local btnHeight = 60
    local spacing = 30
    
    Button.clear()
    
    btnRetry = Button.create(centerX - btnWidth/2, startY, btnWidth, btnHeight, "重试", function()
        if resultData and resultData.modeConfig then
            _G.currentModeConfig = resultData.modeConfig
            Scene.switch("game")
        else
            Scene.switch("select")
        end
    end)
    
    btnSelect = Button.create(centerX - btnWidth/2, startY + btnHeight + spacing, btnWidth, btnHeight, "玩玩别的", function()
        Scene.switch("select")
    end)
end

function ResultScene.update(dt)
    Button.update()
end

function ResultScene.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- 装饰星星
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
    
    -- 标题
    local title = resultData.completed and "完成！" or "游戏结束"
    local titleColor = resultData.completed and {0.3, 0.8, 0.3} or {0.9, 0.3, 0.3}
    
    love.graphics.setColor(titleColor[1], titleColor[2], titleColor[3], 1)
    love.graphics.setFont(largeFont)
    love.graphics.printf(title, 0, 100, width, "center")
    
    -- 统计信息
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

    -- 绘制按钮
    Button.drawAll()
end

function ResultScene.keypressed(key)
    if key == "escape" then
        SFX.play("back")
        Scene.switch("select")
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