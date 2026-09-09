-----------------------------------
-- Imagine XI 2.0: keep !godmode / !immortal across death and raise.
-- Stock death strips every godmode buff (they all carry the death flag).
-- Raise does not re-apply them; onGameIn only restores after zone/login.
-- Pixie rescue then overwrote Invincible / Regen with short safety buffs.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_godmode_persist')

xi = xi or {}
xi.ixi20GodMode = xi.ixi20GodMode or {}

local LISTENER_ID = 'IXI20_GODMODE_PERSIST'
local TOKEN_VAR   = 'IXI20_GM_RESTORE_T'
local POLL_MS     = 250
local POLL_MAX_MS = 60 * 60 * 1000

local function restoreGodModeEffects(player)
    local mode = player:getCharVar('GodMode')
    if mode == 1 then
        player:addStatusEffect(xi.effect.MAX_HP_BOOST, { power = 1000, origin = player })
        player:addStatusEffect(xi.effect.MAX_MP_BOOST, { power = 1000, origin = player })
        player:addStatusEffect(xi.effect.MIGHTY_STRIKES, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.HUNDRED_FISTS, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.CHAINSPELL, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.PERFECT_DODGE, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.INVINCIBLE, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.ELEMENTAL_SFORZO, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.MANAFONT, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.REGAIN, { power = 300, origin = player })
        player:addStatusEffect(xi.effect.REFRESH, { power = 99, origin = player })
        player:addStatusEffect(xi.effect.REGEN, { power = 99, origin = player })
        player:addHP(50000)
        player:setMP(50000)
    elseif mode == 2 then
        player:addStatusEffect(xi.effect.MAX_HP_BOOST, { power = 200, origin = player })
        player:addStatusEffect(xi.effect.REGAIN, { power = 50, origin = player })
        player:addStatusEffect(xi.effect.REFRESH, { power = 999, origin = player })
        player:addStatusEffect(xi.effect.REGEN, { power = 999, origin = player })
        player:addStatusEffect(xi.effect.CHAINSPELL, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.MANAFONT, { power = 1, origin = player })
        player:addHP(50000)
        player:setMP(50000)
    end
end

local function restoreImmortal(player)
    if player:getCharVar('Immortal') == 1 then
        player:setUnkillable(true)
    end
end

function xi.ixi20GodMode.hasActive(player)
    if not player or not player.isPC or not player:isPC() then
        return false
    end

    if player.getGMLevel and player:getGMLevel() <= 0 then
        return false
    end

    return player:getCharVar('GodMode') ~= 0
end

function xi.ixi20GodMode.restoreAfterRaise(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if player.getGMLevel and player:getGMLevel() <= 0 then
        return
    end

    restoreGodModeEffects(player)
    restoreImmortal(player)
end

local function pollUntilAlive(player, token, elapsedMs)
    player:timer(POLL_MS, function(p)
        if not p or not p.isPC or not p:isPC() then
            return
        end

        if p:getLocalVar(TOKEN_VAR) ~= token then
            return
        end

        if p:isAlive() then
            xi.ixi20GodMode.restoreAfterRaise(p)
            return
        end

        local nextElapsed = elapsedMs + POLL_MS
        if nextElapsed < POLL_MAX_MS then
            pollUntilAlive(p, token, nextElapsed)
        end
    end)
end

local function attach(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('DEATH', LISTENER_ID, function(deadPlayer)
        if not xi.ixi20GodMode.hasActive(deadPlayer) and deadPlayer:getCharVar('Immortal') ~= 1 then
            return
        end

        local token = deadPlayer:getLocalVar(TOKEN_VAR) + 1
        deadPlayer:setLocalVar(TOKEN_VAR, token)
        pollUntilAlive(deadPlayer, token, 0)
    end)
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

if xi.zone and GetZone then
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

return m
