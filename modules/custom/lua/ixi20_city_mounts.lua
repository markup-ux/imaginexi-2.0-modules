-----------------------------------
-- Mounts work in the same main cities 1.0 enabled.
-- C++ ixi20_city_mounts.cpp handles /mount, zone-in, and rental chocobos.
-- This covers Chocobo Whistle (Lua canUseMisc).
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_city_mounts')

local mainCityMountZones =
{
    [xi.zone.SOUTHERN_SAN_DORIA]   = true,
    [xi.zone.NORTHERN_SAN_DORIA]   = true,
    [xi.zone.PORT_SAN_DORIA]       = true,
    [xi.zone.CHATEAU_DORAGUILLE]   = true,
    [xi.zone.BASTOK_MINES]         = true,
    [xi.zone.BASTOK_MARKETS]       = true,
    [xi.zone.PORT_BASTOK]          = true,
    [xi.zone.METALWORKS]           = true,
    [xi.zone.WINDURST_WATERS]      = true,
    [xi.zone.WINDURST_WALLS]       = true,
    [xi.zone.PORT_WINDURST]        = true,
    [xi.zone.WINDURST_WOODS]       = true,
    [xi.zone.HEAVENS_TOWER]        = true,
    [xi.zone.RULUDE_GARDENS]       = true,
    [xi.zone.UPPER_JEUNO]          = true,
    [xi.zone.LOWER_JEUNO]          = true,
    [xi.zone.PORT_JEUNO]           = true,
    [xi.zone.AL_ZAHBI]             = true,
    [xi.zone.AHT_URHGAN_WHITEGATE] = true,
    [xi.zone.WESTERN_ADOULIN]      = true,
    [xi.zone.EASTERN_ADOULIN]      = true,
    [xi.zone.RABAO]                = true,
    [xi.zone.SELBINA]              = true,
    [xi.zone.MHAURA]               = true,
    [xi.zone.KAZHAM]               = true,
    [xi.zone.HALL_OF_THE_GODS]     = true,
    [xi.zone.NORG]                 = true,
}

local function cityMountWhistleCheck(target, item, caster)
    if not mainCityMountZones[target:getZoneID()] and not target:canUseMisc(xi.zoneMisc.MOUNT) then
        return xi.msg.basic.CANT_BE_USED_IN_AREA
    elseif
        target:getMainLvl() < 20 or
        not target:hasKeyItem(xi.ki.CHOCOBO_LICENSE) or
        target:hasEnmity()
    then
        return xi.msg.basic.ITEM_UNABLE_TO_USE
    end

    if target:getChocoboRaisingInfo() == nil then
        return xi.msg.basic.ITEM_UNABLE_TO_USE
    end

    return 0
end

m:addOverride('xi.items.chocobo_whistle.onItemCheck', cityMountWhistleCheck)

-- FileWatcher drops addOverride; assignment wrap is not.
if xi.items and xi.items.chocobo_whistle then
    xi.items.chocobo_whistle.onItemCheck = cityMountWhistleCheck
end

return m
