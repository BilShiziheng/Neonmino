-- scenes/result.lua
local ResultScene = {}

-- 引入必要的模块
local Scene = require("core.scene")
local SFX = require("core.sfx")
local Music = require("core.music")

-- 场景变量
local resultData = nil  -- 存储结算数据

-- 按钮定义
local buttons = {}
local buttonWidth = 250
local buttonHeight = 60
local buttonSpacing = 30

-- 设置结算数据
function ResultScene.setResult(data)
    resultData = data
end

-- 场景加载
function ResultScene.load()
    -- 停止游戏音乐
    Music.stop()
    
    -- 播放结算音效
    if resultData and resultData.completed then
        SFX.play("finished")
    else
        SFX.play("gameover")
    end
    
    -- 定义按钮
    buttons = {
        {
            label = "重试",
            action = function()
                -- 重新开始当前模式
                local modeConfig = resultData and resultData.modeConfig
                if modeConfig then
                    _G.currentModeConfig = modeConfig
                    Scene.switch("game")
                else
                    Scene.switch("select")
                end
            end
        },
        {
            label = "返回模式选择",
            action = function()
                Scene.switch("select")
            end
        },
    }
end

function ResultScene.unload()
    resultData = nil
end

function ResultScene.update(dt)
    -- 可以添加一些动画效果
end

function ResultScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local width = love.graphics.getWidth()
    local totalHeight = #buttons * (buttonHeight + buttonSpacing) - buttonSpacing
    local startY = 500
    
    for i, btn in ipairs(buttons) do
        local bx = (width - buttonWidth) / 2
        local by = startY + (i-1) * (buttonHeight + buttonSpacing)
        
        if x >= bx and x <= bx + buttonWidth and 
           y >= by and y <= by + buttonHeight then
            btn.action()
            SFX.play("select")
            return
        end
    end
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
    
    -- 标题（完成/游戏结束）
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
    
    -- 分数
    if resultData.score then
        love.graphics.printf(string.format("分数: %d", resultData.score), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    -- 消除行数
    if resultData.totalLines then
        love.graphics.printf(string.format("消除行数: %d", resultData.totalLines), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    -- 放置方块数
    if resultData.piecesPlaced then
        love.graphics.printf(string.format("放置方块: %d", resultData.piecesPlaced), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    -- 游戏时间
    if resultData.gameTimer then
        local minutes = math.floor(resultData.gameTimer / 60)
        local seconds = math.floor(resultData.gameTimer % 60)
        local milliseconds = math.floor((resultData.gameTimer * 1000) % 1000)
        local timeText = string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
        love.graphics.printf(string.format("游戏时间: %s", timeText), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    -- 平均每秒放置方块数
    if resultData.pps and resultData.pps > 0 then
        love.graphics.printf(string.format("PPS: %.2f", resultData.pps), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    -- 最大连击数
    if resultData.maxBtbCount and resultData.maxBtbCount > 0 then
        love.graphics.printf(string.format("最大连击: %d", resultData.maxBtbCount), 0, infoY, width, "center")
        infoY = infoY + lineHeight
    end
    
    -- 绘制按钮
    local totalHeight = #buttons * (buttonHeight + buttonSpacing) - buttonSpacing
    local startY = 500
    
    for i, btn in ipairs(buttons) do
        local bx = (width - buttonWidth) / 2
        local by = startY + (i-1) * (buttonHeight + buttonSpacing)
        
        -- 按钮背景
        love.graphics.setColor(0.3, 0.3, 0.4, 0.8)
        love.graphics.rectangle("fill", bx, by, buttonWidth, buttonHeight, 10)
        
        -- 按钮边框
        love.graphics.setColor(0.6, 0.6, 0.7, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by, buttonWidth, buttonHeight, 10)
        
        -- 按钮文字
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(mediumFont)
        love.graphics.printf(btn.label, bx, by + (buttonHeight - mediumFont:getHeight()) / 2, buttonWidth, "center")
    end
end

return ResultScene