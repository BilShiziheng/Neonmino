-- main.lua
local Scene = require("core.scene")
local Settings = require("core.settings")
local Background = require("core.background")

-- 字体全局变量
smallFont = nil
mediumFont = nil
largeFont = nil
hugeFont = nil

local globalScale = 1
local sdx, sdy = 0, 0

local function rescale()
	local width, height = love.graphics.getWidth(), love.graphics.getHeight()
	globalScale = math.min(width / WIN_W, height / WIN_H)
	sdx, sdy = (width - globalScale * WIN_W) / 2, (height - globalScale * WIN_H) / 2
end

WIN_W, WIN_H = 1600, 900

function love.load()
    local settings = Settings.load()

	local width, height = settings.resolution.width, settings.resolution.height
    love.window.setMode(width, height, { resizable = false, vsync = settings.vsync, fullscreen = settings.fullscreen })
	rescale()

    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

    local fontPath = "font.ttf"
    smallFont = love.graphics.newFont(fontPath, 18)
    mediumFont = love.graphics.newFont(fontPath, 24)
    largeFont = love.graphics.newFont(fontPath, 36)
    hugeFont = love.graphics.newFont(fontPath, 60)

    -- 注册背景
    Background.register("solid", require("core.backgrounds.solid"))
    Background.register("star", require("core.backgrounds.star"))
    Background.register("cava", require("core.backgrounds.cava"))
    Background.register("blockrain", require("core.backgrounds.blockrain"))
    
    -- 加载保存的背景设置
    local bgName = settings.background or "solid"
    Background.setDefault(bgName)

    -- 注册场景
    local SplashScene = require("scenes.splash")
    local MenuScene = require("scenes.menu")
    local SelectScene = require("scenes.select")
    local SettingsScene = require("scenes.settings")
    local GameScene = require("scenes.game")
	local ResultScene = require("scenes.result")

    Scene.register("splash", SplashScene)
    Scene.register("menu", MenuScene)
    Scene.register("select", SelectScene)
    Scene.register("settings", SettingsScene)
    Scene.register("game", GameScene)
    Scene.register("result", ResultScene)
    
    -- 注册设置子场景
    Scene.register("controls", require("scenes.settings.controls"))
    Scene.register("handling", require("scenes.settings.handling"))
    Scene.register("sound", require("scenes.settings.sound"))
    Scene.register("video", require("scenes.settings.video"))

    -- 从开屏开始
    Scene.switch("splash")
end

function love.resize()
	rescale()
end

function love.update(dt)
    Scene.update(dt)
    Background.update(dt)
end

function love.draw()
	love.graphics.push()
	love.graphics.translate(sdx, sdy)
	love.graphics.scale(globalScale)
    Scene.draw()
	love.graphics.pop()
end

function love.keyreleased(key)
    Scene.keyreleased(key)
end

function love.keypressed(key)
    Scene.keypressed(key)
end

local function round(x)
	return math.floor(x + 0.5)
end

local function filterX(x)
	return round((x - sdx) / globalScale)
end
local function filterY(y)
	return round((y - sdy) / globalScale)
end

-- overrides love.mouse.getPosition()
function getMousePosition()
	local x, y = love.mouse.getPosition()
	return filterX(x), filterY(y)
end

function love.mousepressed(x, y, button)
    Scene.mousepressed(filterX(x), filterY(y), button)
end

function love.mousereleased(x, y, button)
    Scene.mousereleased(filterX(x), filterY(y), button)
end

function love.mousemoved(x, y, dx, dy)
    Scene.mousemoved(filterX(x), filterY(y), dx, dy)
end