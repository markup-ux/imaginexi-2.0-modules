-----------------------------------
-- Imagine XI 1.0 long stance / circle durations (module only)
-- NIN Yonin / Innin / Futae / Issekigan, SAM Hasso / Seigan / Warding Circle,
-- DRG Ancient Circle. Official power / effect math is kept.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_long_stances')

local LONG_DURATION = 3600

m:addOverride('xi.job_utils.ninja.useYonin', function(player, target, ability, action)
    target:delStatusEffect(xi.effect.INNIN)
    target:delStatusEffect(xi.effect.YONIN)
    target:addStatusEffect(xi.effect.YONIN, { power = 30, duration = LONG_DURATION, origin = player, tick = 15 })

    return xi.effect.YONIN
end)

m:addOverride('xi.job_utils.ninja.useInnin', function(player, target, ability, action)
    target:delStatusEffect(xi.effect.INNIN)
    target:delStatusEffect(xi.effect.YONIN)
    target:addStatusEffect(xi.effect.INNIN, { power = 30, duration = LONG_DURATION, origin = player, tick = 15, subPower = 20 })

    return xi.effect.INNIN
end)

m:addOverride('xi.job_utils.ninja.useFutae', function(player, target, ability, action)
    target:addStatusEffect(xi.effect.FUTAE, { duration = LONG_DURATION, origin = player })

    return xi.effect.FUTAE
end)

m:addOverride('xi.job_utils.ninja.useIssekigan', function(player, target, ability, action)
    target:addStatusEffect(xi.effect.ISSEKIGAN, { power = 25, duration = LONG_DURATION, origin = player })

    return xi.effect.ISSEKIGAN
end)

m:addOverride('xi.job_utils.samurai.useHasso', function(player, target, ability)
    local strboost = 0

    if target:getMainJob() == xi.job.SAM then
        strboost = target:getMainLvl() / 7 + target:getJobPointLevel(xi.jp.HASSO_EFFECT)
    elseif target:getSubJob() == xi.job.SAM then
        strboost = target:getSubLvl() / 7
    end

    if strboost > 0 then
        target:delStatusEffect(xi.effect.HASSO)
        target:delStatusEffect(xi.effect.SEIGAN)
        target:addStatusEffect(xi.effect.HASSO, { power = strboost, duration = LONG_DURATION, origin = player })
    end

    return xi.effect.HASSO
end)

m:addOverride('xi.job_utils.samurai.useSeigan', function(player, target, ability)
    if target:isWeaponTwoHanded() then
        target:delStatusEffect(xi.effect.HASSO)
        target:delStatusEffect(xi.effect.SEIGAN)
        target:addStatusEffect(xi.effect.SEIGAN, { duration = LONG_DURATION, origin = player })
    end

    return xi.effect.SEIGAN
end)

m:addOverride('xi.job_utils.samurai.useWardingCircle', function(player, target, ability)
    local duration = LONG_DURATION + player:getMod(xi.mod.WARDING_CIRCLE_DURATION)
    local power    = player:getMainJob() == xi.job.SAM and 15 or 5

    power = power + player:getMod(xi.mod.WARDING_CIRCLE_POTENCY)

    target:addStatusEffect(xi.effect.WARDING_CIRCLE, { power = power, duration = duration, origin = player })

    return xi.effect.WARDING_CIRCLE
end)

m:addOverride('xi.job_utils.dragoon.useAncientCircle', function(player, target, ability)
    local duration = LONG_DURATION + player:getMod(xi.mod.ANCIENT_CIRCLE_DURATION)
    local power    = player:getMainJob() == xi.job.DRG and 15 or 5

    power = power + player:getMod(xi.mod.ANCIENT_CIRCLE_POTENCY)

    ability:setMsg(xi.msg.basic.USES_ABILITY_FORTIFIED_DRAGONS)

    target:addStatusEffect(xi.effect.ANCIENT_CIRCLE, { power = power, duration = duration, origin = player })

    return xi.effect.ANCIENT_CIRCLE
end)
