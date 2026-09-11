/************************************************************************
 * Imagine XI 2.0: SCH always has 5 stratagem charges / 48s from level 1.
 *
 * Stock GetCharge reads abilities_charges, but the live recast slot can
 * keep maxCharges=1 (or 0) after a login. This replaces GetCharge and
 * exposes Ixi20ApplySchCharges so Lua can stamp the recast on login.
 * Rebuild xi_map.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/logging.h"
#include "common/lua.h"

#include "map/ability.h"
#include "map/entities/battle_entity.h"
#include "map/entities/char_entity.h"
#include "map/enums/recast.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/s2c/0x062_clistatus2.h"
#include "map/packets/s2c/0x119_abil_recast.h"
#include "map/recast_container.h"

#include "data/enums/job.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>

#include <cstring>
#include <vector>

namespace
{

std::vector<Charge_t> g_charges;
Charge_t              g_schFive{};

auto entityFromLua(lua_State* L, int index) -> CCharEntity*
{
    if (!sol::stack::check<CLuaBaseEntity*>(L, index))
    {
        return nullptr;
    }

    auto* wrapper = sol::stack::get<CLuaBaseEntity*>(L, index);
    if (wrapper == nullptr)
    {
        return nullptr;
    }

    return dynamic_cast<CCharEntity*>(wrapper->GetBaseEntity());
}

auto schLevel(CBattleEntity* PUser) -> uint8
{
    if (PUser == nullptr)
    {
        return 0;
    }

    if (PUser->GetMJob() == xi::Job::SCH)
    {
        return PUser->GetMLevel();
    }

    if (PUser->GetSJob() == xi::Job::SCH)
    {
        return PUser->GetSLevel();
    }

    return 0;
}

auto hookedGetCharge(CBattleEntity* PUser, uint16 chargeID) -> Charge_t*
{
    if (PUser != nullptr && chargeID == static_cast<uint16>(Recast::Strategems) && schLevel(PUser) >= 1)
    {
        return &g_schFive;
    }

    Charge_t* charge = nullptr;
    for (auto& row : g_charges)
    {
        if (row.ID != chargeID || PUser == nullptr)
        {
            continue;
        }

        if (PUser->GetMJob() == row.job)
        {
            if (PUser->GetMLevel() >= row.level)
            {
                charge = &row;
            }
            else
            {
                break;
            }
        }
        else if (PUser->GetSJob() == row.job)
        {
            if (PUser->GetSLevel() >= row.level)
            {
                charge = &row;
            }
            else
            {
                break;
            }
        }
    }

    return charge;
}

auto luaIxi20ApplySchCharges(lua_State* L) -> int
{
    auto* PChar = entityFromLua(L, 1);
    bool  ok    = false;

    if (PChar != nullptr && PChar->PRecastContainer && schLevel(PChar) >= 1)
    {
        Recast_t* recast = PChar->PRecastContainer->GetRecast(RECAST_ABILITY, Recast::Strategems);
        if (recast == nullptr)
        {
            PChar->PRecastContainer->Add(RECAST_ABILITY, Recast::Strategems, 0s, g_schFive.chargeTime, g_schFive.maxCharges);
        }
        else
        {
            recast->chargeTime = g_schFive.chargeTime;
            recast->maxCharges = g_schFive.maxCharges;
            const auto cap     = g_schFive.chargeTime * g_schFive.maxCharges;
            if (recast->RecastTime > cap)
            {
                recast->RecastTime = cap;
            }
        }

        PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
        PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
        ok = true;
    }

    lua_pushboolean(L, ok ? 1 : 0);
    return 1;
}

auto installJump(void* target, const void* dest) -> bool
{
    auto* bytes = static_cast<uint8*>(target);
    if (bytes == nullptr || dest == nullptr)
    {
        return false;
    }

    DWORD oldProtect = 0;
    if (VirtualProtect(bytes, 16, PAGE_EXECUTE_READWRITE, &oldProtect) == 0)
    {
        return false;
    }

    bytes[0] = 0x48;
    bytes[1] = 0xB8;
    const auto addr = reinterpret_cast<uint64>(dest);
    std::memcpy(bytes + 2, &addr, sizeof(addr));
    bytes[10] = 0xFF;
    bytes[11] = 0xE0;

    DWORD ignored = 0;
    VirtualProtect(bytes, 16, oldProtect, &ignored);
    FlushInstructionCache(GetCurrentProcess(), bytes, 16);
    return true;
}

void loadChargeCache()
{
    g_charges.clear();

    g_schFive.ID         = static_cast<uint16>(Recast::Strategems);
    g_schFive.job        = xi::Job::SCH;
    g_schFive.level      = 1;
    g_schFive.maxCharges = 5;
    g_schFive.chargeTime = 48s;
    g_schFive.merit      = 0;

    const auto rset = db::preparedStmt(
        "SELECT recastId, job, level, maxCharges, chargeTime, meritModId "
        "FROM abilities_charges ORDER BY job, level ASC");
    if (!rset || !rset->rowsCount())
    {
        return;
    }

    while (rset->next())
    {
        Charge_t row{};
        row.ID         = rset->get<uint16>("recastId");
        row.job        = rset->get<xi::Job>("job");
        row.level      = rset->get<uint8>("level");
        row.maxCharges = rset->get<uint8>("maxCharges");
        row.chargeTime = std::chrono::seconds(rset->get<uint32>("chargeTime"));
        row.merit      = rset->get<uint16>("meritModId");

        if (row.ID == static_cast<uint16>(Recast::Strategems) && row.job == xi::Job::SCH)
        {
            continue;
        }

        g_charges.emplace_back(row);
    }
}

} // namespace

class Ixi20SchChargesModule : public CPPModule
{
public:
    void OnInit() override
    {
        loadChargeCache();

        lua_State* L = lua.lua_state();
        if (L != nullptr)
        {
            lua_register(L, "Ixi20ApplySchCharges", luaIxi20ApplySchCharges);
        }

        if (installJump(reinterpret_cast<void*>(&ability::GetCharge),
                        reinterpret_cast<const void*>(&hookedGetCharge)))
        {
            ShowInfo("Imagine XI 2.0: SCH charges module loaded (5x48s from level 1)");
        }
        else
        {
            ShowError("Imagine XI 2.0: SCH charges module failed to patch GetCharge");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20SchChargesModule);
