-----------------------------------
-- Imagine XI 2.0: GM Home test hub.
-- Job-change moogle, vendor (buy/sell), and a hare camp that grants
-- a full level of XP per kill so level-up messages can be tested.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/shop')
require('scripts/zones/GM_Home/Zone')
-----------------------------------

local m = Module:new('ixi20_gm_home_test_hub')

-- Enough for a ding through the 75 cap (exp_base 74→75 is 42000).
local KILL_EXP            = 45000
local HARE_LEVEL          = 1
local HARE_HP             = 1
local HARE_LOOK           = 268 -- Forest Hare
local HARE_GROUP_ID       = 5
local HARE_GROUP_ZONE_ID  = 154 -- Dragon's Aery (Fafnir group, stats overridden)
local HARE_RESPAWN        = 5
local MOOGLE_LOOK         = 981 -- Nomad Moogle
local SHOP_LOOK           = 150 -- Hume male

local shopStock =
{
    { xi.item.POTION,                    100 },
    { xi.item.ETHER,                     100 },
    { xi.item.ANTIDOTE,                  100 },
    { xi.item.FLASK_OF_ECHO_DROPS,       100 },
        { xi.item.LOAF_OF_BLACK_BREAD,       100 },
        { xi.item.FLASK_OF_DISTILLED_WATER,  100 },
    }

local hareSpawns =
{
    { 12.0, 0.0, 12.0, 192 },
    { 16.0, 0.0, 12.0, 192 },
    { 12.0, 0.0, 16.0, 192 },
    { 16.0, 0.0, 16.0, 192 },
    { 14.0, 0.0, 14.0, 192 },
    { 18.0, 0.0, 14.0, 192 },
}

local function grantKillExp(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:addExp(KILL_EXP)
end

local function applyHare(mob)
    if not mob then
        return
    end

    mob:setDropID(0)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
    mob:setMobMod(xi.mobMod.NO_AGGRO, 1)
    mob:setMobMod(xi.mobMod.NO_LINK, 1)
    mob:setMobMod(xi.mobMod.NO_MOVE, 1)
    mob:setMobMod(xi.mobMod.ROAM_DISTANCE, 0)
    mob:setMobMod(xi.mobMod.SIGHT_RANGE, 0)
    mob:setMobMod(xi.mobMod.SOUND_RANGE, 0)
    mob:setMobMod(xi.mobMod.SPECIAL_SKILL, 0)
    mob:setMobMod(xi.mobMod.EXP_BONUS, -100)
    mob:setBehavior(xi.behavior.NONE)
    mob:setAggressive(false)
    mob:setMagicCastingEnabled(false)
    mob:setMobAbilityEnabled(false)
    mob:setAutoAttackEnabled(false)
    mob:setMod(xi.mod.DEF, 0)
    mob:setMod(xi.mod.EVA, 0)
    mob:setMod(xi.mod.HP, 0)
    mob:setMod(xi.mod.HPP, 0)
    mob:setMod(xi.mod.BASE_HP, 0)
    if mob.setMobLevel then
        -- Fafnir group stats; recover=false so CalculateMobStats does not refill HP first.
        mob:setMobLevel(HARE_LEVEL, false)
    end

    mob:setMaxHP(HARE_HP)
    mob:setHP(HARE_HP)
end

local function restatHares(zone)
    if not zone or not zone.queryEntitiesByName then
        return
    end

    for index = 1, #hareSpawns do
        local found = zone:queryEntitiesByName(string.format('DE_XPHare%d', index))
        if found then
            for _, hare in pairs(found) do
                if hare then
                    applyHare(hare)
                end
            end
        end
    end
end

local function spawnMoogle(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'JobMoogle',
        packetName = 'Nomad Moogle',
        look       = MOOGLE_LOOK,
        x          = -8.0,
        y          = 0.0,
        z          = 2.0,
        rotation   = 0,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                'Kupo! Change jobs here — same menu as a Nomad Moogle.',
                xi.msg.channel.NS_SAY,
                npc:getPacketName()
            )
            player:sendMenu(xi.menuType.MOOGLE)
        end,
    })
end

local function spawnShop(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'TestVendor',
        packetName = 'Test Vendor',
        look       = SHOP_LOOK,
        x          = -8.0,
        y          = 0.0,
        z          = -2.0,
        rotation   = 0,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                'Buy is free. Vendor-sell XP is dropped weapons and armor only, not shop goods.',
                xi.msg.channel.NS_SAY,
                npc:getPacketName()
            )
            xi.shop.general(player, shopStock)
        end,
    })
end

local function spawnHares(zone)
    for index, pos in ipairs(hareSpawns) do
        local x, y, z, rot = pos[1], pos[2], pos[3], pos[4]
        local name         = string.format('XPHare%d', index)
        local hare         = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            name                 = name,
            packetName           = 'XP Hare',
            look                 = HARE_LOOK,
            groupId              = HARE_GROUP_ID,
            groupZoneId          = HARE_GROUP_ZONE_ID,
            minLevel             = HARE_LEVEL,
            maxLevel             = HARE_LEVEL,
            x                    = x,
            y                    = y,
            z                    = z,
            rotation             = rot,
            respawn              = HARE_RESPAWN,
            releaseIdOnDisappear = false,
            onMobSpawn           = function(mob)
                applyHare(mob)
            end,
            onMobDeath           = function(mob, player, optParams)
                grantKillExp(player)
            end,
        })

        if hare then
            hare:setSpawn(x, y, z, rot)
            hare:spawn()
            applyHare(hare)
        end
    end
end

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)
    spawnMoogle(zone)
    spawnShop(zone)
    spawnHares(zone)
end)

-- FileWatcher cannot re-run zone init. Restat already-spawned hares on zone-in
-- and on this file reload so they become lv1 / 1 HP without a map restart.
m:addOverride('xi.zones.GM_Home.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    restatHares(player.getZone and player:getZone())
    return cs
end)

if xi.zone and GetZone and xi.zone.GM_HOME then
    restatHares(GetZone(xi.zone.GM_HOME))
end

return m
