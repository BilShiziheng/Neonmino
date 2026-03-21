-- core/discord.lua
local discord = {}
local Version = require("core.version")

local enabled = false

function discord.init()
    -- 如果支持 Discord Rich Presence
    if love.discord then
        enabled = true
        love.discord.setPresence({
            state = "在主菜单",
            details = Version.getStatusText(),
            largeImageKey = "logo",
            largeImageText = Version.name,
            startTimestamp = os.time()
        })
    end
end

function discord.setPlaying(modeName)
    if enabled then
        love.discord.setPresence({
            state = "游戏中",
            details = modeName,
            largeImageKey = "logo",
            largeImageText = Version.name,
            startTimestamp = os.time()
        })
    end
end

function discord.setMenu()
    if enabled then
        love.discord.setPresence({
            state = "在主菜单",
            details = Version.getStatusText(),
            largeImageKey = "logo",
            largeImageText = Version.name,
            startTimestamp = os.time()
        })
    end
end

function discord.setSettings()
    if enabled then
        love.discord.setPresence({
            state = "在设置中",
            details = Version.getStatusText(),
            largeImageKey = "logo",
            largeImageText = Version.name,
            startTimestamp = os.time()
        })
    end
end

return discord