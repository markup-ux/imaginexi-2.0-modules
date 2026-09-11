-----------------------------------
-- Split half of gained XP with the current subjob (always on).
-- Combat XP is halved before it is applied to the main job.
-- Script / gil XP is split by the C++ addExp wrap.
-- Per-kill subjob XP chat is omitted so Fields of Valor 2/3 reports stay visible.
-- Shared subjob XP stops at job level 37; switch that job to main to go higher.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_share_xp')

m:addOverride('xi.experiencePoints.calculate', function(member, mob, data)
    local result = super(member, mob, data)
    if
        result and
        result.exp and
        result.exp > 0 and
        Ixi20PrepareSharedExp
    then
        result.exp = Ixi20PrepareSharedExp(member, result.exp, true)
    end

    return result
end)
