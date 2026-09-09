-----------------------------------
-- Trusts are fully uncastable (settings + canCast deny).
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_disable_trusts')

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    return xi.msg.basic.TRUST_NO_CAST_TRUST
end)
