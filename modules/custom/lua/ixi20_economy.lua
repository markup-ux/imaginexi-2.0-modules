-----------------------------------
-- Imagine XI 2.0 loot-progression economy helpers (not a Module).
-----------------------------------
xi = xi or {}
xi.ixi20_economy = xi.ixi20_economy or {}

local M = xi.ixi20_economy

---@param gilAmount integer
---@return integer
function M.gilToExpAmount(gilAmount)
    if gilAmount <= 0 then
        return 0
    end

    local ratio = xi.settings.main.IMAGINEXI_GIL_TO_EXP_RATIO or 1.0
    return math.floor(gilAmount * ratio)
end

---@param sparkAmount integer
---@return integer
function M.sparksToExpAmount(sparkAmount)
    if sparkAmount <= 0 then
        return 0
    end

    local ratio = xi.settings.main.IMAGINEXI_SPARKS_TO_EXP_RATIO or 1.0
    return math.floor(sparkAmount * ratio)
end

---@param player CBaseEntity
---@param expAmount integer
function M.grantExperience(player, expAmount)
    if expAmount > 0 then
        player:addExp(expAmount)
    end
end

--- Approximate C++ CMobEntity::GetRandomGil for death conversion.
---@param mob CBaseEntity
---@return integer
function M.estimateMobGil(mob)
    local minG = mob:getMobMod(xi.mobMod.GIL_MIN)
    local maxG = mob:getMobMod(xi.mobMod.GIL_MAX)
    if maxG < 0 then
        return 0
    end

    if minG ~= 0 and maxG ~= 0 then
        if maxG <= minG then
            return minG
        end

        return math.random(minG, maxG - 1)
    end

    local gil = mob:getMainLvl() ^ 1.05
    if gil < 1 then
        gil = 1
    end

    local highGil = math.floor(gil / 3 + 4)
    if maxG ~= 0 then
        highGil = maxG
    end

    if highGil < 2 then
        highGil = 2
    end

    gil = gil + math.random(0, highGil - 1)
    if minG ~= 0 and gil < minG then
        gil = minG
    end

    local bonus = mob:getMobMod(xi.mobMod.GIL_BONUS)
    if bonus ~= 0 then
        gil = gil * (bonus / 100)
    end

    return math.floor(gil)
end

--- Convert would-be mob gil into XP (MOB_GIL_MULTIPLIER is 0 so no inventory gil).
---@param mob CBaseEntity
---@param player CBaseEntity
function M.grantMobGilAsExp(mob, player)
    if not xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED then
        return
    end

    if not player or not player.isPC or not player:isPC() then
        return
    end

    if mob:getLocalVar('IXI20_GIL_XP_SET') == 0 then
        mob:setLocalVar('IXI20_GIL_XP_SET', 1)
        mob:setLocalVar('IXI20_GIL_XP', M.estimateMobGil(mob))
    end

    local total = mob:getLocalVar('IXI20_GIL_XP')
    if total <= 0 then
        return
    end

    local tooWeakLoot = xi.ixi20_too_weak_loot
    if
        tooWeakLoot and
        tooWeakLoot.shouldSuppressPlayerReward and
        tooWeakLoot.shouldSuppressPlayerReward(player, mob)
    then
        return
    end

    local shareCount = 0
    for _, member in ipairs(player:getAlliance()) do
        if
            member.isPC and
            member:isPC() and
            member:getZoneID() == mob:getZoneID() and
            member:checkDistance(mob) <= 100 and
            not (
                tooWeakLoot and
                tooWeakLoot.shouldSuppressPlayerReward and
                tooWeakLoot.shouldSuppressPlayerReward(member, mob)
            )
        then
            shareCount = shareCount + 1
        end
    end

    M.grantExperience(player, M.gilToExpAmount(math.floor(total / math.max(1, shareCount))))
end

--- Spark shop equipment pages (3-11) sell progression gear; page 1 consumables stay spark-priced.
---@param category integer
---@return boolean
function M.isSparkShopGearCategory(category)
    return category >= 3 and category <= 11
end

-- Weapon/armor item ID ranges cover most shop progression gear without a DB lookup in Lua.
-- Fishing rods and bait sit in the weapon ID block but are hobby tools, not combat gear.
local blockedSlotRanges =
{
    { 16000, 16999 }, -- head
    { 12544, 12999 }, -- body/hands/legs/feet armor
    { 16384, 18499 }, -- weapons
    { 18720, 18999 }, -- ranged ammo-adjacent weapons
    { 20768, 21295 }, -- eminent / high-tier weapons
    { 27648, 27999 }, -- SoA head pieces
}

function M.isFishingShopItem(itemId)
    local item = GetReadOnlyItem(itemId)
    return item ~= nil and item:getSkillType() == xi.skill.FISHING
end

--- Vendor-sell XP is dropped combat gear plus elemental crystals/clusters.
--- Free shop goods (bait, potions, scrolls, mats, fishing rods) stay at 0.
---@param itemId integer
---@return boolean
function M.isElementalCrystal(itemId)
    local fire = (xi.item and xi.item.FIRE_CRYSTAL) or 4096
    local darkCluster = (xi.item and xi.item.DARK_CLUSTER) or 4111
    return itemId >= fire and itemId <= darkCluster
end

---@param itemId integer
---@return boolean
function M.grantsVendorSellExp(itemId)
    if not xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED or not xi.settings.main.IMAGINEXI_VENDOR_SELL_TO_EXP then
        return false
    end

    if M.isElementalCrystal(itemId) then
        return true
    end

    local item = GetReadOnlyItem(itemId)
    if item == nil or M.isFishingShopItem(itemId) then
        return false
    end

    return item:isType(xi.itemType.WEAPON) or item:isType(xi.itemType.ARMOR)
end

---@param itemId integer
---@return boolean
function M.isBlockedShopItem(itemId)
    if not xi.settings.main.IMAGINEXI_BLOCK_SHOP_GEAR then
        return false
    end

    if M.isFishingShopItem(itemId) then
        return false
    end

    for _, range in ipairs(blockedSlotRanges) do
        if itemId >= range[1] and itemId <= range[2] then
            return true
        end
    end

    return false
end

---@param stock table
---@return table
function M.filterShopStock(stock)
    if not xi.settings.main.IMAGINEXI_BLOCK_SHOP_GEAR then
        return stock
    end

    local filtered = {}
    for _, entry in ipairs(stock) do
        local itemId = entry[1]
        if type(itemId) == 'number' and not M.isBlockedShopItem(itemId) then
            table.insert(filtered, entry)
        end
    end

    return filtered
end

---@param price integer
---@return integer
function M.freeShopPrice(price)
    if xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED then
        return 0
    end

    return price
end

---@param npc CBaseEntity
---@return string
function M.canonicalGuildShopName(npc)
    local name   = npc:getName()
    local shops  = xi.data and xi.data.guildShops
    local cfg    = shops and shops[name]
    return (cfg and cfg.sharedStock) or name
end

local function guildShopState(npc)
    if not xi.guildShops or not xi.guildShops.state then
        return nil
    end

    local state = xi.guildShops.state[M.canonicalGuildShopName(npc)]
    if not state or not state.items then
        return nil
    end

    return state
end

--- Guild buy uses in-memory prices, not the packet list. Zero the live state so 0-gil buys stick.
---@param npc CBaseEntity
function M.zeroGuildShopBuyPrices(npc)
    if not xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED then
        return
    end

    local state = guildShopState(npc)
    if not state then
        return
    end

    for _, item in pairs(state.items) do
        item.buyPrice = 0
    end
end

--- Guild sell-back uses C++ earn() (real inventory gil), not addGil. Always 0 while gil is XP.
---@param npc CBaseEntity
function M.zeroGuildShopSellPrices(npc)
    if not xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED then
        return
    end

    local state = guildShopState(npc)
    if not state then
        return
    end

    for _, item in pairs(state.items) do
        item.sellPrice = 0
    end
end

-- FFXiMain access-violates on 0-item shop open/list packets (0x03E/0x03C, +0xF8B49).
-- Gear-only vendors would otherwise open empty after filterShopStock.
---@param stock table
---@return table
---@return boolean usedFallback
function M.shopStockForClient(stock)
    if type(stock) ~= 'table' or #stock == 0 then
        return {}, false
    end

    local filtered = M.filterShopStock(stock)
    if #filtered > 0 then
        return filtered, false
    end

    -- Keep the window open so vendor sell (gil -> XP) still works.
    local water = (xi.item and xi.item.FLASK_OF_DISTILLED_WATER) or 4509
    return { { water, 12 } }, true
end

local function explainNoGearShop(player)
    if player and player.printToPlayer then
        player:printToPlayer(
            'Weapons and armor are not sold in shops. Hunt zone camps for equipment.',
            xi.msg.channel.SYSTEM_3
        )
    end
end

-- FileWatcher re-runs module files then discards addOverride() registrations, so
-- xi.shop.general must be replaced by assignment or the empty-shop crash stays live.
function M.installShopClientGuard()
    if not xi.shop then
        return
    end

    if type(xi.shop.general) == 'function' then
        if not M._rawShopGeneral then
            M._rawShopGeneral = xi.shop.general
        end

        local rawGeneral = M._rawShopGeneral
        xi.shop.general = function(player, stock, log)
            local filtered, usedFallback = M.shopStockForClient(stock)
            if #filtered == 0 then
                return
            end

            if usedFallback then
                explainNoGearShop(player)
            end

            rawGeneral(player, filtered, log)
        end
    end

    if type(xi.shop.generalGuild) == 'function' then
        if not M._rawShopGeneralGuild then
            M._rawShopGeneralGuild = xi.shop.generalGuild
        end

        local rawGuild = M._rawShopGeneralGuild
        xi.shop.generalGuild = function(player, stock, guildSkillId)
            local filtered, usedFallback = M.shopStockForClient(stock)
            if #filtered == 0 then
                return
            end

            if usedFallback then
                explainNoGearShop(player)
            end

            rawGuild(player, filtered, guildSkillId)
        end
    end

    if type(xi.shop.onSellPriceCheck) == 'function' then
        if not M._rawOnSellPriceCheck then
            M._rawOnSellPriceCheck = xi.shop.onSellPriceCheck
        end

        local rawSellPrice = M._rawOnSellPriceCheck
        xi.shop.onSellPriceCheck = function(player, itemId, fameArea)
            if xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED and not M.grantsVendorSellExp(itemId) then
                return 0
            end

            return rawSellPrice(player, itemId, fameArea)
        end
    end
end

-- FileWatcher also drops guild addOverride; keep sell-back at 0 gil.
function M.installGuildSellGuard()
    if not xi.guildShops then
        return
    end

    if type(xi.guildShops.onSellList) == 'function' then
        if not M._rawGuildOnSellList then
            M._rawGuildOnSellList = xi.guildShops.onSellList
        end

        local rawSellList = M._rawGuildOnSellList
        xi.guildShops.onSellList = function(player, npc)
            M.zeroGuildShopSellPrices(npc)
            return rawSellList(player, npc)
        end
    end

    if type(xi.guildShops.onPlayerSell) == 'function' then
        if not M._rawGuildOnPlayerSell then
            M._rawGuildOnPlayerSell = xi.guildShops.onPlayerSell
        end

        local rawPlayerSell = M._rawGuildOnPlayerSell
        xi.guildShops.onPlayerSell = function(player, npc, itemId, quantity)
            M.zeroGuildShopSellPrices(npc)
            return rawPlayerSell(player, npc, itemId, quantity)
        end
    end
end

M.installShopClientGuard()
M.installGuildSellGuard()
