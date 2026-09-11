-----------------------------------
-- Imagine XI 2.0: GM Home Sky test bench.
-- !skytest in zone 210, or click Sky Tester (south of spawn).
-- Pops garden-god copies and a Kirin that summons them as adds.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------

local m = Module:new('ixi20_sky_gmhome')

local GROUP_ID      = 5
local GROUP_ZONE_ID = 154 -- Dragon's Aery template; look / stats overridden
local NPC_LOOK      = 803
local NPC_X, NPC_Y, NPC_Z, NPC_ROT = 8.0, 0.0, -10.0, 0

local LOOK =
{
    Genbu  = 407,
    Seiryu = 399,
    Byakko = 309,
    Suzaku = 337,
    Kirin  = 403,
}

local GODS = { 'Genbu', 'Seiryu', 'Byakko', 'Suzaku' }

local function say(player, text)
    player:printToPlayer(text, xi.msg.channel.SYSTEM_3, '')
end

local function inFront(player, dist)
    local rot = player:getRotPos()
    local rad = rot * math.pi / 128
    return
        player:getXPos() - math.sin(rad) * dist,
        player:getYPos(),
        player:getZPos() - math.cos(rad) * dist,
        rot
end

local function gmHome(player)
    return player and player.getZoneID and player:getZoneID() == xi.zone.GM_HOME
end

local function findByLookup(zone, lookup)
    if not zone or not zone.queryEntitiesByName then
        return {}
    end

    local found = zone:queryEntitiesByName(lookup)
    local list  = {}
    if found then
        for _, entity in pairs(found) do
            if entity then
                list[#list + 1] = entity
            end
        end
    end

    return list
end

local function despawnList(list)
    for _, entity in ipairs(list) do
        if entity.setHP then
            entity:setHP(0)
        end

        if entity.setStatus then
            entity:setStatus(xi.status.DISAPPEAR)
        end
    end
end

local function clearSkyMobs(zone)
    local count = 0
    for _, name in ipairs({ 'Kirin', 'Genbu', 'Seiryu', 'Byakko', 'Suzaku' }) do
        local list = findByLookup(zone, 'DE_' .. name)
        count = count + #list
        despawnList(list)
    end

    return count
end

local function spawnGod(zone, name, x, y, z, rot, opts)
    opts = opts or {}
    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        name                 = name,
        packetName           = name,
        look                 = LOOK[name],
        groupId              = GROUP_ID,
        groupZoneId          = GROUP_ZONE_ID,
        minLevel             = 90,
        maxLevel             = 90,
        x                    = x,
        y                    = y,
        z                    = z,
        rotation             = rot,
        releaseIdOnDisappear = true,
        onMobSpawn           = function(mobArg)
            mobArg:setLocalVar('[sky]testGod', 1)
            if xi.ixi20Sky and xi.ixi20Sky.onAddSpawn then
                xi.ixi20Sky.onAddSpawn(mobArg)
            end

            if opts.weak and mobArg.getMaxHP then
                mobArg:setHP(math.max(1, math.floor(mobArg:getMaxHP() * 0.02)))
            end
        end,
        onMobDeath           = function(mobArg, player)
            if xi.ixi20Sky and xi.ixi20Sky.onAddDeath then
                xi.ixi20Sky.onAddDeath(mobArg, player)
            end
        end,
    })

    if not mob then
        return nil
    end

    mob:setSpawn(x, y, z, rot)
    mob:spawn()
    mob:setLocalVar('[sky]testGod', 1)
    if xi.ixi20Sky and xi.ixi20Sky.onAddSpawn then
        xi.ixi20Sky.onAddSpawn(mob)
    end

    if opts.weak and mob.getMaxHP then
        mob:setHP(math.max(1, math.floor(mob:getMaxHP() * 0.02)))
    end

    return mob
end

local function tryKirinAdd(kirin, force)
    if not kirin or not kirin:isAlive() then
        return
    end

    if not force and not kirin:isEngaged() then
        return
    end

    local numAdds = kirin:getLocalVar('numAdds')
    if numAdds >= 4 or GetSystemTime() < kirin:getLocalVar('godSpawnTime') then
        return
    end

    local available = {}
    for i, name in ipairs(GODS) do
        if kirin:getLocalVar('add' .. i) == 0 then
            available[#available + 1] = { index = i, name = name }
        end
    end

    if #available == 0 then
        return
    end

    local pick   = available[math.random(1, #available)]
    local zone   = kirin:getZone()
    local rot    = kirin:getRotPos()
    local rad    = rot * math.pi / 128
    local x      = kirin:getXPos() - math.sin(rad) * (4 + pick.index)
    local y      = kirin:getYPos()
    local z      = kirin:getZPos() - math.cos(rad) * (4 + pick.index)
    local add    = spawnGod(zone, pick.name, x, y, z, rot, {})
    if not add then
        return
    end

    kirin:setLocalVar('add' .. pick.index, 1)
    kirin:setLocalVar('numAdds', numAdds + 1)
    if add.updateEnmity and kirin.getTarget then
        local target = kirin:getTarget()
        if target then
            add:updateEnmity(target)
        end
    end
end

local function spawnKirin(zone, x, y, z, rot)
    local kirin = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        name                 = 'Kirin',
        packetName           = 'Kirin',
        look                 = LOOK.Kirin,
        groupId              = GROUP_ID,
        groupZoneId          = GROUP_ZONE_ID,
        minLevel             = 92,
        maxLevel             = 92,
        x                    = x,
        y                    = y,
        z                    = z,
        rotation             = rot,
        releaseIdOnDisappear = true,
        onMobSpawn           = function(mobArg)
            mobArg:setLocalVar('[sky]testGod', 1)
            if xi.ixi20Sky and xi.ixi20Sky.onKirinSpawn then
                xi.ixi20Sky.onKirinSpawn(mobArg)
            end

            -- Faster than the live 60s so GM Home is usable.
            mobArg:setLocalVar('godSpawnTime', GetSystemTime() + 10)
        end,
        onMobFight           = function(mobArg)
            tryKirinAdd(mobArg)
            if xi.ixi20Sky and xi.ixi20Sky.onKirinFight then
                xi.ixi20Sky.onKirinFight(mobArg)
            end
        end,
        onMobDeath           = function(mobArg)
            local home = mobArg.getZone and mobArg:getZone()
            if home then
                for _, name in ipairs(GODS) do
                    despawnList(findByLookup(home, 'DE_' .. name))
                end
            end
        end,
    })

    if not kirin then
        return nil
    end

    kirin:setSpawn(x, y, z, rot)
    kirin:spawn()
    kirin:setLocalVar('[sky]testGod', 1)
    if xi.ixi20Sky and xi.ixi20Sky.onKirinSpawn then
        xi.ixi20Sky.onKirinSpawn(kirin)
    end

    kirin:setLocalVar('godSpawnTime', GetSystemTime() + 10)
    return kirin
end

local function help(player)
    say(player, '!skytest genbu|seiryu|byakko|suzaku  — spawn that garden god')
    say(player, '!skytest loot [god]  — same, at 2% HP for drop checks')
    say(player, '!skytest kirin       — Kirin; first add in 10s, then every 90s')
    say(player, '!skytest add         — force Kirin to pop the next unused god now')
    say(player, '!skytest clear       — despawn test Kirin / gods')
    say(player, 'Or click Sky Tester south of GM Home spawn.')
end

local function runSkyTest(player, arg)
    if not gmHome(player) then
        say(player, '[skytest] Go to GM Home first (!gmhome), then run this.')
        return
    end

    local zone  = player:getZone()
    local token = arg and string.lower(arg:match('^%s*(.-)%s*$') or '') or ''
    local weak  = false

    if token == '' or token == 'help' or token == '?' then
        help(player)
        return
    end

    if token == 'clear' then
        say(player, string.format('[skytest] Despawned %u test mob(s).', clearSkyMobs(zone)))
        return
    end

    if token:sub(1, 4) == 'loot' then
        weak  = true
        token = token:match('^loot%s+(%S+)') or 'genbu'
    end

    if token == 'kirin' then
        local x, y, z, rot = inFront(player, 8)
        local kirin = spawnKirin(zone, x, y, z, rot)
        if kirin then
            say(player, '[skytest] Kirin up. Engage it — first god in 10s. !skytest add to skip the wait.')
        else
            say(player, '[skytest] Failed to spawn Kirin.')
        end

        return
    end

    if token == 'add' then
        local kirins = findByLookup(zone, 'DE_Kirin')
        local kirin  = kirins[1]
        if not kirin or not kirin:isAlive() then
            say(player, '[skytest] No live test Kirin. Use !skytest kirin first.')
            return
        end

        kirin:setLocalVar('godSpawnTime', 0)
        if not kirin:isEngaged() then
            kirin:updateEnmity(player)
        end

        tryKirinAdd(kirin, true)
        if xi.ixi20Sky and xi.ixi20Sky.onKirinFight then
            xi.ixi20Sky.onKirinFight(kirin)
        end

        say(player, string.format('[skytest] Adds out: %u/4.', kirin:getLocalVar('numAdds')))
        return
    end

    local name = token:gsub('^%l', string.upper)
    if name == 'Suzaku' or name == 'Seiryu' or name == 'Byakko' or name == 'Genbu' then
        local x, y, z, rot = inFront(player, 6)
        local mob = spawnGod(zone, name, x, y, z, rot, { weak = weak })
        if mob then
            say(player, string.format('[skytest] %s spawned%s. Kill it to check the garden drop table.', name, weak and ' at 2% HP' or ''))
        else
            say(player, string.format('[skytest] Failed to spawn %s.', name))
        end

        return
    end

    help(player)
end

local function spawnTester(zone)
    if #findByLookup(zone, 'DE_SkyTester') > 0 then
        return
    end

    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'SkyTester',
        packetName = 'Sky Tester',
        look       = NPC_LOOK,
        x          = NPC_X,
        y          = NPC_Y,
        z          = NPC_Z,
        rotation   = NPC_ROT,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer(
                'Sky bench. Pick a pop — Kirin summons the garden gods with their real tables.',
                xi.msg.channel.NS_SAY,
                npc:getPacketName()
            )
            player:timer(50, function(p)
                p:customMenu({
                    title = 'Sky Tester',
                    options =
                    {
                        { 'Genbu', function(p2)
                            runSkyTest(p2, 'genbu')
                        end },
                        { 'Seiryu', function(p2)
                            runSkyTest(p2, 'seiryu')
                        end },
                        { 'Byakko', function(p2)
                            runSkyTest(p2, 'byakko')
                        end },
                        { 'Suzaku', function(p2)
                            runSkyTest(p2, 'suzaku')
                        end },
                        { 'Kirin (adds in 10s)', function(p2)
                            runSkyTest(p2, 'kirin')
                        end },
                        { 'Loot check (Genbu 2% HP)', function(p2)
                            runSkyTest(p2, 'loot genbu')
                        end },
                        { 'Clear test mobs', function(p2)
                            runSkyTest(p2, 'clear')
                        end },
                    },
                })
            end)
        end,
    })
end

local commandObj =
{
    cmdprops =
    {
        permission = 1,
        parameters = 's',
    },
    onTrigger = function(player, arg)
        runSkyTest(player, arg)
    end,
}

xi.module.registerCommand('skytest', commandObj)
xi.commands = xi.commands or {}
xi.commands.skytest = commandObj

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)
    spawnTester(zone)
end)

m:addOverride('xi.zones.GM_Home.Zone.onZoneIn', function(player, prevZone)
    local cs   = super(player, prevZone)
    local zone = player.getZone and player:getZone()
    if zone then
        spawnTester(zone)
    end

    return cs
end)

if GetZone and xi.zone and xi.zone.GM_HOME then
    local zone = GetZone(xi.zone.GM_HOME)
    if zone then
        spawnTester(zone)
    end
end
