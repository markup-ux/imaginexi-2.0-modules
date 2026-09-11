-----------------------------------
-- Imagine XI 2.0: keep !godmode / !immortal across death, raise, and dispel.
-- Stock death strips every godmode buff (they all carry the death flag).
-- Regen / Refresh / Max HP-MP Boost also carry DISPELABLE, so mob skills
-- (Dispelling Wind, Horrid Roar, etc.) can strip them. Raise and onGameIn
-- do not put those back. Pixie rescue must not replace Invincible with a 15s copy.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_godmode_persist')

xi = xi or {}
xi.ixi20GodMode = xi.ixi20GodMode or {}

local DEATH_LISTENER = 'IXI20_GODMODE_PERSIST'
local GAIN_LISTENER  = 'IXI20_GODMODE_HARDEN'
local LOSE_LISTENER  = 'IXI20_GODMODE_REAPPLY'
local TOKEN_VAR      = 'IXI20_GM_RESTORE_T'
local LOSE_VAR       = 'IXI20_GM_LOSE_T'
local POLL_MS     = 250
local POLL_MAX_MS = 60 * 60 * 1000
local LOSE_DELAY_MS = 100

-- These four are the ones mob Dispel can actually take (YAML: dispelable).
-- Invincible and the 2-hours are not dispelable; they still get hardened.
local GODMODE_EFFECTS =
{
    [xi.effect.MAX_HP_BOOST]      = true,
    [xi.effect.MAX_MP_BOOST]      = true,
    [xi.effect.MIGHTY_STRIKES]    = true,
    [xi.effect.HUNDRED_FISTS]     = true,
    [xi.effect.CHAINSPELL]        = true,
    [xi.effect.PERFECT_DODGE]     = true,
    [xi.effect.INVINCIBLE]        = true,
    [xi.effect.ELEMENTAL_SFORZO]  = true,
    [xi.effect.MANAFONT]          = true,
    [xi.effect.REGAIN]            = true,
    [xi.effect.REFRESH]           = true,
    [xi.effect.REGEN]             = true,
}

local function modeEffects(mode)
    if mode == 1 then
        return {
            { xi.effect.MAX_HP_BOOST,     1000 },
            { xi.effect.MAX_MP_BOOST,     1000 },
            { xi.effect.MIGHTY_STRIKES,   1    },
            { xi.effect.HUNDRED_FISTS,    1    },
            { xi.effect.CHAINSPELL,       1    },
            { xi.effect.PERFECT_DODGE,    1    },
            { xi.effect.INVINCIBLE,       1    },
            { xi.effect.ELEMENTAL_SFORZO, 1    },
            { xi.effect.MANAFONT,         1    },
            { xi.effect.REGAIN,           300  },
            { xi.effect.REFRESH,          99   },
            { xi.effect.REGEN,            99   },
        }
    end

    if mode == 2 then
        return {
            { xi.effect.MAX_HP_BOOST, 200 },
            { xi.effect.REGAIN,       50  },
            { xi.effect.REFRESH,      999 },
            { xi.effect.REGEN,        999 },
            { xi.effect.CHAINSPELL,   1   },
            { xi.effect.MANAFONT,     1   },
        }
    end

    return {}
end

local function hardenEffect(effect)
    if not effect then
        return
    end

    -- YAML ORs DISPELABLE onto Regen / Refresh / HP-MP Boost after add.
    -- Duration 0 already blocks stock dispelStatusEffect; this covers
    -- overwrite (a timed Regen replacing ours) and DelStatusEffectsByFlag.
    effect:delEffectFlag(xi.effectFlag.DISPELABLE)
    effect:delEffectFlag(xi.effectFlag.ERASABLE)
end

local function hardenPlayer(player)
    for effectId, _ in pairs(GODMODE_EFFECTS) do
        hardenEffect(player:getStatusEffect(effectId))
    end
end

local function applyOne(player, effectId, power)
    local existing = player:getStatusEffect(effectId)
    if existing then
        if existing:getPower() < power or existing:getDuration() > 0 then
            player:delStatusEffectSilent(effectId)
        else
            hardenEffect(existing)
            return
        end
    end

    player:addStatusEffect(effectId, { power = power, origin = player })
    hardenEffect(player:getStatusEffect(effectId))
end

local function restoreGodModeEffects(player)
    local mode = player:getCharVar('GodMode')
    local list = modeEffects(mode)
    if #list == 0 then
        return
    end

    for i = 1, #list do
        applyOne(player, list[i][1], list[i][2])
    end

    player:addHP(50000)
    player:setMP(50000)
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

local function canRestoreNow(player)
    if not xi.ixi20GodMode.hasActive(player) then
        return false
    end

    if not player:isAlive() or player:getHP() <= 0 then
        return false
    end

    -- Mid-zone loc.zone is nil. Do not re-apply while effects are being dropped for transition.
    if not player.getZone or not player:getZone() then
        return false
    end

    return true
end

function xi.ixi20GodMode.restoreAfterRaise(player)
    if not canRestoreNow(player) then
        return
    end

    restoreGodModeEffects(player)
    restoreImmortal(player)
end

local function scheduleLoseRestore(player)
    local token = player:getLocalVar(LOSE_VAR) + 1
    player:setLocalVar(LOSE_VAR, token)

    player:timer(LOSE_DELAY_MS, function(p)
        if not p or p:getLocalVar(LOSE_VAR) ~= token then
            return
        end

        xi.ixi20GodMode.restoreAfterRaise(p)
    end)
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

    player:removeListener(DEATH_LISTENER)
    player:removeListener(GAIN_LISTENER)
    player:removeListener(LOSE_LISTENER)

    player:addListener('DEATH', DEATH_LISTENER, function(deadPlayer)
        if not xi.ixi20GodMode.hasActive(deadPlayer) and deadPlayer:getCharVar('Immortal') ~= 1 then
            return
        end

        local token = deadPlayer:getLocalVar(TOKEN_VAR) + 1
        deadPlayer:setLocalVar(TOKEN_VAR, token)
        pollUntilAlive(deadPlayer, token, 0)
    end)

    player:addListener('EFFECT_GAIN', GAIN_LISTENER, function(owner, effect)
        if not effect or not xi.ixi20GodMode.hasActive(owner) then
            return
        end

        if GODMODE_EFFECTS[effect:getEffectType()] then
            hardenEffect(effect)
        end
    end)

    player:addListener('EFFECT_LOSE', LOSE_LISTENER, function(owner, effect)
        if not effect or not xi.ixi20GodMode.hasActive(owner) then
            return
        end

        if not GODMODE_EFFECTS[effect:getEffectType()] then
            return
        end

        -- !godmode off sets the charvar to 0 before deleting effects, so
        -- hasActive is already false. Death / zone-out are skipped in the timer.
        scheduleLoseRestore(owner)
    end)

    if xi.ixi20GodMode.hasActive(player) then
        hardenPlayer(player)
        scheduleLoseRestore(player)
    end
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
