-----------------------------------
-- Leftover unused spells (Virus, Curse) can be known and castable while
-- the native magic list drops them on rebuild. Re-pulse the learn path
-- so FFXiMain appends the row again (same as first auto-learn).
-- FileWatcher discards addOverride; live assignment keeps the patch.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_leftover_magic_menu')

local LEFTOVER = { 256, 257 } -- Virus, Curse

local function relistOne(player, spellId, announce)
    if not player:hasSpell(spellId) then
        return
    end

    player:delSpell(spellId, { saveToDB = false, sendUpdate = false })
    player:addSpell(spellId, { silentLog = not announce, saveToDB = false, sendUpdate = true })
end

local function relistKnown(player, announce)
    if not player or player:getObjType() ~= xi.objType.PC then
        return
    end

    for _, spellId in ipairs(LEFTOVER) do
        relistOne(player, spellId, announce)
    end
end

if not xi.player._ixi20LeftoverMagicMenu then
    local onGameIn = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        onGameIn(player, firstLogin, zoning)
        relistKnown(player, false)
    end
    xi.player._ixi20LeftoverMagicMenu = true
end

if xi.spells and xi.spells.enfeebling and not xi.spells.enfeebling._ixi20LeftoverMagicMenu then
    local useEnfeebling = xi.spells.enfeebling.useEnfeeblingSpell
    xi.spells.enfeebling.useEnfeeblingSpell = function(caster, target, spell)
        local result = useEnfeebling(caster, target, spell)
        if caster and caster:getObjType() == xi.objType.PC then
            local spellId = spell:getID()
            if spellId == 256 or spellId == 257 then
                relistOne(caster, spellId, false)
            end
        end
        return result
    end
    xi.spells.enfeebling._ixi20LeftoverMagicMenu = true
end

return m
