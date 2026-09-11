-- Imagine XI 2.0: SCH Arts + all stratagems at level 1, and 5 charges / 48s.
-- Apply after ixi20_job_progression_37cap.sql and ixi20_ja_windows.sql.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only. Restart xi_map after apply.

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

DELETE FROM `abilities_charges` WHERE `recastId` = 231 AND `job` = 20;
INSERT INTO `abilities_charges` VALUES (231, 20, 1, 5, 48, 0);

CREATE TABLE IF NOT EXISTS `ixi20_sch_ability_level_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_sch_ability_level_backup` (`abilityId`, `level`)
SELECT `abilityId`, `level` FROM `abilities`
WHERE `abilityId` IN (
    211, -- light_arts
    212, -- dark_arts
    215, -- penury
    216, -- celerity
    217, -- rapture
    218, -- accession
    219, -- parsimony
    220, -- alacrity
    221, -- ebullience
    222, -- manifestation
    223, -- stratagems
    234, -- addendum_white
    235, -- addendum_black
    240, -- altruism
    241, -- focalization
    242, -- tranquility
    243, -- equanimity
    316, -- perpetuance
    317  -- immanence
);

UPDATE `abilities` SET `level` = 1 WHERE `abilityId` IN (
    211, 212, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    234, 235, 240, 241, 242, 243, 316, 317
);
