-- scenes/settings/video.lua
local VideoScene = {}

local Settings = require("core.settings")
local SFX = require("core.sfx")

local currentSettings = nil
local selected = 1

-- 分辨率选项
local resolutions = {
    { name = "1280x720", width = 1280, height = 720 },
    { name = "1366x768", width = 1366, height = 768 },
    { name = "1600x900", width = 1600, height = 900 },
    { name = "1920x1080", width = 1920, height = 1080 },
}

-- 画面参数列表
local videoItems = {
    { name = "分辨率", key = "resolution", type = "select", options = resolutions, value = 2 },
    { name = "全屏模式", key = "fullscreen", type = "toggle", value = false },
    { name = "垂直同步", key = "vsync", type = "toggle", value = true },
}

local startX = 500
local startY = 40
local lineHeight = 60

function VideoScene.load()
    currentSettings = Settings.load()
    selected = 1
    
    -- 加载保存的分辨率索引
    if currentSettings.resolutionIndex then
        for i, item in ipairs(videoItems) do
            if item.key == "resolution" then
                item.value = currentSettings.resolutionIndex
                break
            end
        end
    end
    
    -- 加载全屏设置
    for i, item in ipairs(videoItems) do
        if item.key == "fullscreen" then
            item.value = currentSettings.fullscreen or false
        elseif item.key == "vsync" then
            item.value = currentSettings.vsync or true
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
        
        love.graphics.setColor(1, 1, 1, 1)
        
        if item.type == "select" then
            local res = item.options[item.value + 1]
            love.graphics.print(item.name .. ": " .. res.name, x, y)
            -- 左右箭头提示
            love.graphics.setColor(0.6, 0.6, 0.8, 1)
            love.graphics.print("<  >", x + 250, y)
        elseif item.type == "toggle" then
            local status = item.value and "✓ 开" or "□ 关"
            love.graphics.print(item.name .. ": " .. status, x, y)
        end
        
        y = y + lineHeight
    end
end

function VideoScene.keypressed(key)
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #videoItems end
        SFX.play("select")
    elseif key == "down" then
        selected = selected + 1
        if selected > #videoItems then selected = 1 end
        SFX.play("select")
    elseif key == "left" then
        local item = videoItems[selected]
        if item.type == "select" then
            item.value = item.value - 1
            if item.value < 0 then item.value = #item.options - 1 end
            currentSettings.resolutionIndex = item.value
            local res = item.options[item.value + 1]
            currentSettings.resolution = { width = res.width, height = res.height }
            Settings.save(currentSettings)
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
            Settings.save(currentSettings)
            SFX.play("move")
        end
    elseif key == "right" then
        local item = videoItems[selected]
        if item.type == "select" then
            item.value = item.value + 1
            if item.value >= #item.options then item.value = 0 end
            currentSettings.resolutionIndex = item.value
            local res = item.options[item.value + 1]
            currentSettings.resolution = { width = res.width, height = res.height }
            Settings.save(currentSettings)
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
            Settings.save(currentSettings)
            SFX.play("move")
        end
    end
end

function VideoScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    local yPos = startY
    for i, item in ipairs(videoItems) do
        if y >= yPos and y <= yPos + lineHeight then
            selected = i
            SFX.play("select")
            
            -- 点击时切换 toggle 类型的选项
            if item.type == "toggle" then
                item.value = not item.value
                if item.key == "fullscreen" then
                    currentSettings.fullscreen = item.value
                    love.window.setFullscreen(item.value)
                elseif item.key == "vsync" then
                    currentSettings.vsync = item.value
                    love.window.setVSync(item.value)
                end
                Settings.save(currentSettings)
                SFX.play("move")
            end
            return
        end
        yPos = yPos + lineHeight
    end
end

function VideoScene.mousemoved(x, y, dx, dy) end
function VideoScene.mousereleased(x, y, button) end

return VideoScene