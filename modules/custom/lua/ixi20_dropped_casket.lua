-----------------------------------
-- Persistent dropped-item caskets (customMenu loot only).
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_dropped_casket')

xi = xi or {}
xi.droppedCasket = xi.droppedCasket or {}

local CASKET_LOOK      = 966
local NPC_PREFIX       = 'Dropped_Item_Casket'
local LV_CASKET_ID     = '[droppedCasket]ID'
local LV_DESPAWNING    = '[droppedCasket]Despawning'
local ITEMS_PER_PAGE   = 10

-- Articles stay lowercase unless they start the name (matches FFXI inventory).
local MINOR_WORDS =
{
    a      = true,
    an     = true,
    ['and'] = true,
    of     = true,
    ['or']  = true,
    the    = true,
}

-- Spell/item suffixes stored as roman numerals in item_basic.name.
local ROMAN_NUMERALS =
{
    ii    = true,
    iii   = true,
    iv    = true,
    vi    = true,
    vii   = true,
    viii  = true,
    ix    = true,
    xi    = true,
    xii   = true,
    xiii  = true,
}

local function formatNameToken(token)
    if token:match('^%+%d+$') then
        return token
    end

    if token:sub(1, 1) == '#' then
        local rest = token:sub(2)
        if rest ~= '' then
            return '#' .. rest:sub(1, 1):upper() .. rest:sub(2):lower()
        end

        return token
    end

    local lower = token:lower()
    if ROMAN_NUMERALS[lower] then
        return lower:upper()
    end

    return lower:sub(1, 1):upper() .. lower:sub(2)
end

-- item:getName() is the lua/sql key (brass_flowerpot). Show the in-game label instead.
local function formatItemDisplayName(rawName)
    if not rawName or rawName == '' then
        return rawName
    end

    local words = {}
    for word in rawName:gmatch('[^_]+') do
        words[#words + 1] = word:gsub('([^%-]+)', formatNameToken)
    end

    for i = 2, #words do
        local lower = words[i]:lower()
        if MINOR_WORDS[lower] then
            words[i] = lower
        end
    end

    return table.concat(words, ' ')
end

local activeNpcs = {}

local function getZoneTable(zoneId)
    activeNpcs[zoneId] = activeNpcs[zoneId] or {}
    return activeNpcs[zoneId]
end

local function zoneText(player)
    return zones[player:getZoneID()].text
end

local function messageItemObtained(player, itemId, quantity)
    local ID = zoneText(player)
    if quantity and quantity > 1 then
        player:messageSpecial(ID.ITEM_OBTAINED + 9, itemId, quantity)
    else
        player:messageSpecial(ID.ITEM_OBTAINED, itemId)
    end
end

local function fetchCasketItems(casketId)
    if GetDroppedCasketItems then
        return GetDroppedCasketItems(casketId)
    end
    return {}
end

-- kesu alone hides the model but leaves a NORMAL NPC (collision + re-spawn
-- when a player re-enters range). Send ENTITY_DESPAWN now, then DISAPPEAR
-- so the next tick can release the dynamic id.
local function hideCasketNpc(npc)
    if not npc then
        return
    end

    if npc:getLocalVar(LV_DESPAWNING) == 1 then
        return
    end

    npc:setLocalVar(LV_DESPAWNING, 1)
    npc:setLocalVar(LV_CASKET_ID, 0)
    npc:setUntargetable(true)
    npc:entityAnimationPacket(xi.animationString.STATUS_DISAPPEAR)
    npc:setStatus(xi.status.DISAPPEAR)

    local zone = npc:getZone()
    if zone then
        for _, player in pairs(zone:getPlayers()) do
            if player and player.sendEntityUpdateToPlayer then
                player:sendEntityUpdateToPlayer(npc, xi.entityUpdate.ENTITY_DESPAWN, xi.updateType.UPDATE_NONE)
            end
        end
    end
end

local function despawnIfEmpty(player, zone, npc, casketId)
    if #fetchCasketItems(casketId) > 0 then
        return false
    end

    player:printToPlayer('The abandoned casket crumbles away.', xi.msg.channel.SYSTEM_3)
    xi.droppedCasket.despawnCasket(zone, casketId, npc)
    return true
end

local function openTextLootMenu(player, npc, casketId, page)
    page = page or 1
    local items = fetchCasketItems(casketId)

    if #items == 0 then
        despawnIfEmpty(player, player:getZone(), npc, casketId)
        return
    end

    local menu =
    {
        title   = 'Abandoned Items',
        options = {},
    }

    local startIdx = (page - 1) * ITEMS_PER_PAGE + 1
    local endIdx   = math.min(page * ITEMS_PER_PAGE, #items)

    for i = startIdx, endIdx do
        local entry = items[i]
        local item  = GetItemByID(entry.itemId)
        local label = item and formatItemDisplayName(item:getName()) or tostring(entry.itemId)
        if entry.quantity > 1 then
            label = string.format('%s x%u', label, entry.quantity)
        end

        menu.options[#menu.options + 1] =
        {
            label,
            function(p)
                if DropCasketItem and DropCasketItem(p, casketId, entry.slot) then
                    messageItemObtained(p, entry.itemId, entry.quantity)
                    if despawnIfEmpty(p, p:getZone(), npc, casketId) then
                        return
                    end
                    openTextLootMenu(p, npc, casketId, page)
                else
                    p:messageSpecial(zoneText(p).ITEM_CANNOT_BE_OBTAINED, entry.itemId)
                    openTextLootMenu(p, npc, casketId, page)
                end
            end,
        }
    end

    if page > 1 then
        menu.options[#menu.options + 1] =
        {
            '<< Previous',
            function(p)
                openTextLootMenu(p, npc, casketId, page - 1)
            end,
        }
    end

    if endIdx < #items then
        menu.options[#menu.options + 1] =
        {
            'Next >>',
            function(p)
                openTextLootMenu(p, npc, casketId, page + 1)
            end,
        }
    end

    menu.options[#menu.options + 1] =
    {
        'Leave',
        function(_)
        end,
    }

    player:timer(50, function(p)
        p:customMenu(menu)
    end)
end

local function onCasketTrigger(player, npc)
    if npc:getLocalVar(LV_DESPAWNING) == 1 then
        player:printToPlayer('The abandoned casket crumbles away.', xi.msg.channel.SYSTEM_3)
        return
    end

    local casketId = npc:getLocalVar(LV_CASKET_ID)
    if casketId == 0 then
        player:printToPlayer('There is nothing here.', xi.msg.channel.SYSTEM_3)
        hideCasketNpc(npc)
        return
    end

    if despawnIfEmpty(player, player:getZone(), npc, casketId) then
        return
    end

    openTextLootMenu(player, npc, casketId, 1)
end

xi.droppedCasket.spawnCasket = function(zone, casketId, x, y, z, rotation, isNew)
    if not zone or casketId == 0 then
        return
    end

    local zoneId   = zone:getID()
    local existing = getZoneTable(zoneId)[casketId]
    if existing then
        existing:setPos(x, y, z, rotation)
        existing:setUntargetable(false)
        existing:setStatus(xi.status.NORMAL)
        existing:setAnimationSub(0, false)
        existing:setLocalVar(LV_DESPAWNING, 0)
        existing:setLocalVar(LV_CASKET_ID, casketId)
        existing:entityAnimationPacket(xi.animationString.STATUS_VISIBLE)
        return
    end

    local npc = zone:insertDynamicEntity({
        objtype              = xi.objType.NPC,
        name                 = string.format('%s_%u', NPC_PREFIX, casketId),
        packetName           = 'Abandoned Casket',
        look                 = CASKET_LOOK,
        x                    = x,
        y                    = y,
        z                    = z,
        rotation             = rotation,
        widescan             = 1,
        releaseIdOnDisappear = true,
        onTrigger            = onCasketTrigger,
    })

    if npc then
        getZoneTable(zoneId)[casketId] = npc
        npc:setLocalVar(LV_CASKET_ID, casketId)
    else
        printf('[droppedCasket] insertDynamicEntity failed zone=%u casket=%u', zoneId, casketId)
    end
end

xi.droppedCasket.despawnCasket = function(zone, casketId, npcHint)
    if not zone or casketId == 0 then
        return
    end

    local zoneId = zone:getID()
    local npc    = npcHint or getZoneTable(zoneId)[casketId]
    hideCasketNpc(npc)
    getZoneTable(zoneId)[casketId] = nil
end

xi.droppedCasket.despawnAllInZone = function(zone)
    if not zone then
        return
    end

    local zoneId = zone:getID()
    local tbl    = getZoneTable(zoneId)
    for id, npc in pairs(tbl) do
        hideCasketNpc(npc)
        tbl[id] = nil
    end
end

local conquestCleanupDone = false

local function tryConquestCleanup(updatetype)
    if updatetype ~= 0 or conquestCleanupDone then -- 0 = TALLY_START
        return
    end

    conquestCleanupDone = true
    if CleanupDroppedCaskets then
        CleanupDroppedCaskets()
    end
end

m:addOverride('xi.conquest.onConquestUpdate', function(zone, updatetype, influence, owner, ranking, isConquestAlliance)
    super(zone, updatetype, influence, owner, ranking, isConquestAlliance)
    tryConquestCleanup(updatetype)
end)

m:addOverride('xi.conquest.onCityConquestUpdate', function(zone, updatetype, ranking, isconquestAlliance)
    super(zone, updatetype, ranking, isconquestAlliance)
    tryConquestCleanup(updatetype)
end)
