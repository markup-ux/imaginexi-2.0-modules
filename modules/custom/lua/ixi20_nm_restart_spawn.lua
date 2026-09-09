-----------------------------------
-- Imagine XI 2.0: pop world HNMs / timed NMs when a map process starts.
-- Stock LSB leaves setRespawnTime windows running after a restart, so
-- Jormungand / Cerberus / Serket / etc. stay down for hours or days.
-- Lottery NMs replace their placeholders so they stand after a restart.
-- Item-pop HNMs (land kings, sky, Kirin) stay on ???.
-- Dynamis / instances / Abyssea / GM Home are skipped.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_hnm_roster')
-----------------------------------

local m = Module:new('ixi20_nm_restart_spawn')

-- zone:name pairs that share a camp or are pet/adds of another HNM
local SKIP =
{
    ['Dragons_Aery:Nidhogg']                 = true,
    ['Valley_of_Sorrows:Aspidochelone']      = true,
    ['Behemoths_Dominion:King_Behemoth']     = true,
    ['Maze_of_Shakhrami:Leech_King']         = true,
    ['Yuhtunga_Jungle:Voluptuous_Vilma']     = true,
    ['RuAun_Gardens:Kirins_Avatar']          = true,
    ['The_Shrine_of_RuAvitau:Kirins_Avatar'] = true,
    ['The_Shrine_of_RuAvitau:Genbu']         = true,
    ['The_Shrine_of_RuAvitau:Seiryu']        = true,
    ['The_Shrine_of_RuAvitau:Byakko']        = true,
    ['The_Shrine_of_RuAvitau:Suzaku']        = true,
    ['RuAun_Gardens:Kirin']                  = true,
}

local itemPopKeys = {}
local timedKeys   = {}
for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
    local key = xi.ixi20Hnm.targetKey(target.zone, target.mob)
    if target.itemPop then
        itemPopKeys[key] = true
    end

    if target.timed then
        timedKeys[key] = true
    end
end

local SKIP_ZONE =
{
    GM_Home = true,
    unknown = true,
    none    = true,
}

local function skipZone(zone)
    local name = zone:getName()
    if SKIP_ZONE[name] then
        return true
    end

    if name:find('^Abyssea', 1, false) or name:find('^Dynamis', 1, false) then
        return true
    end

    local mask = zone:getTypeMask()
    if bit.band(mask, xi.zoneType.DYNAMIS) ~= 0 then
        return true
    end

    if bit.band(mask, xi.zoneType.INSTANCED) ~= 0 then
        return true
    end

    return false
end

local function slotSize(mob)
    if not mob.getSpawnSlotMobs then
        return 0
    end

    local count = 0
    for _ in pairs(mob:getSpawnSlotMobs()) do
        count = count + 1
    end

    return count
end

local function mobScript(zone, mob)
    local zoneTable = xi.zones and xi.zones[zone:getName()]
    return zoneTable and zoneTable.mobs and zoneTable.mobs[mob:getName()]
end

local function isLotteryNM(zone, mob)
    if slotSize(mob) > 1 then
        return true
    end

    local script = mobScript(zone, mob)
    return script ~= nil and script.phList ~= nil
end

local function despawnPlaceholders(zone, mob)
    local script = mobScript(zone, mob)
    if script and script.phList then
        for phId, nmId in pairs(script.phList) do
            local match = false
            if type(nmId) == 'number' then
                match = nmId == mob:getID()
            elseif type(nmId) == 'table' then
                for _, id in pairs(nmId) do
                    if id == mob:getID() then
                        match = true
                        break
                    end
                end
            end

            if match and type(phId) == 'number' and phId > 0 then
                local ph = GetMobByID(phId)
                if ph and ph.isSpawned and ph:isSpawned() then
                    DespawnMob(phId)
                end
            end
        end
    end

    if not mob.getSpawnSlotMobs then
        return
    end

    for _, otherId in pairs(mob:getSpawnSlotMobs()) do
        if type(otherId) == 'number' and otherId > 0 and otherId ~= mob:getID() then
            local other = GetMobByID(otherId)
            if other and other.isSpawned and other:isSpawned() then
                DespawnMob(otherId)
            end
        end
    end
end

local function shouldSpawn(zone, mob, opts)
    if not mob or not mob.isNM or not mob:isNM() then
        return false
    end

    if mob.isSpawned and mob:isSpawned() then
        return false
    end

    if mob.isPet and mob:isPet() then
        return false
    end

    if mob.getMaster and mob:getMaster() then
        return false
    end

    if mob:isMobType(xi.mobType.BATTLEFIELD) then
        return false
    end

    local name = mob:getName()
    if type(name) ~= 'string' or name == '' or name:find('^DE_', 1, false) then
        return false
    end

    local key = zone:getName() .. ':' .. name
    if SKIP[key] then
        return false
    end

    -- ??? HNMs stay down on a normal restart. A live populate can force them.
    if itemPopKeys[key] then
        return opts and opts.includeItemPops == true
    end

    if timedKeys[key] or isLotteryNM(zone, mob) then
        return true
    end

    -- Timed NMs registered a window during initialize. Pop that window now.
    return mob.getRespawnTime and mob:getRespawnTime() > 0
end

-- Mass SpawnMob at map start leaves LastActionTime unset, so every NM
-- RoamAround on the first eligible tick and the navmesh work trips the 2s
-- inactivity watchdog. Hold movement, then release one NM per logic tick.
local ROAM_HOLD_VAR = '[ixi20Nm]roamHold'
local ROAM_HOLD_LISTENER = 'IXI20_NM_ROAM_STAGGER'
local roamHoldIndex = 0

local function randInt(minVal, maxVal)
    if math.randomInt then
        return math.randomInt(minVal, maxVal)
    end

    return math.random(minVal, maxVal)
end

local function releaseRoamHold(mob)
    if not mob or not mob.getLocalVar or mob:getLocalVar(ROAM_HOLD_VAR) ~= 1 then
        return
    end

    mob:setLocalVar(ROAM_HOLD_VAR, 0)
    mob:setMobMod(xi.mobMod.NO_MOVE, 0)
    if mob.removeListener then
        mob:removeListener(ROAM_HOLD_LISTENER)
    end
end

local function staggerRoam(mob)
    if not mob or not mob.setMobMod then
        return
    end

    -- Stationary NMs keep their authored NO_MOVE.
    if mob:getMobMod(xi.mobMod.NO_MOVE) ~= 0 then
        return
    end

    roamHoldIndex = roamHoldIndex + 1
    -- 400ms is one logic tick; jitter keeps two timers from landing together.
    local delayMs = 8000 + (roamHoldIndex * 400) + randInt(0, 200)

    mob:setLocalVar(ROAM_HOLD_VAR, 1)
    mob:setMobMod(xi.mobMod.NO_MOVE, 1)
    mob:addListener('ENGAGE', ROAM_HOLD_LISTENER, function(owner)
        releaseRoamHold(owner)
    end)
    mob:timer(delayMs, releaseRoamHold)
end

local function spawnMobNow(zone, mob)
    if xi.mob and xi.mob.updateNMSpawnPoint then
        xi.mob.updateNMSpawnPoint(mob)
    end

    -- Spawn the NM first so PH onDespawn lottery sees it already up.
    SpawnMob(mob:getID())
    despawnPlaceholders(zone, mob)
    staggerRoam(mob)
end

local function spawnZone(zone, opts)
    if not zone or skipZone(zone) then
        return 0
    end

    local count = 0
    for _, mob in pairs(zone:getMobs()) do
        if shouldSpawn(zone, mob, opts) then
            spawnMobNow(zone, mob)
            count = count + 1
        end
    end

    return count
end

local function spawnAllLoaded(opts)
    roamHoldIndex = 0
    local total = 0
    local seen  = {}

    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and zoneId > 0 and not seen[zoneId] then
            seen[zoneId] = true
            local zone = GetZone(zoneId)
            if zone then
                total = total + spawnZone(zone, opts)
            end
        end
    end

    local label = (opts and opts.label) or (opts and opts.includeItemPops and 'live populate' or 'map start')
    print(string.format('Imagine XI 2.0: spawned %d HNM/NMs on %s', total, label))
    return total
end

-- Shared by !spawnnms. Restart does not include item-pop HNMs.
xi.ixi20NmSpawn =
{
    spawnAll  = spawnAllLoaded,
    spawnZone = spawnZone,
}

m:addOverride('xi.server.onServerStart', function()
    super()
    spawnAllLoaded()
end)

-- Zone reload / FileWatcher of a Zone.lua: pop that zone again.
local wrappedZones = {}
for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
    if not wrappedZones[target.zone] then
        wrappedZones[target.zone] = true
        m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', target.zone), function(zone)
            super(zone)
            spawnZone(zone)
        end)
    end
end
