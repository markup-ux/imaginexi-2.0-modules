-----------------------------------
-- Imagine XI 2.0: refund a Stratagem charge after a 3+ target Arts AoE.
-- Manifestation: successful enfeebles on 3 or more enemies.
-- Accession: successful status-ailment cures on 3 or more allies.
-- Pair with ixi20_sch_stratagem_refund.cpp (rebuild xi_map).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_sch_stratagem_refund')

local LISTENER_ID = 'IXI20_SCH_STRATAGEM_REFUND'
local NEED_HITS   = 3

local ENFEEBLE_OK =
{
    xi.msg.basic.MAGIC_ENFEEB_IS,
    xi.msg.basic.MAGIC_ENFEEB,
    xi.msg.basic.MAGIC_ERASE,
    xi.msg.basic.MAGIC_BURST_ENFEEB,
    xi.msg.basic.MAGIC_BURST_ENFEEB_IS,
    xi.msg.basic.IS_EFFECT,
    278, -- AoE "receives the effect of <status>"
}

local NA_OK =
{
    xi.msg.basic.MAGIC_REMOVE_EFFECT,
    xi.msg.basic.MAGIC_ERASE,
    xi.msg.basic.MAGIC_REMOVE_EFFECT_2,
    xi.msg.basic.MAGIC_ABSORB_AILMENT,
}

local function isScholar(player)
    return player:getMainJob() == xi.job.SCH or player:getSubJob() == xi.job.SCH
end

local function isStatusAilmentSpell(spell)
    local family = spell:getSpellFamily()
    if family == xi.magic.spellFamily.NA then
        return true
    end

    local spellId = spell:getID()
    return spellId == xi.magic.spell.ERASE or
        spellId == xi.magic.spell.ESUNA or
        spellId == xi.magic.spell.SACRIFICE
end

local function tryRefund(player, action, okMessages)
    if not Ixi20CountActionMsgs or not Ixi20RefundStratagemCharge then
        return
    end

    if Ixi20CountActionMsgs(action, okMessages) < NEED_HITS then
        return
    end

    Ixi20RefundStratagemCharge(player)
end

local function onMagicUse(player, _, spell, action)
    if
        not player or
        not player.isPC or
        not player:isPC() or
        not spell or
        not action or
        not isScholar(player)
    then
        return
    end

    local aoe = spell:isAoE()
    if aoe == xi.magic.aoe.RADIAL_MANI then
        tryRefund(player, action, ENFEEBLE_OK)
    elseif aoe == xi.magic.aoe.RADIAL_ACCE and isStatusAilmentSpell(spell) then
        tryRefund(player, action, NA_OK)
    end
end

local function attach(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('MAGIC_USE', LISTENER_ID, onMagicUse)
end

local function attachOnlinePlayers()
    if not xi.zone or not GetZone then
        return
    end

    local visitedZone = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and not visitedZone[zoneId] then
            visitedZone[zoneId] = true
            local zone = GetZone(zoneId)
            if zone then
                for _, player in pairs(zone:getPlayers() or {}) do
                    attach(player)
                end
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

if not xi.player._ixi20SchStratagemRefundGameIn then
    xi.player._ixi20SchStratagemRefundGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
