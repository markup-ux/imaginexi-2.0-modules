-----------------------------------
-- Imagine XI 2.0: Blue Magic damage formulas
-- Physical: skill-based attack, potency Acc folded into attack, CA Acc
--   converted to attack (always-hit), Cannonball DEF * attack mods,
--   per-hit shadows, family bonus stays +/-0.25 on fTP.
-- Magical: dSTAT inside D, skill D-cap floor, MDT / nuke wall / affinity
--   / the rest of the nuke list, BLUE_POWER once.
-- Breath: max HP, no NIN multipliers, BLUE_POWER once.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/bluemagic')
require('scripts/globals/spells/damage_spell')
-----------------------------------

local m = Module:new('ixi20_blu_damage')

-- Physical pDIF uses Blue skill + STR instead of main-hand weapon attack.
xi.settings.main.BLUE_SKILL_IS_BLUE_ATTACK = true

local SKILL_D_CAP_RATE = 0.25 -- max(spell cap, floor(skill * this))

-----------------------------------
-- Shared helpers (stock copies; those functions are local in bluemagic.lua)
-----------------------------------

local function calculateAlpha(level)
    if level <= 60 then
        return math.ceil(100 - level / 6) / 100
    elseif level <= 75 then
        return math.ceil(100 - (level - 40) / 2) / 100
    end

    return 0.83
end

local function calculateWSC(attacker, params)
    local alpha = calculateAlpha(attacker:getMainLvl())
    local wsc   =
        attacker:getStat(xi.mod.STR) * (params.str_wsc or 0) +
        attacker:getStat(xi.mod.DEX) * (params.dex_wsc or 0) +
        attacker:getStat(xi.mod.VIT) * (params.vit_wsc or 0) +
        attacker:getStat(xi.mod.AGI) * (params.agi_wsc or 0) +
        attacker:getStat(xi.mod.INT) * (params.int_wsc or 0) +
        attacker:getStat(xi.mod.MND) * (params.mnd_wsc or 0) +
        attacker:getStat(xi.mod.CHR) * (params.chr_wsc or 0)

    return wsc * alpha
end

local function calculatefSTR(dSTR, level)
    if dSTR > 2 then
        return math.floor(math.min((dSTR + 4) / 4, math.floor((level / 5) + 7)))
    end

    return math.floor(math.max((dSTR + 8) / 4, (math.floor((level / 5) - 1) * -1)))
end

local function calculatefSTR2(dSTR, level)
    if dSTR > 24 then
        return math.floor(math.min((dSTR + 4) / 2, (math.floor((level / 5) + 7) * 2)))
    elseif dSTR > 2 then
        return math.floor((dSTR + 6) / 4)
    elseif dSTR > -21 then
        return math.floor((dSTR + 8) / 4)
    end

    return math.floor(math.max((dSTR + 10) / 4, (math.floor((level / 5) - 1) * -2)))
end

local function getPhysicalBlueMagicBaseDamage(caster, params)
    local multiplier = params.hasEfflux and 1.5 or 1
    local extraDmg   = 0

    if params.hasChainAffinity then
        extraDmg = caster:getMod(xi.mod.ENHANCES_CHAIN_AFFINITY)
    end

    return (math.floor(caster:getSkillLevel(xi.skill.BLUE_MAGIC) * 0.11) * 2 + 3) * multiplier + extraDmg
end

local function calculateCritChance(caster, target, params)
    if
        params.critChance ~= nil and
        (params.hasAzureLore or params.hasEfflux or params.hasChainAffinity)
    then
        local nativecrit = xi.combat.physical.calculateSwingCriticalRate(caster, target, 0, xi.slot.MAIN) - 0.05

        return utils.clamp(params.critChance / 100 + nativecrit, 0.00, 1.0)
    end

    return 0
end

local function getTPBonus(caster, params)
    local tp = 0

    if params.hasEfflux then
        tp = 1000
    end

    if params.hasChainAffinity then
        tp = utils.clamp(tp + caster:getTP() + caster:getMerit(xi.merit.ENCHAINMENT), 0, 3000)
    end

    return tp
end

local function getWSCBonuses(caster, params)
    local bonusWSC = 0

    if math.randomInt(1, 100) <= caster:getMod(xi.mod.AUGMENT_BLU_MAGIC) then
        bonusWSC = 2
    end

    if params.hasChainAffinity then
        bonusWSC = bonusWSC + 1
    end

    return bonusWSC
end

-- Acc-varies-with-TP is dead under ixi20_player_hit. Turn leftover Acc into attack.
local function accToAttackMult(params, attackMult)
    if params.tpModifier ~= xi.spells.blue.tpMod.ACC then
        return attackMult
    end

    local accBonus = params.bonusAcc or 0
    if accBonus <= 0 then
        return attackMult
    end

    return attackMult * (1 + accBonus / 256)
end

-- Physical Potency: +2 Acc per merit does nothing here; fold it into attack.
local function potencyAttackMod(caster)
    local meritValue = caster:getMerit(xi.merit.PHYSICAL_POTENCY) * 2

    return 1 + (meritValue * 2) / 256
end

local function calculateNukeWallFactor(target, spellElement, finalDamage)
    if
        not target:isNM() or
        spellElement <= xi.element.NONE or
        finalDamage < 0
    then
        return 1
    end

    local potency = 0
    local effect  = target:getStatusEffect(xi.effect.NUKE_WALL)

    if effect then
        potency = effect:getPower()

        if effect:getTimeRemaining() <= 4000 then
            potency = utils.clamp(potency - 2000, 0, 4000)
        end

        if target:hasStatusEffect(xi.effect.RAYKE) then
            local raykeSubpower = target:getStatusEffect(xi.effect.RAYKE):getSubPower()

            for i = 0, 16, 4 do
                if bit.band(bit.rshift(raykeSubpower, i), 0xF) == spellElement then
                    potency = math.floor(potency / 2)
                    break
                end
            end
        end

        target:delStatusEffectSilent(xi.effect.NUKE_WALL)
    end

    local damageCap    = target:getMainLvl() * 21 + 500
    local finalPotency = utils.clamp(math.floor(4000 * finalDamage / damageCap) + potency, 0, 4000)

    target:addStatusEffect(xi.effect.NUKE_WALL, { power = finalPotency, duration = 5, origin = target, icon = 0, subPower = spellElement })

    return 1 - potency / 10000
end

local function magicalDCap(caster, params)
    local levelD     = caster:getMainLvl() + 2
    local skillFloor = math.floor(caster:getSkillLevel(xi.skill.BLUE_MAGIC) * SKILL_D_CAP_RATE)
    local cap        = params.baseDamageCap or 0

    if cap <= 0 then
        return math.max(levelD, skillFloor)
    end

    return math.max(cap, skillFloor)
end

local function applyBurstAffinity(caster, target, spell, params, finalDamage, spellId, spellElement, skillType, skillchainCount)
    if
        not params.hasBurstAffinity and
        not params.hasAzureLore
    then
        return finalDamage
    end

    if skillchainCount > 0 then
        finalDamage = math.floor(finalDamage * xi.spells.damage.calculateIfMagicBurst(caster, target, spellElement, skillchainCount))
        finalDamage = math.floor(finalDamage * xi.spells.damage.calculateIfMagicBurstBonus(caster, target, spellId, skillType, spellElement))

        spell:setMsg(spell:getMagicBurstMessage())
        caster:triggerRoeEvent(xi.roeTrigger.MAGIC_BURST)
    end

    caster:delStatusEffectSilent(xi.effect.BURST_AFFINITY)

    return finalDamage
end

-----------------------------------
-- Physical
-----------------------------------

local function usePhysicalSpell(caster, target, spell, params)
    spell:setCritical(false)

    local isCannonball = spell:getID() == xi.magic.spell.CANNONBALL

    local initialD = utils.clamp(getPhysicalBlueMagicBaseDamage(caster, params), 0, params.baseDamageCap)
    local dSTR     = caster:getStat(xi.mod.STR) - target:getStat(xi.mod.VIT)
    local fStr     = 0

    if params.attackType == xi.attackType.RANGED then
        fStr = calculatefSTR2(dSTR, caster:getMainLvl())
    else
        fStr = calculatefSTR(dSTR, caster:getMainLvl())
    end

    if isCannonball then
        fStr = math.min(fStr, 22)
    end

    local ftp      = params.ftp0 or 1
    local bonusWSC = getWSCBonuses(caster, params)
    local tp       = getTPBonus(caster, params)

    if tp > 0 then
        ftp = xi.spells.blue.calculatefTP(tp, params.ftp0, params.ftp1500, params.ftp3000)
    end

    local wsc = calculateWSC(caster, params)
    wsc       = wsc + wsc * bonusWSC

    -- +/-0.25 on the spell multiplier, not a 25% product on final damage.
    local correlationBonus = xi.combat.damage.ecosystemMultiplier(caster, target, params.ecosystem or 0) - 1

    if params.hasAzureLore then
        ftp = params.ftpAzure
    end

    local finalD = math.floor(initialD + fStr + wsc)

    params.bonusAcc   = params.bonusAcc or 0
    params.critChance = calculateCritChance(caster, target, params)

    local spellAttackMod   = params.attackMult or 1
    local attackMultiplier = accToAttackMult(params, spellAttackMod * potencyAttackMod(caster))
    local applyLevelCorrection = xi.data.levelCorrection.isLevelCorrectedZone(caster)
    local hitrate = xi.combat.physicalHitRate.getPhysicalHitRate(caster, target, params.bonusAcc + caster:getMerit(xi.merit.PHYSICAL_POTENCY) * 2, xi.attackAnimation.RIGHT_ATTACK, false)

    local hitsdone          = 0
    local finaldmg          = 0
    local anyCrit           = false
    local sneakIsApplicable = false
    local trickAttackTarget = nil
    local shadowsAbsorbed   = 0

    if spell:isAoE() == 0 and params.attackType ~= xi.attackType.RANGED then
        if
            caster:hasStatusEffect(xi.effect.SNEAK_ATTACK) and
            (caster:isBehind(target) or caster:hasStatusEffect(xi.effect.HIDE))
        then
            sneakIsApplicable = true
        end

        if caster:hasStatusEffect(xi.effect.TRICK_ATTACK) then
            trickAttackTarget = caster:getTrickAttackChar(target)
        end
    end

    if
        target:hasStatusEffect(xi.effect.PERFECT_DODGE) or
        target:hasStatusEffect(xi.effect.ALL_MISS)
    then
        hitrate           = -1
        sneakIsApplicable = false
    end

    params.tpHitsLanded = 0
    params.hitsLanded   = 0

    -- Cannonball uses DEF in pDIF; scale that DEF by the same attack mods other physicals get.
    local cannonballDefTune = 0
    if isCannonball then
        local def    = caster:getStat(xi.mod.DEF)
        local scaled = math.max(1, math.floor(def * attackMultiplier))
        cannonballDefTune = scaled - def
        if cannonballDefTune ~= 0 then
            caster:addMod(xi.mod.DEF, cannonballDefTune)
        end
    end

    while hitsdone < params.numHits do
        local chance = math.randomFloat(0, 1)

        if
            sneakIsApplicable or
            chance <= hitrate
        then
            local absorbed = false
            if params.attackType ~= xi.attackType.RANGED then
                absorbed = utils.shadowAbsorb(target, 1)
            end

            if absorbed then
                shadowsAbsorbed = shadowsAbsorbed + 1
            else
                local isCritical = sneakIsApplicable or math.randomFloat(0, 1) < params.critChance
                local pdif       = xi.combat.physical.calculateMeleePDIF(caster, target, xi.skill.BLUE_MAGIC, attackMultiplier, isCritical, applyLevelCorrection, false, 0, false, xi.slot.MAIN, isCannonball)

                anyCrit = anyCrit or isCritical

                if hitsdone == 0 then
                    finaldmg = finaldmg + finalD * (ftp + correlationBonus) * pdif
                else
                    finaldmg = finaldmg + finalD * (1 + correlationBonus) * pdif
                end

                params.hitsLanded = params.hitsLanded + 1

                if finaldmg > 0 then
                    params.tpHitsLanded = params.tpHitsLanded + 1
                end
            end

            sneakIsApplicable = false
        end

        if params.attackType ~= xi.attackType.RANGED then
            caster:delStatusEffect(xi.effect.SNEAK_ATTACK)
            caster:delStatusEffect(xi.effect.TRICK_ATTACK)
        end

        hitsdone = hitsdone + 1
    end

    if cannonballDefTune ~= 0 then
        caster:delMod(xi.mod.DEF, cannonballDefTune)
    end

    finaldmg = math.floor(finaldmg * xi.combat.damage.calculateDamageAdjustment(target, true, false, false, false))

    if params.hitsLanded == 0 then
        if shadowsAbsorbed > 0 then
            spell:setMsg(xi.msg.basic.SHADOW_ABSORB)
        else
            spell:setMsg(xi.msg.basic.MAGIC_FAIL)
        end
    end

    if anyCrit and params.hitsLanded > 0 then
        target:triggerListener('CRITICAL_TAKE', target, caster)
    end

    spell:setCritical(anyCrit)
    caster:delStatusEffectSilent(xi.effect.EFFLUX)

    return xi.spells.blue.applySpellDamage(caster, target, spell, finaldmg, params, trickAttackTarget)
end

-----------------------------------
-- Magical
-----------------------------------

local function useMagicalSpell(caster, target, spell, params)
    local spellId         = spell:getID()
    local spellElement    = spell:getElement()
    local spellGroup      = spell:getSpellGroup()
    local skillType       = xi.skill.BLUE_MAGIC
    local skillchainCount = xi.combat.magicBurst.getMagicBurstTier(target, spellElement)

    local initialD = utils.clamp(caster:getMainLvl() + 2, 0, magicalDCap(caster, params))
    local wsc      = calculateWSC(caster, params)
    local wscMultiplier = 1

    if math.randomInt(1, 100) <= caster:getMod(xi.mod.AUGMENT_BLU_MAGIC) then
        wscMultiplier = wscMultiplier + 1
    end

    if params.hasBurstAffinity then
        wscMultiplier = wscMultiplier + 1 + caster:getMod(xi.mod.ENHANCES_BURST_AFFINITY) / 100
    end

    wsc = wsc * wscMultiplier

    local statDiff   = caster:getStat(params.dStat) - target:getStat(params.dStat)
    local statBonus  = statDiff * (params.dStatMultiplier or 1)
    local azureBonus = params.hasAzureLore and (params.azureBonus or 0) or 0
    -- Same +/-0.25-on-multiplier rule as physical.
    local correlationBonus = xi.combat.damage.ecosystemMultiplier(caster, target, params.ecosystem or 0) - 1
    local ftp              = (params.ftp0 or 0) + azureBonus + correlationBonus

    local finalDamage = (initialD + wsc + statBonus) * ftp

    local maccParams =
    {
        magicalElement = spellElement,
        magicBurstTier = skillchainCount,
        actorStat      = params.dStat,
        skillType      = skillType,
        spellGroup     = spellGroup,
        bonusMacc      = params.bonusMacc or 0,
    }

    finalDamage = math.floor(finalDamage * xi.combat.magicHitRate.calculateResistRate(caster, target, maccParams))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateAdditionalResistTier(caster, target, spellElement))

    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateMTDR(caster, spell))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateElementalStaffBonus(caster, spellElement))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateElementalAffinityBonus(caster, spellElement))
    finalDamage = math.floor(finalDamage * xi.combat.damage.magicalElementSDT(target, spellElement))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateDayAndWeather(caster, spellElement, false))
    finalDamage = math.floor(finalDamage * xi.combat.damage.steamJacketMultiplier(target, spellElement))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateMagicBonusDiff(caster, target, spellId, skillType, spellElement, 0))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateMagicCriticalMultiplier(caster))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateEbullienceMultiplier(caster, spellGroup))
    finalDamage = math.floor(finalDamage * xi.combat.damage.scarletDeliriumMultiplier(caster))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateAreaOfEffectResistance(target, spell))
    finalDamage = math.floor(finalDamage * xi.spells.damage.calculateSpellActionTypeMultiplier(caster))

    finalDamage = applyBurstAffinity(caster, target, spell, params, finalDamage, spellId, spellElement, skillType, skillchainCount)

    finalDamage = math.floor(finalDamage * calculateNukeWallFactor(target, spellElement, finalDamage))

    -- Absorb, MDT, and BLUE_POWER land in applySpellDamage so 1000 Needles / Self-Destruct share them.
    return xi.spells.blue.applySpellDamage(caster, target, spell, finalDamage, params, nil)
end

-----------------------------------
-- Breath
-----------------------------------

local function useBreathSpell(caster, target, spell, params)
    if
        params.isConal and
        not target:isInfront(caster, 32)
    then
        return 0
    end

    local hpMod = params.hpMod or 1
    if hpMod == 0 then
        hpMod = 1
    end

    local dmg = caster:getMaxHP() / hpMod
    if params.lvlMod and params.lvlMod > 0 then
        dmg = dmg + caster:getMainLvl() / params.lvlMod
    end

    local spellId      = spell:getID() or 0
    local spellFamily  = spell:getSpellFamily() or 0
    local spellElement = spell:getElement() or 0
    local attackType   = params.attackType or xi.attackType.NONE
    local damageType   = params.damageType or xi.damageType.NONE

    local maccParams =
    {
        magicalElement = spellElement,
        skillType      = xi.skill.BLUE_MAGIC,
        spellGroup     = spellFamily,
    }

    dmg = math.floor(dmg * xi.combat.damage.ecosystemMultiplier(caster, target, params.ecosystem or 0))
    dmg = math.floor(dmg * (1 + caster:getMod(xi.mod.BREATH_DMG_DEALT) / 100))
    dmg = math.floor(dmg * xi.spells.damage.calculateAbsorption(target, spellElement, false, true, false, true))
    dmg = math.floor(dmg * xi.spells.damage.calculateNullification(target, spellElement, false, true, false, true))
    dmg = math.floor(dmg * xi.combat.damage.calculateDamageAdjustment(target, false, false, false, true))
    dmg = math.floor(dmg * xi.spells.damage.calculateElementalStaffBonus(caster, spellElement))
    dmg = math.floor(dmg * xi.spells.damage.calculateElementalAffinityBonus(caster, spellElement))
    dmg = math.floor(dmg * xi.combat.magicHitRate.calculateResistRate(caster, target, maccParams))
    dmg = math.floor(dmg * xi.spells.damage.calculateAdditionalResistTier(caster, target, spellElement))
    dmg = math.floor(dmg * xi.combat.damage.magicalElementSDT(target, spellElement))
    dmg = math.floor(dmg * xi.spells.damage.calculateDayAndWeather(caster, spellElement, false))
    dmg = math.floor(dmg * xi.spells.damage.calculateMagicBonusDiff(caster, target, spellId, xi.skill.BLUE_MAGIC, spellElement, 0))
    dmg = math.floor(dmg * xi.combat.damage.scarletDeliriumMultiplier(caster))
    dmg = math.floor(dmg * xi.spells.damage.calculateAreaOfEffectResistance(target, spell))
    dmg = math.floor(dmg * calculateNukeWallFactor(target, spellElement, dmg))
    dmg = math.floor(dmg * (xi.settings.main.BLUE_POWER or 1))

    if dmg < 0 then
        dmg = target:addHP(-dmg)
        spell:setMsg(xi.msg.basic.MAGIC_RECOVERS_HP)
        return dmg
    end

    dmg = math.floor(target:handleSevereDamage(dmg, false))

    if dmg > 0 then
        dmg = utils.clamp(utils.handlePhalanx(target, dmg), 0, 99999)
        dmg = utils.clamp(utils.handleOneForAll(target, dmg), 0, 99999)
        dmg = utils.handleStoneskin(target, dmg, attackType)
        dmg = utils.clamp(dmg, 0, target:getHP())
        dmg = target:checkDamageCap(dmg)
    end

    target:takeSpellDamage(caster, spell, dmg, attackType, damageType)
    target:handleAfflatusMiseryDamage(dmg)
    target:updateEnmityFromDamage(caster, dmg)

    return dmg
end

-----------------------------------
-- Final apply (BLUE_POWER once; MDT on magical)
-----------------------------------

local function applySpellDamage(caster, target, spell, dmg, params, trickAttackTarget)
    dmg = math.floor(dmg * (xi.settings.main.BLUE_POWER or 1))

    local attackType    = params.attackType or xi.attackType.NONE
    local damageType    = params.damageType or xi.damageType.NONE
    local tpHits        = params.tpHitsLanded or 0
    local extraTPGained = xi.combat.tp.calculateTPGainOnMagicalDamage(caster, target, dmg) * math.max(tpHits - 1, 0)

    if attackType == xi.attackType.MAGICAL then
        local absorb  = xi.spells.damage.calculateAbsorption(target, spell:getElement(), false, true, false, false)
        local nullify = xi.spells.damage.calculateNullification(target, spell:getElement(), false, true, false, false)

        if nullify == 0 then
            spell:setMsg(xi.msg.basic.MAGIC_RESIST)
            return 0
        end

        dmg = math.floor(dmg * absorb * nullify)

        if dmg < 0 then
            target:takeSpellDamage(caster, spell, dmg, attackType, damageType)
            target:addTP(extraTPGained)
            return dmg
        end

        dmg = math.floor(dmg * xi.combat.damage.calculateDamageAdjustment(target, false, true, false, false))
        dmg = utils.handleOneForAll(target, dmg)
    end

    dmg = utils.handlePhalanx(target, dmg)
    dmg = utils.handleStoneskin(target, dmg, attackType)
    dmg = target:checkDamageCap(dmg)

    target:takeSpellDamage(caster, spell, dmg, attackType, damageType)
    target:addTP(extraTPGained)

    if not target:isPC() then
        if trickAttackTarget then
            target:updateEnmityFromDamage(trickAttackTarget, dmg)
        else
            target:updateEnmityFromDamage(caster, dmg)
        end
    end

    target:handleAfflatusMiseryDamage(dmg)

    return dmg
end

-----------------------------------
-- Install
-----------------------------------

m:addOverride('xi.spells.blue.usePhysicalSpell', usePhysicalSpell)
m:addOverride('xi.spells.blue.useMagicalSpell', useMagicalSpell)
m:addOverride('xi.spells.blue.useBreathSpell', useBreathSpell)
m:addOverride('xi.spells.blue.applySpellDamage', applySpellDamage)

-- FileWatcher drops addOverride; assignment wrap stays live.
if not xi.spells.blue._ixi20BluDamage then
    xi.spells.blue._ixi20BluDamage = true
end

xi.spells.blue.usePhysicalSpell = usePhysicalSpell
xi.spells.blue.useMagicalSpell  = useMagicalSpell
xi.spells.blue.useBreathSpell   = useBreathSpell
xi.spells.blue.applySpellDamage = applySpellDamage
