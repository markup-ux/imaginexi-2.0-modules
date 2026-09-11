-----------------------------------
-- Imagine XI 2.0: Light / Dark Arts grant +15 matching magic skill.
-- Stock Arts raised SCH D-rank magic toward B+. SCH is A+ here, so that
-- lift is 0. This restores a stance-specific skill bump.
-- Light: Divine / Healing / Enhancing / Enfeebling
-- Dark:  Enfeebling / Elemental / Dark
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_sch_arts_skill')

local LISTENER_GAIN = 'IXI20_SCH_ARTS_SKILL_GAIN'
local LISTENER_LOSE = 'IXI20_SCH_ARTS_SKILL_LOSE'
local VAR_MODE      = 'ixi20ArtsSkill' -- 0 none, 1 light, 2 dark
local SKILL_BONUS   = 15

local LIGHT_MODS =
{
    xi.mod.DIVINE,
    xi.mod.HEALING,
    xi.mod.ENHANCE,
    xi.mod.ENFEEBLE,
}

local DARK_MODS =
{
    xi.mod.ENFEEBLE,
    xi.mod.ELEM,
    xi.mod.DARK,
}

local function applyMods(player, mods, enable)
    for _, mod in ipairs(mods) do
        if enable then
            player:addMod(mod, SKILL_BONUS)
        else
            player:delMod(mod, SKILL_BONUS)
        end
    end
end

local function setArtsSkill(player, mode)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    local current = player:getLocalVar(VAR_MODE)
    if current == mode then
        return
    end

    if current == 1 then
        applyMods(player, LIGHT_MODS, false)
    elseif current == 2 then
        applyMods(player, DARK_MODS, false)
    end

    if mode == 1 then
        applyMods(player, LIGHT_MODS, true)
    elseif mode == 2 then
        applyMods(player, DARK_MODS, true)
    end

    player:setLocalVar(VAR_MODE, mode)
    player:recalculateSkillsTable()
end

local function modeFromEffects(player)
    if
        player:hasStatusEffect(xi.effect.LIGHT_ARTS) or
        player:hasStatusEffect(xi.effect.ADDENDUM_WHITE)
    then
        return 1
    end

    if
        player:hasStatusEffect(xi.effect.DARK_ARTS) or
        player:hasStatusEffect(xi.effect.ADDENDUM_BLACK)
    then
        return 2
    end

    return 0
end

local function attach(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(LISTENER_GAIN)
    player:removeListener(LISTENER_LOSE)

    player:addListener('EFFECT_GAIN', LISTENER_GAIN, function(playerArg, effect)
        if not playerArg or not effect then
            return
        end

        local effectId = effect:getEffectType()
        if
            effectId == xi.effect.LIGHT_ARTS or
            effectId == xi.effect.ADDENDUM_WHITE
        then
            setArtsSkill(playerArg, 1)
        elseif
            effectId == xi.effect.DARK_ARTS or
            effectId == xi.effect.ADDENDUM_BLACK
        then
            setArtsSkill(playerArg, 2)
        end
    end)

    player:addListener('EFFECT_LOSE', LISTENER_LOSE, function(playerArg, effect)
        if not playerArg or not effect then
            return
        end

        local effectId = effect:getEffectType()
        if
            effectId ~= xi.effect.LIGHT_ARTS and
            effectId ~= xi.effect.ADDENDUM_WHITE and
            effectId ~= xi.effect.DARK_ARTS and
            effectId ~= xi.effect.ADDENDUM_BLACK
        then
            return
        end

        -- Addendum replaces Arts on the same tick; wait one tick so the new stance is on.
        playerArg:timer(1, function(restoreTarget)
            if restoreTarget and restoreTarget.isPC and restoreTarget:isPC() then
                setArtsSkill(restoreTarget, modeFromEffects(restoreTarget))
            end
        end)
    end)

    setArtsSkill(player, modeFromEffects(player))
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

-- FileWatcher discards addOverride; keep onGameIn live without a restart.
if not xi.player._ixi20SchArtsSkillGameIn then
    xi.player._ixi20SchArtsSkillGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
