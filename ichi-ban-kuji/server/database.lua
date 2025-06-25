local db = {}

-- 初始化資料庫連接
function db.init()
    if Config.Database.useOxMySQL then
        db.conn = exports.oxmysql
    else
        db.conn = MySQL
    end
end

-- 取得機器狀態
function db.getMachineStatus(machineId)
    local query = [[
        SELECT m.*, 
            (SELECT COUNT(*) FROM ichi_ban_kuji_prizes p WHERE p.machine_id = m.id AND p.tier = 'A') as a_prize,
            (SELECT COUNT(*) FROM ichi_ban_kuji_prizes p WHERE p.machine_id = m.id AND p.tier = 'B') as b_prize,
            (SELECT COUNT(*) FROM ichi_ban_kuji_prizes p WHERE p.machine_id = m.id AND p.tier = 'C') as c_prize,
            (SELECT COUNT(*) FROM ichi_ban_kuji_prizes p WHERE p.machine_id = m.id AND p.tier = 'D') as d_prize,
            (SELECT COUNT(*) FROM ichi_ban_kuji_prizes p WHERE p.machine_id = m.id AND p.tier = 'E') as e_prize
        FROM ichi_ban_kuji_machines m
        WHERE m.id = ?
    ]]
    
    return db.conn.single.await(query, {machineId})
end

-- 獲取獎品狀態
function db.getPrizeStatus(machineId, tier)
    local query = [[
        SELECT won_count FROM ichi_ban_kuji_prizes 
        WHERE machine_id = ? AND tier = ?
    ]]
    
    local result = db.conn.single.await(query, {machineId, tier})
    return result and result.won_count or 0
end

-- 更新獎品狀態
function db.updatePrizeStatus(machineId, tier)
    local query = [[
        UPDATE ichi_ban_kuji_prizes 
        SET won_count = won_count + 1 
        WHERE machine_id = ? AND tier = ?
    ]]
    
    return db.conn.update.await(query, {machineId, tier})
end

-- 更新機器狀態
function db.updateMachineStatus(machineId, remainingTickets)
    local query = [[
        UPDATE ichi_ban_kuji_machines 
        SET remaining_tickets = ? 
        WHERE id = ?
    ]]
    
    return db.conn.update.await(query, {remainingTickets, machineId})
end

-- 重置機器
function db.resetMachine(machineId, maxTickets)
    local query = [[
        UPDATE ichi_ban_kuji_machines 
        SET remaining_tickets = ?, last_reset = CURRENT_TIMESTAMP 
        WHERE id = ?
    ]]
    
    db.conn.update(query, {maxTickets, machineId})
    
    query = [[
        UPDATE ichi_ban_kuji_prizes 
        SET won_count = 0 
        WHERE machine_id = ?
    ]]
    
    db.conn.update(query, {machineId})
end

-- 記錄玩家抽獎
function db.recordPlayerDraw(identifier, machineId, tier)
    local query = [[
        INSERT INTO ichi_ban_kuji_players (identifier, machine_id, tier)
        VALUES (?, ?, ?)
    ]]
    
    db.conn.insert(query, {identifier, machineId, tier})
end

-- 檢查玩家是否已抽中某獎項
function db.hasPlayerWon(identifier, machineId, tier)
    local query = [[
        SELECT COUNT(*) as count FROM ichi_ban_kuji_players
        WHERE identifier = ? AND machine_id = ? AND tier = ?
    ]]
    
    local result = db.conn.single.await(query, {identifier, machineId, tier})
    return result and result.count > 0 or false
end

-- 取得玩家抽獎紀錄
function db.getPlayerHistory(identifier)
    local query = [[
        SELECT p.machine_id, m.name as machine_name, p.tier, p.won_at
        FROM ichi_ban_kuji_players p
        JOIN ichi_ban_kuji_machines m ON p.machine_id = m.id
        WHERE p.identifier = ?
        ORDER BY p.won_at DESC
        LIMIT 10
    ]]
    
    return db.conn.query.await(query, {identifier})
end

return db