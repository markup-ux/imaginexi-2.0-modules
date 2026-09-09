-----------------------------------
-- Imagine XI 2.0: 2-hour / 1-hour windows last 2 minutes.
-- Recast stays 3600s. Instant SPs (Benediction, Eagle Eye Shot, Mijin,
-- Wild Card, Larceny, Cutting Cards, Heady Artifice, Caper Emissarius,
-- Odyllic Subterfuge) are unchanged. Familiar is skipped.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_sp_uptime')

local DURATION_MS = 2 * 60 * 1000
local LISTENER_ID    = 'IXI20_SP_UPTIME'
local PET_LISTENER   = 'IXI20_SP_UPTIME_PET'
local SPAWN_LISTENER = 'IXI20_SP_UPTIME_PETSPAWN'

local SP_EFFECT =
{
    [xi.effect.MIGHTY_STRIKES]    = true,
    [xi.effect.HUNDRED_FISTS]     = true,
    [xi.effect.MANAFONT]          = true,
    [xi.effect.CHAINSPELL]        = true,
    [xi.effect.PERFECT_DODGE]     = true,
    [xi.effect.INVINCIBLE]        = true,
    [xi.effect.BLOOD_WEAPON]      = true,
    [xi.effect.SOUL_VOICE]        = true,
    [xi.effect.MEIKYO_SHISUI]     = true,
    [xi.effect.SPIRIT_SURGE]      = true,
    [xi.effect.ASTRAL_FLOW]       = true,
    [xi.effect.AZURE_LORE]        = true,
    [xi.effect.OVERDRIVE]         = true,
    [xi.effect.TRANCE]            = true,
    [xi.effect.TABULA_RASA]       = true,
    [xi.effect.BOLSTER]           = true,
    [xi.effect.ELEMENTAL_SFORZO]  = true,
    [xi.effect.BRAZEN_RUSH]       = true,
    [xi.effect.INNER_STRENGTH]    = true,
    [xi.effect.ASYLUM]            = true,
    [xi.effect.SUBTLE_SORCERY]    = true,
    [xi.effect.STYMIE]            = true,
    [xi.effect.INTERVENE]         = true,
    [xi.effect.SOUL_ENSLAVEMENT]  = true,
    [xi.effect.UNLEASH]           = true,
    [xi.effect.CLARION_CALL]      = true,
    [xi.effect.OVERKILL]          = true,
    [xi.effect.YAEGASUMI]         = true,
    [xi.effect.MIKAGE]            = true,
    [xi.effect.FLY_HIGH]          = true,
    [xi.effect.ASTRAL_CONDUIT]    = true,
    [xi.effect.UNBRIDLED_WISDOM]  = true,
    [xi.effect.GRAND_PAS]         = true,
    [xi.effect.WIDENED_COMPASS]   = true,
}

-- Retail timed SPs apply ~30s. Scripted short buffs (pixie rescue Invincible
-- is 15s) and duration-0 godmode must keep the duration they were given.
local MIN_REAL_SP_MS = 20 * 1000

local function stretchIfSp(entity, effect)
    if not entity or not effect then
        return
    end

    if not SP_EFFECT[effect:getEffectType()] then
        return
    end

    if effect:getDuration() < MIN_REAL_SP_MS then
        return
    end

    effect:setDuration(DURATION_MS)
end

local function attachPet(pet)
    if not pet or not pet.addListener then
        return
    end

    pet:removeListener(PET_LISTENER)
    pet:addListener('EFFECT_GAIN', PET_LISTENER, function(entity, effect)
        stretchIfSp(entity, effect)
    end)
end

local function attach(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('EFFECT_GAIN', LISTENER_ID, function(entity, effect)
        stretchIfSp(entity, effect)
    end)

    player:removeListener(SPAWN_LISTENER)
    player:addListener('ABILITY_USE', SPAWN_LISTENER, function(user, target)
        if user then
            attachPet(user:getPet())
        end

        -- Intervene and similar land on a non-PC target that has no EFFECT_GAIN hook.
        if target and target.getStatusEffect then
            for effectId, _ in pairs(SP_EFFECT) do
                stretchIfSp(target, target:getStatusEffect(effectId))
            end
        end
    end)

    attachPet(player:getPet())

    for effectId, _ in pairs(SP_EFFECT) do
        local effect = player:getStatusEffect(effectId)
        if effect then
            local remaining = effect:getTimeRemaining()
            if remaining > DURATION_MS then
                effect:setDuration(effect:getDuration() - remaining + DURATION_MS)
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

-- FileWatcher reloads do not run onGameIn. Re-attach whoever is already zoned in.
if xi.zone and GetZone then
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

return m
