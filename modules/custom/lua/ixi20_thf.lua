-----------------------------------
-- Imagine XI 2.0: THF Flee / Hide party buffs + crit JA recast trait.
-- Flee and Hide apply to nearby party members (and trusts), same duration.
-- Main or sub THF: each melee / weaponskill critical shaves 1s off every
-- job-ability recast. Pair with ixi20_thf.cpp (rebuild xi_map).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/job_utils/thief')
require('scripts/globals/weaponskills')
-----------------------------------

local m = Module:new('ixi20_thf')

local LISTENER_ID  = 'IXI20_THF_CRIT_JA'
local PARTY_RANGE  = 14
local CRIT_RECAST  = 1

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function isThf(entity)
    return isPlayer(entity) and (entity:getMainJob() == xi.job.THF or entity:getSubJob() == xi.job.THF)
end

local function tryReduce(attacker)
    if
        not isThf(attacker) or
        not Ixi20ReduceAbilityRecasts
    then
        return
    end

    Ixi20ReduceAbilityRecasts(attacker, CRIT_RECAST)
end

local function partyInRange(player)
    local members = {}
    if not player or not player.getPartyWithTrusts then
        return { player }
    end

    local casterZone = player.getZoneID and player:getZoneID()
    for _, member in pairs(player:getPartyWithTrusts()) do
        if
            member and
            (not member.isDead or not member:isDead()) and
            (not casterZone or not member.getZoneID or member:getZoneID() == casterZone) and
            (member:getID() == player:getID() or player:checkDistance(member) <= PARTY_RANGE)
        then
            members[#members + 1] = member
        end
    end

    if #members == 0 then
        members[1] = player
    end

    return members
end

local function applyFlee(player, member, duration)
    if member.hasStatusEffect and member:hasStatusEffect(xi.effect.WEIGHT) then
        member:delStatusEffect(xi.effect.WEIGHT)
    end

    member:addStatusEffect(xi.effect.FLEE, { power = 10000, duration = duration, origin = player })

    if member:getID() ~= player:getID() then
        member:messageBasic(xi.msg.basic.GAINS_EFFECT_OF_STATUS, xi.effect.FLEE)
    end
end

local function applyHide(player, member, duration)
    member:addStatusEffect(xi.effect.HIDE, { power = 1, duration = duration, origin = player })

    if member:getID() ~= player:getID() then
        member:messageBasic(xi.msg.basic.GAINS_EFFECT_OF_STATUS, xi.effect.HIDE)
    end
end

local function useFlee(player)
    local duration = 30 + player:getMod(xi.mod.FLEE_DURATION)
    for _, member in ipairs(partyInRange(player)) do
        applyFlee(player, member, duration)
    end

    return xi.effect.FLEE
end

local function useHide(player)
    local duration = math.randomInt(30, 300)
    duration = duration * (1 + player:getMod(xi.mod.HIDE_DURATION) / 100)
    duration = math.floor(duration * xi.settings.main.SNEAK_INVIS_DURATION_MULTIPLIER)

    for _, member in ipairs(partyInRange(player)) do
        applyHide(player, member, duration)
    end

    return xi.effect.HIDE
end

local function attach(player)
    if not isPlayer(player) then
        return
    end

    player:removeListener(LISTENER_ID)
    player:addListener('MELEE_SWING_HIT', LISTENER_ID, function(attacker, _, attack)
        if attack and attack.isCritical and attack:isCritical() then
            tryReduce(attacker)
        end
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

local function wrapWeaponskill(fn)
    return function(attacker, ...)
        local dmg, crit, tpHits, extraHits, shadows = fn(attacker, ...)
        if crit then
            tryReduce(attacker)
        end

        return dmg, crit, tpHits, extraHits, shadows
    end
end

m:addOverride('xi.job_utils.thief.useFlee', function(player, target, ability)
    return useFlee(player)
end)

m:addOverride('xi.job_utils.thief.useHide', function(player, target, ability)
    return useHide(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    attach(player)
end)

-- FileWatcher discards addOverride; assignment wraps stay live.
if xi.job_utils and xi.job_utils.thief and not xi.job_utils.thief._ixi20PartyFleeHide then
    xi.job_utils.thief._ixi20PartyFleeHide = true
    xi.job_utils.thief.useFlee = function(player, target, ability)
        return useFlee(player)
    end
    xi.job_utils.thief.useHide = function(player, target, ability)
        return useHide(player)
    end
end

if xi.weaponskills and not xi.weaponskills._ixi20ThfCritRecast then
    xi.weaponskills._ixi20ThfCritRecast = true
    xi.weaponskills.doPhysicalWeaponskill = wrapWeaponskill(xi.weaponskills.doPhysicalWeaponskill)
    xi.weaponskills.doRangedWeaponskill   = wrapWeaponskill(xi.weaponskills.doRangedWeaponskill)
end

if not xi.player._ixi20ThfGameIn then
    xi.player._ixi20ThfGameIn = true
    local prev = xi.player.onGameIn
    xi.player.onGameIn = function(player, firstLogin, zoning)
        if prev then
            prev(player, firstLogin, zoning)
        end

        attach(player)
    end
end

attachOnlinePlayers()
