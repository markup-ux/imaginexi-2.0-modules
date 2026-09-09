-----------------------------------
-- Imagine XI 2.0: Drain / Aspir potency + Aspir floor
-- Stock Drain/Aspir ignore DARK_POWER (that setting only hits dark nukes
-- such as Bio). This module applies it on Drain/Aspir, with a 1.5 default
-- so the spells feel useful without buffing Bio.
-- Aspir also has a skill-based floor after resist so a landed cast is not
-- a 15 MP return. Still clamped to the target's remaining MP and the
-- caster's missing MP. Undead / dark absorb / empty pool stay no-effect.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_drain_aspir')

-- Drain/Aspir only. Stacks with settings DARK_POWER (stock default 1.0).
local DRAIN_ASPIR_POWER = 1.5

local aspirFloorSpec =
{
    [xi.magic.spell.ASPIR] =
    {
        skill = 0.4,
        base  = 25,
    },
    [xi.magic.spell.ASPIR_II] =
    {
        skill = 0.55,
        base  = 35,
    },
    [xi.magic.spell.ASPIR_III] =
    {
        skill = 0.75,
        base  = 45,
    },
}

local function drainAspirPower()
    return DRAIN_ASPIR_POWER * (xi.settings.main.DARK_POWER or 1)
end

local function powerBonusPercent(caster)
    local power = drainAspirPower()
    if power <= 1 then
        return 0
    end

    -- Raising ENH_DRAIN_ASPIR by this percent multiplies the whole product
    -- (resist, weather, gear, and so on) by `power`.
    local absorbMult = 1 + caster:getMod(xi.mod.AUGMENTS_ABSORB) / 100 + caster:getMod(xi.mod.ENH_DRAIN_ASPIR) / 100
    return math.floor(absorbMult * (power - 1) * 100 + 0.5)
end

local function aspirFloor(caster, spellId)
    local spec = aspirFloorSpec[spellId]
    if not spec then
        return 0
    end

    return math.floor(caster:getSkillLevel(xi.skill.DARK_MAGIC) * spec.skill + spec.base)
end

m:addOverride('xi.spells.absorb.doDrainingSpell', function(caster, target, spell)
    local spellId  = spell:getID()
    local bonusPct = powerBonusPercent(caster)

    if bonusPct > 0 then
        caster:addMod(xi.mod.ENH_DRAIN_ASPIR, bonusPct)
    end

    local result = super(caster, target, spell)

    if bonusPct > 0 then
        caster:delMod(xi.mod.ENH_DRAIN_ASPIR, bonusPct)
    end

    -- Floor only after a landed Aspir. Full resist / undead / empty pool stay 0.
    if
        result <= 0 or
        not aspirFloorSpec[spellId]
    then
        return result
    end

    local bonus = math.min(
        aspirFloor(caster, spellId) - result,
        caster:getMaxMP() - caster:getMP(),
        target:getMP()
    )

    if bonus > 0 then
        local added = caster:addMP(bonus)
        if added > 0 then
            target:delMP(added)
            result = result + added
        end
    end

    return result
end)
