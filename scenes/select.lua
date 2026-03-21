-- scenes/select.lua
local SelectScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Button = require("core.button")
local GameModeList = require("core.gamemode_list")

local btnBack
local modeButtons = {}
local selectedIndex = 1

-- 将模式表转换为有序列表
local function getModeList()
    local list = {}
    for key, mode in pairs(GameModeList) do
        mode.key = key
        table.insert(list, mode)
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local modes = nil

function SelectScene.load()
    Button.clear()
    modeButtons = {}
    selectedIndex = 1
    modes = getModeList()
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local centerX = width / 2
    local btnWidth = 800
    local btnHeight = 90
    local spacing = 15
    
    -- 计算总高度并垂直居中
    local totalHeight = #modes * (btnHeight + spacing) + 80
    local startY = (height - totalHeight) / 2
    
    -- 创建模式按钮
    for i, mode in ipairs(modes) do
        local y = startY + (i-1) * (btnHeight + spacing)
        local btn = Button.create(centerX - btnWidth/2, y, btnWidth, btnHeight, mode.name, function()
            SFX.play("confirm")
            -- 转换路径：mode/40L/main.lua -> mode.40L.main
            local path = mode.path:gsub("/", "."):gsub("%.lua$", "")
            print("加载模式: " .. path)
            local success, config = pcall(require, path)
            if success and config then
                _G.currentModeConfig = config
                Scene.switch("game")
            else
                print("无法加载模式: " .. mode.path)
                -- 使用默认配置
                _G.currentModeConfig = { start_speed = 0.5, name = mode.name, description = mode.description }
                Scene.switch("game")
            end
        end)
        table.insert(modeButtons, { id = btn, mode = mode })
    end
    
    -- 返回按钮
    local backY = startY + #modes * (btnHeight + spacing) + 20
    btnBack = Button.create(centerX - 120, backY, 240, 55, "返回主菜单", function()
        SFX.play("back")
        Scene.switch("menu")
    end)
end

function SelectScene.update(dt)
    Button.update()
end

function SelectScene.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- 背景
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- 标题
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(largeFont)
    love.graphics.printf("选择模式", 0, 50, width, "center")
    
    -- 绘制按钮
    Button.drawAll()
    
    -- 绘制模式描述
    love.graphics.setFont(smallFont)
    for _, item in ipairs(modeButtons) do
        local btn = Button.get(item.id)
        if btn then
            local descY = btn.y + btn.h - 30
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            local desc = item.mode.description or ""
            if #desc > 55 then
                desc = desc:sub(1, 52) .. "..."
            end
            local descWidth = smallFont:getWidth(desc)
            local descX = btn.x + (btn.w - descWidth) / 2
            love.graphics.print(desc, descX, descY)
        end
    end
end

function SelectScene.keypressed(key)
    if key == "up" then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = #modeButtons end
        SFX.play("select")
    elseif key == "down" then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #modeButtons then selectedIndex = 1 end
        SFX.play("select")
    elseif key == "return" or key == "space" then
        local item = modeButtons[selectedIndex]
        if item and item.id then
            local btn = Button.get(item.id)
            if btn and btn.action then
                btn.action()
            end
        end
    elseif key == "escape" then
        SFX.play("back")
        Scene.switch("menu")
    end
end

function SelectScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    Button.checkPress(x, y, button)
end

function SelectScene.mousereleased(x, y, button)
    if button ~= 1 then return end
    Button.checkRelease(x, y, button)
end

return SelectScene