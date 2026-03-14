-- core/settings.lua
local settings = {}

local defaultSettings = {
    keys = {
        left = "q",
        right = "e",
        softDrop = "w",
        rotateCW = "p",
        rotateCCW = "o",
        rotate180 = "i",
        hardDrop = "space",
        hold = "lalt",
    },
    das = 10,      -- 帧数
    arr = 2,       -- 帧数
}

local userSettings = {}

local function merge(t, other)
    for k, v in pairs(other) do
        if type(v) == "table" then
            t[k] = t[k] or {}
            merge(t[k], v)
        else
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
        if not first then str = str .. "," end
        first = false
        str = str .. "\n" .. string.rep(" ", indent + 2)
        if type(k) == "string" then
            str = str .. "[\"" .. k .. "\"] = "
        else
            str = str .. "[" .. tostring(k) .. "] = "
        end
        if type(v) == "table" then
            str = str .. serialize(v, indent + 2)
        elseif type(v) == "string" then
            str = str .. "\"" .. v .. "\""
        elseif type(v) == "boolean" then
            str = str .. tostring(v)
        else
            str = str .. tostring(v)
        end
    end
    str = str .. "\n" .. string.rep(" ", indent) .. "}"
    return str
end

function settings.load()
    local success, chunk = pcall(love.filesystem.load, "settings.lua")
    if success and chunk then
        local loaded = chunk()
        if type(loaded) == "table" then
            userSettings = loaded
        end
    else
        -- 文件不存在或加载失败，使用空表
        userSettings = {}
    end
    merge(defaultSettings, userSettings)
    return defaultSettings
end

function settings.save(data)
    local str = "return " .. serialize(data)
    love.filesystem.write("settings.lua", str)
end

return settings