/************************************************************************
 * Imagine XI 2.0: refund one Scholar stratagem charge from Lua.
 *
 * Ixi20CountActionMsgs(action, { msg, ... })
 * Ixi20RefundStratagemCharge(player)
 *
 * Bound with the Lua C API (not sol::set_function + CLuaBaseEntity by value).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"

#include "map/action/action.h"
#include "map/entities/char_entity.h"
#include "map/enums/recast.h"
#include "map/lua/lua_action.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/s2c/0x062_clistatus2.h"
#include "map/packets/s2c/0x119_abil_recast.h"
#include "map/recast_container.h"

#include <chrono>
#include <unordered_set>

namespace
{

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

auto actionFromLua(lua_State* L, int index) -> action_t*
{
    if (!sol::stack::check<CLuaAction*>(L, index))
    {
        return nullptr;
    }

    auto* wrapper = sol::stack::get<CLuaAction*>(L, index);
    return wrapper != nullptr ? wrapper->GetAction() : nullptr;
}

auto luaIxi20CountActionMsgs(lua_State* L) -> int
{
    action_t* action = actionFromLua(L, 1);
    if (action == nullptr || !lua_istable(L, 2))
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    std::unordered_set<uint16> ok;
    lua_pushnil(L);
    while (lua_next(L, 2) != 0)
    {
        ok.insert(static_cast<uint16>(lua_tointeger(L, -1)));
        lua_pop(L, 1);
    }

    int count = 0;
    for (auto&& actionTarget : action->targets)
    {
        for (auto&& result : actionTarget.results)
        {
            if (ok.contains(static_cast<uint16>(result.messageID)))
            {
                ++count;
                break;
            }
        }
    }

    lua_pushinteger(L, count);
    return 1;
}

auto luaIxi20RefundStratagemCharge(lua_State* L) -> int
{
    auto* PChar = entityFromLua(L, 1);
    bool  ok    = false;

    if (PChar != nullptr && PChar->PRecastContainer)
    {
        Recast_t* recast = PChar->PRecastContainer->GetRecast(RECAST_ABILITY, Recast::Strategems);
        if (recast != nullptr && recast->chargeTime > 0s && recast->RecastTime > 0s)
        {
            recast->RecastTime -= recast->chargeTime;
            if (recast->RecastTime < 0s)
            {
                recast->RecastTime = 0s;
            }

            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
            ok = true;
        }
    }

    lua_pushboolean(L, ok ? 1 : 0);
    return 1;
}

} // namespace

class Ixi20SchStratagemRefundModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua_State* L = lua.lua_state();
        if (L == nullptr)
        {
            ShowError("Imagine XI 2.0: SCH stratagem refund skipped (lua state missing)");
            return;
        }

        lua_register(L, "Ixi20CountActionMsgs", luaIxi20CountActionMsgs);
        lua_register(L, "Ixi20RefundStratagemCharge", luaIxi20RefundStratagemCharge);
        ShowInfo("Imagine XI 2.0: SCH stratagem refund loaded (Manifestation/Accession 3+ hits return a charge)");
    }
};

REGISTER_CPP_MODULE(Ixi20SchStratagemRefundModule);
