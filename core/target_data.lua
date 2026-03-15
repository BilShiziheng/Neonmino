-- core/target_data.lua
local M = {}

M.lines = function(required)
    return function(state)
        return state.totalLines >= required
    end
end

M.time = function(required)
    return function(state)
        return state.gameTimer >= required
    end
end

M.pieces = function(required)
    return function(state)
        return state.piecesPlaced >= required
    end
end

M.linesAndTime = function(linesReq, timeReq)
    return function(state)
        return state.totalLines >= linesReq and state.gameTimer <= timeReq
    end
end

M.victory = function()
    return function(state)
        return state.custom and state.custom.victory or false
    end
end

M.height = function(required)
    return function(state)
        return state.custom and state.custom.height and state.custom.height >= required
    end
end

return M  -- 确保在最后