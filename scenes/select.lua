-- scenes/select.lua
local SelectScene = {}
local Scene = require("core.scene")          -- 重要：需要引入 Scene
local gamelist = require("core.gamemode_list")

local modeKeys = {}
local buttons = {}

local buttonWidth = 800
local buttonHeight = 80
local buttonSpacing = 20
local startY = 200

function SelectScene.load()
    modeKeys = {}
    for k, _ in pairs(gamelist) do
        table.insert(modeKeys, k)
    end
    table.sort(modeKeys)
    buttons = {}
    for i, key in ipairs(modeKeys) do
        local mode = gamelist[key]
        table.insert(buttons, {
            label = mode.name,
            desc = mode.description,
            path = mode.path,
            key = key,
            y = startY + (i-1) * (buttonHeight + buttonSpacing)
        })
    end
end

function SelectScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    for i, btn in ipairs(buttons) do
        local bx = (1600 - buttonWidth) / 2
        local by = btn.y
        if x >= bx and x <= bx + buttonWidth and y >= by and y <= by + buttonHeight then
            -- 转换路径：将斜杠替换为点，并去掉末尾的 .lua
            local moduleName = btn.path:gsub("/", "."):gsub("%.lua$", "")
            local param = require(moduleName)
            -- 合并列表中的元数据，并确保包含 goal 字段
            local modeConfig = {
                name = btn.label,
                description = btn.desc,
                start_speed = param.start_speed,
                goal = param.goal,   -- 关键：加入 goal 字段
            }
            _G.currentModeConfig = modeConfig
            Scene.switch("game")
            return
        end
    end
end

function SelectScene.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(largeFont)
    love.graphics.printf("选择模式", 0, 50, 1600, "center")

    love.graphics.setFont(mediumFont)
    for i, btn in ipairs(buttons) do
        local bx = (1600 - buttonWidth) / 2
        local by = btn.y
        love.graphics.setColor(0.2,0.2,0.3)
        love.graphics.rectangle("fill", bx, by, buttonWidth, buttonHeight, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(btn.label, bx, by + 10, buttonWidth, "center")
        love.graphics.setFont(smallFont)
        love.graphics.printf(btn.desc, bx, by + 40, buttonWidth, "center")
        love.graphics.setFont(mediumFont)
    end

    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.print("ESC 返回主菜单", 10, 850)
end

function SelectScene.keypressed(key)
    if key == "escape" then
        Scene.switch("menu")
    end
end

function SelectScene.update(dt) end

return SelectScene