-----------------------------------
-- Imagine XI 1.0 HNM healer pressure (module helper).
-----------------------------------
require('modules/custom/lua/ixi20_hnm_anti_melt')
require('modules/custom/lua/ixi20_hnm_roster')
-----------------------------------
xi = xi or {}
xi.healerPressure = xi.healerPressure or {}

xi.healerPressure.settings =
{
    TELEGRAPH_WINDUP_MS = 2500,
    PULSE_RANGE         = 25,
    ENGAGE_GAP_S        = 20,
    DOOM_POWER          = 10,
    DOOM_TICK           = 3,
}

xi.healerPressure.scalingByPlayers =
{
    [1] = 0.50,
    [2] = 0.60,
    [3] = 0.70,
    [4] = 0.80,
    [5] = 0.90,
    [6] = 1.00,
}

local elementTelegraph =
{
    [xi.element.FIRE]    = 'Searing heat builds around you...',
    [xi.element.ICE]     = 'A freezing chill builds around you...',
    [xi.element.WIND]    = 'Howling winds build around you...',
    [xi.element.EARTH]   = 'The ground trembles beneath you...',
    [xi.element.THUNDER] = 'The air crackles with lightning...',
    [xi.element.WATER]   = 'A crushing tide builds around you...',
    [xi.element.LIGHT]   = 'Blinding radiance builds around you...',
    [xi.element.DARK]    = 'Smothering darkness builds around you...',
}

xi.healerPressure.config =
{
    ['Genbu']  = { pulse = { element = xi.element.WATER, hpPercent = 40, intervalS = 75 }, statuses = { { effect = xi.effect.SLOW, power = 3000, duration = 30 } } },
    ['Seiryu'] = { pulse = { element = xi.element.WIND, hpPercent = 40, intervalS = 75 }, statuses = { { effect = xi.effect.SILENCE, power = 1, duration = 15 } } },
    ['Byakko'] = { pulse = { element = xi.element.THUNDER, hpPercent = 40, intervalS = 75 }, statuses = { { effect = xi.effect.PARALYSIS, power = 20, duration = 30 } } },
    ['Suzaku'] = { pulse = { element = xi.element.FIRE, hpPercent = 40, intervalS = 75 }, statuses = { { effect = xi.effect.BURN, power = 20, tick = 3, duration = 30 } } },
    ['Kirin']  = { pulse = { element = xi.element.LIGHT, hpPercent = 40, intervalS = 75 } },
    ['Tiamat']     = { pulse = { element = xi.element.FIRE, hpPercent = 35, intervalS = 90, mpPercent = 10 } },
    ['Jormungand'] = { pulse = { element = xi.element.ICE, hpPercent = 35, intervalS = 90, mpPercent = 10 } },
    ['Vrtra']      = { pulse = { element = xi.element.DARK, hpPercent = 35, intervalS = 90, mpPercent = 10 } },
    ['Fafnir'] =
    {
        pulse    = { element = xi.element.DARK, hpPercent = 25, intervalS = 75 },
        statuses = { { effect = xi.effect.PARALYSIS, power = 15, duration = 30 }, { effect = xi.effect.BLINDNESS, power = 15, duration = 30 } },
    },
    ['Nidhogg'] =
    {
        pulse    = { element = xi.element.DARK, hpPercent = 25, intervalS = 75 },
        statuses = { { effect = xi.effect.PARALYSIS, power = 15, duration = 30 }, { effect = xi.effect.BLINDNESS, power = 15, duration = 30 } },
    },
    ['Behemoth'] = { pulse = { element = xi.element.THUNDER, hpPercent = 25, intervalS = 75 }, statuses = { { effect = xi.effect.SLOW, power = 2000, duration = 30 } } },
    ['King_Behemoth'] =
    {
        pulse    = { element = xi.element.THUNDER, hpPercent = 0, intervalS = 75 },
        statuses = { { effect = xi.effect.SLOW, power = 2500, duration = 30 }, { effect = xi.effect.PARALYSIS, power = 15, duration = 30 } },
    },
    ['Adamantoise']   = { pulse = { element = xi.element.WATER, hpPercent = 25, intervalS = 75 }, statuses = { { effect = xi.effect.BLINDNESS, power = 20, duration = 30 } } },
    ['Aspidochelone'] = { pulse = { element = xi.element.WATER, hpPercent = 25, intervalS = 75 }, statuses = { { effect = xi.effect.BLINDNESS, power = 20, duration = 30 } } },
    ['Cerberus']      = { pulse = { element = xi.element.FIRE, hpPercent = 30, intervalS = 75 }, statuses = { { effect = xi.effect.BURN, power = 15, tick = 3, duration = 30 } } },
    ['Capricious_Cassie'] = { doom = { hpp = 50, durationS = 30 } },
    ['Khimaira'] =
    {
        pulse = { element = xi.element.THUNDER, hpPercent = 25, intervalS = 75 },
        doom  = { hpp = 40, durationS = 30 },
    },
    ['Serket']         = { pulse = { element = xi.element.EARTH, hpPercent = 0, intervalS = 75 }, statuses = { { effect = xi.effect.POISON, power = 20, tick = 3, duration = 30 } } },
    ['King_Arthro']    = { pulse = { element = xi.element.WATER, hpPercent = 30, intervalS = 75 } },
    ['Lord_of_Onzozo'] = { pulse = { element = xi.element.THUNDER, hpPercent = 0, intervalS = 75 }, statuses = { { effect = xi.effect.PARALYSIS, power = 20, duration = 30 } } },
    ['Roc']            = { pulse = { element = xi.element.WIND, hpPercent = 30, intervalS = 75 } },
    ['Simurgh']        = { pulse = { element = xi.element.WIND, hpPercent = 0, intervalS = 75 }, statuses = { { effect = xi.effect.SLOW, power = 2500, duration = 30 } } },
}

local function getConfig(mob)
    return xi.healerPressure.config[mob:getName()]
end

local function pressureScale(mob)
    local count = math.min(6, math.max(1, xi.hnmAntiMelt.countEngagedRealPlayers(mob)))
    return xi.healerPressure.scalingByPlayers[count] or 1.0
end

local function pulseTargets(mob)
    local targets = {}
    local seen    = {}

    xi.ixi20Hnm.forEachEnmity(mob, function(member)
        if
            member:isPC() and
            (not member.isTrust or not member:isTrust()) and
            not seen[member:getID()] and
            member:getHP() > 0 and
            mob:checkDistance(member) <= xi.healerPressure.settings.PULSE_RANGE
        then
            seen[member:getID()] = true
            table.insert(targets, member)
        end
    end)

    return targets
end

local function telegraph(mob, message)
    xi.ixi20Hnm.forEachEnmity(mob, function(member)
        if member:isPC() then
            member:printToPlayer(message, xi.msg.channel.SYSTEM_3)
        end
    end)
end

local function resolvePulse(mob)
    mob:setLocalVar('[healerPressure]pulsePending', 0)

    local config = getConfig(mob)
    if not config or not config.pulse or not mob:isAlive() or not mob:isEngaged() then
        return
    end

    local pulse = config.pulse
    local scale = pressureScale(mob)

    for _, member in ipairs(pulseTargets(mob)) do
        if pulse.hpPercent and pulse.hpPercent > 0 then
            local damage = utils.clamp(utils.handleStoneskin(member, math.floor(member:getMaxHP() * (pulse.hpPercent / 100) * scale), xi.attackType.MAGICAL), 0, 99999)
            if damage > 0 then
                member:takeDamage(damage, mob, xi.attackType.MAGICAL, xi.damageType.ELEMENTAL + pulse.element)
            end
        end

        if pulse.mpPercent and pulse.mpPercent > 0 then
            member:delMP(math.floor(member:getMaxMP() * (pulse.mpPercent / 100) * scale))
        end

        if config.statuses then
            for _, status in ipairs(config.statuses) do
                member:addStatusEffect(status.effect, { power = status.power, tick = status.tick or 0, duration = status.duration })
            end
        end
    end
end

local function tryPulse(mob)
    local config = getConfig(mob)
    if not config or not config.pulse then
        return
    end

    local now      = GetSystemTime()
    local lastTick = mob:getLocalVar('[healerPressure]lastTick')
    local nextAt   = mob:getLocalVar('[healerPressure]nextPulseAt')

    mob:setLocalVar('[healerPressure]lastTick', now)

    if nextAt == 0 or (lastTick > 0 and now - lastTick > xi.healerPressure.settings.ENGAGE_GAP_S) then
        mob:setLocalVar('[healerPressure]nextPulseAt', now + config.pulse.intervalS)
        return
    end

    if now < nextAt or mob:getLocalVar('[healerPressure]pulsePending') == 1 then
        return
    end

    mob:setLocalVar('[healerPressure]pulsePending', 1)
    mob:setLocalVar('[healerPressure]nextPulseAt', now + config.pulse.intervalS)
    telegraph(mob, config.pulse.message or elementTelegraph[config.pulse.element])

    mob:timer(xi.healerPressure.settings.TELEGRAPH_WINDUP_MS, function(mobArg)
        if mobArg then
            resolvePulse(mobArg)
        end
    end)
end

local function tryDoom(mob)
    local config = getConfig(mob)
    if not config or not config.doom or mob:getLocalVar('[healerPressure]doomApplied') == 1 then
        return
    end

    if mob:getHPP() > config.doom.hpp then
        return
    end

    local targets = pulseTargets(mob)
    if #targets == 0 then
        return
    end

    mob:setLocalVar('[healerPressure]doomApplied', 1)

    local victim = targets[math.random(1, #targets)]
    telegraph(mob, victim:getName() .. ' has been marked for doom!')

    mob:timer(2000, function(mobArg)
        if
            mobArg and
            mobArg:isAlive() and
            victim:isAlive() and
            mobArg:checkDistance(victim) <= xi.healerPressure.settings.PULSE_RANGE
        then
            victim:addStatusEffect(xi.effect.DOOM, {
                power    = xi.healerPressure.settings.DOOM_POWER,
                tick     = xi.healerPressure.settings.DOOM_TICK,
                duration = config.doom.durationS,
            })
        end
    end)
end

xi.healerPressure.onSpawn = function(mob)
    mob:setLocalVar('[healerPressure]nextPulseAt', 0)
    mob:setLocalVar('[healerPressure]lastTick', 0)
    mob:setLocalVar('[healerPressure]pulsePending', 0)
    mob:setLocalVar('[healerPressure]doomApplied', 0)
end

xi.healerPressure.onCombatTick = function(mob)
    tryPulse(mob)
    tryDoom(mob)
end

xi.healerPressure.attach = function(mob)
    mob:addListener('SPAWN', 'IXI20_HEALER_PRESSURE_SPAWN', function(mobArg)
        xi.healerPressure.onSpawn(mobArg)
    end)

    mob:addListener('COMBAT_TICK', 'IXI20_HEALER_PRESSURE_COMBAT', function(mobArg)
        xi.healerPressure.onCombatTick(mobArg)
    end)
end

return xi.healerPressure
