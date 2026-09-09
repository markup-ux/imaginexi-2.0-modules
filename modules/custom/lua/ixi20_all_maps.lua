-----------------------------------
-- Imagine XI 2.0: grant every MAP_OF_* key item on create / login.
-- Map vendors stay free via ixi20_no_gil_fees.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_all_maps')

local function grantAllMaps(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    for name, keyItemId in pairs(xi.ki) do
        if
            type(name) == 'string' and
            type(keyItemId) == 'number' and
            name:find('^MAP_OF_', 1, false) and
            not player:hasKeyItem(keyItemId)
        then
            player:addKeyItem(keyItemId)
        end
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantAllMaps(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        grantAllMaps(player)
    end
end)
