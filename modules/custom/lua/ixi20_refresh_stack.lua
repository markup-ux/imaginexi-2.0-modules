-----------------------------------
-- Imagine XI 2.0: Refresh I and II add on one effect (cap 9)
-- Same tier recasts refresh duration and keep the combined power.
-- Two Refresh IIs do not pile. SCH I still counts next to RDM II.
-- Sublimation stacks (see ixi20_sublimation_stack). One icon (xi.effect.REFRESH).
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_refresh_stack')

local SPELL_CAP = 9

local REFRESH_TIER =
{
    [xi.magic.spell.REFRESH]     = 1,
    [xi.magic.spell.REFRESH_II]  = 2,
    [xi.magic.spell.REFRESH_III] = 3,
}

local function tierBit(tier)
    return bit.lshift(1, math.max(tier or 1, 1) - 1)
end

local function bitsFromEffect(effect)
    local bits = effect:getSubPower()
    if bits > 0 then
        return bits
    end

    return tierBit(effect:getTier())
end

m:addOverride('xi.spells.enhancing.useEnhancingSpell', function(caster, target, spell)
    local spellId = spell:getID()
    local tier    = REFRESH_TIER[spellId]
    if not tier then
        return super(caster, target, spell)
    end

    local spellEffect = xi.effect.REFRESH
    local spellGroup  = spell:getSpellGroup()

    local basePower  = xi.spells.enhancing.calculateEnhancingBasePower(caster, target, spell, spellId, spellEffect)
    local finalPower = xi.spells.enhancing.calculateEnhancingFinalPower(caster, target, spell, basePower, spellGroup, tier, spellEffect)
    local duration   = xi.spells.enhancing.calculateEnhancingDuration(caster, target, spell, spellId, spellGroup, spellEffect)

    if
        not caster:isPet() and
        target:hasStatusEffect(xi.effect.EMBOLDEN) and
        spellGroup == xi.magic.spellGroup.WHITE
    then
        target:delStatusEffectSilent(xi.effect.EMBOLDEN)
    end

    local existing     = target:getStatusEffect(spellEffect)
    local newBit       = tierBit(tier)
    local combinedBits = newBit
    local combinedPower = finalPower
    local combinedTier  = tier

    if existing then
        local oldBits = bitsFromEffect(existing)
        combinedBits  = bit.bor(oldBits, newBit)
        combinedTier  = math.max(existing:getTier(), tier)

        if bit.band(oldBits, newBit) ~= 0 then
            combinedPower = math.max(existing:getPower(), finalPower)
        else
            combinedPower = math.min(existing:getPower() + finalPower, SPELL_CAP)
        end
    end

    target:delStatusEffectSilent(spellEffect)
    target:addStatusEffect(spellEffect, {
        power    = combinedPower,
        duration = duration,
        origin   = caster,
        subPower = combinedBits,
        tier     = combinedTier,
    })

    spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)

    return spellEffect
end)

return m
