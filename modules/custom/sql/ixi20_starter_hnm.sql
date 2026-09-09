-- Dynamic spawn rows for Imagine XI 2.0 starter-zone HNMs.
-- LSB 2.0 keeps zone trash in YAML, so mob_groups is empty for fields 100/101/106/107/115/116
-- except Pixie Rescue (group 35 / zone 100).
--
-- Group 36 = HNM (existing NM pools; look is overridden in Lua)
-- Group 37 = phase adds
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

INSERT INTO `mob_pools` (
    `poolid`, `name`, `packet_name`, `speciesid`, `modelid`,
    `mJob`, `sJob`, `cmbSkill`, `cmbDelay`, `cmbDmgMult`,
    `behavior`, `aggro`, `true_detection`, `links`, `mobType`,
    `immunity`, `name_prefix`, `flag`, `entityFlags`, `animationsub`,
    `hasSpellScript`, `spellList`, `namevis`, `roamflag`,
    `skill_list_id`, `resist_id`, `modelSize`, `modelHitboxSize`
) VALUES
    (4344, 'Wild_Sheep', 'Wild_Sheep', 111, UNHEX('0000540100000000000000000000000000000000'),
     1, 1, 7, 240, 100,
     0, 0, 0, 1, 0,
     0, 0, 0, 129, 16,
     0, 0, 0, 0,
     226, 226, 0, 20),
    (3381, 'Rock_Lizard', 'Rock_Lizard', 307, UNHEX('0000480100000000000000000000000000000000'),
     1, 1, 7, 240, 100,
     0, 0, 0, 1, 0,
     0, 0, 0, 129, 0,
     0, 0, 0, 0,
     174, 174, 0, 13),
    (3924, 'Tiny_Mandragora', 'Tiny_Mandragora', 350, UNHEX('00002C0100000000000000000000000000000000'),
     2, 2, 1, 360, 100,
     0, 0, 0, 1, 0,
     0, 0, 0, 641, 8,
     0, 0, 0, 0,
     178, 178, 0, 9)
ON DUPLICATE KEY UPDATE
    `name`            = VALUES(`name`),
    `packet_name`     = VALUES(`packet_name`),
    `speciesid`       = VALUES(`speciesid`),
    `modelid`         = VALUES(`modelid`),
    `mJob`            = VALUES(`mJob`),
    `sJob`            = VALUES(`sJob`),
    `cmbSkill`        = VALUES(`cmbSkill`),
    `cmbDelay`        = VALUES(`cmbDelay`),
    `skill_list_id`   = VALUES(`skill_list_id`),
    `resist_id`       = VALUES(`resist_id`),
    `entityFlags`     = VALUES(`entityFlags`),
    `animationsub`    = VALUES(`animationsub`),
    `links`           = VALUES(`links`),
    `modelHitboxSize` = VALUES(`modelHitboxSize`);

INSERT INTO `mob_groups`
    (`groupid`, `poolid`, `zoneid`, `name`, `respawntime`, `spawntype`, `dropid`, `HP`, `MP`, `allegiance`)
VALUES
    (36, 2125, 100, 'StarterHNM', 0, 128, 0, 0, 0, 0),
    (37, 4344, 100, 'StarterHNM_Add', 0, 128, 0, 0, 0, 0),
    (36, 3818, 101, 'StarterHNM', 0, 128, 0, 0, 0, 0),
    (37, 4344, 101, 'StarterHNM_Add', 0, 128, 0, 0, 0, 0),
    (36, 2490, 106, 'StarterHNM', 0, 128, 0, 0, 0, 0),
    (37, 3381, 106, 'StarterHNM_Add', 0, 128, 0, 0, 0, 0),
    (36, 2384, 107, 'StarterHNM', 0, 128, 0, 0, 0, 0),
    (37, 3381, 107, 'StarterHNM_Add', 0, 128, 0, 0, 0, 0),
    (36, 3947, 115, 'StarterHNM', 0, 128, 0, 0, 0, 0),
    (37, 3924, 115, 'StarterHNM_Add', 0, 128, 0, 0, 0, 0),
    (36, 4529, 116, 'StarterHNM', 0, 128, 0, 0, 0, 0),
    (37, 3924, 116, 'StarterHNM_Add', 0, 128, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
    `poolid`      = VALUES(`poolid`),
    `name`        = VALUES(`name`),
    `respawntime` = 0,
    `spawntype`   = 128,
    `dropid`      = 0,
    `HP`          = 0,
    `MP`          = 0,
    `allegiance`  = 0;
