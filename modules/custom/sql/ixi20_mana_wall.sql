-- Imagine XI 2.0: Mana Wall recast 180s when turning on.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_mana_wall_recast_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `recastTime` SMALLINT(5) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_mana_wall_recast_backup` (`abilityId`, `recastTime`)
SELECT `abilityId`, `recastTime` FROM `abilities` WHERE `abilityId` = 254;

UPDATE `abilities` SET `recastTime` = 180 WHERE `abilityId` = 254;
