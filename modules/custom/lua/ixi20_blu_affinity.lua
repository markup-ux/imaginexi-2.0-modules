-----------------------------------
-- Imagine XI 2.0: Chain Affinity, Burst Affinity, and Diffusion are
-- always on for main-job and subjob BLU from level 1. Duration 0
-- (never expires). Restored if a spell, zone, death, or job change
-- strips them. Pair with ixi20_blu_affinity.sql (after 37-cap remaps).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/job_utils/blue_mage')
-----------------------------------

local m = Module:new('ixi20_blu_affinity')

local LISTENER_GAIN = 'IXI20_BLU_AFFINITY_GAIN'
local LISTENER_LOSE = 'IXI20_BLU_AFFINITY_LOSE'
local LISTENER_JOB  = 'IXI20_BLU_AFFINITY_JOB'
local LISTENER_TICK = 'IXI20_BLU_AFFINITY_TICK'

local EFFECTS =
{
    xi.effect.CHAIN_AFFINITY,
    xi.effect.BURST_AFFINITY,
    xi.effect.DIFFUSION,
}

local KEEP_FLAGS = bit.bor(
    xi.effectFlag.ON_JOBCHANGE,
    xi.effectFlag.HIDE_TIMER,
    xi.effectFlag.NO_LOSS_MESSAGE,
    xi.effectFlag.NO_CANCEL
)

local applying = false

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function isBlu(entity)
    if not isPlayer(entity) then
        return false
    end

    return entity:getMainJob() == xi.job.BLU or entity:getSubJob() == xi.job.BLU
end

local function isTracked(effectId)
    return effectId == xi.effect.CHAIN_AFFINITY or
        effectId == xi.effect.BURST_AFFINITY or
        effectId == xi.effect.DIFFUSION
end

local function stampEffect(effect)
    if not effect then
        return
    end

    if effect.getDuration and effect:getDuration() ~= 0 then
        effect:setDuration(0)
    end

    if effect.addEffectFlag then
        effect:addEffectFlag(KEEP_FLAGS)
    end

    if effect.delEffectFlag then
        effect:delEffectFlag(xi.effectFlag.DEATH)
        effect:delEffectFlag(xi.effectFlag.ON_ZONE)
    end
end

local function ensureEffect(player, effectId)
    if not isBlu(player) then
        return
    end

    local effect = player:getStatusEffect(effectId)
    if effect then
        stampEffect(effect)
        return
    end

    player:addStatusEffect(effectId, {
        duration = 0,
        origin   = player,
        silent   = true,
        flag     = KEEP_FLAGS,
    })

    stampEffect(player:getStatusEffect(effectId))
end

local function isPermanent(effect)
    if not effect then
        return false
    end

    if effect.getDuration and effect:getDuration() == 0 then
        return true
    end

    return effect.hasEffectFlag and effect:hasEffectFlag(xi.effectFlag.HIDE_TIMER)
end

local function ensureEffects(player)
    if not isBlu(player) or applying then
        return
    end

    applying = true
    for _, effectId in ipairs(EFFECTS) do
        ensureEffect(player, effectId)
    end

    applying = false
end

local function stripPermanent(player)
    if not isPlayer(player) or applying then
        return
    end

    applying = true
    for _, effectId in ipairs(EFFECTS) do
        local effect = player:getStatusEffect(effectId)
        if isPermanent(effect) then
            player:delStatusEffectSilent(effectId)
        end
    end

    applying = false
end

local function syncEffects(player)
    if isBlu(player) then
        ensureEffects(player)
        return
    end

    stripPermanent(player)
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_GAIN)
    player:removeListener(LISTENER_LOSE)
    player:removeListener(LISTENER_JOB)
    player:removeListener(LISTENER_TICK)

    player:addListener('EFFECT_GAIN', LISTENER_GAIN, function(owner, effect)
        if not isBlu(owner) or not effect or not effect.getEffectType then
            return
        end

        if isTracked(effect:getEffectType()) then
            stampEffect(effect)
        end
    end)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(owner, effect)
        if applying or not owner or not effect or not effect.getEffectType then
            return
        end

        if not isTracked(effect:getEffectType()) then
            return
        end

        owner:timer(1, function(restoreTarget)
            syncEffects(restoreTarget)
        end)
    end)

    player:addListener('IXI20_PERSIST_JOB', LISTENER_JOB, function(owner)
        syncEffects(owner)
    end)

    -- Subjob change does not fire IXI20_PERSIST_JOB (main-only).
    player:addListener('EFFECTS_TICK', LISTENER_TICK, function(owner)
        syncEffects(owner)
    end)

    syncEffects(player)
end

local function attachOnlinePlayers()
    if not xi.zone or not GetZone then
        return
    end

    local visitedZone = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and not visitedZone[zoneId] then
            visitedZone[zoneId] = true
            local zone = GetZone(zoneId)
            if zone then
                for _, player in pairs(zone:getPlayers() or {}) do
                    attach(player)
                end
            end
        end
    end
end

local function useTracked(player, effectId)
    if isBlu(player) then
        ensureEffect(player, effectId)
        return effectId
    end

    return effectId
end

local function checkTracked(player, effectId)
    if isBlu(player) and player:hasStatusEffect(effectId) then
        return xi.msg.basic.EFFECT_ALREADY_ACTIVE, 0
    end

    return 0, 0
end

local function durationWithDiffusion(caster, duration)
    if caster:hasStatusEffect(xi.effect.DIFFUSION) then
        local merits = caster:getMerit(xi.merit.DIFFUSION)
        if merits > 0 then
            duration = duration + (merits - 5) * duration / 100
        end
    end

    return duration
end

m:addOverride('xi.job_utils.blue_mage.useChainAffinity', function(player, target, ability, action)
    return useTracked(player, xi.effect.CHAIN_AFFINITY)
end)

m:addOverride('xi.job_utils.blue_mage.useBurstAffinity', function(player, target, ability, action)
    return useTracked(player, xi.effect.BURST_AFFINITY)
end)

m:addOverride('xi.job_utils.blue_mage.useDiffusion', function(player, target, ability, action)
    return useTracked(player, xi.effect.DIFFUSION)
end)

m:addOverride('xi.job_utils.blue_mage.checkChainAffinity', function(player, target, ability)
    return checkTracked(player, xi.effect.CHAIN_AFFINITY)
end)

m:addOverride('xi.job_utils.blue_mage.checkBurstAffinity', function(player, target, ability)
    return checkTracked(player, xi.effect.BURST_AFFINITY)
end)

m:addOverride('xi.job_utils.blue_mage.checkDiffusion', function(player, target, ability)
    return checkTracked(player, xi.effect.DIFFUSION)
end)

m:addOverride('xi.actions.abilities.chain_affinity.onAbilityCheck', function(player, target, ability)
    return checkTracked(player, xi.effect.CHAIN_AFFINITY)
end)

m:addOverride('xi.actions.abilities.burst_affinity.onAbilityCheck', function(player, target, ability)
    return checkTracked(player, xi.effect.BURST_AFFINITY)
end)

m:addOverride('xi.actions.abilities.diffusion.onAbilityCheck', function(player, target, ability)
    return checkTracked(player, xi.effect.DIFFUSION)
end)

m:addOverride('xi.spells.blue.calculateDurationWithDiffusion', function(caster, duration)
    return durationWithDiffusion(caster, duration)
end)

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    ensureEffects(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

-- FileWatcher discards addOverride; assignment wrap stays live.
if xi.job_utils and xi.job_utils.blue_mage then
    xi.job_utils.blue_mage.useChainAffinity = function(player, target, ability, action)
        return useTracked(player, xi.effect.CHAIN_AFFINITY)
    end

    xi.job_utils.blue_mage.useBurstAffinity = function(player, target, ability, action)
        return useTracked(player, xi.effect.BURST_AFFINITY)
    end

    xi.job_utils.blue_mage.useDiffusion = function(player, target, ability, action)
        return useTracked(player, xi.effect.DIFFUSION)
    end

    xi.job_utils.blue_mage.checkChainAffinity = function(player, target, ability)
        return checkTracked(player, xi.effect.CHAIN_AFFINITY)
    end

    xi.job_utils.blue_mage.checkBurstAffinity = function(player, target, ability)
        return checkTracked(player, xi.effect.BURST_AFFINITY)
    end

    xi.job_utils.blue_mage.checkDiffusion = function(player, target, ability)
        return checkTracked(player, xi.effect.DIFFUSION)
    end
end

if xi.actions and xi.actions.abilities then
    if xi.actions.abilities.chain_affinity then
        xi.actions.abilities.chain_affinity.onAbilityCheck = function(player, target, ability)
            return checkTracked(player, xi.effect.CHAIN_AFFINITY)
        end
    end

    if xi.actions.abilities.burst_affinity then
        xi.actions.abilities.burst_affinity.onAbilityCheck = function(player, target, ability)
            return checkTracked(player, xi.effect.BURST_AFFINITY)
        end
    end

    if xi.actions.abilities.diffusion then
        xi.actions.abilities.diffusion.onAbilityCheck = function(player, target, ability)
            return checkTracked(player, xi.effect.DIFFUSION)
        end
    end
end

if xi.spells and xi.spells.blue then
    xi.spells.blue.calculateDurationWithDiffusion = durationWithDiffusion
end

if not xi.player._ixi20BluAlwaysOnGameIn then
    xi.player._ixi20BluAlwaysOnGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
