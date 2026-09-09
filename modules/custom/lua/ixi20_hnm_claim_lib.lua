-----------------------------------
-- Shared HNM claim lottery helpers (not a loaded module).
-----------------------------------
require('modules/custom/lua/ixi20_hnm_roster')
-----------------------------------
xi = xi or {}
xi.ixi20HnmClaim = xi.ixi20HnmClaim or {}

local function setting(key, fallback)
    local map = xi.settings and xi.settings.map
    if map and map[key] ~= nil then
        return map[key]
    end

    return fallback
end

xi.ixi20HnmClaim.shieldMs = function()
    return setting('IMAGINEXI_HNM_CLAIM_SHIELD_MS', 10000)
end

xi.ixi20HnmClaim.idleSeconds = function()
    return setting('IMAGINEXI_HNM_CLAIM_IDLE_SECONDS', 90)
end

local function collectAllianceTickets(mob, filterFn)
    local tickets = {}
    local seen    = {}

    xi.ixi20Hnm.forEachEnmity(mob, function(entity)
        local player = entity:isPC() and entity or (entity.getMaster and entity:getMaster())
        if not player or not player:isPC() or (filterFn and not filterFn(player)) then
            return
        end

        local key = xi.ixi20Hnm.allianceKey(player)
        if not seen[key] then
            seen[key] = true
            tickets[#tickets + 1] = { key = key, player = player }
        end
    end)

    return tickets
end

local function notify(player, message)
    local alliance = player:getAlliance()
    if not alliance then
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3, '')
        return
    end

    for _, member in pairs(alliance) do
        if member and member:isPC() then
            member:printToPlayer(message, xi.msg.channel.SYSTEM_3, '')
        end
    end
end

local function startShield(mob, durationMs)
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.UNCLAIMABLE)
    mob:setUnkillable(true)
    mob:setCallForHelpBlocked(true)
    mob:stun(durationMs)
    mob:setLocalVar('[ixi20Claim]shielding', 1)
    mob:setLocalVar('[ixi20Claim]winnerKey', 0)
    mob:setLocalVar('[ixi20Claim]lastHit', 0)
end

local function endShield(mob)
    mob:setUnkillable(false)
    mob:setCallForHelpBlocked(false)
    mob:setHP(mob:getMaxHP())
    mob:setLocalVar('[ixi20Claim]shielding', 0)

    local mobId = mob:getID()
    for _, effect in ipairs(mob:getStatusEffects()) do
        if effect:getOriginID() ~= mobId then
            mob:delStatusEffectSilent(effect:getEffectType())
        end
    end
end

local function clearEnmity(mob)
    for _, enmityEntry in pairs(mob:getEnmityList()) do
        local entity = enmityEntry.entity or enmityEntry
        if entity then
            if not entity:isPC() then
                entity:disengage()
            end

            mob:resetEnmity(entity)
        end
    end

    mob:resetAI()
    mob:disengage()
end

local function awardClaim(mob, winner)
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.EXCLUSIVE)
    mob:updateClaim(winner)
    mob:addEnmity(winner, 1, 1)
    mob:setLocalVar('[ixi20Claim]winnerKey', xi.ixi20Hnm.allianceKey(winner))
    mob:setLocalVar('[ixi20Claim]lastHit', GetSystemTime())
end

local function resolveLottery(mob, tickets)
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.EXCLUSIVE)
    clearEnmity(mob)

    if #tickets == 0 then
        mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.UNCLAIMABLE)
        mob:setLocalVar('[ixi20Claim]winnerKey', 0)
        return
    end

    local winnerTicket = utils.randomEntry(tickets)
    local winner       = winnerTicket.player
    awardClaim(mob, winner)

    local mobName = mob:getPacketName()
    notify(winner, string.format('Your group won the lottery for %s! (%u alliance%s)', mobName, #tickets, #tickets == 1 and '' or 's'))

    for _, ticket in ipairs(tickets) do
        if ticket.key ~= winnerTicket.key then
            notify(ticket.player, string.format('Your group was not successful in the lottery for %s. (%u alliances)', mobName, #tickets))
        end
    end
end

xi.ixi20HnmClaim.beginLottery = function(mob, durationMs, filterFn)
    if mob:getLocalVar('[ixi20Claim]shielding') == 1 then
        return
    end

    durationMs = durationMs or xi.ixi20HnmClaim.shieldMs()
    mob:setPriorityRender(true)
    startShield(mob, durationMs)

    mob:timer(durationMs, function(mobArg)
        if not mobArg or not mobArg:isAlive() then
            return
        end

        local tickets = collectAllianceTickets(mobArg, filterFn)
        endShield(mobArg)
        resolveLottery(mobArg, tickets)
    end)
end

xi.ixi20HnmClaim.attach = function(mob, opts)
    opts = opts or {}
    local durationMs = opts.shieldMs or xi.ixi20HnmClaim.shieldMs()
    local filterFn   = opts.filterFn
    local prefix     = opts.listenerPrefix or 'IXI20_HNM_CLAIM'

    mob:addListener('SPAWN', prefix .. '_SPAWN', function(mobArg)
        xi.ixi20HnmClaim.beginLottery(mobArg, durationMs, filterFn)
    end)

    mob:addListener('TAKE_DAMAGE', prefix .. '_HIT', function(mobArg, amount, attacker)
        if amount <= 0 or mobArg:getLocalVar('[ixi20Claim]shielding') == 1 then
            return
        end

        local player = attacker and (attacker:isPC() and attacker or (attacker.getMaster and attacker:getMaster()))
        local winnerKey = mobArg:getLocalVar('[ixi20Claim]winnerKey')
        if winnerKey == 0 then
            if player and player:isPC() and (not filterFn or filterFn(player)) then
                xi.ixi20HnmClaim.beginLottery(mobArg, durationMs, filterFn)
            end

            return
        end

        if player and player:isPC() and xi.ixi20Hnm.inAlliance(player, winnerKey) then
            mobArg:setLocalVar('[ixi20Claim]lastHit', GetSystemTime())
        end
    end)

    mob:addListener('COMBAT_TICK', prefix .. '_IDLE', function(mobArg)
        if mobArg:getLocalVar('[ixi20Claim]shielding') == 1 then
            return
        end

        local lastHit   = mobArg:getLocalVar('[ixi20Claim]lastHit')
        local winnerKey = mobArg:getLocalVar('[ixi20Claim]winnerKey')
        if winnerKey == 0 or lastHit == 0 or not mobArg:isEngaged() then
            return
        end

        if GetSystemTime() - lastHit < xi.ixi20HnmClaim.idleSeconds() then
            return
        end

        xi.ixi20Hnm.forEachEnmity(mobArg, function(member)
            if member:isPC() then
                member:printToPlayer(string.format('%s\'s claim has dropped after idle time.', mobArg:getPacketName()), xi.msg.channel.SYSTEM_3)
            end
        end)

        clearEnmity(mobArg)
        xi.ixi20HnmClaim.beginLottery(mobArg, durationMs, filterFn)
    end)
end

return xi.ixi20HnmClaim
