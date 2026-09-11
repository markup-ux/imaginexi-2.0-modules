/************************************************************************
 * Imagine XI 2.0: alive-despawn mobs repop at spawn immediately
 *
 * When a mob despawns without dying (claimer wipe, idle despawn, off-mesh
 * leash), stock LSB keeps the full respawn timer. This module overwrites
 * that pending timer with 1s so the mob returns to its default spawn.
 * Killed mobs keep their normal respawn.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"

#include "map/entities/mob_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/luautils.h"
#include "map/map_constants.h"
#include "map/spawn_handler.h"
#include "map/zone.h"

#include <unordered_set>

namespace
{

constexpr const char* AttachedVar = "[ixi20Repop]on";

void attachIfNeeded(sol::state& lua, CMobEntity* PMob)
{
    if (PMob == nullptr || PMob->GetLocalVar(AttachedVar) != 0)
    {
        return;
    }

    sol::object xiObj = lua["xi"];
    if (!xiObj.valid() || xiObj.get_type() != sol::type::table)
    {
        return;
    }

    sol::table xi = xiObj.as<sol::table>();
    sol::object pkgObj = xi["ixi20DeathRepop"];
    if (!pkgObj.valid() || pkgObj.get_type() != sol::type::table)
    {
        return;
    }

    sol::protected_function ensure = pkgObj.as<sol::table>()["ensure"];
    if (!ensure.valid())
    {
        return;
    }

    auto result = ensure(CLuaBaseEntity(PMob));
    if (!result.valid())
    {
        ShowError("Imagine XI 2.0: xi.ixi20DeathRepop.ensure failed");
        return;
    }

    PMob->SetLocalVar(AttachedVar, 1);
}

} // namespace

class Ixi20DeathRepopModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua.set_function("Ixi20RepopAliveMob", [](CLuaBaseEntity entity) {
            auto* PMob = dynamic_cast<CMobEntity*>(entity.GetBaseEntity());
            if (PMob == nullptr || !PMob->isAlive() || !PMob->m_AllowRespawn || PMob->loc.zone == nullptr)
            {
                return;
            }

            if (PMob->PInstance != nullptr || PMob->PBattlefield != nullptr)
            {
                return;
            }

            PMob->loc.zone->spawnHandler().registerForRespawn(PMob, 1s);
        });

        ShowInfo("Imagine XI 2.0: alive-despawn mobs repop at spawn in 1s");
    }

    void OnZoneTick(CZone* PZone) override
    {
        if (PZone == nullptr)
        {
            return;
        }

        const auto zoneId = static_cast<uint16>(PZone->GetID());
        if (!attachedZoneIds_.insert(zoneId).second)
        {
            return;
        }

        PZone->ForEachMob([this](CMobEntity* PMob) {
            attachIfNeeded(lua, PMob);
        });
    }

private:
    std::unordered_set<uint16> attachedZoneIds_;
};

REGISTER_CPP_MODULE(Ixi20DeathRepopModule);
