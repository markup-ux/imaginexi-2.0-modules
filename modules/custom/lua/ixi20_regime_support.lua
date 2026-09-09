-----------------------------------
-- Imagine XI 2.0: Field Manual / Grounds Tome support costs 0 tabs.
-- FileWatcher does not replace module overrides. Restart xi_map after
-- changing this file. Do not return this module.
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
