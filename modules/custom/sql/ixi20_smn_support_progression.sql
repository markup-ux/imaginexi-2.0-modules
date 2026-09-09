-- Imagine XI 2.0: SMN 1-20 support-first Blood Pact pacing.
-- Apply after ixi20_job_progression_37cap.sql. Does not edit SMN_LEVELS
-- in the 37-cap generator. IVs / merit nukes / 21-37 stay on that map.
-- Every avatar available at 1 gets a regular (non-AF) pact at 1.
-- Buffs and heals land in 1-8; DD is mixed through 16; Hastega II at 20.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_smn_support_pact_level_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_smn_support_pact_level_backup` (`abilityId`, `level`)
SELECT `abilityId`, `level` FROM `abilities`
WHERE `abilityId` IN (
    512, 513, 514, 515, 516, 517, 520,
    521, 522, 523, 525, 526,
    528, 529, 530, 531, 532, 533, 534,
    544, 545, 546, 547, 548, 550,
    560, 561, 562, 563, 564, 566, 569,
    576, 577, 578, 579, 580, 582,
    592, 593, 594, 595, 596, 598, 602,
    608, 609, 610, 611, 612, 614,
    624, 625, 626, 627, 628, 630,
    656, 657, 658, 660, 661,
    961, 964, 967
);

-- Lv.1: every avatar can press a BP. Support pets also heal / blink / raise.
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 512; -- healing_ruby
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 513; -- poison_nails
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 525; -- raise_ii
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 528; -- moonlit_charge
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 544; -- punch
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 560; -- rock_throw
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 576; -- barracuda_dive
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 592; -- claw
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 596; -- aerial_armor
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 608; -- axe_kick
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 624; -- shock_strike
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 656; -- camisado
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 521; -- regal_scratch
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 961; -- welt

-- Lv.4: party identity + first magic DD
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 514; -- shining_ruby
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 533; -- ecliptic_howl
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 545; -- fire_ii
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 548; -- crimson_howl
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 561; -- stone_ii
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 577; -- water_ii
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 593; -- aero_ii
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 595; -- hastega
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 609; -- blizzard_ii
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 625; -- thunder_ii

-- Lv.6: shields and heals
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 515; -- glittering_ruby
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 532; -- ecliptic_growl
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 564; -- earthen_ward
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 579; -- spring_water
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 594; -- whispering_wind
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 610; -- frost_armor
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 628; -- lightning_armor
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 660; -- noctoshield

-- Lv.8: second physicals + CC
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 516; -- meteorite
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 522; -- mewing_lullaby
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 526; -- reraise_ii
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 529; -- crescent_fang
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 530; -- lunar_cry
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 546; -- burning_strike
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 547; -- double_punch
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 562; -- rock_buster
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 578; -- tail_whip
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 580; -- slowga
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 611; -- sleepga
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 626; -- rolling_thunder
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 627; -- thunderspark
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 658; -- nightmare
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 964; -- roundhouse

-- Lv.12: healer / mage support scales
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 517; -- healing_ruby_ii
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 520; -- soothing_ruby
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 523; -- eerie_eye
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 531; -- lunar_roar
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 563; -- megalith_throw
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 612; -- double_slap
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 661; -- dream_shroud

-- Lv.16: XP physical suite
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 534; -- eclipse_bite
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 550; -- flaming_crush
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 566; -- mountain_buster
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 569; -- earthen_armor
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 582; -- spinning_dive
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 598; -- predator_claws
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 614; -- rush
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 630; -- chaotic_strike
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 657; -- somnolence
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 967; -- sonic_buffet

-- Lv.20: haste capstone
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 602; -- hastega_ii
