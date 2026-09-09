/************************************************************************
 * Imagine XI 2.0 job hooks (module only)
 *
 * - Provoke on MNK / PLD / NIN / RUN (main or sub)
 * - Grant level-eligible spells (no trusts, no merit-gated)
 * - Named chat notices for spells/abilities/traits unlocked on level-up
 * - First-time job starter crate (Lua Ixi20GrantJobCrate)
 * - No Soldier / MON unlocks
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/settings.h"

#include "map/ability.h"
#include "map/entities/char_entity.h"
#include "map/enums/chat_message_type.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/s2c/0x017_chat_std.h"
#include "map/packets/s2c/0x0aa_magic_data.h"
#include "map/packets/s2c/0x0ac_command_data.h"
#include "map/spell.h"
#include "map/trait.h"
#include "map/utils/charutils.h"

#include "data/enums/job.h"
#include "enums/packet_s2c.h"

#include <algorithm>
#include <cctype>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>

#include <fmt/format.h>

namespace
{

std::unordered_map<uint16, std::string> traitNames;

void loadTraitNames()
{
    traitNames.clear();
    const auto rset = db::preparedStmt("SELECT traitid, name FROM traits");
    if (!rset)
    {
        return;
    }

    while (rset->next())
    {
        const auto id = rset->get<uint16>("traitid");
        if (traitNames.find(id) == traitNames.end())
        {
            traitNames.emplace(id, rset->get<std::string>("name"));
        }
    }
}

auto jobUsesProvoke(xi::Job job) -> bool
{
    return job == xi::Job::MNK || job == xi::Job::PLD || job == xi::Job::NIN || job == xi::Job::RUN;
}

void grantProvoke(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    if (!jobUsesProvoke(PChar->GetMJob()) && !jobUsesProvoke(PChar->GetSJob()))
    {
        return;
    }

    if (charutils::hasAbility(PChar, ABILITY_PROVOKE))
    {
        return;
    }

    charutils::addAbility(PChar, ABILITY_PROVOKE);
    PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
}

void systemMessage(CCharEntity* PChar, const std::string& message)
{
    if (PChar)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(PChar, MESSAGE_SYSTEM_3, message);
    }
}

auto prettyUnlockName(std::string_view raw) -> std::string
{
    auto isRoman = [](std::string_view token) -> bool {
        static constexpr std::string_view kRoman[] = {
            "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x", "xi", "xii", "xiii"
        };
        for (auto roman : kRoman)
        {
            if (token == roman)
            {
                return true;
            }
        }
        return false;
    };

    std::string result;
    std::string token;
    auto        flush = [&]() {
        if (token.empty())
        {
            return;
        }
        if (!result.empty())
        {
            result.push_back(' ');
        }

        std::string lower = token;
        for (char& ch : lower)
        {
            ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
        }

        if (isRoman(lower))
        {
            for (char ch : lower)
            {
                result.push_back(static_cast<char>(std::toupper(static_cast<unsigned char>(ch))));
            }
        }
        else
        {
            result.push_back(static_cast<char>(std::toupper(static_cast<unsigned char>(token.front()))));
            for (size_t i = 1; i < token.size(); ++i)
            {
                result.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(token[i]))));
            }
        }
        token.clear();
    };

    for (char ch : raw)
    {
        if (ch == '_' || ch == '-' || ch == ' ')
        {
            flush();
        }
        else
        {
            token.push_back(ch);
        }
    }
    flush();
    return result;
}

auto lastToken(const std::string& name) -> std::string_view
{
    const auto pos = name.find_last_of(' ');
    if (pos == std::string::npos)
    {
        return name;
    }
    return std::string_view(name).substr(pos + 1);
}

auto isRomanToken(std::string_view token) -> bool
{
    static constexpr std::string_view kRoman[] = {
        "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"
    };
    for (auto roman : kRoman)
    {
        if (token == roman)
        {
            return true;
        }
    }
    return false;
}

auto rankRoman(uint8 rank) -> std::string_view
{
    static constexpr std::string_view kRoman[] = {
        "", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"
    };
    if (rank >= sizeof(kRoman) / sizeof(kRoman[0]))
    {
        return "";
    }
    return kRoman[rank];
}

auto traitDisplayName(uint16 traitId, uint8 rank) -> std::string
{
    if (traitNames.empty())
    {
        loadTraitNames();
    }

    const auto it = traitNames.find(traitId);
    if (it == traitNames.end())
    {
        return {};
    }

    std::string name = prettyUnlockName(it->second);
    if (rank > 1 && !isRomanToken(lastToken(name)))
    {
        const auto roman = rankRoman(rank);
        if (!roman.empty())
        {
            name.append(" ");
            name.append(roman);
        }
    }
    return name;
}

auto cappedSubLevel(uint8 mLevel, uint8 sJobLevel) -> uint8
{
    if (mLevel == 0 || sJobLevel == 0)
    {
        return 0;
    }

    uint8 cap = sJobLevel;
    switch (settings::get<uint8>("map.SUBJOB_RATIO"))
    {
        case 0:
            return 0;
        case 1:
            cap = (mLevel == 1) ? 1 : static_cast<uint8>(mLevel >> 1);
            break;
        case 2:
            cap = (mLevel == 1) ? 1 : static_cast<uint8>((mLevel * 2) / 3);
            break;
        case 3:
            cap = (mLevel == 1) ? 1 : mLevel;
            break;
        default:
            break;
    }

    return std::min(sJobLevel, cap);
}

auto shouldAnnounceAbility(CCharEntity* PChar, CAbility* PAbility, bool fromSubJob) -> bool
{
    if (PChar == nullptr || PAbility == nullptr || PAbility->getID() == ABILITY_PET_COMMANDS)
    {
        return false;
    }

    if (fromSubJob && (PAbility->getAddType() & ADDTYPE_MAIN_ONLY))
    {
        return false;
    }

    if (PAbility->isPetAbility())
    {
        return true;
    }

    constexpr uint16 skipMask = ADDTYPE_MERIT | ADDTYPE_ASTRAL_FLOW | ADDTYPE_LEARNED |
                                ADDTYPE_LIGHT_ARTS | ADDTYPE_DARK_ARTS | ADDTYPE_JUGPET |
                                ADDTYPE_CHARMPET | ADDTYPE_AVATAR | ADDTYPE_AUTOMATON;
    if (PAbility->getAddType() & skipMask)
    {
        return false;
    }

    return charutils::CheckAbilityAddtype(PChar, PAbility);
}

auto jobMeetsSpellLevel(CSpell* PSpell, xi::Job job, uint8 level) -> bool
{
    if (PSpell == nullptr || job == xi::Job::NONE || level == 0)
    {
        return false;
    }

    const uint8 req = PSpell->getJob(job);
    return req != 255 && level >= req;
}

// True if main or sub already qualified for this spell before the level that just dinged.
auto alreadyLearnedViaOtherJob(CCharEntity* PChar, CSpell* PSpell, xi::Job announcingJob,
                               uint8 prevMainLevel, uint8 prevSubLevel) -> bool
{
    if (PChar == nullptr || PSpell == nullptr)
    {
        return false;
    }

    const auto mainJob = PChar->GetMJob();
    const auto subJob  = PChar->GetSJob();

    if (mainJob != announcingJob && jobMeetsSpellLevel(PSpell, mainJob, prevMainLevel))
    {
        return true;
    }

    if (subJob != announcingJob && subJob != xi::Job::NONE &&
        !(PSpell->getRequirements() & SPELLREQ_MAIN_JOB_ONLY) &&
        jobMeetsSpellLevel(PSpell, subJob, prevSubLevel))
    {
        return true;
    }

    return false;
}

void announceUnlocksForJob(CCharEntity* PChar, xi::Job job, uint8 newLevel, bool fromSubJob,
                           uint8 prevMainLevel, uint8 prevSubLevel,
                           std::unordered_set<uint16>& announcedSpells, std::unordered_set<uint16>& announcedAbilities,
                           std::unordered_set<uint32>& announcedTraits)
{
    if (PChar == nullptr || job == xi::Job::NONE || newLevel == 0)
    {
        return;
    }

    for (uint16 spellId = 1; spellId < MAX_SPELL_ID; ++spellId)
    {
        if (spellId >= 896 && spellId <= 1019)
        {
            continue;
        }

        CSpell* PSpell = spell::GetSpell(static_cast<SpellID>(spellId));
        if (PSpell == nullptr)
        {
            continue;
        }

        const SPELLGROUP group = PSpell->getSpellGroup();
        if (group == SPELLGROUP_NONE || group == SPELLGROUP_TRUST)
        {
            continue;
        }

        if (fromSubJob && (PSpell->getRequirements() & SPELLREQ_MAIN_JOB_ONLY))
        {
            continue;
        }

        if (PSpell->getJob(job) != newLevel)
        {
            continue;
        }

        if (!charutils::hasSpell(PChar, spellId))
        {
            continue;
        }

        if (alreadyLearnedViaOtherJob(PChar, PSpell, job, prevMainLevel, prevSubLevel))
        {
            continue;
        }

        if (!announcedSpells.insert(spellId).second)
        {
            continue;
        }

        systemMessage(PChar, fmt::format("You learned the spell {}.", prettyUnlockName(PSpell->getName())));
    }

    for (auto* PAbility : ability::GetAbilities(job))
    {
        if (PAbility == nullptr || PAbility->getLevel() != newLevel)
        {
            continue;
        }

        if (!shouldAnnounceAbility(PChar, PAbility, fromSubJob))
        {
            continue;
        }

        if (!announcedAbilities.insert(PAbility->getID()).second)
        {
            continue;
        }

        systemMessage(PChar, fmt::format("You learned the ability {}.", prettyUnlockName(PAbility->getName())));
    }

    TraitList_t* traitList = traits::GetTraits(job);
    if (traitList == nullptr)
    {
        return;
    }

    for (CTrait* PTrait : *traitList)
    {
        if (PTrait == nullptr || PTrait->getLevel() != newLevel || PTrait->getMeritID() != 0)
        {
            continue;
        }

        const uint32 key = (static_cast<uint32>(PTrait->getID()) << 8) | PTrait->getRank();
        if (!announcedTraits.insert(key).second)
        {
            continue;
        }

        const std::string name = traitDisplayName(PTrait->getID(), PTrait->getRank());
        if (name.empty())
        {
            continue;
        }

        systemMessage(PChar, fmt::format("You gained the trait {}.", name));
    }
}

void announceLevelUnlocks(CCharEntity* PChar, bool subJobOnly)
{
    if (PChar == nullptr)
    {
        return;
    }

    std::unordered_set<uint16> announcedSpells;
    std::unordered_set<uint16> announcedAbilities;
    std::unordered_set<uint32> announcedTraits;

    const auto  mainJob       = PChar->GetMJob();
    const auto  subJob        = PChar->GetSJob();
    const uint8 storedMLevel  = PChar->jobs.job[static_cast<uint8>(mainJob)];
    const uint8 storedSJobLvl = (subJob != xi::Job::NONE) ? PChar->jobs.job[static_cast<uint8>(subJob)] : 0;

    // Fight-sync / LEVEL_RESTRICTION keep GetMLevel() at the cap. Auto-learn
    // grants from stored job level, so announce that ding, not the cap.
    if (subJobOnly)
    {
        const uint8 prevSLevel = (storedSJobLvl > 0) ? static_cast<uint8>(storedSJobLvl - 1) : 0;
        announceUnlocksForJob(PChar, subJob, storedSJobLvl, true, storedMLevel, prevSLevel, announcedSpells, announcedAbilities, announcedTraits);
        return;
    }

    const uint8 prevMLevel = (storedMLevel > 1) ? static_cast<uint8>(storedMLevel - 1) : 0;
    const uint8 prevSLevel = (storedMLevel > 1) ? cappedSubLevel(prevMLevel, storedSJobLvl) : 0;
    const uint8 newSLevel  = cappedSubLevel(storedMLevel, storedSJobLvl);
    announceUnlocksForJob(PChar, mainJob, storedMLevel, false, prevMLevel, prevSLevel, announcedSpells, announcedAbilities, announcedTraits);

    if (subJob != xi::Job::NONE && newSLevel > prevSLevel)
    {
        announceUnlocksForJob(PChar, subJob, newSLevel, true, prevMLevel, prevSLevel, announcedSpells, announcedAbilities, announcedTraits);
    }
}

void grantLevelEligibleSpells(CCharEntity* PChar, bool announce, bool subJobOnly)
{
    if (PChar == nullptr)
    {
        return;
    }

    bool        learnedAny = false;
    const auto  mainJob    = PChar->GetMJob();
    const auto  subJob     = PChar->GetSJob();
    const uint8 mainJobLvl = PChar->jobs.job[static_cast<uint8>(mainJob)];
    const uint8 storedSLvl = (subJob != xi::Job::NONE) ? PChar->jobs.job[static_cast<uint8>(subJob)] : 0;
    const uint8 subLvl     = cappedSubLevel(mainJobLvl, storedSLvl);

    for (uint16 spellId = 1; spellId < MAX_SPELL_ID; ++spellId)
    {
        if (spellId >= 896 && spellId <= 1019)
        {
            continue;
        }

        CSpell* PSpell = spell::GetSpell(static_cast<SpellID>(spellId));
        if (PSpell == nullptr)
        {
            continue;
        }

        const SPELLGROUP group = PSpell->getSpellGroup();
        if (group == SPELLGROUP_NONE || group == SPELLGROUP_TRUST)
        {
            continue;
        }

        const std::string& contentTag = PSpell->getContentTag();
        if (!contentTag.empty() && !luautils::IsContentEnabled(contentTag))
        {
            continue;
        }

        if (PSpell->getRequirements() & SPELLREQ_MERIT)
        {
            continue;
        }

        if (charutils::hasSpell(PChar, spellId))
        {
            continue;
        }

        const uint8 mainReq  = PSpell->getJob(mainJob);
        bool        eligible = (mainReq != 255) && (mainJobLvl >= mainReq);

        if (!eligible && subJob != xi::Job::NONE && !(PSpell->getRequirements() & SPELLREQ_MAIN_JOB_ONLY))
        {
            const uint8 subReq = PSpell->getJob(subJob);
            eligible           = (subReq != 255) && (subLvl >= subReq);
        }

        if (!eligible)
        {
            continue;
        }

        if (charutils::addSpell(PChar, spellId))
        {
            charutils::SaveSpell(PChar, spellId);
            learnedAny = true;
        }
    }

    if (learnedAny)
    {
        PChar->pushPacket<GP_SERV_COMMAND_MAGIC_DATA>(PChar);
    }

    // JOB_INFO grants spells silently first. Announce only spells this job just
    // unlocked that the other job did not already qualify for.
    if (announce)
    {
        announceLevelUnlocks(PChar, subJobOnly);
    }
}

void applyJobHooks(CCharEntity* PChar)
{
    grantProvoke(PChar);
    grantLevelEligibleSpells(PChar, false, false);
}

} // namespace

class ImagineJobHooksModule : public CPPModule
{
public:
    void OnInit() override
    {
        loadTraitNames();

        lua.set_function("Ixi20GrantSpells", [](CLuaBaseEntity PLuaEntity, sol::optional<bool> announce, sol::optional<bool> subJobOnly) {
            auto* PChar = dynamic_cast<CCharEntity*>(PLuaEntity.GetBaseEntity());
            grantLevelEligibleSpells(PChar, announce.value_or(false), subJobOnly.value_or(false));
        });

        ShowInfo("Imagine XI 2.0: job hooks loaded (Provoke on MNK/PLD/NIN/RUN, auto-learn spells, job crate)");
    }

    void tryGrantJobCrate(CCharEntity* PChar)
    {
        sol::protected_function fn = lua["Ixi20GrantJobCrate"];
        if (!fn.valid() || PChar == nullptr)
        {
            return;
        }

        auto result = fn(CLuaBaseEntity(PChar));
        if (!result.valid())
        {
            ShowError("Imagine XI 2.0: Ixi20GrantJobCrate failed");
        }
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        applyJobHooks(PChar);
        tryGrantJobCrate(PChar);
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr)
        {
            return;
        }

        if (packet->getType() != static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_JOB_INFO))
        {
            return;
        }

        applyJobHooks(PChar);
        tryGrantJobCrate(PChar);
    }
};

REGISTER_CPP_MODULE(ImagineJobHooksModule);
