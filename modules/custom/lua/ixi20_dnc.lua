-----------------------------------
-- Imagine XI 2.0: DNC movement jigs match Flee speed and hit the party.
-- Chocobo Jig and Chocobo Jig II apply Flee (power 10000) to nearby party
-- members and trusts. Duration stays jig duration (JP / JIG_DURATION gear).
-- Spectral Jig also hits the party. Existing sneak / invis (spell, oil,
-- powder, Hide, Camouflage) is left alone when its remaining time is
-- longer than the jig. Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_dnc')

local PARTY_RANGE = 14
local FLEE_POWER  = 10000
local lastCastAt  = {}

local INVIS_FORMS =
{
    xi.effect.INVISIBLE,
    xi.effect.HIDE,
    xi.effect.CAMOUFLAGE,
}

local function partyInRange(player)
    local members = {}
    if not player or not player.getPartyWithTrusts then
        return { player }
    end

    local casterZone = player.getZoneID and player:getZoneID()
    for _, member in pairs(player:getPartyWithTrusts()) do
        if
            member and
            (not member.isDead or not member:isDead()) and
            (not casterZone or not member.getZoneID or member:getZoneID() == casterZone) and
            (member:getID() == player:getID() or player:checkDistance(member) <= PARTY_RANGE)
        then
            members[#members + 1] = member
        end
    end

    if #members == 0 then
        members[1] = player
    end

    return members
end

local function remainingMs(member, effectId)
    local effect = member.getStatusEffect and member:getStatusEffect(effectId)
    if not effect or not effect.getTimeRemaining then
        return 0
    end

    return effect:getTimeRemaining()
end

local function longestInvisMs(member)
    local best = 0
    for _, effectId in ipairs(INVIS_FORMS) do
        best = math.max(best, remainingMs(member, effectId))
    end

    return best
end

local function tryApplyCover(player, member, effectId, duration)
    local existing = member.getStatusEffect and member:getStatusEffect(effectId)
    if existing and existing.getTimeRemaining and existing:getTimeRemaining() >= duration * 1000 then
        return false
    end

    if existing then
        member:delStatusEffectSilent(effectId)
    end

    member:addStatusEffect(effectId, { duration = duration, origin = player, tick = 10 })

    return true
end

local function applySpectral(player, member, duration)
    local gained = false

    if remainingMs(member, xi.effect.SNEAK) < duration * 1000 then
        gained = tryApplyCover(player, member, xi.effect.SNEAK, duration) or gained
    end

    if longestInvisMs(member) < duration * 1000 then
        gained = tryApplyCover(player, member, xi.effect.INVISIBLE, duration) or gained
    end

    if gained and member:getID() ~= player:getID() then
        member:messageBasic(xi.msg.basic.SPECTRAL_JIG)
    end

    return gained
end

local function spectralDuration(player)
    local baseDuration       = 180 + player:getJobPointLevel(xi.jp.JIG_DURATION)
    local durationMultiplier = 1.0 + utils.clamp(player:getMod(xi.mod.JIG_DURATION), 0, 50) / 100

    return math.floor(baseDuration * durationMultiplier * xi.settings.main.SNEAK_INVIS_DURATION_MULTIPLIER)
end

local function useSpectralJig(player, ability)
    local duration = spectralDuration(player)
    local gained   = false

    for _, member in ipairs(partyInRange(player)) do
        gained = applySpectral(player, member, duration) or gained
    end

    if ability then
        if gained then
            ability:setMsg(xi.msg.basic.SPECTRAL_JIG)
        else
            ability:setMsg(xi.msg.basic.NO_EFFECT)
        end
    end

    return 1
end

local function jigDuration(player)
    local baseDuration       = 120 + player:getJobPointLevel(xi.jp.JIG_DURATION)
    local durationMultiplier = 1.0 + utils.clamp(player:getMod(xi.mod.JIG_DURATION), 0, 50) / 100

    return math.floor(baseDuration * durationMultiplier)
end

local function applyFleeSpeed(player, member, duration)
    if member.hasStatusEffect and member:hasStatusEffect(xi.effect.WEIGHT) then
        member:delStatusEffect(xi.effect.WEIGHT)
    end

    member:addStatusEffect(xi.effect.FLEE, { power = FLEE_POWER, duration = duration, origin = player })

    if member:getID() ~= player:getID() then
        member:messageBasic(xi.msg.basic.GAINS_EFFECT_OF_STATUS, xi.effect.FLEE)
    end
end

local function useMovementJig(player)
    local casterId = player:getID()
    local now      = os.time()
    if lastCastAt[casterId] == now then
        return xi.effect.FLEE
    end

    lastCastAt[casterId] = now

    local duration = jigDuration(player)
    for _, member in ipairs(partyInRange(player)) do
        applyFleeSpeed(player, member, duration)
    end

    return xi.effect.FLEE
end

local function install()
    if not xi.actions or not xi.actions.abilities then
        return
    end

    if xi.actions.abilities.chocobo_jig then
        xi.actions.abilities.chocobo_jig.onUseAbility = useMovementJig
    end

    if xi.actions.abilities.chocobo_jig_ii then
        xi.actions.abilities.chocobo_jig_ii.onUseAbility = useMovementJig
    end

    if xi.actions.abilities.spectral_jig then
        xi.actions.abilities.spectral_jig.onUseAbility = function(player, target, ability)
            return useSpectralJig(player, ability)
        end
    end
end

m:addOverride('xi.actions.abilities.chocobo_jig.onUseAbility', function(player, target, ability)
    return useMovementJig(player)
end)

m:addOverride('xi.actions.abilities.chocobo_jig_ii.onUseAbility', function(player, target, ability)
    return useMovementJig(player)
end)

m:addOverride('xi.actions.abilities.spectral_jig.onUseAbility', function(player, target, ability)
    return useSpectralJig(player, ability)
end)

install()
