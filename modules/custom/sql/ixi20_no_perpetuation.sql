-- Imagine XI 2.0: remove Avatar perpetuation cost from gear and give
-- those lines a SMN-useful replacement (1.0 z_imagine_xi_80_item_rebalance).
-- Runtime drain is disabled by ixi20_no_perpetuation.lua / .cpp.
--
-- PERPETUATION_REDUCTION (346) and half-perp (356 / 1170 / 1171) become:
--   SUMMONING (117) at |old| + 4, or PET_MACC_MEVA (993) if the piece
--   already has summoning skill.
-- Half-perp day/weather pairs become summoning + pet MACC.
-- Latents and the "Avatar perpetuation cost -1" augment follow the same rule.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

-- ----------------------------------------------------------------
-- Backups (first apply only)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ixi20_perp_item_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_perp_item_mods_backup` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value`
FROM `item_mods`
WHERE `modId` IN (346, 356, 1170, 1171);

CREATE TABLE IF NOT EXISTS `ixi20_perp_item_mods_pet_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_perp_item_mods_pet_backup` (`itemId`, `modId`, `value`, `petType`)
SELECT `itemId`, `modId`, `value`, `petType`
FROM `item_mods_pet`
WHERE `modId` = 346;

CREATE TABLE IF NOT EXISTS `ixi20_perp_item_latents_backup` (
  `itemId` smallint(5) UNSIGNED NOT NULL,
  `modId` smallint(5) UNSIGNED NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `latentId` smallint(5) NOT NULL,
  `latentParam` smallint(5) NOT NULL,
  PRIMARY KEY (`itemId`, `modId`, `value`, `latentId`, `latentParam`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_perp_item_latents_backup`
SELECT `itemId`, `modId`, `value`, `latentId`, `latentParam`
FROM `item_latents`
WHERE `modId` = 346;

CREATE TABLE IF NOT EXISTS `ixi20_perp_augments_backup` (
  `augmentId` smallint(5) unsigned NOT NULL,
  `multiplier` smallint(2) NOT NULL DEFAULT 0,
  `modId` smallint(5) unsigned NOT NULL DEFAULT 0,
  `value` smallint(5) NOT NULL DEFAULT 0,
  `isPet` tinyint(1) NOT NULL DEFAULT 0,
  `petType` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`augmentId`, `multiplier`, `modId`, `isPet`, `petType`)
) ENGINE=Aria TRANSACTIONAL=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_perp_augments_backup`
SELECT `augmentId`, `multiplier`, `modId`, `value`, `isPet`, `petType`
FROM `augments`
WHERE `augmentId` = 321 AND `modId` = 346;

-- ----------------------------------------------------------------
-- Strip dead perp mods
-- ----------------------------------------------------------------
DELETE FROM `item_mods` WHERE `modId` IN (346, 356, 1170, 1171);
DELETE FROM `item_mods_pet` WHERE `modId` = 346;
DELETE FROM `item_latents` WHERE `modId` = 346;
DELETE FROM `augments` WHERE `augmentId` = 321 AND `modId` = 346;

-- ----------------------------------------------------------------
-- item_mods replacements (1.0 mapping: 346 -> 117 or 993)
-- ----------------------------------------------------------------
INSERT INTO `item_mods` VALUES (10321, 117, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- adhara_gages; was PERPETUATION_REDUCTION 2
INSERT INTO `item_mods` VALUES (10664, 117, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._horn_+2; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods` VALUES (10684, 117, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._doublet_+2; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods` VALUES (11098, 993, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- call._doublet_+2; already has SUMMONING; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (11158, 117, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- callers_pgch._+2; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods` VALUES (11198, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- callers_doublet_+1; already has SUMMONING; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods` VALUES (11258, 117, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- callers_pgch._+1; was PERPETUATION_REDUCTION 2
INSERT INTO `item_mods` VALUES (13814, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- austere_robe; was PERPETUATION_REDUCTION 1
INSERT INTO `item_mods` VALUES (13815, 117, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- penance_robe; was PERPETUATION_REDUCTION 2
INSERT INTO `item_mods` VALUES (14625, 993, 3) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- evokers_ring; already has SUMMONING; was PERPETUATION_REDUCTION 1
INSERT INTO `item_mods` VALUES (14906, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nashira_gages; was PERPETUATION_REDUCTION 1
INSERT INTO `item_mods` VALUES (15366, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- evk._pigaches_+1; was PERPETUATION_REDUCTION 1
INSERT INTO `item_mods` VALUES (15430, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- augurs_brais; was PERPETUATION_REDUCTION 1
INSERT INTO `item_mods` VALUES (17528, 117, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- astral_signa; was PERPETUATION_REDUCTION 2
INSERT INTO `item_mods` VALUES (17597, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- dragon_staff; was PERPETUATION_REDUCTION 1
INSERT INTO `item_mods` VALUES (17598, 993, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- bahamuts_staff; already has SUMMONING; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods` VALUES (19005, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 75; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (19074, 117, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 80; was PERPETUATION_REDUCTION 5
INSERT INTO `item_mods` VALUES (19094, 117, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 85; was PERPETUATION_REDUCTION 6
INSERT INTO `item_mods` VALUES (19626, 117, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 90; was PERPETUATION_REDUCTION 7
INSERT INTO `item_mods` VALUES (19724, 117, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 95; was PERPETUATION_REDUCTION 7
INSERT INTO `item_mods` VALUES (19833, 117, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 99; was PERPETUATION_REDUCTION 8
INSERT INTO `item_mods` VALUES (19962, 117, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 99 after; was PERPETUATION_REDUCTION 8
INSERT INTO `item_mods` VALUES (21141, 117, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 119; was PERPETUATION_REDUCTION 8
INSERT INTO `item_mods` VALUES (21142, 117, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nirvana 119 after; was PERPETUATION_REDUCTION 8
INSERT INTO `item_mods` VALUES (22076, 117, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- was; was PERPETUATION_REDUCTION 5
INSERT INTO `item_mods` VALUES (22077, 117, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- was_+1; was PERPETUATION_REDUCTION 7
INSERT INTO `item_mods` VALUES (23077, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_horn_+2; was PERPETUATION_REDUCTION -4
INSERT INTO `item_mods` VALUES (23144, 117, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_doublet_+2; was PERPETUATION_REDUCTION 5
INSERT INTO `item_mods` VALUES (23166, 993, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_doublet_+2; already has SUMMONING; was PERPETUATION_REDUCTION -7
INSERT INTO `item_mods` VALUES (23322, 117, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- convo._pigaches_+2; was PERPETUATION_REDUCTION 5
INSERT INTO `item_mods` VALUES (23367, 117, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_pigaches_+2; was PERPETUATION_REDUCTION -8
INSERT INTO `item_mods` VALUES (23657, 117, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- convo._pigaches_+3; was PERPETUATION_REDUCTION 6
INSERT INTO `item_mods` VALUES (26652, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_horn; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (26653, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_horn_+1; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (26828, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_doublet; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (26829, 117, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- glyphic_doublet_+1; was PERPETUATION_REDUCTION 5
INSERT INTO `item_mods` VALUES (26926, 993, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_doublet; already has SUMMONING; was PERPETUATION_REDUCTION 5
INSERT INTO `item_mods` VALUES (26927, 993, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beck._doublet_+1; already has SUMMONING; was PERPETUATION_REDUCTION 6
INSERT INTO `item_mods` VALUES (27380, 117, 12) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- apogee_pumps; was PERPETUATION_REDUCTION 8
INSERT INTO `item_mods` VALUES (27381, 117, 13) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- apogee_pumps_+1; was PERPETUATION_REDUCTION 9
INSERT INTO `item_mods` VALUES (27439, 117, 10) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beck._pigaches; was PERPETUATION_REDUCTION 6
INSERT INTO `item_mods` VALUES (27440, 117, 11) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beck._pigaches_+1; was PERPETUATION_REDUCTION 7
INSERT INTO `item_mods` VALUES (27534, 117, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- evans_earring; was PERPETUATION_REDUCTION 2
INSERT INTO `item_mods` VALUES (28237, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._pigaches; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (28258, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- con._pigaches_+1; was PERPETUATION_REDUCTION 4
INSERT INTO `item_mods` VALUES (28296, 117, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- artsieq_boots; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods` VALUES (28416, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- lucidity_sash; already has SUMMONING; was PERPETUATION_REDUCTION 2

-- Half-perpetuation (Carby / day / weather) — 1.0 preview, not in z_80
INSERT INTO `item_mods` VALUES (11118, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- call._bracers_+2; was HALF_PERPETUATION_DAY/WEATHER
INSERT INTO `item_mods` VALUES (11118, 993, 4) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- call._bracers_+2
INSERT INTO `item_mods` VALUES (11218, 117, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- callers_bracers_+1; was HALF_PERPETUATION_DAY
INSERT INTO `item_mods` VALUES (14062, 117, 4) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- carbuncle_mitts; was HALF_PERPETUATION_CARBUNCLE
INSERT INTO `item_mods` VALUES (23233, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_bracers_+2; was HALF_PERPETUATION_DAY/WEATHER
INSERT INTO `item_mods` VALUES (23233, 993, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_bracers_+2
INSERT INTO `item_mods` VALUES (27080, 117, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_bracers; was HALF_PERPETUATION_DAY/WEATHER
INSERT INTO `item_mods` VALUES (27080, 993, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beckoners_bracers
INSERT INTO `item_mods` VALUES (27081, 117, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beck._bracers_+1; was HALF_PERPETUATION_DAY/WEATHER
INSERT INTO `item_mods` VALUES (27081, 993, 5) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- beck._bracers_+1
INSERT INTO `item_mods` VALUES (27106, 117, 3) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- asteria_mitts; was HALF_PERPETUATION_CARBUNCLE
INSERT INTO `item_mods` VALUES (27107, 117, 4) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- asteria_mitts_+1; was HALF_PERPETUATION_CARBUNCLE

-- ----------------------------------------------------------------
-- item_mods_pet: avatar perp -> avatar MACC
-- ----------------------------------------------------------------
INSERT INTO `item_mods_pet` VALUES (10664, 30, 7, 1) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._horn_+2 avatar MACC; was PERPETUATION_REDUCTION 3
INSERT INTO `item_mods_pet` VALUES (10684, 30, 7, 1) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- smn._doublet_+2 avatar MACC; was PERPETUATION_REDUCTION 3

-- ----------------------------------------------------------------
-- item_latents: perp -N while X is out / HP check -> summoning skill
-- ----------------------------------------------------------------
INSERT INTO `item_latents` VALUES (11752, 117, 5, 9, 16) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- diaboloss_rope; Diabolos
INSERT INTO `item_latents` VALUES (12493, 117, 5, 9, 9) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- accord_hat; Fenrir
INSERT INTO `item_latents` VALUES (13300, 117, 5, 2, 75) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- conjurers_ring; HP <= 75%
INSERT INTO `item_latents` VALUES (14401, 117, 5, 9, 7) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- duende_cotehardie; Dark Spirit
INSERT INTO `item_latents` VALUES (14410, 117, 5, 9, 6) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nimbus_doublet; Light Spirit
INSERT INTO `item_latents` VALUES (14946, 117, 5, 13, 2) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nightmare_gloves
INSERT INTO `item_latents` VALUES (14946, 117, 5, 13, 19) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- nightmare_gloves
INSERT INTO `item_latents` VALUES (15285, 117, 6, 8, 15) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- avatar_belt
INSERT INTO `item_latents` VALUES (16154, 117, 6, 9, 13) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- karura_hachigane
INSERT INTO `item_latents` VALUES (25633, 117, 5, 9, 8) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`); -- carbie_cap_+1; Carbuncle
-- 14062 carbuncle_mitts latent was a 0-value placeholder; half-cost is now summoning on item_mods

-- ----------------------------------------------------------------
-- Augment 321: Avatar perpetuation cost -1 -> Summoning magic skill +1
-- ----------------------------------------------------------------
INSERT INTO `augments` VALUES (321, 0, 117, 1, 0, 0)
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
