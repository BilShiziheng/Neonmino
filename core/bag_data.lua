-- core/bag_data.lua
local bag_data = {}

local pieces = {"I", "O", "T", "L", "J", "S", "Z"}
local bag = {}

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function bag_data.init()
    bag = shuffle({unpack(pieces)})
end

function bag_data.next()
    if #bag == 0 then
        bag = shuffle({unpack(pieces)})
    end
    return table.remove(bag, 1)
end

return bag_data