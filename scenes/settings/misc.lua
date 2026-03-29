-- scenes/settings/profile.lua
local MiscScene = {}

local Scene = require("core.scene")
local SFX = require("core.sfx")
local Settings = require("core.settings")
local Profile = require("core.profile")

local currentSettings = nil
local editingName = false
local tempName = ""

local startX = 500
local startY = 20
local lineHeight = 50

function MiscScene.load()
    currentSettings = Settings.load()
    editingName = false
    tempName = Profile.get().name
end

function MiscScene.update(dt)
end

function MiscScene.draw()
    love.graphics.setFont(mediumFont)
    local y = startY
    
    -- 绘制昵称设置区域
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("玩家昵称:", startX, y)
    
    local nameX = startX + 150
    if editingName then
        love.graphics.setColor(1, 0.8, 0.4, 1)
        love.graphics.print(tempName .. "_", nameX, y)
    else
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(Profile.get().name, nameX, y)
    end
    y = y + lineHeight
end

function MiscScene.keypressed(key)
    -- 正在编辑昵称
    if editingName then
        if key == "escape" then
            editingName = false
            tempName = Profile.get().name
            SFX.play("back")
        elseif key == "backspace" then
            tempName = tempName:sub(1, -2)
        elseif key == "space" then
            tempName = tempName .. " "
        elseif key == "return" or key == "kpenter" then
            -- 回车确认，保持当前名字
            editingName = false
			Profile.setName(tempName)
            SFX.play("confirm")
        else
            -- 支持字母、数字、符号
            if #key == 1 then
                tempName = tempName .. key
            end
        end
        return true
    end
end

function MiscScene.mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    -- 检测昵称区域点击
    local nameY = startY
    local nameX1 = startX
    local nameX2 = startX + 250
    if y >= nameY and y <= nameY + lineHeight then
        if x >= nameX1 and x <= nameX2 then
            editingName = true
            tempName = Profile.get().name
            SFX.play("select")
            return true
        end
    end
    
    return false
end

function MiscScene.mousemoved(x, y, dx, dy) return false end
function MiscScene.mousereleased(x, y, button) return false end

return MiscScene