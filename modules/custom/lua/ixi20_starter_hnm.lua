-----------------------------------
-- Imagine XI 1.0 starter-zone HNMs (module).
-- XP-pool pop in nation fields. Stored main > 12 is synced down to 12
-- on engage; sync ends on mob death, player death, or zone.
-- Needs custom/sql/ixi20_starter_hnm.sql (group 36 HNM / 37 adds).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_hnm_claim_lib')
require('scripts/globals/npc_util')
-----------------------------------

local m = Module:new('ixi20_starter_hnm')

xi = xi or {}
xi.imagine = xi.imagine or {}
xi.imagine.starterHnm = xi.imagine.starterHnm or {}

local starterHnm = xi.imagine.starterHnm

starterHnm.BASE_XP_THRESHOLD   = 100000
starterHnm.XP_JITTER_MIN       = 0.85
starterHnm.XP_JITTER_MAX       = 1.15
starterHnm.POST_KILL_COOLDOWN  = 45 * 60
starterHnm.DESPAWN_SECONDS     = 2 * 60 * 60
starterHnm.MAX_CLAIM_LEVEL     = 12
starterHnm.LOOT_ROLLS          = 3
starterHnm.CLUSTER_ROLLS       = 2
starterHnm.GIL_MIN             = 3000
starterHnm.GIL_MAX             = 8000
starterHnm.HP_SCALE            = 1100
starterHnm.MOB_LEVEL           = 16
starterHnm.DAMAGE_MULTIPLIER   = 850
starterHnm.ATT                 = 40
starterHnm.ACC                 = 200
starterHnm.EVA                 = 40
starterHnm.MATT                = 28
starterHnm.MACC                = 140
starterHnm.REGEN               = 18
starterHnm.AOE_INTERVAL_SEC    = 20
starterHnm.PHASE_HPP           = 50
starterHnm.PHASE_DAMAGE_MULT   = 1200
starterHnm.PHASE_ATT_BONUS     = 25
starterHnm.PHASE_REGEN_BONUS   = 10
starterHnm.ADD_COUNT           = 2
starterHnm.ADD_LEVEL           = 12
starterHnm.ADD_DAMAGE_MULTIPLIER = 220
starterHnm.ADD_ATT             = 25
starterHnm.ADD_ACC             = 140
starterHnm.XP_LISTENER_ID      = 'IMAGINE_STARTER_HNM_XP'
starterHnm.ENGAGE_GUARD_LISTENER_ID = 'IMAGINE_STARTER_HNM_ENGAGE_GUARD'
starterHnm.MAGIC_GUARD_LISTENER_ID  = 'IMAGINE_STARTER_HNM_MAGIC_GUARD'
starterHnm.DEATH_GUARD_LISTENER_ID  = 'IMAGINE_STARTER_HNM_DEATH_GUARD'
starterHnm.CLAIM_SHIELD_MS     = 5000
starterHnm.SYNC_VAR            = '[starterHnm]sync'

starterHnm.lookProfiles =
{
    ronfaure =
    {
        look          = '0x0000580100000000000000000000000000000000',
        modelSize     = 3,
        hitboxSize    = 5.8,
    },
    gustaberg =
    {
        look          = '0x0000E30200000000000000000000000000000000',
        modelSize     = 3,
        hitboxSize    = 5.4,
    },
    saruta =
    {
        look          = '0x0000840100000000000000000000000000000000',
        modelSize     = 3,
        hitboxSize    = 5.3,
    },
}

starterHnm.combatProfiles =
{
    ronfaure =
    {
        addGroupId   = 37,
        addName      = 'Wild Sheep',
        aoeSpells    = { xi.magic.spell.SLEEPGA, xi.magic.spell.STONEGA, xi.magic.spell.RASP },
        phaseMessage = 'The warden stamps the earth and wild sheep rush to its defense!',
    },
    gustaberg =
    {
        addGroupId   = 37,
        addName      = 'Rock Lizard',
        aoeSpells    = { xi.magic.spell.BIND, xi.magic.spell.STONEGA, xi.magic.spell.AEROGA },
        phaseMessage = 'The sentinel bellows in rage and rock lizards skitter to its side!',
    },
    saruta =
    {
        addGroupId   = 37,
        addName      = 'Tiny Mandragora',
        aoeSpells    = { xi.magic.spell.POISONGA, xi.magic.spell.WATERGA, xi.magic.spell.SLEEPGA },
        phaseMessage = 'The warden exhales a foul spore cloud and mandragora sprouts erupt nearby!',
    },
}

starterHnm.lootPool =
{
    550, 769, 910, 911, 1152, 2826, 2832, 2834, 2842, 912,
    12371, 12736, 12864, 12992, 13112, 13548, 13607, 14803,
    15218, 15351, 15546, 16185, 16296, 16443, 16486, 17366,
    17594, 17811, 18246, 18394, 18412, 19043, 19160, 4527,
    19305, 2854,
}

starterHnm.clusterPool =
{
    xi.item.FIRE_CLUSTER,
    xi.item.ICE_CLUSTER,
    xi.item.WIND_CLUSTER,
    xi.item.EARTH_CLUSTER,
    xi.item.LIGHTNING_CLUSTER,
    xi.item.WATER_CLUSTER,
    xi.item.LIGHT_CLUSTER,
    xi.item.DARK_CLUSTER,
}

starterHnm.zones =
{
    [xi.zone.WEST_RONFAURE] =
    {
        internalName = 'StarterHNM_WestRonfaure',
        packetName   = 'Ronfaure Warden',
        lookProfile  = 'ronfaure',
        groupId      = 36,
        groupZoneId  = xi.zone.WEST_RONFAURE,
        x = -200.0, y = -60.0, z = 200.0, rot = 128,
        areaHint     = 'the La Theine Plateau approaches',
        zoneScript   = 'West_Ronfaure',
    },
    [xi.zone.EAST_RONFAURE] =
    {
        internalName = 'StarterHNM_EastRonfaure',
        packetName   = 'Eastron Warden',
        lookProfile  = 'ronfaure',
        groupId      = 36,
        groupZoneId  = xi.zone.EAST_RONFAURE,
        x = 86.0, y = -65.0, z = 274.0, rot = 128,
        areaHint     = 'the southern grasslands of East Ronfaure',
        zoneScript   = 'East_Ronfaure',
    },
    [xi.zone.SOUTH_GUSTABERG] =
    {
        internalName = 'StarterHNM_SouthGustaberg',
        packetName   = 'Gustaberg Warden',
        lookProfile  = 'gustaberg',
        groupId      = 36,
        groupZoneId  = xi.zone.SOUTH_GUSTABERG,
        x = -300.0, y = 22.0, z = -380.0, rot = 64,
        areaHint     = 'the far southern cliffs of Gustaberg',
        zoneScript   = 'South_Gustaberg',
    },
    [xi.zone.NORTH_GUSTABERG] =
    {
        internalName = 'StarterHNM_NorthGustaberg',
        packetName   = 'Gustaberg Sentinel',
        lookProfile  = 'gustaberg',
        groupId      = 36,
        groupZoneId  = xi.zone.NORTH_GUSTABERG,
        x = 660.0, y = 0.0, z = 306.0, rot = 190,
        areaHint     = 'the Konschtat Highlands border',
        zoneScript   = 'North_Gustaberg',
    },
    [xi.zone.EAST_SARUTABARUTA] =
    {
        internalName = 'StarterHNM_EastSaruta',
        packetName   = 'Saruta Warden',
        lookProfile  = 'saruta',
        groupId      = 36,
        groupZoneId  = xi.zone.EAST_SARUTABARUTA,
        x = -125.0, y = -3.0, z = -520.0, rot = 4,
        areaHint     = 'the deep Sarutabaruta savanna',
        zoneScript   = 'East_Sarutabaruta',
    },
    [xi.zone.WEST_SARUTABARUTA] =
    {
        internalName = 'StarterHNM_WestSaruta',
        packetName   = 'Saruta Sentinel',
        lookProfile  = 'saruta',
        groupId      = 36,
        groupZoneId  = xi.zone.WEST_SARUTABARUTA,
        x = 320.0, y = -7.0, z = -45.0, rot = 189,
        areaHint     = 'the Tarutaru waterways',
        zoneScript   = 'West_Sarutabaruta',
    },
}

local function xpVar(zoneId)
    return string.format('[StarterHNM]XP_%u', zoneId)
end

local function thresholdVar(zoneId)
    return string.format('[StarterHNM]Threshold_%u', zoneId)
end

local function cooldownVar(zoneId)
    return string.format('[StarterHNM]Cooldown_%u', zoneId)
end

function starterHnm.storedMainLevel(player)
    if not player or not player.getMainJob then
        return 0
    end

    return player:getJobLevel(player:getMainJob())
end

-- Effective level after fight-sync. Used for claim / loot.
function starterHnm.isEligible(player)
    return player
        and player:getObjType() == xi.objType.PC
        and player:getMainLvl() <= starterHnm.MAX_CLAIM_LEVEL
end

function starterHnm.resolvePlayer(entity)
    if not entity then
        return nil
    end

    if entity:getObjType() == xi.objType.PC then
        return entity
    end

    if entity.getMaster then
        local master = entity:getMaster()
        if master and master:getObjType() == xi.objType.PC then
            return master
        end
    end

    return nil
end

function starterHnm.releaseSync(player)
    if not player or player:getObjType() ~= xi.objType.PC then
        return
    end

    if player:getLocalVar(starterHnm.SYNC_VAR) == 0 then
        return
    end

    player:setLocalVar(starterHnm.SYNC_VAR, 0)
    if player:hasStatusEffect(xi.effect.LEVEL_RESTRICTION) then
        player:delStatusEffect(xi.effect.LEVEL_RESTRICTION)
    end
end

function starterHnm.releaseAllSynced(mob)
    local zone = mob and mob.getZone and mob:getZone()
    if not zone then
        return
    end

    local mobId = mob:getID()
    for _, player in pairs(zone:getPlayers()) do
        if player:getLocalVar(starterHnm.SYNC_VAR) == mobId then
            starterHnm.releaseSync(player)
        end
    end
end

-- Pull stored-main > 12 down to 12. Does not sync anyone up.
function starterHnm.applyFightSync(player, mob)
    if not player or player:getObjType() ~= xi.objType.PC or not mob then
        return
    end

    if starterHnm.storedMainLevel(player) <= starterHnm.MAX_CLAIM_LEVEL then
        return
    end

    player:setLocalVar(starterHnm.SYNC_VAR, mob:getID())

    if player:hasStatusEffect(xi.effect.LEVEL_RESTRICTION) then
        local effect = player:getStatusEffect(xi.effect.LEVEL_RESTRICTION)
        if effect and effect:getPower() == starterHnm.MAX_CLAIM_LEVEL then
            return
        end

        player:delStatusEffect(xi.effect.LEVEL_RESTRICTION)
    end

    player:addStatusEffect(xi.effect.LEVEL_RESTRICTION, {
        power  = starterHnm.MAX_CLAIM_LEVEL,
        origin = player,
    })
    player:printToPlayer(string.format(
        'You are synced to level %u for this fight. It ends if the monster dies or you do.',
        starterHnm.MAX_CLAIM_LEVEL
    ), xi.msg.channel.SYSTEM_3)
end

function starterHnm.getThreshold(zoneId)
    local stored = GetServerVariable(thresholdVar(zoneId))
    if stored <= 0 then
        local jitter = starterHnm.XP_JITTER_MIN + math.random() * (starterHnm.XP_JITTER_MAX - starterHnm.XP_JITTER_MIN)
        stored = math.floor(starterHnm.BASE_XP_THRESHOLD * jitter)
        SetServerVariable(thresholdVar(zoneId), stored)
    end

    return stored
end

function starterHnm.isOnCooldown(zoneId)
    return GetServerVariable(cooldownVar(zoneId)) > os.time()
end

function starterHnm.isActive(zoneId)
    local cfg = starterHnm.zones[zoneId]
    if not cfg then
        return false
    end

    local zone = GetZone(zoneId)
    if not zone then
        return false
    end

    local entities = zone:queryEntitiesByName('DE_' .. cfg.internalName)
    for _, mob in pairs(entities) do
        if mob:isSpawned() and mob:isAlive() then
            return true
        end
    end

    return false
end

function starterHnm.isStarterHnmMob(entity)
    return entity
        and entity:getObjType() == xi.objType.MOB
        and entity:getLocalVar('[starterHnm]mob') == 1
end

function starterHnm.tryApplyFightSync(player, target)
    if not player or not starterHnm.isStarterHnmMob(target) then
        return
    end

    starterHnm.applyFightSync(player, target)
end

function starterHnm.getLookProfile(zoneId)
    local cfg = starterHnm.zones[zoneId]
    return cfg and starterHnm.lookProfiles[cfg.lookProfile] or nil
end

function starterHnm.getCombatProfile(zoneId)
    local cfg = starterHnm.zones[zoneId]
    return cfg and starterHnm.combatProfiles[cfg.lookProfile] or nil
end

function starterHnm.broadcast(zone, message)
    for _, player in pairs(zone:getPlayers()) do
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
    end
end

function starterHnm.notifyCombatStart(mob)
    if mob:getLocalVar('[starterHnm]combatAnnounced') == 1 then
        return
    end

    mob:setLocalVar('[starterHnm]combatAnnounced', 1)

    local zone = mob:getZone()
    if not zone then
        return
    end

    for _, player in pairs(zone:getPlayers()) do
        player:printToPlayer(string.format(
            'This notorious monster is far too dangerous to face alone. Gather allies! Anyone above level %u is synced down for the fight.',
            starterHnm.MAX_CLAIM_LEVEL
        ), xi.msg.channel.SYSTEM_3)
    end
end

function starterHnm.tryAoe(mob)
    local profile = starterHnm.getCombatProfile(mob:getZoneID())
    if not profile or not profile.aoeSpells or #profile.aoeSpells == 0 then
        return
    end

    if mob.canUseAbilities and not mob:canUseAbilities() then
        return
    end

    local nextIndex = mob:getLocalVar('[starterHnm]aoeIndex') + 1
    if nextIndex > #profile.aoeSpells then
        nextIndex = 1
    end

    mob:setLocalVar('[starterHnm]aoeIndex', nextIndex)
    mob:castSpell(profile.aoeSpells[nextIndex], mob:getTarget() or mob)
end

function starterHnm.spawnAdds(parentMob)
    if parentMob:getLocalVar('[starterHnm]addsSpawned') == 1 then
        return
    end

    local zoneId  = parentMob:getZoneID()
    local cfg     = starterHnm.zones[zoneId]
    local profile = starterHnm.getCombatProfile(zoneId)
    local zone    = parentMob:getZone()
    if not cfg or not profile or not zone then
        return
    end

    parentMob:setLocalVar('[starterHnm]addsSpawned', 1)

    local px = parentMob:getXPos()
    local py = parentMob:getYPos()
    local pz = parentMob:getZPos()
    local parentId = parentMob:getID()
    local target = parentMob:getTarget()

    for i = 1, starterHnm.ADD_COUNT do
        local offset = (i - 1.5) * 2.5
        local add = zone:insertDynamicEntity({
            objtype              = xi.objType.MOB,
            name                 = string.format('StarterHNM_Add_%u_%u', parentId, i),
            packetName           = profile.addName,
            groupId              = profile.addGroupId,
            groupZoneId          = cfg.groupZoneId,
            minLevel             = starterHnm.ADD_LEVEL,
            maxLevel             = starterHnm.ADD_LEVEL,
            x                    = px + offset,
            y                    = py,
            z                    = pz + offset,
            rotation             = parentMob:getRotPos(),
            releaseIdOnDisappear = true,
            onMobSpawn = function(addMob)
                addMob:setMobMod(xi.mobMod.NO_DROPS, 1)
                addMob:setMobMod(xi.mobMod.SUPERLINK, parentId)
                addMob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, starterHnm.ADD_DAMAGE_MULTIPLIER)
                addMob:setMod(xi.mod.ATT, starterHnm.ADD_ATT)
                addMob:setMod(xi.mod.ACC, starterHnm.ADD_ACC)
            end,
        })

        if add then
            add:setSpawn(px + offset, py, pz + offset, parentMob:getRotPos())
            add:spawn()
            parentMob:setLocalVar(string.format('[starterHnm]add%u', i), add:getID())
            if target then
                add:updateEnmity(target)
            end
        end
    end

    if profile.phaseMessage then
        starterHnm.broadcast(zone, profile.phaseMessage)
    end
end

function starterHnm.enterPhase2(mob)
    mob:setLocalVar('[starterHnm]phase2', 1)
    starterHnm.applyCombatStats(mob)
    mob:setMobMod(xi.mobMod.RUN_SPEED_MULT, 115)
    starterHnm.spawnAdds(mob)
end

function starterHnm.cleanupAdds(mob)
    for i = 1, starterHnm.ADD_COUNT do
        local addId = mob:getLocalVar(string.format('[starterHnm]add%u', i))
        if addId > 0 then
            local add = GetMobByID(addId)
            if add and add:isSpawned() then
                add:disengage()
                DespawnMob(addId)
            end

            mob:setLocalVar(string.format('[starterHnm]add%u', i), 0)
        end
    end
end

function starterHnm.onCombatTick(mob)
    if not mob:isEngaged() then
        return
    end

    if mob:getHPP() <= starterHnm.PHASE_HPP and mob:getLocalVar('[starterHnm]phase2') == 0 then
        starterHnm.enterPhase2(mob)
    end

    local now = os.time()
    if now < mob:getLocalVar('[starterHnm]nextAoe') then
        return
    end

    starterHnm.tryAoe(mob)
    mob:setLocalVar('[starterHnm]nextAoe', now + starterHnm.AOE_INTERVAL_SEC)
end

function starterHnm.attachLevelGuard(mob)
    mob:removeListener('STARTER_HNM_ENGAGE')
    mob:removeListener('STARTER_HNM_DAMAGE')
    mob:removeListener('STARTER_HNM_ROAM')

    mob:addListener('ENGAGE', 'STARTER_HNM_ENGAGE', function(mobArg, target)
        local player = starterHnm.resolvePlayer(target)
        if player then
            starterHnm.applyFightSync(player, mobArg)
        end

        starterHnm.notifyCombatStart(mobArg)
        mobArg:setLocalVar('[starterHnm]nextAoe', os.time() + 15)
    end)

    mob:addListener('TAKE_DAMAGE', 'STARTER_HNM_DAMAGE', function(mobArg, amount, attacker)
        local player = starterHnm.resolvePlayer(attacker)
        if player then
            starterHnm.applyFightSync(player, mobArg)
        end
    end)
end

function starterHnm.applyCombatStats(mob)
    if mob:getMainLvl() < starterHnm.MOB_LEVEL then
        mob:setMobLevel(starterHnm.MOB_LEVEL, false)
    end

    local phase2 = mob:getLocalVar('[starterHnm]phase2') == 1
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, phase2 and starterHnm.PHASE_DAMAGE_MULT or starterHnm.DAMAGE_MULTIPLIER)
    mob:setMod(xi.mod.ATT, starterHnm.ATT + (phase2 and starterHnm.PHASE_ATT_BONUS or 0))
    mob:setMod(xi.mod.ACC, starterHnm.ACC)
    mob:setMod(xi.mod.RACC, starterHnm.ACC)
    mob:setMod(xi.mod.EVA, starterHnm.EVA)
    mob:setMod(xi.mod.MATT, starterHnm.MATT)
    mob:setMod(xi.mod.MACC, starterHnm.MACC)
    mob:setMod(xi.mod.REGEN, starterHnm.REGEN + (phase2 and starterHnm.PHASE_REGEN_BONUS or 0))
    mob:setMagicCastingEnabled(true)
    mob:setMobMod(xi.mobMod.NO_SPELL_COST, 1)
end

function starterHnm.applyMobSetup(mob)
    mob:setMobMod(xi.mobMod.CHECK_AS_NM, 1)
    mob:setMobMod(xi.mobMod.HP_SCALE, starterHnm.HP_SCALE)
    starterHnm.applyCombatStats(mob)
    local scaledHp = math.max(1, math.floor(mob:getMaxHP() * (starterHnm.HP_SCALE / 100)))
    mob:setMaxHP(scaledHp)
    mob:setHP(scaledHp)
    mob:setMobMod(xi.mobMod.NO_LINK, 1)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)

    local profile = starterHnm.getLookProfile(mob:getZoneID())
    if profile then
        mob:setModelSize(profile.modelSize)
        mob:setHitboxSize(profile.hitboxSize)
    end

    mob:setLocalVar('[starterHnm]mob', 1)
    mob:setLocalVar('[starterHnm]aoeIndex', 0)
    mob:setLocalVar('[starterHnm]nextAoe', 0)
    mob:setLocalVar('[starterHnm]phase2', 0)
    mob:setLocalVar('[starterHnm]addsSpawned', 0)
    mob:setLocalVar('[starterHnm]combatAnnounced', 0)

    starterHnm.attachLevelGuard(mob)

    mob:addListener('COMBAT_TICK', 'STARTER_HNM_COMBAT', function(mobArg)
        starterHnm.onCombatTick(mobArg)
    end)

    mob:addListener('DISENGAGE', 'STARTER_HNM_DISENGAGE', function(mobArg)
        mobArg:setLocalVar('[starterHnm]combatAnnounced', 0)
        starterHnm.cleanupAdds(mobArg)

        mobArg:setLocalVar('[starterHnm]phase2', 0)
        mobArg:setLocalVar('[starterHnm]addsSpawned', 0)
        starterHnm.applyCombatStats(mobArg)
        mobArg:setMobMod(xi.mobMod.RUN_SPEED_MULT, 100)
    end)

    xi.ixi20HnmClaim.attach(mob, {
        shieldMs       = starterHnm.CLAIM_SHIELD_MS,
        filterFn       = starterHnm.isEligible,
        listenerPrefix = 'IXI20_STARTER_HNM_CLAIM',
    })
    -- onMobSpawn already happened; the SPAWN listener will not fire for this pop.
    xi.ixi20HnmClaim.beginLottery(mob, starterHnm.CLAIM_SHIELD_MS, starterHnm.isEligible)
end

function starterHnm.awardLoot(player)
    local gilAmount = math.random(starterHnm.GIL_MIN, starterHnm.GIL_MAX)
    player:addGil(gilAmount)

    local pool  = utils.shuffle(starterHnm.lootPool)
    local items = {}
    for i = 1, math.min(starterHnm.LOOT_ROLLS, #pool) do
        items[i] = pool[i]
    end

    local clusters = utils.shuffle(starterHnm.clusterPool)
    for i = 1, math.min(starterHnm.CLUSTER_ROLLS, #clusters) do
        items[#items + 1] = clusters[i]
    end

    player:timer(100, function(p)
        if p and p:isPC() then
            npcUtil.giveItem(p, items)
        end
    end)
end

function starterHnm.onMobDeath(mob, player, optParams)
    local zoneId = mob:getZoneID()
    starterHnm.cleanupAdds(mob)
    SetServerVariable(cooldownVar(zoneId), os.time() + starterHnm.POST_KILL_COOLDOWN)
    SetServerVariable(thresholdVar(zoneId), 0)

    local killer = player
    local giveLoot = killer
        and (not optParams or optParams.isKiller)
        and (starterHnm.isEligible(killer) or killer:getLocalVar(starterHnm.SYNC_VAR) == mob:getID())

    -- Drop fight-sync before gil converts to XP, or auto-learn announces
    -- the restricted level (Blink at 12) instead of the stored ding.
    starterHnm.releaseAllSynced(mob)

    if giveLoot then
        starterHnm.awardLoot(killer)
    end
end

function starterHnm.scheduleDespawn(mob)
    mob:timer(starterHnm.DESPAWN_SECONDS * 1000, function(mobArg)
        if mobArg and mobArg:isAlive() then
            starterHnm.releaseAllSynced(mobArg)
            mobArg:disengage()
            DespawnMob(mobArg:getID())
        end
    end)
end

function starterHnm.despawnActive(zoneId)
    local cfg = starterHnm.zones[zoneId]
    if not cfg then
        return false
    end

    local zone = GetZone(zoneId)
    if not zone then
        return false
    end

    local despawned = false
    for _, mob in pairs(zone:queryEntitiesByName('DE_' .. cfg.internalName)) do
        if mob:isSpawned() then
            starterHnm.releaseAllSynced(mob)
            mob:disengage()
            DespawnMob(mob:getID())
            despawned = true
        end
    end

    return despawned
end

function starterHnm.spawnMob(zoneId, opts)
    opts = opts or {}
    local cfg = starterHnm.zones[zoneId]
    if not cfg then
        return false, 'invalid zone'
    end

    if starterHnm.isActive(zoneId) then
        if opts.replaceActive then
            starterHnm.despawnActive(zoneId)
        else
            return false, 'already active'
        end
    end

    if starterHnm.isOnCooldown(zoneId) and not opts.ignoreCooldown then
        return false, 'on cooldown'
    end

    local zone = GetZone(zoneId)
    if not zone then
        return false, 'zone unavailable'
    end

    local spawnX, spawnY, spawnZ, spawnRot = cfg.x, cfg.y, cfg.z, cfg.rot
    if opts.atPlayer then
        spawnX = opts.atPlayer:getXPos()
        spawnY = opts.atPlayer:getYPos()
        spawnZ = opts.atPlayer:getZPos()
        spawnRot = opts.atPlayer:getRotPos()
    end

    local lookProfile = starterHnm.getLookProfile(zoneId)
    local mob = zone:insertDynamicEntity({
        objtype               = xi.objType.MOB,
        name                  = cfg.internalName,
        packetName            = cfg.packetName,
        look                  = lookProfile and lookProfile.look or nil,
        groupId               = cfg.groupId,
        groupZoneId           = cfg.groupZoneId,
        minLevel              = starterHnm.MOB_LEVEL,
        maxLevel              = starterHnm.MOB_LEVEL,
        x                     = spawnX,
        y                     = spawnY,
        z                     = spawnZ,
        rotation              = spawnRot,
        releaseIdOnDisappear  = true,
        specialSpawnAnimation = true,
        isAggroable           = true,
        modelSize             = lookProfile and lookProfile.modelSize or nil,
        modelHitboxSize       = lookProfile and lookProfile.hitboxSize or nil,
        onMobSpawn = function(mobArg)
            starterHnm.applyMobSetup(mobArg)
        end,
        onMobEngage = function(mobArg, target)
            local player = starterHnm.resolvePlayer(target)
            if player then
                starterHnm.applyFightSync(player, mobArg)
            end
        end,
        onMobFight = function(mobArg, target)
            local player = starterHnm.resolvePlayer(target)
            if player then
                starterHnm.applyFightSync(player, mobArg)
            end
        end,
        onMobDeath = function(mobArg, player, optParams)
            starterHnm.onMobDeath(mobArg, player, optParams)
        end,
    })

    if not mob then
        return false, 'insertDynamicEntity failed'
    end

    if opts.ignoreCooldown then
        SetServerVariable(cooldownVar(zoneId), 0)
    end

    mob:setSpawn(spawnX, spawnY, spawnZ, spawnRot)
    mob:spawn()
    starterHnm.scheduleDespawn(mob)

    if not opts.silent then
        starterHnm.broadcast(zone, string.format(
            '%s has emerged near %s! Seek allies — anyone above level %u is synced down for the fight!',
            cfg.packetName,
            cfg.areaHint or 'this zone',
            starterHnm.MAX_CLAIM_LEVEL
        ))
    end

    return true, cfg.packetName
end

function starterHnm.trySpawn(zoneId)
    starterHnm.spawnMob(zoneId)
end

function starterHnm.gmSpawn(zoneId, opts)
    opts = opts or {}
    opts.ignoreCooldown = true
    opts.replaceActive = true
    return starterHnm.spawnMob(zoneId, opts)
end

function starterHnm.getZoneStatus(zoneId)
    local cfg = starterHnm.zones[zoneId]
    if not cfg then
        return nil
    end

    local cooldownUntil = GetServerVariable(cooldownVar(zoneId))
    local now = os.time()

    return {
        zoneId      = zoneId,
        name        = cfg.packetName,
        xp          = GetServerVariable(xpVar(zoneId)),
        threshold   = starterHnm.getThreshold(zoneId),
        active      = starterHnm.isActive(zoneId),
        onCooldown  = cooldownUntil > now,
        cooldownSec = math.max(0, cooldownUntil - now),
    }
end

function starterHnm.addZoneExp(zoneId, exp)
    local cfg = starterHnm.zones[zoneId]
    if not cfg or exp <= 0 or starterHnm.isOnCooldown(zoneId) or starterHnm.isActive(zoneId) then
        return
    end

    local total = GetServerVariable(xpVar(zoneId)) + exp
    local threshold = starterHnm.getThreshold(zoneId)
    if total >= threshold then
        SetServerVariable(xpVar(zoneId), 0)
        starterHnm.trySpawn(zoneId)
    else
        SetServerVariable(xpVar(zoneId), total)
    end
end

function starterHnm.syncXpListener(player)
    if not player or player:getObjType() ~= xi.objType.PC then
        return
    end

    player:removeListener(starterHnm.XP_LISTENER_ID)
    player:removeListener(starterHnm.ENGAGE_GUARD_LISTENER_ID)
    player:removeListener(starterHnm.MAGIC_GUARD_LISTENER_ID)
    player:removeListener(starterHnm.DEATH_GUARD_LISTENER_ID)

    local zoneId = player:getZoneID()
    if not starterHnm.zones[zoneId] then
        starterHnm.releaseSync(player)
        return
    end

    player:addListener('EXPERIENCE_POINTS', starterHnm.XP_LISTENER_ID, function(playerObj, mobObj, expGained)
        if expGained > 0 then
            starterHnm.addZoneExp(playerObj:getZoneID(), expGained)
        end
    end)

    player:addListener('ENGAGE', starterHnm.ENGAGE_GUARD_LISTENER_ID, function(playerObj, target)
        starterHnm.tryApplyFightSync(playerObj, target)
    end)

    player:addListener('MAGIC_START', starterHnm.MAGIC_GUARD_LISTENER_ID, function(playerObj, target)
        starterHnm.tryApplyFightSync(playerObj, target)
    end)

    player:addListener('DEATH', starterHnm.DEATH_GUARD_LISTENER_ID, function(playerObj)
        starterHnm.releaseSync(playerObj)
    end)
end

function starterHnm.onZoneInit(zone)
    for _, player in pairs(zone:getPlayers()) do
        starterHnm.syncXpListener(player)
    end
end

function starterHnm.onPlayerZoneIn(player)
    starterHnm.syncXpListener(player)
end

for _, cfg in pairs(starterHnm.zones) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', cfg.zoneScript), function(zone)
        super(zone)
        starterHnm.onZoneInit(zone)
    end)

    m:addOverride(string.format('xi.zones.%s.Zone.onZoneIn', cfg.zoneScript), function(player, prevZone)
        local cs = super(player, prevZone)
        starterHnm.onPlayerZoneIn(player)
        return cs
    end)
end

local STARTER_ZONE_IDS =
{
    xi.zone.WEST_RONFAURE,
    xi.zone.EAST_RONFAURE,
    xi.zone.NORTH_GUSTABERG,
    xi.zone.SOUTH_GUSTABERG,
    xi.zone.WEST_SARUTABARUTA,
    xi.zone.EAST_SARUTABARUTA,
}

-- Filewatcher / late load: rebind guards on whoever is already in the fields.
for _, zoneId in ipairs(STARTER_ZONE_IDS) do
    local zone = GetZone and GetZone(zoneId)
    if zone then
        for _, player in pairs(zone:getPlayers()) do
            starterHnm.syncXpListener(player)
        end

        local cfg = starterHnm.zones[zoneId]
        if cfg then
            for _, mob in pairs(zone:queryEntitiesByName('DE_' .. cfg.internalName)) do
                if mob:isSpawned() and mob:isAlive() then
                    starterHnm.attachLevelGuard(mob)
                    starterHnm.applyCombatStats(mob)
                end
            end
        end
    end
end

xi.module.registerCommand('starterhnm', {
    cmdprops =
    {
        permission = 1,
        parameters = 's',
    },
    onTrigger = function(player, arg)
        local token = arg and string.lower(arg) or ''

        if token == '' or token == 'spawn' then
            local zoneId = player:getZoneID()
            local ok, msg = starterHnm.gmSpawn(zoneId)
            player:printToPlayer(ok and string.format('[starterhnm] Spawned %s in zone %u.', msg, zoneId) or string.format('[starterhnm] Failed zone %u: %s', zoneId, msg))
            return
        end

        if token == 'here' then
            local zoneId = player:getZoneID()
            local ok, msg = starterHnm.gmSpawn(zoneId, { atPlayer = player })
            player:printToPlayer(ok and string.format('[starterhnm] Spawned %s at your position (zone %u).', msg, zoneId) or string.format('[starterhnm] Failed zone %u: %s', zoneId, msg))
            return
        end

        if token == 'all' then
            local spawned = 0
            for _, zoneId in ipairs(STARTER_ZONE_IDS) do
                local ok, msg = starterHnm.gmSpawn(zoneId)
                if ok then
                    spawned = spawned + 1
                    player:printToPlayer(string.format('[starterhnm] Spawned %s in zone %u.', msg, zoneId))
                else
                    player:printToPlayer(string.format('[starterhnm] Skipped zone %u: %s', zoneId, msg))
                end
            end

            player:printToPlayer(string.format('[starterhnm] Done. Spawned %u/%u.', spawned, #STARTER_ZONE_IDS))
            return
        end

        if token == 'status' then
            local status = starterHnm.getZoneStatus(player:getZoneID())
            if not status then
                player:printToPlayer('[starterhnm] This is not a starter HNM zone.')
                return
            end

            player:printToPlayer(string.format(
                '[starterhnm] %s (zone %u): XP %u / %u, active=%s, cooldown=%ss',
                status.name, status.zoneId, status.xp, status.threshold,
                status.active and 'yes' or 'no', status.cooldownSec
            ))
            return
        end

        local zoneId = tonumber(token)
        if zoneId then
            local ok, msg = starterHnm.gmSpawn(zoneId)
            player:printToPlayer(ok and string.format('[starterhnm] Spawned %s in zone %u.', msg, zoneId) or string.format('[starterhnm] Failed zone %u: %s', zoneId, msg))
            return
        end

        player:printToPlayer('!starterhnm [here|all|status|<zoneId>]')
        player:printToPlayer('Zones: 100 West Ronfaure, 101 East Ronfaure, 106 North Gustaberg,')
        player:printToPlayer('       107 South Gustaberg, 115 West Saruta, 116 East Saruta')
    end,
})
