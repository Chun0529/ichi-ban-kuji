-- 版本更新时可以添加的迁移脚本
ALTER TABLE `ichi_ban_kuji_machines` ADD COLUMN IF NOT EXISTS `reset_cooldown` INT DEFAULT 24 AFTER `last_reset`;

-- 添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS `idx_player_identifier` ON `ichi_ban_kuji_players` (`identifier`);
CREATE INDEX IF NOT EXISTS `idx_machine_id` ON `ichi_ban_kuji_prizes` (`machine_id`);