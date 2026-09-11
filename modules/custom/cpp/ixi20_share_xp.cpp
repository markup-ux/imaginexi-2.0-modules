/************************************************************************
 * Imagine XI 2.0: split gained XP with the current subjob (module only).
 *
 * Always on. Half of script/combat/gil XP is applied to the current subjob,
 * capped at job level 37 (a 75 main cannot powerlevel the sub past 37).
 * Per-kill subjob XP chat is omitted so FoV regime progress (2/3) is not overwritten.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/enums/chat_message_type.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/luautils.h"
#include "map/packets/s2c/0x017_chat_std.h"
#include "map/packets/s2c/0x01b_job_info.h"
#include "map/utils/charutils.h"

#include "data/enums/job.h"

#include <algorithm>
#include <fmt/format.h>

namespace
{

constexpr uint8 SubjobXpCap = 37;

constexpr const char* JobNames[] = {
    "None",
    "Warrior",
    "Monk",
    "White Mage",
    "Black Mage",
    "Red Mage",
    "Thief",
    "Paladin",
    "Dark Knight",
    "Beastmaster",
    "Bard",
    "Ranger",
    "Samurai",
    "Ninja",
    "Dragoon",
    "Summoner",
    "Blue Mage",
    "Corsair",
    "Puppetmaster",
    "Dancer",
    "Scholar",
    "Geomancer",
    "Rune Fencer",
};

auto jobName(xi::Job job) -> const char*
{
    const auto id = static_cast<uint8>(job);
    if (id >= sizeof(JobNames) / sizeof(JobNames[0]))
    {
        return "job";
    }

    return JobNames[id];
}

void systemMessage(CCharEntity* PChar, const std::string& message)
{
    if (PChar)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(PChar, MESSAGE_SYSTEM_3, message);
    }
}

auto jobCanGainSharedExp(CCharEntity* PChar, xi::Job job) -> bool
{
    if (PChar == nullptr || job == xi::Job::NONE || job == xi::Job::MON)
    {
        return false;
    }

    const auto id    = static_cast<uint8>(job);
    const auto level = PChar->jobs.job[id];
    return level > 0 && level < SubjobXpCap && level < PChar->jobs.genkai;
}

void addExpToJob(CCharEntity* PChar, xi::Job job, uint32 exp)
{
    if (PChar == nullptr || exp == 0 || !jobCanGainSharedExp(PChar, job))
    {
        return;
    }

    if (job == PChar->GetMJob())
    {
        charutils::AddExperiencePoints(false, false, true, PChar, PChar, exp);
        return;
    }

    const auto  jobId      = static_cast<uint8>(job);
    const auto  currentExp = PChar->jobs.exp[jobId];
    const uint8 oldLevel   = PChar->jobs.job[jobId];
    const uint8 oldSLevel  = PChar->GetSLevel();
    const uint8 levelCap   = std::min<uint8>(SubjobXpCap, PChar->jobs.genkai);

    PChar->jobs.exp[jobId] = static_cast<uint16>(currentExp + exp);

    bool leveled = false;
    if ((currentExp + exp) >= charutils::GetExpNEXTLevel(oldLevel))
    {
        if (oldLevel >= levelCap)
        {
            PChar->jobs.exp[jobId] = charutils::GetExpNEXTLevel(oldLevel) - 1;
        }
        else
        {
            PChar->jobs.exp[jobId] -= charutils::GetExpNEXTLevel(oldLevel);
            if (PChar->jobs.exp[jobId] >= charutils::GetExpNEXTLevel(oldLevel + 1))
            {
                PChar->jobs.exp[jobId] = charutils::GetExpNEXTLevel(oldLevel + 1) - 1;
            }

            PChar->jobs.job[jobId] = static_cast<uint8>(oldLevel + 1);
            leveled                = true;

            if (PChar->jobs.job[jobId] >= levelCap)
            {
                PChar->jobs.job[jobId] = levelCap;
                PChar->jobs.exp[jobId] = charutils::GetExpNEXTLevel(levelCap) - 1;
            }
        }
    }

    if (leveled)
    {
        systemMessage(PChar, fmt::format("Your {} is now level {}.", jobName(job), PChar->jobs.job[jobId]));

        if (job == PChar->GetSJob())
        {
            PChar->SetSLevel(PChar->jobs.job[jobId]);
            if (PChar->GetSLevel() != oldSLevel)
            {
                charutils::UpdateSubJob(PChar);

                sol::protected_function grantSpells = lua["Ixi20GrantSpells"];
                if (grantSpells.valid())
                {
                    auto result = grantSpells(CLuaBaseEntity(PChar), true, true);
                    if (!result.valid())
                    {
                        ShowError("Imagine XI 2.0: Ixi20GrantSpells failed after subjob level-up");
                    }
                }
            }
        }
    }

    charutils::SaveCharJob(PChar, job);
    charutils::SaveCharExp(PChar, job);
    PChar->pushPacket<GP_SERV_COMMAND_JOB_INFO>(PChar);
}

// Grants the subjob half immediately and returns the main-job remainder.
// Combat applies map.EXP_RATE after this returns, so the sub half is scaled here.
auto prepareSharedExp(CCharEntity* PChar, uint32 exp, bool applyMapExpRate) -> uint32
{
    if (PChar == nullptr || exp == 0)
    {
        return exp;
    }

    const auto subJob = PChar->GetSJob();
    if (!jobCanGainSharedExp(PChar, subJob) || exp < 2)
    {
        return exp;
    }

    uint32 subExp = exp / 2;
    if (applyMapExpRate)
    {
        subExp = static_cast<uint32>(static_cast<float>(subExp) * settings::get<float>("map.EXP_RATE"));
    }

    if (subExp > 0)
    {
        addExpToJob(PChar, subJob, subExp);
    }

    return exp - (exp / 2);
}

} // namespace

class Ixi20ShareXpModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua.set_function("Ixi20PrepareSharedExp", [](CLuaBaseEntity entity, uint32 exp, sol::optional<bool> applyMapExpRate) -> uint32 {
            return prepareSharedExp(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()), exp, applyMapExpRate.value_or(false));
        });

        lua.set_function("Ixi20AddExpToJob", [](CLuaBaseEntity entity, uint8 jobId, uint32 exp) {
            addExpToJob(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()), static_cast<xi::Job>(jobId), exp);
        });

        if (lua["CBaseEntity"].valid())
        {
            lua["CBaseEntity"]["addExp"] = [](CLuaBaseEntity entity, uint32 exp) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                const uint32 mainExp = prepareSharedExp(PChar, exp, false);
                if (mainExp > 0)
                {
                    entity.addExp(mainExp);
                }
            };
        }
        else
        {
            ShowWarning("Ixi20ShareXp: CBaseEntity usertype missing; addExp wrap skipped");
        }

        ShowInfo("Imagine XI 2.0: subjob XP share loaded (always on)");
    }
};

REGISTER_CPP_MODULE(Ixi20ShareXpModule);
