-----------------------------------
-- Too Weak yields no loot (Imagine XI 2.0).
-- Shared drops / caskets stay if anyone nearby checks Easy Prey or better
-- (unsynced help still works). Steal, mug, and death-gil XP are per-player.
-- Registered via Module:new. Helpers live on xi.ixi20_too_weak_loot.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')
require('scripts/globals/caskets')
require('scripts/globals/job_utils/thief')
-----------------------------------

local m = Module:new('ixi20_too_weak_loot')

xi = xi or {}
xi.ixi20_too_weak_loot = xi.ixi20_too_weak_loot or {}

local M = xi.ixi20_too_weak_loot

local LISTENER_ID   = 'IXI20_TW_RESTORE_NODROPS'
local LV_SUPPRESSED = 'IXI20_TW_NODROPS'
local LV_ORIGINAL   = 'IXI20_TW_ORIG_NODROPS'
local LV_LISTENER   = 'IXI20_TW_LISTENER'
local LV_NOTIFY     = 'IXI20_TW_MSG'
local NOTIFY_GAP    = 30
local DEFAULT_RANGE = 100

local function settings()
    return xi.settings and xi.settings.main or {}
end

function M.enabled()
    return settings().IMAGINEXI_TOO_WEAK_NO_LOOT ~= false
end

local function lootRange()
    local range = settings().IMAGINEXI_TOO_WEAK_LOOT_RANGE
    if type(range) == 'number' and range > 0 then
        return range
    end

    return DEFAULT_RANGE
end

local function isPlayer(entity)
    return entity ~= nil and entity.isPC ~= nil and entity:isPC()
end

local function isMob(entity)
    return entity ~= nil and entity.isMob ~= nil and entity:isMob()
end

local function allianceMembers(player)
    if player.getAlliance then
        local alliance = player:getAlliance()
        if type(alliance) == 'table' and #alliance > 0 then
            return alliance
        end
    end

    return { player }
end

function M.playerChecksTooWeak(player, mob)
    if not isPlayer(player) or not isMob(mob) then
        return false
    end

    return player:checkDifficulty(mob) <= xi.mobDifficulty.TOO_WEAK
end

function M.shouldSuppressPlayerReward(player, mob)
    return M.enabled() and M.playerChecksTooWeak(player, mob)
end

function M.partyHasEligibleLoot(player, mob)
    if not isPlayer(player) or not isMob(mob) then
        return false
    end

    local range = lootRange()
    for _, member in ipairs(allianceMembers(player)) do
        if
            isPlayer(member) and
            not member:isDead() and
            member:getZoneID() == mob:getZoneID() and
            member:checkDistance(mob) <= range and
            not M.playerChecksTooWeak(member, mob)
        then
            return true
        end
    end

    return false
end

function M.shouldSuppressSharedLoot(player, mob)
    return M.enabled() and not M.partyHasEligibleLoot(player, mob)
end

function M.notify(player)
    if not isPlayer(player) then
        return
    end

    local now = os.time()
    if player:getLocalVar(LV_NOTIFY) > now then
        return
    end

    player:setLocalVar(LV_NOTIFY, now + NOTIFY_GAP)
    player:printToPlayer('This monster is too weak to yield items.', xi.msg.channel.SYSTEM_3)
end

function M.suppressMobDrops(mob)
    if not isMob(mob) or mob:getLocalVar(LV_SUPPRESSED) == 1 then
        return
    end

    mob:setLocalVar(LV_SUPPRESSED, 1)
    mob:setLocalVar(LV_ORIGINAL, mob:getMobMod(xi.mobMod.NO_DROPS))
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)

    if mob:getLocalVar(LV_LISTENER) == 0 then
        mob:setLocalVar(LV_LISTENER, 1)
        mob:addListener('SPAWN', LISTENER_ID, function(mobArg)
            if mobArg:getLocalVar(LV_SUPPRESSED) == 1 then
                mobArg:setMobMod(xi.mobMod.NO_DROPS, mobArg:getLocalVar(LV_ORIGINAL))
                mobArg:setLocalVar(LV_SUPPRESSED, 0)
            end
        end)
    end
end

local function blockJobAbility(player, target)
    if not M.shouldSuppressPlayerReward(player, target) then
        return false
    end

    M.notify(player)
    return true
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    if M.shouldSuppressSharedLoot(player, mob) then
        M.suppressMobDrops(mob)
        M.notify(player)
    end

    super(mob, player, isKiller, isWeaponSkillKill)
end)

m:addOverride('xi.caskets.spawnCasket', function(player, mob, x, y, z, r)
    if M.shouldSuppressSharedLoot(player, mob) then
        M.notify(player)
        return
    end

    return super(player, mob, x, y, z, r)
end)

m:addOverride('xi.job_utils.thief.checkSteal', function(player, target, ability)
    if blockJobAbility(player, target) then
        return xi.msg.basic.CANNOT_ON_THAT_TARG, 0
    end

    return super(player, target, ability)
end)

m:addOverride('xi.job_utils.thief.checkDespoil', function(player, target, ability)
    if blockJobAbility(player, target) then
        return xi.msg.basic.CANNOT_ON_THAT_TARG, 0
    end

    return super(player, target, ability)
end)

m:addOverride('xi.job_utils.thief.useSteal', function(player, target, ability, action)
    if blockJobAbility(player, target) then
        ability:setMsg(xi.msg.basic.STEAL_FAIL)
        action:setAnimation(target:getID(), 182)
        return 0
    end

    return super(player, target, ability, action)
end)

m:addOverride('xi.job_utils.thief.useDespoil', function(player, target, ability, action)
    if blockJobAbility(player, target) then
        action:setAnimation(target:getID(), 182)
        ability:setMsg(xi.msg.basic.STEAL_FAIL)
        return 0
    end

    return super(player, target, ability, action)
end)

m:addOverride('xi.job_utils.thief.useMug', function(player, target, ability, action)
    if blockJobAbility(player, target) then
        ability:setMsg(xi.msg.basic.MUG_FAIL)
        action:setAnimation(target:getID(), 184)
        return 0
    end

    return super(player, target, ability, action)
end)

return m
