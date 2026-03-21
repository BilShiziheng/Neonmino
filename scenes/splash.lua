-- scenes/splash.lua
local SplashScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Music = require("core.music")
local Settings = require("core.settings")
local Version = require("core.version")

local logoImage = nil
local logoLoaded = false

-- 加载状态
local loadingProgress = 0
local loadingText = "正在加载..."
local loadingSteps = {
    { name = "加载设置", func = function() Settings.load() end },
    { name = "加载音效", func = function() SFX.load() end },
    { name = "加载音乐", func = function() Music.init() end },
    { name = "准备就绪", func = function() end },
}
local currentStep = 1
local isLoading = true
local showPrompt = false
local fadeOutProgress = false
local fadeTimer = 0
local fadeDuration = 0.5
local waitTimer = 0
local waitDuration = 2.0
local progressAlpha = 1
local promptAlpha = 0
local logoAlpha = 0
local logoFadeTimer = 0
local logoFadeDuration = 0.5

-- 根据时间获取颜色
local function getTimeColor()
    local hour = tonumber(os.date("%H"))
    if hour >= 5 and hour < 8 then
        return {1, 0.7, 0.3}
    elseif hour >= 8 and hour < 12 then
        return {1, 0.85, 0.2}
    elseif hour >= 12 and hour < 17 then
        return {0.3, 0.7, 1}
    elseif hour >= 17 and hour < 19 then
        return {1, 0.5, 0.2}
    elseif hour >= 19 and hour < 22 then
        return {0.8, 0.4, 1}
    else
        return {0.5, 0.7, 1}
    end
end

-- 绘制空心描边文字
local function drawHollowText(text, x, y, color, font)
    love.graphics.setFont(font)
    
    -- 描边（8方向）
    for dx = -2, 2 do
        for dy = -2, 2 do
            if math.abs(dx) + math.abs(dy) <= 2 and (dx ~= 0 or dy ~= 0) then
                love.graphics.setColor(color[1], color[2], color[3], 1)
                love.graphics.print(text, x + dx, y + dy)
            end
        end
    end
    
    -- 空心内部（黑色）
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(text, x, y)
end

function SplashScene.load()
    currentStep = 1
    loadingProgress = 0
    isLoading = true
    showPrompt = false
    fadeOutProgress = false
    fadeTimer = 0
    waitTimer = 0
    progressAlpha = 1
    promptAlpha = 0
    logoAlpha = 0
    logoFadeTimer = 0
    
    local success, img = pcall(love.graphics.newImage, "assets/images/logo.png")
    if success then
        logoImage = img
        logoLoaded = true
    else
        logoLoaded = false
    end
end

function SplashScene.update(dt)
    if isLoading then
        if logoAlpha < 1 then
            logoFadeTimer = logoFadeTimer + dt
            logoAlpha = math.min(1, logoFadeTimer / logoFadeDuration)
        end
        
        if currentStep <= #loadingSteps then
            local step = loadingSteps[currentStep]
            loadingText = step.name
            
            local success, err = pcall(step.func)
            if not success then
                print("加载失败: " .. step.name .. " - " .. tostring(err))
            end
            
            currentStep = currentStep + 1
            loadingProgress = (currentStep - 1) / #loadingSteps
        else
            isLoading = false
            waitTimer = 0
        end
    elseif not showPrompt then
        waitTimer = waitTimer + dt
        if waitTimer >= waitDuration then
            fadeOutProgress = true
        end
        
        if fadeOutProgress then
            fadeTimer = fadeTimer + dt
            progressAlpha = 1 - (fadeTimer / fadeDuration)
            if fadeTimer >= fadeDuration then
                fadeOutProgress = false
                showPrompt = true
                fadeTimer = 0
            end
        end
    elseif showPrompt then
        fadeTimer = fadeTimer + dt
        promptAlpha = math.min(1, fadeTimer / fadeDuration)
    end
end

function SplashScene.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local centerX = width / 2
    local timeColor = getTimeColor()
    
    -- 背景
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Logo
    love.graphics.setColor(1, 1, 1, logoAlpha)
    if logoLoaded and logoImage then
        local imgW = logoImage:getWidth()
        local imgH = logoImage:getHeight()
        local scale = math.min(width / imgW * 0.6, height / imgH * 0.5)
        love.graphics.draw(logoImage, centerX, height/2 - 100, 0, scale, scale, imgW/2, imgH/2)
    else
        love.graphics.setFont(largeFont)
        love.graphics.printf(Version.name, 0, height/2 - 120, width, "center")
    end
    
    -- "Based on LOVE2D" 空心描边，使用 largeFont
    local text = "Based on LOVE2D"
    local textWidth = largeFont:getWidth(text)
    local textX = centerX - textWidth / 2
    local textY = height/2 + 50
    
    drawHollowText(text, textX, textY, timeColor, largeFont)
    
    -- 进度条
    if not showPrompt then
        local barWidth = 400
        local barHeight = 8
        local barX = (width - barWidth) / 2
        local barY = height - 150
        
        love.graphics.setColor(0.3, 0.3, 0.4, progressAlpha)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4)
        
        local fillWidth = barWidth * loadingProgress
        love.graphics.setColor(0.6, 0.8, 1, progressAlpha)
        love.graphics.rectangle("fill", barX, barY, fillWidth, barHeight, 4)
        
        love.graphics.setFont(mediumFont)
        love.graphics.setColor(1, 1, 1, progressAlpha)
        love.graphics.printf(loadingText, 0, barY - 35, width, "center")
        
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.7, 0.7, 0.7, progressAlpha)
        love.graphics.printf(string.format("%d%%", math.floor(loadingProgress * 100)), 0, barY - 60, width, "center")
    end
    
    -- 按任意键开始
    if showPrompt then
        love.graphics.setColor(1, 1, 1, promptAlpha)
        love.graphics.setFont(mediumFont)
        love.graphics.printf("按任意键开始", 0, height - 100, width, "center")
    end
end

function SplashScene.keypressed(key)
    if showPrompt then
        SFX.play("confirm")
        Scene.switch("menu")
    end
end

function SplashScene.mousepressed(x, y, button)
    if showPrompt then
        SFX.play("confirm")
        Scene.switch("menu")
    end
end

return SplashScene