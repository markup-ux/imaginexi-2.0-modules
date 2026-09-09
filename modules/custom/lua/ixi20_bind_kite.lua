-----------------------------------
-- Imagine XI 2.0: Bind is useful for kiting.
-- C++ ixi20_bind_kite.cpp ramps break chance per damaging instance:
--   20% / 40% / 65% / 90%
-- Duration is still the clock (5-60s after resist). DoTs do not count.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_bind_kite')

-- Hit count lives on subPower. Power is the saved walk speed.
m:addOverride('xi.effects.bind.onEffectGain', function(target, effect)
    super(target, effect)
    effect:setSubPower(0)
end)

-- Helix ticks used takeDamage with no flags; keep them from eating Bind hits.
m:addOverride('xi.effects.helix.onEffectTick', function(target, effect)
    local dmg = utils.handleStoneskin(target, effect:getPower(), xi.attackType.NONE)

    if dmg > 0 then
        target:takeDamage(dmg, nil, nil, nil, { wakeUp = true, breakBind = false })
    end
end)
