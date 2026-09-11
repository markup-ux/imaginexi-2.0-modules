/************************************************************************
 * Imagine XI 2.0: THF crits reduce every job-ability recast.
 *
 * Ixi20ReduceAbilityRecasts(player, seconds)
 *
 * Bound with the Lua C API (not sol::set_function + CLuaBaseEntity by value).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"

#include "map/entities/char_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/s2c/0x062_clistatus2.h"
#include "map/packets/s2c/0x119_abil_recast.h"
#include "map/recast_container.h"

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

auto luaIxi20ReduceAbilityRecasts(lua_State* L) -> int
{
    auto* PChar   = entityFromLua(L, 1);
    const int32 seconds = static_cast<int32>(luaL_optinteger(L, 2, 1));
    bool  changed = false;

    if (PChar != nullptr && PChar->PRecastContainer && seconds > 0)
    {
        RecastList_t* list = PChar->PRecastContainer->GetRecastList(RECAST_ABILITY);
        if (list != nullptr)
        {
            const auto reduction = std::chrono::seconds(seconds);
            for (auto&& recast : *list)
            {
                if (recast.RecastTime <= 0s)
                {
                    continue;
                }

                recast.RecastTime -= reduction;
                if (recast.RecastTime < 0s)
                {
                    recast.RecastTime = 0s;
                }

                changed = true;
            }
        }

        if (changed)
        {
            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS2>(PChar);
            PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
        }
    }

    lua_pushboolean(L, changed ? 1 : 0);
    return 1;
}

} // namespace

class Ixi20ThfModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua_State* L = lua.lua_state();
        if (L == nullptr)
        {
            ShowError("Imagine XI 2.0: THF crit recast skipped (lua state missing)");
            return;
        }

        lua_register(L, "Ixi20ReduceAbilityRecasts", luaIxi20ReduceAbilityRecasts);
        ShowInfo("Imagine XI 2.0: THF crits reduce all job-ability recasts by 1s");
    }
};

REGISTER_CPP_MODULE(Ixi20ThfModule);
