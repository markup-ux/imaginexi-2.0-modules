-- Imagine XI 2.0: AF1 weapons stay Lv.40 with keep-worthy stats.
-- Armor AF1 remains Lv.50 via ixi20_af_levels.sql. Delay is unchanged.
-- Apply after ixi20_no_perpetuation.sql so Dragon Staff Summoning+10 wins
-- over the perp remap. Native Examine text is 108.DAT
-- (python tools/scripts/ixi20_patch_af1_weapon_dats.py). Overlay text in
-- Windower/res/item_descriptions.lua.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

-- WAR 16678 razor_axe
-- MNK 17478 beat_cesti
-- WHM 17422 blessed_hammer
-- BLM 17532 kukulcans_staff
-- RDM 16829 fencing_degen
-- THF 16764 marauders_knife
-- PLD 17643 honor_sword
-- DRK 16798 raven_scythe
-- BST 16680 barbaroi_axe
-- BRD 16766 paper_knife
-- RNG 17188 sniping_bow
-- SAM 17812 magoroku
-- NIN 17771 anju / 17772 zushio
-- DRG 16887 peregrine
-- SMN 17597 dragon_staff
-- BLU 17717 immortals_scimitar
-- COR 18702 trump_gun
-- PUP 17858 turbo_animator
-- DNC 19203 war_hoop

-- ----------------------------------------------------------------
-- Backups (first apply only)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_af1_weapons_mods_backup` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value`
FROM `item_mods`
WHERE `itemId` IN (
    16678, 17478, 17422, 17532, 16829, 16764, 17643, 16798, 16680, 16766,
    17188, 17812, 17771, 17772, 16887, 17597, 17717, 18702, 17858, 19203
);

CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_pet_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`, `petType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_af1_weapons_pet_mods_backup` (`itemId`, `modId`, `value`, `petType`)
SELECT `itemId`, `modId`, `value`, `petType`
FROM `item_mods_pet`
WHERE `itemId` IN (16680, 16887, 17597, 17858);

CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_level_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `level`  tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_af1_weapons_level_backup` (`itemId`, `level`)
SELECT `itemId`, `level`
FROM `item_equipment`
WHERE `itemId` IN (
    16678, 17478, 17422, 17532, 16829, 16764, 17643, 16798, 16680, 16766,
    17188, 17812, 17771, 17772, 16887, 17597, 17717, 18702, 17858, 19203
);

CREATE TABLE IF NOT EXISTS `ixi20_af1_weapons_dmg_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `dmg`    int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_af1_weapons_dmg_backup` (`itemId`, `dmg`)
SELECT `itemId`, `dmg`
FROM `item_weapon`
WHERE `itemId` IN (
    16678, 17478, 17422, 17532, 16829, 16764, 17643, 16798, 16680, 16766,
    17188, 17812, 17771, 17772, 16887, 17597, 17717, 18702, 17858, 19203
);

-- ----------------------------------------------------------------
-- Wear level 40
-- ----------------------------------------------------------------
UPDATE `item_equipment` SET `level` = 40 WHERE `itemId` IN (
    16678, 17478, 17422, 17532, 16829, 16764, 17643, 16798, 16680, 16766,
    17188, 17812, 17771, 17772, 16887, 17597, 17717, 18702, 17858, 19203
);

-- ----------------------------------------------------------------
-- Damage (delay unchanged)
-- ----------------------------------------------------------------
UPDATE `item_weapon` SET `dmg` = 38 WHERE `itemId` = 16678; -- razor_axe
UPDATE `item_weapon` SET `dmg` = 10 WHERE `itemId` = 17478; -- beat_cesti
UPDATE `item_weapon` SET `dmg` = 32 WHERE `itemId` = 17422; -- blessed_hammer
UPDATE `item_weapon` SET `dmg` = 28 WHERE `itemId` = 17532; -- kukulcans_staff
UPDATE `item_weapon` SET `dmg` = 30 WHERE `itemId` = 16829; -- fencing_degen
UPDATE `item_weapon` SET `dmg` = 24 WHERE `itemId` = 16764; -- marauders_knife
UPDATE `item_weapon` SET `dmg` = 34 WHERE `itemId` = 17643; -- honor_sword
UPDATE `item_weapon` SET `dmg` = 82 WHERE `itemId` = 16798; -- raven_scythe
UPDATE `item_weapon` SET `dmg` = 38 WHERE `itemId` = 16680; -- barbaroi_axe
UPDATE `item_weapon` SET `dmg` = 22 WHERE `itemId` = 16766; -- paper_knife
UPDATE `item_weapon` SET `dmg` = 36 WHERE `itemId` = 17188; -- sniping_bow
UPDATE `item_weapon` SET `dmg` = 70 WHERE `itemId` = 17812; -- magoroku
UPDATE `item_weapon` SET `dmg` = 26 WHERE `itemId` = 17771; -- anju
UPDATE `item_weapon` SET `dmg` = 28 WHERE `itemId` = 17772; -- zushio
UPDATE `item_weapon` SET `dmg` = 74 WHERE `itemId` = 16887; -- peregrine
UPDATE `item_weapon` SET `dmg` = 24 WHERE `itemId` = 17597; -- dragon_staff
UPDATE `item_weapon` SET `dmg` = 32 WHERE `itemId` = 17717; -- immortals_scimitar
UPDATE `item_weapon` SET `dmg` = 36 WHERE `itemId` = 18702; -- trump_gun
UPDATE `item_weapon` SET `dmg` = 28 WHERE `itemId` = 19203; -- war_hoop

-- ----------------------------------------------------------------
-- Player mods
-- 2 HP, 5 MP, 8 STR, 9 DEX, 10 VIT, 11 AGI, 12 INT, 13 MND, 14 CHR
-- 23 ATT, 24 RATT, 25 ACC, 26 RACC, 27 ENMITY, 28 MATT
-- 68 EVA, 73 STORETP
-- 101 AUTO_MELEE, 103 AUTO_MAGIC
-- 109 SHIELD, 111 DIVINE, 112 HEALING, 113 ENHANCE, 114 ENFEEBLE
-- 115 ELEM, 116 DARK, 117 SUMMONING, 118 NINJUTSU, 119 SINGING
-- 120 STRING, 121 WIND, 122 BLUE
-- 165 CRITHITRATE, 170 FASTCAST
-- 288 DOUBLE_ATTACK, 289 SUBTLE_BLOW, 291 COUNTER, 292 KICK_ATTACK_RATE
-- 303 TREASURE_HUNTER, 306 ZANSHIN, 315 ENH_DRAIN_ASPIR
-- 365 SNAPSHOT, 374 CURE_POTENCY, 391 CHARM_CHANCE, 402 WYVERN_BREATH
-- 490 SAMBA_DURATION, 491 WALTZ_POTENCY
-- 834 QUICK_DRAW_DMG_PERCENT, 854 REPAIR_POTENCY, 881 PHANTOM_ROLL
-- ----------------------------------------------------------------
DELETE FROM `item_mods` WHERE `itemId` IN (
    16678, 17478, 17422, 17532, 16829, 16764, 17643, 16798, 16680, 16766,
    17188, 17812, 17771, 17772, 16887, 17597, 17717, 18702, 17858, 19203
);

-- WAR Razor Axe
INSERT INTO `item_mods` VALUES (16678, 8, 6);
INSERT INTO `item_mods` VALUES (16678, 9, 4);
INSERT INTO `item_mods` VALUES (16678, 25, 8);
INSERT INTO `item_mods` VALUES (16678, 73, 4);
INSERT INTO `item_mods` VALUES (16678, 288, 3);

-- MNK Beat Cesti
INSERT INTO `item_mods` VALUES (17478, 9, 5);
INSERT INTO `item_mods` VALUES (17478, 10, 4);
INSERT INTO `item_mods` VALUES (17478, 25, 8);
INSERT INTO `item_mods` VALUES (17478, 73, 3);
INSERT INTO `item_mods` VALUES (17478, 291, 5);
INSERT INTO `item_mods` VALUES (17478, 292, 6);

-- WHM Blessed Hammer
INSERT INTO `item_mods` VALUES (17422, 5, 30);
INSERT INTO `item_mods` VALUES (17422, 13, 6);
INSERT INTO `item_mods` VALUES (17422, 112, 8);
INSERT INTO `item_mods` VALUES (17422, 113, 5);
INSERT INTO `item_mods` VALUES (17422, 374, 6);

-- BLM Kukulcan's Staff
INSERT INTO `item_mods` VALUES (17532, 5, 40);
INSERT INTO `item_mods` VALUES (17532, 12, 6);
INSERT INTO `item_mods` VALUES (17532, 28, 8);
INSERT INTO `item_mods` VALUES (17532, 115, 8);
INSERT INTO `item_mods` VALUES (17532, 170, 4);

-- RDM Fencing Degen
INSERT INTO `item_mods` VALUES (16829, 5, 25);
INSERT INTO `item_mods` VALUES (16829, 12, 4);
INSERT INTO `item_mods` VALUES (16829, 13, 4);
INSERT INTO `item_mods` VALUES (16829, 25, 6);
INSERT INTO `item_mods` VALUES (16829, 113, 6);
INSERT INTO `item_mods` VALUES (16829, 114, 6);
INSERT INTO `item_mods` VALUES (16829, 170, 3);

-- THF Marauder's Knife
INSERT INTO `item_mods` VALUES (16764, 9, 6);
INSERT INTO `item_mods` VALUES (16764, 11, 4);
INSERT INTO `item_mods` VALUES (16764, 25, 8);
INSERT INTO `item_mods` VALUES (16764, 165, 4);
INSERT INTO `item_mods` VALUES (16764, 303, 1);

-- PLD Honor Sword
INSERT INTO `item_mods` VALUES (17643, 2, 30);
INSERT INTO `item_mods` VALUES (17643, 10, 5);
INSERT INTO `item_mods` VALUES (17643, 13, 5);
INSERT INTO `item_mods` VALUES (17643, 25, 5);
INSERT INTO `item_mods` VALUES (17643, 27, 4);
INSERT INTO `item_mods` VALUES (17643, 109, 6);
INSERT INTO `item_mods` VALUES (17643, 111, 6);

-- DRK Raven Scythe
INSERT INTO `item_mods` VALUES (16798, 8, 6);
INSERT INTO `item_mods` VALUES (16798, 12, 5);
INSERT INTO `item_mods` VALUES (16798, 25, 8);
INSERT INTO `item_mods` VALUES (16798, 116, 8);
INSERT INTO `item_mods` VALUES (16798, 315, 5);

-- BST Barbaroi Axe
INSERT INTO `item_mods` VALUES (16680, 8, 5);
INSERT INTO `item_mods` VALUES (16680, 14, 6);
INSERT INTO `item_mods` VALUES (16680, 391, 5);

-- BRD Paper Knife
INSERT INTO `item_mods` VALUES (16766, 14, 6);
INSERT INTO `item_mods` VALUES (16766, 25, 4);
INSERT INTO `item_mods` VALUES (16766, 119, 8);
INSERT INTO `item_mods` VALUES (16766, 120, 6);
INSERT INTO `item_mods` VALUES (16766, 121, 6);

-- RNG Sniping Bow
INSERT INTO `item_mods` VALUES (17188, 11, 6);
INSERT INTO `item_mods` VALUES (17188, 24, 10);
INSERT INTO `item_mods` VALUES (17188, 26, 12);
INSERT INTO `item_mods` VALUES (17188, 365, 6);

-- SAM Magoroku
INSERT INTO `item_mods` VALUES (17812, 8, 6);
INSERT INTO `item_mods` VALUES (17812, 25, 8);
INSERT INTO `item_mods` VALUES (17812, 73, 5);
INSERT INTO `item_mods` VALUES (17812, 306, 5);

-- NIN Anju
INSERT INTO `item_mods` VALUES (17771, 9, 5);
INSERT INTO `item_mods` VALUES (17771, 25, 6);
INSERT INTO `item_mods` VALUES (17771, 68, 6);
INSERT INTO `item_mods` VALUES (17771, 73, 3);
INSERT INTO `item_mods` VALUES (17771, 118, 6);

-- NIN Zushio
INSERT INTO `item_mods` VALUES (17772, 8, 5);
INSERT INTO `item_mods` VALUES (17772, 23, 8);
INSERT INTO `item_mods` VALUES (17772, 25, 6);
INSERT INTO `item_mods` VALUES (17772, 289, 5);

-- DRG Peregrine
INSERT INTO `item_mods` VALUES (16887, 8, 5);
INSERT INTO `item_mods` VALUES (16887, 9, 4);
INSERT INTO `item_mods` VALUES (16887, 25, 8);
INSERT INTO `item_mods` VALUES (16887, 402, 5);

-- SMN Dragon Staff
INSERT INTO `item_mods` VALUES (17597, 5, 40);
INSERT INTO `item_mods` VALUES (17597, 117, 10);

-- BLU Immortal's Scimitar
INSERT INTO `item_mods` VALUES (17717, 5, 25);
INSERT INTO `item_mods` VALUES (17717, 8, 5);
INSERT INTO `item_mods` VALUES (17717, 12, 5);
INSERT INTO `item_mods` VALUES (17717, 25, 6);
INSERT INTO `item_mods` VALUES (17717, 28, 5);
INSERT INTO `item_mods` VALUES (17717, 122, 8);

-- COR Trump Gun
INSERT INTO `item_mods` VALUES (18702, 11, 5);
INSERT INTO `item_mods` VALUES (18702, 24, 8);
INSERT INTO `item_mods` VALUES (18702, 26, 10);
INSERT INTO `item_mods` VALUES (18702, 834, 10);
INSERT INTO `item_mods` VALUES (18702, 881, 2);

-- PUP Turbo Animator
INSERT INTO `item_mods` VALUES (17858, 9, 4);
INSERT INTO `item_mods` VALUES (17858, 101, 8);
INSERT INTO `item_mods` VALUES (17858, 103, 8);
INSERT INTO `item_mods` VALUES (17858, 854, 8);

-- DNC War Hoop
INSERT INTO `item_mods` VALUES (19203, 9, 4);
INSERT INTO `item_mods` VALUES (19203, 14, 6);
INSERT INTO `item_mods` VALUES (19203, 25, 6);
INSERT INTO `item_mods` VALUES (19203, 490, 20);
INSERT INTO `item_mods` VALUES (19203, 491, 8);

-- ----------------------------------------------------------------
-- Pet mods (PetModType: All=0 Avatar=1 Wyvern=2 Automaton=3)
-- 23 ATT, 25 ACC, 28 MATT, 30 MACC
-- ----------------------------------------------------------------
DELETE FROM `item_mods_pet` WHERE `itemId` IN (16680, 16887, 17597, 17858);

INSERT INTO `item_mods_pet` VALUES (16680, 23, 8, 0); -- barbaroi_axe All Pets ATT+8
INSERT INTO `item_mods_pet` VALUES (16680, 25, 8, 0); -- barbaroi_axe All Pets ACC+8
INSERT INTO `item_mods_pet` VALUES (16887, 23, 8, 2); -- peregrine Wyvern ATT+8
INSERT INTO `item_mods_pet` VALUES (16887, 25, 8, 2); -- peregrine Wyvern ACC+8
INSERT INTO `item_mods_pet` VALUES (17597, 28, 8, 1); -- dragon_staff Avatar MATT+8
INSERT INTO `item_mods_pet` VALUES (17597, 30, 8, 1); -- dragon_staff Avatar MACC+8
INSERT INTO `item_mods_pet` VALUES (17858, 25, 8, 3); -- turbo_animator Automaton ACC+8
