-----------------------------------
-- Retrace is castable without Campaign allegiance.
-- Sends the target to their home nation's past city ([S]).
-- Instant Retrace uses the same destination rule.
-- FileWatcher discards addOverride; live assignment keeps the patch.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/teleports')
-----------------------------------

local m = Module:new('ixi20_retrace')

local function retraceCastingCheck(caster, target, spell)
    if target:hasStatusEffect(xi.effect.MOUNTED) then
        return xi.msg.basic.MAGIC_CANNOT_BE_CAST
    end

    return 0
end

local function applyRetrace(caster, target)
    target:addStatusEffect(xi.effect.TELEPORT, {
        power    = xi.teleport.id.RETRACE,
        duration = 3,
        origin   = caster,
        icon     = 0,
    })
end

local function retraceOnCast(caster, target, spell)
    spell:setMsg(xi.msg.basic.NONE)

    if target:getObjType() ~= xi.objType.PC then
        return 0
    end

    if target:hasStatusEffect(xi.effect.MOUNTED) then
        return 0
    end

    applyRetrace(caster, target)
    spell:setMsg(xi.msg.basic.MAGIC_TELEPORT)

    return xi.effect.TELEPORT
end

local function toAlliedNation(player)
    if not player then
        return
    end

    local allegiance = player:getCampaignAllegiance()
    if allegiance == xi.alliedNation.NONE then
        local nation = player:getNation()
        if nation == xi.nation.SANDORIA then
            allegiance = xi.alliedNation.SANDORIA
        elseif nation == xi.nation.BASTOK then
            allegiance = xi.alliedNation.BASTOK
        elseif nation == xi.nation.WINDURST then
            allegiance = xi.alliedNation.WINDURST
        end
    end

    local dest
    if allegiance == xi.alliedNation.SANDORIA then
        dest = xi.teleport.destination[xi.teleport.id.SOUTHERN_SAN_DORIA_S]
    elseif allegiance == xi.alliedNation.BASTOK then
        dest = xi.teleport.destination[xi.teleport.id.BASTOK_MARKETS_S]
    elseif allegiance == xi.alliedNation.WINDURST then
        dest = xi.teleport.destination[xi.teleport.id.WINDURST_WATERS_S]
    end

    if dest then
        player:setPos(unpack(dest))
    end
end

local function instantRetraceCheck()
    return 0
end

local function instantRetraceUse(target, user)
    if target then
        applyRetrace(user or target, target)
    end
end

local function useTeleportSpell(caster, target, spell)
    if spell and spell.getID and spell:getID() == xi.magic.spell.RETRACE then
        return retraceOnCast(caster, target, spell)
    end

    return xi.spells.enhancing._ixi20RetracePrev(caster, target, spell)
end

local function installLive()
    local retrace = xi.actions and xi.actions.spells and xi.actions.spells.black and xi.actions.spells.black.retrace
    if retrace then
        retrace.onMagicCastingCheck = retraceCastingCheck
        retrace.onSpellCast = retraceOnCast
    end

    if xi.teleport then
        xi.teleport.toAlliedNation = toAlliedNation
    end

    local item = xi.items and xi.items.scroll_of_instant_retrace
    if item then
        item.onItemCheck = instantRetraceCheck
        item.onItemUse = instantRetraceUse
    end

    if
        xi.spells and
        xi.spells.enhancing and
        xi.spells.enhancing.useTeleportSpell and
        not xi.spells.enhancing._ixi20Retrace
    then
        xi.spells.enhancing._ixi20Retrace = true
        xi.spells.enhancing._ixi20RetracePrev = xi.spells.enhancing.useTeleportSpell
        xi.spells.enhancing.useTeleportSpell = useTeleportSpell
    end
end

m:addOverride('xi.actions.spells.black.retrace.onMagicCastingCheck', function(caster, target, spell)
    return retraceCastingCheck(caster, target, spell)
end)

m:addOverride('xi.actions.spells.black.retrace.onSpellCast', function(caster, target, spell)
    return retraceOnCast(caster, target, spell)
end)

m:addOverride('xi.teleport.toAlliedNation', function(player)
    toAlliedNation(player)
end)

m:addOverride('xi.items.scroll_of_instant_retrace.onItemCheck', function(target, item, caster)
    return instantRetraceCheck(target, item, caster)
end)

m:addOverride('xi.items.scroll_of_instant_retrace.onItemUse', function(target, user, item, action)
    instantRetraceUse(target, user)
end)

installLive()

return m
