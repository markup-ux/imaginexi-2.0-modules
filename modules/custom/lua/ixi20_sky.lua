-----------------------------------
-- Imagine XI 2.0 Sky (Tu'Lia) fight layer.
-- Garden gods stay on gem + stone pops. Kirin summons the garden gods
-- (stats, skill lists, drop tables), not the empty pet copies.
-- Small groups keep the melt cap; healer pressure stays full strength.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_hnm_roster')
require('modules/custom/lua/ixi20_hnm_anti_melt')
require('modules/custom/lua/ixi20_healer_pressure')
-----------------------------------

local m = Module:new('ixi20_sky')

xi = xi or {}
xi.ixi20Sky = xi.ixi20Sky or {}

local GARDEN_GODS =
{
    Genbu  = true,
    Seiryu = true,
    Byakko = true,
    Suzaku = true,
}

-- Retail garden pools (Ru'Aun YAML). Kirin adds are promoted to these.
local GARDEN_HP =
{
    Genbu  = 19000,
    Seiryu = 22000,
    Byakko = 22000,
    Suzaku = 25000,
}

local GARDEN_SKILL =
{
    Genbu  = 277,
    Seiryu = 278,
    Byakko = 279,
    Suzaku = 280,
}

-- Shrine Kirin (Deadly Hold / Tail Swing / Heat Breath / sandstorm / whirlwind).
-- GM Home copies spawn from Fafnir's group and would otherwise use Dragon Breath
-- / Horrid Roar, which have no Kirin animation.
local KIRIN_SKILL = 281

local RATE =
{
    [xi.drop_rate.GUARANTEED]  = 1000,
    [xi.drop_rate.VERY_COMMON] = 240,
    [xi.drop_rate.COMMON]      = 150,
    [xi.drop_rate.UNCOMMON]    = 100,
    [xi.drop_rate.RARE]        = 50,
    [xi.drop_rate.VERY_RARE]   = 10,
}

local function abjGroup(a, b, c, d)
    return
    {
        { item = a, weight = 31 },
        { item = b, weight = 23 },
        { item = c, weight = 23 },
        { item = d, weight = 23 },
    }
end

local GARDEN_LOOT =
{
    Genbu =
    {
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.SEAL_OF_GENBU },
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.ARCTIC_WIND },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SEAL_OF_GENBU },
        { rate = xi.drop_rate.COMMON,     item = xi.item.GENBUS_SHIELD },
        { rate = xi.drop_rate.COMMON,     item = xi.item.GENBUS_KABUTO },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.VIAL_OF_BLACK_BEETLE_BLOOD },
        { rate = xi.drop_rate.COMMON,     item = xi.item.VENOMOUS_CLAW },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.ADAMANTOISE_SHELL },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.PIECE_OF_OXBLOOD },
        { rate = xi.drop_rate.RARE,       item = xi.item.ADAMAN_INGOT },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.DIVINE_LOG },
        { rate = xi.drop_rate.GUARANTEED, oneOf = abjGroup(xi.item.WYRMAL_ABJURATION_FEET, xi.item.AQUARIAN_ABJURATION_HANDS, xi.item.AQUARIAN_ABJURATION_HEAD, xi.item.MARTIAL_ABJURATION_HANDS) },
        { rate = xi.drop_rate.UNCOMMON,   oneOf = abjGroup(xi.item.WYRMAL_ABJURATION_FEET, xi.item.AQUARIAN_ABJURATION_HANDS, xi.item.AQUARIAN_ABJURATION_HEAD, xi.item.MARTIAL_ABJURATION_HANDS) },
    },
    Seiryu =
    {
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.SEAL_OF_SEIRYU },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SEAL_OF_SEIRYU },
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.EAST_WIND },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SEIRYUS_SWORD },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SEIRYUS_KOTE },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.DRAGON_TALON },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.VIAL_OF_DRAGON_BLOOD },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.SLICE_OF_DRAGON_MEAT },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.SQUARE_OF_DAMASCENE_CLOTH },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.SPOOL_OF_MALBORO_FIBER },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.DRAGON_HEART },
        { rate = xi.drop_rate.GUARANTEED, oneOf = abjGroup(xi.item.WYRMAL_ABJURATION_HANDS, xi.item.AQUARIAN_ABJURATION_LEGS, xi.item.DRYADIC_ABJURATION_HEAD, xi.item.MARTIAL_ABJURATION_HEAD) },
        { rate = xi.drop_rate.UNCOMMON,   oneOf = abjGroup(xi.item.WYRMAL_ABJURATION_HANDS, xi.item.AQUARIAN_ABJURATION_LEGS, xi.item.DRYADIC_ABJURATION_HEAD, xi.item.MARTIAL_ABJURATION_HEAD) },
    },
    Byakko =
    {
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.SEAL_OF_BYAKKO },
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.ZEPHYR },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SEAL_OF_BYAKKO },
        { rate = xi.drop_rate.COMMON,     item = xi.item.BYAKKOS_AXE },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.DIVINE_LOG },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.SPOOL_OF_MALBORO_FIBER },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.BEHEMOTH_HIDE },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.BEHEMOTH_HIDE },
        { rate = xi.drop_rate.COMMON,     item = xi.item.BYAKKOS_HAIDATE },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.DAMASCUS_INGOT },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.PIECE_OF_OXBLOOD },
        { rate = xi.drop_rate.GUARANTEED, oneOf = abjGroup(xi.item.NEPTUNAL_ABJURATION_HANDS, xi.item.AQUARIAN_ABJURATION_HEAD, xi.item.DRYADIC_ABJURATION_LEGS, xi.item.EARTHEN_ABJURATION_FEET) },
        { rate = xi.drop_rate.UNCOMMON,   oneOf = abjGroup(xi.item.NEPTUNAL_ABJURATION_HANDS, xi.item.AQUARIAN_ABJURATION_HEAD, xi.item.DRYADIC_ABJURATION_LEGS, xi.item.EARTHEN_ABJURATION_FEET) },
    },
    Suzaku =
    {
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.SEAL_OF_SUZAKU },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SEAL_OF_SUZAKU },
        { rate = xi.drop_rate.GUARANTEED, item = xi.item.ANTARCTIC_WIND },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SUZAKUS_SUNE_ATE },
        { rate = xi.drop_rate.COMMON,     item = xi.item.SUZAKUS_SCYTHE },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.SQUARE_OF_DAMASCENE_CLOTH },
        { rate = xi.drop_rate.RARE,       item = xi.item.ORICHALCUM_INGOT },
        { rate = xi.drop_rate.RARE,       item = xi.item.SQUARE_OF_SHINING_CLOTH },
        { rate = xi.drop_rate.VERY_RARE,  item = xi.item.VENOMOUS_CLAW },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.VIAL_OF_BLACK_BEETLE_BLOOD },
        { rate = xi.drop_rate.COMMON,     item = xi.item.LOCK_OF_SIRENS_HAIR },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.LOCK_OF_SIRENS_HAIR },
        { rate = xi.drop_rate.UNCOMMON,   item = xi.item.LOCK_OF_SIRENS_HAIR },
        { rate = xi.drop_rate.GUARANTEED, oneOf = abjGroup(xi.item.NEPTUNAL_ABJURATION_FEET, xi.item.AQUARIAN_ABJURATION_LEGS, xi.item.DRYADIC_ABJURATION_HANDS, xi.item.EARTHEN_ABJURATION_HEAD) },
        { rate = xi.drop_rate.UNCOMMON,   oneOf = abjGroup(xi.item.NEPTUNAL_ABJURATION_FEET, xi.item.AQUARIAN_ABJURATION_LEGS, xi.item.DRYADIC_ABJURATION_HANDS, xi.item.EARTHEN_ABJURATION_HEAD) },
    },
}

local APEX =
{
    Genbu =
    {
        xi.mobSkill.HARDEN_SHELL_1,
        xi.mobSkill.AQUA_BREATH_1,
        xi.mobSkill.TORTOISE_STOMP_1,
        xi.mobSkill.EARTH_BREATH_1,
    },
    Seiryu =
    {
        xi.mobSkill.DISPELLING_WIND,
        xi.mobSkill.DREAD_SHRIEK,
        xi.mobSkill.RADIANT_BREATH,
        xi.mobSkill.TAIL_CRUSH,
    },
    Byakko =
    {
        xi.mobSkill.ROAR_1,
        xi.mobSkill.RAZOR_FANG_1,
        xi.mobSkill.CLAW_CYCLONE_1,
    },
    Suzaku =
    {
        399, -- Blind Vortex
        400, -- Giga Scream
        401, -- Dread Dive
        403, -- Stormwind
    },
    Kirin =
    {
        xi.mobSkill.HEAT_BREATH_1,
        xi.mobSkill.GREAT_SANDSTORM_1,
        xi.mobSkill.GREAT_WHIRLWIND_1,
        xi.mobSkill.DEADLY_HOLD_1,
    },
}

local emberByMob = {}

local function setting(key, fallback)
    local map = xi.settings and xi.settings.map
    if map and map[key] ~= nil then
        return map[key]
    end

    return fallback
end

local function skyGodName(mob)
    if not mob or not mob.getName then
        return nil
    end

    local name = mob:getName():gsub('^DE_', '')
    if GARDEN_GODS[name] or name == 'Kirin' then
        return name
    end

    return nil
end

local function isTestGod(mob)
    return mob and
        (
            mob:getLocalVar('[sky]testGod') == 1 or
            (mob.getZoneID and mob:getZoneID() == xi.zone.GM_HOME)
        )
end

local function isGardenGod(mob)
    return mob and
        mob.getZoneID and
        mob:getZoneID() == xi.zone.RUAUN_GARDENS and
        GARDEN_GODS[skyGodName(mob)] == true
end

local function isShrineKirin(mob)
    return skyGodName(mob) == 'Kirin' and
        mob.getZoneID and
        (
            mob:getZoneID() == xi.zone.THE_SHRINE_OF_RUAVITAU or
            isTestGod(mob)
        )
end

local function isShrineAdd(mob)
    return GARDEN_GODS[skyGodName(mob)] == true and
        mob.getZoneID and
        (
            mob:getZoneID() == xi.zone.THE_SHRINE_OF_RUAVITAU or
            isTestGod(mob)
        )
end

xi.ixi20Sky.godName = skyGodName

local function isSkyGod(mob)
    return isGardenGod(mob) or isShrineAdd(mob)
end

local function rolled(rate)
    return math.random(1, 1000) <= (RATE[rate] or 0)
end

local function pickWeighted(entries)
    local total = 0
    for _, entry in ipairs(entries) do
        total = total + (entry.weight or 1)
    end

    local roll = math.random(1, math.max(1, total))
    local acc  = 0
    for _, entry in ipairs(entries) do
        acc = acc + (entry.weight or 1)
        if roll <= acc then
            return entry.item
        end
    end

    return entries[1] and entries[1].item
end

local function firstEnmityPlayer(mob)
    local found
    if xi.ixi20Hnm and xi.ixi20Hnm.forEachEnmity then
        xi.ixi20Hnm.forEachEnmity(mob, function(member)
            if not found and member:isPC() then
                found = member
            end
        end)
    end

    return found
end

local function giveGardenLoot(mob, player)
    if mob:getLocalVar('[sky]lootDone') == 1 then
        return
    end

    local table = GARDEN_LOOT[skyGodName(mob)]
    if not table or not player or not player.isPC or not player:isPC() then
        return
    end

    mob:setLocalVar('[sky]lootDone', 1)

    for _, entry in ipairs(table) do
        if rolled(entry.rate) then
            local itemId = entry.item
            if entry.oneOf then
                itemId = pickWeighted(entry.oneOf)
            end

            if itemId then
                player:addTreasure(itemId, mob)
            end
        end
    end
end

local function stampSkyLockout(mob, player)
    if not xi.ixi20HnmAccess or not xi.ixi20HnmAccess.lockAlliance then
        return
    end

    local recipient = player
    if not recipient or not recipient.isPC or not recipient:isPC() then
        recipient = firstEnmityPlayer(mob)
    end

    if recipient then
        xi.ixi20HnmAccess.lockAlliance(recipient, mob)
    end
end

local function telegraph(mob, message)
    if not xi.ixi20Hnm or not xi.ixi20Hnm.forEachEnmity then
        return
    end

    xi.ixi20Hnm.forEachEnmity(mob, function(member)
        if member:isPC() then
            member:printToPlayer(message, xi.msg.channel.SYSTEM_3, '')
        end
    end)
end

local function nearbyPlayers(mob, range)
    local targets = {}
    local seen    = {}

    if not xi.ixi20Hnm or not xi.ixi20Hnm.forEachEnmity then
        return targets
    end

    xi.ixi20Hnm.forEachEnmity(mob, function(member)
        if
            member:isPC() and
            (not member.isTrust or not member:isTrust()) and
            not seen[member:getID()] and
            member:getHP() > 0 and
            mob:checkDistance(member) <= range
        then
            seen[member:getID()] = true
            targets[#targets + 1] = member
        end
    end)

    return targets
end

local function applyApex(mob, skills)
    mob:setLocalVar('[hnmApex]replaceDefault', 1)
    for i = 1, 12 do
        mob:setLocalVar('[hnmApex]skill' .. i, skills and skills[i] or 0)
    end
end

local function fireDamage(mob, member, fraction)
    local raw = math.floor(member:getMaxHP() * fraction)
    raw = utils.clamp(utils.handleStoneskin(member, raw, xi.attackType.MAGICAL), 0, 99999)
    if raw > 0 then
        member:takeDamage(raw, mob, xi.attackType.MAGICAL, xi.damageType.FIRE)
    end
end

-- Genbu: physical carapace until a weaponskill or magic lands.
-- Autos bounce (UDMGPHYS -4000). A WS still cracks it even if the
-- hit is reduced to 0 — melee is not gated on a mage.
local function breakCarapace(mob)
    if mob:getLocalVar('[sky]carapace') ~= 1 then
        return
    end

    mob:addMod(xi.mod.UDMGPHYS, 4000)
    mob:setLocalVar('[sky]carapace', 0)
    telegraph(mob, 'Genbu\'s carapace shatters!')
end

local function tryCarapace(mob)
    local now = GetSystemTime()
    if mob:getLocalVar('[sky]carapace') == 1 then
        if now >= mob:getLocalVar('[sky]carapaceUntil') then
            breakCarapace(mob)
        end

        return
    end

    if now < mob:getLocalVar('[sky]carapaceNext') then
        return
    end

    mob:setLocalVar('[sky]carapace', 1)
    mob:setLocalVar('[sky]carapaceUntil', now + 20)
    mob:setLocalVar('[sky]carapaceNext', now + 45)
    mob:addMod(xi.mod.UDMGPHYS, -4000)
    telegraph(mob, 'Genbu withdraws into its carapace. A weaponskill or magic will crack it.')
end

-- Seiryu: punish stacked players.
local function tryGale(mob)
    local now = GetSystemTime()
    if now < mob:getLocalVar('[sky]galeNext') then
        return
    end

    mob:setLocalVar('[sky]galeNext', now + 40)

    local players = nearbyPlayers(mob, 25)
    local clumped = {}
    local marked  = {}

    for i = 1, #players do
        for j = i + 1, #players do
            if players[i]:checkDistance(players[j]) <= 6 then
                marked[players[i]:getID()] = players[i]
                marked[players[j]:getID()] = players[j]
            end
        end
    end

    for _, member in pairs(marked) do
        clumped[#clumped + 1] = member
        member:addStatusEffect(xi.effect.SILENCE, { power = 1, duration = 12 })
    end

    if #clumped >= 2 then
        telegraph(mob, 'The wyrm punishes those who huddle together!')
    end
end

-- Byakko: lock onto the healthiest player.
local function tryPredator(mob)
    local now = GetSystemTime()
    if now < mob:getLocalVar('[sky]predatorNext') then
        return
    end

    mob:setLocalVar('[sky]predatorNext', now + 35)

    local mark
    local bestHp = -1
    for _, member in ipairs(nearbyPlayers(mob, 25)) do
        if member:getHP() > bestHp then
            bestHp = member:getHP()
            mark   = member
        end
    end

    if not mark then
        return
    end

    mob:addEnmity(mark, 1, 8000)
    mob:addMod(xi.mod.ATT, 150)
    mob:setLocalVar('[sky]predatorAtt', 1)
    mob:timer(12000, function(mobArg)
        if mobArg and mobArg:getLocalVar('[sky]predatorAtt') == 1 then
            mobArg:addMod(xi.mod.ATT, -150)
            mobArg:setLocalVar('[sky]predatorAtt', 0)
        end
    end)

    telegraph(mob, string.format('Byakko\'s gaze locks onto %s!', mark:getName()))
end

-- Suzaku: lingering fire under its feet.
local function tryEmber(mob)
    local now = GetSystemTime()
    local ember = emberByMob[mob:getID()]

    if
        (not ember or now >= ember.untilTime) and
        now >= mob:getLocalVar('[sky]emberNext')
    then
        emberByMob[mob:getID()] =
        {
            x         = mob:getXPos(),
            y         = mob:getYPos(),
            z         = mob:getZPos(),
            untilTime = now + 18,
            lastTick  = 0,
        }
        mob:setLocalVar('[sky]emberNext', now + 22)
        telegraph(mob, 'Suzaku scorches the earth!')
        ember = emberByMob[mob:getID()]
    end

    if not ember or now >= ember.untilTime then
        emberByMob[mob:getID()] = nil
        return
    end

    if ember.lastTick > 0 and now - ember.lastTick < 3 then
        return
    end

    ember.lastTick = now

    for _, member in ipairs(nearbyPlayers(mob, 30)) do
        local dx = member:getXPos() - ember.x
        local dz = member:getZPos() - ember.z
        if (dx * dx + dz * dz) <= (7 * 7) then
            fireDamage(mob, member, 0.08)
            member:addStatusEffect(xi.effect.BURN, { power = 20, tick = 3, duration = 18 })
        end
    end
end

local GOD_ORDER = { 'Genbu', 'Seiryu', 'Byakko', 'Suzaku' }

local function livingKirinAdds(mob)
    local count = 0
    local id    = mob:getID()
    local zone  = mob.getZone and mob:getZone()

    for i, name in ipairs(GOD_ORDER) do
        local add = GetMobByID(id + i)
        if add and add:isAlive() then
            count = count + 1
        elseif zone and zone.queryEntitiesByName then
            local found = zone:queryEntitiesByName('DE_' .. name)
            if found then
                for _, entity in pairs(found) do
                    if entity and entity.isAlive and entity:isAlive() then
                        count = count + 1
                        break
                    end
                end
            end
        end
    end

    return count
end

local function addNameByIndex(_, index)
    return GOD_ORDER[index] or 'a celestial guardian'
end

xi.ixi20Sky.godOrder = GOD_ORDER

local function updateKirinWard(mob)
    local living = livingKirinAdds(mob)
    local last   = mob:getLocalVar('[sky]kirinAdds')
    if living == last then
        return
    end

    local delta = (living - last) * -1200
    if delta ~= 0 then
        mob:addMod(xi.mod.UDMGPHYS, delta)
        mob:addMod(xi.mod.UDMGMAGIC, delta)
        mob:addMod(xi.mod.UDMGRANGE, delta)
        mob:addMod(xi.mod.UDMGBREATH, delta)
    end

    mob:setLocalVar('[sky]kirinAdds', living)
    if living > last then
        telegraph(mob, string.format('Kirin draws strength from %u guardian%s.', living, living == 1 and '' or 's'))
    elseif living == 0 and last > 0 then
        telegraph(mob, 'Kirin\'s borrowed ward fades.')
    end
end

function xi.ixi20Sky.hpMultiplier(mob)
    if isSkyGod(mob) then
        return setting('IMAGINEXI_SKY_HP_MULTIPLIER', 1.75)
    end

    if isShrineKirin(mob) then
        return setting('IMAGINEXI_KIRIN_HP_MULTIPLIER', 2.0)
    end

    return nil
end

function xi.ixi20Sky.lockoutSeconds(mob)
    if isSkyGod(mob) then
        return setting('IMAGINEXI_SKY_LOCKOUT_SECONDS', 3 * 3600)
    end

    return nil
end

function xi.ixi20Sky.fullPressure(mob)
    return isSkyGod(mob) or isShrineKirin(mob)
end

function xi.ixi20Sky.pulseInterval(mob, defaultInterval)
    if isSkyGod(mob) and mob:getHPP() <= 50 then
        return math.max(30, math.floor(defaultInterval * 0.6))
    end

    return defaultInterval
end

function xi.ixi20Sky.blocksPixie(player)
    if not player or not player.isPC or not player:isPC() then
        return false
    end

    if setting('IMAGINEXI_HNM_BLOCK_PIXIE', true) == false then
        return false
    end

    if not xi.ixi20Hnm then
        return false
    end

    local zoneId = player:getZoneID()
    local zone   = player.getZone and player:getZone()
    if not zone or not zone.queryEntitiesByName then
        return false
    end

    if zoneId == xi.zone.GM_HOME then
        for _, name in ipairs({ 'Genbu', 'Seiryu', 'Byakko', 'Suzaku', 'Kirin' }) do
            local mobs = zone:queryEntitiesByName('DE_' .. name)
            if mobs then
                for _, mob in pairs(mobs) do
                    if
                        mob and
                        mob.isAlive and
                        mob:isAlive() and
                        mob.isEngaged and
                        mob:isEngaged() and
                        mob.checkDistance and
                        mob:checkDistance(player) <= 50
                    then
                        return true
                    end
                end
            end
        end
    end

    for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
        if
            xi.ixi20Hnm.isPackageTarget(target) and
            (target.itemPop or target.timed) and
            xi.ixi20Hnm.zoneId[target.zone] == zoneId
        then
            local mobs = zone:queryEntitiesByName(target.mob)
            if mobs then
                for _, mob in pairs(mobs) do
                    if
                        mob and
                        mob.isAlive and
                        mob:isAlive() and
                        mob.isEngaged and
                        mob:isEngaged() and
                        mob.checkDistance and
                        mob:checkDistance(player) <= 50
                    then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function xi.ixi20Sky.onGardenTick(mob)
    if not mob or not mob:isAlive() or not mob:isEngaged() then
        return
    end

    local name = skyGodName(mob)
    if name == 'Genbu' then
        tryCarapace(mob)
    elseif name == 'Seiryu' then
        tryGale(mob)
    elseif name == 'Byakko' then
        tryPredator(mob)
    elseif name == 'Suzaku' then
        tryEmber(mob)
    end
end

function xi.ixi20Sky.onGardenSpawn(mob)
    if not isSkyGod(mob) then
        return
    end

    if mob:getLocalVar('[sky]carapace') == 1 then
        mob:addMod(xi.mod.UDMGPHYS, 4000)
        mob:setLocalVar('[sky]carapace', 0)
    end

    if mob:getLocalVar('[sky]predatorAtt') == 1 then
        mob:addMod(xi.mod.ATT, -150)
        mob:setLocalVar('[sky]predatorAtt', 0)
    end

    applyApex(mob, APEX[skyGodName(mob)])
    mob:setLocalVar('[sky]carapace', 0)
    mob:setLocalVar('[sky]carapaceNext', GetSystemTime() + 20)
    mob:setLocalVar('[sky]galeNext', GetSystemTime() + 25)
    mob:setLocalVar('[sky]predatorNext', GetSystemTime() + 20)
    mob:setLocalVar('[sky]emberNext', GetSystemTime() + 15)
    mob:setLocalVar('[sky]predatorAtt', 0)
    emberByMob[mob:getID()] = nil

    mob:removeListener('IXI20_SKY_TICK')
    mob:addListener('COMBAT_TICK', 'IXI20_SKY_TICK', function(mobArg)
        xi.ixi20Sky.onGardenTick(mobArg)
    end)

    mob:removeListener('IXI20_SKY_CARAPACE')
    mob:removeListener('IXI20_SKY_CARAPACE_WS')
    if skyGodName(mob) == 'Genbu' then
        mob:addListener('TAKE_DAMAGE', 'IXI20_SKY_CARAPACE', function(mobArg, amount, _, attackType)
            if
                mobArg:getLocalVar('[sky]carapace') == 1 and
                amount and
                amount > 0 and
                attackType == xi.attackType.MAGICAL
            then
                breakCarapace(mobArg)
            end
        end)

        -- WEAPONSKILL_TAKE fires even when UDMGPHYS zeros the hit.
        mob:addListener('WEAPONSKILL_TAKE', 'IXI20_SKY_CARAPACE_WS', function(_, defender)
            if defender and defender:getLocalVar('[sky]carapace') == 1 then
                breakCarapace(defender)
            end
        end)
    end

    mob:removeListener('IXI20_SKY_HF')
    if skyGodName(mob) == 'Seiryu' then
        mob:addListener('EFFECT_LOSE', 'IXI20_SKY_HF', function(mobArg, effect)
            if effect:getEffectType() == xi.effect.HUNDRED_FISTS then
                mobArg:setLocalVar('[sky]galeNext', 0)
                tryGale(mobArg)
            end
        end)
    end
end

function xi.ixi20Sky.onAddSpawn(mob)
    if not isShrineAdd(mob) then
        return
    end

    local name = skyGodName(mob)
    if mob:getLocalVar('[sky]promoted') ~= 1 then
        mob:setLocalVar('[sky]promoted', 1)
        mob:setLocalVar('[sky]lootDone', 0)
        mob:setMobLevel(90)
        mob:setMobMod(xi.mobMod.SKILL_LIST, GARDEN_SKILL[name] or 0)
        mob:setMobMod(xi.mobMod.NO_DROPS, 0)
        mob:setMobMod(xi.mobMod.CHECK_AS_NM, 1)

        local hp = math.max(1, math.floor((GARDEN_HP[name] or 19000) * setting('IMAGINEXI_SKY_HP_MULTIPLIER', 1.75)))
        mob:setMaxHP(hp)
        mob:setHP(hp)

        if xi.hnmAntiMelt then
            xi.hnmAntiMelt.attach(mob)
            xi.hnmAntiMelt.applyBase(mob)
        end

        if xi.healerPressure then
            xi.healerPressure.attach(mob)
            xi.healerPressure.onSpawn(mob)
        end
    end

    xi.ixi20Sky.onGardenSpawn(mob)
end

function xi.ixi20Sky.onAddDeath(mob, player)
    if not isShrineAdd(mob) then
        return
    end

    local recipient = player
    if not recipient or not recipient.isPC or not recipient:isPC() then
        recipient = firstEnmityPlayer(mob)
    end

    giveGardenLoot(mob, recipient)
    if not isTestGod(mob) then
        stampSkyLockout(mob, recipient)
    end
end

function xi.ixi20Sky.onKirinSpawn(mob)
    if not isShrineKirin(mob) then
        return
    end

    applyApex(mob, APEX.Kirin)
    mob:setMobMod(xi.mobMod.SKILL_LIST, KIRIN_SKILL)
    mob:setLocalVar('godSpawnTime', GetSystemTime() + setting('IMAGINEXI_KIRIN_FIRST_ADD_SECONDS', 60))
    mob:setLocalVar('[sky]lastAdds', 0)
    mob:setLocalVar('[sky]kirinAdds', 0)
    for i = 1, 4 do
        mob:setLocalVar('[sky]announced' .. i, 0)
    end

    mob:removeListener('IXI20_SKY_KIRIN')
    mob:addListener('COMBAT_TICK', 'IXI20_SKY_KIRIN', function(mobArg)
        if mobArg and mobArg:isAlive() and mobArg:isEngaged() then
            updateKirinWard(mobArg)
        end
    end)
end

function xi.ixi20Sky.onKirinFight(mob)
    if not isShrineKirin(mob) then
        return
    end

    local numAdds = mob:getLocalVar('numAdds')
    local last    = mob:getLocalVar('[sky]lastAdds')
    if numAdds > last then
        mob:setLocalVar('[sky]lastAdds', numAdds)
        mob:setLocalVar('godSpawnTime', GetSystemTime() + setting('IMAGINEXI_KIRIN_ADD_INTERVAL_SECONDS', 90))

        local spawned
        for i = 1, 4 do
            if
                mob:getLocalVar('add' .. i) == 1 and
                mob:getLocalVar('[sky]announced' .. i) ~= 1
            then
                mob:setLocalVar('[sky]announced' .. i, 1)
                spawned = addNameByIndex(mob, i)
            end
        end

        telegraph(mob, string.format('Kirin calls forth %s!', spawned or 'a celestial guardian'))
    end

    updateKirinWard(mob)
end

local function wrapHook(zoneName, mobName, hook, fn)
    local path = xi.ixi20Hnm.overridePath(zoneName, mobName, hook)
    m:addOverride(path, function(...)
        super(...)
        fn(...)
    end)

    xi.module.ensureTable(string.format('xi.zones.%s.mobs.%s', zoneName, mobName))
    local script = xi.zones[zoneName].mobs[mobName]
    local flag   = '_ixi20Sky_' .. hook
    if script and not script[flag] then
        local prev = script[hook]
        script[hook] = function(...)
            if prev then
                prev(...)
            end

            fn(...)
        end
        script[flag] = true
    end
end

for _, name in ipairs({ 'Genbu', 'Seiryu', 'Byakko', 'Suzaku' }) do
    wrapHook('RuAun_Gardens', name, 'onMobSpawn', function(mob)
        xi.ixi20Sky.onGardenSpawn(mob)
    end)

    wrapHook('The_Shrine_of_RuAvitau', name, 'onMobSpawn', function(mob)
        xi.ixi20Sky.onAddSpawn(mob)
    end)

    xi.module.ensureTable(string.format('xi.zones.The_Shrine_of_RuAvitau.mobs.%s', name))
    local shrineScript = xi.zones.The_Shrine_of_RuAvitau.mobs[name]
    if shrineScript and not shrineScript.onMobDeath then
        shrineScript.onMobDeath = function()
        end
    end

    wrapHook('The_Shrine_of_RuAvitau', name, 'onMobDeath', function(mob, player)
        xi.ixi20Sky.onAddDeath(mob, player)
    end)
end

wrapHook('The_Shrine_of_RuAvitau', 'Kirin', 'onMobSpawn', function(mob)
    xi.ixi20Sky.onKirinSpawn(mob)
end)

wrapHook('The_Shrine_of_RuAvitau', 'Kirin', 'onMobFight', function(mob)
    xi.ixi20Sky.onKirinFight(mob)
end)

-- Stock callPets uses dieWithOwner. These are the garden gods now, not dummy pets.
m:addOverride('xi.mob.callPets', function(mob, petIds, params)
    if isShrineKirin(mob) then
        local copy = {}
        for key, value in pairs(params or {}) do
            copy[key] = value
        end

        copy.dieWithOwner   = false
        copy.persistOnDeath = true
        params = copy
    end

    return super(mob, petIds, params)
end)
