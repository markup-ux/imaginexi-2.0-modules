-----------------------------------
-- Imagine XI 2.0 multi-currency exchange (beside conquest / signet guards)
-- Port of 1.0 cp_exchange_signet_buddy.lua.
--
-- Plays with ixi20_gil_economy:
--   addGil / spark addCurrency become XP. This NPC never uses those for payouts.
--   Gil cannot be chosen as "Get" or "Spend" while gil-to-XP is on.
--   Sparks are spend-only. Get XP pays at the spark scale (5 CP = 1 XP at ratio 1.0)
--   via ixi20_economy.grantExperience. Refunds use setGil / setCurrency.
--
-- Spawns "Exchange" the first time a player uses a conquest overseer.
-- customMenu is deferred so HandleCustomMenu is not re-entered.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_economy')
require('scripts/globals/conquest')
require('scripts/enum/item')
-----------------------------------

local m = Module:new('ixi20_cp_exchange')

local GIL_CAP        = 999999999
local UNITS_CHOICES  = { 1, 10, 50, 99, 100, 250, 500, 1000, 2500, 5000 }
local UNITS_PER_PAGE = 2
local MENU_PAGE      = 4
local MENU_DELAY_MS  = 100

local ASSETS =
{
    { id = 'cp',       mTag = 'CP',       label = 'Conquest Points',              kind = 'cp',       weight = 1 },
    { id = 'sparks',   mTag = 'Sparks',   label = 'Sparks of Eminence (RoE)',     kind = 'currency', key = 'spark_of_eminence', cap = 'CAP_CURRENCY_SPARKS', weight = 5 },
    { id = 'xp',       mTag = 'XP',       label = 'Experience Points',            kind = 'xp',       weight = 5 },
    { id = 'tabs',     mTag = 'Tabs',     label = 'Book Tabs (Valor)',            kind = 'currency', key = 'valor_point', cap = 'CAP_CURRENCY_VALOR', weight = 5 },
    { id = 'gil',      mTag = 'Gil',      label = 'Gil',                          kind = 'gil',      weight = 100 },
    { id = 'beast',    mTag = 'Beast',    label = 'Ancient beastcoin (Limbus)',   kind = 'currency', key = 'ancient_beastcoin', weight = 5 },
    { id = 'byne',     mTag = 'Byne',     label = 'Byne Bill',                    kind = 'item',     itemId = xi.item.ONE_BYNE_BILL,         weight = 50 },
    { id = 'obronze',  mTag = 'O-Bronze', label = 'O. Bronzepiece',               kind = 'item',     itemId = xi.item.ORDELLE_BRONZEPIECE,   weight = 50 },
    { id = 'twhite',   mTag = 'T-White',  label = 'T. Whiteshell',                kind = 'item',     itemId = xi.item.TUKUKU_WHITESHELL,     weight = 50 },
    { id = '100byne',  mTag = 'Byne100',  label = '100 Byne Bill',                kind = 'item',     itemId = xi.item.ONE_HUNDRED_BYNE_BILL, weight = 5000 },
    { id = 'msilver',  mTag = 'M-Silver', label = 'M. Silverpiece',               kind = 'item',     itemId = xi.item.MONTIONT_SILVERPIECE,  weight = 5000 },
    { id = 'ljade',    mTag = 'L-Jade',   label = 'L. Jadeshell',                 kind = 'item',     itemId = xi.item.LUNGO_NANGO_JADESHELL, weight = 5000 },
    { id = 'imperial', mTag = 'Imp',      label = 'Imperial standing',            kind = 'currency', key = 'imperial_standing', weight = 1 },
    { id = 'leujao',   mTag = 'Asm-LJ',   label = 'Leujaoam assault points',      kind = 'currency', key = 'leujaoam_assault_point', weight = 1 },
    { id = 'mamool',   mTag = 'Asm-MM',   label = 'Mamool Ja assault points',     kind = 'currency', key = 'mamool_assault_point', weight = 1 },
    { id = 'lebros',   mTag = 'Asm-LB',   label = 'Lebros assault points',        kind = 'currency', key = 'lebros_assault_point', weight = 1 },
    { id = 'periqia',  mTag = 'Asm-PQ',   label = 'Periqia assault points',       kind = 'currency', key = 'periqia_assault_point', weight = 1 },
    { id = 'ilrusi',   mTag = 'Asm-IL',   label = 'Ilrusi assault points',        kind = 'currency', key = 'ilrusi_assault_point', weight = 1 },
    { id = 'nyzul',    mTag = 'Nyzul',    label = 'Nyzul Isle assault points',    kind = 'currency', key = 'nyzul_isle_assault_point', weight = 1 },
    { id = 'zeni',     mTag = 'Zeni',     label = 'Zeni (ZNM)',                   kind = 'currency', key = 'zeni_point', weight = 1 },
    { id = 'alex',     mTag = 'Alex',     label = 'Alexandrite',                  kind = 'item',     itemId = xi.item.ALEXANDRITE, weight = 60 },
    { id = 'allied',   mTag = 'Allied',   label = 'Allied notes',                 kind = 'currency', key = 'allied_notes', weight = 1 },
}

local currentNpc = nil
local spawnedForGuard = {}

local function gilToExp()
    return xi.settings and xi.settings.main and xi.settings.main.IMAGINEXI_GIL_TO_EXP_ENABLED
end

-- Gil payouts would be eaten by ixi20_gil_economy.cpp if we used addGil.
-- Sparks are spend-only; leftover RoE sparks dump into other currencies or XP.
local function canReceive(a)
    if a.kind == 'gil' then
        return not gilToExp()
    end

    if a.kind == 'currency' and a.key == 'spark_of_eminence' then
        return false
    end

    return true
end

local function canSpend(a)
    if a.kind == 'xp' then
        return false
    end

    -- Gil is XP; a dummy wallet must not be spendable here.
    if a.kind == 'gil' and gilToExp() then
        return false
    end

    return true
end

local function spendList()
    local t = {}
    for _, a in ipairs(ASSETS) do
        if canSpend(a) then
            table.insert(t, a)
        end
    end

    return t
end

local function openMenu(player, menuTable)
    player:timer(MENU_DELAY_MS, function(p)
        local ok, err = pcall(function()
            p:customMenu(menuTable)
        end)
        if not ok then
            p:printToPlayer(('Exchange: menu error (%s)'):format(tostring(err)), xi.msg.channel.SYSTEM_1)
        end
    end)
end

local function printLine(p, npc, text)
    local name = (npc and npc.getPacketName and npc:getPacketName()) or 'Exchange'
    p:printToPlayer(text, 0, name)
end

local function assetById(id)
    for _, a in ipairs(ASSETS) do
        if a.id == id then
            return a
        end
    end
end

local function receiveListExcept(excludeId)
    local t = {}
    for _, a in ipairs(ASSETS) do
        if a.id ~= excludeId and canReceive(a) then
            table.insert(t, a)
        end
    end

    return t
end

local function playerGil(p)
    if p.getRealGil then
        return p:getRealGil() or 0
    end

    return p:getGil() or 0
end

local function getBalance(p, a)
    if a.kind == 'xp' then
        return 0
    elseif a.kind == 'cp' then
        return p:getCP() or 0
    elseif a.kind == 'currency' then
        return p:getCurrency(a.key) or 0
    elseif a.kind == 'gil' then
        return playerGil(p)
    else
        return p:getItemCount(a.itemId) or 0
    end
end

local function takeAsset(p, a, amt)
    if amt <= 0 then
        return true
    end

    if a.kind == 'cp' then
        if (p:getCP() or 0) < amt then
            return false
        end

        p:delCP(amt)
        return true
    elseif a.kind == 'currency' then
        if (p:getCurrency(a.key) or 0) < amt then
            return false
        end

        p:delCurrency(a.key, amt)
        return true
    elseif a.kind == 'gil' then
        return p:delGil(amt)
    else
        if (p:getItemCount(a.itemId) or 0) < amt then
            return false
        end

        return p:delItem(a.itemId, amt)
    end
end

-- Real gil / sparks, not the economy wraps on addGil / addCurrency('spark_of_eminence').
local function giveRealGil(p, amt)
    p:setGil(playerGil(p) + amt)
    return true
end

local function giveRealCurrency(p, key, amt)
    p:setCurrency(key, (p:getCurrency(key) or 0) + amt)
    return true
end

local function giveAsset(p, a, amt)
    if amt <= 0 then
        return true
    end

    if a.kind == 'xp' then
        xi.ixi20_economy.grantExperience(p, xi.ixi20_economy.sparksToExpAmount(amt))
        return true
    elseif a.kind == 'cp' then
        p:addCP(amt)
        return true
    elseif a.kind == 'currency' then
        if a.key == 'spark_of_eminence' then
            return giveRealCurrency(p, a.key, amt)
        end

        local capVal = a.cap and xi.settings and xi.settings.main and xi.settings.main[a.cap]
        if capVal then
            p:addCurrency(a.key, amt, capVal)
        else
            p:addCurrency(a.key, amt)
        end

        return true
    elseif a.kind == 'gil' then
        return giveRealGil(p, amt)
    else
        local remain = amt
        while remain > 0 do
            local give = math.min(remain, 99)
            if not p:addItem(a.itemId, give) then
                return false
            end

            remain = remain - give
        end

        return true
    end
end

local function hasSpaceFor(p, itemId, units)
    local stacksNeeded = math.ceil(units / 99)
    local free         = p:getFreeSlotsCount() or 0
    return free >= stacksNeeded, stacksNeeded, free
end

local function convertCompute(p, fromA, toA, spendCap)
    local wf, wt = fromA.weight, toA.weight
    local bal      = getBalance(p, fromA)
    local spendMax = math.min(spendCap, bal)
    if spendMax < 1 then
        return nil, 'Not enough to spend.'
    end

    local toReceive = math.floor(spendMax * wf / wt)
    if toReceive < 1 then
        return nil, 'Amount too small to yield even 1 unit.'
    end

    if toA.kind == 'currency' and toA.cap and xi.settings and xi.settings.main then
        local capVal = xi.settings.main[toA.cap]
        if capVal then
            local cur  = p:getCurrency(toA.key) or 0
            local room = math.max(0, capVal - cur)
            toReceive  = math.min(toReceive, room)
        end
    end

    if toA.kind == 'gil' then
        local cur  = playerGil(p)
        local room = math.max(0, GIL_CAP - cur)
        toReceive  = math.min(toReceive, room)
    end

    if toReceive < 1 then
        return nil, 'Target currency is at cap.'
    end

    local fromSpend = math.ceil(toReceive * wt / wf)
    if fromSpend > spendMax then
        toReceive  = math.floor(spendMax * wf / wt)
        if toReceive < 1 then
            return nil, 'Amount too small after cap check.'
        end

        fromSpend = math.ceil(toReceive * wt / wf)
    end

    if fromSpend > spendMax or fromSpend < 1 then
        return nil, 'Could not settle conversion.'
    end

    return fromSpend, toReceive
end

local function printRateCard(p)
    printLine(p, currentNpc, '--- Exchange scale: weight = CP value per 1 unit ---')
    for _, a in ipairs(ASSETS) do
        local note = ''
        if a.kind == 'xp' then
            note = '  (Get only; same scale as sparks)'
        elseif a.kind == 'currency' and a.key == 'spark_of_eminence' then
            note = '  (spend only; leftover RoE sparks)'
        elseif not canReceive(a) then
            note = '  (spend only; payout would become XP)'
        end

        printLine(p, currentNpc, ('  %s = %d CP  |  %s%s'):format(a.mTag, a.weight, a.label, note))
    end

    printLine(p, currentNpc, 'Trades convert on that scale. Menu uses short tags.')
end

local function executeExchange(p, fromA, toA, spendCap)
    if not canReceive(toA) then
        printLine(p, currentNpc, ('Cannot pay out %s here (it would become XP). Pick another Get target.'):format(toA.label))
        return
    end

    local fromSpend, toReceive = convertCompute(p, fromA, toA, spendCap)
    if not fromSpend then
        printLine(p, currentNpc, toReceive or 'Conversion failed.')
        return
    end

    if toA.kind == 'item' then
        local okSpace, need, free = hasSpaceFor(p, toA.itemId, toReceive)
        if not okSpace then
            printLine(p, currentNpc, ('Need %d free slot(s) for items (you have %d).'):format(need, free))
            return
        end
    end

    if not takeAsset(p, fromA, fromSpend) then
        printLine(p, currentNpc, 'Could not remove what you are spending.')
        return
    end

    if not giveAsset(p, toA, toReceive) then
        giveAsset(p, fromA, fromSpend)
        printLine(p, currentNpc, 'Could not deliver — refunded your spend.')
        return
    end

    if toA.kind == 'xp' then
        local expAmount = xi.ixi20_economy.sparksToExpAmount(toReceive)
        printLine(p, currentNpc, ('Traded %d [%s] -> %d XP.'):format(fromSpend, fromA.label, expAmount))
    else
        printLine(p, currentNpc, ('Traded %d [%s] -> %d [%s].'):format(fromSpend, fromA.label, toReceive, toA.label))
    end
end

local showRoot
local showPickFrom
local showPickTo
local showQtyPage

showRoot = function(player)
    openMenu(player, {
        title = 'Exchange',
        options =
        {
            {
                'Trade',
                function(p)
                    printLine(p, currentNpc, 'Pick what to spend. You can open this menu with 0 CP; you only need currency to complete a swap.')
                    showPickFrom(p, 1)
                end,
            },
            {
                'Rates',
                function(p)
                    printRateCard(p)
                    openMenu(p, {
                        title = 'Exchange',
                        options = {
                            {
                                'OK',
                                function(pp)
                                    showRoot(pp)
                                end,
                            },
                        },
                    })
                end,
            },
            {
                'Balances',
                function(p)
                    printLine(p, currentNpc, 'Balances - CP weights are under Rates.')
                    for _, a in ipairs(ASSETS) do
                        if canSpend(a) then
                            printLine(p, currentNpc, ('  %s: %d  [%s]'):format(a.mTag, getBalance(p, a), a.label))
                        end
                    end

                    openMenu(p, {
                        title = 'Exchange',
                        options = {
                            {
                                'OK',
                                function(pp)
                                    showRoot(pp)
                                end,
                            },
                        },
                    })
                end,
            },
        },
    })
end

showPickFrom = function(player, page)
    local list  = spendList()
    local opts  = {}
    local total = #list
    local pages = math.max(1, math.ceil(total / MENU_PAGE))
    local start = (page - 1) * MENU_PAGE + 1
    local stop  = math.min(total, start + MENU_PAGE - 1)

    if page > 1 then
        table.insert(opts, { 'Prev', function(pp) showPickFrom(pp, page - 1) end })
    end

    for i = start, stop do
        local a   = list[i]
        local bal = getBalance(player, a)
        table.insert(opts, {
            ('Spend %s x%d'):format(a.mTag, bal),
            function(pp)
                showPickTo(pp, a.id, 1)
            end,
        })
    end

    if stop < total then
        table.insert(opts, { 'More', function(pp) showPickFrom(pp, page + 1) end })
    end

    table.insert(opts, { 'Close', function(pp) showRoot(pp) end })
    openMenu(player, { title = ('Spend? %d/%d'):format(page, pages), options = opts })
end

showPickTo = function(player, fromId, page)
    local fromA = assetById(fromId)
    if not fromA then
        showRoot(player)
        return
    end

    local list  = receiveListExcept(fromId)
    local total = #list
    local pages = math.max(1, math.ceil(total / MENU_PAGE))
    local opts  = {}
    local start = (page - 1) * MENU_PAGE + 1
    local stop  = math.min(total, start + MENU_PAGE - 1)

    if page > 1 then
        table.insert(opts, { 'Prev', function(pp) showPickTo(pp, fromId, page - 1) end })
    end

    for i = start, stop do
        local a = list[i]
        table.insert(opts, {
            ('Get %s'):format(a.mTag),
            function(pp)
                showQtyPage(pp, fromId, a.id, 1)
            end,
        })
    end

    if stop < total then
        table.insert(opts, { 'More', function(pp) showPickTo(pp, fromId, page + 1) end })
    end

    table.insert(opts, { 'Back', function(pp) showPickFrom(pp, 1) end })
    openMenu(player, { title = ('Get? %s %d/%d'):format(fromA.mTag, page, pages), options = opts })
end

showQtyPage = function(player, fromId, toId, qtyPage)
    local fromA = assetById(fromId)
    local toA   = assetById(toId)
    if not fromA or not toA then
        showRoot(player)
        return
    end

    local bal = getBalance(player, fromA)
    printLine(player, currentNpc, ('%s -> %s | can spend up to %d'):format(fromA.label, toA.label, bal))

    local opts    = {}
    local start   = (qtyPage - 1) * UNITS_PER_PAGE + 1
    local stop    = math.min(#UNITS_CHOICES, start + UNITS_PER_PAGE - 1)
    local hasPrev = start > 1
    local hasNext = stop < #UNITS_CHOICES

    if hasPrev then
        table.insert(opts, { 'Prev', function(pp) showQtyPage(pp, fromId, toId, qtyPage - 1) end })
    end

    for i = start, stop do
        local u = UNITS_CHOICES[i]
        table.insert(opts, {
            ('x%d'):format(u),
            function(pp)
                executeExchange(pp, fromA, toA, u)
                showQtyPage(pp, fromId, toId, qtyPage)
            end,
        })
    end

    table.insert(opts, {
        'MAX',
        function(pp)
            executeExchange(pp, fromA, toA, getBalance(pp, fromA))
            showQtyPage(pp, fromId, toId, qtyPage)
        end,
    })

    if hasNext then
        table.insert(opts, { 'More', function(pp) showQtyPage(pp, fromId, toId, qtyPage + 1) end })
    end

    table.insert(opts, { 'Back', function(pp) showPickTo(pp, fromId, 1) end })
    openMenu(player, {
        title = ('%s>%s'):format(fromA.mTag, toA.mTag),
        options = opts,
    })
end

local function npcStillInZone(npc, zone)
    if not npc or not zone then
        return false
    end

    local ok, sameZone = pcall(function()
        local npcZone = npc.getZone and npc:getZone()
        return npcZone ~= nil and npcZone.getID and npcZone:getID() == zone:getID()
    end)

    return ok and sameZone
end

local function spawnExchangeBeside(guardNpc)
    local zone = guardNpc and guardNpc.getZone and guardNpc:getZone()
    if not zone or not zone.insertDynamicEntity then
        return
    end

    local key = tostring(zone:getID()) .. ':' .. tostring(guardNpc:getID())
    if npcStillInZone(spawnedForGuard[key], zone) then
        return
    end

    local npc = zone:insertDynamicEntity({
        objtype              = xi.objType.NPC,
        name                 = 'Exchange',
        packetName           = 'Exchange',
        look                 = 2433,
        x                    = guardNpc:getXPos() + 1.2,
        y                    = guardNpc:getYPos(),
        z                    = guardNpc:getZPos() + 0.8,
        rotation             = guardNpc:getRotPos(),
        widescan             = 1,
        releaseIdOnDisappear = true,
        onTrigger = function(player, exNpc)
            currentNpc = exNpc
            printLine(player, exNpc, 'Currency exchange. Menu uses short tags; pick Rates for the full CP scale.')
            showRoot(player)
        end,
        onTrade = function(player, exNpc, trade)
            printLine(player, exNpc, 'Use Trade in the menu. Rates print to chat when you open this NPC.')
        end,
    })

    if npc then
        spawnedForGuard[key] = npc
    end
end

m:addOverride('xi.conquest.overseerOnTrigger', function(player, npc, guardNation, guardType, guardEvent, guardRegion)
    spawnExchangeBeside(npc)
    super(player, npc, guardNation, guardType, guardEvent, guardRegion)
end)

return m
