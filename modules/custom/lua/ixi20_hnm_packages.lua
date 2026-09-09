-----------------------------------
-- Imagine XI 2.0 HNM combat packages (module only).
-- Sleep immunity, stun-0 damage, WS reaction TP/Fast Cast, apex skills.
-- Core src stays LSB. C++ ixi20_hnm_packages.cpp attaches this once per zone.
-- applyMixins covers later scripted pops. Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_hnm_packages')

xi = xi or {}
xi.hnmPackages = xi.hnmPackages or {}

local ATTACHED_VAR     = '[ixi20Hnm]pkg'
local STUN_SHIELD_VAR  = '[ixi20Hnm]stunNull'
local WS_REACTION_CD   = 'WS_REACTION_CD'
local APEX_CD_VAR      = '[hnmApex]next'
local STUN_NULL_AMOUNT = 100
local APEX_CHANCE      = 25
local APEX_COOLDOWN_S  = 8

local DEFAULT_APEX_SKILLS =
{
    717,  -- venom breath
    724,  -- evasion
    1744, -- diamondhide
    1017, -- call_beast
    1901, -- activate
}

local function setting(key, fallback)
    local map = xi.settings and xi.settings.map
    if map and map[key] ~= nil then
        return map[key]
    end

    return fallback
end

local function isNotorious(mob)
    return mob and mob.isNM and mob:isNM()
end

local function isDynamisLord(mob)
    local name = mob:getName()
    return name == 'Dynamis_Lord' or name == 'Arch_Dynamis_Lord'
end

local function applySleepImmunity(mob)
    if not isNotorious(mob) then
        return
    end

    mob:addImmunity(xi.immunity.LIGHT_SLEEP)
    mob:addImmunity(xi.immunity.DARK_SLEEP)
end

local function applyStunShield(mob)
    if mob:getLocalVar(STUN_SHIELD_VAR) == 1 then
        return
    end

    mob:addMod(xi.mod.NULL_DAMAGE, STUN_NULL_AMOUNT)
    mob:setLocalVar(STUN_SHIELD_VAR, 1)
end

local function clearStunShield(mob)
    if mob:getLocalVar(STUN_SHIELD_VAR) ~= 1 then
        return
    end

    mob:addMod(xi.mod.NULL_DAMAGE, -STUN_NULL_AMOUNT)
    mob:setLocalVar(STUN_SHIELD_VAR, 0)
end

local function attachStunShield(mob)
    if not isNotorious(mob) or isDynamisLord(mob) then
        return
    end

    mob:addListener('EFFECT_GAIN', 'IXI20_HNM_STUN_GAIN', function(owner, effect)
        if effect:getEffectType() == xi.effect.STUN then
            applyStunShield(owner)
        end
    end)

    mob:addListener('EFFECT_LOSE', 'IXI20_HNM_STUN_LOSE', function(owner, effect)
        if effect:getEffectType() == xi.effect.STUN then
            clearStunShield(owner)
        end
    end)

    if mob:hasStatusEffect(xi.effect.STUN) then
        applyStunShield(mob)
    end
end

local function wsReactionTp(mob)
    if isNotorious(mob) then
        return setting('WS_REACTION_TP_HNM', 800)
    end

    if mob:isMobType(xi.mobType.BATTLEFIELD) or mob:getMobMod(xi.mobMod.CHECK_AS_NM) > 0 then
        return setting('WS_REACTION_TP_NM', 450)
    end

    return setting('WS_REACTION_TP_NORMAL', 200)
end

local function applyWsReactionFastCast(mob)
    local step     = setting('WS_REACTION_FASTCAST_STEP', 5)
    local maxPower = setting('WS_REACTION_FASTCAST_MAX', 50)
    local duration = setting('WS_REACTION_FASTCAST_DURATION_SECONDS', 30)
    local power    = step
    local existing = mob:getStatusEffect(xi.effect.FAST_CAST)

    if existing then
        power = math.min(existing:getPower() + step, maxPower)
        mob:delStatusEffect(xi.effect.FAST_CAST)
    end

    mob:addStatusEffect(xi.effect.FAST_CAST, {
        origin   = mob,
        power    = power,
        duration = duration,
        silent   = true,
    })
end

local function attachWsReaction(mob)
    if not setting('WS_REACTION_ENABLED', true) then
        return
    end

    mob:addListener('WEAPONSKILL_TAKE', 'IXI20_HNM_WS_REACTION', function(_, defender)
        if not defender or not defender.isMob or not defender:isMob() then
            return
        end

        local now = GetSystemTime()
        if defender:getLocalVar(WS_REACTION_CD) > now then
            return
        end

        defender:setLocalVar(WS_REACTION_CD, now + setting('WS_REACTION_COOLDOWN_SECONDS', 2))
        defender:addTP(wsReactionTp(defender))
        applyWsReactionFastCast(defender)
    end)
end

local function collectApexSkills(mob)
    local skills = {}
    local seen   = {}

    local function addSkill(skillId)
        if skillId and skillId > 0 and not seen[skillId] then
            seen[skillId] = true
            table.insert(skills, skillId)
        end
    end

    if mob:getLocalVar('[hnmApex]replaceDefault') ~= 1 then
        for _, skillId in ipairs(DEFAULT_APEX_SKILLS) do
            addSkill(skillId)
        end
    end

    for i = 1, 12 do
        addSkill(mob:getLocalVar('[hnmApex]skill' .. i))
    end

    return skills
end

local function attachApexSkills(mob)
    if not setting('HNM_APEX_SKILL_POOL_ENABLED', true) or not isNotorious(mob) then
        return
    end

    mob:addListener('COMBAT_TICK', 'IXI20_HNM_APEX', function(owner)
        if not owner:isAlive() then
            return
        end

        local behavior = xi.combat and xi.combat.behavior
        if behavior and behavior.isEntityBusy and behavior.isEntityBusy(owner) then
            return
        end

        local now = GetSystemTime()
        if owner:getLocalVar(APEX_CD_VAR) > now then
            return
        end

        if math.random(1, 100) > APEX_CHANCE then
            return
        end

        local skills = collectApexSkills(owner)
        if #skills == 0 then
            return
        end

        owner:setLocalVar(APEX_CD_VAR, now + APEX_COOLDOWN_S)
        owner:useMobAbility(skills[math.random(1, #skills)])
    end)
end

xi.hnmPackages.ensure = function(mob)
    if not mob or not mob.isMob or not mob:isMob() then
        return
    end

    if mob:getLocalVar(ATTACHED_VAR) == 1 then
        return
    end

    mob:setLocalVar(ATTACHED_VAR, 1)
    applySleepImmunity(mob)
    attachStunShield(mob)
    attachWsReaction(mob)
    attachApexSkills(mob)
end

m:addOverride('applyMixins', function(entity, mixins, mixinOptions)
    super(entity, mixins, mixinOptions)
    xi.hnmPackages.ensure(entity)
end)
