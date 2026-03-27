-- core/backgrounds/blockrain.lua
-- 落块雨背景（俄罗斯方块形状）

local blockrain = {}

local mino = {}
local timer = 0
local blockSize = 20

-- 俄罗斯方块形状定义
local shapes = {
    -- I
    {
        grid = {{1, 1, 1, 1}},
        color = {0, 1, 1},
        width = 4, height = 1
    },
    -- O
    {
        grid = {{1, 1}, {1, 1}},
        color = {1, 1, 0},
        width = 2, height = 2
    },
    -- T
    {
        grid = {{0, 1, 0}, {1, 1, 1}},
        color = {0.8, 0.2, 1},
        width = 3, height = 2
    },
    -- L
    {
        grid = {{1, 0, 0}, {1, 1, 1}},
        color = {1, 0.5, 0},
        width = 3, height = 2
    },
    -- J
    {
        grid = {{0, 0, 1}, {1, 1, 1}},
        color = {0, 0, 1},
        width = 3, height = 2
    },
    -- S
    {
        grid = {{0, 1, 1}, {1, 1, 0}},
        color = {0, 1, 0},
        width = 3, height = 2
    },
    -- Z
    {
        grid = {{1, 1, 0}, {0, 1, 1}},
        color = {1, 0, 0},
        width = 3, height = 2
    },
}

-- 创建形状纹理
local function createShapeTexture(shape)
    local w = shape.width * blockSize
    local h = shape.height * blockSize
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(canvas)
    
    for y, row in ipairs(shape.grid) do
        for x, val in ipairs(row) do
            if val == 1 then
                love.graphics.setColor(shape.color[1], shape.color[2], shape.color[3], 1)
                love.graphics.rectangle("fill", (x-1)*blockSize, (y-1)*blockSize, blockSize-1, blockSize-1)
            end
        end
    end
    love.graphics.setCanvas()
    return canvas
end

-- 预生成纹理
local textures = {}
for i, shape in ipairs(shapes) do
    textures[i] = createShapeTexture(shape)
end

function blockrain.load()
    mino = {}
    timer = 0
end

function blockrain.update(dt)
    timer = timer + dt * 60
    
    -- 每15帧生成一个，减少密度
    if timer >= 80 then
        timer = 0
        local width = WIN_W
        local r = math.random(1, #shapes)
        local shape = shapes[r]
        local shapeWidth = shape.width * blockSize
        
        table.insert(mino, {
            id = r,
            texture = textures[r],
            color = shape.color,
            x = math.random(0, width - shapeWidth),
            y = -shape.height * blockSize,
            scale = 0.6 + math.random() * 0.6,
            vy = 35 + math.random() * 60,
            vx = (math.random() - 0.5) * 15,
            angle = math.random() * math.pi * 2,
            va = (math.random() - 0.5) * 0.8,
        })
    end
    
    for i = #mino, 1, -1 do
        local b = mino[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.angle = b.angle + b.va * dt
        
        if b.y > WIN_H + 150 then
            table.remove(mino, i)
        end
    end
end

function blockrain.draw()
    local width = WIN_W
    local height = WIN_H
    
    -- 深色背景
    love.graphics.setColor(0.05, 0.05, 0.07, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- 绘制下落形状
    for _, b in ipairs(mino) do
        love.graphics.setColor(b.color[1], b.color[2], b.color[3], 0.6)
        love.graphics.draw(b.texture, b.x, b.y, b.angle, b.scale, b.scale, 0, 0)
    end
end

function blockrain.unload()
    mino = {}
    timer = 0
end

return blockrain