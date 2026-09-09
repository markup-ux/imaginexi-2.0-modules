-----------------------------------
-- Imagine XI 2.0: GM Home (zone 210) test dummy.
-- 1.0 populated this zone with HNM / summon test mobs.
-- This module spawns a melee dummy for wyvern idle tests:
-- send the wyvern in, let it take hits to 1 HP, confirm sit / heal-up.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------

local m = Module:new('ixi20_gm_home_test_mobs')

-- Fafnir's Dragon's Aery group (same template 1.0 used here). Look is overridden.
local DUMMY_GROUP_ID      = 5
local DUMMY_GROUP_ZONE_ID = 154 -- Dragon's Aery
local DUMMY_LEVEL         = 50
local DUMMY_LOOK          = 268 -- Forest Hare / rabbit
local RESPAWN_SECONDS     = 8
local DUMMY_NAME          = 'WyvernDummy'
local DUMMY_LOOKUP        = 'DE_WyvernDummy'
local LISTENER_ID         = 'IXI20_DUMMY_HIT_PET'
local SPAWN_X             = 0.0
local SPAWN_Y             = 0.0
local SPAWN_Z             = -5.0
local SPAWN_ROT           = 0

-- Pet damage puts enmity on the master. Force the dummy to swing at the wyvern.
local function preferPetTarget(mob)
    if not mob or not mob.isAlive or not mob:isAlive() then
        return
    end

    local target = mob.getTarget and mob:getTarget()
    if not target then
        return
    end

    local pet = nil
    if target.hasPet and target:hasPet() then
        pet = target:getPet()
    elseif target.getMaster then
        local master = target:getMaster()
        if master and master.hasPet and master:hasPet() then
            pet = master:getPet()
        end
    end

    if not pet or not pet.isAlive or not pet:isAlive() then
        return
    end

    if target.getID and pet.getID and target:getID() == pet:getID() then
        return
    end

    mob:addEnmity(pet, 1, 50000)
    mob:updateEnmity(pet)
end

local function applyDummy(mob)
    if not mob then
        return
    end

    mob:setDropID(0)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)
    mob:setMobMod(xi.mobMod.NO_AGGRO, 1)
    mob:setMobMod(xi.mobMod.NO_LINK, 1)
    mob:setMobMod(xi.mobMod.NO_MOVE, 0)
    mob:setMobMod(xi.mobMod.ALWAYS_AGGRO, 0)
    mob:setMobMod(xi.mobMod.SPAWN_LEASH, 25)
    mob:setMobMod(xi.mobMod.ROAM_DISTANCE, 0)
    mob:setMobMod(xi.mobMod.SIGHT_RANGE, 0)
    mob:setMobMod(xi.mobMod.SOUND_RANGE, 0)
    mob:setMobMod(xi.mobMod.MAGIC_RANGE, 0)
    mob:setMobMod(xi.mobMod.SPECIAL_SKILL, 0)
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 220)

    -- Fafnir pool is NO_TURN; a dummy that never faces its target looks idle.
    mob:setBehavior(xi.behavior.NONE)
    mob:setAggressive(false)
    mob:setTrueDetection(false)

    mob:setMagicCastingEnabled(false)
    mob:setMobAbilityEnabled(false)
    mob:setAutoAttackEnabled(true)
    mob:setDelay(160)
    mob:setDamage(45, xi.slot.MAIN)

    mob:setMod(xi.mod.ATT, 90)
    mob:setMod(xi.mod.ACC, 400)
    mob:setMod(xi.mod.DEF, 40)
    mob:setMod(xi.mod.EVA, 20)
    if mob:getMaxHP() < 40000 then
        mob:addMod(xi.mod.HP, 45000)
        mob:updateHealth()
        mob:setHP(mob:getMaxHP())
    end

    mob:removeListener(LISTENER_ID)
    mob:addListener('COMBAT_TICK', LISTENER_ID, function(dummy)
        preferPetTarget(dummy)
    end)
end

local function spawnDummy(zone)
    local dummy = zone:insertDynamicEntity({
        objtype     = xi.objType.MOB,
        name        = DUMMY_NAME,
        packetName  = 'Wyvern Dummy',
        look        = DUMMY_LOOK,
        groupId     = DUMMY_GROUP_ID,
        groupZoneId = DUMMY_GROUP_ZONE_ID,
        minLevel    = DUMMY_LEVEL,
        maxLevel    = DUMMY_LEVEL,
        x           = SPAWN_X,
        y           = SPAWN_Y,
        z           = SPAWN_Z,
        rotation    = SPAWN_ROT,
        respawn     = RESPAWN_SECONDS,
        releaseIdOnDisappear = false,
        onMobSpawn = function(mob)
            applyDummy(mob)
        end,
        onMobEngage = function(mob, target)
            preferPetTarget(mob)
        end,
    })

    if dummy then
        dummy:setSpawn(SPAWN_X, SPAWN_Y, SPAWN_Z, SPAWN_ROT)
        dummy:spawn()
        applyDummy(dummy)
    end

    return dummy
end

local function findDummy(zone)
    if not zone or not zone.queryEntitiesByName then
        return nil
    end

    local found = zone:queryEntitiesByName(DUMMY_LOOKUP)
    if found then
        for _, entity in pairs(found) do
            if entity then
                return entity
            end
        end
    end

    return nil
end

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)
    spawnDummy(zone)
end)

-- FileWatcher cannot re-run zone init. Re-apply combat settings when a GM zones in
-- so an already-spawned dummy starts swinging without a map restart.
m:addOverride('xi.zones.GM_Home.Zone.onZoneIn', function(player, prevZone)
    local cs   = super(player, prevZone)
    local zone = player.getZone and player:getZone()
    local dummy = findDummy(zone)
    if dummy then
        applyDummy(dummy)
        if dummy.isAlive and not dummy:isAlive() and dummy.spawn then
            dummy:spawn()
        end
    end

    return cs
end)

return m
