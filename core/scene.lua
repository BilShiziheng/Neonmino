-- core/scene.lua
local scene = {}
local statusbar = require("core.statusbar")

local scenes = {}
local currentScene = nil
local nextScene = nil
local transitionTimer = 0
local transitionDuration = 0.3
local transitionState = nil
local transitionAlpha = 0

function scene.register(name, sceneTable)
    scenes[name] = sceneTable
end

function scene.switch(name, ...)
    if currentScene and scenes[currentScene] and scenes[currentScene].unload then
        scenes[currentScene].unload()
    end
    
    if transitionDuration > 0 and currentScene then
        nextScene = name
        transitionState = "fade_out"
        transitionTimer = 0
        transitionAlpha = 0
    else
        currentScene = name
        if scenes[currentScene] and scenes[currentScene].load then
            scenes[currentScene].load(...)
        end
    end
end

function scene.update(dt)
    statusbar.update(dt)
    
    if transitionState then
        transitionTimer = transitionTimer + dt
        
        if transitionState == "fade_out" then
            transitionAlpha = transitionTimer / transitionDuration
            if transitionTimer >= transitionDuration then
                currentScene = nextScene
                if scenes[currentScene] and scenes[currentScene].load then
                    scenes[currentScene].load()
                end
                transitionState = "fade_in"
                transitionTimer = 0
            end
        elseif transitionState == "fade_in" then
            transitionAlpha = 1 - (transitionTimer / transitionDuration)
            if transitionTimer >= transitionDuration then
                transitionState = nil
                nextScene = nil
                transitionAlpha = 0
            end
        end
        return
    end
    
    if currentScene and scenes[currentScene] and scenes[currentScene].update then
        scenes[currentScene].update(dt)
    end
end

function scene.draw()
    if currentScene and scenes[currentScene] and scenes[currentScene].draw then
        scenes[currentScene].draw()
    end
    
    statusbar.draw()
    
    if transitionState then
        love.graphics.setColor(0, 0, 0, transitionAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function scene.keypressed(key)
    if currentScene and scenes[currentScene] and scenes[currentScene].keypressed then
        scenes[currentScene].keypressed(key)
    end
end

function scene.keyreleased(key)
    if currentScene and scenes[currentScene] and scenes[currentScene].keyreleased then
        scenes[currentScene].keyreleased(key)
    end
end

function scene.mousepressed(x, y, button)
    if currentScene and scenes[currentScene] and scenes[currentScene].mousepressed then
        scenes[currentScene].mousepressed(x, y, button)
    end
end

function scene.mousereleased(x, y, button)
    if currentScene and scenes[currentScene] and scenes[currentScene].mousereleased then
        scenes[currentScene].mousereleased(x, y, button)
    end
end

function scene.mousemoved(x, y, dx, dy)
    if currentScene and scenes[currentScene] and scenes[currentScene].mousemoved then
        scenes[currentScene].mousemoved(x, y, dx, dy)
    end
end

function scene.getCurrent()
    return currentScene
end

return scene