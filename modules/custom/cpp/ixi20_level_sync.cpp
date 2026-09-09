/************************************************************************
 * Imagine XI 2.0: bidirectional party Level Sync (module only).
 *
 * Stock LSB only syncs down. 1.0 matched the designee's stored main job
 * (up or down, capped by main.MAX_LEVEL) and treated combat/magic working
 * skills as capped for that level while LEVEL_SYNC is active.
 *
 * Core party.cpp / levelRestriction still only lower. This wraps the Lua
 * binding and re-applies after RefreshSync via zone ticks.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/lua_statuseffect.h"
#include "map/packets/s2c/0x061_clistatus.h"
#include "map/packets/s2c/0x0ac_command_data.h"
#include "map/party.h"
#include "map/status_effect.h"
#include "map/status_effect_container.h"
#include "map/utils/battleutils.h"
#include "map/utils/charutils.h"
#include "map/zone.h"

#include "data/enums/job.h"
#include "data/enums/skill_type.h"
#include "data/enums/status.h"
#include "data/enums/status_effect.h"

#include <algorithm>
#include <array>
#include <unordered_map>

using namespace std::chrono_literals;

namespace
{

constexpr int SkillModOffset = 79;
constexpr int SkillLoopEnd   = 48;

struct SkillCapState
{
    uint8                 level            = 0;
    xi::Job               job              = xi::Job::NONE;
    uint32                realFingerprint  = 0;
    std::array<int16, 48> mods{};
};

std::unordered_map<uint32, SkillCapState> g_skillCaps;

auto serverMaxLevel() -> uint8
{
    const uint8 cap = settings::get<uint8>("main.MAX_LEVEL");
    return cap > 0 ? cap : 75;
}

auto storedMainLevel(const CCharEntity* PChar) -> uint8
{
    if (PChar == nullptr)
    {
        return 0;
    }

    return PChar->jobs.job[static_cast<uint8>(PChar->GetMJob())];
}

auto clampSyncLevel(uint8 level) -> uint8
{
    return std::max<uint8>(1, std::min(level, serverMaxLevel()));
}

auto desiredFromParty(CCharEntity* PChar) -> uint8
{
    if (PChar == nullptr || PChar->PParty == nullptr)
    {
        return 0;
    }

    auto* PSync = dynamic_cast<CCharEntity*>(PChar->PParty->GetSyncTarget());
    if (PSync == nullptr)
    {
        return 0;
    }

    return clampSyncLevel(storedMainLevel(PSync));
}

auto isActiveLevelSync(CCharEntity* PChar) -> bool
{
    if (PChar == nullptr || PChar->StatusEffectContainer == nullptr)
    {
        return false;
    }

    CStatusEffect* PEffect = PChar->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::LevelSync);
    return PEffect != nullptr && PEffect->GetDuration() == 0s;
}

auto skipSkillIndex(int skill) -> bool
{
    return (skill >= 13 && skill <= 21) || (skill >= 22 && skill <= 24) || (skill >= 46 && skill <= 47);
}

auto realSkillFingerprint(const CCharEntity* PChar) -> uint32
{
    uint32 sum = 0;
    if (PChar == nullptr)
    {
        return 0;
    }

    for (int i = 1; i < SkillLoopEnd; ++i)
    {
        if (skipSkillIndex(i))
        {
            continue;
        }

        sum += PChar->RealSkills.skill[i];
    }

    return sum;
}

void clearSkillCaps(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    const auto it = g_skillCaps.find(PChar->id);
    if (it == g_skillCaps.end())
    {
        return;
    }

    for (int i = 1; i < SkillLoopEnd; ++i)
    {
        if (it->second.mods[i] != 0)
        {
            PChar->delModifier(static_cast<xi::Mod>(i + SkillModOffset), it->second.mods[i]);
        }
    }

    g_skillCaps.erase(it);
}

void applySkillCaps(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    const uint8   level = PChar->GetMLevel();
    const xi::Job job   = PChar->GetMJob();

    const uint32 fingerprint = realSkillFingerprint(PChar);
    const auto   it          = g_skillCaps.find(PChar->id);
    if (it != g_skillCaps.end() && it->second.level == level && it->second.job == job && it->second.realFingerprint == fingerprint)
    {
        return;
    }

    clearSkillCaps(PChar);

    SkillCapState state;
    state.level           = level;
    state.job             = job;
    state.realFingerprint = fingerprint;

    for (int i = 1; i < SkillLoopEnd; ++i)
    {
        if (skipSkillIndex(i))
        {
            continue;
        }

        const uint16 maxMainSkill = battleutils::GetMaxSkill(static_cast<xi::SkillType>(i), PChar->GetMJob(), PChar->GetMLevel());
        const uint16 maxSubSkill  = battleutils::GetMaxSkill(static_cast<xi::SkillType>(i), PChar->GetSJob(), PChar->GetSLevel());
        const uint16 maxSkill     = maxMainSkill != 0 ? maxMainSkill : maxSubSkill;
        if (maxSkill == 0)
        {
            continue;
        }

        uint16 currentSkill = PChar->RealSkills.skill[i] / 10;
        if (currentSkill > maxSkill)
        {
            currentSkill = maxSkill;
        }

        if (currentSkill >= maxSkill)
        {
            continue;
        }

        const int16 delta = static_cast<int16>(maxSkill - currentSkill);
        PChar->addModifier(static_cast<xi::Mod>(i + SkillModOffset), delta);
        state.mods[i]     = delta;
    }

    g_skillCaps[PChar->id] = state;
    charutils::BuildingCharSkillsTable(PChar);
}

auto handleLevelRestriction(CCharEntity* PChar, const sol::object& level) -> uint8
{
    CLuaBaseEntity luaEntity(PChar);

    const bool isSet = level.valid() && level != sol::lua_nil && (level.is<int>() || level.is<double>());
    if (!isSet)
    {
        return luaEntity.levelRestriction(level);
    }

    const int raw = level.is<int>() ? level.as<int>() : static_cast<int>(level.as<double>());
    if (raw == 0)
    {
        clearSkillCaps(PChar);
        return luaEntity.levelRestriction(level);
    }

    if (!isActiveLevelSync(PChar))
    {
        return luaEntity.levelRestriction(level);
    }

    uint8 desired = clampSyncLevel(static_cast<uint8>(std::clamp(raw, 1, 255)));
    if (const uint8 fromParty = desiredFromParty(PChar); fromParty != 0)
    {
        desired = fromParty;
    }

    const uint8 mjobIdx = static_cast<uint8>(PChar->GetMJob());
    const uint8 stored  = PChar->jobs.job[mjobIdx];
    bool        bumped  = false;
    if (desired > stored)
    {
        PChar->jobs.job[mjobIdx] = desired;
        bumped                   = true;
    }

    const uint8 result = luaEntity.levelRestriction(sol::make_object(lua, static_cast<int>(desired)));

    if (bumped)
    {
        PChar->jobs.job[mjobIdx] = stored;
    }

    charutils::BuildingCharWeaponSkills(PChar);
    applySkillCaps(PChar);

    if (PChar->status != xi::Status::Disappear)
    {
        PChar->pushPacket<GP_SERV_COMMAND_COMMAND_DATA>(PChar);
        PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS>(PChar);
    }

    return result;
}

void maintainSync(CCharEntity* PChar)
{
    if (PChar == nullptr || PChar->status == xi::Status::Disappear || PChar->StatusEffectContainer == nullptr)
    {
        return;
    }

    CStatusEffect* PEffect = PChar->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::LevelSync);
    if (PEffect == nullptr)
    {
        clearSkillCaps(PChar);
        return;
    }

    if (PEffect->GetDuration() != 0s)
    {
        return;
    }

    uint8 desired = desiredFromParty(PChar);
    if (desired == 0)
    {
        desired = clampSyncLevel(static_cast<uint8>(PEffect->GetPower()));
    }

    if (PEffect->GetPower() != desired)
    {
        PEffect->SetPower(desired);
    }

    if (PChar->GetMLevel() != desired || PChar->m_LevelRestriction != desired)
    {
        handleLevelRestriction(PChar, sol::make_object(lua, static_cast<int>(desired)));
        return;
    }

    applySkillCaps(PChar);
}

} // namespace

class Ixi20LevelSyncModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua.set_function("Ixi20LevelSyncPrepare", [](CLuaBaseEntity entity, CLuaStatusEffect effect) {
            auto* PChar   = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
            auto* PEffect = effect.GetStatusEffect();
            if (PChar == nullptr || PEffect == nullptr)
            {
                return;
            }

            uint8 desired = desiredFromParty(PChar);
            if (desired == 0)
            {
                desired = clampSyncLevel(static_cast<uint8>(PEffect->GetPower()));
            }

            PEffect->SetPower(desired);
        });

        if (lua["CBaseEntity"].valid())
        {
            lua["CBaseEntity"]["levelRestriction"] = [](CLuaBaseEntity entity, sol::object level) -> uint8 {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                if (PChar == nullptr)
                {
                    return entity.levelRestriction(level);
                }

                return handleLevelRestriction(PChar, level);
            };
        }
        else
        {
            ShowWarning("Ixi20LevelSync: CBaseEntity usertype missing; levelRestriction wrap skipped");
        }

        ShowInfo("Imagine XI 2.0: bidirectional Level Sync loaded");
    }

    void OnZoneTick(CZone* PZone) override
    {
        if (PZone == nullptr)
        {
            return;
        }

        PZone->ForEachChar([](CCharEntity* PChar) {
            maintainSync(PChar);
        });
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        maintainSync(PChar);
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        clearSkillCaps(PChar);
    }
};

REGISTER_CPP_MODULE(Ixi20LevelSyncModule);
