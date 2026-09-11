-----------------------------------
-- Imagine XI 2.0: SCH Arts + all stratagems at level 1, 5 charges / 48s.
-- Pair with ixi20_sch_charges.sql and ixi20_sch_charges.cpp (rebuild xi_map).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_sch_charges')

local function isScholar(player)
    return player:getMainJob() == xi.job.SCH or player:getSubJob() == xi.job.SCH
end

local function refreshCharges(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if not isScholar(player) then
        return
    end

    if Ixi20ApplySchCharges then
        Ixi20ApplySchCharges(player)
    end

    player:recalculateAbilitiesTable()
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    refreshCharges(player)
end)

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    refreshCharges(player)
end)

return m
