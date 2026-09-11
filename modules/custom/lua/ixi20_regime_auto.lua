-----------------------------------
-- Imagine XI 2.0: Field Manual / Grounds Tome pages are always on.
-- Zone in (or log in) in a book zone and every page on that book
-- counts, set to repeat. No book visit needed to start.
-- Per-page kill counts live in [ixi20rg]<regimeId>.
-- FileWatcher does not replace module overrides. Restart xi_map after
-- changing addOverride handlers. Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/regimes')
require('scripts/globals/roe')
-----------------------------------

local m = Module:new('ixi20_regime_auto')

local ZONE_VAR = 'IXI20_RG_ZONE'
local KILL_PREFIX = '[ixi20rg]'

local cachedInfo

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

local function getRegimeInfo()
    if type(cachedInfo) == 'table' then
        return cachedInfo
    end

    cachedInfo = findRegimeInfo()
    return cachedInfo
end

local function typeEnabled(regimeType)
    return (regimeType == xi.regime.type.FIELDS and xi.settings.main.ENABLE_FIELD_MANUALS == 1) or
        (regimeType == xi.regime.type.GROUNDS and xi.settings.main.ENABLE_GROUNDS_TOMES == 1)
end

local function zoneBook(zoneId, regimeType)
    local all = getRegimeInfo()
    local info = all
        and all[regimeType]
        and all[regimeType].zone
        and all[regimeType].zone[zoneId]

    if
        type(info) == 'table' and
        type(info.page) == 'table' and
        #info.page > 0
    then
        return info
    end

    return nil
end

local function booksInZone(zoneId)
    local books = {}

    for _, regimeType in ipairs({ xi.regime.type.FIELDS, xi.regime.type.GROUNDS }) do
        if typeEnabled(regimeType) then
            local info = zoneBook(zoneId, regimeType)
            if info then
                books[#books + 1] = { type = regimeType, info = info }
            end
        end
    end

    return books
end

local function findPage(regimeType, zoneId, regimeId)
    local info = zoneBook(zoneId, regimeType)
    if not info then
        return nil
    end

    for i = 1, #info.page do
        local page = info.page[i]
        if page and page[8] == regimeId then
            return page
        end
    end

    return nil
end

local function killKey(regimeId)
    return KILL_PREFIX .. tostring(regimeId)
end

local function readPacked(player, regimeId)
    return player:getCharVar(killKey(regimeId))
end

local function writePacked(player, regimeId, packed)
    player:setCharVar(killKey(regimeId), packed)
end

local function unpackSlot(packed, index)
    return bit.band(bit.rshift(packed, (index - 1) * 8), 0xFF)
end

local function packKills(k1, k2, k3, k4)
    return bit.band(k1 or 0, 0xFF) +
        bit.lshift(bit.band(k2 or 0, 0xFF), 8) +
        bit.lshift(bit.band(k3 or 0, 0xFF), 16) +
        bit.lshift(bit.band(k4 or 0, 0xFF), 24)
end

local function loadPageKills(player, regimeId)
    local packed = readPacked(player, regimeId)
    return {
        unpackSlot(packed, 1),
        unpackSlot(packed, 2),
        unpackSlot(packed, 3),
        unpackSlot(packed, 4),
    }
end

local function savePageKills(player, regimeId)
    writePacked(player, regimeId, packKills(
        player:getCharVar('[regime]killed1'),
        player:getCharVar('[regime]killed2'),
        player:getCharVar('[regime]killed3'),
        player:getCharVar('[regime]killed4')
    ))
end

local function snapshotShared(player)
    local saved =
    {
        type      = player:getCharVar('[regime]type'),
        zone      = player:getCharVar('[regime]zone'),
        id        = player:getCharVar('[regime]id'),
        repeating = player:getCharVar('[regime]repeat'),
        killed = {},
        needed = {},
    }

    for i = 1, 4 do
        saved.killed[i] = player:getCharVar('[regime]killed' .. i)
        saved.needed[i] = player:getCharVar('[regime]needed' .. i)
    end

    return saved
end

local function applyPage(player, page, regimeType, zoneId)
    local killed = loadPageKills(player, page[8])

    player:setCharVar('[regime]type', regimeType)
    player:setCharVar('[regime]zone', zoneId)
    player:setCharVar('[regime]id', page[8])
    player:setCharVar('[regime]repeat', 1)

    for i = 1, 4 do
        player:setCharVar('[regime]needed' .. i, page[i])
        player:setCharVar('[regime]killed' .. i, killed[i])
    end
end

local function restoreShared(player, saved)
    player:setCharVar('[regime]type', saved.type)
    player:setCharVar('[regime]zone', saved.zone)
    player:setCharVar('[regime]id', saved.id)
    player:setCharVar('[regime]repeat', saved.repeating)

    for i = 1, 4 do
        player:setCharVar('[regime]killed' .. i, saved.killed[i])
        player:setCharVar('[regime]needed' .. i, saved.needed[i])
    end
end

local function triggerUndertake(player, books)
    for i = 1, #books do
        local regimeType = books[i].type
        if player:getEminenceProgress(3) and regimeType == xi.regime.type.FIELDS then
            xi.roe.onRecordTrigger(player, 3)
        end

        if player:getEminenceProgress(11) and regimeType == xi.regime.type.GROUNDS then
            xi.roe.onRecordTrigger(player, 11)
        end
    end
end

local function activateZonePages(player, force)
    if not player or not player.getZoneID then
        return
    end

    local zoneId = player:getZoneID()
    if not force and player:getLocalVar(ZONE_VAR) == zoneId then
        return
    end

    player:setLocalVar(ZONE_VAR, zoneId)

    local books = booksInZone(zoneId)
    if #books == 0 then
        return
    end

    -- Hunt menu owns the book while a hunt is flagged.
    if player:getCharVar('[hunt]status') < 1 then
        local book = books[1]
        local page = book.info.page[1]
        applyPage(player, page, book.type, zoneId)
    end

    triggerUndertake(player, books)

    if not force then
        local pages = 0
        for i = 1, #books do
            pages = pages + #books[i].info.page
        end

        player:printToPlayer(
            string.format('Training pages in this area are active (%d, repeating).', pages),
            xi.msg.channel.SYSTEM_3
        )
    end
end

local function autoCheck(player, mob, regimeId, index, regimeType)
    local inner = xi.regime._ixi20AutoInner
    if not player or not player.getCharVar or type(inner) ~= 'function' then
        if type(inner) == 'function' then
            return inner(player, mob, regimeId, index, regimeType)
        end

        return
    end

    if
        not typeEnabled(regimeType) or
        player:getHP() == 0
    then
        return inner(player, mob, regimeId, index, regimeType)
    end

    local zoneId = player:getZoneID()
    local page   = findPage(regimeType, zoneId, regimeId)
    if not page then
        return inner(player, mob, regimeId, index, regimeType)
    end

    local saved = snapshotShared(player)
    applyPage(player, page, regimeType, zoneId)
    pcall(inner, player, mob, regimeId, index, regimeType)
    savePageKills(player, regimeId)
    restoreShared(player, saved)
end

m:addOverride('xi.server.onServerStart', function()
    super()
    getRegimeInfo()
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    activateZonePages(player)
end)

-- FileWatcher discards addOverride; keep zone-in and kill credit live.
if not xi.player._ixi20RegimeAutoGameIn then
    xi.player._ixi20RegimeAutoGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        activateZonePages(player)
    end
end

if not xi.regime._ixi20AutoInner then
    xi.regime._ixi20AutoInner = xi.regime.checkRegime
end

xi.regime.checkRegime = autoCheck

if not xi.regime._ixi20AutoClearInner then
    xi.regime._ixi20AutoClearInner = xi.regime.clearRegimeVars
end

xi.regime.clearRegimeVars = function(player)
    xi.regime._ixi20AutoClearInner(player)
    activateZonePages(player, true)
end
