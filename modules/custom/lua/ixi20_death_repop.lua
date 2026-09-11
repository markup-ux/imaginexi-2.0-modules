-----------------------------------
-- Imagine XI 2.0: living mobs that despawn (wipe / leash / bad path)
-- immediately repop at their spawn point instead of sitting on a long timer.
-- Pair with ixi20_death_repop.cpp (attaches the DESPAWN listener).
-- Helper file only: do not call Module:new (no overrides).
-----------------------------------
require('modules/module_utils')
-----------------------------------

xi = xi or {}
xi.ixi20DeathRepop = xi.ixi20DeathRepop or {}

local LISTENER = 'IXI20_ALIVE_REPOP'

function xi.ixi20DeathRepop.onDespawn(mob)
    if not mob or not Ixi20RepopAliveMob then
        return
    end

    Ixi20RepopAliveMob(mob)
end

function xi.ixi20DeathRepop.ensure(mob)
    if not mob or not mob.isMob or not mob:isMob() then
        return
    end

    if mob.removeListener then
        mob:removeListener(LISTENER)
    end

    mob:addListener('DESPAWN', LISTENER, xi.ixi20DeathRepop.onDespawn)
end
