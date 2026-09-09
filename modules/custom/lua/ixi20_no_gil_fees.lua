-----------------------------------
-- Imagine XI 2.0: no gil usage fees
-- Gil converts to XP, so homepoints / outposts / survival guides / airships /
-- chocobos / maps / and other "pay gil to use" services must not require a wallet.
-- Pair with ixi20_no_gil_fees.cpp (getGil afford-checks + delGil no-op).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/conquest')
require('scripts/globals/homepoint')
require('scripts/globals/teleports')
require('scripts/globals/teleports/survival_guide')
-----------------------------------

local survival = require('scripts/globals/teleports/survival_guide_map')

local m = Module:new('ixi20_no_gil_fees')

-- Client menus read this event param to decide if a destination is affordable.
-- Real inventory gil stays 0; only script/event checks see this.
local AFFORD_GIL = 99999999

xi.ixi20_no_gil_fees = xi.ixi20_no_gil_fees or {}

function xi.ixi20_no_gil_fees.affordGil()
    return AFFORD_GIL
end

function xi.ixi20_no_gil_fees.realGil(player)
    if player and player.getRealGil then
        return player:getRealGil() or 0
    end

    return player and player.getGil and player:getGil() or 0
end

-- FileWatcher drops addOverride; assignment keeps outpost menus at 0 gil.
if type(xi.conquest.outpostFee) == 'function' then
    xi.conquest.outpostFee = function()
        return 0
    end
end

-- Sagheera (Port Jeuno): Cosmo-Cleanse for Limbus. Stock is 15,000 gil
-- (1,000 with Rhapsody in Mauve). Client still paints that number; the
-- dummy wallet lets the line stay selectable. Server cost is 0.
local function cosmoCleanseReady(player)
    local wait = player:hasKeyItem(xi.ki.RHAPSODY_IN_MAUVE) and 3600 or 72000
    local last = player:getCharVar('Cosmo_Cleanse_TIME')
    if last ~= 0 then
        last = last + wait
    end

    return last <= GetSystemTime()
end

m:addOverride('xi.server.onServerStart', function()
    super()
    xi.settings.main.COSMO_CLEANSE_BASE_COST = 0
end)

m:addOverride('xi.zones.Port_Jeuno.npcs.Sagheera.onEventFinish', function(player, csid, option, npc)
    local opt = bit.band(option, 65535)
    if csid == 310 and opt == 3 then
        if
            not player:hasKeyItem(xi.ki.COSMO_CLEANSE) and
            cosmoCleanseReady(player)
        then
            player:setCharVar('SagheeraInteractions', utils.mask.setBit(player:getCharVar('SagheeraInteractions'), 0, false))
            npcUtil.giveKeyItem(player, xi.ki.COSMO_CLEANSE)
        end

        return
    end

    super(player, csid, option, npc)
end)

m:addOverride('xi.homepoint.onTrigger', function(player, csid, index)
    if xi.settings.main.HOMEPOINT_TELEPORT ~= 1 then
        player:startEvent(csid, 0, 0, 0, 0, 0, AFFORD_GIL, 4095, index)
        return
    end

    local hpBit  = index % 32
    local hpSet  = math.floor(index / 32)
    local menu   = player:getTeleportMenu(xi.teleport.type.HOMEPOINT)
    local params = bit.bor(index, bit.lshift(menu[10] < 1 and 0 or 1, 18))

    if not player:hasTeleport(xi.teleport.type.HOMEPOINT, hpBit, hpSet) then
        player:addTeleport(xi.teleport.type.HOMEPOINT, hpBit, hpSet)
        params = bit.bor(params, 0x10000)
    end

    if player:hasKeyItem(xi.ki.RHAPSODY_IN_WHITE) then
        params = bit.bor(params, 0x20000)
    end

    player:setLocalVar('originIndex', index)

    local g1, g2, g3, g4 = unpack(player:getTeleportTable(xi.teleport.type.HOMEPOINT))
    player:startEvent(csid, 1, g1, g2, g3, g4, AFFORD_GIL, 4095, params)
end)

m:addOverride('xi.survivalGuide.onTrigger', function(player)
    local tableIndex = survival.zoneIdToGuideIdMap[player:getZoneID()]
    local guide      = survival.survivalGuides[tableIndex]
    if not guide then
        return
    end

    local registered = player:hasTeleport(xi.teleport.type.SURVIVAL, guide.groupIndex - 1, guide.group - 1)
    if not registered then
        player:messageSpecial(zones[guide.zoneId].text.COMMON_SENSE_SURVIVAL)
        player:addTeleport(xi.teleport.type.SURVIVAL, guide.groupIndex - 1, guide.group - 1)
        return
    end

    local noTutorialFlag = 0x4000
    local tabsCurrency   = bit.lshift(player:getCurrency('valor_point'), 16)
    local param          = bit.bor(tableIndex, tabsCurrency + noTutorialFlag)

    -- 0x0400 = all mog tablets found: client shows a free warp.
    param = bit.bor(param, 0x0400)

    local teleportMenu = player:getTeleportMenu(xi.teleport.type.SURVIVAL)
    if teleportMenu[10] == 1 then
        param = bit.bor(param, 0x0800)
    end

    if player:hasKeyItem(xi.ki.RHAPSODY_IN_WHITE) then
        param = bit.bor(param, 0x2000)
    end

    if player:getCharVar('TutorialBypass') == 2 then
        param = bit.band(param, bit.bnot(0x4000))
    end

    local g1, g2, g3, g4 = unpack(player:getTeleportTable(xi.teleport.type.SURVIVAL))
    local expansions = 3 + 4 * xi.settings.main.ENABLE_COP + 8 * xi.settings.main.ENABLE_TOAU + 16 * xi.settings.main.ENABLE_WOTG + 2048 * xi.settings.main.ENABLE_SOA

    player:startEvent(8500, 0, param, AFFORD_GIL, g1, g2, g3, g4, expansions)
end)

m:addOverride('xi.survivalGuide.onEventFinish', function(player, eventId, option, npc)
    if eventId ~= 8500 then
        return
    end

    if bit.band(option, 0xFF) ~= 1 then
        return
    end

    local selectedMenuId = bit.rshift(option, 16)
    if selectedMenuId > 97 then
        return
    end

    local guide = survival.survivalGuides[selectedMenuId]
    if not guide then
        return
    end

    if guide.zoneId == player:getZoneID() then
        return
    end

    if player:checkDistance(npc) > 6 then
        return
    end

    if not player:hasTeleport(xi.teleport.type.SURVIVAL, guide.groupIndex - 1, guide.group - 1) then
        return
    end

    player:setPos(guide.posX, guide.posY, guide.posZ, guide.posRot, guide.zoneId)
end)

m:addOverride('xi.teleport.explorerMoogleOnTrigger', function(player, event)
    if player:getMainLvl() < xi.settings.main.EXPLORER_MOOGLE_LV then
        event = event + 1
    end

    player:startEvent(event, player:getZoneID(), 0, 0)
end)

m:addOverride('xi.teleport.explorerMoogleOnEventFinish', function(player, csid, option, event)
    if csid ~= event then
        return
    end

    local destinations =
    {
        [1] = 231,
        [2] = 234,
        [3] = 240,
        [4] = 248,
        [5] = 249,
    }

    local zoneId = destinations[option]
    if zoneId then
        xi.teleport.toExplorerMoogle(player, zoneId)
    end
end)

return m
