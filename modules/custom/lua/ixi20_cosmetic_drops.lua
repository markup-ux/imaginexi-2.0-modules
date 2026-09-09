-----------------------------------
-- Cosmetic gear on EXP-eligible kills (Imagine XI 1.0 port).
-- One item per kill. Race + ownership weighted. NMs included.
-- Deposited to the recipient's wardrobe (not inventory / treasure pool).
-- Pool is a curated ID list (stock SQL). Do not rebuild from live jobs after all-jobs SQL.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_cosmetic_drops')

-- 1.0 drop pool plus 2.0 costumes that have models (Ilm set, Poroggo Fleece).
-- Racial starters (12631-12637, 12754-12760, 12883-12889, 13005-13011) stay out.
-- Unimplemented 2.0 placeholders and gem/sin armor sets stay out.
local COSMETIC_ITEM_IDS =
{
    10250, 10251, 10252, 10253, 10254, 10256, 10257, 10258, 10259, 10260, 10261, 10262, 10263, 10264, 10265, 10266,
    10267, 10268, 10269, 10270, 10271, 10293, 10330, 10331, 10332, 10333, 10334, 10335, 10336, 10337, 10338, 10339,
    10340, 10341, 10342, 10343, 10344, 10345, 10382, 10383, 10384, 10385, 10429, 10430, 10431, 10432, 10433, 10446,
    10447, 10593, 10594, 10595, 10596, 10875, 11265, 11266, 11267, 11268, 11269, 11270, 11271, 11272, 11273, 11274,
    11275, 11276, 11277, 11278, 11279, 11280, 11290, 11300, 11301, 11316, 11317, 11318, 11319, 11320, 11322, 11323,
    11324, 11326, 11327, 11328, 11355, 11356, 11357, 11358, 11403, 11490, 11491, 11499, 11500, 11811, 11812, 11861,
    11862, 11965, 11966, 11967, 11968, 12523, 12551, 12679, 12807, 12935, 13810, 13819, 13820, 13821, 13822, 13842,
    13917, 13948, 14169, 14171, 14173, 14176, 14395, 14400, 14428, 14429, 14430, 14450, 14451, 14452, 14453, 14454,
    14455, 14456, 14457, 14458, 14459, 14460, 14461, 14462, 14463, 14471, 14472, 14519, 14520, 14532, 14533, 14534,
    14535, 14584, 15008, 15043, 15044, 15045, 15046, 15047, 15048, 15049, 15050, 15051, 15177, 15178, 15179, 15198,
    15199, 15204, 15212, 15213, 15408, 15409, 15410, 15411, 15412, 15413, 15414, 15415, 15416, 15417, 15418, 15419,
    15420, 15421, 15423, 15424, 15752, 15753, 15754, 16075, 16076, 16118, 16119, 16120, 16321, 16322, 16323, 16324,
    16325, 16326, 16327, 16328, 16329, 16330, 16331, 16332, 16333, 16334, 16335, 16336, 16378, 23730, 23731, 23753,
    23754, 23790, 23791, 23792, 23793, 23794, 23795, 23796, 23800, 23803, 23804, 23805, 23807, 23808, 23809, 25585,
    25586, 25587, 25604, 25606, 25607, 25608, 25632, 25633, 25637, 25638, 25639, 25645, 25648, 25649, 25650, 25652,
    25657, 25658, 25669, 25670, 25671, 25672, 25673, 25674, 25675, 25677, 25678, 25679, 25711, 25712, 25713, 25714,
    25715, 25722, 25726, 25734, 25735, 25736, 25737, 25738, 25739, 25740, 25741, 25742, 25743, 25744, 25755, 25756,
    25757, 25758, 25759, 25774, 25775, 25776, 25777, 25778, 25814, 25817, 25838, 25839, 25850, 25857, 25909, 25910,
    25911, 25939, 26514, 26517, 26518, 26520, 26521, 26523, 26524, 26545, 26693, 26694, 26703, 26704, 26705, 26706,
    26707, 26708, 26717, 26718, 26719, 26720, 26728, 26729, 26730, 26738, 26739, 26788, 26789, 26798, 26799, 26889,
    26890, 26946, 26954, 26955, 26956, 26957, 26964, 26965, 26966, 26967, 26968, 26974, 26975, 27110, 27111, 27112,
    27281, 27291, 27292, 27293, 27294, 27296, 27297, 27325, 27326, 27455, 27467, 27468, 27714, 27715, 27716, 27717,
    27718, 27726, 27727, 27733, 27734, 27756, 27757, 27758, 27759, 27760, 27765, 27803, 27804, 27805, 27806, 27854,
    27855, 27859, 27860, 27866, 27867, 27872, 27873, 27879, 27880, 27898, 27899, 27902, 27904, 27905, 27906, 27911,
    27923, 28023, 28024, 28063, 28086, 28087, 28088, 28089, 28149, 28150, 28185, 28186, 28187, 28302, 28303, 28324,
    28325, 28326,
}

local WARDROBES =
{
    { loc = xi.inv.WARDROBE,  name = 'Wardrobe' },
    { loc = xi.inv.WARDROBE2, name = 'Wardrobe 2' },
    { loc = xi.inv.WARDROBE3, name = 'Wardrobe 3' },
    { loc = xi.inv.WARDROBE4, name = 'Wardrobe 4' },
    { loc = xi.inv.WARDROBE5, name = 'Wardrobe 5' },
    { loc = xi.inv.WARDROBE6, name = 'Wardrobe 6' },
    { loc = xi.inv.WARDROBE7, name = 'Wardrobe 7' },
    { loc = xi.inv.WARDROBE8, name = 'Wardrobe 8' },
}

local function itemLabel(itemId)
    local item = GetReadOnlyItem(itemId)
    local raw  = item and item.getName and item:getName() or nil
    if not raw or raw == '' then
        return string.format('#%u', itemId)
    end

    return (raw:gsub('_', ' '):gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest
    end))
end

local function tellPlayer(player, text)
    player:printToPlayer(text, xi.msg.channel.SYSTEM_3)
end

local function addToWardrobe(player, itemId)
    if not Ixi20AddItemToContainer then
        return nil, 'unavailable'
    end

    for i = 1, #WARDROBES do
        local entry = WARDROBES[i]
        if player:getFreeSlotsCount(entry.loc) > 0 and Ixi20AddItemToContainer(player, itemId, entry.loc) then
            return entry.name
        end
    end

    return nil, 'full'
end

local function grantCosmetic(player, itemId)
    local wardrobeName, reason = addToWardrobe(player, itemId)
    if wardrobeName then
        tellPlayer(player, string.format('Obtained: %s. Stored in %s.', itemLabel(itemId), wardrobeName))
        return true
    end

    if player:getFreeSlotsCount() > 0 and player:addItem(itemId, true) then
        if reason == 'full' then
            tellPlayer(player, string.format('Obtained: %s. Stored in inventory (wardrobes are full).', itemLabel(itemId)))
        else
            tellPlayer(player, string.format('Obtained: %s. Stored in inventory.', itemLabel(itemId)))
        end

        return true
    end

    tellPlayer(player, string.format('Could not store %s -- wardrobes and inventory are full.', itemLabel(itemId)))
    return false
end

local function dropEnabled()
    local settings = xi.settings and xi.settings.main
    if settings and settings.IMAGINEXI_COSMETIC_DROP_ENABLED == false then
        return false
    end

    return true
end

local function dropChance()
    local settings = xi.settings and xi.settings.main
    local chance = settings and settings.IMAGINEXI_COSMETIC_DROP_CHANCE or 10
    return math.max(0, math.min(100, chance))
end

local function collectPartyMembers(player)
    local members = {}
    local zoneId = player:getZoneID()
    local party = player:getParty()

    if party then
        for _, member in ipairs(party) do
            if member and member:isPC() and member:getZoneID() == zoneId then
                table.insert(members, member)
            end
        end
    end

    if #members == 0 then
        table.insert(members, player)
    end

    return members
end

local function pickRecipient(player, itemId)
    local members = collectPartyMembers(player)
    local function eligible(member)
        return member:canEquipItem(itemId) and not member:hasItem(itemId)
    end

    if eligible(player) then
        return player
    end

    for i = 1, #members do
        if eligible(members[i]) then
            return members[i]
        end
    end

    return player
end

local function pooledItemIds(player)
    local seen = {}
    local pool = player:getTreasurePool()
    if not pool then
        return seen
    end

    local items = pool:getItems()
    if not items then
        return seen
    end

    for _, entry in ipairs(items) do
        if entry and entry.id and entry.id ~= 0 then
            seen[entry.id] = true
        end
    end

    return seen
end

-- Prefer cosmetics nobody in party owns. Skip pool dupes and fully-owned items.
local function pickPartyWeightedCosmetic(player)
    local members = collectPartyMembers(player)
    local alreadyPooled = pooledItemIds(player)
    local weighted = {}
    local totalWeight = 0

    for i = 1, #COSMETIC_ITEM_IDS do
        local itemId = COSMETIC_ITEM_IDS[i]
        if not alreadyPooled[itemId] then
            local wearers = 0
            local owners = 0
            local nonOwners = 0

            for j = 1, #members do
                local member = members[j]
                if member:canEquipItem(itemId) then
                    wearers = wearers + 1
                    if member:hasItem(itemId) then
                        owners = owners + 1
                    else
                        nonOwners = nonOwners + 1
                    end
                end
            end

            if wearers > 0 and nonOwners > 0 then
                local weight = owners == 0 and (nonOwners + wearers * 2) or nonOwners
                table.insert(weighted, { itemId = itemId, weight = weight })
                totalWeight = totalWeight + weight
            end
        end
    end

    if totalWeight <= 0 or #weighted == 0 then
        return 0
    end

    local roll = math.randomInt(1, totalWeight)
    for i = 1, #weighted do
        local entry = weighted[i]
        if roll <= entry.weight then
            return entry.itemId
        end

        roll = roll - entry.weight
    end

    return weighted[#weighted].itemId
end

local function canDropCosmetic(mob, player)
    if not player or not player:isPC() then
        return false
    end

    if mob:getCallForHelpFlag() then
        return false
    end

    if mob:getMobMod(xi.mobMod.NO_DROPS) ~= 0 then
        return false
    end

    if mob:isMobType(xi.mobType.BATTLEFIELD) then
        return false
    end

    if player:isInDynamis() then
        return false
    end

    if player:getCurrentRegion() == xi.region.LUMORIA then
        return false
    end

    if player:checkDifficulty(mob) <= xi.mobDifficulty.TOO_WEAK then
        return false
    end

    if mob:getMobMod(xi.mobMod.EXP_BONUS) <= -100 then
        return false
    end

    return true
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if not isKiller or not dropEnabled() then
        return
    end

    if not canDropCosmetic(mob, player) then
        return
    end

    if math.randomInt(1, 100) > dropChance() then
        return
    end

    local itemId = pickPartyWeightedCosmetic(player)
    if itemId ~= 0 then
        grantCosmetic(pickRecipient(player, itemId), itemId)
    end
end)
