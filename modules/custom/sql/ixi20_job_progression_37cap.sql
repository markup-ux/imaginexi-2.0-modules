-- Imagine XI 2.0: 37-cap ability / trait / magic-spell progression.
-- Main 75 / sub 37 has the full kit. Two-hour and one-hour JAs at 1.
-- Trusts untouched. No Soldier / MON. Generated; do not edit server/sql.
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

CREATE TABLE IF NOT EXISTS `ixi20_abilities_level_backup` (
    `abilityId` SMALLINT(5) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    PRIMARY KEY (`abilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ixi20_traits_backup` (
    `traitid` TINYINT(3) UNSIGNED NOT NULL,
    `name` TEXT NOT NULL,
    `job` TINYINT(2) UNSIGNED NOT NULL,
    `level` TINYINT(2) UNSIGNED NOT NULL,
    `rank` TINYINT(2) UNSIGNED NOT NULL,
    `modifier` SMALLINT(5) UNSIGNED NOT NULL,
    `value` SMALLINT(5) NOT NULL,
    `content_tag` VARCHAR(7) DEFAULT NULL,
    `meritid` SMALLINT(5) NOT NULL DEFAULT 0,
    PRIMARY KEY (`traitid`,`job`,`level`,`rank`,`modifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `ixi20_spell_jobs_backup` (
    `spellid` SMALLINT(3) UNSIGNED NOT NULL,
    `jobs` BINARY(22) NOT NULL,
    PRIMARY KEY (`spellid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `ixi20_abilities_level_backup` (`abilityId`, `level`)
SELECT `abilityId`, `level` FROM `abilities`;

INSERT IGNORE INTO `ixi20_traits_backup`
SELECT * FROM `traits`;

INSERT IGNORE INTO `ixi20_spell_jobs_backup` (`spellid`, `jobs`)
SELECT `spellid`, `jobs` FROM `spell_list`;

-- Ability unlock remaps
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 16; -- mighty_strikes
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 17; -- hundred_fists
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 18; -- benediction
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 19; -- manafont
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 20; -- chainspell
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 21; -- perfect_dodge
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 22; -- invincible
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 23; -- blood_weapon
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 24; -- familiar
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 25; -- soul_voice
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 26; -- eagle_eye_shot
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 27; -- meikyo_shisui
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 28; -- mijin_gakure
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 29; -- spirit_surge
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 30; -- astral_flow
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 31; -- berserk
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 32; -- warcry
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 33; -- defender
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 34; -- aggressor
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 35; -- provoke
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 36; -- focus
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 37; -- dodge
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 38; -- chakra
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 39; -- boost
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 40; -- counterstance
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 41; -- steal
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 42; -- flee
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 43; -- hide
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 44; -- sneak_attack
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 45; -- mug
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 46; -- shield_bash
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 47; -- holy_circle
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 48; -- sentinel
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 49; -- souleater
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 50; -- arcane_circle
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 51; -- last_resort
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 53; -- gauge
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 54; -- tame
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 56; -- scavenge
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 57; -- shadowbind
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 58; -- camouflage
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 60; -- barrage
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 62; -- third_eye
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 63; -- meditate
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 64; -- warding_circle
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 65; -- ancient_circle
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 66; -- jump
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 67; -- high_jump
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 68; -- super_jump
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 70; -- heel
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 71; -- leave
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 72; -- sic
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 73; -- stay
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 74; -- divine_seal
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 75; -- elemental_seal
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 76; -- trick_attack
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 77; -- weapon_bash
UPDATE `abilities` SET `level` = 5 WHERE `abilityId` = 78; -- reward
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 79; -- cover
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 80; -- spirit_link
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 82; -- chi_blast
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 83; -- convert
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 84; -- accomplice
UPDATE `abilities` SET `level` = 9 WHERE `abilityId` = 85; -- call_beast
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 86; -- unlimited_shot
UPDATE `abilities` SET `level` = 24 WHERE `abilityId` = 92; -- rampart
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 93; -- azure_lore
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 94; -- chain_affinity
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 95; -- burst_affinity
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 96; -- wild_card
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 97; -- phantom_roll
UPDATE `abilities` SET `level` = 19 WHERE `abilityId` = 98; -- fighters_roll
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 99; -- monks_roll
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 100; -- healers_roll
UPDATE `abilities` SET `level` = 22 WHERE `abilityId` = 101; -- wizards_roll
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 102; -- warlocks_roll
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 103; -- rogues_roll
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 104; -- gallants_roll
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 105; -- chaos_roll
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 106; -- beast_roll
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 107; -- choral_roll
UPDATE `abilities` SET `level` = 5 WHERE `abilityId` = 108; -- hunters_roll
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 109; -- samurai_roll
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 110; -- ninja_roll
UPDATE `abilities` SET `level` = 9 WHERE `abilityId` = 111; -- drachen_roll
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 112; -- evokers_roll
UPDATE `abilities` SET `level` = 7 WHERE `abilityId` = 113; -- maguss_roll
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 114; -- corsairs_roll
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 115; -- puppet_roll
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 116; -- dancers_roll
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 117; -- scholars_roll
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 118; -- bolters_roll
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 119; -- casters_roll
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 120; -- coursers_roll
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 121; -- blitzers_roll
UPDATE `abilities` SET `level` = 33 WHERE `abilityId` = 122; -- tacticians_roll
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 123; -- double-up
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 124; -- quick_draw
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 125; -- fire_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 126; -- ice_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 127; -- wind_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 128; -- earth_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 129; -- thunder_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 130; -- water_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 131; -- light_shot
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 132; -- dark_shot
UPDATE `abilities` SET `level` = 19 WHERE `abilityId` = 133; -- random_deal
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 135; -- overdrive
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 137; -- repair
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 140; -- retrieve
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 149; -- warriors_charge
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 150; -- tomahawk
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 151; -- mantra
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 152; -- formless_strikes
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 153; -- martyr
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 154; -- devotion
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 155; -- assassins_charge
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 156; -- feint
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 157; -- fealty
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 158; -- chivalry
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 159; -- dark_seal
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 160; -- diabolic_eye
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 161; -- feral_howl
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 162; -- killer_instinct
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 163; -- nightingale
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 164; -- troubadour
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 165; -- stealth_shot
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 166; -- flashy_shot
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 167; -- shikikoyo
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 168; -- blade_bash
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 169; -- deep_breathing
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 170; -- angon
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 171; -- sange
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 173; -- hasso
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 174; -- seigan
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 175; -- convergence
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 176; -- diffusion
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 177; -- snake_eye
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 178; -- fold
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 179; -- role_reversal
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 180; -- ventriloquy
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 181; -- trance
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 182; -- sambas
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 183; -- waltzes
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 184; -- drain_samba
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 185; -- drain_samba_ii
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 186; -- drain_samba_iii
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 187; -- aspir_samba
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 188; -- aspir_samba_ii
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 189; -- haste_samba
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 190; -- curing_waltz
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 191; -- curing_waltz_ii
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 192; -- curing_waltz_iii
UPDATE `abilities` SET `level` = 27 WHERE `abilityId` = 193; -- curing_waltz_iv
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 194; -- healing_waltz
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 195; -- divine_waltz
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 196; -- spectral_jig
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 197; -- chocobo_jig
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 198; -- jigs
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 199; -- steps
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 200; -- flourishes_i
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 201; -- quickstep
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 202; -- box_step
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 203; -- stutter_step
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 204; -- animated_flourish
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 205; -- desperate_flourish
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 206; -- reverse_flourish
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 207; -- violent_flourish
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 208; -- building_flourish
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 209; -- wild_flourish
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 210; -- tabula_rasa
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 211; -- light_arts
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 212; -- dark_arts
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 213; -- flourishes_ii
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 214; -- modus_veritas
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 215; -- penury
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 216; -- celerity
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 217; -- rapture
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 218; -- accession
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 219; -- parsimony
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 220; -- alacrity
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 221; -- ebullience
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 222; -- manifestation
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 223; -- stratagems
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 224; -- velocity_shot
UPDATE `abilities` SET `level` = 18 WHERE `abilityId` = 225; -- snarl
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 226; -- retaliation
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 227; -- footwork
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 228; -- despoil
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 229; -- pianissimo
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 230; -- sekkanoki
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 232; -- elemental_siphon
UPDATE `abilities` SET `level` = 14 WHERE `abilityId` = 233; -- sublimation
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 234; -- addendum_white
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 235; -- addendum_black
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 236; -- collaborator
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 237; -- saber_dance
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 238; -- fan_dance
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 239; -- no_foot_rise
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 240; -- altruism
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 241; -- focalization
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 242; -- tranquility
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 243; -- equanimity
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 244; -- enlightenment
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 245; -- afflatus_solace
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 246; -- afflatus_misery
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 247; -- composure
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 248; -- yonin
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 249; -- innin
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 250; -- avatars_favor
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 251; -- ready
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 252; -- restraint
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 253; -- perfect_counter
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 254; -- mana_wall
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 255; -- divine_emblem
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 256; -- nether_void
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 257; -- double_shot
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 258; -- sengikori
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 259; -- futae
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 260; -- spirit_jump
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 261; -- presto
UPDATE `abilities` SET `level` = 30 WHERE `abilityId` = 262; -- divine_waltz_ii
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 263; -- flourishes_iii
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 264; -- climactic_flourish
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 265; -- libra
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 266; -- tactical_switch
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 267; -- blood_rage
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 269; -- impetus
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 270; -- divine_caress
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 271; -- sacrosanctity
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 272; -- enmity_douse
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 273; -- manawell
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 274; -- saboteur
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 275; -- spontaneity
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 276; -- conspirator
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 277; -- sepulcher
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 278; -- palisade
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 279; -- arcane_crest
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 280; -- scarlet_delirium
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 281; -- spur
UPDATE `abilities` SET `level` = 36 WHERE `abilityId` = 282; -- run_wild
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 283; -- tenuto
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 284; -- marcato
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 285; -- bounty_shot
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 286; -- decoy_shot
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 287; -- hamanoha
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 288; -- hagakure
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 291; -- issekigan
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 292; -- dragon_breaker
UPDATE `abilities` SET `level` = 33 WHERE `abilityId` = 293; -- soul_jump
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 295; -- steady_wing
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 296; -- mana_cede
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 297; -- efflux
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 298; -- unbridled_learning
UPDATE `abilities` SET `level` = 33 WHERE `abilityId` = 301; -- triple_shot
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 302; -- allies_roll
UPDATE `abilities` SET `level` = 35 WHERE `abilityId` = 303; -- misers_roll
UPDATE `abilities` SET `level` = 36 WHERE `abilityId` = 304; -- companions_roll
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 305; -- avengers_roll
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 309; -- cooldown
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 310; -- deus_ex_automata
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 311; -- curing_waltz_v
UPDATE `abilities` SET `level` = 32 WHERE `abilityId` = 312; -- feather_step
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 313; -- striking_flourish
UPDATE `abilities` SET `level` = 36 WHERE `abilityId` = 314; -- ternary_flourish
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 316; -- perpetuance
UPDATE `abilities` SET `level` = 34 WHERE `abilityId` = 317; -- immanence
UPDATE `abilities` SET `level` = 35 WHERE `abilityId` = 318; -- smiting_breath
UPDATE `abilities` SET `level` = 35 WHERE `abilityId` = 319; -- restoring_breath
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 320; -- konzen-ittai
UPDATE `abilities` SET `level` = 36 WHERE `abilityId` = 321; -- bully
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 322; -- maintenance
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 323; -- brazen_rush
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 324; -- inner_strength
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 325; -- asylum
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 326; -- subtle_sorcery
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 327; -- stymie
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 328; -- larceny
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 329; -- intervene
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 330; -- soul_enslavement
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 331; -- unleash
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 332; -- clarion_call
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 333; -- overkill
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 334; -- yaegasumi
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 335; -- mikage
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 336; -- fly_high
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 337; -- astral_conduit
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 338; -- unbridled_wisdom
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 339; -- cutting_cards
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 340; -- heady_artifice
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 341; -- grand_pas
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 342; -- caper_emissarius
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 344; -- swipe
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 345; -- full_circle
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 346; -- lasting_emanation
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 347; -- ecliptic_attrition
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 348; -- collimated_fervor
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 349; -- life_cycle
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 350; -- blaze_of_glory
UPDATE `abilities` SET `level` = 27 WHERE `abilityId` = 351; -- dematerialize
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 352; -- theurgic_focus
UPDATE `abilities` SET `level` = 35 WHERE `abilityId` = 353; -- concentric_pulse
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 354; -- mending_halation
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 355; -- radial_arcana
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 356; -- elemental_sforzo
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 357; -- rune_enchantment
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 358; -- ignis
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 359; -- gelus
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 360; -- flabra
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 361; -- tellus
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 362; -- sulpor
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 363; -- unda
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 364; -- lux
UPDATE `abilities` SET `level` = 3 WHERE `abilityId` = 365; -- tenebrae
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 366; -- vallation
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 367; -- swordplay
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 368; -- lunge
UPDATE `abilities` SET `level` = 16 WHERE `abilityId` = 369; -- pflug
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 370; -- embolden
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 371; -- valiance
UPDATE `abilities` SET `level` = 27 WHERE `abilityId` = 372; -- gambit
UPDATE `abilities` SET `level` = 33 WHERE `abilityId` = 373; -- liement
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 374; -- one_for_all
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 375; -- rayke
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 376; -- battuta
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 377; -- widened_compass
UPDATE `abilities` SET `level` = 1 WHERE `abilityId` = 378; -- odyllic_subterfuge
UPDATE `abilities` SET `level` = 27 WHERE `abilityId` = 381; -- chocobo_jig_ii
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 383; -- vivacious_pulse
UPDATE `abilities` SET `level` = 20 WHERE `abilityId` = 384; -- contradance
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 385; -- apogee
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 386; -- entrust
UPDATE `abilities` SET `level` = 9 WHERE `abilityId` = 387; -- bestial_loyalty
UPDATE `abilities` SET `level` = 33 WHERE `abilityId` = 388; -- cascade
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 389; -- consume_mana
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 390; -- naturalists_roll
UPDATE `abilities` SET `level` = 27 WHERE `abilityId` = 391; -- runeists_roll
UPDATE `abilities` SET `level` = 36 WHERE `abilityId` = 392; -- crooked_cards
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 393; -- spirit_bond
UPDATE `abilities` SET `level` = 27 WHERE `abilityId` = 394; -- majesty
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 512; -- healing_ruby
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 513; -- poison_nails
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 514; -- shining_ruby
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 515; -- glittering_ruby
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 516; -- meteorite
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 517; -- healing_ruby_ii
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 519; -- holy_mist
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 520; -- soothing_ruby
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 522; -- mewing_lullaby
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 523; -- eerie_eye
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 524; -- level_X_holy
UPDATE `abilities` SET `level` = 6 WHERE `abilityId` = 525; -- raise_ii
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 526; -- reraise_ii
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 527; -- altana_s_favor
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 528; -- moonlit_charge
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 529; -- crescent_fang
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 530; -- lunar_cry
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 531; -- lunar_roar
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 532; -- ecliptic_growl
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 533; -- ecliptic_howl
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 534; -- eclipse_bite
UPDATE `abilities` SET `level` = 29 WHERE `abilityId` = 537; -- lunar_bay
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 538; -- heavenward_howl
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 539; -- impact
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 544; -- punch
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 545; -- fire_ii
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 546; -- burning_strike
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 547; -- double_punch
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 548; -- crimson_howl
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 549; -- fire_iv
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 550; -- flaming_crush
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 551; -- meteor_strike
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 553; -- inferno_howl
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 554; -- conflag_strike
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 560; -- rock_throw
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 561; -- stone_ii
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 562; -- rock_buster
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 563; -- megalith_throw
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 564; -- earthen_ward
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 565; -- stone_iv
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 566; -- mountain_buster
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 567; -- geocrush
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 569; -- earthen_armor
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 570; -- crag_throw
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 576; -- barracuda_dive
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 577; -- water_ii
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 578; -- tail_whip
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 579; -- spring_water
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 580; -- slowga
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 581; -- water_iv
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 582; -- spinning_dive
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 583; -- grand_fall
UPDATE `abilities` SET `level` = 31 WHERE `abilityId` = 585; -- tidal_roar
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 586; -- soothing_current
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 592; -- claw
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 593; -- aero_ii
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 594; -- whispering_wind
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 595; -- hastega
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 596; -- aerial_armor
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 597; -- aero_iv
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 598; -- predator_claws
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 599; -- wind_blade
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 601; -- fleet_wind
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 602; -- hastega_ii
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 609; -- blizzard_ii
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 610; -- frost_armor
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 611; -- sleepga
UPDATE `abilities` SET `level` = 13 WHERE `abilityId` = 612; -- double_slap
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 613; -- blizzard_iv
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 614; -- rush
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 615; -- heavenly_strike
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 617; -- diamond_storm
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 618; -- crystal_blessing
UPDATE `abilities` SET `level` = 4 WHERE `abilityId` = 625; -- thunder_ii
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 626; -- rolling_thunder
UPDATE `abilities` SET `level` = 8 WHERE `abilityId` = 627; -- thunderspark
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 628; -- lightning_armor
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 629; -- thunder_iv
UPDATE `abilities` SET `level` = 17 WHERE `abilityId` = 630; -- chaotic_strike
UPDATE `abilities` SET `level` = 23 WHERE `abilityId` = 631; -- thunderstorm
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 633; -- shock_squall
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 634; -- volt_strike
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 657; -- somnolence
UPDATE `abilities` SET `level` = 12 WHERE `abilityId` = 658; -- nightmare
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 659; -- ultimate_terror
UPDATE `abilities` SET `level` = 15 WHERE `abilityId` = 660; -- noctoshield
UPDATE `abilities` SET `level` = 21 WHERE `abilityId` = 661; -- dream_shroud
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 662; -- nether_blast
UPDATE `abilities` SET `level` = 26 WHERE `abilityId` = 664; -- ruinous_omen
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 665; -- night_terror
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 666; -- pavor_nocturnus
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 667; -- blindside
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 668; -- deconstruction
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 669; -- chronoshift
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 671; -- perfect_defense
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 672; -- foot_kick
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 673; -- dust_cloud
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 674; -- whirl_claws
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 675; -- head_butt
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 676; -- dream_flower
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 677; -- wild_oats
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 678; -- leaf_dagger
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 679; -- scream
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 680; -- roar
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 681; -- razor_fang
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 682; -- claw_cyclone
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 683; -- tail_blow
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 684; -- fireball
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 685; -- blockhead
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 686; -- brain_crush
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 687; -- infrasonics
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 688; -- secretion
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 689; -- lamb_chop
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 690; -- rage
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 691; -- sheep_charge
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 692; -- sheep_song
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 693; -- bubble_shower
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 694; -- bubble_curtain
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 695; -- big_scissors
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 696; -- scissor_guard
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 697; -- metallic_body
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 698; -- needleshot
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 699; -- random_needles
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 700; -- frogkick
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 701; -- spore
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 702; -- queasyshroom
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 703; -- numbshroom
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 704; -- shakeshroom
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 705; -- silence_gas
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 706; -- dark_spore
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 707; -- power_attack
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 708; -- hi-freq_field
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 709; -- rhino_attack
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 710; -- rhino_guard
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 711; -- spoil
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 712; -- cursed_sphere
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 713; -- venom
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 714; -- sandblast
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 715; -- sandpit
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 716; -- venom_spray
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 717; -- mandibular_bite
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 718; -- soporific
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 719; -- gloeosuccus
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 720; -- palsy_pollen
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 721; -- geist_wall
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 722; -- numbing_noise
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 723; -- nimble_snap
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 724; -- cyclotail
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 725; -- toxic_spit
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 726; -- double_claw
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 727; -- grapple
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 728; -- spinning_top
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 729; -- filamented_hold
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 730; -- chaotic_eye
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 731; -- blaster
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 732; -- suction
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 733; -- drainkiss
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 734; -- snow_cloud
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 735; -- wild_carrot
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 736; -- sudden_lunge
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 737; -- spiral_spin
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 738; -- noisome_powder
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 740; -- acid_mist
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 741; -- tp_drainkiss
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 743; -- scythe_tail
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 744; -- ripper_fang
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 745; -- chomp_rush
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 746; -- charged_whisker
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 747; -- purulent_ooze
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 748; -- corrosive_ooze
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 749; -- back_heel
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 750; -- jettatura
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 751; -- choke_breath
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 752; -- fantod
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 753; -- tortoise_stomp
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 754; -- harden_shell
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 755; -- aqua_breath
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 756; -- wing_slap
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 757; -- beak_lunge
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 758; -- intimidate
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 759; -- recoil_dive
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 760; -- water_wall
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 761; -- sensilla_blades
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 762; -- tegmina_buffet
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 763; -- molting_plumage
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 764; -- swooping_frenzy
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 765; -- sweeping_gouge
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 766; -- zealous_snort
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 767; -- pentapeck
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 768; -- tickling_tendrils
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 769; -- stink_bomb
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 770; -- nectarous_deluge
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 771; -- nepenthic_plunge
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 772; -- somersault
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 773; -- pacifying_ruby
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 774; -- foul_waters
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 775; -- pestilent_plume
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 776; -- pecking_flurry
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 777; -- sickle_slash
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 778; -- acid_spray
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 779; -- spider_web
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 781; -- infected_leech
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 782; -- gloom_spray
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 786; -- disembowel
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 787; -- extirpating_salvo
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 788; -- venom_shower
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 789; -- mega_scissors
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 790; -- frenzied_rage
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 791; -- rhinowrecker
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 792; -- fluid_toss
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 793; -- fluid_spread
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 794; -- digest
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 795; -- crossthrash
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 796; -- predatory_glare
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 797; -- hoof_volley
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 798; -- nihility_song
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 960; -- clarsach_call
UPDATE `abilities` SET `level` = 10 WHERE `abilityId` = 964; -- roundhouse
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 967; -- sonic_buffet
UPDATE `abilities` SET `level` = 28 WHERE `abilityId` = 968; -- tornado_ii
UPDATE `abilities` SET `level` = 37 WHERE `abilityId` = 970; -- hysteric_assault

-- Trait unlock remaps (job 1-22 only; replace to avoid PK clashes)
DELETE FROM `traits` WHERE `job` BETWEEN 1 AND 22;
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,4,1,25,10,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,4,1,26,10,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,12,2,25,22,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,12,2,26,22,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,19,3,25,35,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,19,3,26,35,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,26,4,25,48,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,26,4,26,48,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,32,5,25,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,32,5,26,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,36,6,25,73,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',11,36,6,26,73,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',14,12,1,25,10,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',14,12,1,26,10,NULL,0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',14,24,2,25,22,'TOAU',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',14,24,2,26,22,'TOAU',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',14,30,3,25,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',14,30,3,26,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',19,12,1,25,10,'WOTG',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',19,12,1,26,10,'WOTG',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',19,23,2,25,22,'WOTG',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',19,23,2,26,22,'WOTG',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',19,29,3,25,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',19,29,3,26,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',22,19,1,25,10,'SOA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',22,19,1,26,10,'SOA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',22,26,2,25,22,'SOA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',22,26,2,26,22,'SOA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',22,34,3,25,35,'SOA',0);
INSERT INTO `traits` VALUES (1,'accuracy bonus',22,34,3,26,35,'SOA',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',6,4,1,68,10,NULL,0);
INSERT INTO `traits` VALUES (2,'evasion bonus',6,12,2,68,22,NULL,0);
INSERT INTO `traits` VALUES (2,'evasion bonus',6,19,3,68,35,NULL,0);
INSERT INTO `traits` VALUES (2,'evasion bonus',6,27,4,68,48,NULL,0);
INSERT INTO `traits` VALUES (2,'evasion bonus',6,29,5,68,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',6,33,6,68,72,'ABYSSEA',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',18,8,1,68,10,'TOAU',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',18,15,2,68,22,'TOAU',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',18,23,3,68,35,'TOAU',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',18,29,4,68,48,'TOAU',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',19,6,1,68,10,'WOTG',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',19,17,2,68,22,'WOTG',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',19,28,3,68,35,'WOTG',0);
INSERT INTO `traits` VALUES (2,'evasion bonus',19,32,4,68,48,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',1,12,1,23,10,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',1,12,1,24,10,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',1,25,2,23,22,'ROV',0);
INSERT INTO `traits` VALUES (3,'attack bonus',1,25,2,24,22,'ROV',0);
INSERT INTO `traits` VALUES (3,'attack bonus',1,34,3,23,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',1,34,3,24,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,4,1,23,10,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,4,1,24,10,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,12,2,23,22,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,12,2,24,22,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,19,3,23,35,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,19,3,24,35,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,26,4,23,48,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,26,4,24,48,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,29,5,23,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,29,5,24,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,31,6,23,72,'ROV',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,31,6,24,72,'ROV',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,34,7,23,84,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,34,7,24,84,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,37,8,23,96,'ROV',0);
INSERT INTO `traits` VALUES (3,'attack bonus',8,37,8,24,96,'ROV',0);
INSERT INTO `traits` VALUES (3,'attack bonus',14,4,1,23,10,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',14,4,1,24,10,NULL,0);
INSERT INTO `traits` VALUES (3,'attack bonus',14,35,2,23,22,'ABYSSEA',0);
INSERT INTO `traits` VALUES (3,'attack bonus',14,35,2,24,22,'ABYSSEA',0);
INSERT INTO `traits` VALUES (4,'defense bonus',1,4,1,1,10,NULL,0);
INSERT INTO `traits` VALUES (4,'defense bonus',1,17,2,1,22,'ROV',0);
INSERT INTO `traits` VALUES (4,'defense bonus',1,32,3,1,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (4,'defense bonus',7,4,1,1,10,NULL,0);
INSERT INTO `traits` VALUES (4,'defense bonus',7,12,2,1,22,NULL,0);
INSERT INTO `traits` VALUES (4,'defense bonus',7,20,3,1,35,NULL,0);
INSERT INTO `traits` VALUES (4,'defense bonus',7,27,4,1,48,NULL,0);
INSERT INTO `traits` VALUES (4,'defense bonus',7,29,5,1,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (4,'defense bonus',7,35,6,1,72,'ABYSSEA',0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',4,4,1,28,20,NULL,0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',4,12,2,28,24,NULL,0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',4,19,3,28,28,NULL,0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',4,27,4,28,32,NULL,0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',4,31,5,28,36,'ABYSSEA',0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',4,35,6,28,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',5,8,1,28,20,NULL,0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',5,16,2,28,24,NULL,0);
INSERT INTO `traits` VALUES (5,'magic atk. bonus',5,33,3,28,28,'ABYSSEA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',3,4,1,29,10,NULL,0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',3,12,2,29,12,NULL,0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',3,20,3,29,14,NULL,0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',3,27,4,29,16,NULL,0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',3,31,5,29,18,'ABYSSEA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',3,35,6,29,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',5,10,1,29,10,NULL,0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',5,17,2,29,12,NULL,0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',5,37,3,29,14,'ABYSSEA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,4,1,29,10,'SOA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,12,2,29,12,'SOA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,19,3,29,14,'SOA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,26,4,29,16,'SOA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,29,5,29,18,'SOA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,34,6,29,20,'SOA',0);
INSERT INTO `traits` VALUES (6,'magic def. bonus',22,37,7,29,22,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',1,12,1,1095,30,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',1,19,2,1095,60,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',1,26,3,1095,120,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',1,34,4,1095,180,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',2,6,1,1095,30,NULL,0);
INSERT INTO `traits` VALUES (7,'max hp boost',2,10,2,1095,60,NULL,0);
INSERT INTO `traits` VALUES (7,'max hp boost',2,14,3,1095,120,NULL,0);
INSERT INTO `traits` VALUES (7,'max hp boost',2,17,4,1095,180,NULL,0);
INSERT INTO `traits` VALUES (7,'max hp boost',2,21,5,1095,240,'ABYSSEA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',2,25,6,1095,280,'ABYSSEA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',7,18,1,1095,30,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',7,33,2,1095,60,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',13,8,1,1095,30,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',13,15,2,1095,60,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',13,23,3,1095,120,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',13,30,4,1095,180,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',13,37,5,1095,240,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',22,8,1,1095,30,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',22,15,2,1095,60,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',22,23,3,1095,120,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',22,30,4,1095,180,'SOA',0);
INSERT INTO `traits` VALUES (7,'max hp boost',22,37,5,1095,240,'SOA',0);
INSERT INTO `traits` VALUES (8,'max mp boost',15,4,1,1096,10,NULL,0);
INSERT INTO `traits` VALUES (8,'max mp boost',15,12,2,1096,20,NULL,0);
INSERT INTO `traits` VALUES (8,'max mp boost',15,20,3,1096,40,NULL,0);
INSERT INTO `traits` VALUES (8,'max mp boost',15,27,4,1096,60,NULL,0);
INSERT INTO `traits` VALUES (8,'max mp boost',15,29,5,1096,80,'ABYSSEA',0);
INSERT INTO `traits` VALUES (8,'max mp boost',15,37,6,1096,100,'ABYSSEA',0);
INSERT INTO `traits` VALUES (8,'max mp boost',20,12,1,1096,10,'WOTG',0);
INSERT INTO `traits` VALUES (8,'max mp boost',20,33,2,1096,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (8,'max mp boost',21,12,1,1096,10,'SOA',0);
INSERT INTO `traits` VALUES (8,'max mp boost',21,23,2,1096,20,'SOA',0);
INSERT INTO `traits` VALUES (8,'max mp boost',21,34,3,1096,40,'SOA',0);
INSERT INTO `traits` VALUES (9,'auto regen',3,10,1,370,1,NULL,0);
INSERT INTO `traits` VALUES (9,'auto regen',3,29,2,370,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (9,'auto regen',22,13,1,370,1,'SOA',0);
INSERT INTO `traits` VALUES (9,'auto regen',22,25,2,370,2,'SOA',0);
INSERT INTO `traits` VALUES (9,'auto regen',22,36,3,370,3,'SOA',0);
INSERT INTO `traits` VALUES (10,'auto refresh',7,14,1,369,1,'TOAU',0);
INSERT INTO `traits` VALUES (10,'auto refresh',15,10,1,369,1,NULL,0);
INSERT INTO `traits` VALUES (10,'auto refresh',15,35,2,369,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (11,'rapid shot',11,6,1,359,25,NULL,0);
INSERT INTO `traits` VALUES (11,'rapid shot',11,27,2,359,30,'SOA',0);
INSERT INTO `traits` VALUES (11,'rapid shot',17,6,1,359,25,'TOAU',0);
INSERT INTO `traits` VALUES (11,'rapid shot',17,35,2,359,30,'SOA',0);
INSERT INTO `traits` VALUES (12,'fast cast',5,6,1,170,10,NULL,0);
INSERT INTO `traits` VALUES (12,'fast cast',5,14,2,170,15,NULL,0);
INSERT INTO `traits` VALUES (12,'fast cast',5,21,3,170,20,NULL,0);
INSERT INTO `traits` VALUES (12,'fast cast',5,29,4,170,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (12,'fast cast',5,34,5,170,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',4,8,1,296,25,NULL,0);
INSERT INTO `traits` VALUES (13,'conserve mp',4,29,2,296,28,'ABYSSEA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',4,33,3,296,31,'ABYSSEA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',20,10,1,296,25,'WOTG',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,4,1,296,25,'SOA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,10,2,296,28,'SOA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,15,3,296,31,'SOA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,21,4,296,34,'SOA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,26,5,296,37,'SOA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,32,6,296,40,'SOA',0);
INSERT INTO `traits` VALUES (13,'conserve mp',21,37,7,296,43,'SOA',0);
INSERT INTO `traits` VALUES (14,'store tp',12,4,1,73,10,NULL,0);
INSERT INTO `traits` VALUES (14,'store tp',12,12,2,73,15,NULL,0);
INSERT INTO `traits` VALUES (14,'store tp',12,19,3,73,20,NULL,0);
INSERT INTO `traits` VALUES (14,'store tp',12,27,4,73,25,NULL,0);
INSERT INTO `traits` VALUES (14,'store tp',12,34,5,73,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (15,'double attack',1,10,1,288,10,NULL,0);
INSERT INTO `traits` VALUES (15,'double attack',1,19,2,288,12,'ROV',0);
INSERT INTO `traits` VALUES (15,'double attack',1,32,4,288,16,'ROV',0);
INSERT INTO `traits` VALUES (15,'double attack',1,37,5,288,18,'ROV',0);
INSERT INTO `traits` VALUES (16,'triple attack',6,21,1,302,5,NULL,0);
INSERT INTO `traits` VALUES (16,'triple attack',6,36,2,302,6,'ABYSSEA',0);
INSERT INTO `traits` VALUES (17,'counter',2,4,1,291,10,NULL,0);
INSERT INTO `traits` VALUES (17,'counter',2,31,2,291,12,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',6,31,1,259,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',6,34,2,259,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',6,37,3,259,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',13,4,1,259,10,NULL,0);
INSERT INTO `traits` VALUES (18,'dual wield',13,10,2,259,15,NULL,0);
INSERT INTO `traits` VALUES (18,'dual wield',13,17,3,259,25,NULL,0);
INSERT INTO `traits` VALUES (18,'dual wield',13,25,4,259,30,NULL,0);
INSERT INTO `traits` VALUES (18,'dual wield',13,32,5,259,35,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',19,8,1,259,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',19,15,2,259,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',19,23,3,259,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (18,'dual wield',19,30,4,259,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (19,'treasure hunter',6,6,1,303,1,NULL,0);
INSERT INTO `traits` VALUES (20,'gilfinder',6,2,1,897,1,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,1,1,173,80,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,7,2,173,100,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,12,3,173,120,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,18,4,173,140,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,23,5,173,160,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,29,6,173,180,NULL,0);
INSERT INTO `traits` VALUES (23,'martial arts',2,31,7,173,200,'ABYSSEA',0);
INSERT INTO `traits` VALUES (23,'martial arts',18,10,1,173,80,'TOAU',0);
INSERT INTO `traits` VALUES (23,'martial arts',18,19,2,173,100,'TOAU',0);
INSERT INTO `traits` VALUES (23,'martial arts',18,28,3,173,120,'TOAU',0);
INSERT INTO `traits` VALUES (23,'martial arts',18,33,4,173,140,'ABYSSEA',0);
INSERT INTO `traits` VALUES (23,'martial arts',18,37,5,173,160,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',3,8,1,71,3,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',3,14,2,71,6,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',3,20,3,71,9,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',3,20,3,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',3,25,4,71,12,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',3,25,4,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',3,31,5,71,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',3,31,5,295,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',3,37,6,71,18,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',3,37,6,295,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',4,6,1,71,3,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,12,2,71,6,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,17,3,71,9,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,17,3,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,23,4,71,12,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,23,4,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,29,5,71,15,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,29,5,295,2,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',4,37,6,71,18,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',4,37,6,295,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',5,12,1,71,3,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',5,21,2,71,6,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',5,29,3,71,9,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',5,29,3,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',5,35,4,71,12,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',5,35,4,295,1,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',15,6,1,71,3,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,12,2,71,6,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,18,3,71,9,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,18,3,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,23,4,71,12,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,23,4,295,1,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,27,5,71,15,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,27,5,295,2,NULL,0);
INSERT INTO `traits` VALUES (24,'clear mind',15,35,6,71,18,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',15,35,6,295,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,8,1,71,3,'WOTG',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,13,2,71,6,'WOTG',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,19,3,71,9,'WOTG',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,19,3,295,1,'WOTG',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,25,4,71,12,'WOTG',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,25,4,295,1,'WOTG',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,29,5,71,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,29,5,295,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,36,6,71,18,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',20,36,6,295,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,8,1,71,3,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,15,2,71,6,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,23,3,71,9,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,23,3,295,1,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,30,4,71,12,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,30,4,295,1,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,37,5,71,15,'SOA',0);
INSERT INTO `traits` VALUES (24,'clear mind',21,37,5,295,2,'SOA',0);
INSERT INTO `traits` VALUES (25,'shield mastery',1,30,1,485,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (25,'shield mastery',1,33,2,485,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (25,'shield mastery',1,35,3,485,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (25,'shield mastery',5,33,1,485,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (25,'shield mastery',5,37,2,485,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (25,'shield mastery',7,10,1,485,10,'TOAU',0);
INSERT INTO `traits` VALUES (25,'shield mastery',7,20,2,485,20,'TOAU',0);
INSERT INTO `traits` VALUES (25,'shield mastery',7,29,3,485,30,'TOAU',0);
INSERT INTO `traits` VALUES (25,'shield mastery',7,37,4,485,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (32,'beast killer',9,27,1,230,8,NULL,0);
INSERT INTO `traits` VALUES (32,'beast killer',9,36,2,230,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (33,'plantoid killer',9,23,1,229,8,NULL,0);
INSERT INTO `traits` VALUES (33,'plantoid killer',9,34,2,229,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (34,'vermin killer',9,4,1,224,8,NULL,0);
INSERT INTO `traits` VALUES (34,'vermin killer',9,29,2,224,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (35,'lizard killer',9,15,1,227,8,NULL,0);
INSERT INTO `traits` VALUES (35,'lizard killer',9,32,2,227,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (36,'bird killer',9,8,1,225,8,NULL,0);
INSERT INTO `traits` VALUES (36,'bird killer',9,30,2,225,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (37,'amorph killer',9,12,1,226,8,NULL,0);
INSERT INTO `traits` VALUES (37,'amorph killer',9,31,2,226,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (38,'aquan killer',9,19,1,228,8,NULL,0);
INSERT INTO `traits` VALUES (38,'aquan killer',9,33,2,228,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (39,'undead killer',7,3,1,231,8,NULL,0);
INSERT INTO `traits` VALUES (39,'undead killer',7,33,2,231,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (41,'arcana killer',8,10,1,232,8,NULL,0);
INSERT INTO `traits` VALUES (41,'arcana killer',8,32,2,232,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (42,'demon killer',12,15,1,234,8,NULL,0);
INSERT INTO `traits` VALUES (42,'demon killer',12,33,2,234,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (43,'dragon killer',14,10,1,233,8,NULL,0);
INSERT INTO `traits` VALUES (43,'dragon killer',14,34,2,233,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (48,'resist sleep',7,8,1,240,10,NULL,0);
INSERT INTO `traits` VALUES (48,'resist sleep',7,16,2,240,15,NULL,0);
INSERT INTO `traits` VALUES (48,'resist sleep',7,23,3,240,20,NULL,0);
INSERT INTO `traits` VALUES (48,'resist sleep',7,29,4,240,25,NULL,0);
INSERT INTO `traits` VALUES (48,'resist sleep',7,31,5,240,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (49,'resist poison',11,8,1,241,10,NULL,0);
INSERT INTO `traits` VALUES (49,'resist poison',11,15,2,241,15,NULL,0);
INSERT INTO `traits` VALUES (49,'resist poison',11,23,3,241,20,NULL,0);
INSERT INTO `traits` VALUES (49,'resist poison',11,30,4,241,25,NULL,0);
INSERT INTO `traits` VALUES (50,'resist paralyze',8,8,1,242,10,NULL,0);
INSERT INTO `traits` VALUES (50,'resist paralyze',8,15,2,242,15,NULL,0);
INSERT INTO `traits` VALUES (50,'resist paralyze',8,23,3,242,20,NULL,0);
INSERT INTO `traits` VALUES (50,'resist paralyze',8,28,4,242,25,NULL,0);
INSERT INTO `traits` VALUES (50,'resist paralyze',8,30,5,242,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (50,'resist paralyze',17,3,1,242,10,'TOAU',0);
INSERT INTO `traits` VALUES (50,'resist paralyze',17,10,2,242,15,'TOAU',0);
INSERT INTO `traits` VALUES (50,'resist paralyze',17,18,3,242,20,'TOAU',0);
INSERT INTO `traits` VALUES (50,'resist paralyze',17,26,4,242,25,'TOAU',0);
INSERT INTO `traits` VALUES (50,'resist paralyze',17,32,5,242,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (51,'resist blind',12,2,1,243,10,NULL,0);
INSERT INTO `traits` VALUES (51,'resist blind',12,10,2,243,15,NULL,0);
INSERT INTO `traits` VALUES (51,'resist blind',12,17,3,243,20,NULL,0);
INSERT INTO `traits` VALUES (51,'resist blind',12,25,4,243,25,NULL,0);
INSERT INTO `traits` VALUES (51,'resist blind',12,31,5,243,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (52,'resist silence',10,3,1,244,10,NULL,0);
INSERT INTO `traits` VALUES (52,'resist silence',10,10,2,244,15,NULL,0);
INSERT INTO `traits` VALUES (52,'resist silence',10,18,3,244,20,NULL,0);
INSERT INTO `traits` VALUES (52,'resist silence',10,26,4,244,25,NULL,0);
INSERT INTO `traits` VALUES (52,'resist silence',10,32,5,244,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (52,'resist silence',20,4,1,244,10,'WOTG',0);
INSERT INTO `traits` VALUES (52,'resist silence',20,15,2,244,15,'WOTG',0);
INSERT INTO `traits` VALUES (52,'resist silence',20,26,3,244,20,'WOTG',0);
INSERT INTO `traits` VALUES (52,'resist silence',20,30,4,244,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (53,'resist petrify',5,4,1,246,10,NULL,0);
INSERT INTO `traits` VALUES (53,'resist petrify',5,12,2,246,15,NULL,0);
INSERT INTO `traits` VALUES (53,'resist petrify',5,19,3,246,20,NULL,0);
INSERT INTO `traits` VALUES (53,'resist petrify',5,27,4,246,25,NULL,0);
INSERT INTO `traits` VALUES (53,'resist petrify',5,31,5,246,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (54,'resist virus',1,2,1,245,10,NULL,0);
INSERT INTO `traits` VALUES (54,'resist virus',1,13,2,245,15,NULL,0);
INSERT INTO `traits` VALUES (54,'resist virus',1,21,3,245,20,NULL,0);
INSERT INTO `traits` VALUES (54,'resist virus',1,26,4,245,25,NULL,0);
INSERT INTO `traits` VALUES (54,'resist virus',1,30,5,245,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (57,'resist bind',13,4,1,247,10,NULL,0);
INSERT INTO `traits` VALUES (57,'resist bind',13,12,2,247,15,NULL,0);
INSERT INTO `traits` VALUES (57,'resist bind',13,19,3,247,20,NULL,0);
INSERT INTO `traits` VALUES (57,'resist bind',13,26,4,247,25,NULL,0);
INSERT INTO `traits` VALUES (57,'resist bind',13,34,5,247,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (58,'resist gravity',6,8,1,249,10,NULL,0);
INSERT INTO `traits` VALUES (58,'resist gravity',6,15,2,249,15,NULL,0);
INSERT INTO `traits` VALUES (58,'resist gravity',6,25,3,249,20,NULL,0);
INSERT INTO `traits` VALUES (58,'resist gravity',6,28,4,249,25,NULL,0);
INSERT INTO `traits` VALUES (58,'resist gravity',6,31,5,249,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (59,'resist slow',9,6,1,250,10,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',9,14,2,250,15,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',9,21,3,250,20,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',9,28,4,250,25,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',9,31,5,250,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (59,'resist slow',15,8,1,250,10,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',15,16,2,250,15,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',15,23,3,250,20,NULL,0);
INSERT INTO `traits` VALUES (59,'resist slow',15,31,4,250,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (59,'resist slow',18,4,1,250,10,'TOAU',0);
INSERT INTO `traits` VALUES (59,'resist slow',18,19,2,250,15,'TOAU',0);
INSERT INTO `traits` VALUES (59,'resist slow',18,27,3,250,20,'TOAU',0);
INSERT INTO `traits` VALUES (59,'resist slow',18,31,4,250,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (59,'resist slow',19,8,1,250,10,'WOTG',0);
INSERT INTO `traits` VALUES (59,'resist slow',19,21,2,250,15,'WOTG',0);
INSERT INTO `traits` VALUES (59,'resist slow',19,30,3,250,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',9,6,1,253,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',9,14,2,253,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',9,21,3,253,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',9,28,4,253,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',9,36,5,253,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',17,12,1,253,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',17,20,2,253,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',17,27,3,253,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',17,35,4,253,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',18,6,1,253,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',18,14,2,253,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',18,21,3,253,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',18,28,4,253,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (63,'resist amnesia',18,36,5,253,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (64,'treasure hunter ii',6,17,2,303,1,NULL,0);
INSERT INTO `traits` VALUES (65,'treasure hunter iii',6,34,3,303,1,'ABYSSEA',0);
INSERT INTO `traits` VALUES (66,'kick attacks',2,20,1,292,10,'ROTZ',0);
INSERT INTO `traits` VALUES (66,'kick attacks',2,27,2,292,12,'ROTZ',0);
INSERT INTO `traits` VALUES (66,'kick attacks',2,29,3,292,14,'ABYSSEA',0);
INSERT INTO `traits` VALUES (67,'subtle blow',2,3,1,289,5,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',2,10,2,289,10,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',2,16,3,289,15,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',2,25,4,289,20,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',2,35,5,289,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (67,'subtle blow',13,6,1,289,5,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',13,12,2,289,10,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',13,17,3,289,15,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',13,23,4,289,20,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',13,28,5,289,25,'ROTZ',0);
INSERT INTO `traits` VALUES (67,'subtle blow',13,34,6,289,27,'ABYSSEA',0);
INSERT INTO `traits` VALUES (67,'subtle blow',19,10,1,289,5,'WOTG',0);
INSERT INTO `traits` VALUES (67,'subtle blow',19,17,2,289,10,'WOTG',0);
INSERT INTO `traits` VALUES (67,'subtle blow',19,25,3,289,15,'WOTG',0);
INSERT INTO `traits` VALUES (67,'subtle blow',19,32,4,289,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (68,'assassin',6,23,1,0,0,'COP',0);
INSERT INTO `traits` VALUES (69,'divine veil',3,20,1,0,0,'COP',0);
INSERT INTO `traits` VALUES (70,'zanshin',12,8,1,306,15,'COP',0);
INSERT INTO `traits` VALUES (70,'zanshin',12,14,2,306,25,'COP',0);
INSERT INTO `traits` VALUES (70,'zanshin',12,19,3,306,35,'COP',0);
INSERT INTO `traits` VALUES (70,'zanshin',12,28,4,306,45,'COP',0);
INSERT INTO `traits` VALUES (70,'zanshin',12,36,5,306,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (71,'savagery',1,28,1,0,0,'TOAU',2052);
INSERT INTO `traits` VALUES (72,'aggressive aim',1,28,1,0,0,'TOAU',2054);
INSERT INTO `traits` VALUES (73,'invigorate',2,29,1,0,24,'TOAU',2116);
INSERT INTO `traits` VALUES (74,'penance',2,29,1,0,0,'TOAU',2118);
INSERT INTO `traits` VALUES (75,'aura steal',6,28,1,0,0,'TOAU',2372);
INSERT INTO `traits` VALUES (76,'ambush',6,28,1,0,0,'TOAU',2374);
INSERT INTO `traits` VALUES (77,'iron will',7,29,1,0,0,'TOAU',2436);
INSERT INTO `traits` VALUES (78,'guardian',7,29,1,0,0,'TOAU',2438);
INSERT INTO `traits` VALUES (79,'muted soul',8,28,1,0,0,'TOAU',2500);
INSERT INTO `traits` VALUES (80,'desperate blows',8,6,1,906,500,'TOAU',0);
INSERT INTO `traits` VALUES (80,'desperate blows',8,12,2,906,1000,'SOA',0);
INSERT INTO `traits` VALUES (80,'desperate blows',8,17,3,906,1500,'SOA',0);
INSERT INTO `traits` VALUES (81,'beast affinity ',9,28,1,0,0,'TOAU',2564);
INSERT INTO `traits` VALUES (82,'beast healer',9,28,1,0,0,'TOAU',2566);
INSERT INTO `traits` VALUES (83,'snapshot',11,28,1,0,0,'TOAU',2692);
INSERT INTO `traits` VALUES (84,'recycle',11,8,1,305,10,'SOA',0);
INSERT INTO `traits` VALUES (84,'recycle',11,13,2,305,20,'SOA',0);
INSERT INTO `traits` VALUES (84,'recycle',11,19,3,305,30,'SOA',0);
INSERT INTO `traits` VALUES (84,'recycle',17,14,1,305,10,'SOA',0);
INSERT INTO `traits` VALUES (84,'recycle',17,26,2,305,20,'SOA',0);
INSERT INTO `traits` VALUES (84,'recycle',17,37,3,305,30,'SOA',0);
INSERT INTO `traits` VALUES (85,'ikishoten',12,28,1,0,0,'TOAU',2756);
INSERT INTO `traits` VALUES (86,'overwhelm',12,28,1,0,0,'TOAU',2758);
INSERT INTO `traits` VALUES (87,'ninja tool expert.',13,28,1,308,0,'TOAU',2818);
INSERT INTO `traits` VALUES (88,'empathy',14,29,1,0,0,'TOAU',2884);
INSERT INTO `traits` VALUES (89,'strafe',14,8,1,986,10,'TOAU',0);
INSERT INTO `traits` VALUES (89,'strafe',14,16,2,986,15,'SOA',0);
INSERT INTO `traits` VALUES (89,'strafe',14,24,3,986,25,'SOA',0);
INSERT INTO `traits` VALUES (89,'strafe',14,31,4,986,30,'SOA',0);
INSERT INTO `traits` VALUES (90,'enchainment',16,37,1,0,0,'TOAU',3012);
INSERT INTO `traits` VALUES (91,'assimilation',16,37,1,0,0,'TOAU',3014);
INSERT INTO `traits` VALUES (92,'winning streak',17,29,1,0,0,'TOAU',3076);
INSERT INTO `traits` VALUES (93,'loaded deck',17,29,1,0,0,'TOAU',3078);
INSERT INTO `traits` VALUES (94,'fine-tuning',18,28,1,0,0,'TOAU',3140);
INSERT INTO `traits` VALUES (95,'optimization',18,28,1,0,0,'TOAU',3142);
INSERT INTO `traits` VALUES (96,'closed position',19,28,1,0,0,'WOTG',3206);
INSERT INTO `traits` VALUES (97,'stormsurge',20,28,1,0,0,'WOTG',3274);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',1,29,1,421,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',1,32,2,421,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',6,30,1,421,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',6,32,2,421,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',6,34,3,421,11,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',6,37,4,421,14,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',8,32,1,421,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',8,36,2,421,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',19,30,1,421,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',19,33,2,421,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (98,'crit. atk. bonus',19,37,3,421,11,'ABYSSEA',0);
INSERT INTO `traits` VALUES (99,'crit. def. bonus',7,33,2,908,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (99,'crit. def. bonus',7,35,3,908,11,'ABYSSEA',0);
INSERT INTO `traits` VALUES (99,'crit. def. bonus',7,37,4,908,14,'ABYSSEA',0);
INSERT INTO `traits` VALUES (99,'crit. def. bonus',10,35,2,908,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (99,'crit. def. bonus',14,37,2,908,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (99,'crit. def. bonus',18,36,2,908,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',8,33,1,486,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',8,37,2,486,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',13,29,1,486,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',13,33,2,486,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',13,36,3,486,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',19,29,1,486,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',19,31,2,486,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',19,34,3,486,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',19,36,4,486,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',22,15,1,486,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',22,23,2,486,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (100,'tactical parry',22,32,3,486,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (101,'tactical guard',2,29,1,899,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (101,'tactical guard',2,33,2,899,45,'ABYSSEA',0);
INSERT INTO `traits` VALUES (101,'tactical guard',2,37,3,899,60,'ABYSSEA',0);
INSERT INTO `traits` VALUES (101,'tactical guard',18,30,1,899,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (101,'tactical guard',18,34,2,899,45,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',1,30,1,905,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',1,33,2,905,4,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',1,37,3,905,6,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',3,33,1,905,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',3,37,2,905,4,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',7,30,1,905,2,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',7,32,2,905,4,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',7,34,3,905,6,'ABYSSEA',0);
INSERT INTO `traits` VALUES (102,'shield def. bonus',7,36,4,905,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',9,30,1,0,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',9,33,2,0,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',9,37,3,0,9,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',15,33,1,0,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',15,37,2,0,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',18,30,1,0,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',18,33,2,0,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (103,'stout servant',18,37,3,0,9,'ABYSSEA',0);
INSERT INTO `traits` VALUES (105,'blood boon',15,23,1,913,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (105,'blood boon',15,27,2,913,23,'ABYSSEA',0);
INSERT INTO `traits` VALUES (105,'blood boon',15,31,3,913,26,'ABYSSEA',0);
INSERT INTO `traits` VALUES (105,'blood boon',15,35,4,913,29,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',2,33,1,174,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',2,36,2,174,12,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',12,30,1,174,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',12,33,2,174,12,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',12,37,3,174,16,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',13,32,1,174,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',13,36,2,174,12,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',19,17,1,174,8,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',19,22,2,174,12,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',19,27,3,174,16,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',19,31,4,174,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (106,'skillchain bonus',19,36,4,174,23,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,17,1,903,200,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,17,1,904,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,22,2,903,300,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,22,2,904,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,27,3,903,400,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,27,3,904,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,31,4,903,450,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,31,4,904,9,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,36,5,903,500,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',1,36,5,904,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',9,30,1,903,200,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',9,30,1,904,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',9,33,2,903,300,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',9,33,2,904,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',9,36,3,903,400,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',9,36,3,904,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',10,33,1,903,200,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',10,33,1,904,3,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',10,37,2,903,300,'ABYSSEA',0);
INSERT INTO `traits` VALUES (107,'fencer',10,37,2,904,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',4,33,1,902,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',4,36,2,902,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',8,17,1,902,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',8,22,2,902,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',8,27,3,902,75,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',8,31,4,902,100,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',8,36,5,902,125,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',20,29,1,902,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',20,33,2,902,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (109,'occult acumen',20,37,3,902,75,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',4,17,1,274,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',4,22,2,274,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',4,27,3,274,9,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',4,32,4,274,11,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',4,37,5,274,13,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',5,33,1,274,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',5,36,2,274,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',13,30,1,274,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',13,34,2,274,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',20,30,1,274,5,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',20,33,2,274,7,'ABYSSEA',0);
INSERT INTO `traits` VALUES (110,'mag. burst bonus',20,37,3,274,9,'ABYSSEA',0);
INSERT INTO `traits` VALUES (111,'divine benison',3,20,1,910,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (111,'divine benison',3,23,2,910,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (111,'divine benison',3,27,3,910,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (111,'divine benison',3,31,4,910,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (111,'divine benison',3,35,5,910,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (112,'elemental celerity',4,19,1,901,10,'ABYSSEA',0);
INSERT INTO `traits` VALUES (112,'elemental celerity',4,23,2,901,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (112,'elemental celerity',4,27,3,901,20,'ABYSSEA',0);
INSERT INTO `traits` VALUES (112,'elemental celerity',4,31,4,901,25,'ABYSSEA',0);
INSERT INTO `traits` VALUES (112,'elemental celerity',4,34,5,901,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (112,'elemental celerity',21,21,1,901,10,'SOA',0);
INSERT INTO `traits` VALUES (113,'dead aim',11,19,1,964,10,'SOA',0);
INSERT INTO `traits` VALUES (113,'dead aim',11,23,2,964,20,'SOA',0);
INSERT INTO `traits` VALUES (113,'dead aim',11,26,3,964,30,'SOA',0);
INSERT INTO `traits` VALUES (113,'dead aim',11,30,4,964,35,'SOA',0);
INSERT INTO `traits` VALUES (113,'dead aim',11,34,5,964,40,'SOA',0);
INSERT INTO `traits` VALUES (113,'dead aim',11,37,6,964,45,'SOA',0);
INSERT INTO `traits` VALUES (114,'tranquil heart',3,9,1,0,0,'ABYSSEA',0);
INSERT INTO `traits` VALUES (114,'tranquil heart',5,10,1,0,0,'ABYSSEA',0);
INSERT INTO `traits` VALUES (114,'tranquil heart',20,12,1,0,0,'ABYSSEA',0);
INSERT INTO `traits` VALUES (115,'stalwart soul',8,17,1,907,15,'ABYSSEA',0);
INSERT INTO `traits` VALUES (115,'stalwart soul',8,23,2,907,30,'ABYSSEA',0);
INSERT INTO `traits` VALUES (115,'stalwart soul',8,28,3,907,40,'ABYSSEA',0);
INSERT INTO `traits` VALUES (115,'stalwart soul',8,34,4,907,50,'ABYSSEA',0);
INSERT INTO `traits` VALUES (116,'cardinal chant',21,10,1,959,1,'SOA',0);
INSERT INTO `traits` VALUES (116,'cardinal chant',21,17,2,959,2,'SOA',0);
INSERT INTO `traits` VALUES (116,'cardinal chant',21,25,3,959,3,'SOA',0);
INSERT INTO `traits` VALUES (116,'cardinal chant',21,32,4,959,4,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,240,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,241,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,242,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,243,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,244,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,245,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,246,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,247,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,2,1,248,5,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,240,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,241,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,242,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,243,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,244,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,245,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,246,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,247,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,10,2,248,7,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,240,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,241,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,242,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,243,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,244,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,245,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,246,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,247,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,17,3,248,9,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,240,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,241,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,242,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,243,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,244,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,245,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,246,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,247,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,28,4,248,11,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,240,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,241,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,242,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,243,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,244,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,245,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,246,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,247,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,30,5,248,13,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,240,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,241,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,242,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,243,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,244,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,245,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,246,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,247,15,'SOA',0);
INSERT INTO `traits` VALUES (117,'tenacity',22,36,6,248,15,'SOA',0);
INSERT INTO `traits` VALUES (118,'inquartata',22,6,1,963,5,'SOA',0);
INSERT INTO `traits` VALUES (118,'inquartata',22,17,2,963,7,'SOA',0);
INSERT INTO `traits` VALUES (118,'inquartata',22,28,3,963,9,'SOA',0);
INSERT INTO `traits` VALUES (118,'inquartata',22,34,4,963,11,'SOA',0);
INSERT INTO `traits` VALUES (119,'curative recantation',21,28,1,970,0,'SOA',3396);
INSERT INTO `traits` VALUES (120,'primeval zeal',21,28,1,971,0,'SOA',3398);
INSERT INTO `traits` VALUES (123,'daken',13,10,1,911,20,'SOA',0);
INSERT INTO `traits` VALUES (123,'daken',13,15,2,911,25,'SOA',0);
INSERT INTO `traits` VALUES (123,'daken',13,21,3,911,30,'SOA',0);
INSERT INTO `traits` VALUES (123,'daken',13,26,4,911,35,'SOA',0);
INSERT INTO `traits` VALUES (123,'daken',13,36,5,911,40,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',1,13,1,898,25,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',1,25,2,898,38,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',1,36,3,898,51,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',2,16,1,898,25,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',2,31,2,898,38,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',8,6,1,898,25,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',8,13,2,898,38,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',8,21,3,898,51,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',8,28,4,898,64,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',8,36,5,898,76,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',14,16,1,898,25,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',14,31,2,898,38,'SOA',0);
INSERT INTO `traits` VALUES (127,'smite',18,23,1,898,25,'SOA',0);
INSERT INTO `traits` VALUES (129,'damage limit+',1,15,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',1,30,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',2,12,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',2,23,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',2,34,3,1080,30,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',5,23,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',6,19,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',8,8,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',8,15,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',8,21,3,1080,30,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',8,26,4,1080,40,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',8,30,5,1080,50,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',9,17,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',9,34,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',11,12,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',11,23,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',11,34,3,1080,30,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',12,15,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',12,30,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',13,19,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',14,12,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',14,24,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',14,35,3,1080,30,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',18,17,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',18,34,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',19,17,1,1080,10,'ROV',0);
INSERT INTO `traits` VALUES (129,'damage limit+',19,34,2,1080,20,'ROV',0);
INSERT INTO `traits` VALUES (134,'ws damage boost',14,18,1,840,7,'ROV',0);
INSERT INTO `traits` VALUES (134,'ws damage boost',14,22,2,840,10,'ROV',0);
INSERT INTO `traits` VALUES (134,'ws damage boost',14,26,3,840,13,'ROV',0);
INSERT INTO `traits` VALUES (134,'ws damage boost',14,29,4,840,16,'ROV',0);
INSERT INTO `traits` VALUES (134,'ws damage boost',14,33,5,840,19,'ROV',0);
INSERT INTO `traits` VALUES (134,'ws damage boost',14,37,6,840,21,'ROV',0);
INSERT INTO `traits` VALUES (135,'max hp boost II',2,29,1,1095,150,'ROV',0);
INSERT INTO `traits` VALUES (135,'max hp boost II',2,33,2,1095,300,'ROV',0);
INSERT INTO `traits` VALUES (135,'max hp boost II',2,36,3,1095,450,'ROV',0);
INSERT INTO `traits` VALUES (136,'shield barrier',7,27,1,1082,1,'ROV',0);
INSERT INTO `traits` VALUES (137,'tandem strike',9,12,1,271,10,'ROV',0);
INSERT INTO `traits` VALUES (137,'tandem strike',9,17,2,271,20,'ROV',0);
INSERT INTO `traits` VALUES (137,'tandem strike',9,23,3,271,30,'ROV',0);
INSERT INTO `traits` VALUES (137,'tandem strike',9,28,4,271,40,'ROV',0);
INSERT INTO `traits` VALUES (137,'tandem strike',9,34,5,271,50,'ROV',0);
INSERT INTO `traits` VALUES (138,'tandem blow',9,15,1,272,5,'ROV',0);
INSERT INTO `traits` VALUES (138,'tandem blow',9,23,2,272,10,'ROV',0);
INSERT INTO `traits` VALUES (138,'tandem blow',9,30,3,272,15,'ROV',0);

-- Magic spell job-level remaps (groups 1-7; trusts skipped)
UPDATE `spell_list` SET `jobs` = 0x00000100020001000000000000000000000000020000 WHERE `spellid` = 1; -- cure
UPDATE `spell_list` SET `jobs` = 0x00000600080007000000000000000000000000060000 WHERE `spellid` = 2; -- cure_ii
UPDATE `spell_list` SET `jobs` = 0x00000C000E000B0000000000000000000000000D0000 WHERE `spellid` = 3; -- cure_iii
UPDATE `spell_list` SET `jobs` = 0x000015001800150000000000000000000000001B0000 WHERE `spellid` = 4; -- cure_iv
UPDATE `spell_list` SET `jobs` = 0x00001E00000000000000000000000000000000000000 WHERE `spellid` = 5; -- cure_v
UPDATE `spell_list` SET `jobs` = 0x00001E00000000000000000000000000000000000000 WHERE `spellid` = 6; -- cure_vi
UPDATE `spell_list` SET `jobs` = 0x00000900000000000000000000000000000000000000 WHERE `spellid` = 7; -- curaga
UPDATE `spell_list` SET `jobs` = 0x00001000000000000000000000000000000000000000 WHERE `spellid` = 8; -- curaga_ii
UPDATE `spell_list` SET `jobs` = 0x00001A00000000000000000000000000000000000000 WHERE `spellid` = 9; -- curaga_iii
UPDATE `spell_list` SET `jobs` = 0x00002300000000000000000000000000000000000000 WHERE `spellid` = 10; -- curaga_iv
UPDATE `spell_list` SET `jobs` = 0x00002200000000000000000000000000000000000000 WHERE `spellid` = 11; -- curaga_v
UPDATE `spell_list` SET `jobs` = 0x00000D001400130000000000000000000000000F0000 WHERE `spellid` = 12; -- raise
UPDATE `spell_list` SET `jobs` = 0x00001B00240000000000000000000000000000220000 WHERE `spellid` = 13; -- raise_ii
UPDATE `spell_list` SET `jobs` = 0x00000300000000000000000000000000000000030000 WHERE `spellid` = 14; -- poisona
UPDATE `spell_list` SET `jobs` = 0x00000500000000000000000000000000000000040000 WHERE `spellid` = 15; -- paralyna
UPDATE `spell_list` SET `jobs` = 0x00000800000000000000000000000000000000060000 WHERE `spellid` = 16; -- blindna
UPDATE `spell_list` SET `jobs` = 0x00000B00000000000000000000000000000000090000 WHERE `spellid` = 17; -- silena
UPDATE `spell_list` SET `jobs` = 0x00001400000000000000000000000000000000190000 WHERE `spellid` = 18; -- stona
UPDATE `spell_list` SET `jobs` = 0x00001100000000000000000000000000000000170000 WHERE `spellid` = 19; -- viruna
UPDATE `spell_list` SET `jobs` = 0x00000F000000000000000000000000000000000E0000 WHERE `spellid` = 20; -- cursna
UPDATE `spell_list` SET `jobs` = 0x00001900000015000000000000000000000000000000 WHERE `spellid` = 21; -- holy
UPDATE `spell_list` SET `jobs` = 0x00002400000025000000000000000000000000000000 WHERE `spellid` = 22; -- holy_ii
UPDATE `spell_list` SET `jobs` = 0x00000200010000000000000000000000000000000000 WHERE `spellid` = 23; -- dia
UPDATE `spell_list` SET `jobs` = 0x00001200100000000000000000000000000000000000 WHERE `spellid` = 24; -- dia_ii
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 25; -- dia_iii
UPDATE `spell_list` SET `jobs` = 0x00000300000003000000000000000000000000000000 WHERE `spellid` = 28; -- banish
UPDATE `spell_list` SET `jobs` = 0x00000F0000000D000000000000000000000000000000 WHERE `spellid` = 29; -- banish_ii
UPDATE `spell_list` SET `jobs` = 0x00002000000000000000000000000000000000000000 WHERE `spellid` = 30; -- banish_iii
UPDATE `spell_list` SET `jobs` = 0x00000A00080000000000000000000000000000000000 WHERE `spellid` = 33; -- diaga
UPDATE `spell_list` SET `jobs` = 0x00000A00080000000000000000000000000000000000 WHERE `spellid` = 34; -- diaga_ii
UPDATE `spell_list` SET `jobs` = 0x0000080000000B000000000000000000000000000000 WHERE `spellid` = 38; -- banishga
UPDATE `spell_list` SET `jobs` = 0x00001400000000000000000000000000000000000000 WHERE `spellid` = 39; -- banishga_ii
UPDATE `spell_list` SET `jobs` = 0x0000040004000500000000000000000000000003000C WHERE `spellid` = 43; -- protect
UPDATE `spell_list` SET `jobs` = 0x00000E000F000B0000000000000000000000000D0014 WHERE `spellid` = 44; -- protect_ii
UPDATE `spell_list` SET `jobs` = 0x0000180018001300000000000000000000000019001C WHERE `spellid` = 45; -- protect_iii
UPDATE `spell_list` SET `jobs` = 0x00001F001F002300000000000000000000000020001D WHERE `spellid` = 46; -- protect_iv
UPDATE `spell_list` SET `jobs` = 0x00001D001D00210000000000000000000000001E0000 WHERE `spellid` = 47; -- protect_v
UPDATE `spell_list` SET `jobs` = 0x00000900090009000000000000000000000000080005 WHERE `spellid` = 48; -- shell
UPDATE `spell_list` SET `jobs` = 0x00001200130011000000000000000000000000130011 WHERE `spellid` = 49; -- shell_ii
UPDATE `spell_list` SET `jobs` = 0x00001C001C00190000000000000000000000001D0019 WHERE `spellid` = 50; -- shell_iii
UPDATE `spell_list` SET `jobs` = 0x0000210022001B000000000000000000000000220024 WHERE `spellid` = 51; -- shell_iv
UPDATE `spell_list` SET `jobs` = 0x00001D00210000000000000000000000000000210023 WHERE `spellid` = 52; -- shell_v
UPDATE `spell_list` SET `jobs` = 0x00000B000C00000000000000000000000000000D0012 WHERE `spellid` = 53; -- blink
UPDATE `spell_list` SET `jobs` = 0x00000E0011000000000000000000000000000015001A WHERE `spellid` = 54; -- stoneskin
UPDATE `spell_list` SET `jobs` = 0x00000500060000000000000000000000000000040009 WHERE `spellid` = 55; -- aquaveil
UPDATE `spell_list` SET `jobs` = 0x00000700070000000000000000000000000000000000 WHERE `spellid` = 56; -- slow
UPDATE `spell_list` SET `jobs` = 0x00001400180000000000000000000000000000000000 WHERE `spellid` = 57; -- haste
UPDATE `spell_list` SET `jobs` = 0x00000200030000000000000000000000000000000000 WHERE `spellid` = 58; -- paralyze
UPDATE `spell_list` SET `jobs` = 0x000008000A0000000000000000000000000000000000 WHERE `spellid` = 59; -- silence
UPDATE `spell_list` SET `jobs` = 0x0000000009000000000000000000000000000000000A WHERE `spellid` = 60; -- barfire
UPDATE `spell_list` SET `jobs` = 0x000000000B000000000000000000000000000000000C WHERE `spellid` = 61; -- barblizzard
UPDATE `spell_list` SET `jobs` = 0x00000000070000000000000000000000000000000008 WHERE `spellid` = 62; -- baraero
UPDATE `spell_list` SET `jobs` = 0x00000000030000000000000000000000000000000001 WHERE `spellid` = 63; -- barstone
UPDATE `spell_list` SET `jobs` = 0x000000000E0000000000000000000000000000000010 WHERE `spellid` = 64; -- barthunder
UPDATE `spell_list` SET `jobs` = 0x00000000050000000000000000000000000000000003 WHERE `spellid` = 65; -- barwater
UPDATE `spell_list` SET `jobs` = 0x00000900000000000000000000000000000000000000 WHERE `spellid` = 66; -- barfira
UPDATE `spell_list` SET `jobs` = 0x00000C00000000000000000000000000000000000000 WHERE `spellid` = 67; -- barblizzara
UPDATE `spell_list` SET `jobs` = 0x00000700000000000000000000000000000000000000 WHERE `spellid` = 68; -- baraera
UPDATE `spell_list` SET `jobs` = 0x00000300000000000000000000000000000000000000 WHERE `spellid` = 69; -- barstonra
UPDATE `spell_list` SET `jobs` = 0x00000D00000000000000000000000000000000000000 WHERE `spellid` = 70; -- barthundra
UPDATE `spell_list` SET `jobs` = 0x00000500000000000000000000000000000000000000 WHERE `spellid` = 71; -- barwatera
UPDATE `spell_list` SET `jobs` = 0x00000000040000000000000000000000000000000002 WHERE `spellid` = 72; -- barsleep
UPDATE `spell_list` SET `jobs` = 0x00000000050000000000000000000000000000000004 WHERE `spellid` = 73; -- barpoison
UPDATE `spell_list` SET `jobs` = 0x00000000060000000000000000000000000000000007 WHERE `spellid` = 74; -- barparalyze
UPDATE `spell_list` SET `jobs` = 0x000000000A000000000000000000000000000000000B WHERE `spellid` = 75; -- barblind
UPDATE `spell_list` SET `jobs` = 0x000000000C000000000000000000000000000000000D WHERE `spellid` = 76; -- barsilence
UPDATE `spell_list` SET `jobs` = 0x00000000160000000000000000000000000000000015 WHERE `spellid` = 77; -- barpetrify
UPDATE `spell_list` SET `jobs` = 0x00000000140000000000000000000000000000000013 WHERE `spellid` = 78; -- barvirus
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 79; -- slow_ii
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 80; -- paralyze_ii
UPDATE `spell_list` SET `jobs` = 0x00001A00000000000000000000000000000000000000 WHERE `spellid` = 81; -- recall-jugner
UPDATE `spell_list` SET `jobs` = 0x00001A00000000000000000000000000000000000000 WHERE `spellid` = 82; -- recall-pashh
UPDATE `spell_list` SET `jobs` = 0x00001A00000000000000000000000000000000000000 WHERE `spellid` = 83; -- recall-meriph
UPDATE `spell_list` SET `jobs` = 0x000000001D000000000000000000000000000000001B WHERE `spellid` = 84; -- baramnesia
UPDATE `spell_list` SET `jobs` = 0x00001D00000000000000000000000000000000000000 WHERE `spellid` = 85; -- baramnesra
UPDATE `spell_list` SET `jobs` = 0x00000400000000000000000000000000000000000000 WHERE `spellid` = 86; -- barsleepra
UPDATE `spell_list` SET `jobs` = 0x00000500000000000000000000000000000000000000 WHERE `spellid` = 87; -- barpoisonra
UPDATE `spell_list` SET `jobs` = 0x00000600000000000000000000000000000000000000 WHERE `spellid` = 88; -- barparalyzra
UPDATE `spell_list` SET `jobs` = 0x00000A00000000000000000000000000000000000000 WHERE `spellid` = 89; -- barblindra
UPDATE `spell_list` SET `jobs` = 0x00000C00000000000000000000000000000000000000 WHERE `spellid` = 90; -- barsilencera
UPDATE `spell_list` SET `jobs` = 0x00001600000000000000000000000000000000000000 WHERE `spellid` = 91; -- barpetra
UPDATE `spell_list` SET `jobs` = 0x00001400000000000000000000000000000000000000 WHERE `spellid` = 92; -- barvira
UPDATE `spell_list` SET `jobs` = 0x00001400000000000000000000000000000000000000 WHERE `spellid` = 93; -- cura
UPDATE `spell_list` SET `jobs` = 0x00002000000000000000000000000000000000000000 WHERE `spellid` = 94; -- sacrifice
UPDATE `spell_list` SET `jobs` = 0x00001E00000000000000000000000000000000000000 WHERE `spellid` = 95; -- esuna
UPDATE `spell_list` SET `jobs` = 0x00001B00000000000000000000000000000000000000 WHERE `spellid` = 96; -- auspice
UPDATE `spell_list` SET `jobs` = 0x0000000000001B000000000000000000000000000000 WHERE `spellid` = 97; -- reprisal
UPDATE `spell_list` SET `jobs` = 0x00001800000000000000000000000000000000000000 WHERE `spellid` = 98; -- repose
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000130000 WHERE `spellid` = 99; -- sandstorm
UPDATE `spell_list` SET `jobs` = 0x000000000D0000000000000000000000000000000000 WHERE `spellid` = 100; -- enfire
UPDATE `spell_list` SET `jobs` = 0x000000000C0000000000000000000000000000000000 WHERE `spellid` = 101; -- enblizzard
UPDATE `spell_list` SET `jobs` = 0x000000000B0000000000000000000000000000000000 WHERE `spellid` = 102; -- enaero
UPDATE `spell_list` SET `jobs` = 0x000000000A0000000000000000000000000000000000 WHERE `spellid` = 103; -- enstone
UPDATE `spell_list` SET `jobs` = 0x00000000090000000000000000000000000000000000 WHERE `spellid` = 104; -- enthunder
UPDATE `spell_list` SET `jobs` = 0x000000000F0000000000000000000000000000000000 WHERE `spellid` = 105; -- enwater
UPDATE `spell_list` SET `jobs` = 0x00000000110017000000000000000000000000000022 WHERE `spellid` = 106; -- phalanx
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 107; -- phalanx_ii
UPDATE `spell_list` SET `jobs` = 0x00000C000B000000000000000000000000000007000F WHERE `spellid` = 108; -- regen
UPDATE `spell_list` SET `jobs` = 0x0000000015000000000000000000000000000000001E WHERE `spellid` = 109; -- refresh
UPDATE `spell_list` SET `jobs` = 0x000017001C0000000000000000000000000000110017 WHERE `spellid` = 110; -- regen_ii
UPDATE `spell_list` SET `jobs` = 0x000021000000000000000000000000000000001C0024 WHERE `spellid` = 111; -- regen_iii
UPDATE `spell_list` SET `jobs` = 0x0000170000000F000000000000000000000000000016 WHERE `spellid` = 112; -- flash
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000140000 WHERE `spellid` = 113; -- rainstorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000150000 WHERE `spellid` = 114; -- windstorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000150000 WHERE `spellid` = 115; -- firestorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000160000 WHERE `spellid` = 116; -- hailstorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000170000 WHERE `spellid` = 117; -- thunderstorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000170000 WHERE `spellid` = 118; -- voidstorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000180000 WHERE `spellid` = 119; -- aurorastorm
UPDATE `spell_list` SET `jobs` = 0x00001300000000000000000000000000000000000000 WHERE `spellid` = 120; -- teleport-yhoat
UPDATE `spell_list` SET `jobs` = 0x00001300000000000000000000000000000000000000 WHERE `spellid` = 121; -- teleport-altep
UPDATE `spell_list` SET `jobs` = 0x00001200000000000000000000000000000000000000 WHERE `spellid` = 122; -- teleport-holla
UPDATE `spell_list` SET `jobs` = 0x00001200000000000000000000000000000000000000 WHERE `spellid` = 123; -- teleport-dem
UPDATE `spell_list` SET `jobs` = 0x00001200000000000000000000000000000000000000 WHERE `spellid` = 124; -- teleport-mea
UPDATE `spell_list` SET `jobs` = 0x00000400000000000000000000000000000000000000 WHERE `spellid` = 125; -- protectra
UPDATE `spell_list` SET `jobs` = 0x00000E00000000000000000000000000000000000000 WHERE `spellid` = 126; -- protectra_ii
UPDATE `spell_list` SET `jobs` = 0x00001800000000000000000000000000000000000000 WHERE `spellid` = 127; -- protectra_iii
UPDATE `spell_list` SET `jobs` = 0x00001F00000000000000000000000000000000000000 WHERE `spellid` = 128; -- protectra_iv
UPDATE `spell_list` SET `jobs` = 0x00002500000000000000000000000000000000000000 WHERE `spellid` = 129; -- protectra_v
UPDATE `spell_list` SET `jobs` = 0x00000900000000000000000000000000000000000000 WHERE `spellid` = 130; -- shellra
UPDATE `spell_list` SET `jobs` = 0x00001200000000000000000000000000000000000000 WHERE `spellid` = 131; -- shellra_ii
UPDATE `spell_list` SET `jobs` = 0x00001C00000000000000000000000000000000000000 WHERE `spellid` = 132; -- shellra_iii
UPDATE `spell_list` SET `jobs` = 0x00002100000000000000000000000000000000000000 WHERE `spellid` = 133; -- shellra_iv
UPDATE `spell_list` SET `jobs` = 0x00002500000000000000000000000000000000000000 WHERE `spellid` = 134; -- shellra_v
UPDATE `spell_list` SET `jobs` = 0x00000D000000000000000000000000000000000F0000 WHERE `spellid` = 135; -- reraise
UPDATE `spell_list` SET `jobs` = 0x00000D000E00000000000000000000000000000B0000 WHERE `spellid` = 136; -- invisible
UPDATE `spell_list` SET `jobs` = 0x00000B000B0000000000000000000000000000080000 WHERE `spellid` = 137; -- sneak
UPDATE `spell_list` SET `jobs` = 0x00000800080000000000000000000000000000050000 WHERE `spellid` = 138; -- deodorize
UPDATE `spell_list` SET `jobs` = 0x00001500000000000000000000000000000000000000 WHERE `spellid` = 139; -- teleport-vahzl
UPDATE `spell_list` SET `jobs` = 0x00002300000000000000000000000000000000210000 WHERE `spellid` = 140; -- raise_iii
UPDATE `spell_list` SET `jobs` = 0x00001B00000000000000000000000000000000220000 WHERE `spellid` = 141; -- reraise_ii
UPDATE `spell_list` SET `jobs` = 0x00002300000000000000000000000000000000210000 WHERE `spellid` = 142; -- reraise_iii
UPDATE `spell_list` SET `jobs` = 0x00001100000000000000000000000000000000120000 WHERE `spellid` = 143; -- erase
UPDATE `spell_list` SET `jobs` = 0x000000050A0000070000000000000000000000060700 WHERE `spellid` = 144; -- fire
UPDATE `spell_list` SET `jobs` = 0x000000121900001A0000000000000000000000141600 WHERE `spellid` = 145; -- fire_ii
UPDATE `spell_list` SET `jobs` = 0x0000001E2300001F00000000000000000000001E2000 WHERE `spellid` = 146; -- fire_iii
UPDATE `spell_list` SET `jobs` = 0x00000024210000000000000000000000000000241E00 WHERE `spellid` = 147; -- fire_iv
UPDATE `spell_list` SET `jobs` = 0x00000020000000000000000000000000000000210000 WHERE `spellid` = 148; -- fire_v
UPDATE `spell_list` SET `jobs` = 0x000000070D0000090000000000000000000000080900 WHERE `spellid` = 149; -- blizzard
UPDATE `spell_list` SET `jobs` = 0x000000141B00001F0000000000000000000000171800 WHERE `spellid` = 150; -- blizzard_ii
UPDATE `spell_list` SET `jobs` = 0x0000001F240000210000000000000000000000202200 WHERE `spellid` = 151; -- blizzard_iii
UPDATE `spell_list` SET `jobs` = 0x00000024220000000000000000000000000000242000 WHERE `spellid` = 152; -- blizzard_iv
UPDATE `spell_list` SET `jobs` = 0x00000021000000000000000000000000000000230000 WHERE `spellid` = 153; -- blizzard_v
UPDATE `spell_list` SET `jobs` = 0x00000004080000060000000000000000000000040500 WHERE `spellid` = 154; -- aero
UPDATE `spell_list` SET `jobs` = 0x00000010170000170000000000000000000000111300 WHERE `spellid` = 155; -- aero_ii
UPDATE `spell_list` SET `jobs` = 0x0000001C2200001D00000000000000000000001D1E00 WHERE `spellid` = 156; -- aero_iii
UPDATE `spell_list` SET `jobs` = 0x000000231F0000000000000000000000000000231D00 WHERE `spellid` = 157; -- aero_iv
UPDATE `spell_list` SET `jobs` = 0x0000001E000000000000000000000000000000200000 WHERE `spellid` = 158; -- aero_v
UPDATE `spell_list` SET `jobs` = 0x00000001020000010000000000000000000000010200 WHERE `spellid` = 159; -- stone
UPDATE `spell_list` SET `jobs` = 0x0000000C1200001300000000000000000000000D0E00 WHERE `spellid` = 160; -- stone_ii
UPDATE `spell_list` SET `jobs` = 0x000000172000001900000000000000000000001A1A00 WHERE `spellid` = 161; -- stone_iii
UPDATE `spell_list` SET `jobs` = 0x000000211D0000000000000000000000000000221A00 WHERE `spellid` = 162; -- stone_iv
UPDATE `spell_list` SET `jobs` = 0x0000001C0000000000000000000000000000001D0000 WHERE `spellid` = 163; -- stone_v
UPDATE `spell_list` SET `jobs` = 0x000000090F00000E00000000000000000000000A0C00 WHERE `spellid` = 164; -- thunder
UPDATE `spell_list` SET `jobs` = 0x000000161D0000230000000000000000000000191900 WHERE `spellid` = 165; -- thunder_ii
UPDATE `spell_list` SET `jobs` = 0x00000020250000240000000000000000000000212400 WHERE `spellid` = 166; -- thunder_iii
UPDATE `spell_list` SET `jobs` = 0x00000025230000000000000000000000000000252100 WHERE `spellid` = 167; -- thunder_iv
UPDATE `spell_list` SET `jobs` = 0x00000022000000000000000000000000000000250000 WHERE `spellid` = 168; -- thunder_v
UPDATE `spell_list` SET `jobs` = 0x00000003050000040000000000000000000000020400 WHERE `spellid` = 169; -- water
UPDATE `spell_list` SET `jobs` = 0x0000000F1500001600000000000000000000000F1100 WHERE `spellid` = 170; -- water_ii
UPDATE `spell_list` SET `jobs` = 0x0000001A2100001B00000000000000000000001B1C00 WHERE `spellid` = 171; -- water_iii
UPDATE `spell_list` SET `jobs` = 0x000000221E0000000000000000000000000000221B00 WHERE `spellid` = 172; -- water_iv
UPDATE `spell_list` SET `jobs` = 0x0000001D0000000000000000000000000000001E0000 WHERE `spellid` = 173; -- water_v
UPDATE `spell_list` SET `jobs` = 0x0000000D000000000000000000000000000000000000 WHERE `spellid` = 174; -- firaga
UPDATE `spell_list` SET `jobs` = 0x00000019000000000000000000000000000000000000 WHERE `spellid` = 175; -- firaga_ii
UPDATE `spell_list` SET `jobs` = 0x00000022000000000000000000000000000000000000 WHERE `spellid` = 176; -- firaga_iii
UPDATE `spell_list` SET `jobs` = 0x00000010000000000000000000000000000000000000 WHERE `spellid` = 179; -- blizzaga
UPDATE `spell_list` SET `jobs` = 0x0000001B000000000000000000000000000000000000 WHERE `spellid` = 180; -- blizzaga_ii
UPDATE `spell_list` SET `jobs` = 0x00000023000000000000000000000000000000000000 WHERE `spellid` = 181; -- blizzaga_iii
UPDATE `spell_list` SET `jobs` = 0x0000000B000000000000000000000000000000000000 WHERE `spellid` = 184; -- aeroga
UPDATE `spell_list` SET `jobs` = 0x00000016000000000000000000000000000000000000 WHERE `spellid` = 185; -- aeroga_ii
UPDATE `spell_list` SET `jobs` = 0x00000021000000000000000000000000000000000000 WHERE `spellid` = 186; -- aeroga_iii
UPDATE `spell_list` SET `jobs` = 0x00000006000000000000000000000000000000000000 WHERE `spellid` = 189; -- stonega
UPDATE `spell_list` SET `jobs` = 0x00000012000000000000000000000000000000000000 WHERE `spellid` = 190; -- stonega_ii
UPDATE `spell_list` SET `jobs` = 0x0000001E000000000000000000000000000000000000 WHERE `spellid` = 191; -- stonega_iii
UPDATE `spell_list` SET `jobs` = 0x00000011000000000000000000000000000000000000 WHERE `spellid` = 194; -- thundaga
UPDATE `spell_list` SET `jobs` = 0x0000001D000000000000000000000000000000000000 WHERE `spellid` = 195; -- thundaga_ii
UPDATE `spell_list` SET `jobs` = 0x00000024000000000000000000000000000000000000 WHERE `spellid` = 196; -- thundaga_iii
UPDATE `spell_list` SET `jobs` = 0x00000008000000000000000000000000000000000000 WHERE `spellid` = 199; -- waterga
UPDATE `spell_list` SET `jobs` = 0x00000015000000000000000000000000000000000000 WHERE `spellid` = 200; -- waterga_ii
UPDATE `spell_list` SET `jobs` = 0x0000001F000000000000000000000000000000000000 WHERE `spellid` = 201; -- waterga_iii
UPDATE `spell_list` SET `jobs` = 0x0000001D000000000000000000000000000000000000 WHERE `spellid` = 204; -- flare
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 205; -- flare_ii
UPDATE `spell_list` SET `jobs` = 0x00000017000000000000000000000000000000000000 WHERE `spellid` = 206; -- freeze
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 207; -- freeze_ii
UPDATE `spell_list` SET `jobs` = 0x00000018000000000000000000000000000000000000 WHERE `spellid` = 208; -- tornado
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 209; -- tornado_ii
UPDATE `spell_list` SET `jobs` = 0x00000019000000000000000000000000000000000000 WHERE `spellid` = 210; -- quake
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 211; -- quake_ii
UPDATE `spell_list` SET `jobs` = 0x0000001A000000000000000000000000000000000000 WHERE `spellid` = 212; -- burst
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 213; -- burst_ii
UPDATE `spell_list` SET `jobs` = 0x0000001B000000000000000000000000000000000000 WHERE `spellid` = 214; -- flood
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 215; -- flood_ii
UPDATE `spell_list` SET `jobs` = 0x000000000B0000000000000000000000000000000000 WHERE `spellid` = 216; -- gravity
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 217; -- gravity_ii
UPDATE `spell_list` SET `jobs` = 0x00000025000000000000000000000000000000000000 WHERE `spellid` = 218; -- meteor
UPDATE `spell_list` SET `jobs` = 0x00000023000000000000000000000000000000000000 WHERE `spellid` = 219; -- comet
UPDATE `spell_list` SET `jobs` = 0x00000002030000020000000000000000000000000000 WHERE `spellid` = 220; -- poison
UPDATE `spell_list` SET `jobs` = 0x00000014170000150000000000000000000000000000 WHERE `spellid` = 221; -- poison_ii
UPDATE `spell_list` SET `jobs` = 0x0000000B000000080000000000000000000000000000 WHERE `spellid` = 225; -- poisonga
UPDATE `spell_list` SET `jobs` = 0x0000001F0000001F0000000000000000000000000000 WHERE `spellid` = 226; -- poisonga_ii
UPDATE `spell_list` SET `jobs` = 0x00000004050000050000000000000000000000000000 WHERE `spellid` = 230; -- bio
UPDATE `spell_list` SET `jobs` = 0x00000011120000110000000000000000000000000000 WHERE `spellid` = 231; -- bio_ii
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 232; -- bio_iii
UPDATE `spell_list` SET `jobs` = 0x0000000B000000000000000000000000000000000000 WHERE `spellid` = 235; -- burn
UPDATE `spell_list` SET `jobs` = 0x0000000A000000000000000000000000000000000000 WHERE `spellid` = 236; -- frost
UPDATE `spell_list` SET `jobs` = 0x00000009000000000000000000000000000000000000 WHERE `spellid` = 237; -- choke
UPDATE `spell_list` SET `jobs` = 0x00000008000000000000000000000000000000000000 WHERE `spellid` = 238; -- rasp
UPDATE `spell_list` SET `jobs` = 0x00000007000000000000000000000000000000000000 WHERE `spellid` = 239; -- shock
UPDATE `spell_list` SET `jobs` = 0x0000000D000000000000000000000000000000000000 WHERE `spellid` = 240; -- drown
UPDATE `spell_list` SET `jobs` = 0x0000001A000000000000000000000000000000000000 WHERE `spellid` = 241; -- retrace
UPDATE `spell_list` SET `jobs` = 0x000000000000001B0000000000000000000000000000 WHERE `spellid` = 242; -- absorb-acc
UPDATE `spell_list` SET `jobs` = 0x00000000000000200000000000000000000000000000 WHERE `spellid` = 243; -- absorb-attri
UPDATE `spell_list` SET `jobs` = 0x00000005000000030000000000000000000000080600 WHERE `spellid` = 245; -- drain
UPDATE `spell_list` SET `jobs` = 0x000000000000001C0000000000000000000000000000 WHERE `spellid` = 246; -- drain_ii
UPDATE `spell_list` SET `jobs` = 0x0000000C000000070000000000000000000000100C00 WHERE `spellid` = 247; -- aspir
UPDATE `spell_list` SET `jobs` = 0x0000001E0000001A0000000000000000000000242100 WHERE `spellid` = 248; -- aspir_ii
UPDATE `spell_list` SET `jobs` = 0x000000040B00000000000000000000000000000D0016 WHERE `spellid` = 249; -- blaze_spikes
UPDATE `spell_list` SET `jobs` = 0x0000000915000000000000000000000000000019001F WHERE `spellid` = 250; -- ice_spikes
UPDATE `spell_list` SET `jobs` = 0x0000000F1D000000000000000000000000000022001F WHERE `spellid` = 251; -- shock_spikes
UPDATE `spell_list` SET `jobs` = 0x000000150000000F0000000000000000000000000000 WHERE `spellid` = 252; -- stun
UPDATE `spell_list` SET `jobs` = 0x000000090E00000A00000000000000000000000D0F00 WHERE `spellid` = 253; -- sleep
UPDATE `spell_list` SET `jobs` = 0x00000002040000000000000000000000000000000000 WHERE `spellid` = 254; -- blind
UPDATE `spell_list` SET `jobs` = 0x0000001F210000230000000000000000000000210000 WHERE `spellid` = 255; -- break
UPDATE `spell_list` SET `jobs` = 0x00000009000000000000000000000000000000000000 WHERE `spellid` = 256; -- virus
UPDATE `spell_list` SET `jobs` = 0x00000015000000000000000000000000000000000000 WHERE `spellid` = 257; -- curse
UPDATE `spell_list` SET `jobs` = 0x00000003060000070000000000000000000000000000 WHERE `spellid` = 258; -- bind
UPDATE `spell_list` SET `jobs` = 0x000000131700001800000000000000000000001F2200 WHERE `spellid` = 259; -- sleep_ii
UPDATE `spell_list` SET `jobs` = 0x000000001000000000000000000000000000000E0000 WHERE `spellid` = 260; -- dispel
UPDATE `spell_list` SET `jobs` = 0x00000007000000000000000000000000000000000000 WHERE `spellid` = 261; -- warp
UPDATE `spell_list` SET `jobs` = 0x00000012000000000000000000000000000000000000 WHERE `spellid` = 262; -- warp_ii
UPDATE `spell_list` SET `jobs` = 0x0000000E000000000000000000000000000000000000 WHERE `spellid` = 263; -- escape
UPDATE `spell_list` SET `jobs` = 0x0000000C0000000C0000000000000000000000000000 WHERE `spellid` = 264; -- tractor
UPDATE `spell_list` SET `jobs` = 0x00000000000000130000000000000000000000000000 WHERE `spellid` = 266; -- absorb-str
UPDATE `spell_list` SET `jobs` = 0x00000000000000120000000000000000000000000000 WHERE `spellid` = 267; -- absorb-dex
UPDATE `spell_list` SET `jobs` = 0x000000000000000E0000000000000000000000000000 WHERE `spellid` = 268; -- absorb-vit
UPDATE `spell_list` SET `jobs` = 0x000000000000000F0000000000000000000000000000 WHERE `spellid` = 269; -- absorb-agi
UPDATE `spell_list` SET `jobs` = 0x00000000000000100000000000000000000000000000 WHERE `spellid` = 270; -- absorb-int
UPDATE `spell_list` SET `jobs` = 0x000000000000000B0000000000000000000000000000 WHERE `spellid` = 271; -- absorb-mnd
UPDATE `spell_list` SET `jobs` = 0x000000000000000D0000000000000000000000000000 WHERE `spellid` = 272; -- absorb-chr
UPDATE `spell_list` SET `jobs` = 0x0000000F000000000000000000000000000000000000 WHERE `spellid` = 273; -- sleepga
UPDATE `spell_list` SET `jobs` = 0x0000001A000000000000000000000000000000000000 WHERE `spellid` = 274; -- sleepga_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000140000000000000000000000000000 WHERE `spellid` = 275; -- absorb-tp
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 276; -- blind_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000220000000000000000000000000000 WHERE `spellid` = 277; -- dread_spikes
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000070000 WHERE `spellid` = 278; -- geohelix
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000080000 WHERE `spellid` = 279; -- hydrohelix
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000090000 WHERE `spellid` = 280; -- anemohelix
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000000A0000 WHERE `spellid` = 281; -- pyrohelix
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000000B0000 WHERE `spellid` = 282; -- cryohelix
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000000C0000 WHERE `spellid` = 283; -- ionohelix
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000000D0000 WHERE `spellid` = 284; -- noctohelix
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000000E0000 WHERE `spellid` = 285; -- luminohelix
UPDATE `spell_list` SET `jobs` = 0x000023001F0000000000000000000000000000000000 WHERE `spellid` = 286; -- addle
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000170000 WHERE `spellid` = 287; -- klimaform
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000002500000000000000 WHERE `spellid` = 305; -- odin
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000002500000000000000 WHERE `spellid` = 306; -- alexander
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000001F0000 WHERE `spellid` = 308; -- animus_augeo
UPDATE `spell_list` SET `jobs` = 0x000000000000000000000000000000000000001F0000 WHERE `spellid` = 309; -- animus_minuo
UPDATE `spell_list` SET `jobs` = 0x0000000000001D000000000000000000000000000000 WHERE `spellid` = 310; -- enlight
UPDATE `spell_list` SET `jobs` = 0x000000000000001E0000000000000000000000000000 WHERE `spellid` = 311; -- endark
UPDATE `spell_list` SET `jobs` = 0x000000001C0000000000000000000000000000000000 WHERE `spellid` = 312; -- enfire_ii
UPDATE `spell_list` SET `jobs` = 0x000000001B0000000000000000000000000000000000 WHERE `spellid` = 313; -- enblizzard_ii
UPDATE `spell_list` SET `jobs` = 0x000000001A0000000000000000000000000000000000 WHERE `spellid` = 314; -- enaero_ii
UPDATE `spell_list` SET `jobs` = 0x000000001A0000000000000000000000000000000000 WHERE `spellid` = 315; -- enstone_ii
UPDATE `spell_list` SET `jobs` = 0x00000000190000000000000000000000000000000000 WHERE `spellid` = 316; -- enthunder_ii
UPDATE `spell_list` SET `jobs` = 0x000000001D0000000000000000000000000000000000 WHERE `spellid` = 317; -- enwater_ii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000A000000000000000000 WHERE `spellid` = 318; -- monomi_ichi
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000001A000000000000000000 WHERE `spellid` = 319; -- aisha_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000005000000000000000000 WHERE `spellid` = 320; -- katon_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000014000000000000000000 WHERE `spellid` = 321; -- katon_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000025000000000000000000 WHERE `spellid` = 322; -- katon_san
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000005000000000000000000 WHERE `spellid` = 323; -- hyoton_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000014000000000000000000 WHERE `spellid` = 324; -- hyoton_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000025000000000000000000 WHERE `spellid` = 325; -- hyoton_san
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000005000000000000000000 WHERE `spellid` = 326; -- huton_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000014000000000000000000 WHERE `spellid` = 327; -- huton_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000025000000000000000000 WHERE `spellid` = 328; -- huton_san
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000005000000000000000000 WHERE `spellid` = 329; -- doton_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000014000000000000000000 WHERE `spellid` = 330; -- doton_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000025000000000000000000 WHERE `spellid` = 331; -- doton_san
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000005000000000000000000 WHERE `spellid` = 332; -- raiton_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000014000000000000000000 WHERE `spellid` = 333; -- raiton_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000025000000000000000000 WHERE `spellid` = 334; -- raiton_san
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000005000000000000000000 WHERE `spellid` = 335; -- suiton_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000014000000000000000000 WHERE `spellid` = 336; -- suiton_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000025000000000000000000 WHERE `spellid` = 337; -- suiton_san
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000003000000000000000000 WHERE `spellid` = 338; -- utsusemi_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000012000000000000000000 WHERE `spellid` = 339; -- utsusemi_ni
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000E000000000000000000 WHERE `spellid` = 341; -- jubaku_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000009000000000000000000 WHERE `spellid` = 344; -- hojo_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000018000000000000000000 WHERE `spellid` = 345; -- hojo_ni
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000007000000000000000000 WHERE `spellid` = 347; -- kurayami_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000016000000000000000000 WHERE `spellid` = 348; -- kurayami_ni
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000C000000000000000000 WHERE `spellid` = 350; -- dokumori_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000001000000000000000000 WHERE `spellid` = 353; -- tonko_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000010000000000000000000 WHERE `spellid` = 354; -- tonko_ni
UPDATE `spell_list` SET `jobs` = 0x00002525250000000025000000002500000025250000 WHERE `spellid` = 360; -- dispelga
UPDATE `spell_list` SET `jobs` = 0x00000000000000000003000000000000000000000000 WHERE `spellid` = 368; -- foe_requiem
UPDATE `spell_list` SET `jobs` = 0x00000000000000000007000000000000000000000000 WHERE `spellid` = 369; -- foe_requiem_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000012000000000000000000000000 WHERE `spellid` = 370; -- foe_requiem_iii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000017000000000000000000000000 WHERE `spellid` = 371; -- foe_requiem_iv
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001C000000000000000000000000 WHERE `spellid` = 372; -- foe_requiem_v
UPDATE `spell_list` SET `jobs` = 0x00000000000000000021000000000000000000000000 WHERE `spellid` = 373; -- foe_requiem_vi
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001C000000000000000000000000 WHERE `spellid` = 374; -- foe_requiem_vii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000C000000000000000000000000 WHERE `spellid` = 376; -- horde_lullaby
UPDATE `spell_list` SET `jobs` = 0x00000000000000000022000000000000000000000000 WHERE `spellid` = 377; -- horde_lullaby_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000002000000000000000000000000 WHERE `spellid` = 378; -- armys_paeon
UPDATE `spell_list` SET `jobs` = 0x00000000000000000006000000000000000000000000 WHERE `spellid` = 379; -- armys_paeon_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000011000000000000000000000000 WHERE `spellid` = 380; -- armys_paeon_iii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000016000000000000000000000000 WHERE `spellid` = 381; -- armys_paeon_iv
UPDATE `spell_list` SET `jobs` = 0x00000000000000000020000000000000000000000000 WHERE `spellid` = 382; -- armys_paeon_v
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001D000000000000000000000000 WHERE `spellid` = 383; -- armys_paeon_vi
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000B000000000000000000000000 WHERE `spellid` = 386; -- mages_ballad
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001B000000000000000000000000 WHERE `spellid` = 387; -- mages_ballad_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000020000000000000000000000000 WHERE `spellid` = 388; -- mages_ballad_iii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000009000000000000000000000000 WHERE `spellid` = 390; -- knights_minne_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000014000000000000000000000000 WHERE `spellid` = 391; -- knights_minne_iii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001E000000000000000000000000 WHERE `spellid` = 392; -- knights_minne_iv
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001E000000000000000000000000 WHERE `spellid` = 393; -- knights_minne_v
UPDATE `spell_list` SET `jobs` = 0x00000000000000000002000000000000000000000000 WHERE `spellid` = 394; -- valor_minuet
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000A000000000000000000000000 WHERE `spellid` = 395; -- valor_minuet_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000015000000000000000000000000 WHERE `spellid` = 396; -- valor_minuet_iii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001F000000000000000000000000 WHERE `spellid` = 397; -- valor_minuet_iv
UPDATE `spell_list` SET `jobs` = 0x00000000000000000020000000000000000000000000 WHERE `spellid` = 398; -- valor_minuet_v
UPDATE `spell_list` SET `jobs` = 0x00000000000000000004000000000000000000000000 WHERE `spellid` = 399; -- sword_madrigal
UPDATE `spell_list` SET `jobs` = 0x00000000000000000019000000000000000000000000 WHERE `spellid` = 400; -- blade_madrigal
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000F000000000000000000000000 WHERE `spellid` = 401; -- hunters_prelude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000023000000000000000000000000 WHERE `spellid` = 402; -- archers_prelude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000005000000000000000000000000 WHERE `spellid` = 403; -- sheepfoe_mambo
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001A000000000000000000000000 WHERE `spellid` = 404; -- dragonfoe_mambo
UPDATE `spell_list` SET `jobs` = 0x00000000000000000010000000000000000000000000 WHERE `spellid` = 405; -- fowl_aubade
UPDATE `spell_list` SET `jobs` = 0x00000000000000000003000000000000000000000000 WHERE `spellid` = 406; -- herb_pastoral
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001B000000000000000000000000 WHERE `spellid` = 408; -- shining_fantasia
UPDATE `spell_list` SET `jobs` = 0x00000000000000000008000000000000000000000000 WHERE `spellid` = 409; -- scops_operetta
UPDATE `spell_list` SET `jobs` = 0x00000000000000000022000000000000000000000000 WHERE `spellid` = 410; -- puppets_operetta
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001A000000000000000000000000 WHERE `spellid` = 412; -- gold_capriccio
UPDATE `spell_list` SET `jobs` = 0x00000000000000000024000000000000000000000000 WHERE `spellid` = 414; -- warding_round
UPDATE `spell_list` SET `jobs` = 0x00000000000000000018000000000000000000000000 WHERE `spellid` = 415; -- goblin_gavotte
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000E000000000000000000000000 WHERE `spellid` = 419; -- advancing_march
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001D000000000000000000000000 WHERE `spellid` = 420; -- victory_march
UPDATE `spell_list` SET `jobs` = 0x00000000000000000013000000000000000000000000 WHERE `spellid` = 421; -- battlefield_elegy
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001D000000000000000000000000 WHERE `spellid` = 422; -- carnage_elegy
UPDATE `spell_list` SET `jobs` = 0x00000000000000000010000000000000000000000000 WHERE `spellid` = 424; -- sinewy_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000F000000000000000000000000 WHERE `spellid` = 425; -- dextrous_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000E000000000000000000000000 WHERE `spellid` = 426; -- vivacious_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000D000000000000000000000000 WHERE `spellid` = 427; -- quick_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000C000000000000000000000000 WHERE `spellid` = 428; -- learned_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000B000000000000000000000000 WHERE `spellid` = 429; -- spirited_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000A000000000000000000000000 WHERE `spellid` = 430; -- enchanting_etude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000024000000000000000000000000 WHERE `spellid` = 431; -- herculean_etude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000023000000000000000000000000 WHERE `spellid` = 432; -- uncanny_etude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000022000000000000000000000000 WHERE `spellid` = 433; -- vital_etude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000021000000000000000000000000 WHERE `spellid` = 434; -- swift_etude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000020000000000000000000000000 WHERE `spellid` = 435; -- sage_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001F000000000000000000000000 WHERE `spellid` = 436; -- logical_etude
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001E000000000000000000000000 WHERE `spellid` = 437; -- bewitching_etude
UPDATE `spell_list` SET `jobs` = 0x00000000000000000015000000000000000000000000 WHERE `spellid` = 438; -- fire_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000016000000000000000000000000 WHERE `spellid` = 439; -- ice_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000014000000000000000000000000 WHERE `spellid` = 440; -- wind_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000012000000000000000000000000 WHERE `spellid` = 441; -- earth_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000017000000000000000000000000 WHERE `spellid` = 442; -- lightning_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000013000000000000000000000000 WHERE `spellid` = 443; -- water_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000011000000000000000000000000 WHERE `spellid` = 444; -- light_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000018000000000000000000000000 WHERE `spellid` = 445; -- dark_carol
UPDATE `spell_list` SET `jobs` = 0x00000000000000000022000000000000000000000000 WHERE `spellid` = 446; -- fire_carol_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000023000000000000000000000000 WHERE `spellid` = 447; -- ice_carol_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000020000000000000000000000000 WHERE `spellid` = 448; -- wind_carol_ii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001E000000000000000000000000 WHERE `spellid` = 449; -- earth_carol_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000024000000000000000000000000 WHERE `spellid` = 450; -- lightning_carol_ii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001F000000000000000000000000 WHERE `spellid` = 451; -- water_carol_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000025000000000000000000000000 WHERE `spellid` = 452; -- light_carol_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000025000000000000000000000000 WHERE `spellid` = 453; -- dark_carol_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000009000000000000000000000000 WHERE `spellid` = 454; -- fire_threnody
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000A000000000000000000000000 WHERE `spellid` = 455; -- ice_threnody
UPDATE `spell_list` SET `jobs` = 0x00000000000000000008000000000000000000000000 WHERE `spellid` = 456; -- wind_threnody
UPDATE `spell_list` SET `jobs` = 0x00000000000000000006000000000000000000000000 WHERE `spellid` = 457; -- earth_threnody
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000B000000000000000000000000 WHERE `spellid` = 458; -- lightning_threnody
UPDATE `spell_list` SET `jobs` = 0x00000000000000000007000000000000000000000000 WHERE `spellid` = 459; -- water_threnody
UPDATE `spell_list` SET `jobs` = 0x00000000000000000004000000000000000000000000 WHERE `spellid` = 460; -- light_threnody
UPDATE `spell_list` SET `jobs` = 0x00000000000000000005000000000000000000000000 WHERE `spellid` = 461; -- dark_threnody
UPDATE `spell_list` SET `jobs` = 0x00000000000000000010000000000000000000000000 WHERE `spellid` = 462; -- magic_finale
UPDATE `spell_list` SET `jobs` = 0x00000000000000000007000000000000000000000000 WHERE `spellid` = 463; -- foe_lullaby
UPDATE `spell_list` SET `jobs` = 0x00000000000000000023000000000000000000000000 WHERE `spellid` = 464; -- goddesss_hymnus
UPDATE `spell_list` SET `jobs` = 0x00000000000000000024000000000000000000000000 WHERE `spellid` = 465; -- chocobo_mazurka
UPDATE `spell_list` SET `jobs` = 0x00000000000000000025000000000000000000000000 WHERE `spellid` = 466; -- maidens_virelai
UPDATE `spell_list` SET `jobs` = 0x00000000000000000012000000000000000000000000 WHERE `spellid` = 467; -- raptor_mazurka
UPDATE `spell_list` SET `jobs` = 0x00000000000000000025000000000000000000000000 WHERE `spellid` = 468; -- foe_sirvente
UPDATE `spell_list` SET `jobs` = 0x00000000000000000025000000000000000000000000 WHERE `spellid` = 469; -- adventurers_dirge
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001F000000000000000000000000 WHERE `spellid` = 470; -- sentinels_scherzo
UPDATE `spell_list` SET `jobs` = 0x0000000000000000001F000000000000000000000000 WHERE `spellid` = 471; -- foe_lullaby_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000023000000000000000000000000 WHERE `spellid` = 472; -- pining_nocturne
UPDATE `spell_list` SET `jobs` = 0x000000001F0000000000000000000000000000000000 WHERE `spellid` = 473; -- refresh_ii
UPDATE `spell_list` SET `jobs` = 0x00001F00000000000000000000000000000000000000 WHERE `spellid` = 474; -- cura_ii
UPDATE `spell_list` SET `jobs` = 0x00002400000000000000000000000000000000000000 WHERE `spellid` = 475; -- cura_iii
UPDATE `spell_list` SET `jobs` = 0x0000000000001F000000000000000000000000000021 WHERE `spellid` = 476; -- crusade
UPDATE `spell_list` SET `jobs` = 0x000021000000000000000000000000000000001D0025 WHERE `spellid` = 477; -- regen_iv
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000020000 WHERE `spellid` = 478; -- embrava
UPDATE `spell_list` SET `jobs` = 0x00002300000000000000000000000000000000000000 WHERE `spellid` = 479; -- boost-str
UPDATE `spell_list` SET `jobs` = 0x00002500000000000000000000000000000000000000 WHERE `spellid` = 480; -- boost-dex
UPDATE `spell_list` SET `jobs` = 0x00001E00000000000000000000000000000000000000 WHERE `spellid` = 481; -- boost-vit
UPDATE `spell_list` SET `jobs` = 0x00002200000000000000000000000000000000000000 WHERE `spellid` = 482; -- boost-agi
UPDATE `spell_list` SET `jobs` = 0x00002400000000000000000000000000000000000000 WHERE `spellid` = 483; -- boost-int
UPDATE `spell_list` SET `jobs` = 0x00002000000000000000000000000000000000000000 WHERE `spellid` = 484; -- boost-mnd
UPDATE `spell_list` SET `jobs` = 0x00002100000000000000000000000000000000000000 WHERE `spellid` = 485; -- boost-chr
UPDATE `spell_list` SET `jobs` = 0x00000000230000000000000000000000000000000000 WHERE `spellid` = 486; -- gain-str
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 487; -- gain-dex
UPDATE `spell_list` SET `jobs` = 0x000000001E0000000000000000000000000000000000 WHERE `spellid` = 488; -- gain-vit
UPDATE `spell_list` SET `jobs` = 0x00000000220000000000000000000000000000000000 WHERE `spellid` = 489; -- gain-agi
UPDATE `spell_list` SET `jobs` = 0x00000000240000000000000000000000000000000000 WHERE `spellid` = 490; -- gain-int
UPDATE `spell_list` SET `jobs` = 0x00000000200000000000000000000000000000000000 WHERE `spellid` = 491; -- gain-mnd
UPDATE `spell_list` SET `jobs` = 0x00000000210000000000000000000000000000000000 WHERE `spellid` = 492; -- gain-chr
UPDATE `spell_list` SET `jobs` = 0x00000000240000000000000000000000000000000000 WHERE `spellid` = 493; -- temper
UPDATE `spell_list` SET `jobs` = 0x00002500000000000000000000000000000000000000 WHERE `spellid` = 494; -- arise
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000200000 WHERE `spellid` = 495; -- adloquium
UPDATE `spell_list` SET `jobs` = 0x00000022000000000000000000000000000000000000 WHERE `spellid` = 496; -- firaja
UPDATE `spell_list` SET `jobs` = 0x00000023000000000000000000000000000000000000 WHERE `spellid` = 497; -- blizzaja
UPDATE `spell_list` SET `jobs` = 0x00000020000000000000000000000000000000000000 WHERE `spellid` = 498; -- aeroja
UPDATE `spell_list` SET `jobs` = 0x0000001E000000000000000000000000000000000000 WHERE `spellid` = 499; -- stoneja
UPDATE `spell_list` SET `jobs` = 0x00000024000000000000000000000000000000000000 WHERE `spellid` = 500; -- thundaja
UPDATE `spell_list` SET `jobs` = 0x0000001F000000000000000000000000000000000000 WHERE `spellid` = 501; -- waterja
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000020000 WHERE `spellid` = 502; -- kaustra
UPDATE `spell_list` SET `jobs` = 0x00002222220000200000000000001300000000210000 WHERE `spellid` = 503; -- impact
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 504; -- regen_v
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000001F000000000000000000 WHERE `spellid` = 505; -- gekka_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000021000000000000000000 WHERE `spellid` = 506; -- yain_ichi
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000001D000000000000000000 WHERE `spellid` = 507; -- myoshu_ichi
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000001C000000000000000000 WHERE `spellid` = 508; -- yurin_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000023000000000000000000 WHERE `spellid` = 509; -- kakka_ichi
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000001F000000000000000000 WHERE `spellid` = 510; -- migawari_ichi
UPDATE `spell_list` SET `jobs` = 0x00000000240000000000000000000000000000000000 WHERE `spellid` = 511; -- haste_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000010000000000000 WHERE `spellid` = 513; -- venom_shell
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000019000000000000 WHERE `spellid` = 515; -- maelstrom
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000003000000000000 WHERE `spellid` = 517; -- metallic_body
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000009000000000000 WHERE `spellid` = 519; -- screwdriver
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000010000000000000 WHERE `spellid` = 521; -- mp_drainkiss
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000C000000000000 WHERE `spellid` = 522; -- death_ray
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000C000000000000 WHERE `spellid` = 527; -- smite_of_rage
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000005000000000000 WHERE `spellid` = 529; -- bludgeon
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000012000000000000 WHERE `spellid` = 530; -- refueling
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000013000000000000 WHERE `spellid` = 531; -- ice_break
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000010000000000000 WHERE `spellid` = 532; -- blitzstrahl
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000013000000000000 WHERE `spellid` = 533; -- self-destruct
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000F000000000000 WHERE `spellid` = 534; -- mysterious_light
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000014000000000000 WHERE `spellid` = 535; -- cold_wave
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000007000000000000 WHERE `spellid` = 536; -- poison_breath
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000010000000000000 WHERE `spellid` = 537; -- stinking_gas
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001A000000000000 WHERE `spellid` = 538; -- memento_mori
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000F000000000000 WHERE `spellid` = 539; -- terror_touch
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 540; -- spinal_cleave
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000012000000000000 WHERE `spellid` = 541; -- blood_saber
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000D000000000000 WHERE `spellid` = 542; -- digest
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000010000000000000 WHERE `spellid` = 543; -- mandibular_bite
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000005000000000000 WHERE `spellid` = 544; -- cursed_sphere
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000012000000000000 WHERE `spellid` = 545; -- sickle_slash
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000003000000000000 WHERE `spellid` = 547; -- cocoon
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000014000000000000 WHERE `spellid` = 548; -- filamented_hold
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000002000000000000 WHERE `spellid` = 551; -- power_attack
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 554; -- death_scissors
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000011000000000000 WHERE `spellid` = 555; -- magnetite_cloud
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000019000000000000 WHERE `spellid` = 557; -- eyes_on_me
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 560; -- frenetic_rip
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000013000000000000 WHERE `spellid` = 561; -- frightful_roar
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000015000000000000 WHERE `spellid` = 563; -- hecatomb_wave
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001A000000000000 WHERE `spellid` = 564; -- body_slam
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000015000000000000 WHERE `spellid` = 565; -- radiant_breath
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000004000000000000 WHERE `spellid` = 567; -- helldive
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000E000000000000 WHERE `spellid` = 569; -- jet_stream
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000006000000000000 WHERE `spellid` = 570; -- blood_drain
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000B000000000000 WHERE `spellid` = 572; -- sound_blast
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 573; -- feather_tickle
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000016000000000000 WHERE `spellid` = 574; -- feather_barrier
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000012000000000000 WHERE `spellid` = 575; -- jettatura
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 576; -- yawn
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000A000000000000 WHERE `spellid` = 578; -- wild_carrot
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 579; -- voracious_trunk
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000004000000000000 WHERE `spellid` = 581; -- healing_breeze
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000B000000000000 WHERE `spellid` = 582; -- chaotic_eye
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000004000000000000 WHERE `spellid` = 584; -- sheep_song
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000023000000000000 WHERE `spellid` = 585; -- ram_charge
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000006000000000000 WHERE `spellid` = 587; -- claw_cyclone
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 588; -- lowing
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 589; -- dimensional_death
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 591; -- heat_breath
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000E000000000000 WHERE `spellid` = 592; -- blank_gaze
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000016000000000000 WHERE `spellid` = 593; -- magic_fruit
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000E000000000000 WHERE `spellid` = 594; -- uppercut
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001A000000000000 WHERE `spellid` = 595; -- 1000_needles
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000D000000000000 WHERE `spellid` = 596; -- pinecone_bomb
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000002000000000000 WHERE `spellid` = 597; -- sprout_smack
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000008000000000000 WHERE `spellid` = 598; -- soporific
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000003000000000000 WHERE `spellid` = 599; -- queasyshroom
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000002000000000000 WHERE `spellid` = 603; -- wild_oats
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000019000000000000 WHERE `spellid` = 604; -- bad_breath
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000011000000000000 WHERE `spellid` = 605; -- geist_wall
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000011000000000000 WHERE `spellid` = 606; -- awful_eye
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001D000000000000 WHERE `spellid` = 608; -- frost_breath
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 610; -- infrasonics
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 611; -- disseverment
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000024000000000000 WHERE `spellid` = 612; -- actinic_burst
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000024000000000000 WHERE `spellid` = 613; -- reactor_cool
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 614; -- saline_coat
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 615; -- plasma_charge
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000023000000000000 WHERE `spellid` = 616; -- temporal_shift
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 617; -- vertical_cleave
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000005000000000000 WHERE `spellid` = 618; -- blastbomb
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000004000000000000 WHERE `spellid` = 620; -- battle_dance
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001D000000000000 WHERE `spellid` = 621; -- sandspray
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000A000000000000 WHERE `spellid` = 622; -- grand_slam
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000004000000000000 WHERE `spellid` = 623; -- head_butt
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000A000000000000 WHERE `spellid` = 626; -- bomb_toss
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 628; -- frypan
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000016000000000000 WHERE `spellid` = 629; -- flying_hip_press
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 631; -- hydro_shot
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001E000000000000 WHERE `spellid` = 632; -- diamondhide
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001E000000000000 WHERE `spellid` = 633; -- enervation
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000016000000000000 WHERE `spellid` = 634; -- light_of_penance
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001F000000000000 WHERE `spellid` = 636; -- warm-up
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001F000000000000 WHERE `spellid` = 637; -- firespit
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000004000000000000 WHERE `spellid` = 638; -- feather_storm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 640; -- tail_slap
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 641; -- hysteric_barrage
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000021000000000000 WHERE `spellid` = 642; -- amplification
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000021000000000000 WHERE `spellid` = 643; -- cannonball
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000023000000000000 WHERE `spellid` = 644; -- mind_blast
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 645; -- exuviation
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000024000000000000 WHERE `spellid` = 646; -- magic_hammer
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 647; -- zephyr_mantle
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 648; -- regurgitation
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000019000000000000 WHERE `spellid` = 650; -- seedspray
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001D000000000000 WHERE `spellid` = 651; -- corrosive_ooze
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 652; -- spiral_spin
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000021000000000000 WHERE `spellid` = 653; -- asuran_claws
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 654; -- sub-zero_smash
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 655; -- triumphant_roar
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000017000000000000 WHERE `spellid` = 656; -- acrid_stream
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000019000000000000 WHERE `spellid` = 657; -- blazing_bound
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000016000000000000 WHERE `spellid` = 658; -- plenilune_embrace
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000019000000000000 WHERE `spellid` = 659; -- demoralizing_roar
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 660; -- cimicine_discharge
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 661; -- animating_wail
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 662; -- battery_charge
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000017000000000000 WHERE `spellid` = 663; -- leafstorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000018000000000000 WHERE `spellid` = 664; -- regeneration
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001A000000000000 WHERE `spellid` = 665; -- final_sting
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001A000000000000 WHERE `spellid` = 666; -- goblin_rush
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 667; -- vanity_dive
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 668; -- magic_barrier
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 669; -- whirl_of_rage
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001B000000000000 WHERE `spellid` = 670; -- benthic_typhoon
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 671; -- auroral_drape
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 672; -- osmosis
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 673; -- quad_continuum
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001C000000000000 WHERE `spellid` = 674; -- fantod
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001D000000000000 WHERE `spellid` = 675; -- thermal_pulse
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001D000000000000 WHERE `spellid` = 677; -- empty_thrash
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001D000000000000 WHERE `spellid` = 678; -- dream_flower
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001E000000000000 WHERE `spellid` = 679; -- occultation
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001E000000000000 WHERE `spellid` = 680; -- charged_whisker
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001F000000000000 WHERE `spellid` = 681; -- winds_of_promy
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000001F000000000000 WHERE `spellid` = 682; -- delta_thrust
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 683; -- evryone_grudge
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 684; -- reaving_wind
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 685; -- barrier_tusk
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000020000000000000 WHERE `spellid` = 686; -- mortal_ray
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000021000000000000 WHERE `spellid` = 687; -- water_bomb
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000021000000000000 WHERE `spellid` = 688; -- heavy_strike
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 689; -- dark_orb
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 690; -- white_wind
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 692; -- sudden_lunge
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000023000000000000 WHERE `spellid` = 693; -- quadrastrike
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000023000000000000 WHERE `spellid` = 694; -- vapor_spray
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000024000000000000 WHERE `spellid` = 695; -- thunder_breath
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 696; -- orcish_counterstance
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 697; -- amorphic_spikes
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 698; -- wind_breath
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 699; -- barbed_crescent
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 736; -- thunderbolt
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000022000000000000 WHERE `spellid` = 737; -- harden_shell
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000023000000000000 WHERE `spellid` = 738; -- absolute_terror
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000024000000000000 WHERE `spellid` = 739; -- gates_of_hades
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000024000000000000 WHERE `spellid` = 740; -- tourbillion
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 741; -- pyric_bulwark
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 742; -- bilgestorm
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000025000000000000 WHERE `spellid` = 743; -- bloodrake
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000600 WHERE `spellid` = 768; -- indi-regen
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000C00 WHERE `spellid` = 770; -- indi-refresh
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002200 WHERE `spellid` = 771; -- indi-haste
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001600 WHERE `spellid` = 772; -- indi-str
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001500 WHERE `spellid` = 773; -- indi-dex
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001300 WHERE `spellid` = 774; -- indi-vit
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001200 WHERE `spellid` = 775; -- indi-agi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001000 WHERE `spellid` = 776; -- indi-int
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000E00 WHERE `spellid` = 777; -- indi-mnd
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000C00 WHERE `spellid` = 778; -- indi-chr
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000E00 WHERE `spellid` = 779; -- indi-fury
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000B00 WHERE `spellid` = 780; -- indi-barrier
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001600 WHERE `spellid` = 781; -- indi-acumen
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001200 WHERE `spellid` = 782; -- indi-fend
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000400 WHERE `spellid` = 783; -- indi-precision
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000200 WHERE `spellid` = 784; -- indi-voidance
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000800 WHERE `spellid` = 785; -- indi-focus
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000600 WHERE `spellid` = 786; -- indi-attunement
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001D00 WHERE `spellid` = 787; -- indi-wilt
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001A00 WHERE `spellid` = 788; -- indi-frailty
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002300 WHERE `spellid` = 789; -- indi-fade
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002000 WHERE `spellid` = 790; -- indi-malaise
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001A00 WHERE `spellid` = 791; -- indi-slip
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001800 WHERE `spellid` = 792; -- indi-torpor
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002200 WHERE `spellid` = 793; -- indi-vex
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001E00 WHERE `spellid` = 794; -- indi-languor
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001600 WHERE `spellid` = 795; -- indi-slow
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002000 WHERE `spellid` = 796; -- indi-paralysis
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002000 WHERE `spellid` = 797; -- indi-gravity
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000700 WHERE `spellid` = 798; -- geo-regen
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000200 WHERE `spellid` = 799; -- geo-poison
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000E00 WHERE `spellid` = 800; -- geo-refresh
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002400 WHERE `spellid` = 801; -- geo-haste
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001800 WHERE `spellid` = 802; -- geo-str
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001700 WHERE `spellid` = 803; -- geo-dex
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001600 WHERE `spellid` = 804; -- geo-vit
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001400 WHERE `spellid` = 805; -- geo-agi
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001200 WHERE `spellid` = 806; -- geo-int
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001000 WHERE `spellid` = 807; -- geo-mnd
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000E00 WHERE `spellid` = 808; -- geo-chr
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001100 WHERE `spellid` = 809; -- geo-fury
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000D00 WHERE `spellid` = 810; -- geo-barrier
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001800 WHERE `spellid` = 811; -- geo-acumen
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001400 WHERE `spellid` = 812; -- geo-fend
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000500 WHERE `spellid` = 813; -- geo-precision
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000300 WHERE `spellid` = 814; -- geo-voidance
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000A00 WHERE `spellid` = 815; -- geo-focus
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000800 WHERE `spellid` = 816; -- geo-attunement
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001F00 WHERE `spellid` = 817; -- geo-wilt
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001C00 WHERE `spellid` = 818; -- geo-frailty
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002500 WHERE `spellid` = 819; -- geo-fade
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002200 WHERE `spellid` = 820; -- geo-malaise
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001C00 WHERE `spellid` = 821; -- geo-slip
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001A00 WHERE `spellid` = 822; -- geo-torpor
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002400 WHERE `spellid` = 823; -- geo-vex
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002000 WHERE `spellid` = 824; -- geo-languor
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001800 WHERE `spellid` = 825; -- geo-slow
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002300 WHERE `spellid` = 826; -- geo-paralysis
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002200 WHERE `spellid` = 827; -- geo-gravity
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001200 WHERE `spellid` = 828; -- fira
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001E00 WHERE `spellid` = 829; -- fira_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001500 WHERE `spellid` = 830; -- blizzara
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002100 WHERE `spellid` = 831; -- blizzara_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000F00 WHERE `spellid` = 832; -- aera
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001C00 WHERE `spellid` = 833; -- aera_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000A00 WHERE `spellid` = 834; -- stonera
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002200 WHERE `spellid` = 835; -- stonera_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000001800 WHERE `spellid` = 836; -- thundara
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002300 WHERE `spellid` = 837; -- thundara_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000000C00 WHERE `spellid` = 838; -- watera
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000002500 WHERE `spellid` = 839; -- watera_ii
UPDATE `spell_list` SET `jobs` = 0x0000000000000000000000000000000000000000001B WHERE `spellid` = 840; -- foil
UPDATE `spell_list` SET `jobs` = 0x00000000120000000000000000000000000000000000 WHERE `spellid` = 841; -- distract
UPDATE `spell_list` SET `jobs` = 0x00000000200000000000000000000000000000000000 WHERE `spellid` = 842; -- distract_ii
UPDATE `spell_list` SET `jobs` = 0x00000000160000000000000000000000000000000000 WHERE `spellid` = 843; -- frazzle
UPDATE `spell_list` SET `jobs` = 0x00000000230000000000000000000000000000000000 WHERE `spellid` = 844; -- frazzle_ii
UPDATE `spell_list` SET `jobs` = 0x00000000180000000000000000000000000000000000 WHERE `spellid` = 845; -- flurry
UPDATE `spell_list` SET `jobs` = 0x00000000240000000000000000000000000000000000 WHERE `spellid` = 846; -- flurry_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000002500000000000000 WHERE `spellid` = 847; -- atomos
UPDATE `spell_list` SET `jobs` = 0x00000000000000250000000000000000000000000000 WHERE `spellid` = 856; -- endark_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000250000000000000000000000000000 WHERE `spellid` = 880; -- drain_iii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 885; -- geohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 886; -- hydrohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 887; -- anemohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 888; -- pyrohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 889; -- cryohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 890; -- ionohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 891; -- noctohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000000000000000000000000000000000250000 WHERE `spellid` = 892; -- luminohelix_ii
UPDATE `spell_list` SET `jobs` = 0x00000000250000000000000000000000000000000000 WHERE `spellid` = 895; -- temper_ii

