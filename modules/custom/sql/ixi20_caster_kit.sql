-- Imagine XI 2.0: Accession and Manifestation cost no Stratagem charge.
-- They are Lua toggles (ixi20_caster_kit.lua). recastTime 1 = one charge.
-- Restart xi_map after apply. Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_manifestation_recast_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `recastTime` SMALLINT(5) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_manifestation_recast_backup` (`abilityId`, `recastTime`)
SELECT `abilityId`, `recastTime` FROM `abilities` WHERE `abilityId` IN (218, 222);

UPDATE `abilities` SET `recastTime` = 0 WHERE `abilityId` IN (218, 222);
