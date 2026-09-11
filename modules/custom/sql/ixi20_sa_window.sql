-- Imagine XI 2.0: Sneak Attack recast 90s (30s window lives in ixi20_sa_window.lua).
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only. Restart xi_map after apply.

CREATE TABLE IF NOT EXISTS `ixi20_sa_window_recast_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `recastTime` SMALLINT(5) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_sa_window_recast_backup` (`abilityId`, `recastTime`)
SELECT `abilityId`, `recastTime` FROM `abilities` WHERE `abilityId` = 44;

UPDATE `abilities` SET `recastTime` = 90 WHERE `abilityId` = 44;
