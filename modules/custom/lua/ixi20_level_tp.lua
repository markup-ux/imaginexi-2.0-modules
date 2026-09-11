-----------------------------------
-- Imagine XI 2.0: main-job level-up fills TP and grants Meditate-rate Regain.
-- Instant 3000 TP + Regain power 20 (200 TP / 3s) for 2 minutes.
-- Skips raise dings (Weakness). Does not replace !godmode Regain.
-- Subjob levels do not call this hook.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_level_tp')

local TP_FILL        = 3000
local REGAIN_POWER   = 20
local REGAIN_SECONDS = 120

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function grantLevelTp(player)
    if not isPlayer(player) then
        return
    end

    if player.isAlive and not player:isAlive() then
        return
    end

    if player:hasStatusEffect(xi.effect.WEAKNESS) then
        return
    end

    player:setTP(TP_FILL)

    if player:getCharVar('GodMode') ~= 0 then
        return
    end

    player:addStatusEffect(xi.effect.REGAIN, {
        power    = REGAIN_POWER,
        duration = REGAIN_SECONDS,
        origin   = player,
    })

    player:printToPlayer('Your fighting spirit surges!', xi.msg.channel.SYSTEM_3)
end

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    grantLevelTp(player)
end)

return m
