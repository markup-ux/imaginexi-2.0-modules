-- Imagine XI 2.0: no Blood Pact timers + remap Blood Pact delay gear.
-- 1.0: z_imagine_xi_30_smn_no_perp_no_bp_timers.sql + z_imagine_xi_80_item_rebalance.sql
--
-- Recast IDs 173/174 are kept (LSB Recast 0 is the 2-hour). recastTime is 0.
-- BP_DELAY (357) -> PET_MACC_MEVA (993) at |old| + 4 (1.0 curve).
-- BP_DELAY_II (541) -> PET_MAB_MDB (992).
-- Avatar pet BP delay -> avatar MACC (30).
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

-- ----------------------------------------------------------------
-- Ability recast backup + zero timers
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ixi20_bp_ability_recast_backup` (
  `abilityId` smallint(5) unsigned NOT NULL,
  `recastId` smallint(5) unsigned NOT NULL,
  `recastTime` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`abilityId`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_bp_ability_recast_backup` (`abilityId`, `recastId`, `recastTime`)
SELECT `abilityId`, `recastId`, `recastTime`
FROM `abilities`
WHERE `job` = 15
  AND (`abilityId` IN (91, 172) OR `recastId` IN (173, 174));

UPDATE `abilities`
SET `recastTime` = 0
WHERE `job` = 15
  AND (`abilityId` IN (91, 172) OR `recastId` IN (173, 174));

-- ----------------------------------------------------------------
-- Gear backups
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ixi20_bp_item_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_bp_item_mods_backup` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value`
FROM `item_mods`
WHERE `modId` IN (357, 541);

CREATE TABLE IF NOT EXISTS `ixi20_bp_item_mods_pet_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_bp_item_mods_pet_backup` (`itemId`, `modId`, `value`, `petType`)
SELECT `itemId`, `modId`, `value`, `petType`
FROM `item_mods_pet`
WHERE `modId` IN (357, 541);

CREATE TABLE IF NOT EXISTS `ixi20_bp_augments_backup` (
  `augmentId` smallint(5) unsigned NOT NULL,
  `multiplier` smallint(2) NOT NULL DEFAULT 0,
  `modId` smallint(5) unsigned NOT NULL DEFAULT 0,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `isPet` tinyint(1) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`augmentId`, `multiplier`, `modId`, `isPet`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_bp_augments_backup`
SELECT `augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType`
FROM `augments`
WHERE `augmentId` = 320 AND `modId` = 357;

DELETE FROM `item_mods` WHERE `modId` IN (357, 541);
DELETE FROM `item_mods_pet` WHERE `modId` IN (357, 541);
DELETE FROM `augments` WHERE `augmentId` = 320 AND `modId` = 357;

-- ----------------------------------------------------------------
-- item_mods: BP_DELAY (357) -> PET_MACC_MEVA (993)
-- ----------------------------------------------------------------
INSERT INTO `item_mods` VALUES (10664, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._horn_+2; was BP_DELAY 5
INSERT INTO `item_mods` VALUES (10684, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._doublet_+2; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (10704, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._bracers_+2; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (10724, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._spats_+2; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (10744, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._pigaches_+2; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (11052, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- esper_earring; was BP_DELAY -5
INSERT INTO `item_mods` VALUES (11564, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- tiresias_cape; was BP_DELAY 3
INSERT INTO `item_mods` VALUES (11717, 993, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- callers_earring; was BP_DELAY 1
INSERT INTO `item_mods` VALUES (11982, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- magavan_slops; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (12210, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- ebon_gages; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (12211, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- furia_gages; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (12212, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- ebur_gages; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (12493, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- accord_hat; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (13814, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- austere_robe; was BP_DELAY 3
INSERT INTO `item_mods` VALUES (13815, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- penance_robe; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (13939, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- austere_hat; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (13940, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- penance_hat; was BP_DELAY 3
INSERT INTO `item_mods` VALUES (14468, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- yinyang_robe; was BP_DELAY 5
INSERT INTO `item_mods` VALUES (14487, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- evk._doublet_+1; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (14514, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._doublet_+1; was BP_DELAY 4
INSERT INTO `item_mods` VALUES (14826, 993, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- austere_cuffs; was BP_DELAY 1
INSERT INTO `item_mods` VALUES (14827, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- penance_cuffs; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (14904, 993, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- evk._bracers_+1; was BP_DELAY 1
INSERT INTO `item_mods` VALUES (14923, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._bracers_+1; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (15086, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- summoners_horn; was BP_DELAY 3
INSERT INTO `item_mods` VALUES (15101, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- summoners_dblt.; was BP_DELAY 3
INSERT INTO `item_mods` VALUES (15116, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- summoners_brcr.; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (15131, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- summoners_spats; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (15146, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- summoners_pgch.; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (15259, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._horn_+1; was BP_DELAY 3
INSERT INTO `item_mods` VALUES (15594, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._spats_+1; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (15679, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._pigaches_+1; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (17573, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- himmel_stock; was BP_DELAY -3
INSERT INTO `item_mods` VALUES (21394, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- sancus_sachet; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (21395, 993, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- sancus_sachet_+1; was BP_DELAY 7
INSERT INTO `item_mods` VALUES (23077, 993, 13) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_horn_+2; was BP_DELAY -9
INSERT INTO `item_mods` VALUES (23121, 993, 14) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._doublet_+2; was BP_DELAY 10
INSERT INTO `item_mods` VALUES (23211, 993, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_bracers_+2; was BP_DELAY 7
INSERT INTO `item_mods` VALUES (23278, 993, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_spats_+2; was BP_DELAY 7
INSERT INTO `item_mods` VALUES (23456, 993, 15) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._doublet_+3; was BP_DELAY 15
INSERT INTO `item_mods` VALUES (26652, 993, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_horn; was BP_DELAY 7
INSERT INTO `item_mods` VALUES (26653, 993, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_horn_+1; was BP_DELAY 8
INSERT INTO `item_mods` VALUES (26888, 993, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- shomonjijoe_+1; was BP_DELAY 8
INSERT INTO `item_mods` VALUES (27004, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_bracers; was BP_DELAY 5
INSERT INTO `item_mods` VALUES (27005, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_bracers_+1; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (27180, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_spats; was BP_DELAY 5
INSERT INTO `item_mods` VALUES (27181, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_spats_+1; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (27356, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_pigaches; was BP_DELAY 5
INSERT INTO `item_mods` VALUES (27534, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- evans_earring; was BP_DELAY 2
INSERT INTO `item_mods` VALUES (27677, 993, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- convokers_horn; was BP_DELAY 7
INSERT INTO `item_mods` VALUES (27698, 993, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._horn_+1; was BP_DELAY 8
INSERT INTO `item_mods` VALUES (27821, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- convo._doublet; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (27842, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._doublet_+1; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (27957, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._bracers; was BP_DELAY 5
INSERT INTO `item_mods` VALUES (27978, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._bracers_+1; was BP_DELAY 6
INSERT INTO `item_mods` VALUES (28605, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- samanisi_cape; was BP_DELAY 3

-- ----------------------------------------------------------------
-- item_mods: BP_DELAY_II (541) -> PET_MAB_MDB (992)
-- ----------------------------------------------------------------
INSERT INTO `item_mods` VALUES (21377, 992, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- idaraaja; was BP_DELAY_II 4
INSERT INTO `item_mods` VALUES (21381, 992, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- seraphicaller; was BP_DELAY_II 5
INSERT INTO `item_mods` VALUES (21383, 992, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- eminent_sachet; was BP_DELAY_II 3
INSERT INTO `item_mods` VALUES (21432, 992, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- epitaph; was BP_DELAY_II 5
INSERT INTO `item_mods` VALUES (23144, 992, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_doublet_+2; was BP_DELAY_II 3
INSERT INTO `item_mods` VALUES (23345, 992, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyph._pigaches_+2; was BP_DELAY_II 2
INSERT INTO `item_mods` VALUES (23680, 992, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyph._pigaches_+3; was BP_DELAY_II -3
INSERT INTO `item_mods` VALUES (26828, 992, 4) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_doublet; was BP_DELAY_II 1
INSERT INTO `item_mods` VALUES (26829, 992, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_doublet_+1; was BP_DELAY_II 2
INSERT INTO `item_mods` VALUES (26852, 992, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- apogee_dalmatica; was BP_DELAY_II 2
INSERT INTO `item_mods` VALUES (26853, 992, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- apo._dalmatica_+1; was BP_DELAY_II 3
INSERT INTO `item_mods` VALUES (27357, 992, 4) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyph._pigaches_+1; was BP_DELAY_II 1

-- ----------------------------------------------------------------
-- item_mods_pet
-- ----------------------------------------------------------------
INSERT INTO `item_mods_pet` VALUES (15146, 30, 6, 1) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- summoners_pgch. avatar MACC; was BP_DELAY -2
INSERT INTO `item_mods_pet` VALUES (15679, 30, 6, 1) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._pigaches_+1 avatar MACC; was BP_DELAY -2

-- ----------------------------------------------------------------
-- Augment 320: Blood Pact ability delay -1 -> pet MACC +1
-- ----------------------------------------------------------------
INSERT INTO `augments` VALUES (320, 0, 993, 1, 0, 0)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
