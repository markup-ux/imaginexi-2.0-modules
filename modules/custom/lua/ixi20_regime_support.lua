-----------------------------------
-- Imagine XI 2.0: Field Manual / Grounds Tome support costs 0 tabs.
-- Native FoV/GoV kill/review messages are used. This file only keeps
-- page-complete from getting stuck when repeat reset is skipped.
-- FileWatcher does not replace module overrides. Restart xi_map after
-- changing addOverride handlers. Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_regime_support')

-- Client greys out paid lines from this event param. Server cost is 0.
local MENU_TABS = 50000

local function upvalue(fn, name)
    if type(fn) ~= 'function' then
        return nil
    end

    local i = 1
    while true do
        local key, value = debug.getupvalue(fn, i)
        if not key then
            return nil
        end

        if key == name then
            return value
        end

        i = i + 1
    end
end

local function findRegimeInfo()
    local fn = xi.regime.bookOnTrigger
    for _ = 1, 8 do
        if type(fn) ~= 'function' then
            return nil
        end

        local info = upvalue(fn, 'regimeInfo')
        if type(info) == 'table' then
            return info
        end

        local env = getfenv and getfenv(fn)
        fn = env and env.super
    end

    return nil
end

local function zeroBookCosts(info)
    if type(info) ~= 'table' then
        return
    end

    for _, block in pairs(info) do
        if type(block) == 'table' and type(block.finishOptions) == 'table' then
            for _, opt in pairs(block.finishOptions) do
                if type(opt) == 'table' then
                    opt.cost       = 0
                    opt.discounted = 0
                end
            end
        end
    end
end

m:addOverride('xi.server.onServerStart', function()
    super()
    zeroBookCosts(findRegimeInfo())
end)

-- Do not call super(): a prior FileWatcher stack still has the addCurrency crash.
m:addOverride('xi.regime.bookOnTrigger', function(player, regimeType)
    local all = findRegimeInfo()
    zeroBookCosts(all)

    local info = all
        and all[regimeType]
        and all[regimeType].zone
        and all[regimeType].zone[player:getZoneID()]
    if not info then
        return
    end

    local cipher = 0
    local active = xi.extravaganza.campaignActive()
    if
        active == xi.extravaganza.campaign.SPRING_FALL or
        active == xi.extravaganza.campaign.BOTH
    then
        cipher = 3
    end

    if player:getCharVar('[hunt]status') >= 1 then
        player:startEvent(info.event, 0, 0, 3, 1, 0, 0, MENU_TABS, player:getCharVar('[hunt]id'))
        return
    end

    if
        (regimeType == xi.regime.type.FIELDS and xi.settings.main.ENABLE_FIELD_MANUALS == 1) or
        (regimeType == xi.regime.type.GROUNDS and xi.settings.main.ENABLE_GROUNDS_TOMES == 1)
    then
        local pages = #info.page
        local arg2  = 0
        for i = 1, 10 do
            if i > pages then
                arg2 = arg2 + 2^i
            end
        end

        player:startEvent(info.event, 0, arg2, cipher, 1, 0, 0, MENU_TABS, player:getCharVar('[regime]id'))
        return
    end

    player:printToPlayer('Disabled.')
end)

m:addOverride('xi.regime.bookOnEventFinish', function(player, option, regimeType)
    zeroBookCosts(findRegimeInfo())

    -- super is only valid inside this override. Walk past any leftover copies.
    local fn = super
    while type(fn) == 'function' do
        local src = debug.getinfo(fn, 'S')
        if not src or not tostring(src.source):find('ixi20_regime_support', 1, true) then
            fn(player, option, regimeType)
            return
        end

        local env = getfenv and getfenv(fn)
        fn = env and env.super
    end
end)

local function pageIsFilled(player, needed)
    local any = false
    for i = 1, 4 do
        local want = needed[i] or 0
        if want > 0 then
            any = true
            if player:getCharVar('[regime]killed' .. i) < want then
                return false
            end
        end
    end

    return any
end

-- If page-complete Lua errors before the repeat reset, kills stay at cap and
-- further checkRegime calls return immediately (no chat, no credit).
local function recoverStuckRepeat(player, regimeId)
    if
        not player or
        player:getCharVar('[regime]id') ~= regimeId or
        player:getCharVar('[regime]repeat') ~= 1
    then
        return false
    end

    local needed = {}
    for i = 1, 4 do
        needed[i] = player:getCharVar('[regime]needed' .. i)
    end

    if not pageIsFilled(player, needed) then
        return false
    end

    for i = 1, 4 do
        player:setCharVar('[regime]killed' .. i, 0)
    end

    return true
end

-- Drop any leftover FileWatcher progress-chat wraps.
if xi.regime._ixi20ReviewInner then
    xi.regime.bookOnEventUpdate = xi.regime._ixi20ReviewInner
    xi.regime._ixi20ReviewInner = nil
end

if not xi.regime._ixi20CheckInner then
    xi.regime._ixi20CheckInner = xi.regime.checkRegime
end

xi.regime.checkRegime = function(player, mob, regimeId, index, regimeType)
    if not player or not player.getCharVar then
        return xi.regime._ixi20CheckInner(player, mob, regimeId, index, regimeType)
    end

    pcall(xi.regime._ixi20CheckInner, player, mob, regimeId, index, regimeType)

    if recoverStuckRepeat(player, regimeId) then
        pcall(xi.regime._ixi20CheckInner, player, mob, regimeId, index, regimeType)
    end
end
