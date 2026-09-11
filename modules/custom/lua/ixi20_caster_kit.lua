-----------------------------------
-- Imagine XI 2.0: caster kit
-- Damaging elemental / divine / ninjutsu magic can close an existing
-- weaponskill skillchain (never opens). SCH helix closes stretch the
-- window. Immanence and BLU Chain Affinity stay the openers.
-- Accession is always on for main/sub SCH (no MP/recast tax; pair with
-- the C++ module). Manifestation stays a 45s window but costs no charge.
-- Pair with ixi20_caster_kit.cpp / .sql. Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_caster_kit')

local LISTENER_GAIN  = 'IXI20_CASTER_KIT_GAIN'
local LISTENER_LOSE  = 'IXI20_CASTER_KIT_LOSE'
local LISTENER_JOB   = 'IXI20_CASTER_KIT_JOB'
local LISTENER_TICK  = 'IXI20_CASTER_KIT_TICK'
local LISTENER_MAGIC = 'IXI20_CASTER_KIT_MAGIC'

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

local function isScholar(entity)
    if not isPlayer(entity) then
        return false
    end

    return entity:getMainJob() == xi.job.SCH or entity:getSubJob() == xi.job.SCH
end

local function stampAccession(effect)
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

local function isPermanentAccession(effect)
    if not effect then
        return false
    end

    if effect.getDuration and effect:getDuration() == 0 then
        return true
    end

    return effect.hasEffectFlag and effect:hasEffectFlag(xi.effectFlag.HIDE_TIMER)
end

local function ensureAccession(player)
    if not isScholar(player) or applying then
        return
    end

    applying = true

    local effect = player:getStatusEffect(xi.effect.ACCESSION)
    if effect then
        stampAccession(effect)
        applying = false
        return
    end

    player:addStatusEffect(xi.effect.ACCESSION, {
        duration = 0,
        origin   = player,
        silent   = true,
        flag     = KEEP_FLAGS,
    })

    stampAccession(player:getStatusEffect(xi.effect.ACCESSION))
    applying = false
end

local function stripPermanentAccession(player)
    if not isPlayer(player) or applying then
        return
    end

    applying = true
    local effect = player:getStatusEffect(xi.effect.ACCESSION)
    if isPermanentAccession(effect) then
        player:delStatusEffectSilent(xi.effect.ACCESSION)
    end

    applying = false
end

local function syncAccession(player)
    if isScholar(player) then
        ensureAccession(player)
        return
    end

    stripPermanentAccession(player)
end

local function tryMagicSkillchainClose(caster, _, spell, action)
    if Ixi20TryMagicSkillchainClose then
        Ixi20TryMagicSkillchainClose(caster, spell, action)
    end
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_GAIN)
    player:removeListener(LISTENER_LOSE)
    player:removeListener(LISTENER_JOB)
    player:removeListener(LISTENER_TICK)
    player:removeListener(LISTENER_MAGIC)

    player:addListener('EFFECT_GAIN', LISTENER_GAIN, function(owner, effect)
        if not isScholar(owner) or not effect or not effect.getEffectType then
            return
        end

        if effect:getEffectType() == xi.effect.ACCESSION then
            stampAccession(effect)
        end
    end)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(owner, effect)
        if applying or not owner or not effect or not effect.getEffectType then
            return
        end

        if effect:getEffectType() ~= xi.effect.ACCESSION then
            return
        end

        owner:timer(1, function(restoreTarget)
            syncAccession(restoreTarget)
        end)
    end)

    player:addListener('IXI20_PERSIST_JOB', LISTENER_JOB, function(owner)
        syncAccession(owner)
    end)

    player:addListener('EFFECTS_TICK', LISTENER_TICK, function(owner)
        syncAccession(owner)
    end)

    player:addListener('MAGIC_USE', LISTENER_MAGIC, tryMagicSkillchainClose)

    syncAccession(player)
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

local function useAccession(player)
    ensureAccession(player)
    return xi.effect.ACCESSION
end

local function checkAccession(player)
    if isScholar(player) and player:hasStatusEffect(xi.effect.ACCESSION) then
        return xi.msg.basic.EFFECT_ALREADY_ACTIVE, 0
    end

    return 0, 0
end

m:addOverride('xi.combat.magicAoE.calculateTypeAndRadius', function(caster, spell)
    if
        caster and
        spell and
        spell:isAoE() == xi.magic.aoe.RADIAL_ACCE and
        isScholar(caster)
    then
        return { xi.magic.aoe.RADIAL, 10 }
    end

    return super(caster, spell)
end)

m:addOverride('xi.actions.abilities.accession.onUseAbility', function(player, target, ability)
    return useAccession(player)
end)

m:addOverride('xi.actions.abilities.accession.onAbilityCheck', function(player, target, ability)
    return checkAccession(player)
end)

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    ensureAccession(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

-- FileWatcher discards addOverride; assignment wrap stays live.
if xi.combat and xi.combat.magicAoE then
    local prevAoE = xi.combat.magicAoE.calculateTypeAndRadius
    xi.combat.magicAoE.calculateTypeAndRadius = function(caster, spell)
        if
            caster and
            spell and
            spell:isAoE() == xi.magic.aoe.RADIAL_ACCE and
            isScholar(caster)
        then
            return { xi.magic.aoe.RADIAL, 10 }
        end

        if prevAoE then
            return prevAoE(caster, spell)
        end

        return { xi.magic.aoe.NONE, 0 }
    end
end

if xi.actions and xi.actions.abilities then
    if xi.actions.abilities.accession then
        xi.actions.abilities.accession.onUseAbility = function(player, target, ability)
            return useAccession(player)
        end

        xi.actions.abilities.accession.onAbilityCheck = function(player, target, ability)
            return checkAccession(player)
        end
    end
end

if not xi.player._ixi20CasterKitGameIn then
    xi.player._ixi20CasterKitGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
