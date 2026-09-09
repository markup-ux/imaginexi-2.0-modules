-----------------------------------
-- Imagine XI 2.0 unlimited combat ammo (module only).
-- Lua WS / JA paths skip consume. C++ auto-attack is restored by ixi20_infinite_ammo.cpp.
-- Recycle-as-Snapshot is not ported. Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/combat/ranged_utilities')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_infinite_ammo')

local CHAR_VAR_MJ = 'Ixi20AmmoTipMJ'
local CHAR_VAR_SJ = 'Ixi20AmmoTipSJ'

local function usesAmmoSlotJob(jobId)
    return jobId == xi.job.RNG or jobId == xi.job.COR or jobId == xi.job.NIN
end

local function maybeRemind(player)
    if not xi.settings.map.DISABLE_AMMO_CONSUMPTION then
        return
    end

    if not player or not player.isPC or not player:isPC() then
        return
    end

    local mj = player:getMainJob()
    local sj = player:getSubJob()

    if not usesAmmoSlotJob(mj) and not usesAmmoSlotJob(sj) then
        player:setCharVar(CHAR_VAR_MJ, mj)
        player:setCharVar(CHAR_VAR_SJ, sj)
        return
    end

    local prevMj = player:getCharVar(CHAR_VAR_MJ)
    local prevSj = player:getCharVar(CHAR_VAR_SJ)

    player:setCharVar(CHAR_VAR_MJ, mj)
    player:setCharVar(CHAR_VAR_SJ, sj)

    if prevMj == mj and prevSj == sj then
        return
    end

    player:printToPlayer('Imagine: Ammo is not consumed here.', xi.msg.channel.SYSTEM_3)
end

m:addOverride('xi.combat.ranged.shouldUseAmmo', function(attacker)
    if xi.settings.map.DISABLE_AMMO_CONSUMPTION then
        return false
    end

    return super(attacker)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    maybeRemind(player)
end)
