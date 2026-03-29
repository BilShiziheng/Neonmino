-- scenes/settings/video.lua
local VideoScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")
local Background = require("core.background")

local currentSettings = nil
local selected = 1

local resolutions = {
    { name = "1280x720", width = 1280, height = 720 },
    { name = "1366x768", width = 1366, height = 768 },
    { name = "1600x900", width = 1600, height = 900 },
    { name = "1920x1080", width = 1920, height = 1080 },
}

local backgrounds = {"solid", "star", "cava", "blockrain"}
local bgNames = { 
    solid = "纯色", 
    star = "星空", 
    cava = "频谱",
    blockrain = "方块雨"
}
local videoItems = {
    { name = "分辨率", key = "resolution", type = "select", options = resolutions, value = 2 },
    { name = "全屏模式", key = "fullscreen", type = "toggle", value = false },
    { name = "垂直同步", key = "vsync", type = "toggle", value = true },
    { name = "背景", key = "background", type = "select", options = backgrounds, value = 1 },
}

local startX = 500
local startY = 20
local lineHeight = 60

-- 背景切换按钮的点击区域
local bgLeftRect = { x = 0, y = 0, w = 40, h = 40 }
local bgRightRect = { x = 0, y = 0, w = 40, h = 40 }

function VideoScene.load()
    currentSettings = Settings.load()
    selected = 0
    
    if currentSettings.resolutionIndex then
        for i, item in ipairs(videoItems) do
            if item.key == "resolution" then
                item.value = currentSettings.resolutionIndex
                break
            end
        end
    end
    
    for i, item in ipairs(videoItems) do
        if item.key == "fullscreen" then
            item.value = currentSettings.fullscreen or false
        elseif item.key == "vsync" then
            item.value = currentSettings.vsync or true
        elseif item.key == "background" then
            local bgName = currentSettings.background or "solid"
            for j, name in ipairs(backgrounds) do
                if name == bgName then
                    item.value = j - 1
                    break
                end
            end
        end
    end
end

function VideoScene.update(dt)
end

function VideoScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    for i, item in ipairs(videoItems) do
        local x = startX
        
        if i == selected then
            love.graphics.setColor(1, 1, 0.6, 1)
            love.graphics.print(">", x - 30, y)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        
        if item.type == "select" then
            local opt = item.options[item.value + 1]
            local displayName
            if type(opt) == "table" then
                displayName = opt.name
            else
                displayName = bgNames[opt] or opt
            end
            love.graphics.print(item.name .. ": " .. displayName, x, y)
            
            -- 为背景选项添加左右按钮
            if item.key == "background" then
                local btnX = x + 250
                local btnY = y + (lineHeight - 30) / 2  -- 与文字垂直对齐
                
                bgLeftRect.x = btnX
                bgLeftRect.y = btnY
                bgRightRect.x = btnX + 45
                bgRightRect.y = btnY
                
                -- 左按钮
                love.graphics.setColor(0.5, 0.5, 0.7, 0.8)
                love.graphics.rectangle("fill", bgLeftRect.x, bgLeftRect.y, 35, 30, 6)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print("<", bgLeftRect.x + 12, bgLeftRect.y + 5)
                
                -- 右按钮
                love.graphics.setColor(0.5, 0.5, 0.7, 0.8)
                love.graphics.rectangle("fill", bgRightRect.x, bgRightRect.y, 35, 30, 6)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(">", bgRightRect.x + 12, bgRightRect.y + 5)
            end
        elseif item.type == "toggle" then
            local status = item.value and "开" or "关"
            love.graphics.print(item.name .. ": " .. status, x, y)
        end
        
        y = y + lineHeight
    end
end

function VideoScene.keypressed(key)
    if key == "up" or key == "down" then
		local dir = key == "up" and -1 or 1
        selected = selected + dir
        if selected < 0 then selected = #videoItems end
        if selected > #videoItems then selected = 0 end
        SFX.play("select")
		return true
    elseif selected ~= 0 and (key == "left" or key == "right") then
        local item = videoItems[selected]
		local dir = key == "left" and -1 or 1
        if item.type == "select" then
            item.value = item.value + dir
            if item.value < 0 then item.value = #item.options - 1 end
            if item.value >= #item.options then item.value = 0 end
            if item.key == "resolution" then
                currentSettings.resolutionIndex = item.value
                local res = item.options[item.value + 1]
                currentSettings.resolution = { width = res.width, height = res.height }
            elseif item.key == "background" then
                local bgName = item.options[item.value + 1]
                currentSettings.background = bgName
                Background.setDefault(bgName)
            end
            Settings.save()
            SFX.play("move")
        elseif item.type == "toggle" then
            item.value = not item.value
            if item.key == "fullscreen" then
                currentSettings.fullscreen = item.value
                love.window.setFullscreen(item.value)
            elseif item.key == "vsync" then
                currentSettings.vsync = item.value
                love.window.setVSync(item.value)
            end
            Settings.save()
            SFX.play("move")
        end
		return true
    end
	return false
end

function VideoScene.mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    -- 先检测背景切换按钮
    if x >= bgLeftRect.x and x <= bgLeftRect.x + bgLeftRect.w and y >= bgLeftRect.y and y <= bgLeftRect.y + bgLeftRect.h then
        local item = videoItems[4]
        item.value = item.value - 1
        if item.value < 0 then item.value = #item.options - 1 end
        local bgName = item.options[item.value + 1]
        currentSettings.background = bgName
        Background.setDefault(bgName)
        Settings.save()
        SFX.play("move")
        return true
    end
    
    if x >= bgRightRect.x and x <= bgRightRect.x + bgRightRect.w and y >= bgRightRect.y and y <= bgRightRect.y + bgRightRect.h then
        local item = videoItems[4]
        item.value = item.value + 1
        if item.value >= #item.options then item.value = 0 end
        local bgName = item.options[item.value + 1]
        currentSettings.background = bgName
        Background.setDefault(bgName)
        Settings.save()
        SFX.play("move")
        return true
    end
    
    -- 检测选项行
    local yPos = startY
    for i, item in ipairs(videoItems) do
        if y >= yPos and y <= yPos + lineHeight then
            selected = i
            SFX.play("select")
            
            if item.type == "toggle" then
                item.value = not item.value
                if item.key == "fullscreen" then
                    currentSettings.fullscreen = item.value
                    love.window.setFullscreen(item.value)
                elseif item.key == "vsync" then
                    currentSettings.vsync = item.value
                    love.window.setVSync(item.value)
                end
                Settings.save()
                SFX.play("move")
            end
            return true
        end
        yPos = yPos + lineHeight
    end

	return false
end

function VideoScene.mousemoved(x, y, dx, dy) return false end
function VideoScene.mousereleased(x, y, button) return false end

return VideoScene