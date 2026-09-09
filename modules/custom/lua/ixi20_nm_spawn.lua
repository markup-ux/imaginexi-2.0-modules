-----------------------------------
-- Imagine XI 2.0: GM command to populate world HNMs / NMs.
-- !spawnnms       — every loaded zone (includes ??? HNMs)
-- !spawnnms zone  — current zone only
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local function report(player, text)
    print(text)
    if player then
        player:printToPlayer(text, xi.msg.channel.SYSTEM_3)
    end
end

local function helper()
    return xi.ixi20NmSpawn
end

local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

commandObj.onTrigger = function(player, arg)
    local spawn = helper()
    if not spawn or type(spawn.spawnAll) ~= 'function' then
        report(player, '[spawnnms] Spawn helper is not loaded (ixi20_nm_restart_spawn).')
        return
    end

    local token = arg and string.lower(arg) or ''
    if token == 'help' or token == '?' then
        player:printToPlayer('!spawnnms       spawn all HNM/NMs in loaded zones', xi.msg.channel.SYSTEM_3)
        player:printToPlayer('!spawnnms zone  spawn HNM/NMs in your current zone', xi.msg.channel.SYSTEM_3)
        return
    end

    local opts = { includeItemPops = true, label = 'GM !spawnnms' }

    if token == 'zone' or token == 'here' then
        local zone = player:getZone()
        if not zone then
            report(player, '[spawnnms] You are not in a zone.')
            return
        end

        local count = spawn.spawnZone(zone, opts)
        report(player, string.format('[spawnnms] Spawned %d HNM/NMs in %s.', count, zone:getName()))
        return
    end

    if token ~= '' then
        player:printToPlayer('!spawnnms [zone]', xi.msg.channel.SYSTEM_3)
        return
    end

    local count = spawn.spawnAll(opts)
    report(player, string.format('[spawnnms] Spawned %d HNM/NMs.', count))
end

xi.module.registerCommand('spawnnms', commandObj)

-- FileWatcher discards commandRegistry; keep !spawnnms live without a restart.
xi.commands = xi.commands or {}
xi.commands.spawnnms = commandObj
