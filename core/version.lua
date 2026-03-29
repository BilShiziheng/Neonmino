-- core/version.lua
local version = {}

version.name = "Neonmino"
version.number = "Alpha v0.6.5"
version.subtitle = "Based on Love2D"
version.build = "2026.03.29"

-- 获取完整标题
function version.getTitle()
    return version.name .. " " .. version.number
end

-- 获取显示文本
function version.getDisplayText()
    return version.name .. " " .. version.number .. " - " .. version.subtitle
end

-- 获取状态栏文本（用于Discord等）
function version.getStatusText()
    return version.name .. " " .. version.number
end

return version