-- Imagine XI 2.0 starter-zone elementals.
-- Classic elemental pools (missing from LSB YAML-era mob_pools) plus
-- same-zone groups 38-45 in West Ronfaure / North Gustaberg / East Saruta.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

INSERT INTO `mob_pools` (
    `poolid`, `name`, `packet_name`, `speciesid`, `modelid`,
    `mJob`, `sJob`, `cmbSkill`, `cmbDelay`, `cmbDmgMult`,
    `behavior`, `aggro`, `true_detection`, `links`, `mobType`,
    `immunity`, `name_prefix`, `flag`, `entityFlags`, `animationsub`,
    `hasSpellScript`, `spellList`, `namevis`, `roamflag`,
    `skill_list_id`, `resist_id`, `modelSize`, `modelHitboxSize`
) VALUES
    (71,   'Air_Elemental',     'Air_Elemental',     99,  UNHEX('0000B60100000000000000000000000000000000'),
     4, 5, 12, 240, 100, 0, 1, 0, 0, 0, 658, 0, 112, 1155, 16, 0, 12, 0, 0, 99, 99, 1, 3),
    (913,  'Dark_Elemental',    'Dark_Elemental',    100, UNHEX('0000BB0100000000000000000000000000000000'),
     8, 8, 11, 240, 100, 0, 1, 0, 0, 0, 6208, 0, 291, 131, 16, 0, 18, 0, 0, 100, 100, 1, 3),
    (1160, 'Earth_Elemental',   'Earth_Elemental',   101, UNHEX('0000B70100000000000000000000000000000000'),
     4, 5, 12, 240, 100, 0, 1, 0, 0, 0, 648, 0, 508, 1155, 16, 0, 13, 0, 0, 101, 101, 1, 3),
    (1341, 'Fire_Elemental',    'Fire_Elemental',    102, UNHEX('0000B40100000000000000000000000000000000'),
     4, 5, 12, 240, 100, 0, 1, 0, 0, 0, 36, 0, 1934, 131, 16, 0, 17, 0, 0, 102, 102, 1, 3),
    (2043, 'Ice_Elemental',     'Ice_Elemental',     103, UNHEX('0000B50100000000000000000000000000000000'),
     4, 5, 12, 240, 100, 0, 1, 0, 0, 0, 54, 0, 764, 1155, 16, 0, 14, 0, 0, 103, 103, 1, 3),
    (2413, 'Light_Elemental',   'Light_Elemental',   104, UNHEX('0000BA01000000000000000000000000000000'),
     3, 3, 11, 240, 100, 0, 1, 0, 0, 0, 0, 0, 1710, 131, 16, 0, 19, 0, 0, 104, 104, 1, 3),
    (3912, 'Thunder_Elemental', 'Thunder_Elemental', 105, UNHEX('0000B90100000000000000000000000000000000'),
     4, 5, 12, 240, 100, 0, 1, 0, 0, 0, 264, 0, 291, 131, 16, 0, 16, 0, 0, 105, 105, 1, 3),
    (4309, 'Water_Elemental',   'Water_Elemental',   106, UNHEX('0000B80100000000000000000000000000000000'),
     4, 5, 12, 240, 100, 0, 1, 0, 0, 0, 256, 0, 343, 131, 16, 0, 15, 0, 0, 106, 106, 1, 3)
ON DUPLICATE KEY UPDATE
    `name`            = VALUES(`name`),
    `packet_name`     = VALUES(`packet_name`),
    `speciesid`       = VALUES(`speciesid`),
    `modelid`         = VALUES(`modelid`),
    `mJob`            = VALUES(`mJob`),
    `sJob`            = VALUES(`sJob`),
    `cmbSkill`        = VALUES(`cmbSkill`),
    `spellList`       = VALUES(`spellList`),
    `skill_list_id`   = VALUES(`skill_list_id`),
    `resist_id`       = VALUES(`resist_id`),
    `entityFlags`     = VALUES(`entityFlags`),
    `animationsub`    = VALUES(`animationsub`),
    `modelSize`       = VALUES(`modelSize`),
    `modelHitboxSize` = VALUES(`modelHitboxSize`);

-- 38 Fire, 39 Ice, 40 Air, 41 Earth, 42 Thunder, 43 Water, 44 Light, 45 Dark
INSERT INTO `mob_groups`
    (`groupid`, `poolid`, `zoneid`, `name`, `respawntime`, `spawntype`, `dropid`, `HP`, `MP`, `allegiance`)
VALUES
    (38, 1341, 100, 'Starter_Fire_Elemental',    900, 0, 0, 0, 0, 0),
    (39, 2043, 100, 'Starter_Ice_Elemental',     900, 0, 0, 0, 0, 0),
    (40, 71,   100, 'Starter_Air_Elemental',     900, 0, 0, 0, 0, 0),
    (41, 1160, 100, 'Starter_Earth_Elemental',   900, 0, 0, 0, 0, 0),
    (42, 3912, 100, 'Starter_Thunder_Elem', 900, 0, 0, 0, 0, 0),
    (43, 4309, 100, 'Starter_Water_Elemental',   900, 0, 0, 0, 0, 0),
    (44, 2413, 100, 'Starter_Light_Elemental',   900, 0, 0, 0, 0, 0),
    (45, 913,  100, 'Starter_Dark_Elemental',    900, 0, 0, 0, 0, 0),
    (38, 1341, 106, 'Starter_Fire_Elemental',    900, 0, 0, 0, 0, 0),
    (39, 2043, 106, 'Starter_Ice_Elemental',     900, 0, 0, 0, 0, 0),
    (40, 71,   106, 'Starter_Air_Elemental',     900, 0, 0, 0, 0, 0),
    (41, 1160, 106, 'Starter_Earth_Elemental',   900, 0, 0, 0, 0, 0),
    (42, 3912, 106, 'Starter_Thunder_Elem', 900, 0, 0, 0, 0, 0),
    (43, 4309, 106, 'Starter_Water_Elemental',   900, 0, 0, 0, 0, 0),
    (44, 2413, 106, 'Starter_Light_Elemental',   900, 0, 0, 0, 0, 0),
    (45, 913,  106, 'Starter_Dark_Elemental',    900, 0, 0, 0, 0, 0),
    (38, 1341, 116, 'Starter_Fire_Elemental',    900, 0, 0, 0, 0, 0),
    (39, 2043, 116, 'Starter_Ice_Elemental',     900, 0, 0, 0, 0, 0),
    (40, 71,   116, 'Starter_Air_Elemental',     900, 0, 0, 0, 0, 0),
    (41, 1160, 116, 'Starter_Earth_Elemental',   900, 0, 0, 0, 0, 0),
    (42, 3912, 116, 'Starter_Thunder_Elem', 900, 0, 0, 0, 0, 0),
    (43, 4309, 116, 'Starter_Water_Elemental',   900, 0, 0, 0, 0, 0),
    (44, 2413, 116, 'Starter_Light_Elemental',   900, 0, 0, 0, 0, 0),
    (45, 913,  116, 'Starter_Dark_Elemental',    900, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
    `poolid`      = VALUES(`poolid`),
    `name`        = VALUES(`name`),
    `respawntime` = 900,
    `spawntype`   = 0,
    `dropid`      = 0,
    `HP`          = 0,
    `MP`          = 0,
    `allegiance`  = 0;
