-----------------------------------
-- Imagine XI 2.0: every player can use all WotG Cavernous Maws.
-- Grants the Pure White Feather and all past-maw teleports on create / login.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/maws')
require('scripts/globals/player')
require('scripts/globals/teleports')
-----------------------------------

local m = Module:new('ixi20_cavernous_maws')

local MAW_BITS = 8 -- pastMaws bits 0-8

local function grantMawAccess(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if not player:hasKeyItem(xi.ki.PURE_WHITE_FEATHER) then
        player:addKeyItem(xi.ki.PURE_WHITE_FEATHER)
    end

    for bit = 0, MAW_BITS do
        if not player:hasTeleport(xi.teleport.type.PAST_MAW, bit) then
            player:addTeleport(xi.teleport.type.PAST_MAW, bit)
        end
    end
end

local function install()
    if not xi.maws or not xi.maws.onTrigger then
        return
    end

    xi.ixi20CavernousMaws = xi.ixi20CavernousMaws or {}
    if not xi.ixi20CavernousMaws.stockOnTrigger then
        xi.ixi20CavernousMaws.stockOnTrigger = xi.maws.onTrigger
    end

    xi.maws.onTrigger = function(player, npc)
        grantMawAccess(player)
        return xi.ixi20CavernousMaws.stockOnTrigger(player, npc)
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantMawAccess(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    grantMawAccess(player)
end)

m:addOverride('xi.maws.onTrigger', function(player, npc)
    grantMawAccess(player)
    return super(player, npc)
end)

install()
