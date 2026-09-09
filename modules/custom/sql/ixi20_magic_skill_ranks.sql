-- Imagine XI 2.0 magic skill ranks (verified live 1.0 xidb / z_imagine_xi_10).
-- Magic schools, ninjutsu, songs. WAR-RUN only. Blue / geomancy / handbell stay retail.
-- Rank: 1=A+ 2=A 3=B+ 4=B 5=B- 6=C+ 7=C 8=C- 9=D 10=E 11=F 0=none
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_skill_ranks_backup` (
    `skillid` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `name` CHAR(12) DEFAULT NULL,
    `war` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `mnk` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `whm` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `blm` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `rdm` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `thf` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `pld` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `drk` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `bst` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `brd` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `rng` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `sam` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `nin` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `drg` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `smn` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `blu` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `cor` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `pup` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `dnc` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `sch` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `geo` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    `run` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`skillid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `ixi20_skill_ranks_backup`
SELECT `skillid`, `name`, `war`, `mnk`, `whm`, `blm`, `rdm`, `thf`, `pld`, `drk`,
       `bst`, `brd`, `rng`, `sam`, `nin`, `drg`, `smn`, `blu`, `cor`, `pup`,
       `dnc`, `sch`, `geo`, `run`
FROM `skill_ranks`;

UPDATE `skill_ranks`
SET `name` = 'divine',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 1
WHERE `skillid` = 32;

UPDATE `skill_ranks`
SET `name` = 'healing',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 1, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 1, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 1
WHERE `skillid` = 33;

UPDATE `skill_ranks`
SET `name` = 'enhancing',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 1, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 1
WHERE `skillid` = 34;

UPDATE `skill_ranks`
SET `name` = 'enfeebling',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 1, `rng` = 0, `sam` = 0,
    `nin` = 1, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 1, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 0
WHERE `skillid` = 35;

UPDATE `skill_ranks`
SET `name` = 'elemental',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 1, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 0
WHERE `skillid` = 36;

UPDATE `skill_ranks`
SET `name` = 'dark',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 1, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 0
WHERE `skillid` = 37;

UPDATE `skill_ranks`
SET `name` = 'summoning',
    `war` = 0, `mnk` = 0, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 1, `blu` = 1, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 0
WHERE `skillid` = 38;

UPDATE `skill_ranks`
SET `name` = 'ninjutsu',
    `war` = 1, `mnk` = 1, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 1,
    `pld` = 1, `drk` = 1, `bst` = 1, `brd` = 1, `rng` = 1, `sam` = 1,
    `nin` = 1, `drg` = 1, `smn` = 1, `blu` = 1, `cor` = 1, `pup` = 1,
    `dnc` = 1, `sch` = 1, `geo` = 1, `run` = 1
WHERE `skillid` = 39;

UPDATE `skill_ranks`
SET `name` = 'singing',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 1, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 40;

UPDATE `skill_ranks`
SET `name` = 'string',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 1, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 41;

UPDATE `skill_ranks`
SET `name` = 'wind',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 1, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 42;

-- Blue / geomancy / handbell: retail
UPDATE `skill_ranks`
SET `name` = 'blue',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 1, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 43;

UPDATE `skill_ranks`
SET `name` = 'geomancy',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 7, `run` = 0
WHERE `skillid` = 44;

UPDATE `skill_ranks`
SET `name` = 'handbell',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 7, `run` = 0
WHERE `skillid` = 45;
