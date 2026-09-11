-----------------------------------
-- Imagine XI 2.0: every player gets the server linkshell "Imagine"
-- (forest green with a hint of navy). C++ creates the LS if missing.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_imagine_linkshell')

local LS_NAME = 'Imagine'
local PEARL   = 515
local SACK    = 514

local function hasImaginePearl(player)
    for _, itemId in ipairs({ PEARL, SACK }) do
        local items = player:findItems(itemId)
        if items then
            for _, item in pairs(items) do
                if item and item.getSignature and item:getSignature() == LS_NAME then
                    return true
                end
            end
        end
    end

    return false
end

local function grantImagineLinkshell(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if hasImaginePearl(player) then
        return
    end

    -- Equip on LS2 so a personal LS1 is not replaced.
    player:addLinkpearl(LS_NAME, true)
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantImagineLinkshell(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        grantImagineLinkshell(player)
    end
end)

return m
