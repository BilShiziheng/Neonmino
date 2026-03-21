-- core/sfx.lua
local sfx = {}
local sounds = {}
local soundPath = "assets/sfx/"

local masterVolume = 1.0  -- 全局音量

local soundFiles = {
    move     = "move.ogg",
    rotate   = "rotate.ogg",
    harddrop = "harddrop.ogg",
    allclear = "allclear.ogg",
    lock     = "lock.ogg",
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
}

function sfx.load()
    for name, filename in pairs(soundFiles) do
        local path = soundPath .. filename
        local success, source = pcall(love.audio.newSource, path, "static")
        if success and source then
            source:setVolume(masterVolume)
            sounds[name] = source
        end
    end
end

function sfx.play(name, allowOverlap)
    local s = sounds[name]
    if not s then return end
    if allowOverlap then
        local clone = s:clone()
        clone:setVolume(masterVolume)
        clone:play()
    else
        s:stop()
        s:play()
    end
end

function sfx.stop(name)
    local s = sounds[name]
    if s then s:stop() end
end

function sfx.stopAll()
    for _, s in pairs(sounds) do
        s:stop()
    end
end

-- 设置音量 (0-1)
function sfx.setVolume(volume)
    masterVolume = math.max(0, math.min(1, volume))
    for _, s in pairs(sounds) do
        s:setVolume(masterVolume)
    end
end

-- 获取当前音量
function sfx.getVolume()
    return masterVolume
end

return sfx