-- core/sfx.lua
local sfx = {}

local Settings = require("core.settings")

local sounds = {}      -- 存储原始音源
local playing = {}     -- 存储正在播放的实例
local soundPath = "assets/sfx/"

local masterVolume = 1.0

local soundFiles = {
    move     = "move.ogg",
    rotate   = "rotate.ogg",
    harddrop = "harddrop.ogg",
    allclear = "allclear.ogg",
    lock = "softdrop.ogg",
    clear1   = "clearline.ogg",
    clear4   = "clearquad.ogg",
    hold     = "hold.ogg",
    gameover = "topout.ogg",
    spin = "clearspin.ogg",
    btb_start = "clearbtb.ogg",
    btb_break = "b2bcharge_blast_4.ogg",
    btbc = "clearbtb.ogg",
    spin0 = "spin.ogg",
    countdown3 = "countdown3.ogg",
    countdown2 = "countdown2.ogg",
    countdown1 = "countdown1.ogg",
    go = "go.ogg",
    finished = "finish.ogg",
    select = "menuclick.ogg",
    confirm = "menuconfirm.ogg",
    back = "menuback.ogg",
    
    -- 方块生成音效
    spawn_i = "i.ogg",
    spawn_o = "o.ogg",
    spawn_t = "t.ogg",
    spawn_l = "l.ogg",
    spawn_j = "j.ogg",
    spawn_s = "s.ogg",
    spawn_z = "z.ogg",
    
    -- combo 音效
    combo_1 = "combo_1.ogg",
    combo_2 = "combo_2.ogg",
    combo_3 = "combo_3.ogg",
    combo_4 = "combo_4.ogg",
    combo_5 = "combo_5.ogg",
    combo_6 = "combo_6.ogg",
    combo_7 = "combo_7.ogg",
    combo_8 = "combo_8.ogg",
    combo_9 = "combo_9.ogg",
    combo_10 = "combo_10.ogg",
    combo_11 = "combo_11.ogg",
    combo_12 = "combo_12.ogg",
    combo_13 = "combo_13.ogg",
    combo_14 = "combo_14.ogg",
    combo_15 = "combo_15.ogg",
    combo_16 = "combo_16.ogg",
    combo_break = "combobreak.ogg",
}

-- 加载所有音效
function sfx.load()
    for name, filename in pairs(soundFiles) do
        local path = soundPath .. filename
        local success, source = pcall(love.audio.newSource, path, "static")
        if success and source then
            source:setVolume(masterVolume)
            sounds[name] = source
            playing[name] = {}
        else
            print("警告: 无法加载音效 " .. name .. " -> " .. path)
        end
    end

	local currentSettings = Settings.load()
    masterVolume = (currentSettings.sfxVolume or 80) / 100
end

-- 播放音效（支持多实例，不打断）
function sfx.play(name, volume)
    local original = sounds[name]
    if not original then return false end
    
    -- 创建新实例
    local instance = original:clone()
    local vol = volume
    if vol == nil then
        vol = masterVolume
    end
    -- 确保 vol 是数字
    if type(vol) == "boolean" then
        vol = masterVolume
    end
    vol = math.max(0, math.min(1, vol))
    instance:setVolume(vol)
    instance:play()
    
    -- 存储实例
    if not playing[name] then
        playing[name] = {}
    end
    table.insert(playing[name], instance)
    
    -- 清理已播放完毕的实例
    sfx.cleanup(name)
    
    return true
end

-- 清理已结束的音效实例
function sfx.cleanup(name)
    if not playing[name] then return end
    
    local newList = {}
    for _, instance in ipairs(playing[name]) do
        if instance:isPlaying() then
            table.insert(newList, instance)
        else
            instance:stop()
        end
    end
    playing[name] = newList
end

-- 停止指定音效的所有实例
function sfx.stop(name)
    if playing[name] then
        for _, instance in ipairs(playing[name]) do
            instance:stop()
        end
        playing[name] = {}
    end
    if sounds[name] then
        sounds[name]:stop()
    end
end

-- 停止所有音效
function sfx.stopAll()
    for name, _ in pairs(sounds) do
        sfx.stop(name)
    end
end

-- 设置全局音量
function sfx.setVolume(volume)
    masterVolume = math.max(0, math.min(1, volume))
    -- 更新原始音源音量（用于新实例）
    for _, source in pairs(sounds) do
        source:setVolume(masterVolume)
    end
end

-- 获取当前音量
function sfx.getVolume()
    return masterVolume
end

-- 更新（每帧调用，清理已结束的音效）
function sfx.update()
    for name, _ in pairs(sounds) do
        sfx.cleanup(name)
    end
end

return sfx