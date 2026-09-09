/************************************************************************
 * Imagine XI 2.0 loot-progression economy (module only)
 *
 * - player:addGil / spark currency -> XP
 * - Vendor sell (0x085) of combat gear and crystals -> XP (shop goods / fishing tools pay 0)
 * - Shop buy (0x083) blocks weapons / armor (not fishing tools)
 * - addShopItem prices are 0 while gil converts to XP
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/enums/chat_message_type.h"
#include "map/enums/msg_std.h"
#include "map/enums/packet_c2s.h"
#include "map/item_container.h"
#include "map/items/item_weapon.h"
#include "map/items/transactions/item_claim.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x083_shop_buy.h"
#include "map/packets/c2s/0x085_shop_sell_set.h"
#include "map/packets/s2c/0x009_message.h"
#include "map/packets/s2c/0x017_chat_std.h"
#include "map/packets/s2c/0x01d_item_same.h"
#include "map/trade_container.h"
#include "map/utils/charutils.h"
#include "map/utils/itemutils.h"

#include "data/enums/skill_type.h"

#include <algorithm>
#include <cmath>
#include <string>

namespace
{

auto gilToExpEnabled() -> bool
{
    return settings::get<bool>("main.IMAGINEXI_GIL_TO_EXP_ENABLED");
}

auto vendorSellToExpEnabled() -> bool
{
    return settings::get<bool>("main.IMAGINEXI_VENDOR_SELL_TO_EXP");
}

auto sparksToExpEnabled() -> bool
{
    return settings::get<bool>("main.IMAGINEXI_SPARKS_TO_EXP_ENABLED");
}

auto blockShopGear() -> bool
{
    return settings::get<bool>("main.IMAGINEXI_BLOCK_SHOP_GEAR");
}

auto toExp(int32 amount, const char* ratioKey) -> uint32
{
    if (amount <= 0)
    {
        return 0;
    }

    const double ratio = settings::get<double>(ratioKey);
    const double used  = ratio > 0.0 ? ratio : 1.0;
    return static_cast<uint32>(std::max(0.0, std::floor(static_cast<double>(amount) * used)));
}

void grantExp(CCharEntity* PChar, uint32 exp)
{
    if (PChar == nullptr || exp == 0)
    {
        return;
    }

    // Prefer the Lua/CBaseEntity addExp path so subjob XP share can split the grant.
    if (auto addExp = lua["CBaseEntity"]["addExp"]; addExp.valid())
    {
        addExp(CLuaBaseEntity(PChar), exp);
        return;
    }

    charutils::AddExperiencePoints(false, false, true, PChar, PChar, exp);
}

void systemMessage(CCharEntity* PChar, const std::string& message)
{
    if (PChar)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(PChar, MESSAGE_SYSTEM_3, message);
    }
}

auto isFishingTool(const CItem* PItem) -> bool
{
    if (PItem == nullptr || !PItem->isType(ITEM_WEAPON))
    {
        return false;
    }

    const auto* PWeapon = dynamic_cast<const CItemWeapon*>(PItem);
    return PWeapon != nullptr && PWeapon->getSkillType() == xi::SkillType::Fishing;
}

auto isShopGear(uint16 itemId) -> bool
{
    const CItem* PItem = xi::items::lookup(itemId);
    if (PItem == nullptr || isFishingTool(PItem))
    {
        return false;
    }

    return PItem->isType(ITEM_WEAPON) || PItem->isType(ITEM_EQUIPMENT);
}

// Fire–Dark crystals (4096-4103) and clusters (4104-4111). Not live shop stock.
auto isElementalCrystal(uint16 itemId) -> bool
{
    return itemId >= 4096 && itemId <= 4111;
}

auto grantsVendorSellExp(uint16 itemId) -> bool
{
    return isShopGear(itemId) || isElementalCrystal(itemId);
}

auto handleShopBuy(CCharEntity* PChar, CBasicPacket& packet) -> bool
{
    if (!blockShopGear() || PChar == nullptr || PChar->Container == nullptr)
    {
        return false;
    }

    const auto* buy = packet.as<GP_CLI_COMMAND_SHOP_BUY>();
    if (buy == nullptr)
    {
        return false;
    }

    if (buy->ShopItemIndex > PChar->Container->getExSize() - 1)
    {
        return false;
    }

    const uint16 itemId = PChar->Container->getItemID(buy->ShopItemIndex);
    if (!isShopGear(itemId))
    {
        return false;
    }

    systemMessage(PChar, "Weapons and armor are not sold in shops. Hunt zone camps for equipment.");
    ShowInfoFmt("Ixi20GilEconomy: blocked shop buy player={} itemId={}", PChar->getName(), itemId);
    return true;
}

auto handleShopSell(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool
{
    (void)session;
    (void)packet;

    if (!gilToExpEnabled() || !vendorSellToExpEnabled() || PChar == nullptr || PChar->Container == nullptr)
    {
        return false;
    }

    const uint32 quantity = PChar->Container->getQuantity(PChar->Container->getExSize());
    const uint16 itemId   = PChar->Container->getItemID(PChar->Container->getExSize());
    const uint8  slotId   = PChar->Container->getInvSlotID(PChar->Container->getExSize());

    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        return true;
    }

    const CItem* PItem = transaction->claimSlot(LOC_INVENTORY, slotId);
    if (!PItem)
    {
        ShowWarningFmt("Ixi20GilEconomy: sell of missing/claimed item by {}", PChar->getName());
        return true;
    }

    if (quantity < 1 || quantity > PItem->getStackSize() || quantity > PItem->getQuantity() || itemId != PItem->getID())
    {
        ShowWarningFmt("Ixi20GilEconomy: invalid sell qty/id by {} itemId={} qty={}", PChar->getName(), itemId, quantity);
        return true;
    }

    // Combat gear and elemental crystals/clusters. Free shop stock (bait, potions,
    // scrolls, mats, rods) must not convert into a buy-then-sell XP loop.
    const auto unitPrice = grantsVendorSellExp(itemId)
                               ? luautils::callGlobal<uint32>("xi.shop.onSellPriceCheck", PChar, itemId, PChar->Container->getShopFameArea())
                               : 0;
    const auto cost      = quantity * unitPrice;

    if (!transaction->take(LOC_INVENTORY, slotId, quantity) || !transaction->commit())
    {
        ShowWarningFmt("Ixi20GilEconomy: {} could not sell item ID {}", PChar->getName(), itemId);
        return true;
    }

    grantExp(PChar, toExp(static_cast<int32>(cost), "main.IMAGINEXI_GIL_TO_EXP_RATIO"));

    ShowInfoFmt("Ixi20GilEconomy: Player '{}' sold {} of itemID {} for {} XP [to VENDOR]", PChar->getName(), quantity, itemId, cost);
    PChar->pushPacket<GP_SERV_COMMAND_MESSAGE>(nullptr, itemId, quantity, MsgStd::Sell);
    PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);
    PChar->Container->setItem(PChar->Container->getExSize(), 0, -1, 0);
    return true;
}

} // namespace

class Ixi20GilEconomyModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (lua["CBaseEntity"].valid())
        {
            lua["CBaseEntity"]["addGil"] = [](CLuaBaseEntity entity, int32 gil) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                if (PChar && gil > 0 && gilToExpEnabled())
                {
                    grantExp(PChar, toExp(gil, "main.IMAGINEXI_GIL_TO_EXP_RATIO"));
                    return;
                }

                entity.addGil(gil);
            };

            lua["CBaseEntity"]["addCurrency"] = [](CLuaBaseEntity entity, const std::string& currencyType, int32 amount, sol::object maxObj) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                if (
                    PChar &&
                    amount > 0 &&
                    sparksToExpEnabled() &&
                    currencyType == "spark_of_eminence")
                {
                    grantExp(PChar, toExp(amount, "main.IMAGINEXI_SPARKS_TO_EXP_RATIO"));
                    return;
                }

                entity.addCurrency(currencyType, amount, maxObj);
            };

            lua["CBaseEntity"]["addShopItem"] = [](CLuaBaseEntity entity, uint16 itemID, double rawPrice, sol::variadic_args va) {
                if (gilToExpEnabled())
                {
                    rawPrice = 0;
                }

                sol::optional<sol::table> requirements = sol::nullopt;
                if (va.size() > 0 && va[0].is<sol::table>())
                {
                    requirements = va[0].as<sol::table>();
                }

                entity.addShopItem(itemID, rawPrice, requirements);
            };

            lua["CBaseEntity"]["sendMenu"] = [](CLuaBaseEntity entity, uint32 menu) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                // Retail FFXiMain access-violates on 0-item shop open/list (0x03E/0x03C, +0xF8B49).
                if (menu == 2 && PChar != nullptr && PChar->Container != nullptr && PChar->Container->getItemsCount() == 0)
                {
                    systemMessage(PChar, "Weapons and armor are not sold in shops. Hunt zone camps for equipment.");
                    ShowWarningFmt("Ixi20GilEconomy: blocked 0-item shop for {}", PChar->getName());
                    return;
                }

                entity.sendMenu(menu);
            };
        }
        else
        {
            ShowWarning("Ixi20GilEconomy: CBaseEntity usertype missing; addGil/addCurrency/addShopItem/sendMenu wraps skipped");
        }

        ShowInfo("Imagine XI 2.0: gil economy module loaded");
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        switch (packet.getType())
        {
            case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_SHOP_BUY):
                return handleShopBuy(PChar, packet);
            case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_SHOP_SELL_SET):
                return handleShopSell(session, PChar, packet);
            default:
                return false;
        }
    }
};

REGISTER_CPP_MODULE(Ixi20GilEconomyModule);
