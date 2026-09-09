/************************************************************************
 * Imagine XI 2.0: combat and magic skills stay at stored job caps
 * (module only).
 *
 * 1.0 wrote char_skills to the cap for stored main/sub levels whenever
 * BuildingCharSkillsTable ran. Stock LSB has no such hook, so this
 * raises RealSkills on zone-in, job-info, and zone ticks, and wraps the
 * Lua skill helpers that would otherwise use effective/synced MLV.
 *
 * Crafts, fishing, RID, and DIG are not auto-capped.
 * Caps use stored jobs.job[] so a sync-down does not wipe real skills.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/enums/packet_s2c.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/basic.h"
#include "map/packets/s2c/0x062_clistatus2.h"
#include "map/packets/s2c/0x0ac_command_data.h"
#include "map/packets/s2c/0x119_abil_recast.h"
#include "map/utils/battleutils.h"
#include "map/utils/charutils.h"
#include "map/zone.h"

#include "data/enums/job.h"
#include "data/enums/skill_type.h"
#include "data/enums/status.h"

#include <algorithm>

namespace
{

constexpr int SkillLoopEnd = 48;

auto featureEnabled() -> bool
{
    return settings::get<bool>("main.IMAGINEXI_ALWAYS_CAP_COMBAT_MAGIC_SKILLS");
}

auto isCombatMagicAutoCapSkill(uint8 skillId) -> bool
{
    if (skillId < 1 || skillId >= SkillLoopEnd)
    {
        return false;
    }

    if ((skillId >= 13 && skillId <= 21) || (skillId >= 46 && skillId <= 47))
    {
        return false;
    }

    return true;
}

auto combatMagicSkillCap(CCharEntity* PChar, xi::SkillType skillId) -> uint16
{
    if (PChar == nullptr || !isCombatMagicAutoCapSkill(static_cast<uint8>(skillId)))
    {
        return 0;
    }

    const uint8 realMLv = PChar->jobs.job[static_cast<uint8>(PChar->GetMJob())];
    const uint8 realSLv = PChar->jobs.job[static_cast<uint8>(PChar->GetSJob())];

    uint16 maxMainSkill = battleutils::GetMaxSkill(skillId, PChar->GetMJob(), realMLv);
    uint16 maxSubSkill  = battleutils::GetMaxSkill(skillId, PChar->GetSJob(), realSLv);

    const uint8 rawSkill = static_cast<uint8>(skillId);
    if (rawSkill >= static_cast<uint8>(xi::SkillType::AutomatonMelee) && rawSkill <= static_cast<uint8>(xi::SkillType::AutomatonMagic))
    {
        if (PChar->GetMJob() == xi::Job::PUP)
        {
            maxMainSkill = battleutils::GetMaxSkill(1, realMLv);
        }
        else if (PChar->GetSJob() == xi::Job::PUP)
        {
            maxSubSkill = battleutils::GetMaxSkill(1, realSLv);
        }
    }

    return std::max(maxMainSkill, maxSubSkill);
}

auto raiseCombatMagicSkills(CCharEntity* PChar) -> bool
{
    if (PChar == nullptr || !featureEnabled())
    {
        return false;
    }

    if (PChar->GetMJob() == xi::Job::MON || PChar->GetSJob() == xi::Job::MON)
    {
        return false;
    }

    bool changed = false;
    for (int i = 1; i < SkillLoopEnd; ++i)
    {
        if (!isCombatMagicAutoCapSkill(static_cast<uint8>(i)))
        {
            continue;
        }

        const uint16 cap = combatMagicSkillCap(PChar, static_cast<xi::SkillType>(i));
        if (cap == 0)
        {
            continue;
        }

        const uint16 targetTenths = static_cast<uint16>(cap * 10);
        if (PChar->RealSkills.skill[i] != targetTenths)
        {
            PChar->RealSkills.skill[i] = targetTenths;
            charutils::SaveCharSkills(PChar, static_cast<uint8>(i));
            changed                    = true;
        }
    }

    return changed;
}

void rebuildSkills(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    charutils::BuildingCharSkillsTable(PChar);
    charutils::BuildingCharWeaponSkills(PChar);

    if (PChar->status != xi::Status::Disappear)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
        PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
        PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
    }
}

void applyIfChanged(CCharEntity* PChar)
{
    if (raiseCombatMagicSkills(PChar))
    {
        rebuildSkills(PChar);
    }
}

void capOneSkillToStored(CCharEntity* PChar, uint8 skill)
{
    if (PChar == nullptr)
    {
        return;
    }

    uint16 cap = combatMagicSkillCap(PChar, static_cast<xi::SkillType>(skill));
    if (cap == 0)
    {
        cap = battleutils::GetMaxSkill(static_cast<xi::SkillType>(skill), PChar->GetMJob(), PChar->GetMLevel());
    }

    const uint16 maxSkill            = static_cast<uint16>(cap * 10);
    PChar->RealSkills.skill[skill]   = maxSkill;
    PChar->WorkingSkills.skill[skill] = maxSkill / 10;
    PChar->WorkingSkills.skill[skill] |= 0x8000;
    charutils::SaveCharSkills(PChar, skill);
    charutils::CheckWeaponSkill(PChar, skill);
    charutils::BuildingCharWeaponSkills(PChar);

    if (PChar->status != xi::Status::Disappear)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
        PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
    }
}

} // namespace

class Ixi20CappedSkillsModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua.set_function("Ixi20CapCombatMagicSkills", [](CLuaBaseEntity entity) {
            applyIfChanged(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()));
        });

        if (lua["CBaseEntity"].valid())
        {
            lua["CBaseEntity"]["recalculateSkillsTable"] = [](CLuaBaseEntity entity) {
                raiseCombatMagicSkills(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()));
                entity.recalculateSkillsTable();
            };

            lua["CBaseEntity"]["capAllSkills"] = [](CLuaBaseEntity entity) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                if (PChar == nullptr || !featureEnabled())
                {
                    entity.capAllSkills();
                    return;
                }

                raiseCombatMagicSkills(PChar);
                rebuildSkills(PChar);
            };

            lua["CBaseEntity"]["capSkill"] = [](CLuaBaseEntity entity, uint8 skill) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                if (PChar == nullptr || !featureEnabled() || !isCombatMagicAutoCapSkill(skill))
                {
                    entity.capSkill(skill);
                    return;
                }

                capOneSkillToStored(PChar, skill);
            };
        }
        else
        {
            ShowWarning("Ixi20CappedSkills: CBaseEntity usertype missing; Lua skill wraps skipped");
        }

        ShowInfo("Imagine XI 2.0: always-capped combat/magic skills loaded");
    }

    void OnZoneTick(CZone* PZone) override
    {
        if (PZone == nullptr || !featureEnabled())
        {
            return;
        }

        PZone->ForEachChar([](CCharEntity* PChar) {
            applyIfChanged(PChar);
        });
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        applyIfChanged(PChar);
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr || !featureEnabled())
        {
            return;
        }

        if (packet->getType() == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_JOB_INFO))
        {
            applyIfChanged(PChar);
        }
    }
};

REGISTER_CPP_MODULE(Ixi20CappedSkillsModule);
