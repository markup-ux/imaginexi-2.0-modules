-- Imagine XI 2.0: Cascade recast 90s.
-- SCH charge pool lives in ixi20_sch_charges.sql.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_cascade_recast_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `recastTime` SMALLINT(5) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_cascade_recast_backup` (`abilityId`, `recastTime`)
SELECT `abilityId`, `recastTime` FROM `abilities` WHERE `abilityId` = 388;

UPDATE `abilities` SET `recastTime` = 90 WHERE `abilityId` = 388;
