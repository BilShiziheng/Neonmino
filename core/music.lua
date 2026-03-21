-- core/music.lua
-- 音乐管理模块，支持随机播放多个曲目并显示信息（数据从 music_data 导入）

local music = {}

local tracks = {}           -- 曲目列表
local currentTrack = nil    -- 当前播放的曲目
local currentSource = nil   -- Love2D 音频源
local currentIndex = nil    -- 当前索引
local masterVolume = 1.0    -- 全局音量

-- 添加一首曲目
function music.addTrack(filename, title, artist, source)
    table.insert(tracks, {
        filename = filename,
        title = title,
        artist = artist,
        source = source or "Unknown"
    })
end

-- 初始化曲目库
function music.init()
    local data = require("core.music_data")
    for _, track in ipairs(data) do
        music.addTrack(track.filename, track.title, track.artist, track.source)
    end
end

-- 随机选择一首曲目
function music.pickRandom()
    if #tracks == 0 then return nil end
    local idx = math.random(1, #tracks)
    return tracks[idx], idx
end

-- 播放指定的曲目
function music.playTrack(track, idx)
    if not track then return false end
    -- 停止并清除当前播放
    if currentSource then
        pcall(function() currentSource:stop() end)
        currentSource = nil
        currentTrack = nil
    end
    local path = "assets/music/" .. track.filename
    local success, source = pcall(love.audio.newSource, path, "stream")
    if success and source then
        currentSource = source
        currentTrack = track
        currentIndex = idx or 1
        currentSource:setLooping(false)
        currentSource:setVolume(masterVolume)
        currentSource:play()
        return true
    else
        print("Warning: Could not load music file: " .. path)
        return false
    end
end

-- 开始随机播放
function music.play()
    if #tracks == 0 then return false end
    local attempts = 0
    while attempts < #tracks do
        local track, idx = music.pickRandom()
        if music.playTrack(track, idx) then
            return true
        end
        attempts = attempts + 1
    end
    print("Error: No playable music tracks found.")
    return false
end

-- 停止播放
function music.stop()
    if currentSource then
        pcall(function() currentSource:stop() end)
        currentSource = nil
        currentTrack = nil
    end
end

-- 更新函数，检测音乐结束并自动下一首
function music.update()
    if currentSource then
        -- 检查是否已停止（使用 pcall 防止错误）
        local ok, stopped = pcall(function() return currentSource:isStopped() end)
        if ok and stopped then
            -- 当前曲目已结束，播放下一首
            music.play()
        end
    else
        -- 没有播放中的音乐，尝试开始播放
        music.play()
    end
end

-- 获取当前曲目信息
function music.getCurrentTrack()
    return currentTrack
end

-- 设置音量 (0-1)
function music.setVolume(volume)
    masterVolume = math.max(0, math.min(1, volume))
    if currentSource then
        currentSource:setVolume(masterVolume)
    end
end

-- 获取当前音量
function music.getVolume()
    return masterVolume
end

return music