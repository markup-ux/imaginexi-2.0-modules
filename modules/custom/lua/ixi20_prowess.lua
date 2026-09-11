-----------------------------------
-- Imagine XI 2.0: Grounds Tome prowess
-- Different prowess types already stack (separate effect IDs).
-- Retail wipes them on zone. Keep every kind for 3 real days
-- (offline tick), including the page-clear counter.
-- Hidden icons: announce on login, on gain, and every 30 minutes.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_prowess')

local LISTENER_ID      = 'IXI20_PROWESS'
local TICK_ID          = 'IXI20_PROWESS_REMIND'
local LAST_MSG_VAR     = 'IXI20_PROWESS_MSG'
local PROWESS_SECONDS  = 3 * 24 * 60 * 60
local PROWESS_DURATION = PROWESS_SECONDS * 1000
local REMIND_SECONDS   = 30 * 60
local LOGIN_DELAY_MS   = 2500

local attaching = false

local function pct(power)
    return string.format('+%d%%', power)
end

local function hastePct(power)
    return string.format('+%d%%', math.floor(power / 100))
end

-- Bonus types use icon 0. Page-clear PROWESS is the visible icon.
local PROWESS_INFO =
{
    [xi.effect.PROWESS] =
    {
        name = 'Page clears',
        format = function(power)
            return tostring(power)
        end,
    },
    [xi.effect.PROWESS_CASKET_RATE] =
    {
        name = 'Casket rate',
        format = pct,
    },
    [xi.effect.PROWESS_SKILL_RATE] =
    {
        name = 'Skillup rate',
        format = pct,
    },
    [xi.effect.PROWESS_CRYSTAL_YIELD] =
    {
        name = 'Crystal yield',
        format = pct,
    },
    [xi.effect.PROWESS_TH] =
    {
        name = 'Treasure Hunter',
        format = function(power)
            return string.format('+%d', power)
        end,
    },
    [xi.effect.PROWESS_ATTACK_SPEED] =
    {
        name = 'Attack speed',
        format = hastePct,
    },
    [xi.effect.PROWESS_HP_MP] =
    {
        name = 'HP/MP',
        format = pct,
    },
    [xi.effect.PROWESS_ACC_RACC] =
    {
        name = 'Accuracy',
        format = pct,
    },
    [xi.effect.PROWESS_ATT_RATT] =
    {
        name = 'Attack',
        format = pct,
    },
    [xi.effect.PROWESS_MACC_MATK] =
    {
        name = 'Magic acc/atk',
        format = pct,
    },
    [xi.effect.PROWESS_CURE_POTENCY] =
    {
        name = 'Cure potency',
        format = pct,
    },
    [xi.effect.PROWESS_WS_DMG] =
    {
        name = 'WS damage',
        format = pct,
    },
    [xi.effect.PROWESS_KILLER] =
    {
        name = 'Killer effects',
        format = pct,
    },
}

local function remainingSeconds(effect)
    if not effect or not effect.getDuration then
        return 0
    end

    local durationSec = math.floor((effect:getDuration() or 0) / 1000)
    local started     = effect:getStartTime() or 0
    if started <= 0 then
        return durationSec
    end

    return math.max(0, durationSec - (os.time() - started))
end

local function formatRemain(seconds)
    if seconds >= 172800 then
        return string.format('%dd %dh', math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
    end

    if seconds >= 3600 then
        return string.format('%dh', math.floor(seconds / 3600))
    end

    if seconds >= 60 then
        return string.format('%dm', math.floor(seconds / 60))
    end

    return '<1m'
end

local function formatEntry(effectId, effect)
    local info = PROWESS_INFO[effectId]
    if not info then
        return nil
    end

    return string.format('%s %s (%s)', info.name, info.format(effect:getPower() or 0), formatRemain(remainingSeconds(effect)))
end

local function collectProwess(player)
    local parts = {}
    if not player or not player.getStatusEffect then
        return parts
    end

    -- Bonus types first, page-clear counter last.
    for effectId, _ in pairs(PROWESS_INFO) do
        if effectId ~= xi.effect.PROWESS then
            local effect = player:getStatusEffect(effectId)
            if effect then
                parts[#parts + 1] = formatEntry(effectId, effect)
            end
        end
    end

    table.sort(parts)

    local clears = player:getStatusEffect(xi.effect.PROWESS)
    if clears then
        parts[#parts + 1] = formatEntry(xi.effect.PROWESS, clears)
    end

    return parts
end

local function chat(player, text)
    if player and player.printToPlayer then
        player:printToPlayer(text, xi.msg.channel.SYSTEM_1)
    end
end

local function printSummary(player, force)
    if not player then
        return false
    end

    local last = player.getLocalVar and player:getLocalVar(LAST_MSG_VAR) or 0
    if not force and last > 0 and os.time() - last < 10 then
        return false
    end

    local parts = collectProwess(player)
    if #parts == 0 then
        return false
    end

    chat(player, 'Prowess: ' .. table.concat(parts, ', '))
    if player.setLocalVar then
        player:setLocalVar(LAST_MSG_VAR, os.time())
    end

    return true
end

local function stampProwess(player, effect, resetDuration)
    local effectId = effect and effect.getEffectType and effect:getEffectType()
    if not effectId or not PROWESS_INFO[effectId] then
        return
    end

    effect:delEffectFlag(xi.effectFlag.ON_ZONE)
    effect:addEffectFlag(xi.effectFlag.OFFLINE_TICK)
    if resetDuration or effect:getDuration() == 0 then
        effect:setDuration(PROWESS_DURATION)
    end

    if attaching or not player then
        return
    end

    -- Must not throw: this listener runs inside GoV page-complete and would
    -- skip the repeat reset, leaving the page stuck at full counts.
    pcall(function()
        local line = formatEntry(effectId, effect)
        if line then
            chat(player, 'Prowess gained: ' .. line)
        end

        printSummary(player, true)
    end)
end

local function attachProwess(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    attaching = true
    player:removeListener(LISTENER_ID)
    player:removeListener(TICK_ID)
    player:addListener('EFFECT_GAIN', LISTENER_ID, function(owner, effect)
        stampProwess(owner, effect, true)
    end)

    player:addListener('TICK', TICK_ID, function(owner)
        local last = owner:getLocalVar(LAST_MSG_VAR)
        if last == 0 then
            owner:setLocalVar(LAST_MSG_VAR, os.time())
            return
        end

        if os.time() - last >= REMIND_SECONDS then
            printSummary(owner)
        end
    end)

    for _, effect in pairs(player:getStatusEffects()) do
        stampProwess(player, effect)
    end

    attaching = false
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
                    printSummary(player)
                end
            end
        end
    end
end

-- Assignment wrap survives FileWatcher. addOverride does not.
if not xi.player._ixi20ProwessInner then
    xi.player._ixi20ProwessInner = xi.player.onGameIn
end

xi.player.onGameIn = function(player, firstLogin, zoning)
    xi.player._ixi20ProwessInner(player, firstLogin, zoning)
    attachProwess(player)

    if not zoning then
        player:timer(LOGIN_DELAY_MS, function(p)
            printSummary(p, true)
        end)
    end
end

-- Keep the module registered. Logic lives on the assignment wrap above.
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
end)

attachOnlinePlayers()
