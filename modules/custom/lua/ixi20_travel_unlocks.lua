-----------------------------------
-- Imagine XI 2.0 travel unlocks
-- - All crag crystals + airship passes from character start / login
-- - All mount companion key items at main level 10
-- Pair with ixi20_mount_level.cpp so /mount works at 10 (stock LSB is 20).
-- Pair with ixi20_city_mounts so those mounts work in main cities.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_travel_unlocks')

local startKeyItems =
{
    xi.ki.AIRSHIP_PASS,
    xi.ki.AIRSHIP_PASS_FOR_KAZHAM,
    xi.ki.HOLLA_GATE_CRYSTAL,
    xi.ki.DEM_GATE_CRYSTAL,
    xi.ki.MEA_GATE_CRYSTAL,
    xi.ki.VAHZL_GATE_CRYSTAL,
    xi.ki.YHOATOR_GATE_CRYSTAL,
    xi.ki.ALTEPA_GATE_CRYSTAL,
    xi.ki.JUGNER_GATE_CRYSTAL,
    xi.ki.PASHHOW_GATE_CRYSTAL,
    xi.ki.MERIPHATAUD_GATE_CRYSTAL,
}

local function grantMissingKeyItem(player, keyItemId)
    if keyItemId and not player:hasKeyItem(keyItemId) then
        player:addKeyItem(keyItemId)
    end
end

local function grantStartTravelKeyItems(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    for _, keyItemId in ipairs(startKeyItems) do
        grantMissingKeyItem(player, keyItemId)
    end
end

local function unlockAllMountsIfEligible(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if player:getMainLvl() < 10 then
        return
    end

    for keyItemId = xi.ki.CHOCOBO_COMPANION, xi.ki.CRAKLAW_COMPANION do
        grantMissingKeyItem(player, keyItemId)
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantStartTravelKeyItems(player)
    unlockAllMountsIfEligible(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    grantStartTravelKeyItems(player)
    unlockAllMountsIfEligible(player)
end)

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    unlockAllMountsIfEligible(player)
end)

return m
