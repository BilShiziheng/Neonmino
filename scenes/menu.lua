-- scenes/menu.lua
local MenuScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Button = require("core.button")
local Ticker = require("core.ticker")
local Version = require("core.version")
local Background = require("core.background")
local Music = require("core.music").createEnv("main")

local btnStart, btnSettings, btnExit
local logoImage = nil
local logoLoaded = false

local tickerRect = { x = 0, y = 0, w = 0, h = 0 }

function MenuScene.load()
	Music.play()

    local success, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    if success then
        logoImage = img
        logoLoaded = true
    end
    
    local width = WIN_W
    local height = WIN_H
    
    tickerRect.w = 950
    tickerRect.h = 50
    tickerRect.x = (width - tickerRect.w) / 2
    tickerRect.y = height - 100
    
    Ticker.init(tickerRect.w, tickerRect.x)
    
    local centerX = width / 2
    local startY = height / 2 + 50
    local btnWidth = 250
    local btnHeight = 60
    local spacing = 30
    
    Button.clear()
    
    btnStart = Button.create(centerX - btnWidth/2, startY, btnWidth, btnHeight, "开始游戏", function()
        SFX.play("confirm")
        Scene.switch("select")
    end)
    
    btnSettings = Button.create(centerX - btnWidth/2, startY + btnHeight + spacing, btnWidth, btnHeight, "设置", function()
        SFX.play("select")
        local SettingsScene = require("scenes.settings")
        SettingsScene.setReturnScene("menu")
        Scene.switch("settings")
    end)
    
    btnExit = Button.create(centerX - btnWidth/2, startY + (btnHeight + spacing) * 2, btnWidth, btnHeight, "退出游戏", function()
        SFX.play("back")
        love.event.quit()
    end)
end

function MenuScene.unload(to)
	if to ~= "splash" and to ~= "menu" and to ~= "select" then
		Music.stop()
	end
end

function MenuScene.update(dt)
    Button.update()
    Ticker.update(dt)
end

function MenuScene.draw()
    Background.draw()
    
    local width = WIN_W
    local height = WIN_H
    local centerX = width / 2
    
    if logoLoaded and logoImage then
        local imgW = logoImage:getWidth()
        local imgH = logoImage:getHeight()
        local scale = math.min(width / imgW * 0.5, 150 / imgH)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(logoImage, centerX, 80, 0, scale, scale, imgW/2, 0)
    else
        love.graphics.setFont(largeFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Neonmino", 0, 80, width, "center")
    end
    
    love.graphics.setFont(mediumFont)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local versionText = Version.number
    local versionWidth = mediumFont:getWidth(versionText)
    love.graphics.print(versionText, centerX - versionWidth / 2, 200)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tickerRect.x, tickerRect.y, tickerRect.w, tickerRect.h, 8)
    
    love.graphics.setScissor(tickerRect.x, tickerRect.y, tickerRect.w, tickerRect.h)
    
    local segments = Ticker.getCurrentSegments()
    local scrollX = Ticker.getScrollX()
    local textY = tickerRect.y + (tickerRect.h - mediumFont:getHeight()) / 2
    local currentX = tickerRect.x + scrollX
    
    for _, seg in ipairs(segments) do
        local font = mediumFont
        local scale = seg.scale
        local color = seg.color
        local bold = seg.bold
        
        if scale ~= 1 then
            love.graphics.push()
            love.graphics.translate(currentX, textY)
            love.graphics.scale(scale, scale)
            if color then
                love.graphics.setColor(color[1], color[2], color[3], 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.setFont(font)
            
            if bold then
                love.graphics.print(seg.text, 1, 0)
                love.graphics.print(seg.text, 0, 1)
                love.graphics.print(seg.text, 0, 0)
            else
                love.graphics.print(seg.text, 0, 0)
            end
            love.graphics.pop()
            
            local w = font:getWidth(seg.text)
            if bold then w = w + 1 end
            currentX = currentX + w * scale
        else
            if color then
                love.graphics.setColor(color[1], color[2], color[3], 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.setFont(font)
            
            if bold then
                love.graphics.print(seg.text, currentX + 1, textY)
                love.graphics.print(seg.text, currentX, textY + 1)
                love.graphics.print(seg.text, currentX, textY)
            else
                love.graphics.print(seg.text, currentX, textY)
            end
            
            local w = font:getWidth(seg.text)
            if bold then w = w + 1 end
            currentX = currentX + w
        end
    end
    
    love.graphics.setScissor()
    
    Button.drawAll()
end

function MenuScene.keypressed(key)
    if key == "return" or key == "space" then
        local btn = Button.get(btnStart)
        if btn and btn.action then
            btn.action()
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

function MenuScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    Button.checkPress(x, y, button)
end

function MenuScene.mousereleased(x, y, button)
    if button ~= 1 then return end
    Button.checkRelease(x, y, button)
end

return MenuScene