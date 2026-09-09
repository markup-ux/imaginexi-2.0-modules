-----------------------------------
-- Imagine XI 1.0 Mana Wall (module only)
-- Toggle: long duration until off / death / zone / job change.
-- Recast 180s when turning on; 3s when turning off.
-- Absorb-with-MP math is unchanged.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_mana_wall')

local MANA_WALL_DURATION = 604800 -- 7 days; yaml flags already clear on death / zone / job change
local TOGGLE_OFF_RECAST  = 3

local function useManaWall(player, target, ability, action)
    if player:hasStatusEffect(xi.effect.MANA_WALL) then
        player:delStatusEffect(xi.effect.MANA_WALL)
        if action then
            action:setRecast(TOGGLE_OFF_RECAST)
        end

        return 0
    end

    player:addStatusEffect(xi.effect.MANA_WALL, { power = 1, duration = MANA_WALL_DURATION, origin = player })

    return xi.effect.MANA_WALL
end

m:addOverride('xi.job_utils.black_mage.useManaWall', function(player, target, ability, action)
    return useManaWall(player, target, ability, action)
end)

-- Official script does not pass action; override so toggle-off can shorten recast.
m:addOverride('xi.actions.abilities.mana_wall.onUseAbility', function(player, target, ability, action)
    return useManaWall(player, target, ability, action)
end)
