-----------------------------------
-- Imagine XI 2.0: any NPC-sellable item (mob drops, junk, seals, gear)
-- converts to XP. Fishing tools stay 0. Pair with ixi20_gil_economy.cpp
-- which prefers Ixi20GrantsVendorSellExp when this module is loaded.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_economy')
-----------------------------------

local m = Module:new('ixi20_mob_drop_sell')

function Ixi20GrantsVendorSellExp(itemId)
    if not xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED or not xi.settings.main.IMAGINEXI_VENDOR_SELL_TO_EXP then
        return false
    end

    if xi.ixi20_economy.isFishingShopItem(itemId) then
        return false
    end

    return true
end

local function grants(itemId)
    return Ixi20GrantsVendorSellExp(itemId)
end

xi.ixi20_economy.grantsVendorSellExp = grants

m:addOverride('xi.shop.onSellPriceCheck', function(player, itemId, fameArea)
    local price = super(player, itemId, fameArea)
    if price == 0 and Ixi20GrantsVendorSellExp(itemId) then
        return 1
    end

    return price
end)

if xi.shop then
    xi.ixi20MobDropSell = xi.ixi20MobDropSell or {}
    if not xi.ixi20MobDropSell.stockPriceCheck then
        xi.ixi20MobDropSell.stockPriceCheck = xi.shop.onSellPriceCheck
    end

    xi.shop.onSellPriceCheck = function(player, itemId, fameArea)
        local price = xi.ixi20MobDropSell.stockPriceCheck(player, itemId, fameArea)
        if price == 0 and Ixi20GrantsVendorSellExp(itemId) then
            return 1
        end

        return price
    end
end

return m
