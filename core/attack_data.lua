-- core/attack_data.lua
-- 攻击数据模块，定义不同消行类型对应的攻击值

local attack_data = {}

-- 基础攻击值（普通消行）
attack_data.base = {
    [1] = 0,   -- 单消
    [2] = 1,   -- 双消
    [3] = 2,   -- 三消
    [4] = 4,   -- 四消（Tetris）
}

-- Spin 攻击值（包括 T-Spin 和其他 Spin）
attack_data.spin = {
    [1] = 2,   -- Spin 单消
    [2] = 4,   -- Spin 双消
    [3] = 6,   -- Spin 三消
    [4] = 10,  -- Spin 四消
}

-- Mini Spin 攻击值（如果游戏需要区分 Mini）
attack_data.mini = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 5,
}

-- 全清奖励（Back-to-Back 全清可额外叠加）
attack_data.all_clear = 10

-- B2B 加成（每次特殊消行额外增加的值）
attack_data.b2b_bonus = 1

-- 连击表（连击数对应的额外攻击加成，0 表示无连击）
-- 格式：连击数 => 加成值
attack_data.combo = {
    [0] = 0,
    [1] = 0,
    [2] = 1,
    [3] = 1,
    [4] = 2,
    [5] = 2,
    [6] = 3,
    [7] = 3,
    [8] = 4,
    [9] = 4,
    [10] = 5,
    -- 更高连击可自行扩展
}

-- 获取攻击值函数（方便调用）
function attack_data.get(lines, isSpin, isMini, combo, isAllClear)
    local attack = 0
    if isSpin then
        attack = attack_data.spin[lines] or 0
    elseif isMini then
        attack = attack_data.mini[lines] or 0
    else
        attack = attack_data.base[lines] or 0
    end
    -- 连击加成
    if combo and combo > 0 then
        attack = attack + (attack_data.combo[combo] or 0)
    end
    -- B2B 加成（如果触发）
    -- 这部分需要在游戏逻辑中判断，此处仅提供数值
    return attack
end

return attack_data