-- Imagine XI 2.0: all Corsair Phantom Rolls unlock at level 1.
-- Apply after ixi20_job_progression_37cap.sql. Pair with ixi20_corsair.lua
-- so dice-taught rolls are already learned. Revert with ixi20_REVERT.sql
-- on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_corsair_roll_level_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_corsair_roll_level_backup` (`abilityId`, `level`)
SELECT `abilityId`, `level` FROM `abilities`
WHERE `abilityId` IN (
    97,  -- phantom_roll
    98,  -- fighters_roll
    99,  -- monks_roll
    100, -- healers_roll
    101, -- wizards_roll
    102, -- warlocks_roll
    103, -- rogues_roll
    104, -- gallants_roll
    105, -- chaos_roll
    106, -- beast_roll
    107, -- choral_roll
    108, -- hunters_roll
    109, -- samurai_roll
    110, -- ninja_roll
    111, -- drachen_roll
    112, -- evokers_roll
    113, -- maguss_roll
    114, -- corsairs_roll
    115, -- puppet_roll
    116, -- dancers_roll
    117, -- scholars_roll
    118, -- bolters_roll
    119, -- casters_roll
    120, -- coursers_roll
    121, -- blitzers_roll
    122, -- tacticians_roll
    302, -- allies_roll
    303, -- misers_roll
    304, -- companions_roll
    305, -- avengers_roll
    390, -- naturalists_roll
    391  -- runeists_roll
);

UPDATE `abilities` SET `level` = 1 WHERE `abilityId` IN (
    97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
    111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,
    302, 303, 304, 305, 390, 391
);
