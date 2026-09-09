-----------------------------------
-- Fame from XP-credited beastmen kills (Imagine XI 1.0 port).
-- Canonical conquest region -> home-nation fame. Not conquest ownership.
-- Jeuno / Selbina-Rabao are LSB-derived and are not written here.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobs')
-----------------------------------

local m = Module:new('ixi20_conquest_fame')

local function settings()
    return xi.settings and xi.settings.main or {}
end

local function killFameEnabled()
    return settings().IMAGINEXI_CONQUEST_FAME ~= false
end

local function isPlayer(entity)
    return entity ~= nil and entity.isPC ~= nil and entity:isPC()
end

local abysseaZoneToFameArea =
{
    [xi.zone.ABYSSEA_KONSCHTAT]  = xi.fameArea.ABYSSEA_KONSCHTAT,
    [xi.zone.ABYSSEA_TAHRONGI]   = xi.fameArea.ABYSSEA_TAHRONGI,
    [xi.zone.ABYSSEA_LA_THEINE]  = xi.fameArea.ABYSSEA_LATHEINE,
    [xi.zone.ABYSSEA_MISAREAUX]  = xi.fameArea.ABYSSEA_MISAREAUX,
    [xi.zone.ABYSSEA_VUNKERL]    = xi.fameArea.ABYSSEA_VUNKERL,
    [xi.zone.ABYSSEA_ATTOHWA]    = xi.fameArea.ABYSSEA_ATTOHWA,
    [xi.zone.ABYSSEA_ALTEPA]     = xi.fameArea.ABYSSEA_ALTEPA,
    [xi.zone.ABYSSEA_GRAUBERG]   = xi.fameArea.ABYSSEA_GRAUBERG,
    [xi.zone.ABYSSEA_ULEGUERAND] = xi.fameArea.ABYSSEA_ULEGUERAND,
}

-- Fixed home-nation mapping. Independent of current conquest owner.
local regionToFameArea =
{
    [xi.region.RONFAURE]         = xi.fameArea.SANDORIA,
    [xi.region.ZULKHEIM]         = xi.fameArea.SANDORIA,
    [xi.region.NORVALLEN]        = xi.fameArea.SANDORIA,
    [xi.region.FAUREGANDI]       = xi.fameArea.SANDORIA,
    [xi.region.VALDEAUNIA]       = xi.fameArea.SANDORIA,
    [xi.region.TAVNAZIANARCH]    = xi.fameArea.SANDORIA,
    [xi.region.RONFAURE_FRONT]   = xi.fameArea.SANDORIA,
    [xi.region.NORVALLEN_FRONT]  = xi.fameArea.SANDORIA,
    [xi.region.FAUREGANDI_FRONT] = xi.fameArea.SANDORIA,
    [xi.region.VALDEAUNIA_FRONT] = xi.fameArea.SANDORIA,

    [xi.region.GUSTABERG]        = xi.fameArea.BASTOK,
    [xi.region.DERFLAND]         = xi.fameArea.BASTOK,
    [xi.region.QUFIMISLAND]      = xi.fameArea.BASTOK,
    [xi.region.KUZOTZ]           = xi.fameArea.BASTOK,
    [xi.region.VOLLBOW]          = xi.fameArea.BASTOK,
    [xi.region.MOVALPOLOS]       = xi.fameArea.BASTOK,
    [xi.region.GUSTABERG_FRONT]  = xi.fameArea.BASTOK,
    [xi.region.DERFLAND_FRONT]   = xi.fameArea.BASTOK,

    [xi.region.SARUTABARUTA]     = xi.fameArea.WINDURST,
    [xi.region.KOLSHUSHU]        = xi.fameArea.WINDURST,
    [xi.region.ARAGONEU]         = xi.fameArea.WINDURST,
    [xi.region.LITELOR]          = xi.fameArea.WINDURST,
    [xi.region.ELSHIMO_LOWLANDS] = xi.fameArea.WINDURST,
    [xi.region.ELSHIMO_UPLANDS]  = xi.fameArea.WINDURST,
    [xi.region.TULIA]            = xi.fameArea.WINDURST,
    [xi.region.SARUTA_FRONT]     = xi.fameArea.WINDURST,
    [xi.region.ARAGONEAU_FRONT]  = xi.fameArea.WINDURST,
}

local fameAreaNames =
{
    [xi.fameArea.SANDORIA]           = "San d'Oria",
    [xi.fameArea.BASTOK]             = 'Bastok',
    [xi.fameArea.WINDURST]           = 'Windurst',
    [xi.fameArea.JEUNO]              = 'Jeuno',
    [xi.fameArea.SELBINA_RABAO]      = 'Selbina / Rabao',
    [xi.fameArea.NORG]               = 'Norg',
    [xi.fameArea.ABYSSEA_KONSCHTAT]  = 'Abyssea - Konschtat',
    [xi.fameArea.ABYSSEA_TAHRONGI]   = 'Abyssea - Tahrongi',
    [xi.fameArea.ABYSSEA_LATHEINE]   = 'Abyssea - La Theine',
    [xi.fameArea.ABYSSEA_MISAREAUX]  = 'Abyssea - Misareaux',
    [xi.fameArea.ABYSSEA_VUNKERL]    = 'Abyssea - Vunkerl',
    [xi.fameArea.ABYSSEA_ATTOHWA]    = 'Abyssea - Attohwa',
    [xi.fameArea.ABYSSEA_ALTEPA]     = 'Abyssea - Altepa',
    [xi.fameArea.ABYSSEA_GRAUBERG]   = 'Abyssea - Grauberg',
    [xi.fameArea.ABYSSEA_ULEGUERAND] = 'Abyssea - Uleguerand',
    [xi.fameArea.ADOULIN]            = 'Adoulin',
}

local function fameAmountForMob(mob)
    return math.min(12, math.max(4, math.floor(mob:getMainLvl() / 6) + 2))
end

local function resolveFameArea(player)
    local abysseaFameId = abysseaZoneToFameArea[player:getZoneID()]
    if abysseaFameId then
        return abysseaFameId
    end

    local region = player:getCurrentRegion()
    local conquestFameArea = regionToFameArea[region]
    if conquestFameArea then
        return conquestFameArea
    end

    if region == xi.region.SANDORIA then
        return xi.fameArea.SANDORIA
    elseif region == xi.region.BASTOK then
        return xi.fameArea.BASTOK
    elseif region == xi.region.WINDURST then
        return xi.fameArea.WINDURST
    elseif region == xi.region.ADOULIN_ISLANDS or region == xi.region.EAST_ULBUKA then
        return xi.fameArea.ADOULIN
    end

    return nil
end

local function tryGrantKillFame(mob, player)
    if not killFameEnabled() or not isPlayer(player) then
        return
    end

    if mob:getEcosystem() ~= xi.ecosystem.BEASTMEN then
        return
    end

    if mob:getAllegiance() == xi.allegiance.PLAYER then
        return
    end

    if not player:checkKillCredit(mob) then
        return
    end

    local fameArea = resolveFameArea(player)
    if not fameArea then
        return
    end

    local oldFameLevel = player:getFameLevel(fameArea)
    player:addFame(fameArea, fameAmountForMob(mob))
    local newFameLevel = player:getFameLevel(fameArea)

    if newFameLevel > oldFameLevel then
        local fameAreaName = fameAreaNames[fameArea] or 'Unknown'
        player:printToPlayer(string.format('Your reputation in %s has increased to fame level %u!', fameAreaName, newFameLevel), xi.msg.channel.SYSTEM_3)
    end
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    tryGrantKillFame(mob, player)
end)

xi.module.registerCommand('fame', {
    cmdprops =
    {
        permission = 0,
        parameters = '',
    },
    onTrigger = function(player)
        if not isPlayer(player) then
            return
        end

        local rankPoints = xi.data and xi.data.fame and xi.data.fame.rankPoints or {}

        player:printToPlayer(string.format('Fame report for %s:', player:getName()), xi.msg.channel.SYSTEM_3)

        for fameArea = 0, 15 do
            local areaName = fameAreaNames[fameArea] or ('AREA_' .. tostring(fameArea))
            local fame = player:getFame(fameArea)
            local level = player:getFameLevel(fameArea)
            local nextPoints = rankPoints[level + 1]
            local line

            if nextPoints and fame < nextPoints then
                line = string.format('  %-22s  fame %5u   level %u  (%u to next)', areaName, fame, level, nextPoints - fame)
            else
                line = string.format('  %-22s  fame %5u   level %u', areaName, fame, level)
            end

            player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
        end
    end,
})
