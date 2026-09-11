-----------------------------------
-- Imagine XI 2.0: Signet is always on.
-- Applied on create / login / zone. Duration 0 (never expires).
-- Restored if a guard, staff, or another influence buff strips it.
-- Region rules (crystals, CP, DEF/EVA latent, party XP) stay stock.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_signet')

local LISTENER_GAIN = 'IXI20_SIGNET_GAIN'
local LISTENER_LOSE = 'IXI20_SIGNET_LOSE'

local applying = false

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function stampSignet(effect)
    if not effect then
        return
    end

    if effect.getDuration and effect:getDuration() ~= 0 then
        effect:setDuration(0)
    end

    if effect.addEffectFlag then
        effect:addEffectFlag(xi.effectFlag.HIDE_TIMER)
    end
end

local function ensureSignet(player)
    if not isPlayer(player) or applying then
        return
    end

    applying = true

    local effect = player:getStatusEffect(xi.effect.SIGNET)
    if effect then
        stampSignet(effect)
        applying = false
        return
    end

    player:addStatusEffect(xi.effect.SIGNET, {
        duration = 0,
        origin   = player,
        silent   = true,
    })

    stampSignet(player:getStatusEffect(xi.effect.SIGNET))
    applying = false
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_GAIN)
    player:removeListener(LISTENER_LOSE)

    player:addListener('EFFECT_GAIN', LISTENER_GAIN, function(owner, effect)
        if not effect or not effect.getEffectType then
            return
        end

        if effect:getEffectType() == xi.effect.SIGNET then
            stampSignet(effect)
        end
    end)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(owner, effect)
        if applying or not owner or not effect or not effect.getEffectType then
            return
        end

        if effect:getEffectType() ~= xi.effect.SIGNET then
            return
        end

        owner:timer(1, function(restoreTarget)
            ensureSignet(restoreTarget)
        end)
    end)

    ensureSignet(player)
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

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    ensureSignet(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

m:addOverride('xi.conquest.bestowSignet', function(player, pNation, pRank, mOffset)
    super(player, pNation, pRank, mOffset)
    ensureSignet(player)
end)

-- FileWatcher discards addOverride; keep onGameIn live without a restart.
if not xi.player._ixi20SignetGameIn then
    xi.player._ixi20SignetGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
