-----------------------------------
-- Imagine XI 2.0: Sublimation stacks with Refresh (all tiers).
-- Stock deletes Refresh I/II when charging, and Refresh III deletes
-- Sublimation. This module keeps both.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_sublimation_stack')

local function useSublimation(player, target, ability)
    local mp        = 0
    local maxMP     = player:getMaxMP()
    local currentMP = player:getMP()

    if player:hasStatusEffect(xi.effect.SUBLIMATION_COMPLETE) then
        mp = player:getStatusEffect(xi.effect.SUBLIMATION_COMPLETE):getPower()
        if mp + currentMP > maxMP then
            mp = maxMP - currentMP
        end

        player:addMP(mp)
        player:delStatusEffectSilent(xi.effect.SUBLIMATION_COMPLETE)
        ability:setMsg(xi.msg.basic.JA_RECOVERS_MP)
    elseif player:hasStatusEffect(xi.effect.SUBLIMATION_ACTIVATED) then
        mp = player:getStatusEffect(xi.effect.SUBLIMATION_ACTIVATED):getPower()
        if mp + currentMP > maxMP then
            mp = maxMP - currentMP
        end

        player:addMP(mp)
        player:delStatusEffectSilent(xi.effect.SUBLIMATION_ACTIVATED)
        ability:setMsg(xi.msg.basic.JA_RECOVERS_MP)
    else
        player:addStatusEffect(xi.effect.SUBLIMATION_ACTIVATED, { duration = 7200, origin = player, tick = 3 })
    end

    return mp
end

local function refreshGain(target, effect)
    -- Keep Sublimation. Stock Refresh III deletes it.
    effect:addMod(xi.mod.REFRESH, effect:getPower())
end

local function keepRefresh()
    -- Stock Sublimation: Activated / Complete delete Refresh here.
end

local function install()
    if xi.actions and xi.actions.abilities and xi.actions.abilities.sublimation then
        xi.actions.abilities.sublimation.onUseAbility = useSublimation
    end

    if xi.effects and xi.effects.refresh then
        xi.effects.refresh.onEffectGain = refreshGain
    end

    if xi.effects and xi.effects.sublimation_activated then
        xi.effects.sublimation_activated.onEffectGain = keepRefresh
    end

    if xi.effects and xi.effects.sublimation_complete then
        xi.effects.sublimation_complete.onEffectGain = keepRefresh
    end
end

m:addOverride('xi.actions.abilities.sublimation.onUseAbility', function(player, target, ability)
    return useSublimation(player, target, ability)
end)

m:addOverride('xi.effects.refresh.onEffectGain', function(target, effect)
    refreshGain(target, effect)
end)

m:addOverride('xi.effects.sublimation_activated.onEffectGain', function(target, effect)
    keepRefresh(target, effect)
end)

m:addOverride('xi.effects.sublimation_complete.onEffectGain', function(target, effect)
    keepRefresh(target, effect)
end)

install()

return m
