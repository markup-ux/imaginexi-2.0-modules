-----------------------------------
-- GM command !bis: grant and equip level-appropriate BiS for the current job.
-- Command-only module (no overrides). Uses ixi20_bis_gear_progression lists.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_bis_gear_progression')
-----------------------------------

local SLOT_ORDER =
{
    xi.slot.HEAD,
    xi.slot.BODY,
    xi.slot.HANDS,
    xi.slot.LEGS,
    xi.slot.FEET,
    xi.slot.NECK,
    xi.slot.WAIST,
    xi.slot.EAR1,
    xi.slot.EAR2,
    xi.slot.RING1,
    xi.slot.RING2,
    xi.slot.BACK,
    xi.slot.RANGED,
    xi.slot.AMMO,
    xi.slot.SUB,
    xi.slot.MAIN,
}

local SLOT_SOURCE =
{
    [xi.slot.EAR2]  = xi.slot.EAR1,
    [xi.slot.RING2] = xi.slot.RING1,
}

local SLOT_NAME =
{
    [xi.slot.MAIN]   = 'Main',
    [xi.slot.SUB]    = 'Sub',
    [xi.slot.RANGED] = 'Ranged',
    [xi.slot.AMMO]   = 'Ammo',
    [xi.slot.HEAD]   = 'Head',
    [xi.slot.BODY]   = 'Body',
    [xi.slot.HANDS]  = 'Hands',
    [xi.slot.LEGS]   = 'Legs',
    [xi.slot.FEET]   = 'Feet',
    [xi.slot.NECK]   = 'Neck',
    [xi.slot.WAIST]  = 'Waist',
    [xi.slot.EAR1]   = 'Ear1',
    [xi.slot.EAR2]   = 'Ear2',
    [xi.slot.RING1]  = 'Ring1',
    [xi.slot.RING2]  = 'Ring2',
    [xi.slot.BACK]   = 'Back',
}

local function jobAbbrev(job)
    local names = xi.jobName and xi.jobName[job]
    return names and names[1] or tostring(job)
end

local function itemLabel(itemId)
    local item = GetReadOnlyItem(itemId)
    local raw  = item and item.getName and item:getName() or nil
    if not raw or raw == '' then
        return string.format('#%u', itemId)
    end

    return (raw:gsub('_', ' '):gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest
    end))
end

local function isPlayer(entity)
    return entity ~= nil and entity.isPC ~= nil and entity:isPC()
end

local function canWear(player, itemId)
    if not itemId or itemId <= 0 then
        return false
    end

    if GetReadOnlyItem(itemId) == nil then
        return false
    end

    return player:canEquipItem(itemId, true) == true
end

---@return { slot: integer, itemId: integer }[]
local function buildSet(player)
    local job   = player:getMainJob()
    local level = player:getMainLvl()
    local used  = {}
    local set   = {}

    for _, slot in ipairs(SLOT_ORDER) do
        local source     = SLOT_SOURCE[slot] or slot
        local candidates = xi.bis_gear_progression.getCandidatesAcrossTiers(job, level, source)
        local pick       = nil

        local dualSlot = slot == xi.slot.EAR2 or slot == xi.slot.RING2
        for _, itemId in ipairs(candidates) do
            if canWear(player, itemId) and not (dualSlot and used[itemId]) then
                pick = itemId
                break
            end
        end

        if not pick and (slot == xi.slot.EAR2 or slot == xi.slot.RING2) then
            for _, itemId in ipairs(candidates) do
                if canWear(player, itemId) then
                    pick = itemId
                    break
                end
            end
        end

        if pick then
            table.insert(set, { slot = slot, itemId = pick })
            used[pick] = true
        end
    end

    return set
end

local function printUsage(player)
    player:printToPlayer('!bis [player]   Grant and equip BiS for the current job and level.', xi.msg.channel.SYSTEM_3)
    player:printToPlayer('!bis list [player]   Preview the set without giving items.', xi.msg.channel.SYSTEM_3)
end

local function resolveTarget(player, name)
    if name == nil or name == '' then
        return player
    end

    local targ = GetPlayerByName(name)
    if targ == nil then
        player:printToPlayer(string.format('[bis] Player "%s" not found.', name), xi.msg.channel.SYSTEM_3)
        return nil
    end

    return targ
end

local function printSet(player, targ, set, granted)
    local job   = targ:getMainJob()
    local level = targ:getMainLvl()
    local tier  = xi.bis_gear_progression.getTierMinLevel(job, level)
    local verb  = granted and 'Granted' or 'Preview'

    player:printToPlayer(string.format(
        '[bis] %s lv%u %s set (tier %u, %u pieces)%s:',
        verb,
        level,
        jobAbbrev(job),
        tier,
        #set,
        targ:getID() ~= player:getID() and (' for ' .. targ:getName()) or ''
    ), xi.msg.channel.SYSTEM_3)

    for _, entry in ipairs(set) do
        player:printToPlayer(
            string.format('  %-6s  %s', SLOT_NAME[entry.slot] or tostring(entry.slot), itemLabel(entry.itemId)),
            xi.msg.channel.SYSTEM_3
        )
    end
end

local function grantSet(player, targ, set)
    if #set == 0 then
        player:printToPlayer('[bis] No wearable BiS pieces for that job and level.', xi.msg.channel.SYSTEM_3)
        return
    end

    if targ:getFreeSlotsCount() < #set then
        player:printToPlayer(string.format(
            '[bis] Need %u free inventory slots (%s has %u).',
            #set,
            targ:getName(),
            targ:getFreeSlotsCount()
        ), xi.msg.channel.SYSTEM_3)
        return
    end

    local equippedId = {}
    for _, entry in ipairs(set) do
        if not targ:addItem({ id = entry.itemId, silent = true }) then
            player:printToPlayer(string.format('[bis] Failed to add %s.', itemLabel(entry.itemId)), xi.msg.channel.SYSTEM_3)
            return
        end
    end

    for _, entry in ipairs(set) do
        if not equippedId[entry.itemId] then
            targ:equipItem(entry.itemId, xi.inv.INVENTORY, entry.slot)
            equippedId[entry.itemId] = true
        end
    end

    printSet(player, targ, set, true)

    if targ:getID() ~= player:getID() then
        targ:printToPlayer(
            string.format('[bis] %s granted you a lv%u %s BiS set.', player:getName(), targ:getMainLvl(), jobAbbrev(targ:getMainJob())),
            xi.msg.channel.SYSTEM_3
        )
    end
end

local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ss',
}

commandObj.onTrigger = function(player, arg1, arg2)
    if not isPlayer(player) then
        return
    end

    local token1 = arg1 and string.lower(arg1) or ''
    local preview = false
    local targetName = nil

    if token1 == 'help' or token1 == '?' then
        printUsage(player)
        return
    end

    if token1 == 'list' or token1 == 'preview' then
        preview = true
        targetName = arg2
    else
        targetName = arg1
    end

    local targ = resolveTarget(player, targetName)
    if not targ then
        return
    end

    local job = targ:getMainJob()
    if not xi.bis_gear_progression.byJob[job] then
        player:printToPlayer(string.format('[bis] No BiS lists for job %s.', jobAbbrev(job)), xi.msg.channel.SYSTEM_3)
        return
    end

    local set = buildSet(targ)
    if preview then
        if #set == 0 then
            player:printToPlayer('[bis] No wearable BiS pieces for that job and level.', xi.msg.channel.SYSTEM_3)
            return
        end

        printSet(player, targ, set, false)
        return
    end

    grantSet(player, targ, set)
end

xi.module.registerCommand('bis', commandObj)

-- FileWatcher re-runs module files but discards commandRegistry, so also
-- publish here so !bis is live without a map restart.
xi.commands = xi.commands or {}
xi.commands.bis = commandObj
