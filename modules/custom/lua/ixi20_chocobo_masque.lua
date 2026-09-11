-----------------------------------
-- Imagine XI 2.0: Chocobo Masque +1 always warps to the home-nation telepoint chocogirl.
-- Recast is zeroed by the C++ module so the 20h charge wait does not apply.
-- Stock LSB has no item script, so OnItemCheck fails (msg 56) without this table.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/teleports')
-----------------------------------

local m = Module:new('ixi20_chocobo_masque')

-- Telepoint chocogirls: Holla (San d'Oria), Dem (Bastok), Mea (Windurst).
local destByNation =
{
    [xi.nation.SANDORIA] = xi.teleport.id.HOLLA,
    [xi.nation.BASTOK]   = xi.teleport.id.DEM,
    [xi.nation.WINDURST] = xi.teleport.id.MEA,
}

local function onItemCheck()
    return 0
end

local function onItemUse(target, user)
    local player = target or user
    if not player or not player.isPC or not player:isPC() then
        return
    end

    local dest = destByNation[player:getNation()] or xi.teleport.id.HOLLA
    player:addStatusEffect(xi.effect.TELEPORT, {
        power    = dest,
        duration = 4,
        origin   = user or player,
        icon     = 0,
    })
end

local function install()
    xi.items = xi.items or {}
    xi.items['chocobo_masque_+1'] =
    {
        onItemCheck = onItemCheck,
        onItemUse   = onItemUse,
    }
end

m:addOverride('xi.items.chocobo_masque_+1.onItemCheck', function(target, item, caster)
    return onItemCheck(target, item, caster)
end)

m:addOverride('xi.items.chocobo_masque_+1.onItemUse', function(target, user, item, action)
    return onItemUse(target, user, item, action)
end)

install()

return m
