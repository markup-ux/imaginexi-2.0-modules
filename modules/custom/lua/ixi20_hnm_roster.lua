-----------------------------------
-- Shared world-HNM allowlist for Imagine XI 2.0 difficulty / claim modules.
-- Instance copies (Nyzul, Everbloom, Boyahda Fafnir) are excluded.
-----------------------------------
xi = xi or {}
xi.ixi20Hnm = xi.ixi20Hnm or {}

-- itemPop: retail ??? trade. Do not auto-spawn on map start.
-- timed: world window. Fast death respawn + restart spawn.
-- add: Kirin / pet copy. No difficulty, claim, or lockout.
-- event: Strange Happenings / other scripted copy. Skip packages.
xi.ixi20Hnm.worldTargets =
{
    { zone = 'Dragons_Aery',           mob = 'Fafnir',             itemPop = true },
    { zone = 'Dragons_Aery',           mob = 'Nidhogg',            itemPop = true },
    { zone = 'Valley_of_Sorrows',      mob = 'Adamantoise',        itemPop = true },
    { zone = 'Valley_of_Sorrows',      mob = 'Aspidochelone',      itemPop = true },
    { zone = 'Behemoths_Dominion',     mob = 'Behemoth',           itemPop = true },
    { zone = 'Behemoths_Dominion',     mob = 'King_Behemoth',      itemPop = true },
    { zone = 'RuAun_Gardens',          mob = 'Genbu',              itemPop = true },
    { zone = 'RuAun_Gardens',          mob = 'Seiryu',             itemPop = true },
    { zone = 'RuAun_Gardens',          mob = 'Byakko',             itemPop = true },
    { zone = 'RuAun_Gardens',          mob = 'Suzaku',             itemPop = true },
    { zone = 'The_Shrine_of_RuAvitau', mob = 'Genbu',              add = true },
    { zone = 'The_Shrine_of_RuAvitau', mob = 'Seiryu',             add = true },
    { zone = 'The_Shrine_of_RuAvitau', mob = 'Byakko',             add = true },
    { zone = 'The_Shrine_of_RuAvitau', mob = 'Suzaku',             add = true },
    { zone = 'The_Shrine_of_RuAvitau', mob = 'Kirin',              itemPop = true },
    { zone = 'Attohwa_Chasm',          mob = 'Tiamat',             timed = true },
    { zone = 'Uleguerand_Range',       mob = 'Jormungand',         timed = true },
    { zone = 'King_Ranperres_Tomb',    mob = 'Vrtra',              timed = true },
    { zone = 'Sauromugue_Champaign',   mob = 'Roc',                timed = true },
    { zone = 'Rolanberry_Fields',      mob = 'Simurgh',            timed = true },
    { zone = 'Mount_Zhayolm',          mob = 'Cerberus',           timed = true },
    { zone = 'Caedarva_Mire',          mob = 'Khimaira',           timed = true },
    { zone = 'Garlaige_Citadel',       mob = 'Serket',             timed = true },
    { zone = 'FeiYin',                 mob = 'Capricious_Cassie',  timed = true },
    { zone = 'Jugner_Forest',          mob = 'King_Arthro',        timed = true },
    { zone = 'Labyrinth_of_Onzozo',    mob = 'Lord_of_Onzozo',     timed = true },
}

xi.ixi20Hnm.zoneId =
{
    Dragons_Aery           = xi.zone.DRAGONS_AERY,
    Valley_of_Sorrows      = xi.zone.VALLEY_OF_SORROWS,
    Behemoths_Dominion     = xi.zone.BEHEMOTHS_DOMINION,
    RuAun_Gardens          = xi.zone.RUAUN_GARDENS,
    The_Shrine_of_RuAvitau = xi.zone.THE_SHRINE_OF_RUAVITAU,
    Attohwa_Chasm          = xi.zone.ATTOHWA_CHASM,
    Uleguerand_Range       = xi.zone.ULEGUERAND_RANGE,
    King_Ranperres_Tomb    = xi.zone.KING_RANPERRES_TOMB,
    Sauromugue_Champaign   = xi.zone.SAUROMUGUE_CHAMPAIGN,
    Rolanberry_Fields      = xi.zone.ROLANBERRY_FIELDS,
    Mount_Zhayolm          = xi.zone.MOUNT_ZHAYOLM,
    Caedarva_Mire          = xi.zone.CAEDARVA_MIRE,
    Garlaige_Citadel       = xi.zone.GARLAIGE_CITADEL,
    FeiYin                 = xi.zone.FEIYIN,
    Jugner_Forest          = xi.zone.JUGNER_FOREST,
    Labyrinth_of_Onzozo    = xi.zone.LABYRINTH_OF_ONZOZO,
}

xi.ixi20Hnm.isPackageTarget = function(target)
    return target and not target.add and not target.event
end

xi.ixi20Hnm.targetKey = function(zoneName, mobName)
    return zoneName .. ':' .. mobName
end

xi.ixi20Hnm.isItemPop = function(zoneName, mobName)
    for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
        if target.zone == zoneName and target.mob == mobName then
            return target.itemPop == true
        end
    end

    return false
end

xi.ixi20Hnm.isTimed = function(zoneName, mobName)
    for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
        if target.zone == zoneName and target.mob == mobName then
            return target.timed == true
        end
    end

    return false
end

xi.ixi20Hnm.overridePath = function(zoneName, mobName, hook)
    return string.format('xi.zones.%s.mobs.%s.%s', zoneName, mobName, hook)
end

xi.ixi20Hnm.forEachEnmity = function(mob, fn)
    local list = mob:getEnmityList()
    if not list then
        return
    end

    for _, entry in pairs(list) do
        local member = type(entry) == 'table' and (entry.entity or entry) or entry
        if member then
            fn(member)
        end
    end
end

xi.ixi20Hnm.allianceKey = function(player)
    local key = player:getID()
    local alliance = player:getAlliance()
    if not alliance then
        return key
    end

    for _, member in pairs(alliance) do
        if member and member:isPC() then
            key = math.min(key, member:getID())
        end
    end

    return key
end

xi.ixi20Hnm.inAlliance = function(player, allianceKey)
    return player and player:isPC() and xi.ixi20Hnm.allianceKey(player) == allianceKey
end

return xi.ixi20Hnm
