-----------------------------------
-- Nation liveries (Royal Guard / Mythril Musketeer / Patriarch Protector)
-- apply in BOTH:
--   * Campaign past: areas under that nation's army control
--   * Present 75-era: conquest regions that nation owns, plus its cities
-- Retail text is Campaign. These pieces had no latents. Signet is not required.
-- When Campaign is scripted later, set xi.campaign.getZoneControl(zoneId)
-- (returns campaign_map.nation: 2/4/6/8) or zone local var campaignNation.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/campaign')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_nation_liveries')

local LISTENER_ID = 'IXI20_NATION_LIVERY'
local VAR_ACTIVE  = 'ixi20LiveryOn'
local VAR_ITEM    = 'ixi20LiveryItem'
local VAR_MOVE    = 'ixi20LiveryMove'
local MOVE        = 12
local DURATION    = 30

-- 11358 is missing from scripts/enum/item.lua
local LIVERIES =
{
    [xi.item.ROYAL_GUARD_LIVERY]       = xi.nation.SANDORIA,
    [xi.item.MYTHRIL_MUSKETEER_LIVERY] = xi.nation.BASTOK,
    [11358]                            = xi.nation.WINDURST,
}

local HOME_REGION =
{
    [xi.nation.SANDORIA] = xi.region.SANDORIA,
    [xi.nation.BASTOK]   = xi.region.BASTOK,
    [xi.nation.WINDURST] = xi.region.WINDURST,
}

local NATION_TO_ARMY =
{
    [xi.nation.SANDORIA] = xi.campaign.control.SANDORIA,
    [xi.nation.BASTOK]   = xi.campaign.control.BASTOK,
    [xi.nation.WINDURST] = xi.campaign.control.WINDURST,
}

-- campaign_map.sql defaults. Cities stay that nation's army; fields start beastmen.
-- Live ownership overrides this via getZoneControl / campaignNation.
local CAMPAIGN_DEFAULT_CONTROL =
{
    [xi.zone.SOUTHERN_SAN_DORIA_S]     = xi.campaign.control.SANDORIA,
    [xi.zone.EAST_RONFAURE_S]          = xi.campaign.control.BEASTMEN,
    [xi.zone.JUGNER_FOREST_S]          = xi.campaign.control.BEASTMEN,
    [xi.zone.VUNKERL_INLET_S]          = xi.campaign.control.BEASTMEN,
    [xi.zone.BATALLIA_DOWNS_S]         = xi.campaign.control.BEASTMEN,
    [xi.zone.LA_VAULE_S]               = xi.campaign.control.BEASTMEN,
    [xi.zone.THE_ELDIEME_NECROPOLIS_S] = xi.campaign.control.BEASTMEN,
    [xi.zone.BASTOK_MARKETS_S]         = xi.campaign.control.BASTOK,
    [xi.zone.NORTH_GUSTABERG_S]        = xi.campaign.control.BEASTMEN,
    [xi.zone.GRAUBERG_S]               = xi.campaign.control.BEASTMEN,
    [xi.zone.PASHHOW_MARSHLANDS_S]     = xi.campaign.control.BEASTMEN,
    [xi.zone.ROLANBERRY_FIELDS_S]      = xi.campaign.control.BEASTMEN,
    [xi.zone.BEADEAUX_S]               = xi.campaign.control.BEASTMEN,
    [xi.zone.CRAWLERS_NEST_S]          = xi.campaign.control.BEASTMEN,
    [xi.zone.WINDURST_WATERS_S]        = xi.campaign.control.WINDURST,
    [xi.zone.WEST_SARUTABARUTA_S]      = xi.campaign.control.BEASTMEN,
    [xi.zone.FORT_KARUGO_NARUGO_S]     = xi.campaign.control.BEASTMEN,
    [xi.zone.MERIPHATAUD_MOUNTAINS_S]  = xi.campaign.control.BEASTMEN,
    [xi.zone.SAUROMUGUE_CHAMPAIGN_S]   = xi.campaign.control.BEASTMEN,
    [xi.zone.CASTLE_OZTROJA_S]         = xi.campaign.control.BEASTMEN,
    [xi.zone.GARLAIGE_CITADEL_S]       = xi.campaign.control.BEASTMEN,
    [xi.zone.BEAUCEDINE_GLACIER_S]     = xi.campaign.control.BEASTMEN,
    [xi.zone.XARCABARD_S]              = xi.campaign.control.BEASTMEN,
    [xi.zone.CASTLE_ZVAHL_BAILEYS_S]   = xi.campaign.control.BEASTMEN,
    [xi.zone.CASTLE_ZVAHL_KEEP_S]      = xi.campaign.control.BEASTMEN,
    [xi.zone.THRONE_ROOM_S]            = xi.campaign.control.BEASTMEN,
}

local LIVERY_BAGS =
{
    xi.inv.INVENTORY,
    xi.inv.WARDROBE,
    xi.inv.WARDROBE2,
    xi.inv.WARDROBE3,
    xi.inv.WARDROBE4,
    xi.inv.WARDROBE5,
    xi.inv.WARDROBE6,
    xi.inv.WARDROBE7,
    xi.inv.WARDROBE8,
}

local function isPlayer(entity)
    return entity ~= nil and entity.isPC ~= nil and entity:isPC()
end

local function conquestOwnedBy(region, nation)
    if HOME_REGION[nation] == region then
        return true
    end

    -- 75-era conquest map (Ronfaure through Tavnazian Archipelago).
    if region >= xi.region.RONFAURE and region <= xi.region.TAVNAZIANARCH then
        return GetRegionOwner(region) == nation
    end

    return false
end

local function campaignControlForZone(zoneId)
    if CAMPAIGN_DEFAULT_CONTROL[zoneId] == nil then
        return nil
    end

    if type(xi.campaign.getZoneControl) == 'function' then
        local live = xi.campaign.getZoneControl(zoneId)
        if live ~= nil then
            return live
        end
    end

    local zone = GetZone and GetZone(zoneId)
    if zone and zone.getLocalVar then
        local live = zone:getLocalVar('campaignNation')
        if live ~= 0 then
            return live
        end
    end

    return CAMPAIGN_DEFAULT_CONTROL[zoneId]
end

local function armyOwnsZone(zoneId, nation)
    local control = campaignControlForZone(zoneId)
    if control == nil then
        return false
    end

    return control == NATION_TO_ARMY[nation]
end

local function areaOwnedBy(player, nation)
    return conquestOwnedBy(player:getCurrentRegion(), nation) or armyOwnsZone(player:getZoneID(), nation)
end

-- Gear-bonus % is item-only in UpdateSpeed. Put +12% on the player as
-- stackable points (12% of base 50 = +6) and refresh the status packet.
local function movePoints(player)
    local base = player:getBaseSpeed()
    if not base or base < 1 then
        base = 50
    end

    return math.floor(base * MOVE / 100)
end

local function refreshSpeed(player)
    if player.recalculateStats then
        player:recalculateStats()
        return
    end

    local base = player:getBaseSpeed()
    player:setBaseSpeed(base + 1)
    player:setBaseSpeed(base)
end

local function clearBonuses(player)
    local move = player:getLocalVar(VAR_MOVE)
    if move > 0 then
        player:delMod(xi.mod.MOVE_SPEED_STACKABLE, move)
        player:setLocalVar(VAR_MOVE, 0)
    end

    if player:getLocalVar(VAR_ACTIVE) == 1 then
        player:delMod(xi.mod.SNEAK_DURATION, DURATION)
        player:delMod(xi.mod.INVISIBLE_DURATION, DURATION)
    end

    -- Drop leftover item-speed from the first draft, if any.
    local equipped = player:getEquippedItem(xi.slot.BODY)
    if equipped and LIVERIES[equipped:getID()] and equipped.getMod and equipped.delMod then
        local extra = equipped:getMod(xi.mod.MOVE_SPEED_GEAR_BONUS)
        if extra >= MOVE then
            equipped:delMod(xi.mod.MOVE_SPEED_GEAR_BONUS, MOVE)
        end
    end

    for _, container in ipairs(LIVERY_BAGS) do
        for slot = 0, 80 do
            local item = player:getStorageItem(container, slot, 255)
            if item and LIVERIES[item:getID()] and item.getMod and item.delMod then
                local extra = item:getMod(xi.mod.MOVE_SPEED_GEAR_BONUS)
                if extra >= MOVE then
                    item:delMod(xi.mod.MOVE_SPEED_GEAR_BONUS, MOVE)
                end
            end
        end
    end

    player:setLocalVar(VAR_ACTIVE, 0)
    player:setLocalVar(VAR_ITEM, 0)
end

local function applyBonuses(player, itemId)
    local add = movePoints(player)
    if add > 0 then
        player:addMod(xi.mod.MOVE_SPEED_STACKABLE, add)
        player:setLocalVar(VAR_MOVE, add)
    end

    player:addMod(xi.mod.SNEAK_DURATION, DURATION)
    player:addMod(xi.mod.INVISIBLE_DURATION, DURATION)
    player:setLocalVar(VAR_ACTIVE, 1)
    player:setLocalVar(VAR_ITEM, itemId)
    refreshSpeed(player)
end

local function syncLivery(player)
    if not isPlayer(player) then
        return
    end

    local bodyId    = player:getEquipID(xi.slot.BODY)
    local nation    = LIVERIES[bodyId]
    local shouldOn  = nation ~= nil and areaOwnedBy(player, nation)
    local isOn      = player:getLocalVar(VAR_ACTIVE) == 1
    local appliedId = player:getLocalVar(VAR_ITEM)

    if shouldOn and isOn and appliedId == bodyId then
        return
    end

    if isOn then
        clearBonuses(player)
        refreshSpeed(player)
    end

    if shouldOn then
        applyBonuses(player, bodyId)
    end
end

local function attachLivery(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('EFFECTS_TICK', LISTENER_ID, function(playerArg)
        syncLivery(playerArg)
    end)

    -- Rebuild from scratch so a live reload applies speed after the first draft.
    if player:getLocalVar(VAR_ACTIVE) == 1 then
        clearBonuses(player)
    end

    syncLivery(player)
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
                    attachLivery(player)
                end
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attachLivery(player)
end)

-- FileWatcher discards addOverride; keep onGameIn live without a restart.
if not xi.player._ixi20LiveryGameIn then
    xi.player._ixi20LiveryGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attachLivery(player)
    end
end

local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local bodyId  = player:getEquipID(xi.slot.BODY)
    local nation  = LIVERIES[bodyId]
    local region  = player:getCurrentRegion()
    local owner   = GetRegionOwner(region)
    local should  = nation ~= nil and areaOwnedBy(player, nation)
    local army    = campaignControlForZone(player:getZoneID())
    player:printToPlayer(string.format(
        'Livery item=%u nation=%s zone=%u region=%u conquestOwner=%u campaign=%s should=%s active=%s speed=%u/%u',
        bodyId,
        tostring(nation),
        player:getZoneID(),
        region,
        owner,
        tostring(army),
        tostring(should),
        tostring(player:getLocalVar(VAR_ACTIVE) == 1),
        player:getSpeed(),
        player:getBaseSpeed()
    ), xi.msg.channel.SYSTEM_3)
end

xi.module.registerCommand('livery', commandObj)
xi.commands = xi.commands or {}
xi.commands.livery = commandObj

attachOnlinePlayers()

return m
