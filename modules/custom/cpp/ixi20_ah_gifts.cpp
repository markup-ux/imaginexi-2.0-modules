/************************************************************************
 * Imagine XI 2.0: auction house is a gift locker (module only).
 *
 * Gil is XP, so the retail AH (real-gil fees and bids) cannot work.
 * Listings are stored at 0 gil, takes do not charge gil, and sellers
 * are not paid. The native bid box still requires at least 1 gil, so
 * a 0-gil wallet is shown as 1 gil on the client only.
 * The category list is only items players currently have up (pair with
 * search.OMIT_NO_HISTORY).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/earth_time.h"
#include "common/logging.h"
#include "common/settings.h"

#include <chrono>
#include <fstream>
#include <stdexcept>

#include "map/entities/char_entity.h"
#include "map/enums/chat_message_type.h"
#include "map/enums/item_flag.h"
#include "map/enums/packet_c2s.h"
#include "map/enums/packet_s2c.h"
#include "map/item_container.h"
#include "map/items.h"
#include "map/items/item.h"
#include "map/items/item_usable.h"
#include "map/items/transactions/item_claim.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x04e_auc.h"
#include "map/packets/s2c/0x017_chat_std.h"
#include "map/packets/s2c/0x04c_auc.h"
#include "map/packets/s2c/0x01d_item_same.h"
#include "map/utils/auctionutils.h"
#include "map/utils/itemutils.h"

#include <string>

namespace
{

constexpr uint32 DisplayGilWhenBroke = 1;
constexpr const char* ToldVar        = "[ahGifts]Told";

using Clock     = std::chrono::steady_clock;
using TimePoint = Clock::time_point;

TimePoint lastAhOpenAt{};
TimePoint lastAhListAt{};

auto recently(const TimePoint& when, int seconds) -> bool
{
    if (when == TimePoint{})
    {
        return false;
    }

    return std::chrono::duration_cast<std::chrono::seconds>(Clock::now() - when).count() < seconds;
}

auto jsonEscape(const std::string& text) -> std::string
{
    std::string out;
    out.reserve(text.size());
    for (const char ch : text)
    {
        if (ch == '"' || ch == '\\')
        {
            out.push_back('\\');
        }
        if (ch >= 32)
        {
            out.push_back(ch);
        }
    }
    return out;
}

void writeAhBoardFile()
{
    const auto rset = db::preparedStmt(
        "SELECT id, itemid, stack, seller_name, price, date "
        "FROM auction_house "
        "WHERE buyer_name IS NULL AND sale = 0 AND seller <> 0 "
        "ORDER BY date DESC, id DESC LIMIT 200");

    std::string json = "[";
    bool        first = true;
    if (rset && rset->rowsCount())
    {
        while (rset->next())
        {
            if (!first)
            {
                json += ",";
            }
            first = false;
            json += "{\"id\":" + std::to_string(rset->get<uint32>("id")) +
                    ",\"kind\":\"listing\"" +
                    ",\"item_id\":" + std::to_string(rset->get<uint16>("itemid")) +
                    ",\"stack\":" + std::to_string(rset->get<uint8>("stack")) +
                    ",\"price\":" + std::to_string(rset->get<uint32>("price")) +
                    ",\"seller\":\"" + jsonEscape(rset->get<std::string>("seller_name")) + "\"" +
                    ",\"buyer\":\"\"" +
                    ",\"timestamp\":" + std::to_string(rset->get<uint32>("date")) + "}";
        }
    }
    json += "]";

    const char* paths[] = {
        "D:/Imagine XI 2.0/Windower/addons/imaginexi_overlay/data/ah_board.json",
        "D:/ImagineXI20/Windower/addons/imaginexi_overlay/data/ah_board.json",
    };
    for (const char* path : paths)
    {
        std::ofstream out(path, std::ios::binary | std::ios::trunc);
        if (out)
        {
            out << json;
        }
    }
}

auto realGil(const CCharEntity* PChar) -> uint32
{
    if (PChar == nullptr)
    {
        return 0;
    }

    const CItem* PGil = PChar->getStorage(LOC_INVENTORY)->GetItem(0);
    if (PGil == nullptr || PGil->getID() != ITEMID::GIL)
    {
        return 0;
    }

    return PGil->getQuantity();
}

void systemMessage(CCharEntity* PChar, const std::string& message)
{
    if (PChar)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(PChar, MESSAGE_SYSTEM_3, message);
    }
}

// Keep in sync with Windower/addons/imaginexi_overlay/ah_categories.lua
auto ahCategoryPath(uint8 ahCat) -> const char*
{
    switch (ahCat)
    {
        case 1:  return "Weapons > Hand-to-Hand";
        case 2:  return "Weapons > Dagger";
        case 3:  return "Weapons > Sword";
        case 4:  return "Weapons > Great Sword";
        case 5:  return "Weapons > Axe";
        case 6:  return "Weapons > Great Axe";
        case 7:  return "Weapons > Scythe";
        case 8:  return "Weapons > Polearm";
        case 9:  return "Weapons > Katana";
        case 10: return "Weapons > Great Katana";
        case 11: return "Weapons > Club";
        case 12: return "Weapons > Staff";
        case 13: return "Weapons > Bow";
        case 14: return "Weapons > Instruments";
        case 15: return "Weapons > Ammo & Misc > Ammunition";
        case 16: return "Armor > Shield";
        case 17: return "Armor > Head";
        case 18: return "Armor > Body";
        case 19: return "Armor > Hands";
        case 20: return "Armor > Legs";
        case 21: return "Armor > Feet";
        case 22: return "Armor > Neck";
        case 23: return "Armor > Waist";
        case 24: return "Armor > Earrings";
        case 25: return "Armor > Rings";
        case 26: return "Armor > Back";
        case 28: return "Scrolls > White Magic";
        case 29: return "Scrolls > Black Magic";
        case 30: return "Scrolls > Summoning";
        case 31: return "Scrolls > Ninjutsu";
        case 32: return "Scrolls > Songs";
        case 33: return "Medicines";
        case 34: return "Furnishings";
        case 35: return "Crystals";
        case 36: return "Others > Cards";
        case 37: return "Others > Cursed Items";
        case 38: return "Materials > Smithing";
        case 39: return "Materials > Goldsmithing";
        case 40: return "Materials > Clothcraft";
        case 41: return "Materials > Leathercraft";
        case 42: return "Materials > Bonecraft";
        case 43: return "Materials > Woodworking";
        case 44: return "Materials > Alchemy";
        case 45: return "Scrolls > Geomancy";
        case 46: return "Others > Misc.";
        case 47: return "Weapons > Ammo & Misc > Fishing Gear";
        case 48: return "Weapons > Ammo & Misc > Pet Items";
        case 49: return "Others > Ninja Tools";
        case 50: return "Others > Beast-made";
        case 51: return "Food > Fish";
        case 52: return "Food > Meals > Meat & Eggs";
        case 53: return "Food > Meals > Seafood";
        case 54: return "Food > Meals > Vegetables";
        case 55: return "Food > Meals > Soups";
        case 56: return "Food > Meals > Breads & Rice";
        case 57: return "Food > Meals > Sweets";
        case 58: return "Food > Meals > Drinks";
        case 59: return "Food > Ingredients";
        case 60: return "Scrolls > Dice";
        case 61: return "Others > Automaton";
        case 62: return "Weapons > Ammo & Misc > Grips";
        case 63: return "Materials > Alchemy 2";
        case 64: return "Others > Misc. 2";
        case 65: return "Others > Misc. 3";
        default: return nullptr;
    }
}

auto isPartiallyUsed(const CItem* PItem) -> bool
{
    if (PItem == nullptr || !PItem->isSubType(ITEM_CHARGED))
    {
        return false;
    }

    const auto* PCharged = static_cast<const CItemUsable*>(PItem);
    return PCharged->getCurrentCharges() < PCharged->getMaxCharges();
}

void rememberListedItem(uint16 itemId)
{
    db::preparedStmt("INSERT IGNORE INTO auction_house_items (itemid) VALUES (?)", itemId);
}

void forgetUnlistedItem(uint16 itemId)
{
    db::preparedStmt(
        "DELETE FROM auction_house_items "
        "WHERE itemid = ? AND NOT EXISTS ("
        "SELECT 1 FROM auction_house "
        "WHERE itemid = ? AND buyer_name IS NULL AND sale = 0 AND seller <> 0)",
        itemId,
        itemId);
}

void syncPlayerAhCatalog()
{
    // Rebuild the search catalog only. Never delete open player listings.
    db::preparedStmt("DELETE FROM auction_house_items");
    db::preparedStmt(
        "INSERT IGNORE INTO auction_house_items (itemid) "
        "SELECT DISTINCT itemid FROM auction_house WHERE buyer_name IS NULL AND sale = 0 AND seller <> 0");
    db::preparedStmt("UPDATE auction_house SET price = 0 WHERE buyer_name IS NULL AND sale = 0 AND price <> 0");
    writeAhBoardFile();
}

void stripGiftGilMail(uint32 sellerId, uint16 itemId)
{
    if (sellerId == 0)
    {
        return;
    }

    db::preparedStmt(
        "DELETE FROM delivery_box "
        "WHERE charid = ? AND box = 1 AND itemid = ? AND itemsubid = ? AND quantity = 1 "
        "AND sender = 'AH-Jeuno' AND received = 0 "
        "ORDER BY slot DESC LIMIT 1",
        sellerId,
        static_cast<uint16>(ITEMID::GIL),
        itemId);
}

auto handleList(CCharEntity* PChar, const GP_AUC_PARAM_LOT& param) -> bool
{
    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    CItem* PItem = transaction->claimSlot(LOC_INVENTORY, static_cast<uint8>(param.ItemWorkIndex));
    if (PItem == nullptr || PItem->hasFlag(ItemFlag::NoAuction) || PItem->getQuantity() < param.ItemStacks)
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    if (isPartiallyUsed(PItem))
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    if (param.ItemStacks == 0 && (PItem->getStackSize() == 1 || PItem->getStackSize() != PItem->getQuantity()))
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    const auto ahListings = [&]() -> uint32
    {
        const auto rset = db::preparedStmt("SELECT COUNT(*) FROM auction_house WHERE seller = ? AND sale = 0", PChar->id);
        if (rset && rset->rowsCount() && rset->next())
        {
            return rset->get<uint32>(0);
        }

        return 0;
    }();

    const auto ahListLimit = settings::get<uint8>("map.AH_LIST_LIMIT");
    if (ahListLimit && ahListings >= ahListLimit)
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    const auto listedQuantity = static_cast<int32>(param.ItemStacks != 0 ? 1 : PItem->getStackSize());
    const auto listedItemId   = PItem->getID();
    const auto listedItemName = PItem->getName();

    if (!transaction->take(LOC_INVENTORY, static_cast<uint8>(param.ItemWorkIndex), listedQuantity))
    {
        ShowErrorFmt("Ixi20AhGifts: cannot take {} from {} to list it", listedItemName, PChar->getName());
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    if (!db::preparedStmt("INSERT INTO auction_house(itemid, stack, seller, seller_name, date, price) VALUES(?, ?, ?, ?, ?, 0)",
                          listedItemId,
                          param.ItemStacks == 0,
                          PChar->id,
                          PChar->getName(),
                          earth_time::timestamp()))
    {
        ShowErrorFmt("Ixi20AhGifts: cannot insert {} for {}", listedItemName, PChar->getName());
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 197, 0, 0, 0, 0);
        return true;
    }

    if (!transaction->commit())
    {
        return true;
    }

    rememberListedItem(listedItemId);
    PChar->m_ah_history.push_back(AuctionHistory_t{
        .itemid = listedItemId,
        .stack  = static_cast<uint8>(param.ItemStacks == 0 ? 1 : 0),
        .price  = 0,
        .status = 0,
    });
    lastAhListAt = Clock::now();
    writeAhBoardFile();
    PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::LotIn, 1, 0, 0, 0, 0);
    PChar->pushPacket<GP_SERV_COMMAND_AUC>(static_cast<GP_CLI_COMMAND_AUC_COMMAND>(0x0C), static_cast<uint8>(ahListings), PChar);
    if (const char* ahPath = ahCategoryPath(PItem->getAHCat()); ahPath != nullptr)
    {
        systemMessage(PChar, std::string("Listed as a gift (0 gil). Find it under ") + ahPath + ".");
    }
    else
    {
        systemMessage(PChar, "Listed as a gift (0 gil). Anyone can take it from the auction house.");
    }
    return true;
}

auto handleTake(CCharEntity* PChar, const GP_AUC_PARAM_BID& param) -> bool
{
    if (PChar->getStorage(LOC_INVENTORY)->GetFreeSlotsCount() == 0)
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::Bid, 0xE5, 0, 0, 0, 0);
        return true;
    }

    const CItem* PItem = xi::items::lookup(param.ItemNo);
    if (PItem == nullptr)
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::Bid, 0xC5, param.ItemNo, 0, param.ItemStacks, 0);
        return true;
    }

    if (PItem->hasFlag(ItemFlag::Rare))
    {
        for (uint8 loc = 0; loc < CONTAINER_ID::MAX_CONTAINER_ID; ++loc)
        {
            if (PChar->getStorage(loc)->SearchItem(param.ItemNo) != ERROR_SLOTID)
            {
                PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::Bid, 0xE5, 0, 0, 0, 0);
                return true;
            }
        }
    }

    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::Bid, 0xC5, param.ItemNo, 0, param.ItemStacks, PItem->getStackSize());
        return true;
    }

    const auto boughtQuantity = static_cast<uint32>(param.ItemStacks == 0 ? PItem->getStackSize() : 1);
    uint32     sellerId       = 0;

    const auto success = db::transaction(
        [&]()
        {
            const auto found = db::preparedStmt(
                "SELECT id, seller FROM auction_house "
                "WHERE itemid = ? AND buyer_name IS NULL AND stack = ? "
                "ORDER BY id LIMIT 1",
                param.ItemNo,
                param.ItemStacks == 0);
            if (!found || !found->next())
            {
                throw std::runtime_error("Ixi20AhGifts: no listing");
            }

            const auto listingId = found->get<uint32>("id");
            sellerId             = found->get<uint32>("seller");

            const auto updated = db::preparedStmt(
                "UPDATE auction_house SET buyer = ?, buyer_name = ?, sale = 1, sell_date = ? "
                "WHERE id = ? AND buyer_name IS NULL",
                PChar->id,
                PChar->getName(),
                earth_time::timestamp(),
                listingId);
            if (!updated || !updated->rowsAffected() || !transaction->give(LOC_INVENTORY, param.ItemNo, boughtQuantity))
            {
                throw std::runtime_error("Ixi20AhGifts: take failed");
            }
        });

    if (success && transaction->commit())
    {
        stripGiftGilMail(sellerId, param.ItemNo);
        forgetUnlistedItem(param.ItemNo);
        writeAhBoardFile();
        PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::Bid, 0x01, param.ItemNo, 0, param.ItemStacks, PItem->getStackSize());
        PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);
        systemMessage(PChar, "Taken as a gift (0 gil).");
        return true;
    }

    PChar->pushPacket<GP_SERV_COMMAND_AUC>(GP_CLI_COMMAND_AUC_COMMAND::Bid, 0xC5, param.ItemNo, 0, param.ItemStacks, PItem->getStackSize());
    return true;
}

void spoofBrokeGilDisplay(CBasicPacket& packet)
{
    const uint16 type = packet.getType();
    if (type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_ITEM_NUM))
    {
        if (packet.ref<uint8>(8) == LOC_INVENTORY && packet.ref<uint8>(9) == 0)
        {
            packet.ref<uint32>(4) = DisplayGilWhenBroke;
        }
        return;
    }

    if (type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_ITEM_LIST))
    {
        if (packet.ref<uint16>(8) == static_cast<uint16>(ITEMID::GIL) &&
            packet.ref<uint8>(10) == LOC_INVENTORY &&
            packet.ref<uint8>(11) == 0)
        {
            packet.ref<uint32>(4) = DisplayGilWhenBroke;
        }
        return;
    }

    if (type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_ITEM_ATTR))
    {
        if (packet.ref<uint16>(12) == static_cast<uint16>(ITEMID::GIL) &&
            packet.ref<uint8>(14) == LOC_INVENTORY &&
            packet.ref<uint8>(15) == 0)
        {
            packet.ref<uint32>(4) = DisplayGilWhenBroke;
        }
    }
}

} // namespace

class Ixi20AhGiftsModule : public CPPModule
{
public:
    void OnInit() override
    {
        syncPlayerAhCatalog();
        ShowInfo("Imagine XI 2.0: auction house gift locker loaded (overlay reads data/ah_board.json)");
    }

    void OnTimeServerTick() override
    {
        static TimePoint lastBoardWrite{};
        if (recently(lastBoardWrite, 20))
        {
            return;
        }
        lastBoardWrite = Clock::now();
        writeAhBoardFile();
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr || realGil(PChar) > 0)
        {
            return;
        }

        spoofBrokeGilDisplay(*packet);
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_AUC))
        {
            return false;
        }

        const auto* auc = packet.as<GP_CLI_COMMAND_AUC>();
        if (auc == nullptr)
        {
            return false;
        }

        switch (auc->Command)
        {
            case GP_CLI_COMMAND_AUC_COMMAND::WorkCheck:
            {
                lastAhOpenAt = Clock::now();
                if (PChar->GetLocalVar(ToldVar) == 0)
                {
                    PChar->SetLocalVar(ToldVar, 1);
                    systemMessage(PChar, "Auction House is a gift board: listings cost 0 gil, and anyone can take them for 0 gil.");
                }
                return false;
            }
            case GP_CLI_COMMAND_AUC_COMMAND::LotIn:
                return handleList(PChar, auc->Param.LotIn);
            case GP_CLI_COMMAND_AUC_COMMAND::Bid:
                return handleTake(PChar, auc->Param.Bid);
            case GP_CLI_COMMAND_AUC_COMMAND::LotCancel:
            {
                // Opening the AH / confirming a list sends sale-list 0x0C packets.
                // The client sometimes echoes those as LotCancel and would wipe gifts.
                if (recently(lastAhOpenAt, 8) || recently(lastAhListAt, 8))
                {
                    ShowInfo("Ixi20AhGifts: ignoring LotCancel echo after AH open/list");
                    return true;
                }

                uint16 itemId = 0;
                if (auc->AucWorkIndex >= 0 && static_cast<size_t>(auc->AucWorkIndex) < PChar->m_ah_history.size())
                {
                    itemId = PChar->m_ah_history[auc->AucWorkIndex].itemid;
                }

                auctionutils::CancelSale(PChar, auc->AucWorkIndex);
                if (itemId != 0)
                {
                    forgetUnlistedItem(itemId);
                }
                writeAhBoardFile();
                return true;
            }
            default:
                return false;
        }
    }
};

REGISTER_CPP_MODULE(Ixi20AhGiftsModule);
