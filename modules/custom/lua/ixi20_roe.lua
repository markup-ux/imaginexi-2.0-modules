-----------------------------------
-- Imagine XI 2.0: all implemented RoE records count. No 30-slot cap
-- (C++). First Step Forward completes on login. Progress spam stays
-- off; a completion line names the objective. Pair with ixi20_roe.cpp.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/roe')
require('scripts/globals/npc_util')
-----------------------------------

local m = Module:new('ixi20_roe')

local recordNames = {}

local function loadRecordNames()
    local file = io.open('scripts/globals/roe_records.lua', 'r')
    if not file then
        return
    end

    local pending
    for line in file:lines() do
        local id = line:match('^%s*%[(%d+)%]%s*=')
        if id then
            pending = tonumber(id)
        elseif pending then
            local name = line:match('^%s*{%s*%-%-%s*(.+)%s*$')
            if name then
                name = name:gsub('%s+%+$', ''):gsub('%s+$', '')
                recordNames[pending] = name
                pending = nil
            elseif line:find('%S') then
                pending = nil
            end
        end
    end

    file:close()
end

loadRecordNames()

local function recordLabel(record)
    return recordNames[record] or ('objective #' .. tostring(record))
end

local function announceComplete(player, record, rewards)
    local exp = 0
    if rewards and type(rewards.exp) == 'number' then
        exp = rewards.exp * (xi.settings.main.ROE_EXP_RATE or 1)
    end

    local text = 'RoE complete: ' .. recordLabel(record)
    if exp > 0 then
        text = string.format('%s (+%d XP)', text, exp)
    end

    player:printToPlayer(text, xi.msg.channel.SYSTEM_3)
end

local function isRepeatItemRewardException(items)
    local itemExceptionsMap =
    {
        [xi.item.SILT_POUCH] = true,
        [xi.item.BEAD_POUCH] = true,
    }

    if type(items) == 'table' then
        for _, v in pairs(items) do
            if type(v) == 'number' and itemExceptionsMap[v] == nil then
                return false
            end
        end
    elseif type(items) == 'number' then
        return itemExceptionsMap[items] ~= nil
    end

    return true
end

local function completeRecordQuiet(player, record)
    local recordEntry   = xi.roe.records[record]
    local recordFlags   = recordEntry.flags or {}
    local rewards       = recordEntry.reward or {}
    local canRewardItem = rewards['item'] and (not player:getEminenceCompleted(record) or isRepeatItemRewardException(rewards['item']))

    if canRewardItem then
        if not npcUtil.giveItem(player, rewards['item'], { silent = true }) then
            return false
        end
    end

    announceComplete(player, record, rewards)

    if rewards['sparks'] ~= nil and type(rewards['sparks']) == 'number' then
        local bonus = player:getEminenceCompleted(record) and 1 or 3
        player:addCurrency('spark_of_eminence', rewards['sparks'] * bonus * xi.settings.main.SPARKS_RATE, xi.settings.main.CAP_CURRENCY_SPARKS)
    end

    if rewards['exp'] ~= nil and type(rewards['exp']) == 'number' then
        player:addExp(rewards['exp'] * xi.settings.main.ROE_EXP_RATE)
    end

    if rewards['capacity'] ~= nil and type(rewards['capacity']) == 'number' then
        player:addCapacityPoints(rewards['capacity'])
    end

    if recordFlags['repeat'] then
        player:setEminenceCompleted(record, true)
    else
        player:setEminenceCompleted(record)
    end

    if
        player:getUnityLeader() > 0 and
        rewards['accolades'] ~= nil and
        type(rewards['accolades']) == 'number'
    then
        local bonusAccoladeRate = 1.0
        if record ~= 5 then
            bonusAccoladeRate = bonusAccoladeRate + ((player:getUnityRank() - 1) * 0.05)
        end

        player:addCurrency('unity_accolades', math.floor(rewards['accolades'] * bonusAccoladeRate), xi.settings.main.CAP_CURRENCY_ACCOLADES)
    end

    if rewards['keyItem'] ~= nil then
        npcUtil.giveKeyItem(player, rewards['keyItem'])
    end

    if
        not player:getEminenceCompleted(4085) and
        player:getNumEminenceCompleted() >= 10
    then
        player:setEminenceCompleted(4085)
    end

    return true
end

local function onRecordTrigger(player, recordID, params)
    params = params or {}
    params.progress = params.progress or player:getEminenceProgress(recordID)

    local entry = xi.roe.records[recordID]
    local isClaiming = params.claim

    if entry and params.progress ~= nil then
        local awaitingClaim = params.progress >= entry.goal

        if awaitingClaim and not isClaiming then
            return
        elseif isClaiming or entry:check(player, params) then
            params.progress = params.progress + (isClaiming and 0 or entry.increment)
            if params.progress >= entry.goal then
                if not completeRecordQuiet(player, recordID) and not awaitingClaim then
                    player:setEminenceProgress(recordID, entry.goal, entry.goal)
                end
            else
                -- Third arg is required by the ixi20 C++ wrap. Progress chat stays off
                -- because that wrap does not send ROERecord / ROEProgress packets.
                player:setEminenceProgress(recordID, params.progress, entry.goal)
            end
        end
    end
end

local function unlockTutorial(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if xi.settings.main.ENABLE_ROE == 0 then
        return
    end

    if not player:getEminenceCompleted(1) then
        onRecordTrigger(player, 1, { progress = 0 })
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    unlockTutorial(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if not zoning then
        unlockTutorial(player)
    end
end)

m:addOverride('xi.roe.onRecordTrigger', function(player, recordID, params)
    onRecordTrigger(player, recordID, params)
end)

if xi.roe then
    xi.roe.onRecordTrigger = onRecordTrigger
end

return m
