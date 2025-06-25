-- 创建一番赏机器表
CREATE TABLE IF NOT EXISTS `ichi_ban_kuji_machines` (
    `id` VARCHAR(50) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `remaining_tickets` INT NOT NULL,
    `last_reset` TIMESTAMP NULL DEFAULT NULL,
    `is_active` BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 创建奖品表
CREATE TABLE IF NOT EXISTS `ichi_ban_kuji_prizes` (
    `id` INT AUTO_INCREMENT,
    `machine_id` VARCHAR(50) NOT NULL,
    `tier` VARCHAR(10) NOT NULL,
    `won_count` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`machine_id`) REFERENCES `ichi_ban_kuji_machines`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 创建玩家记录表
CREATE TABLE IF NOT EXISTS `ichi_ban_kuji_players` (
    `id` INT AUTO_INCREMENT,
    `identifier` VARCHAR(50) NOT NULL,
    `machine_id` VARCHAR(50) NOT NULL,
    `tier` VARCHAR(10) NOT NULL,
    `won_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`machine_id`) REFERENCES `ichi_ban_kuji_machines`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 初始化机器数据
INSERT IGNORE INTO `ichi_ban_kuji_machines` (`id`, `name`, `remaining_tickets`)
VALUES ('premium_set', 'Premium 一番赏', 200);

-- 初始化奖品数据
INSERT IGNORE INTO `ichi_ban_kuji_prizes` (`machine_id`, `tier`, `won_count`)
VALUES 
('premium_set', 'A', 0),
('premium_set', 'B', 0),
('premium_set', 'C', 0),
('premium_set', 'D', 0),
('premium_set', 'E', 0);