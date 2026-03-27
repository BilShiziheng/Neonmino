function love.conf(t)
    -- 窗口设置
    t.window.title = "Neonmino"
    t.window.width = 1600
    t.window.height = 900
    t.window.resizable = false      -- 固定窗口大小
    t.window.vsync = true

    -- ==== 俄罗斯方块需要的模块 ====
    -- 核心模块（必须保留）
    t.modules.event = true      -- 事件处理（按键响应必需）
    t.modules.graphics = true   -- 绘图（显示方块必需）
    t.modules.timer = true      -- 计时器（方块下落必需）
    t.modules.window = true     -- 窗口管理
    
    -- 输入模块（必需）
    t.modules.keyboard = true   -- 键盘控制（左右旋转等）
    
    -- 其他必需模块
    t.modules.audio = true      -- 音效（如果有音效）
    t.modules.sound = true      -- 声音（如果有音效）
    t.modules.font = true       -- 字体（显示分数）
    t.modules.image = true      -- 图片（如果用图片做方块）
    
    -- ==== 可以禁用的模块 ====
    t.modules.joystick = false  -- 不用手柄
    t.modules.physics = false   -- 不用物理引擎
    t.modules.touch = true    -- 不用触摸
    t.modules.video = true     -- 不用视频
    t.modules.thread = false    -- 不用多线程
    t.modules.data = false      -- 不用数据编码
    t.modules.math = false      -- 可禁用（除非你用了love.math）
    t.modules.mouse = true     -- 可禁用（俄罗斯方块用键盘）
    t.modules.system = true    -- 可禁用（除非需要系统信息）
    
    -- 版本
    t.console = true
    t.identity = "neonmino_rc"
end