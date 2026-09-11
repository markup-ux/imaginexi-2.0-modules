-----------------------------------
-- Imagine XI 2.0: WHM main Bar-element also grants that element's En-spell.
-- Barfire / Barfira -> Enfire, and the same for the other five elements.
-- Applies to every player the Bar spell actually hits (self, -ra, Accession).
-- Duration follows the Bar. Self-cast En-spell survives zoning with the Bar.
-- FileWatcher drops addOverride; assignment wrap stays live.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_whm_bar_enspell')

local PERSIST_FLAGS_COMMON = bit.bor(xi.effectFlag.ON_JOBCHANGE, xi.effectFlag.HIDE_TIMER)
local PERSIST_FLAGS_PARTY  = bit.bor(PERSIST_FLAGS_COMMON, xi.effectFlag.ON_ZONE)

local function persistFlags(caster, target)
    if caster:getID() == target:getID() then
        return PERSIST_FLAGS_COMMON
    end

    return PERSIST_FLAGS_PARTY
end

local BAR_TO_ENSPELL =
{
    [xi.magic.spell.BARFIRE]     = { effect = xi.effect.ENFIRE,     spell = xi.magic.spell.ENFIRE     },
    [xi.magic.spell.BARFIRA]     = { effect = xi.effect.ENFIRE,     spell = xi.magic.spell.ENFIRE     },
    [xi.magic.spell.BARBLIZZARD] = { effect = xi.effect.ENBLIZZARD, spell = xi.magic.spell.ENBLIZZARD },
    [xi.magic.spell.BARBLIZZARA] = { effect = xi.effect.ENBLIZZARD, spell = xi.magic.spell.ENBLIZZARD },
    [xi.magic.spell.BARAERO]     = { effect = xi.effect.ENAERO,     spell = xi.magic.spell.ENAERO     },
    [xi.magic.spell.BARAERA]     = { effect = xi.effect.ENAERO,     spell = xi.magic.spell.ENAERO     },
    [xi.magic.spell.BARSTONE]    = { effect = xi.effect.ENSTONE,    spell = xi.magic.spell.ENSTONE    },
    [xi.magic.spell.BARSTONRA]   = { effect = xi.effect.ENSTONE,    spell = xi.magic.spell.ENSTONE    },
    [xi.magic.spell.BARTHUNDER]  = { effect = xi.effect.ENTHUNDER,  spell = xi.magic.spell.ENTHUNDER  },
    [xi.magic.spell.BARTHUNDRA]  = { effect = xi.effect.ENTHUNDER,  spell = xi.magic.spell.ENTHUNDER  },
    [xi.magic.spell.BARWATER]    = { effect = xi.effect.ENWATER,    spell = xi.magic.spell.ENWATER    },
    [xi.magic.spell.BARWATERA]   = { effect = xi.effect.ENWATER,    spell = xi.magic.spell.ENWATER    },
}

local ENSPELL_OVERWRITE =
{
    xi.effect.ENFIRE,
    xi.effect.ENBLIZZARD,
    xi.effect.ENAERO,
    xi.effect.ENSTONE,
    xi.effect.ENTHUNDER,
    xi.effect.ENWATER,
    xi.effect.ENFIRE_II,
    xi.effect.ENBLIZZARD_II,
    xi.effect.ENAERO_II,
    xi.effect.ENSTONE_II,
    xi.effect.ENTHUNDER_II,
    xi.effect.ENWATER_II,
    xi.effect.ENLIGHT,
    xi.effect.ENDARK,
}

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function isWhmMain(entity)
    return isPlayer(entity) and entity:getMainJob() == xi.job.WHM
end

local function grantBarEnspell(caster, target, spell, barEffectId)
    if
        not barEffectId or
        barEffectId == 0 or
        barEffectId == xi.effect.NONE or
        not isWhmMain(caster) or
        not isPlayer(target)
    then
        return
    end

    local mapping = BAR_TO_ENSPELL[spell:getID()]
    if not mapping then
        return
    end

    local barEffect = target:getStatusEffect(barEffectId)
    if not barEffect then
        return
    end

    local duration = math.max(math.floor(barEffect:getDuration() / 1000), 1)
    local basePower = xi.spells.enhancing.calculateEnhancingBasePower(caster, target, spell, mapping.spell, mapping.effect)
    local finalPower = xi.spells.enhancing.calculateEnhancingFinalPower(caster, target, spell, basePower, spell:getSpellGroup(), 1, mapping.effect)

    for _, effectId in ipairs(ENSPELL_OVERWRITE) do
        target:delStatusEffectSilent(effectId)
    end

    local flags = persistFlags(caster, target)
    target:addStatusEffect(mapping.effect, {
        power    = finalPower,
        duration = duration,
        origin   = caster,
        silent   = true,
        flag     = flags,
    })

    local enEffect = target:getStatusEffect(mapping.effect)
    if not enEffect then
        return
    end

    enEffect:addEffectFlag(flags)
    if caster:getID() == target:getID() then
        enEffect:delEffectFlag(xi.effectFlag.ON_ZONE)
    end
    target:messageBasic(xi.msg.basic.GAINS_EFFECT_OF_STATUS, mapping.effect)
end

local function afterBarCast(caster, target, spell, result)
    grantBarEnspell(caster, target, spell, result)
    return result
end

m:addOverride('xi.spells.enhancing.useEnhancingSpell', function(caster, target, spell)
    return afterBarCast(caster, target, spell, super(caster, target, spell))
end)

-- FileWatcher re-runs this file then discards addOverride. Keep a live wrap.
if not xi.spells.enhancing._ixi20WhmBarEnspell then
    xi.spells.enhancing._ixi20WhmBarEnspell = true

    local previous = xi.spells.enhancing.useEnhancingSpell
    xi.spells.enhancing.useEnhancingSpell = function(caster, target, spell)
        return afterBarCast(caster, target, spell, previous(caster, target, spell))
    end
end

-- Drop the old MAGIC_USE animation swap if it is still attached from a prior load.
if xi.zone and GetZone then
    local visitedZone = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and not visitedZone[zoneId] then
            visitedZone[zoneId] = true
            local zone = GetZone(zoneId)
            if zone then
                for _, player in pairs(zone:getPlayers() or {}) do
                    if player and player.removeListener then
                        player:removeListener('IXI20_WHM_BAR_ENSPELL')
                    end
                end
            end
        end
    end
end
