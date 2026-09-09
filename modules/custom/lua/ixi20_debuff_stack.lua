-----------------------------------
-- Imagine XI 2.0: Dia stacks with Bio. Different source families of the
-- same debuff stack. Same family still overwrites (not per person).
-- Magic Poison/II/III | Dokumori | ammo | melee AE | each weaponskill.
-- Same pattern for Slow/Hojo, Paralyze/Jubaku, Blind/Kurayami.
-- All six elemental DoTs stack (no Burn/Frost cycle). Helixes stack by element.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_debuff_stack')

local FAMILY_SOURCE_TYPE = 32

local FAMILY =
{
    UNTAGGED = 0,
    MAGIC    = 1,
    NINJUTSU = 2,
    RANGED   = 3,
    MELEE    = 4,
    WS       = 1000,
    HELIX    = 200,
}

local STACKABLE =
{
    [xi.effect.POISON]    = true,
    [xi.effect.SLOW]      = true,
    [xi.effect.PARALYSIS] = true,
    [xi.effect.BLINDNESS] = true,
    [xi.effect.HELIX]     = true,
}

local ELEMENTAL_DOT =
{
    [xi.effect.BURN]  = true,
    [xi.effect.FROST] = true,
    [xi.effect.CHOKE] = true,
    [xi.effect.RASP]  = true,
    [xi.effect.SHOCK] = true,
    [xi.effect.DROWN] = true,
}

local HELIX_SPELL =
{
    [xi.magic.spell.GEOHELIX]       = true,
    [xi.magic.spell.GEOHELIX_II]    = true,
    [xi.magic.spell.HYDROHELIX]     = true,
    [xi.magic.spell.HYDROHELIX_II]  = true,
    [xi.magic.spell.ANEMOHELIX]     = true,
    [xi.magic.spell.ANEMOHELIX_II]  = true,
    [xi.magic.spell.PYROHELIX]      = true,
    [xi.magic.spell.PYROHELIX_II]   = true,
    [xi.magic.spell.CRYOHELIX]      = true,
    [xi.magic.spell.CRYOHELIX_II]   = true,
    [xi.magic.spell.IONOHELIX]      = true,
    [xi.magic.spell.IONOHELIX_II]   = true,
    [xi.magic.spell.NOCTOHELIX]     = true,
    [xi.magic.spell.NOCTOHELIX_II]  = true,
    [xi.magic.spell.LUMINOHELIX]    = true,
    [xi.magic.spell.LUMINOHELIX_II] = true,
}

local pendingFamily = 0
local pendingWsId   = 0

local function setFamily(family)
    pendingFamily = family or 0
    if Ixi20DebuffStackSetFamily then
        Ixi20DebuffStackSetFamily(pendingFamily)
    end
end

local function familyOf(effect)
    local sub = effect:getSubType()
    if sub ~= 0 then
        return sub
    end

    if effect:getSourceType() == FAMILY_SOURCE_TYPE then
        return effect:getSourceTypeParam()
    end

    return FAMILY.UNTAGGED
end

local function findFamilyEffect(target, effectId, family)
    for _, effect in ipairs(target:getStatusEffects()) do
        if effect:getEffectType() == effectId and familyOf(effect) == family then
            return effect
        end
    end

    return nil
end

local function removeFamily(target, effectId, family)
    local existing = findFamilyEffect(target, effectId, family)
    if not existing then
        return
    end

    local sub = existing:getSubType()
    if sub ~= 0 then
        target:delStatusEffect(effectId, sub)
        return
    end

    if existing:getSourceType() == FAMILY_SOURCE_TYPE then
        target:delStatusEffect(effectId, nil, FAMILY_SOURCE_TYPE, family)
    end
end

local function stampFamily(target, effectId, family)
    if not family or family == FAMILY.UNTAGGED then
        return
    end

    for _, effect in ipairs(target:getStatusEffects()) do
        if effect:getEffectType() == effectId and familyOf(effect) == FAMILY.UNTAGGED then
            effect:setSource(FAMILY_SOURCE_TYPE, family)
        end
    end
end

local function familyForSpell(spell)
    if HELIX_SPELL[spell:getID()] then
        return FAMILY.HELIX + spell:getElement()
    end

    if spell:getSkillType() == xi.skill.NINJUTSU then
        return FAMILY.NINJUTSU
    end

    return FAMILY.MAGIC
end

local function familyForItem(item)
    if not item or not item.getSkillType then
        return FAMILY.MELEE
    end

    local skill = item:getSkillType()
    if
        skill == xi.skill.ARCHERY or
        skill == xi.skill.MARKSMANSHIP or
        skill == xi.skill.THROWING
    then
        return FAMILY.RANGED
    end

    return FAMILY.MELEE
end

m:addOverride('xi.data.statusEffect.getNullificatingEffect', function(effectId)
    if ELEMENTAL_DOT[effectId] then
        return 0
    end

    return super(effectId)
end)

m:addOverride('xi.data.statusEffect.getEffectToRemove', function(effectId)
    if ELEMENTAL_DOT[effectId] then
        return 0
    end

    return super(effectId)
end)

m:addOverride('xi.data.statusEffect.getNullificatingEffectByTier', function(effectId)
    if effectId == xi.effect.DIA or effectId == xi.effect.BIO then
        return 0
    end

    return super(effectId)
end)

m:addOverride('xi.data.statusEffect.isEffectNullified', function(target, effectId, effectTier)
    if effectId == xi.effect.DIA or effectId == xi.effect.BIO or ELEMENTAL_DOT[effectId] then
        local always = xi.data.statusEffect.getNullificatingEffect(effectId)
        if always > 0 and target:hasStatusEffect(always) then
            return true
        end

        if effectTier ~= 0 and target:hasStatusEffect(effectId) then
            local existing = target:getStatusEffect(effectId)
            if existing and existing:getTier() >= effectTier then
                return true
            end
        end

        return false
    end

    if STACKABLE[effectId] then
        local always = xi.data.statusEffect.getNullificatingEffect(effectId)
        if always > 0 and target:hasStatusEffect(always) then
            return true
        end

        if effectTier ~= 0 then
            local existing = findFamilyEffect(target, effectId, pendingFamily)
            if existing and existing:getTier() >= effectTier then
                return true
            end
        end

        return false
    end

    return super(target, effectId, effectTier)
end)

local SPELL_EFFECT =
{
    [xi.magic.spell.POISON]         = xi.effect.POISON,
    [xi.magic.spell.POISON_II]      = xi.effect.POISON,
    [xi.magic.spell.POISON_III]     = xi.effect.POISON,
    [xi.magic.spell.POISONGA]       = xi.effect.POISON,
    [xi.magic.spell.POISONGA_II]    = xi.effect.POISON,
    [xi.magic.spell.POISONGA_III]   = xi.effect.POISON,
    [xi.magic.spell.DOKUMORI_ICHI]  = xi.effect.POISON,
    [xi.magic.spell.DOKUMORI_NI]    = xi.effect.POISON,
    [xi.magic.spell.DOKUMORI_SAN]   = xi.effect.POISON,
    [xi.magic.spell.SLOW]           = xi.effect.SLOW,
    [xi.magic.spell.SLOW_II]        = xi.effect.SLOW,
    [xi.magic.spell.SLOWGA]         = xi.effect.SLOW,
    [xi.magic.spell.HOJO_ICHI]      = xi.effect.SLOW,
    [xi.magic.spell.HOJO_NI]        = xi.effect.SLOW,
    [xi.magic.spell.HOJO_SAN]       = xi.effect.SLOW,
    [xi.magic.spell.PARALYZE]       = xi.effect.PARALYSIS,
    [xi.magic.spell.PARALYZE_II]    = xi.effect.PARALYSIS,
    [xi.magic.spell.PARALYGA]       = xi.effect.PARALYSIS,
    [xi.magic.spell.JUBAKU_ICHI]    = xi.effect.PARALYSIS,
    [xi.magic.spell.JUBAKU_NI]      = xi.effect.PARALYSIS,
    [xi.magic.spell.JUBAKU_SAN]     = xi.effect.PARALYSIS,
    [xi.magic.spell.BLIND]          = xi.effect.BLINDNESS,
    [xi.magic.spell.BLIND_II]       = xi.effect.BLINDNESS,
    [xi.magic.spell.BLINDGA]        = xi.effect.BLINDNESS,
    [xi.magic.spell.KURAYAMI_ICHI]  = xi.effect.BLINDNESS,
    [xi.magic.spell.KURAYAMI_NI]    = xi.effect.BLINDNESS,
    [xi.magic.spell.KURAYAMI_SAN]   = xi.effect.BLINDNESS,
}

m:addOverride('xi.spells.enfeebling.useEnfeeblingSpell', function(caster, target, spell)
    local family   = familyForSpell(spell)
    local effectId = HELIX_SPELL[spell:getID()] and xi.effect.HELIX or SPELL_EFFECT[spell:getID()]
    setFamily(family)
    if effectId and STACKABLE[effectId] then
        removeFamily(target, effectId, family)
    end

    local result = super(caster, target, spell)
    if result and STACKABLE[result] then
        stampFamily(target, result, family)
    end

    setFamily(0)
    return result
end)

m:addOverride('xi.weaponskills.doPhysicalWeaponskill', function(attacker, target, wsID, ...)
    pendingWsId = wsID or 0
    return super(attacker, target, wsID, ...)
end)

m:addOverride('xi.weaponskills.doMagicWeaponskill', function(attacker, target, wsID, ...)
    pendingWsId = wsID or 0
    return super(attacker, target, wsID, ...)
end)

m:addOverride('xi.weaponskills.handleWeaponskillEffect', function(actor, target, effectId, actionElement, damage, power, duration)
    if not STACKABLE[effectId] then
        return super(actor, target, effectId, actionElement, damage, power, duration)
    end

    if
        damage <= 0 or
        xi.data.statusEffect.isTargetImmune(target, effectId, actionElement) or
        xi.data.statusEffect.isTargetResistant(actor, target, effectId)
    then
        return
    end

    local family = FAMILY.WS + (pendingWsId or 0)
    setFamily(family)
    if xi.data.statusEffect.isEffectNullified(target, effectId, 0) then
        setFamily(0)
        return
    end

    removeFamily(target, effectId, family)
    target:addStatusEffect(effectId, {
        power    = power,
        duration = duration,
        origin   = actor,
        subType  = family,
    })
    setFamily(0)
end)

m:addOverride('xi.combat.action.executeAddEffectEnfeeblement', function(actor, target, fedData)
    fedData = fedData or {}
    if STACKABLE[fedData.effectId] and (fedData.subType or 0) == 0 then
        fedData.subType = fedData.isRanged and FAMILY.RANGED or FAMILY.MELEE
    end

    setFamily(fedData.subType or 0)
    if STACKABLE[fedData.effectId] then
        removeFamily(target, fedData.effectId, fedData.subType or 0)
    end

    local anim, msg, effectId = super(actor, target, fedData)
    setFamily(0)
    return anim, msg, effectId
end)

do
    local origDebuff = xi.additionalEffect.procFunctions[xi.additionalEffect.procType.DEBUFF]
    xi.additionalEffect.procFunctions[xi.additionalEffect.procType.DEBUFF] = function(actor, target, item, params)
        local family   = familyForItem(item)
        local effectId = params and (params.effect or params.effectId)
        setFamily(family)
        if effectId and STACKABLE[effectId] then
            removeFamily(target, effectId, family)
        end

        local subEffect, msg, appliedId = origDebuff(actor, target, item, params)
        if appliedId and STACKABLE[appliedId] then
            stampFamily(target, appliedId, family)
        elseif effectId and STACKABLE[effectId] then
            stampFamily(target, effectId, family)
        end

        setFamily(0)
        return subEffect, msg, appliedId
    end
end

local helixPaths =
{
    'xi.actions.spells.black.geohelix.onSpellCast',
    'xi.actions.spells.black.geohelix_ii.onSpellCast',
    'xi.actions.spells.black.hydrohelix.onSpellCast',
    'xi.actions.spells.black.hydrohelix_ii.onSpellCast',
    'xi.actions.spells.black.anemohelix.onSpellCast',
    'xi.actions.spells.black.anemohelix_ii.onSpellCast',
    'xi.actions.spells.black.pyrohelix.onSpellCast',
    'xi.actions.spells.black.pyrohelix_ii.onSpellCast',
    'xi.actions.spells.black.cryohelix.onSpellCast',
    'xi.actions.spells.black.cryohelix_ii.onSpellCast',
    'xi.actions.spells.black.ionohelix.onSpellCast',
    'xi.actions.spells.black.ionohelix_ii.onSpellCast',
    'xi.actions.spells.black.noctohelix.onSpellCast',
    'xi.actions.spells.black.noctohelix_ii.onSpellCast',
    'xi.actions.spells.black.luminohelix.onSpellCast',
    'xi.actions.spells.black.luminohelix_ii.onSpellCast',
}

for _, path in ipairs(helixPaths) do
    m:addOverride(path, function(caster, target, spell)
        setFamily(FAMILY.HELIX + spell:getElement())
        local result = super(caster, target, spell)
        setFamily(0)
        return result
    end)
end

local elementalGain =
{
    { 'xi.effects.burn.onEffectGain',  xi.mod.INT },
    { 'xi.effects.frost.onEffectGain', xi.mod.AGI },
    { 'xi.effects.choke.onEffectGain', xi.mod.VIT },
    { 'xi.effects.rasp.onEffectGain',  xi.mod.DEX },
    { 'xi.effects.shock.onEffectGain', xi.mod.MND },
    { 'xi.effects.drown.onEffectGain', xi.mod.STR },
}

for _, row in ipairs(elementalGain) do
    m:addOverride(row[1], function(target, effect)
        local statReduction = (effect:getPower() - 1) * 2 + 5
        effect:addMod(xi.mod.REGEN_DOWN, effect:getPower())
        effect:addMod(row[2], -statReduction)
    end)
end

m:addOverride('xi.actions.spells.white.poisona.onSpellCast', function(caster, target, spell)
    local removed = false
    while target:hasStatusEffect(xi.effect.POISON) do
        if not target:delStatusEffect(xi.effect.POISON) then
            break
        end

        removed = true
    end

    if removed then
        spell:setMsg(xi.msg.basic.MAGIC_REMOVE_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.POISON
end)

return m
