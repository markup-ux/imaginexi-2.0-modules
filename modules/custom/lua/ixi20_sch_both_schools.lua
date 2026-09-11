-----------------------------------
-- Imagine XI 2.0: SCH Light or Dark Arts does not punish the other school.
-- Stock Light Arts is -10% white cost/cast/recast and +20% black (and the reverse
-- for Dark Arts). This module keeps the matching-school bonus and drops the tax,
-- so Cure and Stone are both usable on either stance. Addendum extras are
-- unlocked by the C++ module. Pair with ixi20_sch_arts.cpp for stratagems.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_sch_both_schools')

local function applyWhiteBonus(target, bonus, extra)
    target:addMod(xi.mod.WHITE_MAGIC_COST, -bonus)
    target:addMod(xi.mod.WHITE_MAGIC_CAST, -bonus)
    target:addMod(xi.mod.WHITE_MAGIC_RECAST, -bonus)
    if extra then
        target:addMod(xi.mod.WHITE_MAGIC_COST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_CAST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_RECAST, -10)
    end
end

local function removeWhiteBonus(target, bonus, extra)
    target:delMod(xi.mod.WHITE_MAGIC_COST, -bonus)
    target:delMod(xi.mod.WHITE_MAGIC_CAST, -bonus)
    target:delMod(xi.mod.WHITE_MAGIC_RECAST, -bonus)
    if extra then
        target:delMod(xi.mod.WHITE_MAGIC_COST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_CAST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_RECAST, -10)
    end
end

local function applyBlackBonus(target, bonus, extra)
    target:addMod(xi.mod.BLACK_MAGIC_COST, -bonus)
    target:addMod(xi.mod.BLACK_MAGIC_CAST, -bonus)
    target:addMod(xi.mod.BLACK_MAGIC_RECAST, -bonus)
    if extra then
        target:addMod(xi.mod.BLACK_MAGIC_COST, -10)
        target:addMod(xi.mod.BLACK_MAGIC_CAST, -10)
        target:addMod(xi.mod.BLACK_MAGIC_RECAST, -10)
    end
end

local function removeBlackBonus(target, bonus, extra)
    target:delMod(xi.mod.BLACK_MAGIC_COST, -bonus)
    target:delMod(xi.mod.BLACK_MAGIC_CAST, -bonus)
    target:delMod(xi.mod.BLACK_MAGIC_RECAST, -bonus)
    if extra then
        target:delMod(xi.mod.BLACK_MAGIC_COST, -10)
        target:delMod(xi.mod.BLACK_MAGIC_CAST, -10)
        target:delMod(xi.mod.BLACK_MAGIC_RECAST, -10)
    end
end

local function notTabula(target)
    return not target:hasStatusEffect(xi.effect.TABULA_RASA)
end

local function lightGain(target, effect)
    target:recalculateAbilitiesTable()
    local bonus = effect:getPower()
    local regen = effect:getSubPower()
    local extra = notTabula(target)
    applyWhiteBonus(target, bonus, extra)
    if extra then
        target:addMod(xi.mod.LIGHT_ARTS_REGEN, regen)
        target:addMod(xi.mod.REGEN_DURATION, regen * 2)
    end

    target:recalculateSkillsTable()
end

local function lightLose(target, effect)
    target:recalculateAbilitiesTable()
    local bonus = effect:getPower()
    local regen = effect:getSubPower()
    local extra = notTabula(target)
    removeWhiteBonus(target, bonus, extra)
    if extra then
        target:delMod(xi.mod.LIGHT_ARTS_REGEN, regen)
        target:delMod(xi.mod.REGEN_DURATION, regen * 2)
    end

    target:recalculateSkillsTable()
end

local function darkGain(target, effect)
    if target:getObjType() ~= xi.objType.TRUST then
        target:recalculateAbilitiesTable()
    end

    local bonus = effect:getPower()
    local helix = effect:getSubPower()
    local extra = notTabula(target)
    applyBlackBonus(target, bonus, extra)
    if extra then
        target:addMod(xi.mod.HELIX_EFFECT, helix)
        target:addMod(xi.mod.HELIX_DURATION, 72)
    end

    if target:getObjType() ~= xi.objType.TRUST then
        target:recalculateSkillsTable()
    else
        local rankD    = target:getSkillLevel(xi.skill.ENFEEBLING_MAGIC)
        local artsRank = target:getMaxSkillLevel(target:getMainLvl(), xi.job.RDM, xi.skill.ENHANCING_MAGIC)
        target:addMod(xi.mod.MACC, artsRank - rankD)
    end
end

local function darkLose(target, effect)
    if target:getObjType() ~= xi.objType.TRUST then
        target:recalculateAbilitiesTable()
    end

    local bonus = effect:getPower()
    local helix = effect:getSubPower()
    local extra = notTabula(target)
    removeBlackBonus(target, bonus, extra)
    if extra then
        target:delMod(xi.mod.HELIX_EFFECT, helix)
        target:delMod(xi.mod.HELIX_DURATION, 72)
    end

    if target:getObjType() ~= xi.objType.TRUST then
        target:recalculateSkillsTable()
    else
        local rankD    = target:getSkillLevel(xi.skill.ENFEEBLING_MAGIC)
        local artsRank = target:getMaxSkillLevel(target:getMainLvl(), xi.job.RDM, xi.skill.ENHANCING_MAGIC)
        target:delMod(xi.mod.MACC, artsRank - rankD)
    end
end

-- Tabula Rasa used -30 on the off-school to cancel the old +20 tax and leave -10.
-- With no tax, -10 on the off-school is the same net TR bonus.
local function tabulaGain(target, effect)
    local regen = effect:getSubPower()
    local helix = effect:getPower()
    if
        target:hasStatusEffect(xi.effect.LIGHT_ARTS) or
        target:hasStatusEffect(xi.effect.ADDENDUM_WHITE)
    then
        target:addMod(xi.mod.BLACK_MAGIC_COST, -10)
        target:addMod(xi.mod.BLACK_MAGIC_CAST, -10)
        target:addMod(xi.mod.BLACK_MAGIC_RECAST, -10)
        target:addMod(xi.mod.LIGHT_ARTS_REGEN, math.ceil(regen / 1.5))
        target:addMod(xi.mod.REGEN_DURATION, math.ceil((regen * 2) / 1.5))
        target:addMod(xi.mod.HELIX_EFFECT, helix)
        target:addMod(xi.mod.HELIX_DURATION, 108)
    elseif
        target:hasStatusEffect(xi.effect.DARK_ARTS) or
        target:hasStatusEffect(xi.effect.ADDENDUM_BLACK)
    then
        target:addMod(xi.mod.WHITE_MAGIC_COST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_CAST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_RECAST, -10)
        target:addMod(xi.mod.LIGHT_ARTS_REGEN, regen)
        target:addMod(xi.mod.REGEN_DURATION, regen * 2)
        target:addMod(xi.mod.HELIX_EFFECT, math.ceil(helix / 1.5))
        target:addMod(xi.mod.HELIX_DURATION, 36)
    else
        target:addMod(xi.mod.BLACK_MAGIC_COST, -10)
        target:addMod(xi.mod.BLACK_MAGIC_CAST, -10)
        target:addMod(xi.mod.BLACK_MAGIC_RECAST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_COST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_CAST, -10)
        target:addMod(xi.mod.WHITE_MAGIC_RECAST, -10)
        target:addMod(xi.mod.LIGHT_ARTS_REGEN, regen)
        target:addMod(xi.mod.REGEN_DURATION, regen * 2)
        target:addMod(xi.mod.HELIX_EFFECT, helix)
        target:addMod(xi.mod.HELIX_DURATION, 108)
    end
end

local function tabulaLose(target, effect)
    local regen = effect:getSubPower()
    local helix = effect:getPower()
    if
        target:hasStatusEffect(xi.effect.LIGHT_ARTS) or
        target:hasStatusEffect(xi.effect.ADDENDUM_WHITE)
    then
        target:delMod(xi.mod.BLACK_MAGIC_COST, -10)
        target:delMod(xi.mod.BLACK_MAGIC_CAST, -10)
        target:delMod(xi.mod.BLACK_MAGIC_RECAST, -10)
        target:delMod(xi.mod.LIGHT_ARTS_REGEN, math.ceil(regen / 1.5))
        target:delMod(xi.mod.REGEN_DURATION, math.ceil((regen * 2) / 1.5))
        target:delMod(xi.mod.HELIX_EFFECT, helix)
        target:delMod(xi.mod.HELIX_DURATION, 108)
    elseif
        target:hasStatusEffect(xi.effect.DARK_ARTS) or
        target:hasStatusEffect(xi.effect.ADDENDUM_BLACK)
    then
        target:delMod(xi.mod.WHITE_MAGIC_COST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_CAST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_RECAST, -10)
        target:delMod(xi.mod.LIGHT_ARTS_REGEN, regen)
        target:delMod(xi.mod.REGEN_DURATION, regen * 2)
        target:delMod(xi.mod.HELIX_EFFECT, math.ceil(helix / 1.5))
        target:delMod(xi.mod.HELIX_DURATION, 36)
    else
        target:delMod(xi.mod.BLACK_MAGIC_COST, -10)
        target:delMod(xi.mod.BLACK_MAGIC_CAST, -10)
        target:delMod(xi.mod.BLACK_MAGIC_RECAST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_COST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_CAST, -10)
        target:delMod(xi.mod.WHITE_MAGIC_RECAST, -10)
        target:delMod(xi.mod.LIGHT_ARTS_REGEN, regen)
        target:delMod(xi.mod.REGEN_DURATION, regen * 2)
        target:delMod(xi.mod.HELIX_EFFECT, helix)
        target:delMod(xi.mod.HELIX_DURATION, 108)
    end
end

m:addOverride('xi.effects.light_arts.onEffectGain', function(target, effect)
    lightGain(target, effect)
end)

m:addOverride('xi.effects.light_arts.onEffectLose', function(target, effect)
    lightLose(target, effect)
end)

m:addOverride('xi.effects.addendum_white.onEffectGain', function(target, effect)
    lightGain(target, effect)
end)

m:addOverride('xi.effects.addendum_white.onEffectLose', function(target, effect)
    lightLose(target, effect)
end)

m:addOverride('xi.effects.dark_arts.onEffectGain', function(target, effect)
    darkGain(target, effect)
end)

m:addOverride('xi.effects.dark_arts.onEffectLose', function(target, effect)
    darkLose(target, effect)
end)

m:addOverride('xi.effects.addendum_black.onEffectGain', function(target, effect)
    darkGain(target, effect)
end)

m:addOverride('xi.effects.addendum_black.onEffectLose', function(target, effect)
    darkLose(target, effect)
end)

m:addOverride('xi.effects.tabula_rasa.onEffectGain', function(target, effect)
    tabulaGain(target, effect)
end)

m:addOverride('xi.effects.tabula_rasa.onEffectLose', function(target, effect)
    tabulaLose(target, effect)
end)

return m
