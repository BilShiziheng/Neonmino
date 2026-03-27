-- core/music.lua
-- 音乐管理模块，支持随机播放多个曲目并显示信息（数据从 music_data 导入）

local music = {}

local Settings = require("core.settings")

local tracks = {}           -- 所有音乐
local tracklists = {}		-- 曲目列表
local allMusicEnvs = {}		-- 所有环境
local activeMusicEnv = nil	-- 正在活跃的环境
local currentPlayId = 0		-- 当前播放动作编号

local inited = false
local masterVolume = 1.0	-- 全局音量

-- 添加一首曲目
function music.addTrack(id, lists, filename, title, artist, source)
    table.insert(tracks, {
		id = id,
		lists = lists,
        filename = filename,
        title = title,
        artist = artist,
        source = source or "Unknown"
    })
	local index = #tracks
	for _, listname in ipairs(lists) do
		tracklists[listname] = tracklists[listname] or {}
		table.insert(tracklists[listname], index)
	end
end

-- 初始化曲目库
function music.init()
	if inited then return end
	inited = true
    local data = require("core.music_data")
    for _, track in ipairs(data) do
        music.addTrack(track.id, track.lists, track.filename, track.title, track.artist, track.source)
    end
	
	local currentSettings = Settings.load()
    masterVolume = (currentSettings.musicVolume or 80) / 100
end

function music.setVolume(volume)
	masterVolume = math.max(0, math.min(1, volume))
	activeMusicEnv.updateVolume()
end

local envId = 0

function music.createEnv(name)
	music.init()

	if allMusicEnvs[name] ~= nil then return allMusicEnvs[name] end

	local musicEnv = {}
	allMusicEnvs[name] = musicEnv

	local lastTime = love.timer.getTime()
	local currentList = nil		-- 当前的曲目列表
	local currentTrack = nil	-- 当前播放的曲目
	local currentPosition = 0	-- 当前播放时间戳
	local currentSource = nil	-- Love2D 音频源
	local currentIndex = nil	-- 当前索引
	local paused = true			-- 是否暂停

	local function updateTime()
		local newTime = love.timer.getTime()
		local dt = newTime - lastTime
		if not paused then
			currentPosition = currentPosition + dt
		end
		lastTime = newTime
	end

	local function activate()
	--	print("activate()", eid)
		if activeMusicEnv == nil then
			musicEnv.updateVolume()
			activeMusicEnv = musicEnv
		elseif activeMusicEnv ~= musicEnv then
			print("Warning: multi-active musicEnv occured")
		end
	end

	local function inactivate()
	--	print("inactivate()", eid)
		if activeMusicEnv == musicEnv then
			activeMusicEnv = nil
		elseif activeMusicEnv ~= nil then
			print("Warning: inactive musicEnv inactivate()-ed")
		end
	end

	-- 随机选择一首曲目
	local function pickRandom()
		if #currentList == 0 then return nil end
		local idx = currentList[math.random(1, #currentList)]
		return tracks[idx], idx
	end

	-- 播放指定的曲目
	local function playTrack(track, idx)
		if not track then return false end
		if track == currentTrack and idx == currentIdx then
			currentSource:stop()
			updateTime()
			currentPosition = 0
			activate()
			currentSource:play()
			return
		end
		-- 停止并清除当前播放
		if currentSource then
			pcall(function() currentSource:stop() end)
			currentSource = nil
			currentTrack = nil
			paused = true
		end
		local path = "assets/music/" .. track.filename
	--	print('load', path, track.title)
		local success, source = pcall(love.audio.newSource, path, "stream")
		if success and source then
			currentSource = source
			currentTrack = track
			currentIndex = idx or 1
			currentSource:setLooping(false)
			currentSource:setVolume(masterVolume)
			currentSource:stop()
			updateTime()
			currentPosition = 0
			activate()
			currentSource:play()
			paused = false
			return true
		else
			print("Warning: Could not load music file: " .. path)
			return false
		end
	end

	-- 设定音乐列表
	function musicEnv.setTracklist(listname)
		currentList = tracklists[listname] or {}
	end

	-- 开始随机播放
	function musicEnv.playNext()
		if #currentList == 0 then return false end
		local attempts = 0
		while attempts < 1 do
			local track, idx = pickRandom()
			if playTrack(track, idx) then
				currentPlayId = currentPlayId + 1
				return true
			end
			attempts = attempts + 1
		end
		paused = true
		print("Error: No playable music tracks found.")
		return false
	end

	-- 停止播放
	function musicEnv.stop()
		inactivate()
		if currentSource then
			pcall(function() currentSource:stop() end)
			updateTime()
			currentPosition = 0
			currentSource = nil
			currentTrack = nil
			paused = true
		end
	end

	-- 是否暂停
	function musicEnv.isPaused()
		return paused
	end

	-- 暂停播放
	function musicEnv.pause()
		if currentSource and not paused then
			inactivate()
			updateTime()
			pcall(function() currentSource:pause() paused = true end)
		end
	end

	-- 继续播放
	function musicEnv.play()
		if currentSource == nil then
			activate()
			musicEnv.playNext()
		elseif currentSource and paused then
			activate()
			updateTime()
			pcall(function() currentSource:play() paused = false end)
		end
	end

	-- 更新函数，检测音乐结束并自动下一首
	-- ? more?
	function musicEnv.update()
		updateTime()
		if paused then return end
		if currentSource then
			-- 检查是否到歌曲结尾（使用 pcall 防止错误）
			local ok, isPlaying = pcall(function() return currentSource:isPlaying() end)
			if ok and not isPlaying then
				-- 当前曲目已结束，播放下一首
				playTrack(currentTrack, currentIdx)
				-- musicEnv.playNext()
			end
		else
			-- 没有播放中的音乐，尝试开始播放
			musicEnv.playNext()
		end
	end

	-- 获取当前曲目信息
	function musicEnv.getCurrentTrack()
		return currentTrack
	end

	-- 获取当前播放动作编号
	function musicEnv.getCurrentPlayId()
		return currentPlayId
	end

	-- 获取当前曲目列表
	function musicEnv.getCurrentTracklist()
		return currentTracklist
	end

	-- 获取当前播放位置
	function musicEnv.getCurrentPosition()
		return currentPosition
	end

	-- 更新音量
	function musicEnv.updateVolume(volume)
		if currentSource then
			currentSource:setVolume(masterVolume)
		end
	end

	-- 设置音量 (0-1)
	function musicEnv.setVolume(volume)
		music.setVolume(volume)
	end

	-- 获取当前音量
	function musicEnv.getVolume()
		return masterVolume
	end

	return musicEnv
end

local lastMusicPlayId = nil
local musicDisplayTime = 0
local musicDisplayDuration = 5
local fadeTime = 0.5

function music.update(dt)
	if activeMusicEnv ~= nil then
		activeMusicEnv.update()
		local currentPlayId = activeMusicEnv.getCurrentPlayId()
		if currentPlayId ~= lastMusicPlayId then
			lastMusicPlayId = currentPlayId
			musicDisplayTime = currentPlayId and musicDisplayDuration or 0
		end
		if musicDisplayTime > 0 then
			musicDisplayTime = musicDisplayTime - dt
		end
	end
end

function music.drawBar()
    -- 音乐信息
	if activeMusicEnv ~= nil then
		if musicDisplayTime > 0 then
			local width = WIN_W
			local height = WIN_H
			local track = activeMusicEnv.getCurrentTrack()
			if track then
				local progress = musicDisplayTime / musicDisplayDuration
				local alpha
				if progress > 1 - fadeTime / musicDisplayDuration then
					alpha = (musicDisplayDuration - musicDisplayTime) / fadeTime
				elseif progress < fadeTime / musicDisplayDuration then
					alpha = musicDisplayTime / fadeTime
				else
					alpha = 1
				end
				alpha = math.max(0, math.min(1, alpha)) * 0.8

				love.graphics.setColor(0.8, 0.8, 0.8, alpha)
				love.graphics.setFont(smallFont)

				local line1 = track.title .. " - " .. track.artist
				local line2 = "from " .. track.source
				local w1 = smallFont:getWidth(line1)
				local w2 = smallFont:getWidth(line2)
				local x1 = (width - w1) / 2
				local x2 = (width - w2) / 2
				local y = height - 80
				love.graphics.print(line1, x1, y)
				love.graphics.print(line2, x2, y + 25)
			end
		end
	end
end

return music
