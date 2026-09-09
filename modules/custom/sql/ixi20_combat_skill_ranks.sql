-- Imagine XI 2.0 combat skill ranks (verified live 1.0 xidb / z_imagine_xi_10).
-- Weapons, H2H, ranged, guarding, evasion, shield, parrying. WAR-RUN only.
-- Rank: 1=A+ 2=A 3=B+ 4=B 5=B- 6=C+ 7=C 8=C- 9=D 10=E 11=F 0=none
-- Hand-to-hand, evasion, and parrying stay retail. Revert with ixi20_REVERT.sql on xidb_ixi20 only.

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

-- H2H: retail (WAR D, MNK A+, THF E, NIN E, PUP A+, DNC D)
UPDATE `skill_ranks`
SET `name` = 'hand2hand',
    `war` = 9, `mnk` = 1, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 10,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 10, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 1,
    `dnc` = 9, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 1;

UPDATE `skill_ranks`
SET `name` = 'dagger',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 9, `rdm` = 1, `thf` = 1,
    `pld` = 8, `drk` = 7, `bst` = 6, `brd` = 1, `rng` = 1, `sam` = 10,
    `nin` = 1, `drg` = 10, `smn` = 10, `blu` = 0, `cor` = 1, `pup` = 8,
    `dnc` = 1, `sch` = 9, `geo` = 8, `run` = 0
WHERE `skillid` = 2;

UPDATE `skill_ranks`
SET `name` = 'sword',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 1, `thf` = 9,
    `pld` = 1, `drk` = 1, `bst` = 10, `brd` = 1, `rng` = 9, `sam` = 6,
    `nin` = 7, `drg` = 8, `smn` = 0, `blu` = 1, `cor` = 1, `pup` = 0,
    `dnc` = 9, `sch` = 0, `geo` = 0, `run` = 1
WHERE `skillid` = 3;

UPDATE `skill_ranks`
SET `name` = 'great sword',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 1, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 1
WHERE `skillid` = 4;

UPDATE `skill_ranks`
SET `name` = 'axe',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 1, `bst` = 1, `brd` = 0, `rng` = 1, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 5
WHERE `skillid` = 5;

UPDATE `skill_ranks`
SET `name` = 'great axe',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 4
WHERE `skillid` = 6;

UPDATE `skill_ranks`
SET `name` = 'scythe',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 1, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 1, `bst` = 1, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 7;

UPDATE `skill_ranks`
SET `name` = 'polearm',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 1, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 1,
    `nin` = 0, `drg` = 1, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 8;

UPDATE `skill_ranks`
SET `name` = 'katana',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 1, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 9;

UPDATE `skill_ranks`
SET `name` = 'great katana',
    `war` = 0, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 1,
    `nin` = 1, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 10;

UPDATE `skill_ranks`
SET `name` = 'club',
    `war` = 1, `mnk` = 6, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 10,
    `pld` = 1, `drk` = 8, `bst` = 9, `brd` = 9, `rng` = 10, `sam` = 10,
    `nin` = 10, `drg` = 10, `smn` = 6, `blu` = 5, `cor` = 0, `pup` = 9,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 8
WHERE `skillid` = 11;

UPDATE `skill_ranks`
SET `name` = 'staff',
    `war` = 1, `mnk` = 1, `whm` = 1, `blm` = 1, `rdm` = 1, `thf` = 0,
    `pld` = 2, `drk` = 0, `bst` = 0, `brd` = 6, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 5, `smn` = 1, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 1, `geo` = 1, `run` = 0
WHERE `skillid` = 12;

UPDATE `skill_ranks`
SET `name` = 'archery',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 9, `thf` = 1,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 1, `sam` = 1,
    `nin` = 10, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 25;

UPDATE `skill_ranks`
SET `name` = 'marksmanship',
    `war` = 1, `mnk` = 0, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 1,
    `pld` = 0, `drk` = 1, `bst` = 0, `brd` = 0, `rng` = 1, `sam` = 0,
    `nin` = 7, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 1, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 26;

UPDATE `skill_ranks`
SET `name` = 'throwing',
    `war` = 9, `mnk` = 10, `whm` = 10, `blm` = 9, `rdm` = 11, `thf` = 1,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 10, `rng` = 1, `sam` = 6,
    `nin` = 1, `drg` = 0, `smn` = 0, `blu` = 1, `cor` = 6, `pup` = 6,
    `dnc` = 1, `sch` = 9, `geo` = 0, `run` = 0
WHERE `skillid` = 27;

UPDATE `skill_ranks`
SET `name` = 'guarding',
    `war` = 0, `mnk` = 1, `whm` = 0, `blm` = 0, `rdm` = 0, `thf` = 0,
    `pld` = 0, `drk` = 0, `bst` = 0, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 5, `pup` = 1,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 28;

-- Evasion: retail
UPDATE `skill_ranks`
SET `name` = 'evasion',
    `war` = 7, `mnk` = 3, `whm` = 10, `blm` = 10, `rdm` = 9, `thf` = 1,
    `pld` = 7, `drk` = 7, `bst` = 7, `brd` = 9, `rng` = 10, `sam` = 3,
    `nin` = 2, `drg` = 4, `smn` = 10, `blu` = 8, `cor` = 9, `pup` = 4,
    `dnc` = 3, `sch` = 10, `geo` = 9, `run` = 3
WHERE `skillid` = 29;

UPDATE `skill_ranks`
SET `name` = 'shield',
    `war` = 1, `mnk` = 0, `whm` = 1, `blm` = 0, `rdm` = 1, `thf` = 1,
    `pld` = 1, `drk` = 1, `bst` = 10, `brd` = 0, `rng` = 0, `sam` = 0,
    `nin` = 0, `drg` = 0, `smn` = 0, `blu` = 0, `cor` = 0, `pup` = 0,
    `dnc` = 0, `sch` = 0, `geo` = 0, `run` = 0
WHERE `skillid` = 30;

-- Parrying: retail
UPDATE `skill_ranks`
SET `name` = 'parrying',
    `war` = 8, `mnk` = 10, `whm` = 0, `blm` = 0, `rdm` = 10, `thf` = 2,
    `pld` = 7, `drk` = 10, `bst` = 7, `brd` = 10, `rng` = 0, `sam` = 2,
    `nin` = 2, `drg` = 5, `smn` = 0, `blu` = 9, `cor` = 2, `pup` = 9,
    `dnc` = 4, `sch` = 10, `geo` = 10, `run` = 1
WHERE `skillid` = 31;
