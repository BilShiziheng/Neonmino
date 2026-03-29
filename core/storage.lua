-- core/storage.lua
local storage = {}

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
	assert(indent < 64, "tbl depth >= 64")
    local str = "{"
    local first = true
    for k, v in pairs(tbl) do
        if not first then str = str .. "," else first = false end
        str = str .. "\n" .. string.rep("  ", indent + 1)
        if type(k) == "string" then
            str = str .. "[" .. string.format("%q", k) .. "] = "
        else
            str = str .. "[" .. tostring(k) .. "] = "
        end
        if type(v) == "table" then
            str = str .. serialize(v, indent + 1)
        elseif type(v) == "string" then
            str = str .. string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" or type(v) == "nil" then
            str = str .. tostring(v)
        else
            str = str .. tostring(v)
        end
    end
    str = str .. "\n" .. string.rep("  ", indent) .. "}"
    return str
end

local readedFiles = {}

function storage.load(path, default)
	if readedFiles[path] then
		return readedFiles[path]
	end
	local file = {}
    if love.filesystem.getInfo(path) then
        local chunk = love.filesystem.load(path)
        if chunk then
            local ok, loaded = pcall(chunk)
            if ok and type(loaded) == "table" then
                file = loaded
			end
        end
    end
	fallbackMerge(file, default)
	readedFiles[path] = file
    return readedFiles[path]
end

function storage.save(path)
    local data = "return " .. serialize(readedFiles[path])
    love.filesystem.write(path, data)
end

function storage.saveAll(path)
	for path, _ in pairs(readedFiles) do
		storage.save(path)
	end
end

return storage