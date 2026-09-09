-----------------------------------
-- Imagine XI 2.0: Regen tick matches current Refresh
-- Each player gains HP on the same 3s pulse as Refresh, equal to their
-- live Refresh from traits / gear / food. Spell Refresh (xi.effect.REFRESH)
-- is MP only. Existing Regen is kept. No Auto Regen trait icon.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_refresh_regen')

local LISTENER_ID = 'IXI20_REFRESH_REGEN'

local function currentRefresh(player)
    -- Same formula TickRegen uses for MP.
    return math.max(player:getMod(xi.mod.REFRESH), 0) - player:getMod(xi.mod.REFRESH_DOWN)
end

local function attachRefreshRegen(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('EFFECTS_TICK', LISTENER_ID, function(playerArg)
        if not playerArg or not playerArg.isPC or not playerArg:isPC() or playerArg:isDead() then
            return
        end

        local refresh = currentRefresh(playerArg)
        local spellRefresh = playerArg:getStatusEffect(xi.effect.REFRESH)
        if spellRefresh then
            refresh = refresh - spellRefresh:getPower()
        end

        if refresh > 0 then
            playerArg:addHP(refresh)
        end
    end)
end

-- FileWatcher reloads do not run onGameIn. Re-attach whoever is already zoned in.
local function attachOnlinePlayers()
    if not xi.zone or not GetZone then
        return
    end

    local visitedZone = {}
    for _, zoneId in pairs(xi.zone) do
        if type(zoneId) == 'number' and not visitedZone[zoneId] then
            visitedZone[zoneId] = true
            local zone = GetZone(zoneId)
            if zone then
                for _, player in pairs(zone:getPlayers() or {}) do
                    attachRefreshRegen(player)
                end
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attachRefreshRegen(player)
end)

attachOnlinePlayers()

return m
