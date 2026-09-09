# Imagine XI 2.0 modules

Drop-in [LandSandBoat](https://github.com/LandSandBoat/server) modules. Core `src/` and `scripts/` stay stock.

Copy the files you want into your server's `modules/custom/`, add the matching lines from [`modules/init.txt.example`](modules/init.txt.example) to your `init.txt`, apply the `.sql` with dbtool, and rebuild `xi_map` if you enabled a `.cpp`. Comment a line to turn a feature off.

Play on Imagine XI 2.0: https://github.com/markup-ux/imaginexi-updates

Helpers used by other modules (do not add these to `init.txt`): `ixi20_economy.lua`, `ixi20_gear_loot.lua`, `ixi20_shop_gear.lua`, `ixi20_bis_gear_progression.lua`, `ixi20_hnm_claim_lib.lua`, `ixi20_hnm_roster.lua`, `ixi20_hnm_defense_scaling.lua`, `ixi20_hnm_anti_melt.lua`, `ixi20_healer_pressure.lua`.

To undo SQL changes, apply `modules/custom/sql/ixi20_REVERT.sql` on your database only after you have a backup.

## Settings

Several modules read `xi.settings.main.IMAGINEXI_*` and `xi.settings.map.IMAGINEXI_*`. Add the keys you need to your `settings/main.lua` and `settings/map.lua` (they default in a useful direction if missing, but economy, cosmetics, and HNM tuning expect these):

```lua
-- settings/main.lua
IMAGINEXI_GIL_TO_EXP_ENABLED = true
IMAGINEXI_SPARKS_TO_EXP_ENABLED = true
IMAGINEXI_BLOCK_SHOP_GEAR = true
IMAGINEXI_GEAR_LOOT_ENABLED = true
IMAGINEXI_COSMETIC_DROP_ENABLED = true
IMAGINEXI_TOO_WEAK_NO_LOOT = true
IMAGINEXI_CONQUEST_FAME = true
IMAGINEXI_ALWAYS_CAP_COMBAT_MAGIC_SKILLS = true

-- settings/map.lua
IMAGINEXI_HNM_HP_MULTIPLIER = 3.0
IMAGINEXI_HNM_STAT_MULTIPLIER = 2.0
IMAGINEXI_HNM_CLAIM_SHIELD_MS = 10000
IMAGINEXI_HNM_CLAIM_IDLE_SECONDS = 90
IMAGINEXI_HNM_LOCKOUT_SECONDS = 43200
IMAGINEXI_HNM_TIMED_RESPAWN_SECONDS = 1200
```

## Jobs and progression

| Module | What it does |
|---|---|
| `ixi20_all_jobs_at_start` | Unlocks WAR–RUN at create |
| `ixi20_job_progression_37cap.sql` | Abilities, traits, and magic unlock by 37. Two-hours / one-hours at 1 |
| `ixi20_extra_job_traits.sql` | Dual Wield V on WAR–RUN; TH3 on THF/BST/RNG/COR; caster Refresh / Conserve MP / Fast Cast; RDM Shield Mastery at 1 |
| `ixi20_combat_skill_ranks.sql` / `ixi20_magic_skill_ranks.sql` | Native weapons A+, ninjutsu A+ on all jobs, songs A+ on BRD |
| `ixi20_capped_skills.cpp` | Combat / magic / defensive skills stay at stored job cap |
| `ixi20_share_xp` | Half of gained XP levels the current subjob (cap 37) |
| `ixi20_auto_learn_spells` | Grants eligible spells on login / level-up / job change |
| `ixi20_all_equipment_all_jobs.sql` | Wear anything on any job |
| `ixi20_af_levels.sql` | AF1 / Yinyang at 50; AF2 / Relic at 60 |
| `ixi20_corsair` | All Phantom Rolls from create. No dice. Quick Draw does not eat cards |
| `ixi20_smn_support_progression.sql` | SMN 1–20 support-first Blood Pacts |

## Combat

| Module | What it does |
|---|---|
| `ixi20_disable_trusts` | Trusts cannot be cast |
| `ixi20_level_sync` + `ixi20_gear_sync_scaling.cpp` | Level Sync up or down. The set stays on and scales |
| `ixi20_debuff_stack` | Dia + Bio together. Poison / Slow / Paralyze / Blind stack by source. Elemental DoTs and helixes stack |
| `ixi20_bind_kite` | Bind holds through a few hits for kiting |
| `ixi20_infinite_ammo` | Combat ammo is not consumed |
| `ixi20_ninja_tools.cpp` | Ninjutsu needs no tools |
| `ixi20_ja_windows` | Cascade 8 min 10% MAB; SCH 5×48s stratagems; 45s Accession / Manifestation / Diffusion |
| `ixi20_mana_wall` | Mana Wall is a toggle |
| `ixi20_benediction_mp` | Benediction also restores MP |
| `ixi20_sp_uptime` | Timed two-hours / one-hours last 2 minutes |
| `ixi20_long_stances` | NIN / SAM / DRG stances last 1 hour |
| `ixi20_enhancing_persist` | Enhancing, songs, and rolls last until zone / death / job change |
| `ixi20_refresh_regen` / `ixi20_refresh_stack` | Regen matches Refresh. Refresh I + II stack |
| `ixi20_flatten_latents.sql` | Most single-condition latents are always on |
| `ixi20_haste_belts.sql` | Swift Belt / Velocious Belt haste retune |
| `imagine_job_hooks.cpp` | Provoke on MNK / PLD / NIN / RUN; first-job starter crate |

## Pets

| Module | What it does |
|---|---|
| `ixi20_hybrid_wyvern` | DRG wyvern is always hybrid DD + party support |
| `ixi20_subjob_wyvern` | Subjob DRG can Call Wyvern |
| `ixi20_pet_helpful_magic.cpp` | Cure / Protect can target player pets |
| `ixi20_no_perpetuation` | Avatar / spirit perpetuation is 0 |
| `ixi20_no_bp_timers` | Blood Pact recast is 0 |

## Economy and loot

| Module | What it does |
|---|---|
| `ixi20_gil_economy` | Gil and Sparks become XP. Shops do not sell weapons / armor. DC+ kills drop gear |
| `ixi20_too_weak_loot` | Too Weak kills drop nothing |
| `ixi20_cosmetic_drops` | 10% cosmetic on EXP kills, into wardrobe |
| `ixi20_dropped_casket` | Discarded items become community caskets |
| `ixi20_ah_gifts` | Auction House is a 0-gil gift locker |
| `ixi20_no_gil_fees` | Homepoints, guides, airships, chocobos — no gil cost |
| `ixi20_cp_exchange` | Exchange NPC beside conquest / signet guards |
| `ixi20_max_storage` | 80-slot inventory + every Mog bag / wardrobe |
| `ixi20_craft_always_succeed.cpp` | Valid recipes never break. HQ stays retail |

## Travel

| Module | What it does |
|---|---|
| `ixi20_travel_unlocks` | Crag crystals + both airship passes on create |
| `ixi20_all_maps` / `ixi20_survival_guides` | Every map and Survival Guide on create |
| `ixi20_city_mounts` + `ixi20_mount_level.cpp` | Mounts at main 10, including main cities |
| `ixi20_teleport_no_visit` | Teleports do not require a prior visit |
| `ixi20_retrace` | Retrace without Campaign allegiance |
| `ixi20_permanent_warp` | Instant Warp is not consumed |

## World and HNMs

| Module | What it does |
|---|---|
| `ixi20_conquest_fame` | Beastmen XP-kills raise home-nation fame |
| `ixi20_prowess` / `ixi20_regime_support` | Grounds prowess lasts 3 days. Field / Grounds support is free |
| `ixi20_starter_hnm` | Lowbie HNMs in the six nation fields |
| `ixi20_hnm_access` / `ixi20_hnm_claim` / `ixi20_hnm_difficulty` / `ixi20_hnm_packages` | Timed respawns, lottery claim, 3× HP, no Sleep, apex skills |
| `ixi20_nm_restart_spawn` | Timed / lottery NMs up when the map process starts |
| `ixi20_pixie_rescue` | A spirit raises you on death (weakness stays) |
| `ixi20_whm_bar_enspell` | WHM Bar-element also En-spells the party |

## Host / GM only (skip these on another server)

| Module | What it does |
|---|---|
| `ixi20_daily_mantra` | Shared daily login quote |
| `ixi20_leftover_magic_menu` | Client leftover-spell menu fix (needs a DAT) |
| `ixi20_gm_home_test_*` | GM Home test dummy / vendor / XP hares |
| `ixi20_godmode_persist` | Re-applies `!godmode` after raise |
| `ixi20_nm_spawn` | GM `!spawnnms` |
| `ixi20_bis` | GM `!bis` |
| `ixi20_job_change.cpp` | Job-change packet trace |

## License

GNU GPL v3 — same as LandSandBoat. FINAL FANTASY XI and its assets belong to Square Enix. This repository distributes none of them.
