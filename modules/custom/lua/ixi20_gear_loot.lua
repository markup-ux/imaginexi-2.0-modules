-----------------------------------
-- Imagine XI 2.0 gear loot (helper; not a Module).
-- Decent Challenge+ kills, any zone. Starter/pantheon through 20; shop gear after.
-- Florist flowers quests consume drop on their own DC+ roll.
-- After a ding, DC+ kills fill each unowned slot at that level: A+ weapons/shields, then ammo, then armor.
-- Required by ixi20_gil_economy. No chase / AF / relic / Perdu / sky / HNM.
-----------------------------------
xi = xi or {}
xi.imagine_gear_loot = xi.imagine_gear_loot or {}

local M = xi.imagine_gear_loot
M.shopGear = require('modules/custom/lua/ixi20_shop_gear')

M.CVAR_BLU_FOCUS  = 'IMAGINEXI_BLU_LOOT_FOCUS'
M.CVAR_JOB_CRATE  = 'IXI20_JOB_CRATE'
M.CVAR_CATCHUP    = 'IXI20_GEAR_CATCH'
M.CVAR_CATCHUP_ARMOR = 'IXI20_GEAR_CATCH_ARM'
M.CVAR_LAST_LVL   = 'IXI20_GEAR_LAST_LVL'
M.DEFAULT_MAX_LEVEL = 20
M.DEFAULT_CATCHUP_KILLS = 5

-- Pantheon Abyssea +15 (req 15). Freya's (req 35) is not in this pool.
M.pantheon =
{
    anu =
    {
        [xi.slot.HEAD]  = { 16097 },
        [xi.slot.BODY]  = { 14559 },
        [xi.slot.HANDS] = { 14974 },
        [xi.slot.LEGS]  = { 15638 },
        [xi.slot.FEET]  = { 15724 },
    },
    nemain =
    {
        [xi.slot.HEAD]  = { 16101 },
        [xi.slot.BODY]  = { 14563 },
        [xi.slot.HANDS] = { 14978 },
        [xi.slot.LEGS]  = { 15642 },
        [xi.slot.FEET]  = { 15728 },
    },
    enyo =
    {
        [xi.slot.HEAD]  = { 16085 },
        [xi.slot.BODY]  = { 14547 },
        [xi.slot.HANDS] = { 14962 },
        [xi.slot.LEGS]  = { 15626 },
        [xi.slot.FEET]  = { 15712 },
    },
    njord =
    {
        [xi.slot.HEAD]  = { 16089 },
        [xi.slot.BODY]  = { 14551 },
        [xi.slot.HANDS] = { 14966 },
        [xi.slot.LEGS]  = { 15630 },
        [xi.slot.FEET]  = { 15716 },
    },
    hoshikazu =
    {
        [xi.slot.BODY]  = { 14555 },
        [xi.slot.HANDS] = { 14970 },
        [xi.slot.LEGS]  = { 15634 },
    },
}

M.tunicCaster =
{
    [xi.slot.HEAD]  = { 12496, 12495 }, -- Copper Hairpin, Silver Hairpin
    [xi.slot.BODY]  = { 12609 },        -- Black Tunic
    [xi.slot.HANDS] = { 12749, 12704 }, -- Scentless Armlets, Bronze Mittens
    [xi.slot.LEGS]  = { 15611, 12832 }, -- Sturdy Slacks, Bronze Subligar
    [xi.slot.FEET]  = { 13052, 12960 }, -- Light Soleas, Bronze Leggings
}

M.accessoryEarly =
{
    [xi.slot.RING1] = { 15546, 11654 }, -- Fasting, Puffin
    [xi.slot.EAR1]  = { 13375, 14803 }, -- Knowledge, Optical
    [xi.slot.WAIST] = { 13192 },        -- Leather Belt
}

-- Florist-shop flowers quests consume (city flower quests, Wandering Souls).
-- `want` is how many a player can hold before the extra DC+ roll skips it.
M.questFlowers =
{
    { itemId = 941, minLevel = 1, want = 4 },  -- red_rose
    { itemId = 948, minLevel = 1, want = 8 },  -- carnation (Nokkhi quivers)
    { itemId = 949, minLevel = 1, want = 4 },  -- rain_lily (Flagellant's Rope)
    { itemId = 951, minLevel = 1, want = 8 },  -- wijnruit (toolbags)
    { itemId = 956, minLevel = 1, want = 4 },  -- lilac (Flower Child, WotG)
    { itemId = 957, minLevel = 1, want = 4 },  -- amaryllis (A Lady's Heart)
    { itemId = 958, minLevel = 1, want = 4 },  -- marguerite (Growing Flowers)
}

M.starterMeleeArmor =
{
    [xi.slot.HEAD]  = { 12440, 12496 }, -- Leather Bandana, Copper Hairpin
    [xi.slot.BODY]  = { 12576, 12577 }, -- Bronze Harness, Brass Harness
    [xi.slot.HANDS] = { 12696, 12704 }, -- Leather Gloves, Bronze Mittens
    [xi.slot.LEGS]  = { 12832, 12824 }, -- Bronze Subligar, Leather Trousers
    [xi.slot.FEET]  = { 12952, 12960 }, -- Leather Highboots, Bronze Leggings
}

-- Combat A+ ranks from ixi20_combat_skill_ranks.sql (1 = A+).
M.aPlusSkills =
{
    [xi.job.WAR] = { xi.skill.DAGGER, xi.skill.SWORD, xi.skill.GREAT_SWORD, xi.skill.AXE, xi.skill.GREAT_AXE, xi.skill.SCYTHE, xi.skill.POLEARM, xi.skill.CLUB, xi.skill.STAFF, xi.skill.ARCHERY, xi.skill.MARKSMANSHIP, xi.skill.SHIELD },
    [xi.job.MNK] = { xi.skill.HAND_TO_HAND, xi.skill.STAFF },
    [xi.job.WHM] = { xi.skill.CLUB, xi.skill.STAFF, xi.skill.SHIELD },
    [xi.job.BLM] = { xi.skill.SCYTHE, xi.skill.CLUB, xi.skill.STAFF },
    [xi.job.RDM] = { xi.skill.DAGGER, xi.skill.SWORD, xi.skill.CLUB, xi.skill.STAFF, xi.skill.SHIELD },
    [xi.job.THF] = { xi.skill.DAGGER, xi.skill.ARCHERY, xi.skill.MARKSMANSHIP, xi.skill.THROWING, xi.skill.SHIELD },
    [xi.job.PLD] = { xi.skill.SWORD, xi.skill.GREAT_SWORD, xi.skill.POLEARM, xi.skill.CLUB, xi.skill.SHIELD },
    [xi.job.DRK] = { xi.skill.SWORD, xi.skill.GREAT_SWORD, xi.skill.AXE, xi.skill.GREAT_AXE, xi.skill.SCYTHE, xi.skill.MARKSMANSHIP, xi.skill.SHIELD },
    [xi.job.BST] = { xi.skill.AXE, xi.skill.SCYTHE },
    [xi.job.BRD] = { xi.skill.DAGGER, xi.skill.SWORD },
    [xi.job.RNG] = { xi.skill.DAGGER, xi.skill.AXE, xi.skill.ARCHERY, xi.skill.MARKSMANSHIP, xi.skill.THROWING },
    [xi.job.SAM] = { xi.skill.POLEARM, xi.skill.GREAT_KATANA, xi.skill.ARCHERY },
    [xi.job.NIN] = { xi.skill.DAGGER, xi.skill.KATANA, xi.skill.GREAT_KATANA, xi.skill.THROWING },
    [xi.job.DRG] = { xi.skill.POLEARM },
    [xi.job.SMN] = { xi.skill.STAFF },
    [xi.job.BLU] = { xi.skill.SWORD, xi.skill.THROWING },
    [xi.job.COR] = { xi.skill.DAGGER, xi.skill.SWORD, xi.skill.MARKSMANSHIP },
    [xi.job.PUP] = { xi.skill.HAND_TO_HAND },
    [xi.job.DNC] = { xi.skill.DAGGER, xi.skill.THROWING },
    [xi.job.SCH] = { xi.skill.CLUB, xi.skill.STAFF },
    [xi.job.GEO] = { xi.skill.CLUB, xi.skill.STAFF },
    [xi.job.RUN] = { xi.skill.SWORD, xi.skill.GREAT_SWORD },
}

M.starterWeaponBySkill =
{
    [xi.skill.HAND_TO_HAND] = { 16405 },           -- Cat Baghnakhs
    [xi.skill.DAGGER]       = { 16448 },           -- Bronze Dagger
    [xi.skill.SWORD]        = { 16535 },           -- Bronze Sword
    [xi.skill.GREAT_SWORD]  = { 16583 },           -- Claymore
    [xi.skill.AXE]          = { 16640 },           -- Bronze Axe
    [xi.skill.GREAT_AXE]    = { 16704 },           -- Butterfly Axe
    [xi.skill.SCYTHE]       = { 16768 },           -- Bronze Zaghnal
    [xi.skill.POLEARM]      = { 16833 },           -- Bronze Spear
    [xi.skill.KATANA]       = { 16896 },           -- Kunai
    [xi.skill.GREAT_KATANA] = { 17809 },           -- Mumeito
    [xi.skill.CLUB]         = { 17024, 17049 },    -- Ash Club, Maple Wand
    [xi.skill.STAFF]        = { 17088 },           -- Ash Staff
    [xi.skill.ARCHERY]      = { 17152 },           -- Shortbow
    [xi.skill.MARKSMANSHIP] = { 17216 },           -- Light Crossbow
    [xi.skill.THROWING]     = { 17280 },           -- Boomerang
}

-- Signature first weapon is kept for the job crate. A+ categories are appended for drops.
M.starterWeapons =
{
    [xi.job.WAR] = { 16640 }, -- Bronze Axe
    [xi.job.MNK] = { 16405 }, -- Cat Baghnakhs
    [xi.job.WHM] = { 17049 }, -- Maple Wand
    [xi.job.BLM] = { 17088 }, -- Ash Staff
    [xi.job.RDM] = { 16448 }, -- Bronze Dagger
    [xi.job.THF] = { 16448 },
    [xi.job.PLD] = { 16535 }, -- Bronze Sword
    [xi.job.DRK] = { 16768 }, -- Bronze Zaghnal
    [xi.job.BST] = { 16640 },
    [xi.job.BRD] = { 16448 }, -- Bronze Dagger (A+); staff/wand were not A+
    [xi.job.RNG] = { 17152 }, -- Shortbow
    [xi.job.SMN] = { 17088 },
    [xi.job.NIN] = { 16896 }, -- Kunai
    [xi.job.SAM] = { 17809 }, -- Mumeito
    [xi.job.DRG] = { 16832 }, -- Harpoon
    [xi.job.BLU] = { 16535 },
    [xi.job.COR] = { 17216 }, -- Light Crossbow
    [xi.job.PUP] = { 16405 }, -- Cat Baghnakhs
    [xi.job.DNC] = { 16448 },
    [xi.job.SCH] = { 17088 },
    [xi.job.GEO] = { 17088 },
    [xi.job.RUN] = { 16535 },
}

local function appendAPlusStarterWeapons()
    for job, skills in pairs(M.aPlusSkills) do
        local list = M.starterWeapons[job] or {}
        local have = {}
        for _, itemId in ipairs(list) do
            have[itemId] = true
        end

        for _, skill in ipairs(skills) do
            for _, itemId in ipairs(M.starterWeaponBySkill[skill] or {}) do
                if not have[itemId] then
                    table.insert(list, itemId)
                    have[itemId] = true
                end
            end
        end

        M.starterWeapons[job] = list
    end
end

appendAPlusStarterWeapons()

local casterJobs =
{
    [xi.job.WHM] = true, [xi.job.BLM] = true, [xi.job.RDM] = true,
    [xi.job.SMN] = true, [xi.job.BRD] = true, [xi.job.SCH] = true,
    [xi.job.GEO] = true,
}

local jobAbbrev =
{
    [xi.job.WAR] = 'WAR', [xi.job.MNK] = 'MNK', [xi.job.WHM] = 'WHM',
    [xi.job.BLM] = 'BLM', [xi.job.RDM] = 'RDM', [xi.job.THF] = 'THF',
    [xi.job.PLD] = 'PLD', [xi.job.DRK] = 'DRK', [xi.job.BST] = 'BST',
    [xi.job.BRD] = 'BRD', [xi.job.RNG] = 'RNG', [xi.job.SMN] = 'SMN',
    [xi.job.NIN] = 'NIN', [xi.job.SAM] = 'SAM', [xi.job.DRG] = 'DRG',
    [xi.job.BLU] = 'BLU', [xi.job.COR] = 'COR', [xi.job.PUP] = 'PUP',
    [xi.job.DNC] = 'DNC', [xi.job.SCH] = 'SCH', [xi.job.GEO] = 'GEO',
    [xi.job.RUN] = 'RUN',
}

-- Player-level bands through 20 (no zone gate). Shop catalog is used after 20.
M.levelBands =
{
    { levelMin = 1,  levelMax = 7,  pools = { 'starter', 'accessory' } },
    { levelMin = 8,  levelMax = 14, pools = { 'starter', 'tunic', 'accessory' } },
    { levelMin = 15, levelMax = 20, pools = { 'pantheon', 'accessory' } },
}

local pantheonFamilyByJob =
{
    [xi.job.WHM] = 'anu', [xi.job.BLM] = 'anu', [xi.job.RDM] = 'anu',
    [xi.job.SCH] = 'anu', [xi.job.GEO] = 'anu', [xi.job.SMN] = 'anu',
    [xi.job.BRD] = 'nemain',
    [xi.job.RNG] = 'njord', [xi.job.COR] = 'njord',
    [xi.job.NIN] = 'hoshikazu', [xi.job.SAM] = 'hoshikazu', [xi.job.THF] = 'hoshikazu',
    [xi.job.DRG] = 'hoshikazu', [xi.job.MNK] = 'hoshikazu',
}

local function estimateExpToNext(level)
    if level >= 75 then
        return 22000
    end

    return math.floor(400 + level * level * 4.5)
end

local function isCasterJob(job)
    return casterJobs[job] == true
end

local function armorPoolForJob(job)
    if isCasterJob(job) then
        return M.tunicCaster
    end

    return M.starterMeleeArmor
end

---@return integer
function M.getMaxLootLevel()
    return xi.settings.main.IMAGINEXI_GEAR_LOOT_MAX_LEVEL or M.DEFAULT_MAX_LEVEL
end

---@param player CBaseEntity
---@return integer
function M.getEffectiveLevel(player)
    return player:getMainLvl()
end

---@param player CBaseEntity
---@return string
function M.getBluLootFocus(player)
    local focus = player:getCharVar(M.CVAR_BLU_FOCUS)
    if focus == 'melee' or focus == 'mage' then
        return focus
    end

    return 'hybrid'
end

---@param player CBaseEntity
---@param focus string|nil
function M.setBluLootFocus(player, focus)
    if focus == 'melee' or focus == 'mage' or focus == 'hybrid' then
        player:setCharVar(M.CVAR_BLU_FOCUS, focus == 'hybrid' and '' or focus)
    end
end

---@param player CBaseEntity
---@return boolean
function M.hasJobCrate(player)
    local job = player:getMainJob()
    if not job or job < xi.job.WAR or job > xi.job.RUN then
        return true
    end

    local granted = player:getCharVar(M.CVAR_JOB_CRATE)
    return bit.band(granted, bit.lshift(1, job)) ~= 0
end

---@param player CBaseEntity
local function markJobCrate(player, job)
    local granted = player:getCharVar(M.CVAR_JOB_CRATE)
    player:setCharVar(M.CVAR_JOB_CRATE, bit.bor(granted, bit.lshift(1, job)))
end

-- Race armor comes from xi.player.charCreate. Job crates are weapon-only;
-- GEO also gets the lv.1 handbell.
---@param job integer
---@return integer[]
function M.getJobCrateItems(job)
    local items = {}
    local weapons = M.starterWeapons[job]
    if weapons and weapons[1] then
        table.insert(items, weapons[1])
    end

    if job == xi.job.PUP then
        table.insert(items, xi.item.ANIMATOR)
    elseif job == xi.job.GEO then
        table.insert(items, xi.item.MATRE_BELL)
    end

    return items
end

---@param player CBaseEntity
---@param itemId integer
---@return boolean
local function playerOwns(player, itemId)
    return player:hasItem(itemId) == true
end

--- One-time starter crate the first time a job is played. Not level-gated.
--- Weapon only (plus GEO bell / PUP Animator). Skips items already owned.
---@param player CBaseEntity
---@param announce boolean|nil  -- false from the C++ job-info hook (avoids spam)
---@return boolean
function M.tryGrantJobCrate(player, announce)
    if not player or not player.isPC or not player:isPC() then
        return false
    end

    if M.hasJobCrate(player) then
        return false
    end

    local job   = player:getMainJob()
    local items = M.getJobCrateItems(job)
    local needed = {}
    for _, itemId in ipairs(items) do
        if not playerOwns(player, itemId) then
            table.insert(needed, itemId)
        end
    end

    if #needed == 0 then
        markJobCrate(player, job)
        return false
    end

    if player:getFreeSlotsCount() < #needed then
        if announce ~= false then
            player:printToPlayer(
                string.format('Starter gear crate for %s waiting: free %d inventory slots.', jobAbbrev[job] or 'this job', #needed),
                xi.msg.channel.SYSTEM_3
            )
        end

        return false
    end

    for _, itemId in ipairs(needed) do
        player:addItem(itemId, true)
    end

    markJobCrate(player, job)
    player:printToPlayer(
        string.format('Starter gear crate granted for %s.', jobAbbrev[job] or 'this job'),
        xi.msg.channel.SYSTEM_3
    )
    return true
end

---@param player CBaseEntity
---@param itemId integer
---@return boolean
local function canUseUnowned(player, itemId)
    if not itemId or playerOwns(player, itemId) then
        return false
    end

    if not player:canEquipItem(itemId) then
        return false
    end

    return true
end

---@param player CBaseEntity
---@param list integer[]|nil
---@return integer|nil
local function pickUnownedFromList(player, list)
    if not list or #list == 0 then
        return nil
    end

    local fresh = {}
    for _, itemId in ipairs(list) do
        if canUseUnowned(player, itemId) then
            table.insert(fresh, itemId)
        end
    end

    return #fresh > 0 and utils.randomEntry(fresh) or nil
end

---@param player CBaseEntity
---@param slotMap table
---@return integer|nil
local function pickUnownedFromSlotMap(player, slotMap)
    if not slotMap then
        return nil
    end

    local fresh = {}
    for _, list in pairs(slotMap) do
        for _, itemId in ipairs(list) do
            if canUseUnowned(player, itemId) then
                table.insert(fresh, itemId)
            end
        end
    end

    return #fresh > 0 and utils.randomEntry(fresh) or nil
end

---@param skill integer|nil
---@return boolean
local function isInstrumentSkill(skill)
    return skill == xi.skill.STRING_INSTRUMENT
        or skill == xi.skill.WIND_INSTRUMENT
        or skill == xi.skill.SINGING
end

---@param row table
---@return boolean
local function isShieldRow(row)
    local skill = row[5] or 0
    return row[3] == xi.slot.SUB and skill <= 0
end

---@param row table
---@return boolean
local function isWeaponOrShieldRow(row)
    local slot  = row[3]
    local skill = row[5] or 0
    if isInstrumentSkill(skill) then
        return false
    end

    if slot == xi.slot.MAIN or slot == xi.slot.RANGED then
        return skill > 0
    end

    return isShieldRow(row)
end

---@param row table
---@return boolean
local function isAmmoRow(row)
    local skill = row[5] or 0
    return row[3] == xi.slot.AMMO
        and (skill == xi.skill.ARCHERY or skill == xi.skill.MARKSMANSHIP)
end

local ARMOR_SLOT_ORDER =
{
    xi.slot.HEAD,
    xi.slot.BODY,
    xi.slot.HANDS,
    xi.slot.LEGS,
    xi.slot.FEET,
}

local ACCESSORY_SLOT_ORDER =
{
    xi.slot.NECK,
    xi.slot.WAIST,
    xi.slot.EAR1,
    xi.slot.RING1,
    xi.slot.BACK,
}

---@return integer
local function catchupKills()
    return xi.settings.main.IMAGINEXI_GEAR_LOOT_CATCHUP_KILLS or M.DEFAULT_CATCHUP_KILLS
end

---@param job integer
---@param level integer
---@param tries integer
---@return integer
local function packCatchup(job, level, tries)
    return bit.bor(
        bit.band(tries, 0xFF),
        bit.lshift(bit.band(level, 0xFF), 8),
        bit.lshift(bit.band(job, 0xFF), 16)
    )
end

---@param value integer
---@return table|nil
local function unpackCatchup(value)
    if not value or value == 0 then
        return nil
    end

    return
    {
        tries = bit.band(value, 0xFF),
        level = bit.band(bit.rshift(value, 8), 0xFF),
        job   = bit.band(bit.rshift(value, 16), 0xFF),
    }
end

---@param player CBaseEntity
---@param poolName string
---@return integer|nil
local function pickFromPool(player, poolName)
    local job = player:getMainJob()

    if poolName == 'tunic' then
        return pickUnownedFromSlotMap(player, M.tunicCaster)
    elseif poolName == 'starter' then
        local weapon = pickUnownedFromList(player, M.starterWeapons[job])
        if weapon then
            return weapon
        end

        return pickUnownedFromSlotMap(player, armorPoolForJob(job))
    elseif poolName == 'pantheon' then
        local family = pantheonFamilyByJob[job] or 'enyo'
        if job == xi.job.BLU then
            family = M.getBluLootFocus(player) == 'mage' and 'anu' or 'hoshikazu'
        end

        return pickUnownedFromSlotMap(player, M.pantheon[family])
    elseif poolName == 'accessory' then
        return pickUnownedFromSlotMap(player, M.accessoryEarly)
    end

    return nil
end

---@return number
local function dropRate()
    return xi.settings.main.IMAGINEXI_GEAR_LOOT_FIELD_RATE or 0.15
end

---@return number
local function questFodderRate()
    return xi.settings.main.IMAGINEXI_QUEST_FODDER_RATE or 0.10
end

---@param player CBaseEntity
---@param list table
---@return integer|nil
local function pickFodderFromList(player, list)
    local level = M.getEffectiveLevel(player)
    local candidates = {}
    local total = 0
    for _, row in ipairs(list) do
        if level >= row.minLevel then
            local have = player:getItemCount(row.itemId) or 0
            local need = row.want - have
            if need > 0 then
                table.insert(candidates, { itemId = row.itemId, weight = need })
                total = total + need
            end
        end
    end

    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    local acc = 0
    for _, row in ipairs(candidates) do
        acc = acc + row.weight
        if roll <= acc then
            return row.itemId
        end
    end

    return candidates[#candidates].itemId
end

---@param player CBaseEntity
---@return integer|nil
local function pickQuestFlower(player)
    return pickFodderFromList(player, M.questFlowers)
end

---@param level integer
---@return table|nil
local function bandForLevel(level)
    for _, band in ipairs(M.levelBands) do
        if level >= band.levelMin and level <= band.levelMax then
            return band
        end
    end

    return nil
end

---@param job integer
---@return integer
local function jobBit(job)
    return bit.lshift(1, job - 1)
end

---@param job integer
---@return table
local function aPlusSkillSet(job)
    local set = {}
    for _, skill in ipairs(M.aPlusSkills[job] or {}) do
        set[skill] = true
    end

    return set
end

---@param row table
---@param job integer
---@param aPlus table
---@return boolean
local function shopRowMatchesJob(row, job, aPlus)
    if isShieldRow(row) then
        return aPlus[xi.skill.SHIELD] == true and bit.band(row[4], jobBit(job)) ~= 0
    end

    local skill = row[5]
    if skill and skill > 0 then
        return aPlus[skill] == true
    end

    return bit.band(row[4], jobBit(job)) ~= 0
end

---@param player CBaseEntity
---@param row table
---@param job integer
---@param aPlus table
---@return boolean
local function shopRowEligible(player, row, job, aPlus)
    return shopRowMatchesJob(row, job, aPlus) and canUseUnowned(player, row[1])
end

---@param rows table
---@return integer|nil
local function pickWeightedShopRow(rows)
    local total = 0
    for _, row in ipairs(rows) do
        total = total + row[2]
    end

    if total <= 0 then
        local chosen = utils.randomEntry(rows)
        return chosen and chosen[1] or nil
    end

    local roll = math.random() * total
    local acc = 0
    for _, row in ipairs(rows) do
        acc = acc + row[2]
        if roll <= acc then
            return row[1]
        end
    end

    return rows[#rows][1]
end

---@param rows table
---@return table, table
local function splitWeaponArmorRows(rows)
    local weapons = {}
    local armor = {}
    for _, row in ipairs(rows) do
        if isWeaponOrShieldRow(row) or isAmmoRow(row) then
            table.insert(weapons, row)
        else
            table.insert(armor, row)
        end
    end

    return weapons, armor
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@param predicate fun(row: table): boolean
---@return integer|nil
local function pickExactLevelRows(player, level, job, predicate)
    local catalog = M.shopGear
    if not catalog or #catalog == 0 then
        return nil
    end

    local aPlus = aPlusSkillSet(job)
    local matches = {}
    for _, row in ipairs(catalog) do
        if row[2] == level and predicate(row) and shopRowEligible(player, row, job, aPlus) then
            table.insert(matches, row)
        end
    end

    return #matches > 0 and pickWeightedShopRow(matches) or nil
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@return integer|nil
local function pickExactLevelWeaponShield(player, level, job)
    return pickExactLevelRows(player, level, job, isWeaponOrShieldRow)
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@param slots integer[]
---@return integer|nil
local function pickExactLevelForSlots(player, level, job, slots)
    for _, slot in ipairs(slots) do
        local itemId = pickExactLevelRows(player, level, job, function(row)
            return row[3] == slot
        end)
        if itemId then
            return itemId
        end
    end

    return nil
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@return integer|nil
local function pickExactLevelArmor(player, level, job)
    return pickExactLevelForSlots(player, level, job, ARMOR_SLOT_ORDER)
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@return integer|nil
local function pickExactLevelAccessory(player, level, job)
    return pickExactLevelForSlots(player, level, job, ACCESSORY_SLOT_ORDER)
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@return integer|nil
local function pickUnownedAmmo(player, level, job)
    local exact = pickExactLevelRows(player, level, job, isAmmoRow)
    if exact then
        return exact
    end

    local catalog = M.shopGear
    if not catalog or #catalog == 0 then
        return nil
    end

    local aPlus = aPlusSkillSet(job)
    local bestLvl = nil
    local matches = {}
    for _, row in ipairs(catalog) do
        if isAmmoRow(row) and row[2] <= level and shopRowEligible(player, row, job, aPlus) then
            if bestLvl == nil or row[2] < bestLvl then
                bestLvl = row[2]
                matches = { row }
            elseif row[2] == bestLvl then
                table.insert(matches, row)
            end
        end
    end

    return #matches > 0 and pickWeightedShopRow(matches) or nil
end

---@param player CBaseEntity
---@param level integer
---@param job integer
---@return integer|nil
local function pickExactLevelSlotItem(player, level, job)
    return pickExactLevelWeaponShield(player, level, job)
        or pickUnownedAmmo(player, level, job)
        or pickExactLevelArmor(player, level, job)
        or pickExactLevelAccessory(player, level, job)
end

---@param player CBaseEntity
---@return integer|nil
local function pickShopGear(player)
    local catalog = M.shopGear
    if not catalog or #catalog == 0 then
        return nil
    end

    local level = M.getEffectiveLevel(player)
    local job = player:getMainJob()
    local aPlus = aPlusSkillSet(job)
    local window = xi.settings.main.IMAGINEXI_GEAR_LOOT_LEVEL_WINDOW or 10
    local minLvl = math.max(1, level - window)

    local jobMatch = {}
    local anyMatch = {}
    for _, row in ipairs(catalog) do
        local reqLvl = row[2]
        if reqLvl <= level and reqLvl >= minLvl and canUseUnowned(player, row[1]) then
            table.insert(anyMatch, row)
            if shopRowMatchesJob(row, job, aPlus) then
                table.insert(jobMatch, row)
            end
        end
    end

    local function pickPreferred(rows)
        local weapons, armor = splitWeaponArmorRows(rows)
        if #weapons > 0 then
            return pickWeightedShopRow(weapons)
        end

        if #armor > 0 then
            return pickWeightedShopRow(armor)
        end

        return nil
    end

    local chosen = pickPreferred(jobMatch) or pickPreferred(anyMatch)
    if chosen then
        return chosen
    end

    local bestLvl = 0
    local fallback = {}
    for _, row in ipairs(catalog) do
        if row[2] <= level and canUseUnowned(player, row[1]) then
            if row[2] > bestLvl then
                bestLvl = row[2]
                fallback = { row }
            elseif row[2] == bestLvl then
                table.insert(fallback, row)
            end
        end
    end

    local jobFallback = {}
    for _, row in ipairs(fallback) do
        if shopRowMatchesJob(row, job, aPlus) then
            table.insert(jobFallback, row)
        end
    end

    return pickPreferred(jobFallback) or pickPreferred(fallback)
end

---@param player CBaseEntity
---@return integer|nil
local function pickLevelBandItem(player)
    local band = bandForLevel(M.getEffectiveLevel(player))
    if not band then
        return nil
    end

    local pools = {}
    for i, name in ipairs(band.pools) do
        pools[i] = name
    end

    for i = #pools, 2, -1 do
        local j = math.random(i)
        pools[i], pools[j] = pools[j], pools[i]
    end

    for _, poolName in ipairs(pools) do
        local itemId = pickFromPool(player, poolName)
        if itemId then
            return itemId
        end
    end

    return nil
end

---@param player CBaseEntity
---@return integer|nil
local function pickPreferredGear(player)
    local level = M.getEffectiveLevel(player)
    local job   = player:getMainJob()
    local exact = pickExactLevelSlotItem(player, level, job)
    if exact then
        return exact
    end

    if level <= M.getMaxLootLevel() then
        local bandItem = pickLevelBandItem(player)
        if bandItem then
            return bandItem
        end
    end

    return pickShopGear(player)
end

---@param player CBaseEntity
---@param announce boolean|nil
---@return boolean
local function giveLootItem(player, itemId, announce)
    if not itemId then
        return false
    end

    if player:addItem(itemId, true) then
        if announce ~= false then
            player:messageSpecial(zones[player:getZoneID()].text.ITEM_OBTAINED, itemId)
        end

        return true
    end

    return false
end

---@param player CBaseEntity
---@return boolean
local function tryQuestFlowerDrop(player)
    if math.random() > questFodderRate() then
        return false
    end

    if player:getFreeSlotsCount() < 1 then
        return false
    end

    return giveLootItem(player, pickQuestFlower(player))
end

---@param player CBaseEntity
---@param cvar string
---@param picker fun(player: CBaseEntity, level: integer, job: integer): integer|nil
---@param level integer
---@param job integer
local function queueOneCatchup(player, cvar, picker, level, job)
    if picker(player, level, job) then
        player:setCharVar(cvar, packCatchup(job, level, catchupKills()))
        return
    end

    local pending = unpackCatchup(player:getCharVar(cvar))
    if pending and pending.job == job and pending.tries > 0 then
        return
    end

    player:setCharVar(cvar, 0)
end

---@param player CBaseEntity
function M.queueWeaponCatchup(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    local level = M.getEffectiveLevel(player)
    local job   = player:getMainJob()
    player:setCharVar(M.CVAR_LAST_LVL, level)
    queueOneCatchup(player, M.CVAR_CATCHUP, pickExactLevelWeaponShield, level, job)
    queueOneCatchup(player, M.CVAR_CATCHUP_ARMOR, pickExactLevelArmor, level, job)
end

---@param player CBaseEntity
function M.ensureCatchupTracking(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if player:getCharVar(M.CVAR_LAST_LVL) == 0 then
        player:setCharVar(M.CVAR_LAST_LVL, M.getEffectiveLevel(player))
    end
end

---@param player CBaseEntity
function M.onPlayerLevelUp(player)
    M.queueWeaponCatchup(player)
end

---@param player CBaseEntity
local function syncLevelCatchup(player)
    local level = M.getEffectiveLevel(player)
    local last  = player:getCharVar(M.CVAR_LAST_LVL)
    if last == 0 then
        player:setCharVar(M.CVAR_LAST_LVL, level)
        return
    end

    if level > last then
        M.queueWeaponCatchup(player)
    end
end

---@param player CBaseEntity
---@param cvar string
---@param picker fun(player: CBaseEntity, level: integer, job: integer): integer|nil
---@return boolean
local function tryOneCatchup(player, cvar, picker)
    local state = unpackCatchup(player:getCharVar(cvar))
    if not state or state.tries <= 0 then
        return false
    end

    if player:getMainJob() ~= state.job then
        return false
    end

    local itemId = picker(player, state.level, state.job)
    if not itemId then
        player:setCharVar(cvar, 0)
        return false
    end

    if player:getFreeSlotsCount() < 1 then
        return true
    end

    if giveLootItem(player, itemId) then
        if not picker(player, state.level, state.job) then
            player:setCharVar(cvar, 0)
        end

        return true
    end

    local remaining = state.tries - 1
    player:setCharVar(cvar, remaining > 0 and packCatchup(state.job, state.level, remaining) or 0)
    return true
end

--- Fill the next unowned exact-level slot. Weapons first, then each armor slot, then accessories.
---@param player CBaseEntity
---@return boolean
local function tryExactLevelSlotDrop(player)
    local level  = M.getEffectiveLevel(player)
    local job    = player:getMainJob()
    local itemId = pickExactLevelSlotItem(player, level, job)
    if not itemId then
        return false
    end

    if player:getFreeSlotsCount() < 1 then
        return true
    end

    return giveLootItem(player, itemId)
end

--- True when this kill was used for an exact-level slot fill.
---@param player CBaseEntity
---@return boolean
local function tryCatchupDrop(player)
    if tryOneCatchup(player, M.CVAR_CATCHUP, pickExactLevelWeaponShield) then
        return true
    end

    if tryOneCatchup(player, M.CVAR_CATCHUP_ARMOR, pickExactLevelArmor) then
        return true
    end

    return tryExactLevelSlotDrop(player)
end

---@param mob CBaseEntity
---@param player CBaseEntity
function M.onMobDeath(mob, player)
    if not xi.settings.main.IMAGINEXI_GEAR_LOOT_ENABLED then
        return
    end

    if not player or not player:isPC() then
        return
    end

    if not player:checkKillCredit(mob) then
        return
    end

    if mob:isNM() then
        M.onNmDeath(mob, player)
        return
    end

    if player:checkDifficulty(mob) < xi.mobDifficulty.DECENT_CHALLENGE then
        return
    end

    syncLevelCatchup(player)
    if not tryCatchupDrop(player) and math.random() <= dropRate() then
        giveLootItem(player, pickPreferredGear(player))
    end

    tryQuestFlowerDrop(player)
end

---@param mob CBaseEntity
---@param player CBaseEntity
function M.onNmDeath(mob, player)
    if not xi.settings.main.IMAGINEXI_NM_XP_BURST_ENABLED then
        return
    end

    local mobId = mob:getID()
    local varName = string.format('IX_NM_%u', mobId)
    local kills = player:getCharVar(varName)
    player:setCharVar(varName, kills + 1)

    local fraction = kills == 0 and (xi.settings.main.IMAGINEXI_NM_XP_BURST_FIRST or 0.85)
        or (xi.settings.main.IMAGINEXI_NM_XP_BURST_REPEAT or 0.35)

    local burst = math.min(
        xi.settings.main.IMAGINEXI_NM_XP_BURST_CAP or 15000,
        math.floor(estimateExpToNext(player:getMainLvl()) * fraction)
    )

    if burst > 0 then
        player:addExp(burst)
    end
end

-- Called from C++ job-info hook (mog-house job change / login). Silent if inventory is full.
function Ixi20GrantJobCrate(player)
    M.tryGrantJobCrate(player, false)
end

return xi.imagine_gear_loot
