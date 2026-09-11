-----------------------------------
-- Overlay hairstyle sync. Stores a cosmetic style id and whispers it to the
-- zone on a chat mode the retail client does not print (channel 9).
-- Does not change char_look. Only Imagine XI overlay users apply the fake hair.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_overlay_hair')

local VAR = 'ixi20Hair'
local PREFIX = 'IXI20HAIR|'
local HIDDEN_CHANNEL = 9
local MAX_STYLE = 32

local function isPlayer(entity)
    return entity ~= nil and entity.isPC ~= nil and entity:isPC()
end

local function payload(player, styleId)
    return string.format('%s%u|%u', PREFIX, player:getID(), styleId or 0)
end

local function sendHidden(target, message)
    if not isPlayer(target) then
        return
    end

    target:printToPlayer(message, HIDDEN_CHANNEL)
end

local function styleOf(player)
    if not isPlayer(player) then
        return 0
    end

    local styleId = player:getCharVar(VAR) or 0
    if styleId < 0 or styleId > MAX_STYLE then
        return 0
    end

    return styleId
end

local function broadcastSelf(player)
    if not isPlayer(player) then
        return
    end

    local zone = player:getZone()
    if not zone then
        return
    end

    local message = payload(player, styleOf(player))
    for _, other in pairs(zone:getPlayers() or {}) do
        sendHidden(other, message)
    end
end

local function sendSnapshot(player)
    if not isPlayer(player) then
        return
    end

    local zone = player:getZone()
    if not zone then
        return
    end

    for _, other in pairs(zone:getPlayers() or {}) do
        if isPlayer(other) then
            sendHidden(player, payload(other, styleOf(other)))
        end
    end
end

local function setStyle(player, styleId)
    if not isPlayer(player) then
        return
    end

    styleId = tonumber(styleId) or 0
    if styleId < 0 or styleId > MAX_STYLE then
        styleId = 0
    end

    player:setCharVar(VAR, styleId)
    broadcastSelf(player)
    sendSnapshot(player)
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if not isPlayer(player) then
        return
    end

    player:timer(2000, function(p)
        sendSnapshot(p)
        broadcastSelf(p)
    end)
end)

local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

commandObj.onTrigger = function(player, arg)
    if not isPlayer(player) then
        return
    end

    arg = string.lower(tostring(arg or ''))
    if arg == '' or arg == 'sync' then
        sendSnapshot(player)
        broadcastSelf(player)
        return
    end

    setStyle(player, tonumber(arg) or 0)
end

xi.module.registerCommand('ixihair', commandObj)
xi.commands = xi.commands or {}
xi.commands.ixihair = commandObj

return m
