-- Imagine XI 2.0: Swift Belt (Sacrarium) and Velocious Belt (King Arthro)
-- share the same stats. Haste +8%, Accuracy +8, Store TP +4. No Attack penalty.
-- Velocious wear level 55 -> 50 (Swift is already 50). Jobs stay All via
-- ixi20_all_equipment_all_jobs.sql.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

-- ----------------------------------------------------------------
-- Backups (first apply only)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ixi20_haste_belts_mods_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `modId` smallint(5) unsigned NOT NULL,
  `value` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`, `modId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_haste_belts_mods_backup` (`itemId`, `modId`, `value`)
SELECT `itemId`, `modId`, `value`
FROM `item_mods`
WHERE `itemId` IN (15457, 15899);

CREATE TABLE IF NOT EXISTS `ixi20_haste_belts_level_backup` (
  `itemId` smallint(5) unsigned NOT NULL,
  `level`  tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_haste_belts_level_backup` (`itemId`, `level`)
SELECT `itemId`, `level`
FROM `item_equipment`
WHERE `itemId` IN (15457, 15899);

-- ----------------------------------------------------------------
-- Shared package
-- mod 23 ATT, 25 ACC, 73 STORE_TP, 384 HASTE_GEAR (100 = 1%)
-- ----------------------------------------------------------------
DELETE FROM `item_mods` WHERE `itemId` IN (15457, 15899);

INSERT INTO `item_mods` VALUES (15457, 25, 8);   -- swift_belt ACC+8
INSERT INTO `item_mods` VALUES (15457, 73, 4);   -- swift_belt STORE_TP+4
INSERT INTO `item_mods` VALUES (15457, 384, 800); -- swift_belt Haste+8%

INSERT INTO `item_mods` VALUES (15899, 25, 8);   -- velocious_belt ACC+8
INSERT INTO `item_mods` VALUES (15899, 73, 4);   -- velocious_belt STORE_TP+4
INSERT INTO `item_mods` VALUES (15899, 384, 800); -- velocious_belt Haste+8%

UPDATE `item_equipment` SET `level` = 50 WHERE `itemId` IN (15457, 15899);
