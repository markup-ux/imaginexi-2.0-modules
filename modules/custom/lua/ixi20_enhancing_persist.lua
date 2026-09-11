-----------------------------------
-- Imagine XI 2.0: Enhancing magic, BRD songs, and COR rolls last until
-- death / job change if you cast them on yourself (they survive zoning).
-- Party-cast persist buffs last until zone / death / job change, and drop
-- if the caster leaves that party or job-changes. Blink, Embrava, and Foil
-- stay timed. Utsusemi is ninjutsu and is not touched. Enfeebling songs
-- stay timed. Bust and Double-Up stay timed. Recast overwrites. Players
-- only. Power is unchanged. Recast still upgrades tier / stacked Refresh.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_enhancing_persist')

local PERSIST_SECONDS      = 604800 -- 7 days; self lasts across zones, party ends on zone
local PERSIST_FLAGS_COMMON = bit.bor(xi.effectFlag.ON_JOBCHANGE, xi.effectFlag.HIDE_TIMER)
local PERSIST_FLAGS_PARTY  = bit.bor(PERSIST_FLAGS_COMMON, xi.effectFlag.ON_ZONE)
local LISTENER_AUDIT  = 'IXI20_PERSIST_AUDIT'
local LISTENER_JOB    = 'IXI20_PERSIST_JOB'
local LISTENER_TICK   = 'IXI20_PERSIST_TICK'

local KEEP_TIMED_SPELL =
{
    [xi.magic.spell.BLINK]   = true,
    [xi.magic.spell.EMBRAVA] = true,
    [xi.magic.spell.FOIL]    = true,
}

local KEEP_TIMED_EFFECT =
{
    [xi.effect.BLINK]   = true,
    [xi.effect.EMBRAVA] = true,
    [xi.effect.FOIL]    = true,
}

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function sameParty(a, b)
    if not isPlayer(a) or not isPlayer(b) then
        return false
    end

    if a:getID() == b:getID() then
        return true
    end

    local party = a.getParty and a:getParty()
    if not party then
        return false
    end

    local bId = b:getID()
    for _, member in pairs(party) do
        if member and member.getID and member:getID() == bId then
            return true
        end
    end

    return false
end

local function shouldPersist(caster, target, spellId, spellEffect)
    if not isPlayer(target) or not isPlayer(caster) then
        return false
    end

    if spellId and KEEP_TIMED_SPELL[spellId] then
        return false
    end

    if spellEffect and KEEP_TIMED_EFFECT[spellEffect] then
        return false
    end

    return caster:getID() == target:getID() or sameParty(caster, target)
end

local function isSelfCast(caster, target)
    return isPlayer(caster) and isPlayer(target) and caster:getID() == target:getID()
end

local function applyPersistFlags(effect, caster, target)
    if isSelfCast(caster, target) then
        effect:addEffectFlag(PERSIST_FLAGS_COMMON)
        effect:delEffectFlag(xi.effectFlag.ON_ZONE)
        return
    end

    effect:addEffectFlag(PERSIST_FLAGS_PARTY)
end

local function persistCasterId(effect)
    if not effect then
        return 0
    end

    local origin = effect:getOriginID()
    if origin and origin ~= 0 then
        return origin
    end

    if effect:hasEffectFlag(xi.effectFlag.SONG) then
        local sub = effect:getSubType()
        if sub and sub ~= 0 then
            return sub
        end
    end

    if effect:hasEffectFlag(xi.effectFlag.ROLL) then
        local src = effect:getSourceTypeParam()
        if src and src ~= 0 then
            return src
        end
    end

    return 0
end

local function isPersistBuff(effect)
    if not effect then
        return false
    end

    local effectType = effect:getEffectType()
    if KEEP_TIMED_EFFECT[effectType] then
        return false
    end

    if effectType == xi.effect.BUST then
        return false
    end

    if effect:hasEffectFlag(xi.effectFlag.SONG) then
        return true
    end

    if effect:hasEffectFlag(xi.effectFlag.ROLL) then
        return true
    end

    return effect:hasEffectFlag(xi.effectFlag.HIDE_TIMER) and
        (effect:hasEffectFlag(xi.effectFlag.ON_ZONE) or effect:hasEffectFlag(xi.effectFlag.ON_JOBCHANGE))
end

local function partyIdSet(player)
    local ids = { [player:getID()] = true }
    for _, member in pairs(player:getParty() or {}) do
        if member and member.getID then
            ids[member:getID()] = true
        end
    end

    return ids
end

local function casterStillValid(player, effect, casterId, inParty)
    if not inParty[casterId] then
        return false
    end

    local caster = GetPlayerByID and GetPlayerByID(casterId)
    if not caster or not caster.getMainJob then
        return true
    end

    local mainJob = caster:getMainJob()
    local subJob  = caster:getSubJob()

    if effect:hasEffectFlag(xi.effectFlag.SONG) then
        return mainJob == xi.job.BRD or subJob == xi.job.BRD
    end

    if effect:hasEffectFlag(xi.effectFlag.ROLL) then
        return mainJob == xi.job.COR or subJob == xi.job.COR
    end

    if
        effect:getSourceType() == 0 and
        effect:getSourceTypeParam() > 0
    then
        return mainJob == effect:getSourceTypeParam()
    end

    return true
end

local function auditPersist(player)
    if not isPlayer(player) then
        return
    end

    local selfId  = player:getID()
    local inParty = partyIdSet(player)
    local drop    = {}

    -- Songs / rolls / En-spells get ON_ZONE back from YAML on load. Strip it
    -- from self-cast persist kit so the next zone line keeps them.
    for _, effect in pairs(player:getStatusEffects()) do
        if isPersistBuff(effect) then
            local casterId = persistCasterId(effect)
            if casterId == selfId then
                effect:delEffectFlag(xi.effectFlag.ON_ZONE)
            elseif
                casterId ~= 0 and
                not casterStillValid(player, effect, casterId, inParty)
            then
                drop[#drop + 1] = effect:getEffectType()
            end
        end
    end

    for i = 1, #drop do
        player:delStatusEffectSilent(drop[i])
    end
end

local function stripOriginFromParty(caster)
    if not isPlayer(caster) then
        return
    end

    local casterId = caster:getID()
    for _, member in pairs(caster:getParty() or {}) do
        if
            member and
            member.getID and
            member:getID() ~= casterId and
            member.getStatusEffects
        then
            local drop = {}
            for _, effect in pairs(member:getStatusEffects()) do
                if isPersistBuff(effect) and persistCasterId(effect) == casterId then
                    drop[#drop + 1] = effect:getEffectType()
                end
            end

            for i = 1, #drop do
                member:delStatusEffectSilent(drop[i])
            end
        end
    end
end

local function stampPersist(caster, target, spellId, spellEffect)
    if not shouldPersist(caster, target, spellId, spellEffect) then
        return
    end

    local effect = target:getStatusEffect(spellEffect)
    if not effect then
        return
    end

    applyPersistFlags(effect, caster, target)
    effect:setOriginID(caster:getID())
    if effect:getSourceType() == 0 then
        effect:setSource(0, caster:getMainJob())
    end
end

local function persistReraise(caster, target)
    if not shouldPersist(caster, target, nil, xi.effect.RERAISE) then
        return
    end

    local effect = target:getStatusEffect(xi.effect.RERAISE)
    if not effect then
        return
    end

    effect:setDuration(PERSIST_SECONDS * 1000)
    applyPersistFlags(effect, caster, target)
    effect:setOriginID(caster:getID())
    if effect:getSourceType() == 0 then
        effect:setSource(0, caster:getMainJob())
    end
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_AUDIT)
    player:addListener('IXI20_PERSIST_AUDIT', LISTENER_AUDIT, function(playerArg)
        auditPersist(playerArg)
    end)

    player:removeListener(LISTENER_JOB)
    player:addListener('IXI20_PERSIST_JOB', LISTENER_JOB, function(playerArg)
        stripOriginFromParty(playerArg)
    end)

    player:removeListener(LISTENER_TICK)
    player:addListener('EFFECTS_TICK', LISTENER_TICK, function(playerArg)
        auditPersist(playerArg)
    end)

    auditPersist(player)
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

m:addOverride('xi.spells.enhancing.calculateEnhancingDuration', function(caster, target, spell, spellId, spellGroup, spellEffect)
    local duration = super(caster, target, spell, spellId, spellGroup, spellEffect)
    if shouldPersist(caster, target, spellId, spellEffect) then
        return PERSIST_SECONDS
    end

    return duration
end)

-- Wraps ixi20_refresh_stack when that module is loaded first.
m:addOverride('xi.spells.enhancing.useEnhancingSpell', function(caster, target, spell)
    local result = super(caster, target, spell)
    if
        result and
        result ~= 0 and
        result ~= xi.effect.NONE
    then
        stampPersist(caster, target, spell:getID(), result)
    end

    return result
end)

local function stampSong(caster, target)
    if not isPlayer(target) then
        return
    end

    local casterId = caster and caster.getID and caster:getID()
    for _, effect in pairs(target:getStatusEffects()) do
        if effect:hasEffectFlag(xi.effectFlag.SONG) then
            local songCaster = persistCasterId(effect)
            if not casterId or songCaster == 0 or songCaster == casterId then
                applyPersistFlags(effect, caster, target)
                if casterId then
                    effect:setOriginID(casterId)
                end
            end
        end
    end
end

local function stampRoll(caster, target)
    if not isPlayer(target) then
        return
    end

    local casterId = caster and caster.getID and caster:getID()
    for _, effect in pairs(target:getStatusEffects()) do
        if
            effect:hasEffectFlag(xi.effectFlag.ROLL) and
            (not casterId or effect:getSourceTypeParam() == casterId)
        then
            effect:setDuration(PERSIST_SECONDS * 1000)
            applyPersistFlags(effect, caster, target)
            effect:delEffectFlag(xi.effectFlag.LOGOUT)
            if casterId then
                effect:setOriginID(casterId)
            end
        end
    end
end

m:addOverride('xi.spells.enhancing.calculateSongDuration', function(caster, target, spell, instrumentBoost, soulVoicePower)
    local duration = super(caster, target, spell, instrumentBoost, soulVoicePower)
    if shouldPersist(caster, target, nil, nil) then
        return PERSIST_SECONDS
    end

    return duration
end)

m:addOverride('xi.spells.enhancing.useEnhancingSong', function(caster, target, spell)
    local result = super(caster, target, spell)
    if shouldPersist(caster, target, nil, nil) then
        stampSong(caster, target)
    end

    return result
end)

-- Retail blocks recasting an active roll. Persist would pin a bad number
-- until Fold / zone. Recast replaces it. Double-Up still upgrades in place.
m:addOverride('xi.job_utils.corsair.onRollAbilityCheck', function(player, target, ability)
    local numBusts = player:numBustEffects()
    local maxRolls = player:getMainJob() == xi.job.COR and 2 or 1
    if numBusts >= maxRolls then
        return xi.msg.basic.CANNOT_PERFORM, 0
    end

    return 0, 0
end)

m:addOverride('xi.job_utils.corsair.applyRoll', function(caster, target, inAbility, total, isDoubleup, currentAbility)
    if not isDoubleup then
        local rollInfo = xi.job_utils.corsair.rollData[inAbility:getID()]
        if rollInfo and target:hasStatusEffect(rollInfo.effect) then
            target:delStatusEffectSilent(rollInfo.effect)
        end
    end

    local result = super(caster, target, inAbility, total, isDoubleup, currentAbility)
    if shouldPersist(caster, target, nil, nil) then
        stampRoll(caster, target)
    end

    return result
end)

m:addOverride('xi.actions.spells.white.reraise.onSpellCast', function(caster, target, spell)
    local result = super(caster, target, spell)
    persistReraise(caster, target)
    return result
end)

m:addOverride('xi.actions.spells.white.reraise_ii.onSpellCast', function(caster, target, spell)
    local result = super(caster, target, spell)
    persistReraise(caster, target)
    return result
end)

m:addOverride('xi.actions.spells.white.reraise_iii.onSpellCast', function(caster, target, spell)
    local result = super(caster, target, spell)
    persistReraise(caster, target)
    return result
end)

m:addOverride('xi.actions.spells.white.reraise_iv.onSpellCast', function(caster, target, spell)
    local result = super(caster, target, spell)
    persistReraise(caster, target)
    return result
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

attachOnlinePlayers()
