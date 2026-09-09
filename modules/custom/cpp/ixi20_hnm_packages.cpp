/************************************************************************
 * Imagine XI 2.0 HNM combat packages (module only).
 *
 * Stock LSB has no combat CPPModule hooks. Sleep block, stun-0, WS
 * reaction, and apex skills live in ixi20_hnm_packages.lua.
 * Attach once per zone on its first tick — not every 400ms. A full-world
 * scan each tick was stalling the main loop past the 2s inactivity watchdog.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/mob_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/zone.h"

#include <unordered_set>

namespace
{

constexpr const char* AttachedVar = "[ixi20Hnm]pkg";

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
    sol::object pkgObj = xi["hnmPackages"];
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
        ShowError("Imagine XI 2.0: xi.hnmPackages.ensure failed");
    }
}

} // namespace

class Ixi20HnmPackagesModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: HNM packages attach-once (sleep / stun-0 / WS reaction / apex)");
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

REGISTER_CPP_MODULE(Ixi20HnmPackagesModule);
