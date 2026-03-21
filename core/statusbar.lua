-- core/statusbar.lua
local statusbar = {}

local Version = require("core.version")
local loveVersion = love._version or "LOVE"

-- 获取操作系统
local function getOS()
    local osName = love.system.getOS()
    if osName == "Windows" then return "Win"
    elseif osName == "OS X" then return "macOS"
    elseif osName == "Linux" then return "Linux"
    elseif osName == "Android" then return "Android"
    elseif osName == "iOS" then return "iOS"
    else return osName end
end

-- 获取FPS
local fps = 0
local fpsTimer = 0
local fpsCounter = 0

function statusbar.update(dt)
    -- 计算FPS
    fpsCounter = fpsCounter + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 0.5 then
        fps = fpsCounter / fpsTimer
        fpsCounter = 0
        fpsTimer = 0
    end
end

function statusbar.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local bottomY = height - 25  -- 距离底部25像素
    
    local osName = getOS()
    local versionStr = Version.number
    local fpsStr = string.format("FPS: %.0f", fps)
    
    local infoText = osName .. " | " .. versionStr .. " | " .. fpsStr
    
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    local textWidth = smallFont:getWidth(infoText)
    love.graphics.print(infoText, (width - textWidth) / 2, bottomY)
end

return statusbar