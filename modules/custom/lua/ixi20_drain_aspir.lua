-----------------------------------
-- Imagine XI 2.0: Drain / Aspir return a % of the caster's max pool
-- Players steal a fixed percent of their own max HP (Drain) or MP
-- (Aspir). Still clamped to what the target has left, so a 50-HP
-- goblin cannot fund a 200-HP heal. Mob casters use the same % of the
-- target's current pool so high-HP NMs do not one-shot. Resist,
-- weather, staff, absorb gear, and Nether Void still apply. Undead /
-- dark absorb / empty pool stay no-effect. Drain II / III max-HP
-- overflow is stock.
-- FileWatcher drops addOverride; assignment wrap stays live.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/spells/absorb_spell')
require('scripts/globals/spells/damage_spell')
-----------------------------------

local m = Module:new('ixi20_drain_aspir')

-- Player: % of caster max HP/MP. Mob: same number as % of target current.
local absorbPercent =
{
    [xi.magic.spell.DRAIN]     = 20,
    [xi.magic.spell.DRAIN_II]  = 30,
    [xi.magic.spell.DRAIN_III] = 40,
    [xi.magic.spell.ASPIR]     = 25,
    [xi.magic.spell.ASPIR_II]  = 35,
    [xi.magic.spell.ASPIR_III] = 50,
}

local function doDrainingSpell(caster, target, spell)
    local spellId = spell:getID()
    local percent = absorbPercent[spellId]
    if not percent then
        return xi.spells.absorb._ixi20StockDrainingSpell(caster, target, spell)
    end

    local finalDamage  = 0
    local spellData    = xi.spells.absorb.absorbPointsData[spellId]
    local modAbsorbed  = spellData[1]
    local targetPoints = target:getHP()
    local displayCap   = caster:getMaxHP() - caster:getHP()

    if modAbsorbed == xi.mod.MP then
        targetPoints = target:getMP()
        displayCap   = caster:getMaxMP() - caster:getMP()
    end

    if target:isUndead() then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
        return finalDamage
    end

    if
        xi.spells.damage.calculateAbsorption(target, xi.element.DARK, false, true, false, false) ~= 1 or
        xi.spells.damage.calculateNullification(target, xi.element.DARK, false, true, false, false) ~= 1
    then
        spell:setMsg(xi.msg.basic.MAGIC_RESIST)
        return finalDamage
    end

    if targetPoints == 0 then
        spell:setMsg(xi.msg.basic.NO_EFFECT)
        return finalDamage
    end

    local casterPool = caster:getMaxHP()
    if modAbsorbed == xi.mod.MP then
        casterPool = caster:getMaxMP()
    end

    -- Players scale off their own pool so trash is not a 20-HP Drain.
    -- Mobs scale off the target so a 200k HP NM is not a 40k Drain.
    local pool = targetPoints
    if caster.isPC and caster:isPC() then
        pool = casterPool
    end

    local baseDamage = math.max(1, math.floor(pool * percent / 100))

    local maccParams =
    {
        magicalElement = xi.element.DARK,
        actorStat      = xi.mod.INT,
        skillType      = xi.skill.DARK_MAGIC,
        spellGroup     = xi.magic.spellGroup.BLACK,
    }

    local resistTier             = xi.combat.magicHitRate.calculateResistRate(caster, target, maccParams)
    local additionalResistTier   = xi.spells.damage.calculateAdditionalResistTier(caster, target, xi.element.DARK)
    local sdt                    = xi.combat.damage.magicalElementSDT(target, xi.element.DARK)
    local elementalStaffBonus    = xi.spells.damage.calculateElementalStaffBonus(caster, xi.element.DARK)
    local elementalAffinityBonus = xi.spells.damage.calculateElementalAffinityBonus(caster, xi.element.DARK)
    local dayAndWeather          = xi.spells.damage.calculateDayAndWeather(caster, xi.element.DARK, false)
    local absorbMultiplier       = 1 + caster:getMod(xi.mod.AUGMENTS_ABSORB) / 100 + caster:getMod(xi.mod.ENH_DRAIN_ASPIR) / 100
    local liberatorMultiplier    = 1 + caster:getMod(xi.mod.AUGMENTS_ABSORB_LIBERATOR) / 100
    local netherVoidMultiplier   = 1
    if caster:hasStatusEffect(xi.effect.NETHER_VOID) then
        netherVoidMultiplier = 1 + caster:getStatusEffect(xi.effect.NETHER_VOID):getPower() / 100
    end

    finalDamage = math.floor(baseDamage * resistTier)
    finalDamage = math.floor(finalDamage * additionalResistTier)
    finalDamage = math.floor(finalDamage * sdt)
    finalDamage = math.floor(finalDamage * elementalStaffBonus)
    finalDamage = math.floor(finalDamage * elementalAffinityBonus)
    finalDamage = math.floor(finalDamage * dayAndWeather)
    finalDamage = math.floor(finalDamage * absorbMultiplier)
    finalDamage = math.floor(finalDamage * liberatorMultiplier)
    finalDamage = math.floor(finalDamage * netherVoidMultiplier)

    if modAbsorbed == xi.mod.HP then
        finalDamage = utils.clamp(utils.handlePhalanx(target, finalDamage), 0, 99999)
        finalDamage = utils.clamp(utils.handleOneForAll(target, finalDamage), 0, 99999)
        finalDamage = utils.handleStoneskin(target, finalDamage, xi.attackType.MAGICAL)
        finalDamage = utils.clamp(finalDamage, 0, targetPoints)
        finalDamage = target:checkDamageCap(finalDamage)

        target:takeSpellDamage(caster, spell, finalDamage, xi.attackType.MAGICAL, xi.damageType.DARK)
        target:handleAfflatusMiseryDamage(finalDamage)
        target:updateEnmityFromDamage(caster, finalDamage)
    else
        finalDamage = utils.clamp(finalDamage, 0, targetPoints)
    end

    if spellData[5] then
        displayCap = 9999 - caster:getHP()

        local overflow = finalDamage + caster:getHP() - caster:getMaxHP()
        if overflow > 0 then
            local hasMaxHPEffect      = caster:hasStatusEffect(xi.effect.MAX_HP_BOOST)
            local maxHPEffectPower    = 0
            local maxHPEffectSubpower = 0

            if hasMaxHPEffect then
                maxHPEffectPower    = caster:getStatusEffect(xi.effect.MAX_HP_BOOST):getPower()
                maxHPEffectSubpower = caster:getStatusEffect(xi.effect.MAX_HP_BOOST):getSubPower()
            end

            if
                not hasMaxHPEffect or
                (maxHPEffectPower == 0 and
                maxHPEffectSubpower < overflow)
            then
                local duration = 180 + 180 * caster:getMod(xi.mod.DARK_MAGIC_DURATION) / 100
                caster:delStatusEffect(xi.effect.MAX_HP_BOOST)
                caster:addStatusEffect(xi.effect.MAX_HP_BOOST, { duration = duration, origin = caster, subPower = overflow })
            end
        end
    end

    if modAbsorbed == xi.mod.HP then
        caster:addHP(finalDamage)
    else
        caster:addMP(finalDamage)
        target:delMP(finalDamage)
    end

    return utils.clamp(finalDamage, 0, displayCap)
end

if not xi.spells.absorb._ixi20StockDrainingSpell then
    xi.spells.absorb._ixi20StockDrainingSpell = xi.spells.absorb.doDrainingSpell
end

m:addOverride('xi.spells.absorb.doDrainingSpell', doDrainingSpell)

if not xi.spells.absorb._ixi20DrainAspir then
    xi.spells.absorb._ixi20DrainAspir = true
end

xi.spells.absorb.doDrainingSpell = doDrainingSpell
