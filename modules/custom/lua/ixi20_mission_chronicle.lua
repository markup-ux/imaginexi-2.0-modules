-----------------------------------
-- Imagine XI 2.0: missions tell the story; they do not sell the ticket.
--
-- World access (Sea, Dynamis, Assault, Salvage, Abyssea, Adoulin, sky, Tavnazia)
-- is granted on create / login. A Chronicler in the cities offers:
--   Play it            - do nothing; walk the story
--   Skip to next battle
--   Close this chapter - mark the log complete and grant its access flags
--
-- Toggle: settings.main.IMAGINEXI_STORY_OPEN_WORLD
-- Pair with FREE_COP_DYNAMIS = 1
-----------------------------------
require('modules/module_utils')
require('scripts/globals/besieged')
require('scripts/globals/icons')
require('scripts/globals/missions')
require('scripts/globals/player')
require('scripts/globals/quests')
require('scripts/missions/soa/helpers')
require('scripts/missions/wotg/helpers')
require('scripts/zones/Lower_Jeuno/Zone')
require('scripts/zones/Aht_Urhgan_Whitegate/Zone')
require('scripts/zones/Western_Adoulin/Zone')
require('scripts/zones/GM_Home/Zone')
require('scripts/zones/The_Garden_of_RuHmet/Zone')
-----------------------------------

local m = Module:new('ixi20_mission_chronicle')

local MENU_DELAY_MS = 50
local SAY           = xi.msg.channel.NS_SAY
local SYSTEM        = xi.msg.channel.SYSTEM_3

local function openWorld()
    local settings = xi.settings and xi.settings.main
    if not settings then
        return true
    end

    if settings.IMAGINEXI_STORY_OPEN_WORLD == nil then
        return true
    end

    return settings.IMAGINEXI_STORY_OPEN_WORLD
end

local function isPlayer(entity)
    return entity and entity.isPC and entity:isPC()
end

local function npcName(npc)
    if npc and npc.getPacketName then
        return npc:getPacketName()
    end

    return 'Chronicler'
end

local function say(player, npc, text)
    player:printToPlayer(text, SAY, npcName(npc))
end

local function note(player, text)
    player:printToPlayer(text, SYSTEM)
end

local function grantKeyItem(player, keyItemId)
    if keyItemId and not player:hasKeyItem(keyItemId) then
        player:addKeyItem(keyItemId)
    end
end

local function emptyCurrent(logId)
    return logId <= 2 and 65535 or 0
end

local function usesCurrentCompare(logId, missionId)
    return logId == xi.mission.log_id.COP or missionId >= 64
end

local function missionIds(logId)
    local area = xi.mission.area[logId]
    local ids  = {}

    if not area or not xi.mission.id[area] then
        return ids
    end

    for name, missionId in pairs(xi.mission.id[area]) do
        if type(missionId) == 'number' and name ~= 'NONE' then
            ids[#ids + 1] = missionId
        end
    end

    table.sort(ids)

    local unique = {}
    local last
    for _, missionId in ipairs(ids) do
        if missionId ~= last then
            unique[#unique + 1] = missionId
            last = missionId
        end
    end

    return unique
end

local function lastMissionId(logId)
    local ids = missionIds(logId)
    return ids[#ids]
end

local function clearCurrent(player, logId)
    local current = player:getCurrentMission(logId)
    if current ~= emptyCurrent(logId) then
        player:delMission(logId, current)
    end
end

local function setCurrent(player, logId, missionId)
    clearCurrent(player, logId)
    player:addMission(logId, missionId)
end

local function completeMissionId(player, logId, missionId)
    if usesCurrentCompare(logId, missionId) then
        return
    end

    if player:hasCompletedMission(logId, missionId) then
        return
    end

    setCurrent(player, logId, missionId)
    player:completeMission(logId, missionId)
end

local function nationRankForMission(missionId)
    if missionId <= 2 then
        return math.floor(missionId / 3) + 1
    elseif missionId >= 10 and missionId <= 12 then
        return 3
    elseif missionId == 13 then
        return 4
    elseif missionId >= 14 then
        return math.floor((missionId - 14) / 2) + 5
    end

    return 2
end

local function ensureNationRank(player, missionId)
    local nation = player:getNation()
    local needed = nationRankForMission(missionId)
    if player:getRank(nation) < needed then
        player:setRank(needed)
    end

    player:setRankPoints(4000)
end

local function completeLogThrough(player, logId, beforeId)
    local ids = missionIds(logId)
    local lastCompleted

    for _, missionId in ipairs(ids) do
        if beforeId and missionId >= beforeId then
            break
        end

        if usesCurrentCompare(logId, missionId) then
            lastCompleted = missionId
        else
            completeMissionId(player, logId, missionId)
            lastCompleted = missionId
        end
    end

    if lastCompleted and usesCurrentCompare(logId, lastCompleted) and (not beforeId or lastCompleted < beforeId) then
        setCurrent(player, logId, lastCompleted)
    end
end

local function closeLog(player, logId)
    local last = lastMissionId(logId)
    if not last then
        return
    end

    completeLogThrough(player, logId, nil)

    if usesCurrentCompare(logId, last) then
        setCurrent(player, logId, last)
    else
        completeMissionId(player, logId, last)
    end

    if logId <= 2 then
        player:setRank(10)
        player:setRankPoints(0)
    end
end

local function chapterClosed(player, logId)
    local last = lastMissionId(logId)
    if not last then
        return true
    end

    if usesCurrentCompare(logId, last) then
        return player:getCurrentMission(logId) >= last
    end

    return player:hasCompletedMission(logId, last)
end

local function battlePassed(player, logId, battle)
    if player:hasCompletedMission(logId, battle.missionId) then
        return true
    end

    local current = player:getCurrentMission(logId)
    if usesCurrentCompare(logId, battle.missionId) then
        return current > battle.missionId
    end

    return false
end

local ACCESS_KEY_ITEMS =
{
    xi.ki.BOARDING_PERMIT,
    xi.ki.LIGHT_OF_HOLLA,
    xi.ki.LIGHT_OF_DEM,
    xi.ki.LIGHT_OF_MEA,
    xi.ki.LIGHT_OF_VAHZL,
    xi.ki.LIGHT_OF_ALTAIEU,
    xi.ki.PRISMATIC_HOURGLASS,
    xi.ki.VIAL_OF_SHROUDED_SAND,
    xi.ki.REMNANTS_PERMIT,
    xi.ki.COSMO_CLEANSE,
    xi.ki.PIONEERS_BADGE,
    xi.ki.ADOULINIAN_CHARTER_PERMIT,
    xi.ki.PSC_WILDCAT_BADGE,
    xi.ki.IMPERIAL_ARMY_ID_TAG,
    xi.ki.TRAVERSER_STONE1,
    xi.ki.BRAND_OF_DAWN,
    xi.ki.BRAND_OF_TWILIGHT,
}

local CHAPTER_KEY_ITEMS =
{
    [xi.mission.log_id.ZILART] =
    {
        xi.ki.PRISMATIC_FRAGMENT,
    },
    [xi.mission.log_id.COP] =
    {
        xi.ki.LIGHT_OF_HOLLA,
        xi.ki.LIGHT_OF_DEM,
        xi.ki.LIGHT_OF_MEA,
        xi.ki.LIGHT_OF_VAHZL,
        xi.ki.LIGHT_OF_ALTAIEU,
        xi.ki.BRAND_OF_DAWN,
        xi.ki.BRAND_OF_TWILIGHT,
    },
    [xi.mission.log_id.TOAU] =
    {
        xi.ki.BOARDING_PERMIT,
        xi.ki.PSC_WILDCAT_BADGE,
        xi.ki.REMNANTS_PERMIT,
        xi.ki.IMPERIAL_ARMY_ID_TAG,
    },
    [xi.mission.log_id.SOA] =
    {
        xi.ki.PIONEERS_BADGE,
        xi.ki.ADOULINIAN_CHARTER_PERMIT,
    },
}

local function grantChapterKeyItems(player, logId)
    local list = CHAPTER_KEY_ITEMS[logId]
    if not list then
        return
    end

    for _, keyItemId in ipairs(list) do
        grantKeyItem(player, keyItemId)
    end
end

local function grantAbysseaAccess(player)
    local abyssea = xi.questLog.ABYSSEA
    local journey = xi.quest.id.abyssea.A_JOURNEY_BEGINS
    local truth   = xi.quest.id.abyssea.THE_TRUTH_BECKONS
    local dawn    = xi.quest.id.abyssea.DAWN_OF_DEATH

    if player:getQuestStatus(abyssea, journey) ~= xi.questStatus.QUEST_COMPLETED then
        if player:getQuestStatus(abyssea, journey) == xi.questStatus.QUEST_AVAILABLE then
            player:addQuest(abyssea, journey)
        end

        player:completeQuest(abyssea, journey)
        if player.setTraverserEpoch then
            player:setTraverserEpoch()
        end
    end

    if player:getQuestStatus(abyssea, truth) ~= xi.questStatus.QUEST_COMPLETED then
        if player:getQuestStatus(abyssea, truth) == xi.questStatus.QUEST_AVAILABLE then
            player:addQuest(abyssea, truth)
        end

        player:completeQuest(abyssea, truth)
    end

    if player:getQuestStatus(abyssea, dawn) == xi.questStatus.QUEST_AVAILABLE then
        player:addQuest(abyssea, dawn)
    end
end

local function grantWorldAccess(player)
    if not isPlayer(player) or not openWorld() then
        return
    end

    for _, keyItemId in ipairs(ACCESS_KEY_ITEMS) do
        grantKeyItem(player, keyItemId)
    end

    grantAbysseaAccess(player)
end

local function applyBattleReady(player, logId, battle)
    setCurrent(player, logId, battle.missionId)

    if logId <= 2 then
        ensureNationRank(player, battle.missionId)
    end

    if battle.status then
        player:setMissionStatus(logId, battle.status)
    end

    if battle.varStatus then
        xi.mission.setVar(player, logId, battle.missionId, 'Status', battle.varStatus)
    end

    if xi.mission.setMustZone then
        player:setCharVar(string.format('Mission[%d][%d]mustZone', logId, battle.missionId), 0)
    end

    if battle.keyItems then
        for _, keyItemId in ipairs(battle.keyItems) do
            grantKeyItem(player, keyItemId)
        end
    end

    grantChapterKeyItems(player, logId)
end

local function nationFinale(player)
    local nation = player:getNation()

    if nation == xi.nation.SANDORIA then
        return
        {
            name      = 'Heir to the Light',
            missionId = xi.mission.id.sandoria.THE_HEIR_TO_THE_LIGHT,
            zone      = xi.zone.QUBIA_ARENA,
            pos       = { -241.046, -25.907, 20.000, 0 },
            status    = 3,
        }
    elseif nation == xi.nation.BASTOK then
        return
        {
            name      = 'Where Two Paths Converge',
            missionId = xi.mission.id.bastok.WHERE_TWO_PATHS_CONVERGE,
            zone      = xi.zone.THRONE_ROOM,
            pos       = { 0.000, -1.000, 0.000, 192 },
            status    = 1,
        }
    end

    return
    {
        name      = 'Moon Reading',
        missionId = xi.mission.id.windurst.MOON_READING,
        zone      = xi.zone.FULL_MOON_FOUNTAIN,
        pos       = { -17.000, 9.000, -260.000, 0 },
        status    = 3,
    }
end

local function nationBattles(player)
    return
    {
        {
            name      = 'Archlich (Rank 5)',
            missionId = xi.mission.id.nation.ARCHLICH,
            zone      = xi.zone.QUBIA_ARENA,
            pos       = { -241.046, -25.907, 20.000, 0 },
            status    = 11,
            keyItems  = { xi.ki.NEW_FEIYIN_SEAL },
        },
        {
            name      = 'The Shadow Lord',
            missionId = xi.mission.id.nation.SHADOW_LORD,
            zone      = xi.zone.THRONE_ROOM,
            pos       = { 0.000, -1.000, 0.000, 192 },
            status    = 3,
        },
        nationFinale(player),
    }
end

local function chapterLogIds(chapter, player)
    if chapter.logIds then
        return chapter.logIds(player)
    end

    return chapter.logs
end

local function chapterBattles(chapter, player)
    if chapter.battles then
        return chapter.battles(player)
    end

    return chapter.fightList or {}
end

local CHAPTERS =
{
    {
        id    = 'nation',
        title = 'Nation missions',
        logIds = function(player)
            return { player:getNation() }
        end,
        battles = nationBattles,
    },
    {
        id    = 'zilart',
        title = 'Rise of the Zilart',
        logs  = { xi.mission.log_id.ZILART },
        fightList =
        {
            {
                name      = 'Temple of Uggalepih',
                missionId = xi.mission.id.zilart.THE_TEMPLE_OF_UGGALEPIH,
                zone      = xi.zone.SACRIFICIAL_CHAMBER,
                pos       = { 0.000, 0.000, 0.000, 0 },
                status    = 0,
            },
            {
                name      = 'Through the Quicksand Caves',
                missionId = xi.mission.id.zilart.THROUGH_THE_QUICKSAND_CAVES,
                zone      = xi.zone.CHAMBER_OF_ORACLES,
                pos       = { -221.000, -24.000, 19.000, 0 },
                status    = 0,
            },
            {
                name      = 'Return to Delkfutt',
                missionId = xi.mission.id.zilart.RETURN_TO_DELKFUTTS_TOWER,
                zone      = xi.zone.STELLAR_FULCRUM,
                pos       = { 0.000, 0.000, 0.000, 0 },
                status    = 1,
            },
            {
                name      = 'Ark Angels',
                missionId = xi.mission.id.zilart.ARK_ANGELS,
                zone      = xi.zone.LALOFF_AMPHITHEATER,
                pos       = { 0.000, -23.750, 0.000, 0 },
                status    = 1,
            },
            {
                name      = 'The Celestial Nexus',
                missionId = xi.mission.id.zilart.THE_CELESTIAL_NEXUS,
                zone      = xi.zone.THE_CELESTIAL_NEXUS,
                pos       = { 0.000, 0.000, 0.000, 192 },
                status    = 0,
            },
        },
    },
    {
        id    = 'cop',
        title = 'Chains of Promathia',
        logs  = { xi.mission.log_id.COP },
        fightList =
        {
            {
                name      = 'Ancient Vows',
                missionId = xi.mission.id.cop.ANCIENT_VOWS,
                zone      = xi.zone.MONARCH_LINN,
                pos       = { 12.000, 0.000, 0.000, 0 },
                varStatus = 2,
            },
            {
                name      = 'Darkness Named',
                missionId = xi.mission.id.cop.DARKNESS_NAMED,
                zone      = xi.zone.THE_SHROUDED_MAW,
                pos       = { -300.000, -47.000, 220.000, 0 },
                varStatus = 4,
            },
            {
                name      = 'The Savage',
                missionId = xi.mission.id.cop.THE_SAVAGE,
                zone      = xi.zone.MONARCH_LINN,
                pos       = { 12.000, 0.000, 0.000, 0 },
                varStatus = 1,
            },
            {
                name      = 'Desires of Emptiness',
                missionId = xi.mission.id.cop.DESIRES_OF_EMPTINESS,
                zone      = xi.zone.SPIRE_OF_VAHZL,
                pos       = { 0.000, 0.000, 0.000, 0 },
                varStatus = 2,
            },
            {
                name      = 'One to be Feared',
                missionId = xi.mission.id.cop.ONE_TO_BE_FEARED,
                zone      = xi.zone.SEALIONS_DEN,
                pos       = { 0.000, 0.000, 0.000, 192 },
                varStatus = 3,
            },
            {
                name      = "The Warrior's Path",
                missionId = xi.mission.id.cop.THE_WARRIORS_PATH,
                zone      = xi.zone.SEALIONS_DEN,
                pos       = { 0.000, 0.000, 0.000, 192 },
                varStatus = 1,
            },
            {
                name      = 'When Angels Fall',
                missionId = xi.mission.id.cop.WHEN_ANGELS_FALL,
                zone      = xi.zone.THE_GARDEN_OF_RUHMET,
                pos       = { -20.000, 0.000, -355.000, 192 },
                varStatus = 4,
            },
            {
                name      = 'Dawn',
                missionId = xi.mission.id.cop.DAWN,
                zone      = xi.zone.EMPYREAL_PARADOX,
                pos       = { 540.000, 0.000, -594.000, 0 },
                varStatus = 1,
            },
        },
    },
    {
        id    = 'toau',
        title = 'Treasures of Aht Urhgan',
        logs  = { xi.mission.log_id.TOAU },
        fightList =
        {
            {
                name      = 'The Black Coffin',
                missionId = xi.mission.id.toau.THE_BLACK_COFFIN,
                zone      = xi.zone.NASHMAU,
                pos       = { 12.000, 0.000, -80.000, 0 },
            },
            {
                name      = 'Shield of Diplomacy',
                missionId = xi.mission.id.toau.SHIELD_OF_DIPLOMACY,
                zone      = xi.zone.NAVUKGO_EXECUTION_CHAMBER,
                pos       = { 0.000, 0.000, 0.000, 0 },
                status    = 2,
            },
            {
                name      = 'Puppet in Peril',
                missionId = xi.mission.id.toau.PUPPET_IN_PERIL,
                zone      = xi.zone.JADE_SEPULCHER,
                pos       = { 0.000, 0.000, 0.000, 0 },
                status    = 1,
            },
            {
                name      = 'Legacy of the Lost',
                missionId = xi.mission.id.toau.LEGACY_OF_THE_LOST,
                zone      = xi.zone.TALACCA_COVE,
                pos       = { 0.000, 0.000, 0.000, 0 },
                status    = 0,
            },
            {
                name      = 'Path of Darkness',
                missionId = xi.mission.id.toau.PATH_OF_DARKNESS,
                zone      = xi.zone.NYZUL_ISLE,
                pos       = { 0.000, 0.000, 0.000, 0 },
            },
            {
                name      = "Nashmeira's Plea",
                missionId = xi.mission.id.toau.NASHMEIRAS_PLEA,
                zone      = xi.zone.NYZUL_ISLE,
                pos       = { 0.000, 0.000, 0.000, 0 },
            },
        },
    },
    {
        id    = 'wotg',
        title = 'Wings of the Goddess',
        logs  = { xi.mission.log_id.WOTG },
        fightList =
        {
            {
                name      = 'Purple, the New Black',
                missionId = xi.mission.id.wotg.PURPLE_THE_NEW_BLACK,
                zone      = xi.zone.LA_VAULE_S,
                pos       = { 0.000, 0.000, 0.000, 0 },
                status    = 1,
            },
        },
    },
    {
        id    = 'soa',
        title = 'Seekers of Adoulin',
        logs  = { xi.mission.log_id.SOA },
        fightList = {},
    },
    {
        id    = 'rov',
        title = "Rhapsodies of Vana'diel",
        logs  = { xi.mission.log_id.ROV },
        fightList = {},
    },
    {
        id    = 'addons',
        title = 'Add-on scenarios',
        logs  =
        {
            xi.mission.log_id.ACP,
            xi.mission.log_id.AMK,
            xi.mission.log_id.ASA,
        },
        fightList = {},
    },
}

local function chapterById(chapterId)
    for _, chapter in ipairs(CHAPTERS) do
        if chapter.id == chapterId then
            return chapter
        end
    end
end

local function nextBattle(player, chapter)
    local logIds = chapterLogIds(chapter, player)
    local logId  = logIds[1]
    local fights = chapterBattles(chapter, player)

    for _, battle in ipairs(fights) do
        if not battlePassed(player, logId, battle) then
            return logId, battle
        end
    end
end

local function closeChapter(player, chapter)
    for _, logId in ipairs(chapterLogIds(chapter, player)) do
        closeLog(player, logId)
        grantChapterKeyItems(player, logId)
    end

    grantWorldAccess(player)
end

local function skipToBattle(player, npc, chapter)
    local logId, battle = nextBattle(player, chapter)
    if not logId or not battle then
        say(player, npc, 'That chapter has no battle left. Close it if you want the log marked done.')
        return
    end

    if player:getCurrentMission(logId) ~= battle.missionId then
        completeLogThrough(player, logId, battle.missionId)
    end

    applyBattleReady(player, logId, battle)

    local x, y, z, rot = battle.pos[1], battle.pos[2], battle.pos[3], battle.pos[4]
    say(player, npc, string.format('The next fight is %s. I will take you to the door.', battle.name))
    note(player, string.format('[chronicle] %s — enter the battlefield here.', battle.name))
    player:setPos(x, y, z, rot, battle.zone)
end

local delayMenu
local openMain
local openMore
local openChapter

delayMenu = function(player, menu)
    player:timer(MENU_DELAY_MS, function(playerArg)
        playerArg:customMenu(menu)
    end)
end

openMain = function(player, npc)
    delayMenu(player, {
        title = 'The Chronicler',
        options =
        {
            {
                'How this works',
                function(playerArg)
                    say(playerArg, npc, 'The world is already open. Missions are optional.')
                    say(playerArg, npc, 'Play a chapter, skip to its next battle, or close it if you already know the tale.')
                    openMain(playerArg, npc)
                end,
            },
            {
                CHAPTERS[1].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[1])
                end,
            },
            {
                CHAPTERS[2].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[2])
                end,
            },
            {
                CHAPTERS[3].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[3])
                end,
            },
            {
                CHAPTERS[4].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[4])
                end,
            },
            {
                'More chapters',
                function(playerArg)
                    openMore(playerArg, npc)
                end,
            },
        },
    })
end

openMore = function(player, npc)
    delayMenu(player, {
        title = 'More chapters',
        options =
        {
            {
                CHAPTERS[5].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[5])
                end,
            },
            {
                CHAPTERS[6].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[6])
                end,
            },
            {
                CHAPTERS[7].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[7])
                end,
            },
            {
                CHAPTERS[8].title,
                function(playerArg)
                    openChapter(playerArg, npc, CHAPTERS[8])
                end,
            },
            {
                'Back',
                function(playerArg)
                    openMain(playerArg, npc)
                end,
            },
        },
    })
end

openChapter = function(player, npc, chapter)
    local logIds  = chapterLogIds(chapter, player)
    local closed  = true
    local _, battle = nextBattle(player, chapter)

    for _, logId in ipairs(logIds) do
        if not chapterClosed(player, logId) then
            closed = false
            break
        end
    end

    local options = {}

    if closed then
        options[#options + 1] =
        {
            'Already finished',
            function(playerArg)
                say(playerArg, npc, string.format('You already closed %s.', chapter.title))
                openMain(playerArg, npc)
            end,
        }
    else
        if battle then
            options[#options + 1] =
            {
                'Skip to next battle',
                function(playerArg)
                    delayMenu(playerArg, {
                        title = battle.name,
                        options =
                        {
                            {
                                'Take me there',
                                function(confirmPlayer)
                                    skipToBattle(confirmPlayer, npc, chapter)
                                end,
                            },
                            {
                                'Never mind',
                                function(confirmPlayer)
                                    openChapter(confirmPlayer, npc, chapter)
                                end,
                            },
                        },
                    })
                end,
            }
        end

        options[#options + 1] =
        {
            'Close this chapter',
            function(playerArg)
                delayMenu(playerArg, {
                    title = 'Close this chapter?',
                    options =
                    {
                        {
                            'Yes, I know this tale',
                            function(confirmPlayer)
                                closeChapter(confirmPlayer, chapter)
                                say(confirmPlayer, npc, string.format('%s is closed. The doors it used to hold stay open.', chapter.title))
                                note(confirmPlayer, string.format('[chronicle] Closed %s.', chapter.title))
                            end,
                        },
                        {
                            'Never mind',
                            function(confirmPlayer)
                                openChapter(confirmPlayer, npc, chapter)
                            end,
                        },
                    },
                })
            end,
        }
    end

    options[#options + 1] =
    {
        'Play it myself',
        function(playerArg)
            say(playerArg, npc, 'Then walk it. The world does not wait on the story.')
            openMain(playerArg, npc)
        end,
    }

    options[#options + 1] =
    {
        'Back',
        function(playerArg)
            openMain(playerArg, npc)
        end,
    }

    delayMenu(player, {
        title   = chapter.title,
        options = options,
    })
end

local function onChroniclerTrigger(player, npc)
    grantWorldAccess(player)
    say(player, npc, 'Missions tell the story. They do not sell the ticket.')
    openMain(player, npc)
end

local CHRONICLERS =
{
    {
        zone     = 'Lower_Jeuno',
        x        = 18.000,
        y        = 0.000,
        z        = -16.000,
        rotation = 160,
    },
    {
        zone     = 'Aht_Urhgan_Whitegate',
        x        = 8.000,
        y        = 0.000,
        z        = -8.000,
        rotation = 96,
    },
    {
        zone     = 'Western_Adoulin',
        x        = 8.000,
        y        = 0.000,
        z        = -8.000,
        rotation = 160,
    },
    {
        zone     = 'GM_Home',
        x        = 2.000,
        y        = 0.000,
        z        = 8.000,
        rotation = 128,
    },
}

local function spawnChronicler(zone, pos)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Chronicler',
        packetName = string.format('%sChronicler', xi.icon.STAR_LARGE),
        look       = 2430,
        x          = pos.x,
        y          = pos.y,
        z          = pos.z,
        rotation   = pos.rotation,
        widescan   = 1,
        onTrigger  = onChroniclerTrigger,
    })
end

for _, pos in ipairs(CHRONICLERS) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', pos.zone), function(zone)
        super(zone)
        spawnChronicler(zone, pos)
    end)
end

local function overrideIfOpen(path, handler)
    m:addOverride(path, function(player, npc)
        if openWorld() then
            return handler(player, npc)
        end

        return super(player, npc)
    end)
end

overrideIfOpen('xi.zones.Valkurm_Dunes.npcs.Swirling_Vortex.onTrigger', function(player)
    player:startOptionalCutscene(12, { cs_option = 0, canSkip = true })
end)

overrideIfOpen('xi.zones.Qufim_Island.npcs.Swirling_Vortex.onTrigger', function(player)
    player:startOptionalCutscene(300, { cs_option = 0, canSkip = true })
end)

overrideIfOpen('xi.zones.Tavnazian_Safehold.npcs._0q1.onTrigger', function(player)
    player:startEvent(502)
end)

overrideIfOpen('xi.zones.Tavnazian_Safehold.npcs.Senvaleget.onTrigger', function(player)
    player:sendMenu(xi.menuType.AUCTION)
end)

overrideIfOpen('xi.zones.Tavnazian_Safehold.npcs.Ferocious_Artisan.onTrigger', function(player)
    player:sendMenu(xi.menuType.AUCTION)
end)

overrideIfOpen('xi.zones.Tavnazian_Safehold.npcs.Eliot.onTrigger', function(player)
    player:sendMenu(xi.menuType.AUCTION)
end)

overrideIfOpen('xi.zones.PsoXja.npcs._i98.onTrigger', function(player)
    if player:getZPos() < 318 then
        player:startOptionalCutscene(69, { cs_option = 0, canSkip = true })
    else
        player:startOptionalCutscene(70, { cs_option = 0, canSkip = true })
    end
end)

overrideIfOpen('xi.zones.The_Garden_of_RuHmet.npcs._0zs.onTrigger', function(player)
    player:startEvent(112)
end)

overrideIfOpen('xi.zones.Misareaux_Coast.npcs.Spatial_Displacement.onTrigger', function(player)
    player:startEvent(551)
end)

overrideIfOpen('xi.zones.Misareaux_Coast.npcs._0p2.onTrigger', function(player)
    player:startCutscene(552)
end)

overrideIfOpen('xi.zones.Misareaux_Coast.npcs._0p8.onTrigger', function(player)
    player:startCutscene(502)
end)

overrideIfOpen('xi.zones.Hall_of_the_Gods.npcs.Shimmering_Circle.onTrigger', function(player, npc)
    if player:getZPos() < 200 then
        player:startEvent(10)
    else
        player:startEvent(11)
    end
end)

overrideIfOpen('xi.zones.La_Theine_Plateau.npcs.Dimensional_Portal.onTrigger', function(player)
    player:startOptionalCutscene(204, { cs_option = 0, canSkip = true })
end)

overrideIfOpen('xi.zones.Konschtat_Highlands.npcs.Dimensional_Portal.onTrigger', function(player)
    player:startOptionalCutscene(915, { cs_option = 0, canSkip = true })
end)

overrideIfOpen('xi.zones.Tahrongi_Canyon.npcs.Dimensional_Portal.onTrigger', function(player)
    player:startOptionalCutscene(915, { cs_option = 0, canSkip = true })
end)

local function overrideRunic(path, portal, unlockedCs, firstCs)
    m:addOverride(path, function(player, npc)
        if
            openWorld() and
            player:getCurrentMission(xi.mission.log_id.TOAU) < xi.mission.id.toau.IMMORTAL_SENTRIES and
            not player:hasKeyItem(xi.ki.SUPPLIES_PACKAGE)
        then
            if xi.besieged.hasRunicPortal(player, portal) then
                player:startEvent(unlockedCs)
            else
                player:startEvent(firstCs)
            end

            return
        end

        return super(player, npc)
    end)
end

overrideRunic('xi.zones.Mount_Zhayolm.npcs.Runic_Portal.onTrigger', xi.teleport.runic_portal.HALVUNG, 109, 111)
overrideRunic('xi.zones.Bhaflau_Thickets.npcs.Runic_Portal.onTrigger', xi.teleport.runic_portal.MAMOOL, 109, 111)
overrideRunic('xi.zones.Arrapago_Reef.npcs.Runic_Portal.onTrigger', xi.teleport.runic_portal.ILRUSI, 109, 111)
overrideRunic('xi.zones.Caedarva_Mire.npcs.Runic_Portal_Azouph.onTrigger', xi.teleport.runic_portal.AZOUPH, 131, 124)
overrideRunic('xi.zones.Caedarva_Mire.npcs.Runic_Portal_Dvucca.onTrigger', xi.teleport.runic_portal.DVUCCA, 134, 125)

m:addOverride('xi.zones.Alzadaal_Undersea_Ruins.npcs.Runic_Portal.onTrigger', function(player, npc)
    if
        openWorld() and
        player:getCurrentMission(xi.mission.log_id.TOAU) < xi.mission.id.toau.IMMORTAL_SENTRIES and
        not player:hasKeyItem(xi.ki.SUPPLIES_PACKAGE)
    then
        local ID    = zones[xi.zone.ALZADAAL_UNDERSEA_RUINS]
        local npcid = npc:getID()
        local event
        if xi.besieged.hasRunicPortal(player, xi.teleport.runic_portal.NYZUL) then
            event = npcid == ID.npc.RUNIC_PORTAL_OFFSET and 117 or 118
        else
            event = npcid == ID.npc.RUNIC_PORTAL_OFFSET and 121 or 122
        end

        player:startEvent(event)
        return
    end

    return super(player, npc)
end)

local function overrideAssaultStaging(path, ordersKi, paidEvent, readyEvent, readyParam)
    m:addOverride(path, function(player, npc)
        if
            openWorld() and
            player:getCurrentMission(xi.mission.log_id.TOAU) < xi.mission.id.toau.PRESIDENT_SALAHEEM
        then
            local imperial = player:getCurrency('imperial_standing')
            if
                player:hasKeyItem(ordersKi) and
                not player:hasKeyItem(xi.ki.ASSAULT_ARMBAND)
            then
                player:startEvent(paidEvent, 50, imperial)
            elseif readyParam then
                player:startEvent(readyEvent, readyParam)
            else
                player:startEvent(readyEvent)
            end

            return
        end

        return super(player, npc)
    end)
end

overrideAssaultStaging('xi.zones.Mount_Zhayolm.npcs.Waudeen.onTrigger', xi.ki.LEBROS_ASSAULT_ORDERS, 209, 6)
overrideAssaultStaging('xi.zones.Caedarva_Mire.npcs.Nareema.onTrigger', xi.ki.LEUJAOAM_ASSAULT_ORDERS, 149, 7, 1)
overrideAssaultStaging('xi.zones.Caedarva_Mire.npcs.Nahshib.onTrigger', xi.ki.PERIQIA_ASSAULT_ORDERS, 148, 7)
overrideAssaultStaging('xi.zones.Bhaflau_Thickets.npcs.Daswil.onTrigger', xi.ki.MAMOOL_JA_ASSAULT_ORDERS, 512, 7)
overrideAssaultStaging('xi.zones.Arrapago_Reef.npcs.Meyaada.onTrigger', xi.ki.ILRUSI_ASSAULT_ORDERS, 223, 7)

m:addOverride('xi.zones.The_Garden_of_RuHmet.Zone.onTriggerAreaEnter', function(player, triggerArea)
    if
        openWorld() and
        player:getLocalVar('TeleportAntiTrigger') == 0 and
        player:getAnimation() == xi.animation.NONE and
        triggerArea:getTriggerAreaID() == 1
    then
        local current = player:getCurrentMission(xi.mission.log_id.COP)
        if
            current ~= xi.mission.id.cop.DAWN and
            not player:hasCompletedMission(xi.mission.log_id.COP, xi.mission.id.cop.DAWN) and
            not player:hasCompletedMission(xi.mission.log_id.COP, xi.mission.id.cop.THE_LAST_VERSE)
        then
            player:startEvent(101)
            return
        end
    end

    return super(player, triggerArea)
end)

m:addOverride('xi.soa.helpers.imprimaturGate', function(player, gateAmount)
    if openWorld() then
        return true
    end

    return super(player, gateAmount)
end)

for _, helper in ipairs({
    'meetsMission3Reqs',
    'meetsMission4Reqs',
    'meetsMission8Reqs',
    'meetsMission15Reqs',
    'meetsMission26Reqs',
    'meetsMission38Reqs',
}) do
    m:addOverride('xi.wotg.helpers.' .. helper, function(player)
        if openWorld() then
            return true
        end

        return super(player)
    end)
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantWorldAccess(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    grantWorldAccess(player)
end)

xi.ixi20MissionChronicle =
{
    grantWorldAccess = grantWorldAccess,
    closeChapter     = function(player, chapterId)
        local chapter = chapterById(chapterId)
        if chapter then
            closeChapter(player, chapter)
        end
    end,
    openMenu = onChroniclerTrigger,
}

local commandObj =
{
    cmdprops =
    {
        permission = 0,
        parameters = 's',
    },
    onTrigger = function(player, arg)
        if not isPlayer(player) then
            return
        end

        local token = arg and string.lower(arg) or ''
        if token == 'help' or token == '?' then
            note(player, '!chronicle — talk to the Chronicler (Jeuno, Whitegate, Adoulin).')
            note(player, 'The world is open. Missions are optional.')
            return
        end

        onChroniclerTrigger(player, nil)
    end,
}

xi.module.registerCommand('chronicle', commandObj)
xi.commands = xi.commands or {}
xi.commands.chronicle = commandObj

return m
