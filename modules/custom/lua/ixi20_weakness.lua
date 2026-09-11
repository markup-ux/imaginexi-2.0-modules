-----------------------------------
-- Imagine XI 2.0: Weakness lasts 3 minutes (stock is 5; Arise is already 3).
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_weakness')

local WEAKNESS_MS = 180000

local function clampWeakness(target, effect)
    if not effect or not target then
        return
    end

    if effect:getDuration() > WEAKNESS_MS then
        effect:setDuration(WEAKNESS_MS)
        effect:resetStartTime()
    end
end

local function install()
    if not xi.effects or not xi.effects.weakness then
        return
    end

    local prev = xi.effects.weakness.onEffectGain
    xi.effects.weakness.onEffectGain = function(target, effect)
        clampWeakness(target, effect)
        if prev then
            return prev(target, effect)
        end
    end
end

m:addOverride('xi.effects.weakness.onEffectGain', function(target, effect)
    clampWeakness(target, effect)
    return super(target, effect)
end)

install()

return m
