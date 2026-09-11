/************************************************************************
 * Imagine XI 2.0: vendor-sell NoSale mob drops (module only)
 *
 * Stock 0x084 rejects ItemFlag::NoSale. This module still appraises those
 * items when Ixi20GrantsVendorSellExp says they convert to XP. Native DAT
 * may still grey them in the shop UI.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"

#include "map/entities/char_entity.h"
#include "map/enums/item_flag.h"
#include "map/enums/packet_c2s.h"
#include "map/item_container.h"
#include "map/items/item.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x084_shop_sell_req.h"
#include "map/packets/s2c/0x03d_shop_sell.h"
#include "map/trade_container.h"

#include <algorithm>

namespace
{

auto handleNoSaleAppraise(CCharEntity* PChar, CBasicPacket& packet) -> bool
{
    const auto* req = packet.as<GP_CLI_COMMAND_SHOP_SELL_REQ>();
    if (req == nullptr || PChar == nullptr || PChar->Container == nullptr)
    {
        return false;
    }

    CItem* PItem = PChar->getStorage(LOC_INVENTORY)->GetItem(req->ItemIndex);
    if (PItem == nullptr || PItem->getID() != req->ItemNo || !PItem->hasFlag(ItemFlag::NoSale))
    {
        return false;
    }

    auto fn = lua["Ixi20GrantsVendorSellExp"];
    if (!fn.valid())
    {
        return false;
    }

    auto result = fn(PItem->getID());
    if (!result.valid() || !result.get<bool>())
    {
        return false;
    }

    const uint32 quantity = std::min<uint32>(req->ItemNum, PItem->getQuantity());
    PChar->Container->setItem(PChar->Container->getExSize(), req->ItemNo, req->ItemIndex, quantity);

    const auto sellPrice = luautils::callGlobal<uint32>("xi.shop.onSellPriceCheck", PChar, req->ItemNo, PChar->Container->getShopFameArea());
    PChar->pushPacket<GP_SERV_COMMAND_SHOP_SELL>(req->ItemIndex, sellPrice);
    return true;
}

} // namespace

class Ixi20MobDropSellModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: mob-drop vendor sell allows NoSale items that convert to XP");
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;
        if (packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_SHOP_SELL_REQ))
        {
            return false;
        }

        return handleNoSaleAppraise(PChar, packet);
    }
};

REGISTER_CPP_MODULE(Ixi20MobDropSellModule);
