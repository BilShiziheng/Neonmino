-- core/settings.lua
local settings = {}

defaultSettings = {
    das = 10,        -- DAS 10帧
    arr = 2,         -- ARR 2帧
    sdf = 6,         -- SDF 6倍（6X）
    lockDelay = 30,
    musicVolume = 80,
    sfxVolume = 80,
    resolutionIndex = 2,
    fullscreen = false,
    vsync = true,
    keys = {
        left = {"left"},
        right = {"right"},
        softDrop = {"down"},
        rotateCW = {"up", "z"},
        rotateCCW = {"x"},
        rotate180 = {"a"},
        hardDrop = {"space"},
        hold = {"c", "shift"},
        restart = {"r"},
    }
}

-- 检查按键是否匹配
function settings.isKeyPressed(action, key)
    local keys = settings.get().keys[action]
    if type(keys) == "table" then
        for _, k in ipairs(keys) do
            if k == key then return true end
        end
    elseif keys == key then
        return true
    end
    return false
end

-- 获取按键显示文本
function settings.getKeyDisplay(action)
    local keys = settings.get().keys[action]
    if type(keys) == "table" then
        return table.concat(keys, " / ")
    end
    return keys or "无"
end

-- 添加按键绑定
function settings.addKey(action, key)
    local current = settings.get().keys[action]
    if type(current) == "table" then
        table.insert(current, key)
    else
        settings.get().keys[action] = {current, key}
    end
    settings.save()
end

-- 移除按键绑定
function settings.removeKey(action, key)
    local current = settings.get().keys[action]
    if type(current) == "table" then
        local new = {}
        for _, k in ipairs(current) do
            if k ~= key then
                table.insert(new, k)
            end
        end
        if #new == 1 then
            settings.get().keys[action] = new[1]
        elseif #new == 0 then
            settings.get().keys[action] = nil
        else
            settings.get().keys[action] = new
        end
    elseif current == key then
        settings.get().keys[action] = nil
    end
    settings.save()
end

-- ... 其他代码保持不变 ...

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
