-----------------------------------
-- Pixie Rescue (module). No core player.lua edits.
-- On death: spirit on corpse, Raise, then full HP/MP (weakness stays).
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_pixie_rescue')

xi = xi or {}
xi.pixieRescue = xi.pixieRescue or {}

local PENDING_LOCAL_VAR       = 'PIXIE_RESCUE_PENDING'
local TICKET_LOCAL_VAR        = 'PIXIE_RESCUE_TICKET'
local POST_REVIVE_HANDLED_VAR = 'PIXIE_RESCUE_POST_DONE'
local PRE_RAISE_GUARD_VAR     = 'PIXIE_PRE_RAISE_G'
local MOB_TARG_LOCAL_VAR      = 'PIXIE_R_MTARG'
local DEATH_GATE_LOCAL_VAR    = 'PIXIE_DEATH_GATE'
local DEATH_LISTENER_ID       = 'IXI20_PIXIE_DEATH'

local PRE_RAISE_VEIL_SECONDS   = 55
local RAISE_CAST_START_DELAY_MS = 1000
local WATCH_FAST_MS            = 50
local WATCH_FAST_WINDOW_MS     = 5000
local WATCH_SLOW_MS            = 500
local WATCH_RECAST_MS          = 20000
local WATCH_MAX_MS             = 60 * 60 * 1000 -- full death homepoint window
local PIXIE_GROUP_ID           = 35
local PIXIE_GROUP_ZONE_ID      = 100
local MAX_PACKET_NAME_LEN      = 20

local function rescueChat(player, message)
    player:printToPlayer(message, 0x1F)
end

local function addPlayerBuff(player, effectId, power, tickSeconds, durationSeconds)
    player:addStatusEffect(effectId, {
        power    = power,
        tick     = tickSeconds,
        duration = durationSeconds,
        origin   = player,
    })
end

local function clearNearbyAggro(player, rescueMob, radius)
    local entities = player:getEntitiesInRange(
        player,
        xi.aoeType.ROUND,
        xi.aoeRadius.ATTACKER,
        radius or 42,
        xi.findFlag.HIT_ALL,
        xi.targetType.MOB
    ) or {}

    for _, ent in ipairs(entities) do
        if ent and ent:getObjType() == xi.objType.MOB then
            local skipEnt = false
            if rescueMob and rescueMob:isAlive() then
                skipEnt = ent:getID() == rescueMob:getID()
            end

            if not skipEnt then
                pcall(function()
                    ent:clearEnmityForEntity(player)
                end)
                pcall(function()
                    ent:resetEnmity(player)
                end)
                if rescueMob and rescueMob:isAlive() then
                    pcall(function()
                        ent:clearEnmityForEntity(rescueMob)
                    end)
                    pcall(function()
                        ent:resetEnmity(rescueMob)
                    end)
                end

                pcall(function()
                    ent:disengage()
                end)
            end
        end
    end
end

local function schedulePostSpellThreatWipe(player, rescueMob, radius)
    if not player or not rescueMob then
        return
    end

    local r = radius or 58
    for _, ms in ipairs({ 250, 700, 1400, 2600, 4200, 7000, 10000 }) do
        player:timer(ms, function(p)
            if rescueMob and rescueMob:isAlive() then
                clearNearbyAggro(p, rescueMob, r)
            end
        end)
    end
end

local function castSpellWithThreatWipe(player, rescueMob, spellId, target)
    clearNearbyAggro(player, rescueMob, 58)
    pcall(function()
        rescueMob:castSpell(spellId, target)
    end)
    schedulePostSpellThreatWipe(player, rescueMob, 58)
end

local function ensureAboveBloodAggroThreshold(pc)
    if not pc or not pc:isPC() or not pc:isAlive() then
        return
    end

    if pc:getHPP() < 75 then
        local minHp = math.ceil(pc:getMaxHP() * 0.75)
        if pc:getHP() < minHp then
            pc:setHP(minHp)
        end
    end
end

local function applyBloodAggroProtectionToNearbyParty(revivee)
    if not revivee then
        return
    end

    ensureAboveBloodAggroThreshold(revivee)

    local party = revivee:getParty() or {}
    for _, member in ipairs(party) do
        if
            member and
            member:isPC() and
            member:isAlive() and
            member:getZoneID() == revivee:getZoneID() and
            member:checkDistance(revivee) <= 40.0
        then
            ensureAboveBloodAggroThreshold(member)
        end
    end
end

local function fillToCurrentMaxResources(pc)
    if not pc or not pc:isPC() or not pc:isAlive() then
        return
    end

    pc:setHP(pc:getMaxHP())
    pc:setMP(pc:getMaxMP())
end

local function hasGodMode(player)
    if xi.ixi20GodMode and xi.ixi20GodMode.hasActive then
        return xi.ixi20GodMode.hasActive(player)
    end

    return player and player.isPC and player:isPC() and
        player.getGMLevel and player:getGMLevel() > 0 and
        player:getCharVar('GodMode') ~= 0
end

local function restoreGmEffectsFallback(player)
    if not player or player:getGMLevel() <= 0 then
        return
    end

    local mode = player:getCharVar('GodMode')
    if mode == 1 then
        player:addStatusEffect(xi.effect.MAX_HP_BOOST, { power = 1000, origin = player })
        player:addStatusEffect(xi.effect.MAX_MP_BOOST, { power = 1000, origin = player })
        player:addStatusEffect(xi.effect.MIGHTY_STRIKES, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.HUNDRED_FISTS, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.CHAINSPELL, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.PERFECT_DODGE, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.INVINCIBLE, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.ELEMENTAL_SFORZO, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.MANAFONT, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.REGAIN, { power = 300, origin = player })
        player:addStatusEffect(xi.effect.REFRESH, { power = 99, origin = player })
        player:addStatusEffect(xi.effect.REGEN, { power = 99, origin = player })
        player:addHP(50000)
        player:setMP(50000)
    elseif mode == 2 then
        player:addStatusEffect(xi.effect.MAX_HP_BOOST, { power = 200, origin = player })
        player:addStatusEffect(xi.effect.REGAIN, { power = 50, origin = player })
        player:addStatusEffect(xi.effect.REFRESH, { power = 999, origin = player })
        player:addStatusEffect(xi.effect.REGEN, { power = 999, origin = player })
        player:addStatusEffect(xi.effect.CHAINSPELL, { power = 1, origin = player })
        player:addStatusEffect(xi.effect.MANAFONT, { power = 1, origin = player })
        player:addHP(50000)
        player:setMP(50000)
    end

    if player:getCharVar('Immortal') == 1 then
        player:setUnkillable(true)
    end
end

local function restoreGmAfterRescue(player)
    if xi.ixi20GodMode and xi.ixi20GodMode.restoreAfterRaise then
        xi.ixi20GodMode.restoreAfterRaise(player)
        return
    end

    restoreGmEffectsFallback(player)
end

local function applyPostRaiseSafety(player, rescueTicket, rescueMob)
    local safetyDuration    = 75
    local hardGuardDuration = 25
    local keepGodMode       = hasGodMode(player)

    player:setUnkillable(true)
    player:setLocalVar(TICKET_LOCAL_VAR, rescueTicket)
    applyBloodAggroProtectionToNearbyParty(player)

    player:delStatusEffectSilent(xi.effect.SNEAK)
    player:delStatusEffectSilent(xi.effect.INVISIBLE)
    player:delStatusEffectSilent(xi.effect.DEODORIZE)
    addPlayerBuff(player, xi.effect.SNEAK, 0, 10, safetyDuration)
    addPlayerBuff(player, xi.effect.INVISIBLE, 0, 10, safetyDuration)
    addPlayerBuff(player, xi.effect.DEODORIZE, 0, 10, safetyDuration)

    -- Death already stripped !godmode buffs (death flag). Do not replace
    -- Invincible / Regen with a 15s rescue copy — that is what dropped godmode.
    if not keepGodMode then
        addPlayerBuff(player, xi.effect.REGEN, 12, 3, 45)
        addPlayerBuff(player, xi.effect.INVINCIBLE, 1, 0, 15)
        -- SP-uptime stretches real Invincible (30s JA) to 2 minutes. Keep this
        -- rescue window at 15s even if that listener still fires.
        local invincible = player:getStatusEffect(xi.effect.INVINCIBLE)
        if invincible and invincible:getDuration() > 0 then
            invincible:setDuration(15 * 1000)
        end
    end

    restoreGmAfterRescue(player)
    clearNearbyAggro(player, rescueMob, 45)

    for i = 1, hardGuardDuration * 2 do
        player:timer(i * 500, function(p)
            if p:getLocalVar(TICKET_LOCAL_VAR) ~= rescueTicket then
                return
            end

            ensureAboveBloodAggroThreshold(p)
            applyBloodAggroProtectionToNearbyParty(p)
            clearNearbyAggro(p, rescueMob, 45)
        end)
    end

    player:timer(hardGuardDuration * 1000, function(p)
        if p:getLocalVar(TICKET_LOCAL_VAR) == rescueTicket then
            if p:getCharVar('Immortal') ~= 1 then
                p:setUnkillable(false)
            else
                p:setUnkillable(true)
            end

            restoreGmAfterRescue(p)
            p:setLocalVar(TICKET_LOCAL_VAR, 0)
            p:setLocalVar(MOB_TARG_LOCAL_VAR, 0)
        end
    end)
end

local function applyPreRaiseVeil(player, rescueMob, rescueTicket)
    player:setUnkillable(true)
    player:setLocalVar(PRE_RAISE_GUARD_VAR, rescueTicket)
    player:delStatusEffectSilent(xi.effect.SNEAK)
    player:delStatusEffectSilent(xi.effect.INVISIBLE)
    player:delStatusEffectSilent(xi.effect.DEODORIZE)
    addPlayerBuff(player, xi.effect.SNEAK, 0, 10, PRE_RAISE_VEIL_SECONDS)
    addPlayerBuff(player, xi.effect.INVISIBLE, 0, 10, PRE_RAISE_VEIL_SECONDS)
    addPlayerBuff(player, xi.effect.DEODORIZE, 0, 10, PRE_RAISE_VEIL_SECONDS)
    addPlayerBuff(player, xi.effect.REGEN, 8, 3, 30)

    clearNearbyAggro(player, rescueMob, 52)

    for i = 1, 16 do
        player:timer(i * 3500, function(p)
            if p:getLocalVar(PRE_RAISE_GUARD_VAR) ~= rescueTicket or p:isAlive() then
                return
            end

            clearNearbyAggro(p, rescueMob, 52)
        end)
    end

    player:timer(30000, function(p)
        if p:getLocalVar(PRE_RAISE_GUARD_VAR) == rescueTicket and p:isDead() then
            p:setUnkillable(false)
            p:setLocalVar(PRE_RAISE_GUARD_VAR, 0)
        end
    end)
end

local function buildPartyMembersSameZone(owner)
    local party   = owner:getParty() or {}
    local members = {}

    for _, member in ipairs(party) do
        if member and member:isPC() and member:getZoneID() == owner:getZoneID() then
            members[#members + 1] = member
        end
    end

    return members
end

local function buildPartyInHealSpellRange(owner)
    local party    = owner:getParty() or {}
    local eligible = {}

    for _, member in ipairs(party) do
        if
            member and
            member:isPC() and
            member:getZoneID() == owner:getZoneID() and
            member:checkDistance(owner) <= 45.0
        then
            eligible[#eligible + 1] = member
        end
    end

    return eligible
end

local function healPartyWithPixieCasts(owner, mob, finishCb)
    local inSpellRange  = buildPartyInHealSpellRange(owner)
    local sameZoneParty = buildPartyMembersSameZone(owner)

    local function topOffAndNotify()
        for _, member in ipairs(sameZoneParty) do
            if member and member:isPC() and member:isAlive() then
                fillToCurrentMaxResources(member)
                rescueChat(member, '[Pixie] Gentle light restores your strength.')
            end
        end

        finishCb()
    end

    if not mob then
        topOffAndNotify()
        return
    end

    mob:setBattleID(owner:getBattleID())
    castSpellWithThreatWipe(owner, mob, xi.magic.spell.CURAGA_V, owner)

    owner:timer(6500, function()
        local needHeal = {}

        for _, member in ipairs(inSpellRange) do
            if member and member:isPC() and member:isAlive() and member:getHP() < member:getMaxHP() then
                needHeal[#needHeal + 1] = member
            end
        end

        local idx = 0
        local function nextCure()
            idx = idx + 1
            if idx > #needHeal then
                owner:timer(2000, topOffAndNotify)
                return
            end

            local target = needHeal[idx]
            if mob and mob:isAlive() and target and target:isAlive() then
                castSpellWithThreatWipe(owner, mob, xi.magic.spell.CURE_VI, target)
            end

            owner:timer(5200, nextCure)
        end

        if #needHeal == 0 then
            owner:timer(1200, topOffAndNotify)
        else
            nextCure()
        end
    end)
end

local function despawnRescueMob(mob)
    if mob and mob.setStatus then
        mob:setStatus(xi.status.DISAPPEAR)
    end
end

local function resolveRescueMobFromPlayer(player, mobArg)
    if mobArg and mobArg:isAlive() then
        return mobArg
    end

    local t = player:getLocalVar(MOB_TARG_LOCAL_VAR)
    if not t or t == 0 then
        return nil
    end

    local e = player:getEntity(t)
    if e and e:isAlive() and e:getObjType() == xi.objType.MOB then
        return e
    end

    return nil
end

local function tryCastPixieRaise(player, mobArg, isFirstAttempt)
    if not player or not player:isDead() then
        return
    end

    local spirit = resolveRescueMobFromPlayer(player, mobArg)
    if not spirit or not spirit:isAlive() then
        return
    end

    if isFirstAttempt then
        pcall(function()
            spirit:setSpawnAnimation(0)
        end)
    end

    castSpellWithThreatWipe(player, spirit, xi.magic.spell.RAISE, player)
end

local function tryCompletePixieReviveStand(player, rescueTicket, mobArg)
    if not player or not player:isPC() then
        return
    end

    if player:getLocalVar(POST_REVIVE_HANDLED_VAR) == 1 then
        return
    end

    if player:getLocalVar(TICKET_LOCAL_VAR) ~= rescueTicket then
        return
    end

    if not player:isAlive() then
        return
    end

    local mob = resolveRescueMobFromPlayer(player, mobArg)

    player:setLocalVar(POST_REVIVE_HANDLED_VAR, 1)
    player:setLocalVar(PRE_RAISE_GUARD_VAR, 0)
    ensureAboveBloodAggroThreshold(player)
    applyBloodAggroProtectionToNearbyParty(player)
    clearNearbyAggro(player, mob, 72)
    applyPostRaiseSafety(player, rescueTicket, mob)
    restoreGmAfterRescue(player)
    fillToCurrentMaxResources(player)
    ensureAboveBloodAggroThreshold(player)
    clearNearbyAggro(player, mob, 72)
    rescueChat(player, '[Pixie] Your spirit returns to you. Live.')
    healPartyWithPixieCasts(player, mob, function()
        despawnRescueMob(mob)
    end)
end

local function cleanupAbandonedRescue(player)
    if not player then
        return
    end

    local mob = resolveRescueMobFromPlayer(player, nil)
    despawnRescueMob(mob)
    pcall(function()
        if player:getCharVar('Immortal') == 1 then
            player:setUnkillable(true)
        else
            player:setUnkillable(false)
        end
    end)
    player:setLocalVar(TICKET_LOCAL_VAR, 0)
    player:setLocalVar(MOB_TARG_LOCAL_VAR, 0)
    player:setLocalVar(PRE_RAISE_GUARD_VAR, 0)
    player:setLocalVar(POST_REVIVE_HANDLED_VAR, 1)
    player:setLocalVar(PENDING_LOCAL_VAR, 0)
end

local function scheduleReviveWatch(player, rescueTicket, mobArg, elapsedMs, lastRecastMs)
    elapsedMs    = elapsedMs or 0
    lastRecastMs = lastRecastMs or 0

    local delay = (elapsedMs < WATCH_FAST_WINDOW_MS) and WATCH_FAST_MS or WATCH_SLOW_MS
    player:timer(delay, function(p)
        if not p or not p:isPC() then
            return
        end

        if p:getLocalVar(TICKET_LOCAL_VAR) ~= rescueTicket then
            return
        end

        if p:getLocalVar(POST_REVIVE_HANDLED_VAR) == 1 then
            return
        end

        if p:isAlive() then
            tryCompletePixieReviveStand(p, rescueTicket, mobArg)
            return
        end

        local nextElapsed = elapsedMs + delay
        if nextElapsed >= WATCH_MAX_MS then
            cleanupAbandonedRescue(p)
            return
        end

        local nextRecast = lastRecastMs
        if (nextElapsed - lastRecastMs) >= WATCH_RECAST_MS then
            tryCastPixieRaise(p, mobArg, false)
            nextRecast = nextElapsed
        end

        scheduleReviveWatch(p, rescueTicket, mobArg, nextElapsed, nextRecast)
    end)
end

function xi.pixieRescue.onPlayerRaiseAccept(player)
    if not player or not player:isPC() or not player:isAlive() then
        return
    end

    if player:getLocalVar(TICKET_LOCAL_VAR) == 0 or player:getLocalVar(POST_REVIVE_HANDLED_VAR) == 1 then
        return
    end

    tryCompletePixieReviveStand(player, player:getLocalVar(TICKET_LOCAL_VAR), nil)
end

function xi.pixieRescue.cleanupAbandonedRescue(player)
    cleanupAbandonedRescue(player)
end

local function resolveZoneForDynamicSpawn(player)
    local inst = player:getInstance()
    if inst then
        return inst
    end

    local z = player:getZone()
    if z then
        return z
    end

    local zoneId = player:getZoneID()
    if zoneId and zoneId > 0 then
        return GetZone(zoneId)
    end

    return nil
end

local function buildSpiritPacketName(playerName)
    local suffix   = ' Spirit'
    local safeName = tostring(playerName or 'Fallen')
    local maxBase  = MAX_PACKET_NAME_LEN - #suffix

    if maxBase < 3 then
        return 'Spirit'
    end

    if #safeName > maxBase then
        safeName = string.sub(safeName, 1, maxBase)
    end

    return safeName .. suffix
end

local function startPixieRescue(player, rescueTicket)
    despawnRescueMob(resolveRescueMobFromPlayer(player, nil))

    local zoneOrInst = resolveZoneForDynamicSpawn(player)
    if not zoneOrInst then
        printf('[pixie_rescue] no zone/instance for dynamic spawn (char=%s zoneId=%s)', player:getName(), tostring(player:getZoneID()))
        rescueChat(player, '[Pixie] (Rescue could not anchor to this area; contact a GM.)')
        return false
    end

    local sx         = player:getXPos()
    local sy         = player:getYPos()
    local sz         = player:getZPos()
    local srot       = player:getRotPos()
    local spiritName = buildSpiritPacketName(player:getName())
    local mob        = zoneOrInst:insertDynamicEntity({
        objtype                = xi.objType.MOB,
        name                   = 'Rescue_Pixie',
        packetName             = spiritName,
        -- Retail WotG pixie look (same as 1.0 pool 3148). Applied before zone insert.
        look                   = '0000EE0700000000000000000000000000000000',
        x                      = sx,
        y                      = sy,
        z                      = sz,
        rotation               = srot,
        groupId                = PIXIE_GROUP_ID,
        groupZoneId            = PIXIE_GROUP_ZONE_ID,
        minLevel               = 99,
        maxLevel               = 99,
        spellList              = 356,
        isAggroable            = false,
        releaseIdOnDisappear   = true,
        specialSpawnAnimation  = true,
        onMobSpawn             = function(mobArg)
            mobArg:setAnimationSub(8)
            mobArg:setAllegiance(xi.allegiance.PLAYER)
            mobArg:setMobMod(xi.mobMod.SKIP_ALLEGIANCE_CHECK, 1)
            mobArg:setMobMod(xi.mobMod.NO_AGGRO, 1)
            mobArg:setAutoAttackEnabled(false)
            mobArg:setMobAbilityEnabled(false)
            mobArg:setMagicCastingEnabled(false)
            mobArg:setMobMod(xi.mobMod.MAGIC_COOL, 999)
            mobArg:setUnkillable(true)
            mobArg:setUntargetable(true)
            pcall(function()
                mobArg:setIsAggroable(false)
            end)
            pcall(function()
                mobArg:setRoamFlags(xi.roamFlag.SCRIPTED)
            end)
        end,
        onMobRoam = function()
        end,
    })

    if not mob then
        printf('[pixie_rescue] insertDynamicEntity failed (char=%s zoneId=%s)', player:getName(), tostring(player:getZoneID()))
        rescueChat(player, '[Pixie] (Spirit could not take form; try again or contact a GM.)')
        return false
    end

    mob:setDropID(0)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
    mob:setSpawn(sx, sy, sz, srot)
    mob:setMobMod(xi.mobMod.SKIP_ALLEGIANCE_CHECK, 1)
    pcall(function()
        mob:setIsAggroable(false)
    end)
    pcall(function()
        mob:setRoamFlags(xi.roamFlag.SCRIPTED)
    end)
    mob:spawn()
    mob:setBattleID(player:getBattleID())
    rescueChat(player, string.format('[Pixie] %s rises from your fallen spirit, offering one more chance to live.', spiritName))
    applyPreRaiseVeil(player, mob, rescueTicket)
    clearNearbyAggro(player, mob, 48)
    mob:setUntargetable(false)
    player:setLocalVar(MOB_TARG_LOCAL_VAR, mob:getTargID())

    for i = 0, 8 do
        player:timer(RAISE_CAST_START_DELAY_MS + i * 1200, function(p2)
            tryCastPixieRaise(p2, mob, i == 0)
        end)
    end

    scheduleReviveWatch(player, rescueTicket, mob, 0, 0)

    return true
end

function xi.pixieRescue.dispatchToPlayer(player, options)
    options = options or {}

    if not player or not player:isPC() or not player:isDead() then
        return false, 'not_dead'
    end

    if not options.ignoreReraise and player:hasStatusEffect(xi.effect.RERAISE) then
        return false, 'reraise'
    end

    if not options.ignoreReraise and player.hasRaiseTractorMenu and player:hasRaiseTractorMenu() then
        return false, 'reraise'
    end

    if player:getLocalVar(PENDING_LOCAL_VAR) == 1 then
        return false, 'pending'
    end

    local rescueTicket = os.time() + math.random(1000, 999999)
    player:setLocalVar(PENDING_LOCAL_VAR, 1)
    player:setLocalVar(TICKET_LOCAL_VAR, rescueTicket)
    player:setLocalVar(POST_REVIVE_HANDLED_VAR, 0)
    rescueChat(player, '[Pixie] Your spirit stirs...')

    if not startPixieRescue(player, rescueTicket) then
        player:setLocalVar(PENDING_LOCAL_VAR, 0)
        player:setLocalVar(TICKET_LOCAL_VAR, 0)
        player:setLocalVar(MOB_TARG_LOCAL_VAR, 0)
        return false, 'spawn_failed'
    end

    return true, 'dispatched'
end

function xi.pixieRescue.onPlayerDeath(player)
    if not player or not player:isPC() then
        return
    end

    -- Die() + DEATH listener + onPlayerDeath can all land on the same tick.
    if player:getLocalVar(DEATH_GATE_LOCAL_VAR) == 1 then
        return
    end

    player:setLocalVar(DEATH_GATE_LOCAL_VAR, 1)
    player:setLocalVar(PENDING_LOCAL_VAR, 0)
    player:timer(1500, function(p)
        if p then
            p:setLocalVar(DEATH_GATE_LOCAL_VAR, 0)
        end
    end)

    local function tryDispatch(p)
        if not p or not p:isPC() then
            return
        end

        local ticket = p:getLocalVar(TICKET_LOCAL_VAR)
        if ticket ~= 0 and p:getLocalVar(POST_REVIVE_HANDLED_VAR) == 0 then
            local spirit = resolveRescueMobFromPlayer(p, nil)
            if spirit and spirit:isAlive() then
                applyPreRaiseVeil(p, spirit, ticket)
                tryCastPixieRaise(p, spirit, true)
                scheduleReviveWatch(p, ticket, spirit, 0, 0)
                return
            end
        end

        local ok, reason = xi.pixieRescue.dispatchToPlayer(p, { ignoreReraise = false })
        if not ok then
            printf('[pixie_rescue] death skip char=%s reason=%s', p:getName(), tostring(reason))
        end
    end

    -- Player is already dead here. Dispatch now; retry once if HP/state has not settled.
    tryDispatch(player)
    player:timer(250, function(p)
        if p and p:isPC() and p:isDead() and p:getLocalVar(TICKET_LOCAL_VAR) == 0 then
            tryDispatch(p)
        end
    end)
end

function xi.pixieRescue.attachDeathListener(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(DEATH_LISTENER_ID)
    player:addListener('DEATH', DEATH_LISTENER_ID, function(playerArg)
        xi.pixieRescue.onPlayerDeath(playerArg)
    end)
end

-- Later modules require() player.lua, which does `xi.player = {}` and wipes wraps.
-- addOverride is applied after that require. FileWatcher of this file discards
-- addOverride, so also wrap and re-attach listeners on every load.
local function wrapDeathHook()
    if not xi.player then
        return
    end

    if xi.player._ixi20PixieDeathFn == xi.player.onPlayerDeath then
        return
    end

    local rawOnDeath = xi.player.onPlayerDeath
    local function wrapped(player)
        if rawOnDeath then
            rawOnDeath(player)
        end

        xi.pixieRescue.onPlayerDeath(player)
    end

    xi.player.onPlayerDeath = wrapped
    xi.player._ixi20PixieDeathFn = wrapped
end

local function forEachOnlinePlayer(fn)
    if not xi.zone or not GetZone then
        return
    end

    local visitedZone = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and not visitedZone[zoneId] then
            visitedZone[zoneId] = true
            local zone = GetZone(zoneId)
            if zone then
                for _, p in pairs(zone:getPlayers() or {}) do
                    if p and p:isPC() then
                        fn(p)
                    end
                end
            end
        end
    end
end

local function clipStretchedRescueInvincible(player)
    if not player or not player:hasStatusEffect(xi.effect.INVINCIBLE) then
        return
    end

    if hasGodMode(player) then
        return
    end

    local fromRescue = player:getLocalVar(TICKET_LOCAL_VAR) ~= 0 or
        (player:hasStatusEffect(xi.effect.SNEAK) and player:hasStatusEffect(xi.effect.INVISIBLE))

    if not fromRescue then
        return
    end

    local invincible = player:getStatusEffect(xi.effect.INVINCIBLE)
    -- Duration 0 is !godmode (permanent). Only clip a timed rescue copy.
    if invincible and invincible:getDuration() > 20 * 1000 then
        invincible:setDuration(15 * 1000)
    end
end

local function resumeOutstandingRescues()
    forEachOnlinePlayer(function(p)
        xi.pixieRescue.attachDeathListener(p)
        clipStretchedRescueInvincible(p)

        local ticket = p:getLocalVar(TICKET_LOCAL_VAR)
        if ticket ~= 0 and p:getLocalVar(POST_REVIVE_HANDLED_VAR) == 0 then
            local spirit = resolveRescueMobFromPlayer(p, nil)
            if p:isAlive() then
                tryCompletePixieReviveStand(p, ticket, spirit)
            elseif spirit and spirit:isAlive() then
                applyPreRaiseVeil(p, spirit, ticket)
                tryCastPixieRaise(p, spirit, true)
                scheduleReviveWatch(p, ticket, spirit, 0, 0)
            else
                scheduleReviveWatch(p, ticket, nil, 0, 0)
                if not (p.hasRaiseTractorMenu and p:hasRaiseTractorMenu()) then
                    xi.pixieRescue.dispatchToPlayer(p, { ignoreReraise = false })
                end
            end
        elseif p:isDead() then
            xi.pixieRescue.dispatchToPlayer(p, { ignoreReraise = false })
        end
    end)
end

m:addOverride('xi.player.onPlayerDeath', function(player)
    super(player)
    xi.pixieRescue.onPlayerDeath(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    xi.pixieRescue.attachDeathListener(player)
end)

wrapDeathHook()
resumeOutstandingRescues()

xi.module.registerCommand('pixierescue', {
    cmdprops =
    {
        permission = 1,
        parameters = '',
    },
    onTrigger = function(player)
        local deadFound      = 0
        local dispatched     = 0
        local skippedReraise = 0
        local skippedOther   = 0
        local visitedZone    = {}

        for _, zoneId in pairs(xi.zone) do
            if type(zoneId) == 'number' and not visitedZone[zoneId] then
                visitedZone[zoneId] = true
                local zone = GetZone(zoneId)
                if zone then
                    for _, p in pairs(zone:getPlayers() or {}) do
                        if p and p:isPC() and p:isDead() then
                            deadFound = deadFound + 1
                            local ok, reason = xi.pixieRescue.dispatchToPlayer(p, { ignoreReraise = false })
                            if ok then
                                dispatched = dispatched + 1
                            elseif reason == 'reraise' then
                                skippedReraise = skippedReraise + 1
                            else
                                skippedOther = skippedOther + 1
                            end
                        end
                    end
                end
            end
        end

        local summary = string.format(
            '[pixierescue] dead=%u dispatched=%u skipped_reraise=%u skipped_other=%u',
            deadFound,
            dispatched,
            skippedReraise,
            skippedOther
        )
        print(summary)
        player:printToPlayer(summary)
    end,
})
