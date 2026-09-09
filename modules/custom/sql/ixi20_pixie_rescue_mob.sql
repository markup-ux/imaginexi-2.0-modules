-- Reserved dynamic spawn row for Pixie Rescue (group 35 / zone 100).
-- LSB 2.0 has no WotG Pixie pool; 1.0 used pool 3148 + model 0x07EE.
-- resist_id 195 is missing here, so use Light Spirit resist 104.

INSERT INTO `mob_pools` (
    `poolid`, `name`, `packet_name`, `speciesid`, `modelid`,
    `mJob`, `sJob`, `cmbSkill`, `cmbDelay`, `cmbDmgMult`,
    `behavior`, `aggro`, `true_detection`, `links`, `mobType`,
    `immunity`, `name_prefix`, `flag`, `entityFlags`, `animationsub`,
    `hasSpellScript`, `spellList`, `namevis`, `roamflag`,
    `skill_list_id`, `resist_id`, `modelSize`, `modelHitboxSize`
) VALUES (
    3148, 'Pixie', 'Pixie', 274, UNHEX('0000EE0700000000000000000000000000000000'),
    3, 3, 7, 240, 100,
    0, 0, 0, 0, 0,
    0, 0, 4421, 513, 8,
    0, 20, 0, 0,
    195, 104, 0, 6
)
ON DUPLICATE KEY UPDATE
    `name`            = 'Pixie',
    `packet_name`     = 'Pixie',
    `speciesid`       = 274,
    `modelid`         = UNHEX('0000EE0700000000000000000000000000000000'),
    `mJob`            = 3,
    `sJob`            = 3,
    `cmbSkill`        = 7,
    `skill_list_id`   = 195,
    `resist_id`       = 104,
    `animationsub`    = 8,
    `flag`            = 4421,
    `entityFlags`     = 513,
    `modelSize`       = 0,
    `modelHitboxSize` = 6;

INSERT INTO `mob_groups`
    (`groupid`, `poolid`, `zoneid`, `name`, `respawntime`, `spawntype`, `dropid`, `HP`, `MP`, `allegiance`)
VALUES
    (35, 3148, 100, 'PixieRescue', 0, 128, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
    `poolid`      = 3148,
    `name`        = 'PixieRescue',
    `respawntime` = 0,
    `spawntype`   = 128,
    `dropid`      = 0,
    `HP`          = 0,
    `MP`          = 0,
    `allegiance`  = 0;
