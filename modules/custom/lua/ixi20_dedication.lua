-----------------------------------
-- Imagine XI 2.0: Dedication is always on.
-- +150% EXP (Allied / Echad / Caliber). No bonus cap.
-- Applied on create / login / zone. Duration 0 (never expires).
-- Restored if a ring cap, zone, or another effect strips it.
-- Stock Abyssea skip in experience_points.lua stays.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_dedication')

local LISTENER_GAIN = 'IXI20_DEDICATION_GAIN'
local LISTENER_LOSE = 'IXI20_DEDICATION_LOSE'

-- Matches the best retail EXP rings. subPower is uint16; restock every kill
-- so handleDedicationBonus never burns the effect off.
local POWER = 150
local CAP   = 65535

local applying = false

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function stampDedication(effect)
    if not effect then
        return
    end

    if effect.getDuration and effect:getDuration() ~= 0 then
        effect:setDuration(0)
    end

    if effect.getPower and effect:getPower() ~= POWER then
        effect:setPower(POWER)
    end

    if effect.getSubPower and effect:getSubPower() < CAP then
        effect:setSubPower(CAP)
    end

    if effect.addEffectFlag then
        effect:addEffectFlag(xi.effectFlag.HIDE_TIMER)
    end
end

local function restockCap(member)
    if not isPlayer(member) then
        return
    end

    stampDedication(member:getStatusEffect(xi.effect.DEDICATION))
end

local function ensureDedication(player)
    if not isPlayer(player) or applying then
        return
    end

    applying = true

    local effect = player:getStatusEffect(xi.effect.DEDICATION)
    if effect then
        stampDedication(effect)
        applying = false
        return
    end

    player:addStatusEffect(xi.effect.DEDICATION, {
        power    = POWER,
        duration = 0,
        origin   = player,
        subPower = CAP,
        silent   = true,
    })

    stampDedication(player:getStatusEffect(xi.effect.DEDICATION))
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

        if effect:getEffectType() == xi.effect.DEDICATION then
            stampDedication(effect)
        end
    end)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(owner, effect)
        if applying or not owner or not effect or not effect.getEffectType then
            return
        end

        if effect:getEffectType() ~= xi.effect.DEDICATION then
            return
        end

        owner:timer(1, function(restoreTarget)
            ensureDedication(restoreTarget)
        end)
    end)

    ensureDedication(player)
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
    ensureDedication(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

m:addOverride('xi.experiencePoints.calculate', function(member, mob, data)
    restockCap(member)
    return super(member, mob, data)
end)

-- FileWatcher discards addOverride; keep onGameIn and the cap restock live.
if not xi.player._ixi20DedicationGameIn then
    xi.player._ixi20DedicationGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

if not xi.experiencePoints._ixi20DedicationWrap then
    xi.experiencePoints._ixi20DedicationWrap = true
    local prev = xi.experiencePoints.calculate
    xi.experiencePoints.calculate = function(member, mob, data)
        restockCap(member)
        if prev then
            return prev(member, mob, data)
        end
    end
end

attachOnlinePlayers()
