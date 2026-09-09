-----------------------------------
-- Imagine XI 2.0: unlock every Survival Guide on create / login.
-- Warps are already free in ixi20_no_gil_fees (no visit-to-register).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/teleports')
-----------------------------------

local m = Module:new('ixi20_survival_guides')

local survival = require('scripts/globals/teleports/survival_guide_map')

local function unlockAllGuides(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    for _, guide in pairs(survival.survivalGuides) do
        if guide and guide.group and guide.groupIndex then
            local bit  = guide.groupIndex - 1
            local set  = guide.group - 1
            if not player:hasTeleport(xi.teleport.type.SURVIVAL, bit, set) then
                player:addTeleport(xi.teleport.type.SURVIVAL, bit, set)
            end
        end
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    unlockAllGuides(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        unlockAllGuides(player)
    end
end)
