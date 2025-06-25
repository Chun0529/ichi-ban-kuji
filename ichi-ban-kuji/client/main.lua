local currentMachine = nil
local isDrawing = false

-- 初始化目標系統
local function initTargets()
    if Config.TargetSystem == 'qb_target' then
        for _, machine in ipairs(Config.Machines) do
            if machine.model then
                exports['qb-target']:AddTargetModel(machine.model, {
                    options = {
                        {
                            type = "client",
                            event = "ichi-ban-kuji:client:openMenu",
                            icon = machine.icon,
                            label = machine.label,
                            machineId = machine.id
                        }
                    },
                    distance = 2.0
                })
            else
                exports['qb-target']:AddBoxZone("ichi_ban_kuji_" .. machine.id, 
                    machine.coords, machine.length, machine.width, {
                        name = "ichi_ban_kuji_" .. machine.id,
                        heading = machine.heading,
                        debugPoly = Config.Debug,
                        minZ = machine.minZ,
                        maxZ = machine.maxZ,
                    }, {
                        options = {
                            {
                                type = "client",
                                event = "ichi-ban-kuji:client:openMenu",
                                icon = machine.icon,
                                label = machine.label,
                                machineId = machine.id
                            }
                        },
                        distance = 2.0
                    })
            end
        end
    elseif Config.TargetSystem == 'ox_target' then
        for _, machine in ipairs(Config.Machines) do
            if machine.model then
                exports.ox_target:addModel(machine.model, {
                    {
                        name = 'ichi_ban_kuji_' .. machine.id,
                        event = 'ichi-ban-kuji:client:openMenu',
                        icon = machine.icon,
                        label = machine.label,
                        distance = 2.0,
                        machineId = machine.id
                    }
                })
            else
                exports.ox_target:addBoxZone({
                    coords = machine.coords,
                    size = vec3(machine.length, machine.width, machine.maxZ - machine.minZ),
                    rotation = machine.heading,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'ichi_ban_kuji_' .. machine.id,
                            event = 'ichi-ban-kuji:client:openMenu',
                            icon = machine.icon,
                            label = machine.label,
                            distance = 2.0,
                            machineId = machine.id
                        }
                    }
                })
            end
        end
    end
end

-- 顯示抽獎動畫
local function showDrawAnimation(callback)
    if not Config.Animation.enable then
        if callback then callback() end
        return
    end
    
    isDrawing = true
    
    -- 播放音效
    if Config.Animation.sound.enabled then
        TriggerEvent("interaction:client:playSound", Config.Animation.sound.spinSound, Config.Animation.sound.volume)
    end
    
    -- 建立動畫UI
    if Config.UI.type == 'qb-menu' then
        local spinItems = {}
        for i = 1, Config.Animation.spinItems do
            table.insert(spinItems, {
                header = "抽獎中...",
                txt = "請稍候",
                icon = "fas fa-spinner fa-spin",
                isMenuHeader = true
            })
        end
        
        exports['qb-menu']:openMenu(spinItems)
        
        Citizen.CreateThread(function()
            local startTime = GetGameTimer()
            while GetGameTimer() - startTime < Config.Animation.duration do
                Citizen.Wait(0)
            end
            
            exports['qb-menu']:closeMenu()
            isDrawing = false
            
            if callback then callback() end
        end)
    else
        -- 其他UI系統的實現...
    end
end

-- 顯示獎品
local function showPrize(prize)
    -- 播放中獎音效
    if Config.Animation.sound.enabled then
        TriggerEvent("interaction:client:playSound", Config.Animation.sound.winSound, Config.Animation.sound.volume)
    end
    
    -- 顯示獎品UI
    if Config.UI.type == 'qb-menu' then
        local prizeItems = {}
        table.insert(prizeItems, {
            header = prize.label,
            txt = "恭喜你獲得了大獎!",
            icon = "fas fa-trophy",
            isMenuHeader = true
        })
        
        for _, item in ipairs(prize.items) do
            table.insert(prizeItems, {
                header = item.label,
                txt = "數量: " .. item.amount,
                icon = "fas fa-gift"
            })
        end
        
        table.insert(prizeItems, {
            header = "關閉",
            txt = "",
            params = {
                event = "qb-menu:closeMenu",
            }
        })
        
        exports['qb-menu']:openMenu(prizeItems)
        Citizen.Wait(5000)
        exports['qb-menu']:closeMenu()
    else
        -- 其他UI系統的實現...
    end
end

-- 打開抽獎菜單
local function openMenu(data)
    if isDrawing then return end
    
    currentMachine = data.machineId
    
    QBCore.Functions.TriggerCallback('ichi-ban-kuji:server:getMachineStatus', function(machineStatus)
        if not machineStatus then
            TriggerEvent('ichi-ban-kuji:client:notify', "无法获取机器状态", 'error')
            return
        end
        
        local machineConfig
        for _, m in ipairs(Config.Machines) do
            if m.id == currentMachine then
                machineConfig = m
                break
            end
        end
        
        if not machineConfig then return end
        
        -- 建立選單
        if Config.UI.type == 'qb-menu' then
            local menu = {
                {
                    header = machineConfig.name,
                    txt = "剩餘獎券: " .. machineStatus.remaining_tickets .. "/" .. machineConfig.maxTickets,
                    isMenuHeader = true
                }
            }
            
            -- 添加獎品訊息
            for _, prize in ipairs(machineConfig.prizes) do
                local wonCount = 0
                if prize.tier == "A" then wonCount = machineStatus.a_prize
                elseif prize.tier == "B" then wonCount = machineStatus.b_prize
                elseif prize.tier == "C" then wonCount = machineStatus.c_prize
                elseif prize.tier == "D" then wonCount = machineStatus.d_prize
                elseif prize.tier == "E" then wonCount = machineStatus.e_prize end
                
                local remaining = prize.max - wonCount
                
                table.insert(menu, {
                    header = prize.label,
                    txt = (Config.UI.showProbability and "機率: " .. prize.chance .. "% | " or "") .. 
                          (Config.UI.showRemainingPrizes and "剩余: " .. remaining .. "/" .. prize.max or ""),
                    icon = "fas fa-gift",
                    isMenuHeader = true
                })
            end
            
            -- 添加抽獎按鈕
            table.insert(menu, {
                header = "抽獎 (" .. machineConfig.price .. "$)",
                txt = "點擊進行抽獎",
                params = {
                    event = "ichi-ban-kuji:client:startDraw",
                    args = {
                        machineId = currentMachine
                    }
                }
            })
            
            -- 新增歷史記錄按鈕
            table.insert(menu, {
                header = "我的抽獎紀錄",
                txt = "查看你的抽獎歷史",
                params = {
                    event = "ichi-ban-kuji:client:viewHistory"
                }
            })
            
            table.insert(menu, {
                header = "關閉",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            })
            
            exports['qb-menu']:openMenu(menu)
        else
            -- 其他UI系統的實現...
        end
    end, currentMachine)
end

-- 開始抽獎
local function startDraw(data)
    if isDrawing then return end
    
    TriggerEvent('ichi-ban-kuji:client:notify', Config.Notify.messages.draw_in_progress, 'info')
    
    showDrawAnimation(function()
        TriggerServerEvent('ichi-ban-kuji:server:purchaseTicket', data.machineId)
    end)
end

-- 查看历史记录
local function viewHistory()
    QBCore.Functions.TriggerCallback('ichi-ban-kuji:server:getPlayerHistory', function(history)
        if Config.UI.type == 'qb-menu' then
            local menu = {
                {
                    header = "我的抽獎紀錄",
                    txt = "最近的抽獎記錄",
                    isMenuHeader = true
                }
            }
            
            if #history == 0 then
                table.insert(menu, {
                    header = "暫無紀錄",
                    txt = "你還沒有抽獎",
                    isMenuHeader = true
                })
            else
                for _, record in ipairs(history) do
                    table.insert(menu, {
                        header = record.machine_name,
                        txt = "獎項: " .. record.tier .. " | 時間: " .. record.won_at,
                        isMenuHeader = true
                    })
                end
            end
            
            table.insert(menu, {
                header = "返回",
                txt = "",
                params = {
                    event = "ichi-ban-kuji:client:openMenu",
                    args = {
                        machineId = currentMachine
                    }
                }
            })
            
            exports['qb-menu']:openMenu(menu)
        else
            -- 其他UI系統的實現...
        end
    end)
end

-- 通知函数
local function notify(msg, type)
    if Config.Notify.system == 'qb' then
        QBCore.Functions.Notify(msg, type)
    elseif Config.Notify.system == 'esx' then
        ESX.ShowNotification(msg)
    elseif Config.Notify.system == 'okok' then
        exports['okokNotify']:Alert("一番賞", msg, 5000, type)
    elseif Config.Notify.system == 'ox_lib' then
        lib.notify({
            title = '一番賞',
            description = msg,
            type = type
        })
    end
end

-- 事件註冊
RegisterNetEvent('ichi-ban-kuji:client:openMenu', openMenu)
RegisterNetEvent('ichi-ban-kuji:client:startDraw', startDraw)
RegisterNetEvent('ichi-ban-kuji:client:viewHistory', viewHistory)
RegisterNetEvent('ichi-ban-kuji:client:notify', notify)
RegisterNetEvent('ichi-ban-kuji:client:showPrize', showPrize)

-- 資源啟動
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        initTargets()
    end
end)

-- 導出函數
exports('getDatabase', function()
    return db
end)