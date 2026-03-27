-- core/settings.lua
local settings = {}

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

local function fallbackMerge(t, other)
    for k, v in pairs(other) do
        if type(v) == "table" then
			if type(t[k]) ~= "table" then
            	t[k] = {}
			end
            fallbackMerge(t[k], v)
        elseif type(v) ~= type(t[k]) then
            t[k] = v
        end
    end
    return t
end

local function serialize(tbl, indent)
    indent = indent or 0
    local str = "{"
    local first = true
    for k, v in pairs(tbl) do
        if not first then str = str .. "," else first = false end
        str = str .. "\n" .. string.rep(" ", indent + 2)
        if type(k) == "string" then
            str = str .. "[" .. string.format("%q", k) .. "] = "
        else
            str = str .. "[" .. tostring(k) .. "] = "
        end
        if type(v) == "table" then
            str = str .. serialize(v, indent + 2)
        elseif type(v) == "string" then
            str = str .. string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" or type(v) == "nil" then
            str = str .. tostring(v)
        else
            str = str .. tostring(v)
        end
    end
    str = str .. "\n" .. string.rep(" ", indent) .. "}"
    return str
end

local fileReaded = false
local currentSettings = {}
local configPath = "settings.lua"

function settings.load()
	if fileReaded then
		return currentSettings
	end
    if love.filesystem.getInfo(configPath) then
        local chunk = love.filesystem.load(configPath)
        if chunk then
            local ok, loaded = pcall(chunk)
            if ok and type(loaded) == "table" then
                currentSettings = loaded
            end
        end
    end
	fileReaded = true
	fallbackMerge(currentSettings, defaultSettings)
    settings.save()
    return currentSettings
end

function settings.save()
    local data = "return " .. serialize(currentSettings)
    love.filesystem.write(configPath, data)
end

function settings.get()
    return currentSettings or defaultSettings
end

function settings.getDefault()
    return defaultSettings
end

function settings.set(settingsTable)
    currentSettings = settingsTable
    settings.save()
end

return settings