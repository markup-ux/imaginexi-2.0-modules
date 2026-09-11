-----------------------------------
-- Imagine XI 2.0 loot-progression economy (Lua).
-- Gil/sparks become XP. NPC/spark shops do not sell weapons or armor.
-- Remaining NPC/guild stock (bait, potions, craft mats, fishing rods) is free to use.
-- Vendor-sell XP is dropped combat gear and crystals (not shop goods or fishing tools).
-- Gear loot on Decent Challenge+ kills (starter through 20, shop catalog after) + NM XP burst.
-- Florist flowers for quests drop on their own DC+ roll (see ixi20_gear_loot).
-- No Soldier. Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_economy')
require('modules/custom/lua/ixi20_gear_loot')
require('scripts/globals/mobs')
require('scripts/globals/npc_util')
require('scripts/globals/shop')
require('scripts/globals/sparkshop')
require('scripts/globals/guild_shops')
-----------------------------------

local m = Module:new('ixi20_gil_economy')

local function filterStock(stock)
    return xi.ixi20_economy.filterShopStock(stock)
end

local function explainNoGearShop(player)
    player:printToPlayer(
        'Weapons and armor are not sold in shops. Hunt zone camps for equipment.',
        xi.msg.channel.SYSTEM_3
    )
end

m:addOverride('xi.shop.general', function(player, stock, log)
    local filtered, usedFallback = xi.ixi20_economy.shopStockForClient(stock)
    if #filtered == 0 then
        return
    end

    if usedFallback then
        explainNoGearShop(player)
    end

    super(player, filtered, log)
end)

m:addOverride('xi.shop.generalGuild', function(player, stock, guildSkillId)
    local filtered, usedFallback = xi.ixi20_economy.shopStockForClient(stock)
    if #filtered == 0 then
        return
    end

    if usedFallback then
        explainNoGearShop(player)
    end

    super(player, filtered, guildSkillId)
end)

m:addOverride('xi.shop.curioVendorMoogle', function(player, stock)
    local filtered = filterStock(stock)
    -- Curio only adds items the player has the key item for. A dummy row
    -- without a KI would still send a 0-item shop and crash the client.
    if #filtered == 0 then
        explainNoGearShop(player)
        return
    end

    super(player, filtered)
end)

m:addOverride('xi.guildShops.onBuyList', function(player, npc)
    local items = super(player, npc) or {}
    xi.ixi20_economy.zeroGuildShopBuyPrices(npc)

    local filtered = {}
    for _, entry in ipairs(items) do
        if not xi.ixi20_economy.isBlockedShopItem(entry.id) then
            entry.price = xi.ixi20_economy.freeShopPrice(entry.price)
            filtered[#filtered + 1] = entry
        end
    end

    return filtered
end)

m:addOverride('xi.guildShops.onPlayerBuy', function(player, npc, itemId, quantity)
    if xi.ixi20_economy.isBlockedShopItem(itemId) then
        explainNoGearShop(player)
        return { itemNo = 0, count = 0, tradeCode = -1 }
    end

    -- Roll the shop day, then force 0 gil before super charges.
    xi.guildShops.onBuyList(player, npc)
    return super(player, npc, itemId, quantity)
end)

m:addOverride('xi.shop.onSellPriceCheck', function(player, itemId, fameArea)
    if xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED and not xi.ixi20_economy.grantsVendorSellExp(itemId) then
        return 0
    end

    return super(player, itemId, fameArea)
end)

m:addOverride('xi.guildShops.onSellList', function(player, npc)
    xi.ixi20_economy.zeroGuildShopSellPrices(npc)
    return super(player, npc)
end)

m:addOverride('xi.guildShops.onPlayerSell', function(player, npc, itemId, quantity)
    xi.ixi20_economy.zeroGuildShopSellPrices(npc)
    return super(player, npc, itemId, quantity)
end)

m:addOverride('npcUtil.giveCurrency', function(player, currency, amount, useTreasurePoolMsg)
    currency = string.lower(currency)

    if currency == 'gil' and xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED and amount > 0 then
        amount = amount * xi.settings.main.GIL_RATE
        local expAmount = xi.ixi20_economy.gilToExpAmount(amount)
        xi.ixi20_economy.grantExperience(player, expAmount)

        if useTreasurePoolMsg then
            player:messageSystem(xi.msg.system.OBTAINS_GIL, amount)
        else
            local ID = zones[player:getZoneID()]
            if ID and ID.text.GIL_OBTAINED then
                player:messageSpecial(ID.text.GIL_OBTAINED, amount)
            end
        end

        return true
    end

    return super(player, currency, amount, useTreasurePoolMsg)
end)

m:addOverride('npcUtil.giveReward', function(player, params)
    params = params or {}

    if params['gil'] ~= nil and type(params['gil']) == 'number' and xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED then
        local gilAmount = params['gil'] * xi.settings.main.GIL_RATE
        local expAmount = xi.ixi20_economy.gilToExpAmount(gilAmount)
        xi.ixi20_economy.grantExperience(player, expAmount)

        local ID = zones[player:getZoneID()]
        if ID and ID.text.GIL_OBTAINED then
            player:messageSpecial(ID.text.GIL_OBTAINED, gilAmount)
        end

        params['gil'] = nil
    end

    return super(player, params)
end)

m:addOverride('xi.sparkshop.onEventUpdate', function(player, csid, option, npc)
    local category = bit.band(option, 0xFF)

    if xi.settings.main.IMAGINEXI_BLOCK_SPARK_GEAR and xi.ixi20_economy.isSparkShopGearCategory(category) then
        local sparks = player:getCurrency('spark_of_eminence')
        local remainingLimit = xi.settings.main.WEEKLY_EXCHANGE_LIMIT - player:getCharVar('weekly_sparks_spent')
        player:printToPlayer('Progression gear is not sold for Sparks of Eminence. Fight Decent Challenge or tougher for shop-tier equipment.', xi.msg.channel.SYSTEM_3)
        player:updateEvent(sparks, 0, 0, 0, 0, remainingLimit)
        return
    end

    super(player, csid, option, npc)
end)

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    xi.imagine_gear_loot.tryGrantJobCrate(player)
    xi.imagine_gear_loot.ensureCatchupTracking(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    xi.imagine_gear_loot.tryGrantJobCrate(player)
    xi.imagine_gear_loot.ensureCatchupTracking(player)
end)

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    xi.imagine_gear_loot.onPlayerLevelUp(player)
end)

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    xi.imagine_gear_loot.onMobDeath(mob, player)
end)

-- addOverride is discarded on FileWatcher reload; assignment wrap is not.
xi.ixi20_economy.installShopClientGuard()
xi.ixi20_economy.installGuildSellGuard()

return m
