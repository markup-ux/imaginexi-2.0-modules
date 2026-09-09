-----------------------------------
-- Imagine XI 2.0: max inventory + all mog storage
-- 80 slots on inventory, Safe, Safe 2, Storage, Locker, Satchel, Sack,
-- Case, and Wardrobes 1-8. Mog Locker is all-areas with no lease expiry.
-- Mog House 2F (Safe 2 access) is unlocked.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/moghouse')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_max_storage')

local MAX_SLOTS = 80
-- Same clock as hasMogLockerAccess (earth_time::vanadiel_timestamp).
-- char_vars are INT(11); keep the lease at the signed max.
local LOCKER_EXPIRY_MAX = 2147483647
local MH_2F_UNLOCK      = 0x0020

local containers =
{
    xi.inv.INVENTORY,
    xi.inv.MOGSAFE,
    xi.inv.STORAGE,
    xi.inv.MOGLOCKER,
    xi.inv.MOGSATCHEL,
    xi.inv.MOGSACK,
    xi.inv.MOGCASE,
    xi.inv.WARDROBE,
    xi.inv.MOGSAFE2,
    xi.inv.WARDROBE2,
    xi.inv.WARDROBE3,
    xi.inv.WARDROBE4,
    xi.inv.WARDROBE5,
    xi.inv.WARDROBE6,
    xi.inv.WARDROBE7,
    xi.inv.WARDROBE8,
}

local function maxContainer(player, container)
    local current = player:getContainerSize(container)
    if current < MAX_SLOTS then
        player:changeContainerSize(container, MAX_SLOTS - current)
    end
end

local function unlockMogHouse2F(player)
    local mhflag = player:getMoghouseFlag()
    if bit.band(mhflag, MH_2F_UNLOCK) == 0 then
        player:setMoghouseFlag(mhflag + MH_2F_UNLOCK)
    end
end

local function openMogLocker(player)
    local allAreas = xi.moghouse.lockerAccessType.ALLAREAS
    if player:getCharVar(xi.moghouse.MOGLOCKER_PLAYERVAR_ACCESS_TYPE) ~= allAreas then
        player:setCharVar(xi.moghouse.MOGLOCKER_PLAYERVAR_ACCESS_TYPE, allAreas)
    end

    if player:getCharVar('mog-locker-expiry-timestamp') < LOCKER_EXPIRY_MAX then
        player:setCharVar('mog-locker-expiry-timestamp', LOCKER_EXPIRY_MAX)
        return true
    end

    return false
end

local function grantMaxStorage(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    unlockMogHouse2F(player)

    local lockerWasMax = player:getContainerSize(xi.inv.MOGLOCKER) >= MAX_SLOTS
    local lockerLeaseChanged = openMogLocker(player)

    for i = 1, #containers do
        maxContainer(player, containers[i])
    end

    -- ITEM_MAX uses hasMogLockerAccess; refresh if size was already 80.
    if lockerWasMax and lockerLeaseChanged then
        player:changeContainerSize(xi.inv.MOGLOCKER, 0)
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantMaxStorage(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        grantMaxStorage(player)
    end
end)

return m
