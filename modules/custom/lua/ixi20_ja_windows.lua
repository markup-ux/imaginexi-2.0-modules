-----------------------------------
-- Imagine XI 1.0 JA windows (module only)
-- Cascade: 8 min +10 MATT (10% MAB), does not consume on the next nuke
-- Manifestation: 45s multi-spell window (charge-free via ixi20_caster_kit)
-- Accession is always-on in ixi20_caster_kit (main and sub SCH)
-- Diffusion is always-on in ixi20_blu_affinity (main and sub BLU)
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_ja_windows')

local WINDOW_SECONDS =
{
    [xi.effect.CASCADE]       = 480,
    [xi.effect.MANIFESTATION] = 45,
}

local JOB_FOR_EFFECT =
{
    [xi.effect.CASCADE]       = xi.job.BLM,
    [xi.effect.MANIFESTATION] = xi.job.SCH,
}

local windows     = {}
local cascadeMatt = {}

local function playerId(player)
    return player:getID()
end

local function canHoldWindow(player, effectId)
    local job = JOB_FOR_EFFECT[effectId]
    if not job then
        return false
    end

    return player:getMainJob() == job or player:getSubJob() == job
end

local function rememberWindow(player, effectId, duration, zoneId)
    local id = playerId(player)
    windows[id] = windows[id] or {}
    windows[id][effectId] =
    {
        expire = os.time() + duration,
        zone   = zoneId or player:getZoneID(),
    }
end

local function remainingWindow(player, effectId)
    local slot = windows[playerId(player)]
    local rec  = slot and slot[effectId]
    if not rec then
        return 0
    end

    if player:getZoneID() ~= rec.zone then
        return 0
    end

    return math.max(0, rec.expire - os.time())
end

local function clearWindow(player, effectId)
    local slot = windows[playerId(player)]
    if slot then
        slot[effectId] = nil
    end
end

local CASCADE_MATT = 10 -- 10% MAB: magic formula is (100 + MATT) / (100 + MDEF)

local function setCascadeMatt(player, enable)
    local id = playerId(player)
    if enable and not cascadeMatt[id] then
        player:addMod(xi.mod.MATT, CASCADE_MATT)
        cascadeMatt[id] = true
    elseif not enable and cascadeMatt[id] then
        player:delMod(xi.mod.MATT, CASCADE_MATT)
        cascadeMatt[id] = nil
    end
end

local function attachWindows(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener('IXI20_JA_WINDOWS')
    player:addListener('EFFECT_LOSE', 'IXI20_JA_WINDOWS', function(playerArg, effect)
        if not playerArg or not effect then
            return
        end

        local effectId = effect:getEffectType()
        if not WINDOW_SECONDS[effectId] then
            return
        end

        local left = remainingWindow(playerArg, effectId)
        if left <= 0 or not canHoldWindow(playerArg, effectId) then
            clearWindow(playerArg, effectId)
            if effectId == xi.effect.CASCADE then
                setCascadeMatt(playerArg, false)
            end

            return
        end

        local savedTp = 0
        if effectId == xi.effect.CASCADE then
            savedTp = playerArg:getTP()
        end

        playerArg:timer(1, function(restoreTarget)
            if not restoreTarget or not restoreTarget.isPC or not restoreTarget:isPC() then
                return
            end

            local remain = remainingWindow(restoreTarget, effectId)
            if remain <= 0 or not canHoldWindow(restoreTarget, effectId) then
                clearWindow(restoreTarget, effectId)
                if effectId == xi.effect.CASCADE then
                    setCascadeMatt(restoreTarget, false)
                end

                return
            end

            if not restoreTarget:hasStatusEffect(effectId) then
                restoreTarget:addStatusEffect(effectId, { power = 1, duration = remain, origin = restoreTarget })
            end

            if effectId == xi.effect.CASCADE then
                setCascadeMatt(restoreTarget, true)
                if savedTp > 0 then
                    restoreTarget:setTP(savedTp)
                end
            end
        end)
    end)
end

local function applyTimedWindow(player, effectId)
    local duration = WINDOW_SECONDS[effectId]
    rememberWindow(player, effectId, duration)
    player:addStatusEffect(effectId, { power = 1, duration = duration, origin = player })
    if effectId == xi.effect.CASCADE then
        setCascadeMatt(player, true)
    end

    return effectId
end

m:addOverride('xi.job_utils.black_mage.useCascade', function(player, target, ability)
    return applyTimedWindow(player, xi.effect.CASCADE)
end)

m:addOverride('xi.actions.abilities.manifestation.onUseAbility', function(player, target, ability)
    if ability and ability.setRecast then
        ability:setRecast(0)
    end

    return applyTimedWindow(player, xi.effect.MANIFESTATION)
end)

m:addOverride('xi.spells.blue.calculateDurationWithDiffusion', function(caster, duration)
    if caster:hasStatusEffect(xi.effect.DIFFUSION) then
        local merits = caster:getMerit(xi.merit.DIFFUSION)
        if merits > 0 then
            duration = duration + (merits - 5) * duration / 100
        end
    end

    return duration
end)

m:addOverride('xi.actions.spells.blue.regeneration.onSpellCast', function(caster, target, spell)
    local power    = 25
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 90)

    if
        target:hasStatusEffect(xi.effect.REGEN) and
        target:getStatusEffect(xi.effect.REGEN):getTier() == 1
    then
        target:delStatusEffect(xi.effect.REGEN)
    end

    if not target:addStatusEffect(xi.effect.REGEN, { power = power, duration = duration, origin = caster, tick = 3 }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.REGEN
end)

m:addOverride('xi.actions.spells.blue.occultation.onSpellCast', function(caster, target, spell)
    local skill    = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local power    = skill / 50
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    if skill < 100 then
        power = 2
    end

    if not target:addStatusEffect(xi.effect.BLINK, { power = power, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.BLINK
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if zoning or firstLogin then
        clearWindow(player, xi.effect.CASCADE)
        clearWindow(player, xi.effect.MANIFESTATION)
        setCascadeMatt(player, false)
    end

    attachWindows(player)
end)

if xi.actions and xi.actions.abilities and xi.actions.abilities.manifestation then
    xi.actions.abilities.manifestation.onUseAbility = function(player, target, ability)
        if ability and ability.setRecast then
            ability:setRecast(0)
        end

        return applyTimedWindow(player, xi.effect.MANIFESTATION)
    end
end
