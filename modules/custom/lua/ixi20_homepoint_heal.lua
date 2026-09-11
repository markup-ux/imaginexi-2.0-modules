-----------------------------------
-- Imagine XI 2.0: Home Points restore HP/MP (1.0 homepoint_heal).
-- Click a crystal like a single-player save point, then the menu opens.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/homepoint')
-----------------------------------

local m = Module:new('ixi20_homepoint_heal')

m:addOverride('xi.homepoint.onTrigger', function(player, csid, index)
    if player and player.isPC and player:isPC() then
        player:addHP(player:getMaxHP())
        player:addMP(player:getMaxMP())
    end

    super(player, csid, index)
end)

return m
