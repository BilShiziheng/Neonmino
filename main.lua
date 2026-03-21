-- main.lua
local Scene = require("core.scene")

-- 字体全局变量
smallFont = nil
mediumFont = nil
largeFont = nil

function love.load()
    love.window.setMode(1600, 900, { resizable = false, vsync = true })
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

    local fontPath = "font.ttf"
    smallFont = love.graphics.newFont(fontPath, 18)
    mediumFont = love.graphics.newFont(fontPath, 24)
    largeFont = love.graphics.newFont(fontPath, 36)

    -- 注册场景（不再在这里加载资源）
    local SplashScene = require("scenes.splash")
    local MenuScene = require("scenes.menu")
    local SelectScene = require("scenes.select")
    local SettingsScene = require("scenes.settings")
    local GameScene = require("scenes.game")

    Scene.register("splash", SplashScene)
    Scene.register("menu", MenuScene)
    Scene.register("select", SelectScene)
    Scene.register("settings", SettingsScene)
    Scene.register("game", GameScene)
    Scene.register("result", require("scenes.result"))
    
    -- 注册设置子场景
    Scene.register("controls", require("scenes.settings.controls"))
    Scene.register("handing", require("scenes.settings.handing"))
    Scene.register("sound", require("scenes.settings.sound"))
    Scene.register("video", require("scenes.settings.video"))

    -- 从开屏开始
    Scene.switch("splash")
end

function love.update(dt)
    Scene.update(dt)
end

function love.draw()
    Scene.draw()
end

function love.keyreleased(key)
    Scene.keyreleased(key)
end

function love.keypressed(key)
    Scene.keypressed(key)
end

function love.mousepressed(x, y, button)
    Scene.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Scene.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    Scene.mousemoved(x, y, dx, dy)
end