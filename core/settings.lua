-- core/settings.lua
local settings = {}

local Storage = require("core.storage")

local defaultSettings = {
    das = 10,
    arr = 2,
    sdf = 6,
    lockDelay = 30,
    musicVolume = 80,
    sfxVolume = 80,
    resolutionIndex = 2,
    fullscreen = false,
	resolution = {width = 1600, height = 900},
    vsync = true,
    background = "solid",
    keys = {
        left = {"left", ""},
        right = {"right", ""},
        softDrop = {"down", ""},
        rotateCW = {"up", "x"},
        rotateCCW = {"z", ""},
        rotate180 = {"a", ""},
        hardDrop = {"space", ""},
        hold = {"c", "shift"},
        restart = {"r", ""},
    }
}

local currentSettings = nil
local configPath = "settings.lua"

function settings.load()
	if currentSettings == nil then
		currentSettings = Storage.load(configPath, defaultSettings)
	end
	return currentSettings
end

function settings.save()
	return Storage.save(configPath)
end

function settings.getDefault()
    return defaultSettings
end

--	Is it really useful?
function settings.set(settingsTable)
    currentSettings = settingsTable
    settings.save()
end

return settings