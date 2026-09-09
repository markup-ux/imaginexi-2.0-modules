-- Imagine XI 2.0: all equipment / all jobs + unrestricted WS job blobs.
-- Revert with ixi20_REVERT.sql (restores from backup tables created here).
-- Does not touch Soldier.

CREATE TABLE IF NOT EXISTS `ixi20_item_equipment_jobs_backup` (
    `itemId` SMALLINT(5) UNSIGNED NOT NULL,
    `jobs`   INT(10) UNSIGNED NOT NULL,
    PRIMARY KEY (`itemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ixi20_weapon_skills_jobs_backup` (
    `weaponskillid` TINYINT(3) UNSIGNED NOT NULL,
    `jobs`          BINARY(22) NOT NULL,
    `main_only`     TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`weaponskillid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_item_equipment_jobs_backup` (`itemId`, `jobs`)
SELECT `itemId`, `jobs` FROM `item_equipment`;

INSERT IGNORE INTO `ixi20_weapon_skills_jobs_backup` (`weaponskillid`, `jobs`, `main_only`)
SELECT `weaponskillid`, `jobs`, `main_only` FROM `weapon_skills`;

UPDATE `item_equipment`
SET `jobs` = 4194303
WHERE `jobs` <> 4194303;

-- Relic / mythic / empyrean / campaign / event WS use skilllevel 0 and are
-- granted by the weapon (ADDS_WEAPONSKILL) or a trial unlock. Opening their
-- job blobs makes Knights of Round, Uriel Blade, etc. appear on a level 2
-- with any sword. Keep those rows at stock jobs; only open skill-based WS.
UPDATE `weapon_skills` w
INNER JOIN `ixi20_weapon_skills_jobs_backup` b ON b.`weaponskillid` = w.`weaponskillid`
SET w.`jobs` = b.`jobs`,
    w.`main_only` = b.`main_only`
WHERE w.`skilllevel` = 0;

UPDATE `weapon_skills`
SET `jobs` = UNHEX(REPEAT('01', 22)),
    `main_only` = 0
WHERE `skilllevel` > 0;
