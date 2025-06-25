local QBCore, ESX = nil, nil
local db = exports['ichi-ban-kuji']:getDatabase()

-- 初始化框架
if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

-- 取得玩家標識符
local function getPlayerIdentifiers(playerId)
    local identifiers = {}
    for _, v in ipairs(GetPlayerIdentifiers(playerId)) do
        for _, identifier in ipairs(Config.Database.playerIdentifiers) do
            if string.match(v, identifier) then
                identifiers[identifier] = v
                break
            end
        end
    end
    return identifiers
end

-- 檢查玩家是否有足夠金錢
local function hasEnoughMoney(playerId, amount, currency)
    -- 實現同前...
end

-- 扣除玩家金錢
local function removeMoney(playerId, amount, currency)
    -- 實現同前...
end

-- 給予玩家獎品
local function givePrize(playerId, items)
    -- 實現同前...
end

-- 檢查獎品要求
local function checkPrizeRequirements(playerId, prize)
    if prize.requireLicense then
        if Config.Framework == 'qbcore' then
            local player = QBCore.Functions.GetPlayer(playerId)
            return player.PlayerData.metadata['licences'].weapon
        elseif Config.Framework == 'esx' then
            -- ESX 武器執照檢查
            -- 根據實際ESX實現調整
            return true
        end
    end
    return true
end

-- 抽獎邏輯
local function drawPrize(machineId, playerId)
    local machineConfig
    for _, m in ipairs(Config.Machines) do
        if m.id == machineId then
            machineConfig = m
            break
        end
    end
    
    if not machineConfig then return nil, "invalid_machine" end
    
    -- 取得機器狀態
    local machineStatus = db.getMachineStatus(machineId)
    if not machineStatus or machineStatus.remaining_tickets <= 0 then
        return nil, "no_prizes_left"
    end
    
    -- 檢查是否所有獎品都已抽完
    local availablePrizes = {}
    for _, prize in ipairs(machineConfig.prizes) do
        local wonCount = db.getPrizeStatus(machineId, prize.tier)
        if wonCount < prize.max then
            table.insert(availablePrizes, {
                prize = prize,
                wonCount = wonCount,
                max = prize.max,
                chance = prize.chance
            })
        end
    end
    
    if #availablePrizes == 0 then
        -- 嘗試重置機器
        if machineConfig.resetAfterEmpty then
            local lastReset = machineStatus.last_reset
            local resetCooldown = machineConfig.resetCooldown or 24
            
            if not lastReset or os.difftime(os.time(), lastReset) >= (resetCooldown * 3600) then
                db.resetMachine(machineId, machineConfig.maxTickets)
                return drawPrize(machineId, playerId)
            else
                return nil, "machine_on_cooldown"
            end
        else
            return nil, "no_prizes_left"
        end
    end
    
    -- 計算總機率
    local totalChance = 0
    for _, p in ipairs(availablePrizes) do
        totalChance = totalChance + p.chance
    end
    
    -- 隨機選擇獎品
    local random = math.random(1, totalChance)
    local cumulativeChance = 0
    local selectedPrize
    
    for _, p in ipairs(availablePrizes) do
        cumulativeChance = cumulativeChance + p.chance
        if random <= cumulativeChance then
            selectedPrize = p.prize
            break
        end
    end
    
    -- 更新資料庫
    db.updatePrizeStatus(machineId, selectedPrize.tier)
    db.updateMachineStatus(machineId, machineStatus.remaining_tickets - 1)
    
    -- 記錄玩家抽獎
    local identifiers = getPlayerIdentifiers(playerId)
    for _, identifier in pairs(identifiers) do
        db.recordPlayerDraw(identifier, machineId, selectedPrize.tier)
        break -- 只記錄一個標識符
    end
    
    return selectedPrize, nil
end

-- 事件處理
RegisterNetEvent('ichi-ban-kuji:server:purchaseTicket', function(machineId)
    local src = source
    local machineConfig
    
    for _, m in ipairs(Config.Machines) do
        if m.id == machineId then
            machineConfig = m
            break
        end
    end
    
    if not machineConfig then return end
    
    -- 檢查金錢
    if not hasEnoughMoney(src, machineConfig.price, machineConfig.currency) then
        TriggerClientEvent('ichi-ban-kuji:client:notify', src, Config.Notify.messages.not_enough_money, 'error')
        return
    end
    
    -- 抽獎
    local prize, error = drawPrize(machineId, src)
    if not prize then
        TriggerClientEvent('ichi-ban-kuji:client:notify', src, Config.Notify.messages[error] or "抽奖失败!", 'error')
        return
    end
    
    -- 檢查獎品要求
    if not checkPrizeRequirements(src, prize) then
        TriggerClientEvent('ichi-ban-kuji:client:notify', src, Config.Notify.messages.requirement_not_met, 'error')
        -- 退還金錢
        if Config.Framework == 'qbcore' then
            local player = QBCore.Functions.GetPlayer(src)
            if machineConfig.currency == 'money' then
                player.Functions.AddMoney('cash', machineConfig.price)
            elseif machineConfig.currency == 'bank' then
                player.Functions.AddMoney('bank', machineConfig.price)
            else
                player.Functions.AddItem(machineConfig.currency, machineConfig.price)
            end
        elseif Config.Framework == 'esx' then
            -- ESX 退還實現
        end
        return
    end
    
    -- 扣除金錢
    removeMoney(src, machineConfig.price, machineConfig.currency)
    
    -- 給予獎品
    local success = givePrize(src, prize.items)
    if success then
        local msg = string.gsub(Config.Notify.messages.won_prize, "{prize}", prize.label)
        TriggerClientEvent('ichi-ban-kuji:client:notify', src, msg, 'success')
        TriggerClientEvent('ichi-ban-kuji:client:showPrize', src, prize)
    else
        TriggerClientEvent('ichi-ban-kuji:client:notify', src, Config.Notify.messages.inventory_full, 'error')
        -- 退還金錢
        -- 實現同前...
    end
end)

-- 管理員命令
RegisterCommand(Config.Admin.resetCommand, function(source, args)
    if source == 0 then
        -- 控制台執行
        if #args < 1 then
            print("用法: resetkuji [machineId]")
            return
        end
        
        local machineId = args[1]
        local machineConfig
        
        for _, m in ipairs(Config.Machines) do
            if m.id == machineId then
                machineConfig = m
                break
            end
        end
        
        if machineConfig then
            db.resetMachine(machineId, machineConfig.maxTickets)
            print("一番賞機器 " .. machineId .. " 已重置!")
        else
            print("無效的機器ID: " .. machineId)
        end
    else
        -- 玩家执行
        local player = nil
        if Config.Framework == 'qbcore' then
            player = QBCore.Functions.GetPlayer(source)
            local isAdmin = false
            for _, group in ipairs(Config.Admin.adminGroups) do
                if player.PlayerData.groups[group] then
                    isAdmin = true
                    break
                end
            end
            
            if not isAdmin then
                TriggerClientEvent('ichi-ban-kuji:client:notify', source, "你沒有權限執行此命令!", 'error')
                return
            end
        elseif Config.Framework == 'esx' then
            -- ESX 管理員檢查
        end
        
        if #args < 1 then
            TriggerClientEvent('ichi-ban-kuji:client:notify', source, "用法: /" .. Config.Admin.resetCommand .. " [machineId]", 'error')
            return
        end
        
        local machineId = args[1]
        local machineConfig
        
        for _, m in ipairs(Config.Machines) do
            if m.id == machineId then
                machineConfig = m
                break
            end
        end
        
        if machineConfig then
            db.resetMachine(machineId, machineConfig.maxTickets)
            TriggerClientEvent('ichi-ban-kuji:client:notify', source, Config.Notify.messages.machine_reset, 'success')
        else
            TriggerClientEvent('ichi-ban-kuji:client:notify', source, "無效的機器ID: " .. machineId, 'error')
        end
    end
end)

-- 取得機器狀態回呼
QBCore.Functions.CreateCallback('ichi-ban-kuji:server:getMachineStatus', function(source, cb, machineId)
    local status = db.getMachineStatus(machineId)
    cb(status)
end)

-- 取得玩家歷史記錄
QBCore.Functions.CreateCallback('ichi-ban-kuji:server:getPlayerHistory', function(source, cb)
    local identifiers = getPlayerIdentifiers(source)
    local history = {}
    
    for _, identifier in pairs(identifiers) do
        history = db.getPlayerHistory(identifier)
        if next(history) ~= nil then break end
    end
    
    cb(history)
end)

-- 資源啟動時初始化資料庫
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        db.init()
        
        -- 確保所有機器都在資料庫中有記錄
        for _, machine in ipairs(Config.Machines) do
            local status = db.getMachineStatus(machine.id)
            if not status then
                -- 初始化機器
                db.conn.insert('INSERT IGNORE INTO ichi_ban_kuji_machines (id, name, remaining_tickets) VALUES (?, ?, ?)', 
                    {machine.id, machine.name, machine.maxTickets})
                
                -- 初始化獎品
                for _, prize in ipairs(machine.prizes) do
                    db.conn.insert('INSERT IGNORE INTO ichi_ban_kuji_prizes (machine_id, tier) VALUES (?, ?)', 
                        {machine.id, prize.tier})
                end
            end
        end
    end
end)