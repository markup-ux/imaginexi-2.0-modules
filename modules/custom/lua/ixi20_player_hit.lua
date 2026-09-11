-----------------------------------
-- Imagine XI 2.0: player melee and ranged attacks always connect.
-- Weaponskills, physical JAs, and BLU physicals use the same hit-rate functions.
-- Mobs and pets keep retail Acc/Eva.
-- Shadows, Third Eye, parry, guard, block, and Perfect Dodge are unchanged.
-- Ranged shots past 25 yalms still miss (out of range, not accuracy).
-- FileWatcher drops addOverride; assignment wrap stays live.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/combat/physical_hit_rate')
-----------------------------------

local m = Module:new('ixi20_player_hit')

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function physicalHitRate(attacker, target, bonus, slot, isWeaponskill, fallback)
    if isPlayer(attacker) then
        return 1
    end

    return fallback(attacker, target, bonus, slot, isWeaponskill)
end

local function rangedHitRate(attacker, target, bonus, isWeaponskill, fallback)
    if isPlayer(attacker) then
        if attacker:checkDistance(target) > 25 then
            return 0
        end

        return 1
    end

    return fallback(attacker, target, bonus, isWeaponskill)
end

m:addOverride('xi.combat.physicalHitRate.getPhysicalHitRate', function(attacker, target, bonus, slot, isWeaponskill)
    return physicalHitRate(attacker, target, bonus, slot, isWeaponskill, super)
end)

m:addOverride('xi.combat.physicalHitRate.getRangedHitRate', function(attacker, target, bonus, isWeaponskill)
    return rangedHitRate(attacker, target, bonus, isWeaponskill, super)
end)

if not xi.combat.physicalHitRate._ixi20PlayerHit then
    xi.combat.physicalHitRate._ixi20PlayerHit = true

    local previousPhysical = xi.combat.physicalHitRate.getPhysicalHitRate
    local previousRanged   = xi.combat.physicalHitRate.getRangedHitRate

    xi.combat.physicalHitRate.getPhysicalHitRate = function(attacker, target, bonus, slot, isWeaponskill)
        return physicalHitRate(attacker, target, bonus, slot, isWeaponskill, previousPhysical)
    end

    xi.combat.physicalHitRate.getRangedHitRate = function(attacker, target, bonus, isWeaponskill)
        return rangedHitRate(attacker, target, bonus, isWeaponskill, previousRanged)
    end
end
