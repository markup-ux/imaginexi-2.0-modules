-----------------------------------
-- Imagine XI 2.0 world-HNM claim lottery.
-- 10s unclaimable window, one ticket per alliance, 90s idle release.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_hnm_roster')
require('modules/custom/lua/ixi20_hnm_claim_lib')
-----------------------------------

local m = Module:new('ixi20_hnm_claim')

for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
    if xi.ixi20Hnm.isPackageTarget(target) then
        m:addOverride(xi.ixi20Hnm.overridePath(target.zone, target.mob, 'onMobInitialize'), function(mob)
            xi.ixi20HnmClaim.attach(mob, {
                filterFn = function(player)
                    return not xi.ixi20HnmAccess or not xi.ixi20HnmAccess.isLocked(player, mob)
                end,
            })
            super(mob)
        end)
    end
end
