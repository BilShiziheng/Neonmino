-- core/scene.lua
local SceneManager = {}
local scenes = {}
local currentScene = nil

function SceneManager.register(name, scene)
    scenes[name] = scene
end

function SceneManager.switch(name)
    local newScene = scenes[name]
    if not newScene then
        error("Scene not found: " .. name)
    end
    if currentScene and currentScene.unload then
        currentScene.unload()
    end
    currentScene = newScene
    if currentScene.load then
        currentScene.load()
    end
end

function SceneManager.update(dt)
    if currentScene and currentScene.update then
        currentScene.update(dt)
    end
end

function SceneManager.draw()
    if currentScene and currentScene.draw then
        currentScene.draw()
    end
end

function SceneManager.keypressed(key)
    if currentScene and currentScene.keypressed then
        currentScene.keypressed(key)
    end
end

function SceneManager.keyreleased(key)
    if currentScene and currentScene.keyreleased then
        currentScene.keyreleased(key)
    end
end

function SceneManager.mousepressed(x, y, button)
    if currentScene and currentScene.mousepressed then
        currentScene.mousepressed(x, y, button)
    end
end

function SceneManager.mousereleased(x, y, button)
    if currentScene and currentScene.mousereleased then
        currentScene.mousereleased(x, y, button)
    end
end

function SceneManager.mousemoved(x, y, dx, dy)
    if currentScene and currentScene.mousemoved then
        currentScene.mousemoved(x, y, dx, dy)
    end
end

return SceneManager