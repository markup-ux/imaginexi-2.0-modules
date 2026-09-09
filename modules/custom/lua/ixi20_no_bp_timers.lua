-----------------------------------
-- Imagine XI 2.0: no Blood Pact recast (module only).
-- 1.0 zeroed SMN BP timers. Recast IDs 173/174 stay so they do not
-- collide with 2-hour (Recast 0). recastTime is 0 in SQL; this also
-- clears the rage/ward groups after a pact so a leftover timer cannot stick.
-- Gear with Blood Pact delay is remapped in ixi20_no_bp_timers.sql.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/summoner')
-----------------------------------

local m = Module:new('ixi20_no_bp_timers')

m:addOverride('xi.job_utils.summoner.onUseBloodPact', function(target, petskill, summoner, action)
    if summoner then
        summoner:setLocalVar('bpRecastTime', 0)
    end

    super(target, petskill, summoner, action)

    if not summoner or not summoner.isPC or not summoner:isPC() then
        return
    end

    summoner:resetRecast(xi.recast.ABILITY, xi.recastID.BLOODPACT_RAGE)
    summoner:resetRecast(xi.recast.ABILITY, xi.recastID.BLOODPACT_WARD)
end)
