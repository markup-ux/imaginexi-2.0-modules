/************************************************************************
 * Imagine XI 2.0: no gil usage fees (module only).
 *
 * Gil converts to XP, so scripts that check getGil() / delGil() to use
 * a service (airships, chocobos, maps, image support, porter slips,
 * conquest set-home, title changers, etc.) would otherwise fail.
 *
 * - getGil() reports a dummy wallet for PCs so client menus and
 *   "can you afford this?" checks pass
 * - delGil() succeeds without taking gil
 * - getRealGil() is the actual inventory amount (Exchange NPC)
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/lua/lua_base_entity.h"

namespace
{

constexpr uint32 DummyAffordGil = 99999999;

} // namespace

class Ixi20NoGilFeesModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (!lua["CBaseEntity"].valid())
        {
            ShowWarning("Ixi20NoGilFees: CBaseEntity usertype missing; getGil/delGil wraps skipped");
            return;
        }

        lua["CBaseEntity"]["getRealGil"] = [](CLuaBaseEntity entity) -> uint32 {
            return entity.getGil();
        };

        lua["CBaseEntity"]["getGil"] = [](CLuaBaseEntity entity) -> uint32 {
            auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
            if (PChar != nullptr)
            {
                return DummyAffordGil;
            }

            return entity.getGil();
        };

        lua["CBaseEntity"]["delGil"] = [](CLuaBaseEntity entity, int32 gil) -> bool {
            auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
            if (PChar != nullptr)
            {
                return true;
            }

            return entity.delGil(gil);
        };

        ShowInfo("Imagine XI 2.0: gil usage fees disabled");
    }
};

REGISTER_CPP_MODULE(Ixi20NoGilFeesModule);
