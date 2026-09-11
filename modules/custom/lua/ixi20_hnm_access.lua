-----------------------------------
-- Imagine XI 2.0 HNM access: item pops stay on ???, timed HNMs
-- come back in 20 minutes, alliance lockout after a kill.
-- Pop items come from their normal sources (KSNMs, sky, etc.).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_hnm_roster')
-----------------------------------

local m = Module:new('ixi20_hnm_access')

xi = xi or {}
xi.ixi20HnmAccess = xi.ixi20HnmAccess or {}

local LOCK_PREFIX = '[ixi20Hnm]lock_'

local function setting(key, fallback)
    local map = xi.settings and xi.settings.map
    if map and map[key] ~= nil then
        return map[key]
    end

    return fallback
end

local function lockoutSeconds()
    return setting('IMAGINEXI_HNM_LOCKOUT_SECONDS', 12 * 3600)
end

local function timedRespawnSeconds()
    return setting('IMAGINEXI_HNM_TIMED_RESPAWN_SECONDS', 20 * 60)
end

local function lockVar(mobName)
    return LOCK_PREFIX .. mobName
end

local function remainingLock(player, mobName)
    local untilTime = player:getCharVar(lockVar(mobName))
    if untilTime <= 0 then
        return 0
    end

    return math.max(0, untilTime - GetSystemTime())
end

local function formatRemain(seconds)
    local hours = math.floor(seconds / 3600)
    local mins  = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return string.format('%uh %um', hours, mins)
    end

    return string.format('%um', math.max(1, mins))
end

xi.ixi20HnmAccess.remainingLock = remainingLock
xi.ixi20HnmAccess.formatRemain  = formatRemain

xi.ixi20HnmAccess.isLocked = function(player, mob)
    if not player or not player.isPC or not player:isPC() or not mob then
        return false
    end

    return remainingLock(player, mob:getName()) > 0
end

xi.ixi20HnmAccess.lockAlliance = function(player, mob)
    if not player or not player.isPC or not player:isPC() or not mob then
        return
    end

    local untilTime = GetSystemTime() + lockoutSeconds()
    local var       = lockVar(mob:getName())
    local alliance  = player:getAlliance()
    local stamped   = {}

    local function stamp(member)
        if not member or not member.isPC or not member:isPC() then
            return
        end

        local id = member:getID()
        if stamped[id] then
            return
        end

        stamped[id] = true
        member:setCharVar(var, untilTime)
        member:printToPlayer(string.format(
            '%s lockout: %s. Another group can pop the next one.',
            mob:getPacketName(),
            formatRemain(lockoutSeconds())
        ), xi.msg.channel.SYSTEM_3, '')
    end

    if alliance then
        for _, member in pairs(alliance) do
            stamp(member)
        end
    else
        stamp(player)
    end
end

local function stampFromEnmity(mob)
    local seen = {}
    xi.ixi20Hnm.forEachEnmity(mob, function(entity)
        local player = entity:isPC() and entity or (entity.getMaster and entity:getMaster())
        if player and player:isPC() and not seen[player:getID()] then
            seen[player:getID()] = true
            xi.ixi20HnmAccess.lockAlliance(player, mob)
        end
    end)
end

local function applyTimedRespawn(mob)
    if mob then
        mob:setRespawnTime(timedRespawnSeconds())
    end
end

local function refuseLockedTrade(player, mob)
    if not mob then
        return false
    end

    local remain = remainingLock(player, mob:getName())
    if remain <= 0 then
        return false
    end

    player:printToPlayer(string.format(
        'Your group is locked out of %s for %s.',
        mob:getPacketName(),
        formatRemain(remain)
    ), xi.msg.channel.SYSTEM_3, '')
    return true
end

-- Timed HNM death windows and lockout stamps.
for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
    if target.timed then
        m:addOverride(xi.ixi20Hnm.overridePath(target.zone, target.mob, 'onMobInitialize'), function(mob)
            super(mob)
            applyTimedRespawn(mob)
        end)

        m:addOverride(xi.ixi20Hnm.overridePath(target.zone, target.mob, 'onMobDespawn'), function(mob)
            super(mob)
            applyTimedRespawn(mob)
        end)
    end

    if target.itemPop or target.timed then
        m:addOverride(xi.ixi20Hnm.overridePath(target.zone, target.mob, 'onMobDeath'), function(mob, player, optParams)
            super(mob, player, optParams)
            if player then
                xi.ixi20HnmAccess.lockAlliance(player, mob)
            else
                stampFromEnmity(mob)
            end
        end)
    end
end

-- Zone scripts overwrite Cerberus / Khimaira with 12-36h on initialize.
m:addOverride('xi.zones.Mount_Zhayolm.Zone.onInitialize', function(zone)
    super(zone)
    local mob = zone:queryEntitiesByName('Cerberus')[1]
    if mob then
        applyTimedRespawn(mob)
    end
end)

m:addOverride('xi.zones.Caedarva_Mire.Zone.onInitialize', function(zone)
    super(zone)
    local mob = zone:queryEntitiesByName('Khimaira')[1]
    if mob then
        applyTimedRespawn(mob)
    end
end)

local function wrapItemPopTrade(zoneName, npcName, mobNames)
    m:addOverride(string.format('xi.zones.%s.npcs.%s.onTrade', zoneName, npcName), function(player, npc, trade)
        local zone = player.getZone and player:getZone() or (npc.getZone and npc:getZone())
        for _, mobName in ipairs(mobNames) do
            if remainingLock(player, mobName) > 0 then
                local mobs = zone and zone.queryEntitiesByName and zone:queryEntitiesByName(mobName)
                local mob  = mobs and mobs[1]
                if mob then
                    refuseLockedTrade(player, mob)
                else
                    player:printToPlayer(string.format(
                        'Your group is locked out of %s for %s.',
                        mobName:gsub('_', ' '),
                        formatRemain(remainingLock(player, mobName))
                    ), xi.msg.channel.SYSTEM_3, '')
                end

                return
            end
        end

        super(player, npc, trade)
    end)
end

wrapItemPopTrade('Dragons_Aery', 'qm_fafnir', { 'Fafnir', 'Nidhogg' })
wrapItemPopTrade('Valley_of_Sorrows', 'qm_adamantoise', { 'Adamantoise', 'Aspidochelone' })
wrapItemPopTrade('Behemoths_Dominion', 'qm_behemoth', { 'Behemoth', 'King_Behemoth' })
wrapItemPopTrade('RuAun_Gardens', 'qm1', { 'Genbu' })
wrapItemPopTrade('RuAun_Gardens', 'qm2', { 'Seiryu' })
wrapItemPopTrade('RuAun_Gardens', 'qm3', { 'Byakko' })
wrapItemPopTrade('RuAun_Gardens', 'qm4', { 'Suzaku' })
wrapItemPopTrade('The_Shrine_of_RuAvitau', 'qm2', { 'Kirin' })

-- FileWatcher / live map: hide leftover free-shop NPCs from the old module.
if GetZone and xi.zone then
    local seen = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and zoneId > 0 and not seen[zoneId] then
            seen[zoneId] = true
            local zone = GetZone(zoneId)
            if zone and zone.queryEntitiesByName then
                local leftover = zone:queryEntitiesByName('DE_HNM_Pops')
                if leftover then
                    for _, npc in pairs(leftover) do
                        if npc and npc.setStatus then
                            npc:setStatus(xi.status.DISAPPEAR)
                        end
                    end
                end
            end
        end
    end
end
