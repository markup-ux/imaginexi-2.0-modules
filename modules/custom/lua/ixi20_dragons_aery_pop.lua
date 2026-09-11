-----------------------------------
-- Dragon's Aery ??? click-pops Fafnir or Nidhogg. No Honey Wine / Sweet Tea.
-- FileWatcher discards addOverride; live assignment keeps the patch.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/npc_util')
-----------------------------------

local m = Module:new('ixi20_dragons_aery_pop')

local ID = zones[xi.zone.DRAGONS_AERY]

local function remainingLock(player, mob)
    if not player or not mob then
        return 0
    end

    if xi.ixi20HnmAccess and xi.ixi20HnmAccess.remainingLock then
        return xi.ixi20HnmAccess.remainingLock(player, mob:getName())
    end

    if xi.ixi20HnmAccess and xi.ixi20HnmAccess.isLocked and xi.ixi20HnmAccess.isLocked(player, mob) then
        return 1
    end

    return 0
end

local function formatRemain(seconds)
    if xi.ixi20HnmAccess and xi.ixi20HnmAccess.formatRemain then
        return xi.ixi20HnmAccess.formatRemain(seconds)
    end

    return string.format('%um', math.max(1, math.floor(seconds / 60)))
end

local function tryPop(player, npc)
    local fafnir  = GetMobByID(ID.mob.FAFNIR)
    local nidhogg = GetMobByID(ID.mob.NIDHOGG)
    if not fafnir or not nidhogg then
        return false
    end

    if fafnir:isSpawned() or nidhogg:isSpawned() then
        return false
    end

    local eligible = {}
    local locked   = {}
    for _, mob in ipairs({ fafnir, nidhogg }) do
        local remain = remainingLock(player, mob)
        if remain > 0 then
            locked[#locked + 1] = { mob = mob, remain = remain }
        else
            eligible[#eligible + 1] = mob
        end
    end

    if #eligible == 0 then
        for _, entry in ipairs(locked) do
            player:printToPlayer(string.format(
                'Your group is locked out of %s for %s.',
                entry.mob:getPacketName(),
                formatRemain(entry.remain)
            ), xi.msg.channel.SYSTEM_3, '')
        end

        return true
    end

    local pick = utils.randomEntry(eligible)
    return npcUtil.popFromQM(player, npc, pick:getID(), { claim = false, hide = 30 })
end

local function onTrigger(player, npc)
    if not tryPop(player, npc) then
        player:messageSpecial(ID.text.NOTHING_OUT_OF_ORDINARY)
    end
end

local function onTrade(player, npc, trade)
    tryPop(player, npc)
end

m:addOverride('xi.zones.Dragons_Aery.npcs.qm_fafnir.onTrigger', onTrigger)
m:addOverride('xi.zones.Dragons_Aery.npcs.qm_fafnir.onTrade', onTrade)

-- FileWatcher re-runs this file then discards addOverride. Keep a live wrap.
xi.module.ensureTable('xi.zones.Dragons_Aery.npcs.qm_fafnir')
xi.zones.Dragons_Aery.npcs.qm_fafnir.onTrigger = onTrigger
xi.zones.Dragons_Aery.npcs.qm_fafnir.onTrade   = onTrade
