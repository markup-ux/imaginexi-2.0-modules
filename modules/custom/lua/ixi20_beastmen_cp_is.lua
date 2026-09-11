-----------------------------------
-- Imagine XI 2.0: XP-credited beastmen always grant conquest points
-- and the same amount of Imperial Standing, including outside
-- conquest regions. Stock Signet CP in Ronfaure-Jeuno is not doubled.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
-----------------------------------

local m = Module:new('ixi20_beastmen_cp_is')

local LISTENER = 'IXI20_BEASTMEN_CP_IS'

local function settings()
    return xi.settings and xi.settings.main or {}
end

local function enabled()
    return settings().IMAGINEXI_BEASTMEN_CP_IS ~= false
end

local function isPlayer(entity)
    return entity ~= nil and entity.isPC ~= nil and entity:isPC()
end

-- Same rate as conquest::AddConquestPoints (exp * 10-20% + CONQUEST_BONUS).
-- Unknown regions keep the default 15% so Dynamis / ToAU / fronts still pay.
local function conquestPointsForExp(player, exp)
    local percentage = 0.15
    local region     = player:getCurrentRegion()

    if region ~= xi.region.UNKNOWN then
        local owner      = GetRegionOwner(region)
        local nationRank = GetNationRank(player:getNation())

        if owner <= xi.nation.WINDURST and nationRank > 1 then
            if IsConquestAlliance() then
                percentage = GetNationRank(owner) == 1 and 0.2 or 0.1
            elseif owner == player:getNation() then
                percentage = 0.1
            end
        end
    end

    percentage = percentage + (player:getMod(xi.mod.CONQUEST_BONUS) or 0) / 100.0

    return math.max(1, math.floor(exp * percentage))
end

local function stockAlreadyGrantedCp(player)
    local region = player:getCurrentRegion()

    return player:hasStatusEffect(xi.effect.SIGNET) and
        region >= xi.region.RONFAURE and
        region <= xi.region.JEUNO
end

local function tryGrant(player, mob, exp)
    if not enabled() or not isPlayer(player) then
        return
    end

    if type(exp) ~= 'number' or exp <= 0 then
        return
    end

    if mob == nil or mob.isMob == nil or not mob:isMob() then
        return
    end

    if mob:getEcosystem() ~= xi.ecosystem.BEASTMEN then
        return
    end

    if mob:getAllegiance() == xi.allegiance.PLAYER then
        return
    end

    local points = conquestPointsForExp(player, exp)

    -- C++ already paid CP for Signet + conquest-region combat XP.
    if not stockAlreadyGrantedCp(player) then
        player:addCP(points)
    end

    player:addCurrency('imperial_standing', points)
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER)
    player:addListener('EXPERIENCE_POINTS', LISTENER, function(playerObj, mobObj, expGained)
        tryGrant(playerObj, mobObj, expGained)
    end)
end

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
                    attach(player)
                end
            end
        end
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

-- FileWatcher discards addOverride; keep onGameIn live without a restart.
if not xi.player._ixi20BeastmenCpIsGameIn then
    xi.player._ixi20BeastmenCpIsGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
