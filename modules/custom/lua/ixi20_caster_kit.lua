-----------------------------------
-- Imagine XI 2.0: caster kit
-- Damaging elemental / divine / ninjutsu magic can close an existing
-- weaponskill skillchain (never opens). SCH helix closes stretch the
-- window. Immanence and BLU Chain Affinity stay the openers.
-- Accession and Manifestation are Mana Wall-style toggles: press on,
-- press off, not eaten by the next spell. Drop on death / zone / job
-- change. No Stratagem charge. Accession has no MP/recast tax.
-- Pair with ixi20_caster_kit.cpp / .sql. Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_caster_kit')

local LISTENER_LOSE  = 'IXI20_CASTER_KIT_LOSE'
local LISTENER_JOB   = 'IXI20_CASTER_KIT_JOB'
local LISTENER_MAGIC = 'IXI20_CASTER_KIT_MAGIC'

local TOGGLE_OFF_RECAST = 3

local TOGGLE_FLAGS = bit.bor(
    xi.effectFlag.HIDE_TIMER,
    xi.effectFlag.NO_CANCEL
)

local toggled  = {}
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

local function playerId(player)
    return player:getID()
end

local function isToggled(player, effectId)
    local slot = toggled[playerId(player)]
    local rec  = slot and slot[effectId]
    return rec and rec.zone == player:getZoneID()
end

local function setToggled(player, effectId, enable)
    local id = playerId(player)
    toggled[id] = toggled[id] or {}
    if enable then
        toggled[id][effectId] =
        {
            zone = player:getZoneID(),
        }
        return
    end

    toggled[id][effectId] = nil
end

local function clearToggles(player)
    toggled[playerId(player)] = nil
end

local function stampToggle(effect)
    if not effect then
        return
    end

    if effect.getDuration and effect:getDuration() ~= 0 then
        effect:setDuration(0)
    end

    if effect.addEffectFlag then
        effect:addEffectFlag(TOGGLE_FLAGS)
    end
end

local function applyToggle(player, effectId)
    applying = true
    if not player:hasStatusEffect(effectId) then
        player:addStatusEffect(effectId, {
            power    = 1,
            duration = 0,
            origin   = player,
            silent   = true,
            flag     = TOGGLE_FLAGS,
        })
    end

    stampToggle(player:getStatusEffect(effectId))
    applying = false
end

local function restoreToggle(player, effectId)
    if applying or not isToggled(player, effectId) then
        return
    end

    if not isScholar(player) or player:getHP() <= 0 then
        setToggled(player, effectId, false)
        return
    end

    applyToggle(player, effectId)
end

local function useToggle(player, effectId, action)
    if player:hasStatusEffect(effectId) then
        setToggled(player, effectId, false)
        applying = true
        player:delStatusEffect(effectId)
        applying = false
        if action and action.setRecast then
            action:setRecast(TOGGLE_OFF_RECAST)
        end

        return 0
    end

    setToggled(player, effectId, true)
    applyToggle(player, effectId)
    return effectId
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

    player:removeListener(LISTENER_LOSE)
    player:removeListener(LISTENER_JOB)
    player:removeListener(LISTENER_MAGIC)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(owner, effect)
        if applying or not owner or not effect or not effect.getEffectType then
            return
        end

        local effectId = effect:getEffectType()
        if effectId ~= xi.effect.ACCESSION and effectId ~= xi.effect.MANIFESTATION then
            return
        end

        owner:timer(1, function(restoreTarget)
            if not restoreTarget or not isPlayer(restoreTarget) then
                return
            end

            restoreToggle(restoreTarget, effectId)
        end)
    end)

    player:addListener('IXI20_PERSIST_JOB', LISTENER_JOB, function(owner)
        clearToggles(owner)
    end)

    player:addListener('MAGIC_USE', LISTENER_MAGIC, tryMagicSkillchainClose)
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

m:addOverride('xi.actions.abilities.accession.onAbilityCheck', function(player, target, ability)
    return 0, 0
end)

m:addOverride('xi.actions.abilities.manifestation.onAbilityCheck', function(player, target, ability)
    return 0, 0
end)

m:addOverride('xi.actions.abilities.accession.onUseAbility', function(player, target, ability, action)
    return useToggle(player, xi.effect.ACCESSION, action)
end)

m:addOverride('xi.actions.abilities.manifestation.onUseAbility', function(player, target, ability, action)
    return useToggle(player, xi.effect.MANIFESTATION, action)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if zoning or firstLogin then
        clearToggles(player)
    end

    attach(player)
end)

if xi.actions and xi.actions.abilities then
    if xi.actions.abilities.accession then
        xi.actions.abilities.accession.onAbilityCheck = function(player, target, ability)
            return 0, 0
        end

        xi.actions.abilities.accession.onUseAbility = function(player, target, ability, action)
            return useToggle(player, xi.effect.ACCESSION, action)
        end
    end

    if xi.actions.abilities.manifestation then
        xi.actions.abilities.manifestation.onAbilityCheck = function(player, target, ability)
            return 0, 0
        end

        xi.actions.abilities.manifestation.onUseAbility = function(player, target, ability, action)
            return useToggle(player, xi.effect.MANIFESTATION, action)
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

        if zoning or firstLogin then
            clearToggles(player)
        end

        attach(player)
    end
end

attachOnlinePlayers()
