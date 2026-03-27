-- core/backgrounds/cava.lua
local cava = {}

local bars = {}
local barCount = 60
local barWidth = 0
local time = 0

function cava.load()
    local width = WIN_W
    barWidth = width / barCount
    for i = 1, barCount do
        bars[i] = 0.1
    end
end

function cava.update(dt)
    time = time + dt
    for i = 1, barCount do
        -- 正弦波流动效果
        local freq = i / barCount * 8
        local value = 0.2 + 0.3 * math.sin(time * 5 + freq)
        bars[i] = bars[i] + (value - bars[i]) * dt * 5
    end
end

function cava.draw()
    local width = WIN_W
    local height = WIN_H
    barWidth = width / barCount
    
    for i, h in ipairs(bars) do
        local barHeight = h * height * 0.4
        love.graphics.setColor(0.3, 0.6, 0.9, 0.6)
        love.graphics.rectangle("fill", (i-1) * barWidth, height - barHeight, barWidth - 1, barHeight)
    end
end

function cava.unload()
    bars = {}
end

return cava