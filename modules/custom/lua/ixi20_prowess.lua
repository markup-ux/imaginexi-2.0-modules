-----------------------------------
-- Imagine XI 2.0: Grounds Tome prowess
-- Different prowess types already stack (separate effect IDs).
-- Retail wipes them on zone. Keep every kind for 3 real days
-- (offline tick), including the page-clear counter.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_prowess')

local LISTENER_ID      = 'IXI20_PROWESS'
local PROWESS_SECONDS  = 3 * 24 * 60 * 60
local PROWESS_DURATION = PROWESS_SECONDS * 1000

local PROWESS_EFFECT =
{
    [xi.effect.PROWESS]                 = true,
    [xi.effect.PROWESS_CASKET_RATE]     = true,
    [xi.effect.PROWESS_SKILL_RATE]      = true,
    [xi.effect.PROWESS_CRYSTAL_YIELD]   = true,
    [xi.effect.PROWESS_TH]              = true,
    [xi.effect.PROWESS_ATTACK_SPEED]    = true,
    [xi.effect.PROWESS_HP_MP]           = true,
    [xi.effect.PROWESS_ACC_RACC]        = true,
    [xi.effect.PROWESS_ATT_RATT]        = true,
    [xi.effect.PROWESS_MACC_MATK]       = true,
    [xi.effect.PROWESS_CURE_POTENCY]    = true,
    [xi.effect.PROWESS_WS_DMG]          = true,
    [xi.effect.PROWESS_KILLER]          = true,
}

local function stampProwess(effect, resetDuration)
    if not effect or not PROWESS_EFFECT[effect:getEffectType()] then
        return
    end

    effect:delEffectFlag(xi.effectFlag.ON_ZONE)
    effect:addEffectFlag(xi.effectFlag.OFFLINE_TICK)
    if resetDuration or effect:getDuration() == 0 then
        effect:setDuration(PROWESS_DURATION)
    end
end

local function attachProwess(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('EFFECT_GAIN', LISTENER_ID, function(_, effect)
        stampProwess(effect, true)
    end)

    for _, effect in pairs(player:getStatusEffects()) do
        stampProwess(effect)
    end
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
                    attachProwess(player)
                end
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attachProwess(player)
end)

attachOnlinePlayers()
