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
    
    -- 尝试加载Logo图片
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
        -- 执行加载步骤
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
            -- 加载完成，开始等待
            isLoading = false
            waitTimer = 0
        end
    elseif not showPrompt then
        -- 等待2秒后开始淡出进度条
        waitTimer = waitTimer + dt
        if waitTimer >= waitDuration then
            fadeOutProgress = true
        end
        
        -- 进度条淡出
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
        -- 提示文字淡入
        fadeTimer = fadeTimer + dt
        promptAlpha = math.min(1, fadeTimer / fadeDuration)
    end
end

function SplashScene.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- 黑色背景
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- 绘制Logo
    love.graphics.setColor(1, 1, 1, 1)
    if logoLoaded and logoImage then
        local imgW = logoImage:getWidth()
        local imgH = logoImage:getHeight()
        local scale = math.min(width / imgW * 0.6, height / imgH * 0.5)
        love.graphics.draw(logoImage, width/2, height/2 - 100, 0, scale, scale, imgW/2, imgH/2)
    else
        love.graphics.setFont(largeFont)
        love.graphics.printf(Version.name, 0, height/2 - 120, width, "center")
        love.graphics.setFont(mediumFont)
        love.graphics.printf(Version.subtitle, 0, height/2 - 60, width, "center")
    end
    
    -- 加载进度条（带淡出效果）
    if not showPrompt then
        love.graphics.setColor(1, 1, 1, progressAlpha)
        local barWidth = 400
        local barHeight = 8
        local barX = (width - barWidth) / 2
        local barY = height - 150
        love.graphics.setColor(0.3, 0.3, 0.4, progressAlpha)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4)
        
        local fillWidth = barWidth * loadingProgress
        love.graphics.setColor(0.6, 0.8, 1, progressAlpha)
        love.graphics.rectangle("fill", barX, barY, fillWidth, barHeight, 4)
        
        -- 加载文字
        love.graphics.setFont(mediumFont)
        love.graphics.setColor(1, 1, 1, progressAlpha)
        love.graphics.printf(loadingText, 0, barY - 35, width, "center")
        
        -- 百分比
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.7, 0.7, 0.7, progressAlpha)
        love.graphics.printf(string.format("%d%%", math.floor(loadingProgress * 100)), 0, barY - 60, width, "center")
    end
    
    -- 按任意键开始（淡入）
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