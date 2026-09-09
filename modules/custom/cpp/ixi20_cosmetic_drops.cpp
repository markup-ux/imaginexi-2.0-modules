/************************************************************************
 * Imagine XI 2.0 cosmetic drops: grant equipment into a wardrobe.
 *
 * Lua addItem() only writes inventory. This exposes
 * Ixi20AddItemToContainer(player, itemId, container) for Wardrobe 1-8.
 *
 * Bound with the Lua C API (not sol::set_function + CLuaBaseEntity by value).
 * That sol signature access-violates during module OnInit in this TU.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"
#include "common/types/flag.h"

#include "map/entities/char_entity.h"
#include "map/item_container.h"
#include "map/items/item.h"
#include "map/items/transactions/item_claim.h"
#include "map/lua/lua_base_entity.h"
#include "map/utils/itemutils.h"

namespace
{

auto isWardrobe(uint8 location) -> bool
{
    switch (location)
    {
        case LOC_WARDROBE:
        case LOC_WARDROBE2:
        case LOC_WARDROBE3:
        case LOC_WARDROBE4:
        case LOC_WARDROBE5:
        case LOC_WARDROBE6:
        case LOC_WARDROBE7:
        case LOC_WARDROBE8:
            return true;
        default:
            return false;
    }
}

auto canStoreInWardrobe(uint16 itemId) -> bool
{
    const CItem* PItem = xi::items::lookup(itemId);
    if (PItem == nullptr)
    {
        return false;
    }

    return PItem->isType(ITEM_EQUIPMENT) || PItem->isType(ITEM_WEAPON);
}

auto addItemToContainer(CCharEntity* PChar, uint16 itemId, uint8 location) -> bool
{
    if (PChar == nullptr || itemId == 0 || !isWardrobe(location) || !canStoreInWardrobe(itemId))
    {
        return false;
    }

    CItemContainer* PStorage = PChar->getStorage(location);
    if (PStorage == nullptr || PStorage->GetFreeSlotsCount() == 0)
    {
        return false;
    }

    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        return false;
    }

    const auto slot = transaction->give(location, itemId, 1, Silence::Yes);
    return slot.has_value() && transaction->commit();
}

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

auto luaIxi20AddItemToContainer(lua_State* L) -> int
{
    auto* PChar     = entityFromLua(L, 1);
    const auto itemId   = static_cast<uint16>(luaL_checkinteger(L, 2));
    const auto location = static_cast<uint8>(luaL_checkinteger(L, 3));
    lua_pushboolean(L, addItemToContainer(PChar, itemId, location) ? 1 : 0);
    return 1;
}

} // namespace

class Ixi20CosmeticDropsModule : public CPPModule
{
public:
    void OnInit() override
    {
        // Global ::lua is valid by OnInit (after main). A CPPModule member reference
        // bound at static init can dangle if this TU constructs first.
        lua_State* L = lua.lua_state();
        if (L == nullptr)
        {
            ShowError("Imagine XI 2.0: cosmetic wardrobe grants skipped (lua state missing)");
            return;
        }

        lua_register(L, "Ixi20AddItemToContainer", luaIxi20AddItemToContainer);
        ShowInfo("Imagine XI 2.0: cosmetic wardrobe grants loaded");
    }
};

REGISTER_CPP_MODULE(Ixi20CosmeticDropsModule);
