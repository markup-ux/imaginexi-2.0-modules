-----------------------------------
-- Imagine XI 2.0: Sneak Attack is a 30s window on main THF.
-- Every qualifying first swing / weaponskill / physical BLU is SA
-- (behind, Hide, or Doubt). Not consumed on hit. Recast 90s via SQL.
-- Sub THF keeps the retail 60s consume-on-hit buff.
-- Trick Attack is unchanged. Pair with ixi20_sa_window.sql.
-- ixi20_thf.cpp skips SA so crit recast cannot chain this window.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/job_utils/thief')
-----------------------------------

local m = Module:new('ixi20_sa_window')

local LISTENER_GAIN = 'IXI20_SA_WINDOW_GAIN'
local LISTENER_LOSE = 'IXI20_SA_WINDOW_LOSE'
local WINDOW_SECONDS = 30
local RETAIL_SECONDS = 60

local windows = {}

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function playerId(player)
    return player:getID()
end

local function isMainThf(player)
    return isPlayer(player) and player:getMainJob() == xi.job.THF
end

local function stampWindowEffect(effect)
    if not effect then
        return
    end

    if effect.delEffectFlag then
        effect:delEffectFlag(xi.effectFlag.ATTACK)
    end

    if effect.addEffectFlag then
        effect:addEffectFlag(xi.effectFlag.NO_LOSS_MESSAGE)
    end
end

local function rememberWindow(player, duration)
    windows[playerId(player)] =
    {
        expire = os.time() + duration,
        zone   = player:getZoneID(),
    }
end

local function clearWindow(player)
    windows[playerId(player)] = nil
end

local function remainingWindow(player)
    if
        not isMainThf(player) or
        (player.isDead and player:isDead())
    then
        return 0
    end

    local rec = windows[playerId(player)]
    if not rec then
        return 0
    end

    if player:getZoneID() ~= rec.zone then
        return 0
    end

    return math.max(0, rec.expire - os.time())
end

local function applyWindow(player, duration, silent)
    player:addStatusEffect(xi.effect.SNEAK_ATTACK, {
        power    = 1,
        duration = duration,
        origin   = player,
        silent   = silent,
    })
    stampWindowEffect(player:getStatusEffect(xi.effect.SNEAK_ATTACK))
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_GAIN)
    player:removeListener(LISTENER_LOSE)

    player:addListener('EFFECT_GAIN', LISTENER_GAIN, function(owner, effect)
        if
            not isMainThf(owner) or
            not effect or
            not effect.getEffectType or
            effect:getEffectType() ~= xi.effect.SNEAK_ATTACK
        then
            return
        end

        if remainingWindow(owner) > 0 then
            stampWindowEffect(effect)
        end
    end)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(owner, effect)
        if
            not owner or
            not effect or
            not effect.getEffectType or
            effect:getEffectType() ~= xi.effect.SNEAK_ATTACK
        then
            return
        end

        local left = remainingWindow(owner)
        if left <= 0 then
            clearWindow(owner)
            return
        end

        owner:timer(1, function(restoreTarget)
            if not isMainThf(restoreTarget) then
                clearWindow(restoreTarget)
                return
            end

            local remain = remainingWindow(restoreTarget)
            if remain <= 0 then
                clearWindow(restoreTarget)
                return
            end

            if not restoreTarget:hasStatusEffect(xi.effect.SNEAK_ATTACK) then
                applyWindow(restoreTarget, remain, true)
            else
                stampWindowEffect(restoreTarget:getStatusEffect(xi.effect.SNEAK_ATTACK))
            end
        end)
    end)
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
                for _, online in pairs(zone:getPlayers() or {}) do
                    attach(online)
                end
            end
        end
    end
end

local function useSneakAttack(player)
    if not isMainThf(player) then
        player:addStatusEffect(xi.effect.SNEAK_ATTACK, {
            power    = 1,
            duration = RETAIL_SECONDS,
            origin   = player,
        })
        return xi.effect.SNEAK_ATTACK
    end

    rememberWindow(player, WINDOW_SECONDS)
    applyWindow(player, WINDOW_SECONDS, false)
    return xi.effect.SNEAK_ATTACK
end

m:addOverride('xi.job_utils.thief.useSneakAttack', function(player, target, ability)
    return useSneakAttack(player)
end)

m:addOverride('xi.actions.abilities.sneak_attack.onUseAbility', function(player, target, ability)
    return useSneakAttack(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if zoning or firstLogin then
        clearWindow(player)
    end

    attach(player)
end)

-- FileWatcher discards addOverride; assignment wraps stay live.
if xi.job_utils and xi.job_utils.thief and not xi.job_utils.thief._ixi20SaWindow then
    xi.job_utils.thief._ixi20SaWindow = true
    xi.job_utils.thief.useSneakAttack = function(player, target, ability)
        return useSneakAttack(player)
    end
end

if xi.actions and xi.actions.abilities and xi.actions.abilities.sneak_attack then
    xi.actions.abilities.sneak_attack.onUseAbility = function(player, target, ability)
        return useSneakAttack(player)
    end
end

if not xi.player._ixi20SaWindowGameIn then
    xi.player._ixi20SaWindowGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        if zoning or firstLogin then
            clearWindow(player)
        end

        attach(player)
    end
end

attachOnlinePlayers()
