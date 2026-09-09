-----------------------------------
-- Imagine XI 1.0 HNM anti-melt (module helper).
-- Per-hit caps, UDMG floors, party scaling, optional 50% ward.
-----------------------------------
require('modules/custom/lua/ixi20_hnm_defense_scaling')
require('modules/custom/lua/ixi20_hnm_roster')
-----------------------------------
xi = xi or {}
xi.hnmAntiMelt = xi.hnmAntiMelt or {}

xi.hnmAntiMelt.defaults =
{
    BASELINE_ENGAGED_PLAYERS = 6,
    DAMAGE_CAP_HP_FRACTION   = 0.032,
    DAMAGE_CAP_MIN           = 300,
    DAMAGE_CAP_MAX           = 1800,
    DAMAGE_VARIANCE_FRACTION = 0.1875,
    UDMG_PHYS                = -2000,
    UDMG_MAGIC               = -2000,
    UDMG_RANGE               = -1500,
    UDMG_BREATH              = -1500,
    WARD_HPP                 = 50,
    WARD_BONUS_UDMG          = -1000,
    WARD_BONUS_DURATION_S    = 30,
    WARD_MESSAGE             = 'A protective ward flares -- incoming damage is blunted.',
}

xi.hnmAntiMelt.scalingByPlayers =
{
    [1] = { extraUDMG = -5000, capScale = 0.5625, varianceScale = 0.6670 },
    [2] = { extraUDMG = -3500, capScale = 0.6875, varianceScale = 0.6670 },
    [3] = { extraUDMG = -2000, capScale = 0.8125, varianceScale = 0.8000 },
    [4] = { extraUDMG = -1000, capScale = 0.8750, varianceScale = 0.8670 },
    [5] = { extraUDMG = -500,  capScale = 0.9375, varianceScale = 0.9340 },
    [6] = { extraUDMG = 0,     capScale = 1.0000, varianceScale = 1.0000 },
}

local skyGodTuning =
{
    damageCap   = 800,
    ward        = true,
    wardMessage = 'The Sky god\'s ward flares -- incoming damage is blunted.',
}

xi.hnmAntiMelt.config =
{
    ['Genbu']  = skyGodTuning,
    ['Seiryu'] = skyGodTuning,
    ['Byakko'] = skyGodTuning,
    ['Suzaku'] = skyGodTuning,
    ['Kirin']  = { ward = false },
    ['Fafnir']  = { ward = true },
    ['Nidhogg'] = { ward = true },
    ['Behemoth']      = { ward = true },
    ['King_Behemoth'] = { ward = false },
    ['Adamantoise']   = { ward = true },
    ['Aspidochelone'] = { ward = false, manageUDMG = false },
    ['Tiamat']     = { ward = false, udmgMagic = -5000, udmgRange = -5000, udmgBreath = -5000 },
    ['Jormungand'] = { ward = false, udmgMagic = -5000, udmgRange = -5000, udmgBreath = -5000 },
    ['Vrtra']      = { ward = false, udmgMagic = -5000, udmgRange = -5000, udmgBreath = -5000 },
    ['Roc']               = { ward = true },
    ['Simurgh']           = { ward = true },
    ['Cerberus']          = { ward = false },
    ['Khimaira']          = { ward = true },
    ['Serket']            = { ward = true },
    ['Capricious_Cassie'] = { ward = true },
    ['King_Arthro']       = { ward = true },
    ['Lord_of_Onzozo']    = { ward = true },
}

local function getSetting(mob, key)
    local mobConfig = xi.hnmAntiMelt.config[mob:getName()]
    if mobConfig and mobConfig[key] ~= nil then
        return mobConfig[key]
    end

    return xi.hnmAntiMelt.defaults[key]
end

local function managesUDMG(mob)
    local mobConfig = xi.hnmAntiMelt.config[mob:getName()]
    if mobConfig and mobConfig.manageUDMG ~= nil then
        return mobConfig.manageUDMG
    end

    return true
end

local function hasWard(mob)
    local mobConfig = xi.hnmAntiMelt.config[mob:getName()]
    return mobConfig ~= nil and mobConfig.ward == true
end

local function baselineDamageCap(mob)
    local explicit = getSetting(mob, 'damageCap')
    if explicit then
        return explicit
    end

    local defaults = xi.hnmAntiMelt.defaults
    return utils.clamp(math.floor(mob:getMaxHP() * defaults.DAMAGE_CAP_HP_FRACTION), defaults.DAMAGE_CAP_MIN, defaults.DAMAGE_CAP_MAX)
end

local function applyUDMGFloor(mob, mod, value)
    mob:setMod(mod, math.min(mob:getMod(mod), value))
end

xi.hnmAntiMelt.countEngagedRealPlayers = function(mob)
    local seen  = {}
    local count = 0

    xi.ixi20Hnm.forEachEnmity(mob, function(member)
        if
            member:isPC() and
            (not member.isTrust or not member:isTrust()) and
            not seen[member:getID()]
        then
            seen[member:getID()] = true
            count = count + 1
        end
    end)

    return count
end

xi.hnmAntiMelt.applyBase = function(mob)
    local baseCap  = baselineDamageCap(mob)
    local variance = math.floor(baseCap * xi.hnmAntiMelt.defaults.DAMAGE_VARIANCE_FRACTION)

    mob:setMod(xi.mod.RECEIVED_DAMAGE_CAP, baseCap)
    mob:setMod(xi.mod.RECEIVED_DAMAGE_VARIANT, variance)

    if managesUDMG(mob) then
        applyUDMGFloor(mob, xi.mod.UDMGPHYS, getSetting(mob, 'udmgPhys') or xi.hnmAntiMelt.defaults.UDMG_PHYS)
        applyUDMGFloor(mob, xi.mod.UDMGMAGIC, getSetting(mob, 'udmgMagic') or xi.hnmAntiMelt.defaults.UDMG_MAGIC)
        applyUDMGFloor(mob, xi.mod.UDMGRANGE, getSetting(mob, 'udmgRange') or xi.hnmAntiMelt.defaults.UDMG_RANGE)
        applyUDMGFloor(mob, xi.mod.UDMGBREATH, getSetting(mob, 'udmgBreath') or xi.hnmAntiMelt.defaults.UDMG_BREATH)
    end

    mob:setLocalVar('[antiMelt]baseCap', baseCap)
    mob:setLocalVar('[antiMelt]baseVariance', variance)
    mob:setLocalVar('[antiMelt]extraUDMG', 0)
    mob:setLocalVar('[antiMelt]lastPlayerCount', 0)
    mob:setLocalVar('[antiMelt]wardApplied', 0)
    mob:setLocalVar('[antiMelt]wardBonusActive', 0)
end

xi.hnmAntiMelt.updatePartyScaling = function(mob)
    local count = xi.hnmAntiMelt.countEngagedRealPlayers(mob)
    if count == 0 then
        count = 1
    end

    count = math.min(xi.hnmAntiMelt.defaults.BASELINE_ENGAGED_PLAYERS, count)
    if count == mob:getLocalVar('[antiMelt]lastPlayerCount') then
        return
    end

    local scale = xi.hnmAntiMelt.scalingByPlayers[count] or xi.hnmAntiMelt.scalingByPlayers[6]

    if managesUDMG(mob) then
        local extraDelta = scale.extraUDMG - mob:getLocalVar('[antiMelt]extraUDMG')
        if extraDelta ~= 0 then
            mob:addMod(xi.mod.UDMGPHYS, extraDelta)
            mob:addMod(xi.mod.UDMGMAGIC, extraDelta)
            mob:addMod(xi.mod.UDMGRANGE, extraDelta)
            mob:addMod(xi.mod.UDMGBREATH, extraDelta)
            mob:setLocalVar('[antiMelt]extraUDMG', scale.extraUDMG)
        end
    end

    mob:setMod(xi.mod.RECEIVED_DAMAGE_CAP, math.floor(mob:getLocalVar('[antiMelt]baseCap') * scale.capScale))
    mob:setMod(xi.mod.RECEIVED_DAMAGE_VARIANT, math.floor(mob:getLocalVar('[antiMelt]baseVariance') * scale.varianceScale))
    mob:setLocalVar('[antiMelt]lastPlayerCount', count)
end

xi.hnmAntiMelt.tryWardPhase = function(mob)
    if not hasWard(mob) or mob:getLocalVar('[antiMelt]wardApplied') == 1 then
        return
    end

    if mob:getHPP() > xi.hnmAntiMelt.defaults.WARD_HPP then
        return
    end

    mob:setLocalVar('[antiMelt]wardApplied', 1)

    local absorb, duration = xi.ixi20HnmDefense.diamondhide(mob)
    mob:addStatusEffect(xi.effect.STONESKIN, { power = absorb, duration = duration, origin = mob, tier = 0 })

    local bonusUDMG = xi.hnmAntiMelt.defaults.WARD_BONUS_UDMG
    mob:addMod(xi.mod.UDMGPHYS, bonusUDMG)
    mob:addMod(xi.mod.UDMGMAGIC, bonusUDMG)
    mob:setLocalVar('[antiMelt]wardBonusActive', 1)

    mob:timer(xi.hnmAntiMelt.defaults.WARD_BONUS_DURATION_S * 1000, function(mobArg)
        if mobArg and mobArg:getLocalVar('[antiMelt]wardBonusActive') == 1 then
            mobArg:addMod(xi.mod.UDMGPHYS, -bonusUDMG)
            mobArg:addMod(xi.mod.UDMGMAGIC, -bonusUDMG)
            mobArg:setLocalVar('[antiMelt]wardBonusActive', 0)
        end
    end)

    local wardMessage = getSetting(mob, 'wardMessage')
    xi.ixi20Hnm.forEachEnmity(mob, function(member)
        if member:isPC() then
            member:printToPlayer(wardMessage, xi.msg.channel.SYSTEM_3)
        end
    end)
end

xi.hnmAntiMelt.attach = function(mob)
    mob:addListener('SPAWN', 'IXI20_HNM_ANTI_MELT_SPAWN', function(mobArg)
        xi.hnmAntiMelt.applyBase(mobArg)
    end)

    mob:addListener('COMBAT_TICK', 'IXI20_HNM_ANTI_MELT_COMBAT', function(mobArg)
        xi.hnmAntiMelt.updatePartyScaling(mobArg)
        xi.hnmAntiMelt.tryWardPhase(mobArg)
    end)
end

return xi.hnmAntiMelt
