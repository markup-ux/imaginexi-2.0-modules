-- Revert Imagine XI 2.0 module SQL on xidb_ixi20 only.
-- After this: comment ixi20 lines in modules/init.txt and rebuild xi_map.

UPDATE `item_equipment` e
INNER JOIN `ixi20_item_equipment_jobs_backup` b ON b.`itemId` = e.`itemId`
SET e.`jobs` = b.`jobs`;

UPDATE `item_equipment` e
INNER JOIN `ixi20_item_equipment_level_backup` b ON b.`itemId` = e.`itemId`
SET e.`level` = b.`level`;

UPDATE `weapon_skills` w
INNER JOIN `ixi20_weapon_skills_jobs_backup` b ON b.`weaponskillid` = w.`weaponskillid`
SET w.`jobs` = b.`jobs`,
    w.`main_only` = b.`main_only`;

DELETE FROM `mob_groups`
WHERE `groupid` = 35 AND `zoneid` = 100 AND `name` = 'PixieRescue';

DELETE FROM `mob_groups`
WHERE `groupid` IN (36, 37)
  AND `zoneid` IN (100, 101, 106, 107, 115, 116)
  AND `name` IN ('StarterHNM', 'StarterHNM_Add');

DELETE FROM `mob_groups`
WHERE `groupid` BETWEEN 38 AND 45
  AND `zoneid` IN (100, 106, 116)
  AND `name` LIKE 'Starter_%';

DELETE FROM `mob_pools`
WHERE (`poolid` = 71 AND `name` = 'Air_Elemental')
   OR (`poolid` = 913 AND `name` = 'Dark_Elemental')
   OR (`poolid` = 1160 AND `name` = 'Earth_Elemental')
   OR (`poolid` = 1341 AND `name` = 'Fire_Elemental')
   OR (`poolid` = 2043 AND `name` = 'Ice_Elemental')
   OR (`poolid` = 2413 AND `name` = 'Light_Elemental')
   OR (`poolid` = 3912 AND `name` = 'Thunder_Elemental')
   OR (`poolid` = 4309 AND `name` = 'Water_Elemental');

DELETE FROM `mob_pools`
WHERE `poolid` = 3148 AND `name` = 'Pixie';

DELETE FROM `mob_pools`
WHERE (`poolid` = 4344 AND `name` = 'Wild_Sheep')
   OR (`poolid` = 3381 AND `name` = 'Rock_Lizard')
   OR (`poolid` = 3924 AND `name` = 'Tiny_Mandragora');

UPDATE `abilities` a
INNER JOIN `ixi20_corsair_roll_level_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`level` = b.`level`;

CREATE TABLE IF NOT EXISTS `ixi20_smn_support_pact_level_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

UPDATE `abilities` a
INNER JOIN `ixi20_smn_support_pact_level_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`level` = b.`level`;

UPDATE `abilities` a
INNER JOIN `ixi20_abilities_level_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`level` = b.`level`;

DELETE FROM `traits` WHERE `job` BETWEEN 1 AND 22;
INSERT INTO `traits`
SELECT * FROM `ixi20_traits_backup` WHERE `job` BETWEEN 1 AND 22;

UPDATE `spell_list` s
INNER JOIN `ixi20_spell_jobs_backup` b ON b.`spellid` = s.`spellid`
SET s.`jobs` = b.`jobs`;

DELETE FROM `abilities_charges` WHERE `recastId` = 231 AND `job` = 20;
INSERT INTO `abilities_charges`
SELECT * FROM `ixi20_abilities_charges_backup`;

UPDATE `abilities` a
INNER JOIN `ixi20_cascade_recast_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`recastTime` = b.`recastTime`;

UPDATE `abilities` a
INNER JOIN `ixi20_manifestation_recast_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`recastTime` = b.`recastTime`;

UPDATE `abilities` a
INNER JOIN `ixi20_mana_wall_recast_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`recastTime` = b.`recastTime`;

UPDATE `abilities` a
INNER JOIN `ixi20_sa_window_recast_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`recastTime` = b.`recastTime`;

UPDATE `skill_ranks` s
INNER JOIN `ixi20_skill_ranks_backup` b ON b.`skillid` = s.`skillid`
SET s.`name` = b.`name`,
    s.`war` = b.`war`, s.`mnk` = b.`mnk`, s.`whm` = b.`whm`, s.`blm` = b.`blm`,
    s.`rdm` = b.`rdm`, s.`thf` = b.`thf`, s.`pld` = b.`pld`, s.`drk` = b.`drk`,
    s.`bst` = b.`bst`, s.`brd` = b.`brd`, s.`rng` = b.`rng`, s.`sam` = b.`sam`,
    s.`nin` = b.`nin`, s.`drg` = b.`drg`, s.`smn` = b.`smn`, s.`blu` = b.`blu`,
    s.`cor` = b.`cor`, s.`pup` = b.`pup`, s.`dnc` = b.`dnc`, s.`sch` = b.`sch`,
    s.`geo` = b.`geo`, s.`run` = b.`run`;

DROP TABLE IF EXISTS `dropped_casket_items`;
DROP TABLE IF EXISTS `dropped_caskets`;
DROP TABLE IF EXISTS `ixi20_item_equipment_jobs_backup`;
DROP TABLE IF EXISTS `ixi20_item_equipment_level_backup`;
DROP TABLE IF EXISTS `ixi20_weapon_skills_jobs_backup`;
DROP TABLE IF EXISTS `ixi20_corsair_roll_level_backup`;
DROP TABLE IF EXISTS `ixi20_smn_support_pact_level_backup`;
DROP TABLE IF EXISTS `ixi20_abilities_level_backup`;
DROP TABLE IF EXISTS `ixi20_traits_backup`;
DROP TABLE IF EXISTS `ixi20_spell_jobs_backup`;
DROP TABLE IF EXISTS `ixi20_abilities_charges_backup`;
DROP TABLE IF EXISTS `ixi20_sch_ability_level_backup`;
DROP TABLE IF EXISTS `ixi20_cascade_recast_backup`;
DROP TABLE IF EXISTS `ixi20_manifestation_recast_backup`;
DROP TABLE IF EXISTS `ixi20_mana_wall_recast_backup`;
DROP TABLE IF EXISTS `ixi20_sa_window_recast_backup`;
DROP TABLE IF EXISTS `ixi20_skill_ranks_backup`;

-- AF1 weapons (ixi20_af1_weapons.sql). Run before no_perpetuation revert so
-- Dragon Staff Summoning+10 is cleared, then perp-1 can be restored.
CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_pet_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`, `petType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_level_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `level`  tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_dmg_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `dmg`    int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `item_mods` WHERE `itemId` IN (
    16678, 17478, 17422, 17532, 16829, 16764, 17643, 16798, 16680, 16766,
    17188, 17812, 17771, 17772, 16887, 17597, 17717, 18702, 17858, 19203
);
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value` FROM `ixi20_af1_weapons_mods_backup`;

DELETE FROM `item_mods_pet` WHERE `itemId` IN (16680, 16887, 17597, 17858);
INSERT IGNORE INTO `item_mods_pet` (`itemId`, `modId`, `value`, `petType`)
SELECT `itemId`, `modId`, `value`, `petType` FROM `ixi20_af1_weapons_pet_mods_backup`;

UPDATE `item_equipment` e
INNER JOIN `ixi20_af1_weapons_level_backup` b ON b.`itemId` = e.`itemId`
SET e.`level` = b.`level`;

UPDATE `item_weapon` w
INNER JOIN `ixi20_af1_weapons_dmg_backup` b ON b.`itemId` = w.`itemId`
SET w.`dmg` = b.`dmg`;

DROP TABLE IF EXISTS `ixi20_af1_weapons_mods_backup`;
DROP TABLE IF EXISTS `ixi20_af1_weapons_pet_mods_backup`;
DROP TABLE IF EXISTS `ixi20_af1_weapons_level_backup`;
DROP TABLE IF EXISTS `ixi20_af1_weapons_dmg_backup`;

-- Perpetuation gear remaps (ixi20_no_perpetuation.sql)
CREATE TABLE IF NOT EXISTS `ixi20_perp_item_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE TABLE IF NOT EXISTS `ixi20_perp_item_mods_pet_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE TABLE IF NOT EXISTS `ixi20_perp_item_latents_backup` (
  `itemId` smallint(5) UNSIGNED NOT NULL,
  `modId` smallint(5) UNSIGNED NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `latentId` smallint(5) NOT NULL,
  `latentParam` smallint(5) NOT NULL,
  PRIMARY KEY (`itemId`, `modId`, `value`, `latentId`, `latentParam`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE TABLE IF NOT EXISTS `ixi20_perp_augments_backup` (
  `augmentId` smallint(5) unsigned NOT NULL,
  `multiplier` smallint(2) NOT NULL DEFAULT 0,
  `modId` smallint(5) unsigned NOT NULL DEFAULT 0,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `isPet` tinyint(1) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`augmentId`, `multiplier`, `modId`, `isPet`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELETE FROM `item_mods` WHERE (`itemId`, `modId`) IN (
  (10321,117),(10664,117),(10684,117),(11098,993),(11158,117),(11198,993),(11258,117),
  (13814,117),(13815,117),(14625,993),(14906,117),(15366,117),(15430,117),(17528,117),
  (17597,117),(17598,993),(19005,117),(19074,117),(19094,117),(19626,117),(19724,117),
  (19833,117),(19962,117),(21141,117),(21142,117),(22076,117),(22077,117),(23077,117),
  (23144,117),(23166,993),(23322,117),(23367,117),(23657,117),(26652,117),(26653,117),
  (26828,117),(26829,117),(26926,993),(26927,993),(27380,117),(27381,117),(27439,117),
  (27440,117),(27534,117),(28237,117),(28258,117),(28296,117),(28416,993),
  (11118,117),(11118,993),(11218,117),(14062,117),(23233,117),(23233,993),
  (27080,117),(27080,993),(27081,117),(27081,993),(27106,117),(27107,117)
);

INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value` FROM `ixi20_perp_item_mods_backup`;

DELETE FROM `item_mods_pet` WHERE (`itemId`, `modId`, `petType`) IN ((10664,30,1),(10684,30,1));
INSERT IGNORE INTO `item_mods_pet` (`itemId`, `modId`, `value`, `petType`)
SELECT `itemId`, `modId`, `value`, `petType` FROM `ixi20_perp_item_mods_pet_backup`;

DELETE FROM `item_latents` WHERE (`itemId`, `modId`, `value`, `latentId`, `latentParam`) IN (
  (11752,117,5,9,16),(12493,117,5,9,9),(13300,117,5,2,75),(14401,117,5,9,7),(14410,117,5,9,6),
  (14946,117,5,13,2),(14946,117,5,13,19),(15285,117,6,8,15),(16154,117,6,9,13),(25633,117,5,9,8)
);
INSERT IGNORE INTO `item_latents` (`itemId`, `modId`, `value`, `latentId`, `latentParam`)
SELECT `itemId`, `modId`, `value`, `latentId`, `latentParam` FROM `ixi20_perp_item_latents_backup`;

DELETE FROM `augments` WHERE `augmentId` = 321 AND `modId` = 117;
INSERT IGNORE INTO `augments` (`augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType`)
SELECT `augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType` FROM `ixi20_perp_augments_backup`;

DROP TABLE IF EXISTS `ixi20_perp_item_mods_backup`;
DROP TABLE IF EXISTS `ixi20_perp_item_mods_pet_backup`;
DROP TABLE IF EXISTS `ixi20_perp_item_latents_backup`;
DROP TABLE IF EXISTS `ixi20_perp_augments_backup`;

-- Blood Pact timer remaps (ixi20_no_bp_timers.sql)
CREATE TABLE IF NOT EXISTS `ixi20_bp_ability_recast_backup` (
  `abilityId` smallint(5) unsigned NOT NULL,
  `recastId` smallint(5) unsigned NOT NULL,
  `recastTime` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`abilityId`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE TABLE IF NOT EXISTS `ixi20_bp_item_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE TABLE IF NOT EXISTS `ixi20_bp_item_mods_pet_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE TABLE IF NOT EXISTS `ixi20_bp_augments_backup` (
  `augmentId` smallint(5) unsigned NOT NULL,
  `multiplier` smallint(2) NOT NULL DEFAULT 0,
  `modId` smallint(5) unsigned NOT NULL DEFAULT 0,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `isPet` tinyint(1) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`augmentId`, `multiplier`, `modId`, `isPet`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

UPDATE `abilities` a
INNER JOIN `ixi20_bp_ability_recast_backup` b ON b.`abilityId` = a.`abilityId`
SET a.`recastId` = b.`recastId`,
    a.`recastTime` = b.`recastTime`;

DELETE FROM `item_mods` WHERE (`itemId`, `modId`) IN (
  (10664,993),(10684,993),(10704,993),(10724,993),(10744,993),(11052,993),(11564,993),
  (11717,993),(11982,993),(12210,993),(12211,993),(12212,993),(12493,993),(13814,993),
  (13815,993),(13939,993),(13940,993),(14468,993),(14487,993),(14514,993),(14826,993),
  (14827,993),(14904,993),(14923,993),(15086,993),(15101,993),(15116,993),(15131,993),
  (15146,993),(15259,993),(15594,993),(15679,993),(17573,993),(21394,993),(21395,993),
  (23077,993),(23121,993),(23211,993),(23278,993),(23456,993),(26652,993),(26653,993),
  (26888,993),(27004,993),(27005,993),(27180,993),(27181,993),(27356,993),(27534,993),
  (27677,993),(27698,993),(27821,993),(27842,993),(27957,993),(27978,993),(28605,993),
  (21377,992),(21381,992),(21383,992),(21432,992),(23144,992),(23345,992),(23680,992),
  (26828,992),(26829,992),(26852,992),(26853,992),(27357,992)
);
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value` FROM `ixi20_bp_item_mods_backup`;

DELETE FROM `item_mods_pet` WHERE (`itemId`, `modId`, `petType`) IN ((15146,30,1),(15679,30,1));
INSERT IGNORE INTO `item_mods_pet` (`itemId`, `modId`, `value`, `petType`)
SELECT `itemId`, `modId`, `value`, `petType` FROM `ixi20_bp_item_mods_pet_backup`;

DELETE FROM `augments` WHERE `augmentId` = 320 AND `modId` = 993;
INSERT IGNORE INTO `augments` (`augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType`)
SELECT `augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType` FROM `ixi20_bp_augments_backup`;

DROP TABLE IF EXISTS `ixi20_bp_ability_recast_backup`;
DROP TABLE IF EXISTS `ixi20_bp_item_mods_backup`;
DROP TABLE IF EXISTS `ixi20_bp_item_mods_pet_backup`;
DROP TABLE IF EXISTS `ixi20_bp_augments_backup`;

-- Swift / Velocious shared haste package (ixi20_haste_belts.sql)
CREATE TABLE IF NOT EXISTS `ixi20_haste_belts_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `ixi20_haste_belts_level_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `level`  tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `item_mods` WHERE `itemId` IN (15457, 15899);
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value` FROM `ixi20_haste_belts_mods_backup`;

UPDATE `item_equipment` e
INNER JOIN `ixi20_haste_belts_level_backup` b ON b.`itemId` = e.`itemId`
SET e.`level` = b.`level`;

DROP TABLE IF EXISTS `ixi20_haste_belts_mods_backup`;
DROP TABLE IF EXISTS `ixi20_haste_belts_level_backup`;

-- Flatten latents (ixi20_flatten_latents.sql). Apply after that SQL so backup tables exist.
CREATE TABLE IF NOT EXISTS `ixi20_flatten_latents_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `latentId` smallint(5) NOT NULL,
  `latentParam` smallint(5) NOT NULL,
  PRIMARY KEY (`itemId`, `modId`, `value`, `latentId`, `latentParam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `ixi20_flatten_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE m FROM `item_mods` m
INNER JOIN (SELECT DISTINCT `itemId` FROM `ixi20_flatten_latents_backup`) x ON x.`itemId` = m.`itemId`;
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value` FROM `ixi20_flatten_mods_backup`;

DELETE l FROM `item_latents` l
INNER JOIN (SELECT DISTINCT `itemId` FROM `ixi20_flatten_latents_backup`) x ON x.`itemId` = l.`itemId`;
INSERT IGNORE INTO `item_latents` (`itemId`, `modId`, `value`, `latentId`, `latentParam`)
SELECT `itemId`, `modId`, `value`, `latentId`, `latentParam` FROM `ixi20_flatten_latents_backup`;

DROP TABLE IF EXISTS `ixi20_flatten_latents_backup`;
DROP TABLE IF EXISTS `ixi20_flatten_mods_backup`;

UPDATE `zone_settings` SET `zoneip` = '127.0.0.1' WHERE `zoneport` > 0;

-- Restore retail AH seller gil mail (ixi20_ah_gifts.sql)
DROP TRIGGER IF EXISTS auction_house_buy;
DELIMITER $$
CREATE TRIGGER auction_house_buy
    BEFORE UPDATE ON auction_house
    FOR EACH ROW
BEGIN
    IF OLD.seller != 0 AND NEW.sale != 0 THEN INSERT INTO delivery_box VALUES (NEW.seller, NEW.seller_name, 1, 0, 0xFFFF, NEW.itemid, NEW.sale, NULL, 0, 'AH-Jeuno', 0, 0); END IF;
END $$
DELIMITER ;
