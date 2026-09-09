-----------------------------------
-- Teleport items work without a prior zone visit.
-- Tidal Talisman also works outside its city pairs (falls back to Ru'Lude Gardens).
-- Nexus Cape still needs a valid party leader in an allowed zone.
-- FileWatcher discards addOverride; assignment on xi.items keeps the patch live.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/teleports')
-----------------------------------

local m = Module:new('ixi20_teleport_no_visit')

local function allowUse()
    return 0
end

-- Stock Tidal only works inside its city pairs. From anywhere else, go to Jeuno
-- (same dest as Three Nations => Jeuno) so the enchantment is usable in the field.
local tidalFallbackDest = { 0, 3, 2, 64, xi.zone.RULUDE_GARDENS }

local function tidalTeleport(player)
    if not player then
        return
    end

    local destination = xi.teleport.tidalDestinations[player:getZoneID()] or tidalFallbackDest
    player:setPos(unpack(destination))
end

-- Stock list from scripts/items/nexus_cape.lua, minus the visit bit.
local nexusValidZones =
{
    [xi.zone.ULEGUERAND_RANGE]           = true,
    [xi.zone.ATTOHWA_CHASM]              = true,
    [xi.zone.WEST_RONFAURE]              = true,
    [xi.zone.EAST_RONFAURE]              = true,
    [xi.zone.LA_THEINE_PLATEAU]          = true,
    [xi.zone.VALKURM_DUNES]              = true,
    [xi.zone.JUGNER_FOREST]              = true,
    [xi.zone.BATALLIA_DOWNS]             = true,
    [xi.zone.NORTH_GUSTABERG]            = true,
    [xi.zone.SOUTH_GUSTABERG]            = true,
    [xi.zone.KONSCHTAT_HIGHLANDS]        = true,
    [xi.zone.PASHHOW_MARSHLANDS]         = true,
    [xi.zone.ROLANBERRY_FIELDS]          = true,
    [xi.zone.BEAUCEDINE_GLACIER]         = true,
    [xi.zone.XARCABARD]                  = true,
    [xi.zone.CAPE_TERIGGAN]              = true,
    [xi.zone.EASTERN_ALTEPA_DESERT]      = true,
    [xi.zone.WEST_SARUTABARUTA]          = true,
    [xi.zone.EAST_SARUTABARUTA]          = true,
    [xi.zone.TAHRONGI_CANYON]            = true,
    [xi.zone.BUBURIMU_PENINSULA]         = true,
    [xi.zone.MERIPHATAUD_MOUNTAINS]      = true,
    [xi.zone.SAUROMUGUE_CHAMPAIGN]       = true,
    [xi.zone.YUHTUNGA_JUNGLE]            = true,
    [xi.zone.YHOATOR_JUNGLE]             = true,
    [xi.zone.WESTERN_ALTEPA_DESERT]      = true,
    [xi.zone.QUFIM_ISLAND]               = true,
    [xi.zone.BEHEMOTHS_DOMINION]         = true,
    [xi.zone.VALLEY_OF_SORROWS]          = true,
    [xi.zone.SOUTHERN_SAN_DORIA]         = true,
    [xi.zone.NORTHERN_SAN_DORIA]         = true,
    [xi.zone.PORT_SAN_DORIA]             = true,
    [xi.zone.BASTOK_MINES]               = true,
    [xi.zone.BASTOK_MARKETS]             = true,
    [xi.zone.PORT_BASTOK]                = true,
    [xi.zone.WINDURST_WATERS]            = true,
    [xi.zone.WINDURST_WALLS]             = true,
    [xi.zone.PORT_WINDURST]              = true,
    [xi.zone.WINDURST_WOODS]             = true,
    [xi.zone.RULUDE_GARDENS]             = true,
    [xi.zone.UPPER_JEUNO]                = true,
    [xi.zone.LOWER_JEUNO]                = true,
    [xi.zone.PORT_JEUNO]                 = true,
    [xi.zone.RABAO]                      = true,
    [xi.zone.SELBINA]                    = true,
    [xi.zone.MHAURA]                     = true,
    [xi.zone.KAZHAM]                     = true,
    [xi.zone.NORG]                       = true,
    [xi.zone.CARPENTERS_LANDING]         = true,
    [xi.zone.BIBIKI_BAY]                 = true,
    [xi.zone.LUFAISE_MEADOWS]            = true,
    [xi.zone.MISAREAUX_COAST]            = true,
    [xi.zone.ALTAIEU]                    = true,
    [xi.zone.BHAFLAU_THICKETS]           = true,
    [xi.zone.EAST_RONFAURE_S]            = true,
    [xi.zone.JUGNER_FOREST_S]            = true,
    [xi.zone.VUNKERL_INLET_S]            = true,
    [xi.zone.BATALLIA_DOWNS_S]           = true,
    [xi.zone.NORTH_GUSTABERG_S]          = true,
    [xi.zone.GRAUBERG_S]                 = true,
    [xi.zone.PASHHOW_MARSHLANDS_S]       = true,
    [xi.zone.ROLANBERRY_FIELDS_S]        = true,
    [xi.zone.WEST_SARUTABARUTA_S]        = true,
    [xi.zone.FORT_KARUGO_NARUGO_S]       = true,
    [xi.zone.MERIPHATAUD_MOUNTAINS_S]    = true,
    [xi.zone.SAUROMUGUE_CHAMPAIGN_S]     = true,
    [xi.zone.THE_SANCTUARY_OF_ZITAH]     = true,
    [xi.zone.ROMAEVE]                    = true,
    [xi.zone.RUAUN_GARDENS]              = true,
    [xi.zone.BEAUCEDINE_GLACIER_S]       = true,
    [xi.zone.XARCABARD_S]                = true,
}

local function nexusOnItemCheck(target)
    local result = xi.msg.basic.ITEM_UNABLE_TO_USE
    local leader = target and target.getPartyLeader and target:getPartyLeader()

    if leader ~= nil and not leader:inMogHouse() and target:getID() ~= leader:getID() then
        result = xi.msg.basic.ITEM_UNABLE_TO_USE_PARTY_LEADER
        if nexusValidZones[leader:getZoneID()] then
            result = 0
        end
    end

    return result
end

local itemChecks =
{
    ['cumulus_masque_+1']        = allowUse,
    ['custom_gilet_+1']          = allowUse,
    ['custom_top_+1']            = allowUse,
    ['ducal_guards_ring']        = allowUse,
    ['elder_gilet_+1']           = allowUse,
    ['federation_stables_scarf'] = allowUse,
    ['kingdom_stables_collar']   = allowUse,
    ['magna_gilet_+1']           = allowUse,
    ['magna_top_+1']             = allowUse,
    ['nexus_cape']               = nexusOnItemCheck,
    ['republic_stables_medal']   = allowUse,
    ['savage_top_+1']            = allowUse,
    ['shadow_lord_shirt']        = allowUse,
    ['tidal_talisman']           = allowUse,
    ['wonder_maillot_+1']        = allowUse,
    ['wonder_top_+1']            = allowUse,
    ['wyrmking_suit_+1']         = allowUse,
}

local function installItemChecks()
    if not xi.items then
        return
    end

    for itemName, onItemCheck in pairs(itemChecks) do
        local item = xi.items[itemName]
        if item then
            item.onItemCheck = onItemCheck
        end
    end
end

for itemName, onItemCheck in pairs(itemChecks) do
    -- Wrapper so applyOverride setfenv does not poison the shared allowUse closure.
    m:addOverride(string.format('xi.items.%s.onItemCheck', itemName), function(target, item, caster)
        return onItemCheck(target, item, caster)
    end)
end

m:addOverride('xi.teleport.tidalTeleport', function(player)
    tidalTeleport(player)
end)

-- FileWatcher re-runs this file and drops addOverride. Patch live tables now.
installItemChecks()
if xi.teleport then
    xi.teleport.tidalTeleport = tidalTeleport
end

return m
