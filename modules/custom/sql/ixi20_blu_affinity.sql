-- Imagine XI 2.0: Chain Affinity / Burst Affinity JA levels stay retail.
-- Apply after ixi20_job_progression_37cap.sql. Pair with ixi20_blu_affinity.lua
-- so main and sub BLU have Chain Affinity, Burst Affinity, and Diffusion
-- always-on from level 1 (the JAs themselves are unused).

UPDATE `abilities` SET `level` = 40 WHERE `abilityId` = 94; -- chain_affinity
UPDATE `abilities` SET `level` = 25 WHERE `abilityId` = 95; -- burst_affinity
