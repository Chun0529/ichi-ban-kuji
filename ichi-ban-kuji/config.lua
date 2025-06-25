Config = {}

-- 框架設定
Config.Framework = 'qbcore' -- 'qbcore' 或 'esx'

-- 目標系統
Config.TargetSystem = 'qb_target' -- 'qb_target' 或 'ox_target'

-- 庫存系統
Config.InventorySystem = 'qb_inventory' -- 'qb_inventory', 'ox_inventory' 或 'esx_inventory'

-- 資料庫設定
Config.Database = {
    useOxMySQL = true, -- 是否使用 oxmysql (推荐)
    useMySQL = true, -- 是否使用 MySQL (false 則使用 SQLite)
    playerIdentifiers = { -- 玩家識別碼 (用於資料庫記錄)
        'license', 
        'license2', 
        'steamid', 
        'discord'
    }
}

-- 一番賞機配置
Config.Machines = {
    {
        id = "premium_set", -- 唯一ID
        name = "Premium 一番賞", -- 顯示名稱
        coords = vector3(120.0, -200.0, 30.0), -- 位置
        heading = 180.0, -- 朝向
        model = `prop_vend_soda_01`, -- 模型 (可選)
        length = 1.0, -- 目標區域長度
        width = 1.0, -- 目標區域寬度
        minZ = 29.0, -- 最小高度
        maxZ = 32.0, -- 最大高度
        label = "Premium 一番賞", -- 目標標籤
        icon = "fas fa-ticket-alt", -- 目標圖示
        color = "#FF69B4", -- 目標色 (ox_target)
        price = 1000, -- 每次抽獎價格
        currency = "money", -- 貨幣類型 (money, bank, black_money等)
        maxTickets = 200, -- 總獎券數量
        resetAfterEmpty = true, -- 獎品抽完後自動重置
        resetCooldown = 24, -- 重置冷卻時間(小時)
        prizes = {
            {
                tier = "A", -- 獎項等級
                label = "A賞 - 豪華跑車", -- 顯示名稱
                chance = 1, -- 中獎機率 (1%)
                items = { -- 獎品物品
                    { name = "adder", amount = 1, label = "特斯塔羅薩" } -- 車輛需要配合車輛插件
                },
                max = 1, -- 最大可中獎次數
                isGrandPrize = true -- 是否為大獎
            },
            {
                tier = "B",
                label = "B賞 - 高級摩托車",
                chance = 5,
                items = {
                    { name = "akuma", amount = 1, label = "Akuma摩托车" }
                },
                max = 3
            },
            {
                tier = "C",
                label = "C賞 - 金條",
                chance = 10,
                items = {
                    { name = "gold_bar", amount = 5, label = "金條" }
                },
                max = 10
            },
            {
                tier = "D",
                label = "D賞 - 武器",
                chance = 15,
                items = {
                    { name = "weapon_pistol", amount = 1, label = "手槍" }
                },
                max = 15,
                requireLicense = true -- 需要武器执照
            },
            {
                tier = "E",
                label = "E賞 - 安慰獎",
                chance = 69,
                items = {
                    { name = "water", amount = 10, label = "礦泉水" },
                    { name = "sandwich", amount = 10, label = "三明治" }
                },
                max = 161
            }
        }
    }
    -- 可新增更多機器配置
}

-- 動畫效果設定
Config.Animation = {
    enable = true, -- 啟用抽獎動畫
    duration = 5000, -- 動畫持續時間(毫秒)
    spinItems = 24, -- 動畫中顯示的物品數量
    sound = { -- 音效設定
        enabled = true,
        spinSound = "spin_sound", -- 旋轉音效
        winSound = "win_sound", -- 中獎音效
        volume = 0.5 -- 音量
    }
}

-- UI設定
Config.UI = {
    type = "qb-menu", -- 'qb-menu', 'esx-menu', 'ox_lib'
    showRemainingPrizes = true, -- 顯示剩餘獎品
    showProbability = true, -- 顯示中獎機率
    showMachineStatus = true -- 顯示機器狀態
}

-- 通知設定
Config.Notify = {
    system = "qb", -- 'qb', 'esx', 'okok', 'ox_lib'
    messages = {
        not_enough_money = "你没有足够的钱购买奖券!",
        won_prize = "恭喜你获得了 {prize}!", -- {prize} 會被替換為獎品名稱
        no_prizes_left = "这个一番賞已经没有奖品了!",
        inventory_full = "你的背包空间不足，无法领取奖品!",
        machine_reset = "一番賞机器已重置!",
        draw_in_progress = "正在抽奖中...",
        requirement_not_met = "你不满足领取此奖品的条件!"
    }
}

-- 管理員命令
Config.Admin = {
    resetCommand = "resetkuji", -- 重置機器命令
    adminGroups = { -- 有權使用管理員命令的群組
        "admin",
        "mod"
    }
}

-- 偵錯模式
Config.Debug = false