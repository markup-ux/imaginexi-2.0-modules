-- Imagine XI 2.0: SCH 5 stratagem charges / 48s from first unlock; Cascade recast 90s.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_abilities_charges_backup` (
    `recastId` SMALLINT(5) UNSIGNED NOT NULL,
    `job` TINYINT(2) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    `maxCharges` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `chargeTime` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
    `meritModID` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`recastId`, `job`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_abilities_charges_backup`
SELECT * FROM `abilities_charges`
WHERE `recastId` = 231 AND `job` = 20;

CREATE TABLE IF NOT EXISTS `ixi20_cascade_recast_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `recastTime` SMALLINT(5) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_cascade_recast_backup` (`abilityId`, `recastTime`)
SELECT `abilityId`, `recastTime` FROM `abilities` WHERE `abilityId` = 388;

DELETE FROM `abilities_charges` WHERE `recastId` = 231 AND `job` = 20;
INSERT INTO `abilities_charges` VALUES (231, 20, 1, 5, 48, 0);

UPDATE `abilities` SET `recastTime` = 90 WHERE `abilityId` = 388;
