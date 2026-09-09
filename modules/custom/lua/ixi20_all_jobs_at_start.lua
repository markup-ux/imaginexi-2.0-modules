-----------------------------------
-- Unlock every retail job (WAR-RUN) at create / login.
-- Does not unlock MON or any Imagine XI 1.0 Soldier job.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_all_jobs_at_start')

local function unlockRetailJobs(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    -- xi.job.WAR (1) through xi.job.RUN (22). Skip NONE and MON.
    -- unlockJob always pushes 0x01B; only call it when the bit is missing.
    for job = xi.job.WAR, xi.job.RUN do
        if not player:hasJob(job) then
            player:unlockJob(job)
        end
    end

    if not player:hasJob(0) then
        player:unlockJob(0) -- subjob
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    unlockRetailJobs(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    unlockRetailJobs(player)
end)
