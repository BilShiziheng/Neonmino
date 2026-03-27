-- core/background.lua
local background = {}

local backgrounds = {}
local currentBg = nil
local currentBgName = nil
local savedBgName = nil  -- 保存用户设置的背景

-- 注册背景
function background.register(name, bgModule)
    backgrounds[name] = bgModule
end

-- 切换到指定背景
function background.switch(name)
    if not backgrounds[name] then
        name = "solid"
    end
    if currentBg and currentBg.unload then
        currentBg.unload()
    end
    currentBg = backgrounds[name]
    currentBgName = name
    if currentBg and currentBg.load then
        currentBg.load()
    end
end

-- 临时切换（用于模式指定背景，保存当前背景以便恢复）
function background.tempSwitch(name)
    if savedBgName == nil then
        savedBgName = currentBgName
    end
    background.switch(name)
end

-- 恢复到用户保存的背景
function background.restore()
    if savedBgName then
        background.switch(savedBgName)
        savedBgName = nil
    end
end

-- 设置用户默认背景（由视频设置调用）
function background.setDefault(name)
    savedBgName = nil
    background.switch(name)
end

-- 获取当前背景名称
function background.getCurrent()
    return currentBgName
end

-- 获取所有背景列表
function background.getList()
    local list = {}
    for name, _ in pairs(backgrounds) do
        table.insert(list, name)
    end
    return list
end

-- 更新当前背景
function background.update(dt)
    if currentBg and currentBg.update then
        currentBg.update(dt)
    end
end

-- 绘制当前背景
function background.draw()
    if currentBg and currentBg.draw then
        currentBg.draw()
    end
end

return background