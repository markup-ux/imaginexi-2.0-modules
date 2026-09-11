-- Imagine XI 2.0: Manifestation costs no Stratagem charge.
-- Accession is always-on in Lua/C++; this only zeros Manifestation's
-- charge cost (recastTime 1 = one charge). Restart xi_map after apply.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_manifestation_recast_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `recastTime` SMALLINT(5) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_manifestation_recast_backup` (`abilityId`, `recastTime`)
SELECT `abilityId`, `recastTime` FROM `abilities` WHERE `abilityId` = 222;

UPDATE `abilities` SET `recastTime` = 0 WHERE `abilityId` = 222;
