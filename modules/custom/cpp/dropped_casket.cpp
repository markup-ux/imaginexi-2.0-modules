/************************************************************************
 * Imagine XI 2.0 dropped-item caskets (module only)
 *
 * Intercepts C2S 0x028 ITEM_DUMP and stores the item in a community casket.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/logging.h"
#include "common/settings.h"
#include "common/utils.h"

#include "map/entities/char_entity.h"
#include "map/enums/msg_std.h"
#include "map/enums/packet_c2s.h"
#include "map/item_container.h"
#include "map/items/item.h"
#include "map/items/item_linkshell.h"
#include "map/items/transactions/item_claim.h"
#include "map/linkshell.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x028_item_dump.h"
#include "map/packets/s2c/0x009_message.h"
#include "map/packets/s2c/0x01d_item_same.h"
#include "map/utils/itemutils.h"
#include "map/utils/zoneutils.h"
#include "map/zone.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <mutex>
#include <random>
#include <unordered_set>
#include <vector>

namespace
{

std::mutex                 g_mutex;
std::unordered_set<uint16> g_loadedZones;

struct CasketRow
{
    uint32 id       = 0;
    uint16 zoneid   = 0;
    float  x        = 0.f;
    float  y        = 0.f;
    float  z        = 0.f;
    uint8  rotation = 0;
};

struct CasketItemRow
{
    uint8                                slot     = 0;
    uint16                               itemId   = 0;
    uint32                               quantity = 0;
    std::string                          signature;
    std::array<uint8, CItem::extra_size> extra{};
};

auto zoneIdOf(const CZone* PZone) -> uint16
{
    return PZone ? static_cast<uint16>(PZone->GetID()) : 0;
}

auto zoneIdOf(const CCharEntity* PChar) -> uint16
{
    return PChar && PChar->loc.zone ? zoneIdOf(PChar->loc.zone) : 0;
}

auto communityRadius() -> float
{
    const double v = settings::get<double>("map.DROPPED_CASKET_COMMUNITY_RADIUS");
    return v > 0.0 ? static_cast<float>(v) : 5.f;
}

auto spawnRadiusMin() -> float
{
    const double v = settings::get<double>("map.DROPPED_CASKET_SPAWN_RADIUS_MIN");
    return v > 0.0 ? static_cast<float>(v) : 1.f;
}

auto spawnRadiusMax() -> float
{
    const double v = settings::get<double>("map.DROPPED_CASKET_SPAWN_RADIUS_MAX");
    return std::max(spawnRadiusMin(), v > 0.0 ? static_cast<float>(v) : 3.f);
}

auto maxItemsPerCasket() -> uint32
{
    const double v = settings::get<double>("map.DROPPED_CASKET_MAX_ITEMS");
    return v > 0.0 ? static_cast<uint32>(v) : 100;
}

auto maxCasketsPerZone() -> uint32
{
    const double v = settings::get<double>("map.DROPPED_CASKET_MAX_CASKETS_PER_ZONE");
    return v > 0.0 ? static_cast<uint32>(v) : 32;
}

auto maxCasketsServerWide() -> uint32
{
    const double v = settings::get<double>("map.DROPPED_CASKET_MAX_CASKETS_SERVER");
    return v > 0.0 ? static_cast<uint32>(v) : 5000;
}

auto maxSpawnRetries() -> int
{
    const double v = settings::get<double>("map.DROPPED_CASKET_MAX_SPAWN_RETRIES");
    return static_cast<int>(std::clamp(v > 0.0 ? v : 10.0, 1.0, 50.0));
}

auto persistAcrossRestart() -> bool
{
    return true;
}

auto cleanupAtConquest() -> bool
{
    return true;
}

void logDrop(const CCharEntity* PChar, uint16 itemId, uint32 quantity)
{
    ShowInfoFmt("DroppedCasket DROP player={} zone={} itemId={} qty={}", PChar->getName(), zoneIdOf(PChar), itemId, quantity);
}

void logLoot(const CCharEntity* PChar, uint32 casketId, uint16 itemId, uint32 quantity)
{
    ShowInfoFmt("DroppedCasket LOOT player={} zone={} casket={} itemId={} qty={}", PChar->getName(), zoneIdOf(PChar), casketId, itemId, quantity);
}

auto countItemsInCasket(uint32 casketId) -> uint32
{
    const auto rset = db::preparedStmt("SELECT COUNT(*) AS cnt FROM dropped_casket_items WHERE casket_id = ?", casketId);
    if (!rset || !rset->next())
    {
        return 0;
    }
    return rset->get<uint32>("cnt");
}

auto countCasketsInZone(uint16 zoneid) -> uint32
{
    const auto rset = db::preparedStmt("SELECT COUNT(*) AS cnt FROM dropped_caskets WHERE zoneid = ?", zoneid);
    if (!rset || !rset->next())
    {
        return 0;
    }
    return rset->get<uint32>("cnt");
}

auto countCasketsServerWide() -> uint32
{
    const auto rset = db::preparedStmt("SELECT COUNT(*) AS cnt FROM dropped_caskets");
    if (!rset || !rset->next())
    {
        return 0;
    }
    return rset->get<uint32>("cnt");
}

auto fetchCasketsInZone(uint16 zoneid) -> std::vector<CasketRow>
{
    std::vector<CasketRow> rows;
    const auto             rset = db::preparedStmt("SELECT id, zoneid, x, y, z, rotation FROM dropped_caskets WHERE zoneid = ?", zoneid);
    if (!rset)
    {
        return rows;
    }

    while (rset->next())
    {
        CasketRow row{};
        row.id       = rset->get<uint32>("id");
        row.zoneid   = rset->get<uint16>("zoneid");
        row.x        = rset->get<float>("x");
        row.y        = rset->get<float>("y");
        row.z        = rset->get<float>("z");
        row.rotation = rset->get<uint8>("rotation");
        rows.push_back(row);
    }

    return rows;
}

auto findNearbyCasket(uint16 zoneid, const position_t& origin, float radius, bool requireCapacity) -> CasketRow
{
    CasketRow best{};
    float     bestDist = radius + 1.f;

    for (const auto& row : fetchCasketsInZone(zoneid))
    {
        position_t pos{};
        pos.x = row.x;
        pos.y = row.y;
        pos.z = row.z;

        const float dist = distance(origin, pos);
        if (dist > radius)
        {
            continue;
        }

        if (requireCapacity && countItemsInCasket(row.id) >= maxItemsPerCasket())
        {
            continue;
        }

        if (dist < bestDist)
        {
            bestDist = dist;
            best     = row;
        }
    }

    return best;
}

auto findFreeSlot(uint32 casketId) -> uint8
{
    const auto rset = db::preparedStmt("SELECT slot FROM dropped_casket_items WHERE casket_id = ? ORDER BY slot ASC", casketId);
    if (!rset)
    {
        return 0;
    }

    uint8 expected = 0;
    while (rset->next())
    {
        const uint8 slot = rset->get<uint8>("slot");
        if (slot != expected)
        {
            return expected;
        }
        ++expected;
    }

    if (expected >= maxItemsPerCasket())
    {
        return ERROR_SLOTID;
    }

    return expected;
}

auto positionOverlapsCasket(const position_t& pos, const std::vector<CasketRow>& caskets) -> bool
{
    for (const auto& row : caskets)
    {
        position_t other{};
        other.x = row.x;
        other.y = row.y;
        other.z = row.z;
        if (distance(pos, other) < 1.0f)
        {
            return true;
        }
    }
    return false;
}

auto findSpawnPosition(CZone* PZone, const position_t& origin, const std::vector<CasketRow>& existing) -> position_t
{
    position_t fallback = origin;
    if (PZone == nullptr)
    {
        return fallback;
    }

    std::mt19937                          rng(std::random_device{}());
    std::uniform_real_distribution<float> angleDist(0.f, 2.f * static_cast<float>(M_PI));
    std::uniform_real_distribution<float> radiusDist(spawnRadiusMin(), spawnRadiusMax());

    for (int attempt = 0; attempt < maxSpawnRetries(); ++attempt)
    {
        const float radius    = radiusDist(rng);
        const float theta     = angleDist(rng);
        position_t  candidate = nearPosition(origin, radius, theta);

        if (auto* mesh = PZone->navMesh())
        {
            if (const auto valid = mesh->findFurthestValidPoint(origin, candidate))
            {
                candidate = *valid;
            }
            else
            {
                continue;
            }
        }

        if (positionOverlapsCasket(candidate, existing))
        {
            continue;
        }

        return candidate;
    }

    return fallback;
}

auto insertCasket(uint16 zoneid, const position_t& pos, uint8 rotation) -> uint32
{
    if (!db::preparedStmt("INSERT INTO dropped_caskets (zoneid, x, y, z, rotation) VALUES (?, ?, ?, ?, ?)", zoneid, pos.x, pos.y, pos.z, rotation))
    {
        return 0;
    }

    const auto rset = db::preparedStmt("SELECT LAST_INSERT_ID() AS id");
    if (!rset || !rset->next())
    {
        return 0;
    }
    return rset->get<uint32>("id");
}

auto insertCasketItem(uint32 casketId, uint8 slot, const CItem* PItem) -> bool
{
    std::array<uint8, CItem::extra_size> extraCopy{};
    std::memcpy(extraCopy.data(), PItem->m_extra, sizeof(extraCopy));

    return static_cast<bool>(db::preparedStmt(
        "INSERT INTO dropped_casket_items (casket_id, slot, itemId, quantity, signature, extra) VALUES (?, ?, ?, ?, ?, ?)",
        casketId,
        slot,
        PItem->getID(),
        PItem->getQuantity(),
        PItem->getSignature(),
        extraCopy));
}

auto touchCasket(uint32 casketId) -> void
{
    db::preparedStmt("UPDATE dropped_caskets SET updated_time = CURRENT_TIMESTAMP WHERE id = ?", casketId);
}

auto deleteCasket(uint32 casketId) -> void
{
    db::preparedStmt("DELETE FROM dropped_caskets WHERE id = ?", casketId);
}

auto fetchCasketItems(uint32 casketId) -> std::vector<CasketItemRow>
{
    std::vector<CasketItemRow> items;
    const auto                 rset = db::preparedStmt(
        "SELECT slot, itemId, quantity, signature, extra FROM dropped_casket_items WHERE casket_id = ? ORDER BY slot ASC",
        casketId);
    if (!rset)
    {
        return items;
    }

    while (rset->next())
    {
        CasketItemRow row{};
        row.slot      = rset->get<uint8>("slot");
        row.itemId    = rset->get<uint16>("itemId");
        row.quantity  = rset->get<uint32>("quantity");
        row.signature = rset->get<std::string>("signature");
        db::extractFromBlob(rset, "extra", row.extra);
        items.push_back(row);
    }

    return items;
}

auto spawnCasketLua(CZone* PZone, const CasketRow& row, bool isNew) -> void
{
    if (PZone == nullptr || row.id == 0)
    {
        return;
    }

    luautils::callGlobal<void>("xi.droppedCasket.spawnCasket", PZone, row.id, row.x, row.y, row.z, row.rotation, isNew);
}

auto despawnCasketLua(CZone* PZone, uint32 casketId) -> void
{
    if (PZone == nullptr || casketId == 0)
    {
        return;
    }

    luautils::callGlobal<void>("xi.droppedCasket.despawnCasket", PZone, casketId);
}

auto despawnAllInZoneLua(CZone* PZone) -> void
{
    if (PZone == nullptr)
    {
        return;
    }

    luautils::callGlobal<void>("xi.droppedCasket.despawnAllInZone", PZone);
}

auto resolveOrCreateCasket(CCharEntity* PChar, CZone* PZone, bool& createdNew, CasketRow& outRow) -> bool
{
    createdNew = false;
    outRow     = {};

    const position_t origin = PChar->loc.p;
    const uint16     zoneid = zoneIdOf(PChar);

    outRow = findNearbyCasket(zoneid, origin, communityRadius(), true);
    if (outRow.id != 0)
    {
        return true;
    }

    if (countCasketsInZone(zoneid) >= maxCasketsPerZone())
    {
        ShowWarningFmt("DroppedCasket: zone {} at casket cap", zoneid);
        return false;
    }

    if (countCasketsServerWide() >= maxCasketsServerWide())
    {
        ShowWarning("DroppedCasket: server at casket cap");
        return false;
    }

    const auto existing = fetchCasketsInZone(zoneid);
    const auto spawnPos = findSpawnPosition(PZone, origin, existing);
    const auto casketId = insertCasket(zoneid, spawnPos, PChar->loc.p.rotation);
    if (casketId == 0)
    {
        return false;
    }

    outRow.id       = casketId;
    outRow.zoneid   = zoneid;
    outRow.x        = spawnPos.x;
    outRow.y        = spawnPos.y;
    outRow.z        = spawnPos.z;
    outRow.rotation = PChar->loc.p.rotation;
    createdNew      = true;
    return true;
}

auto tryPlayerDrop(CCharEntity* PChar, uint8 container, uint8 slotID, uint32 quantity) -> bool
{
    if (PChar == nullptr)
    {
        return false;
    }

    std::lock_guard<std::mutex> lock(g_mutex);

    auto* PZone = PChar->loc.zone;
    if (PZone == nullptr)
    {
        return false;
    }

    auto* PSrcItem = PChar->getStorage(container)->GetItem(slotID);
    if (PSrcItem == nullptr || PSrcItem->isBusy())
    {
        return false;
    }

    quantity = std::min(quantity, PSrcItem->getQuantity());
    if (quantity == 0)
    {
        return false;
    }

    auto PDropped = xi::items::clone(*PSrcItem);
    if (PDropped == nullptr)
    {
        return false;
    }
    PDropped->setQuantity(quantity);

    bool      createdNew = false;
    CasketRow casket{};
    if (!resolveOrCreateCasket(PChar, PZone, createdNew, casket))
    {
        PChar->pushPacket<GP_SERV_COMMAND_MESSAGE>(PSrcItem->getID(), MsgStd::UnableToThrowAway);
        return true;
    }

    const uint8 itemSlot = findFreeSlot(casket.id);
    if (itemSlot == ERROR_SLOTID)
    {
        PChar->pushPacket<GP_SERV_COMMAND_MESSAGE>(PSrcItem->getID(), MsgStd::UnableToThrowAway);
        return true;
    }

    if (!insertCasketItem(casket.id, itemSlot, PDropped.get()))
    {
        if (createdNew)
        {
            deleteCasket(casket.id);
        }
        PChar->pushPacket<GP_SERV_COMMAND_MESSAGE>(PSrcItem->getID(), MsgStd::UnableToThrowAway);
        return true;
    }

    touchCasket(casket.id);

    uint32      breakLsid = 0;
    const bool  breakLS   = [&]() {
        if (auto* itemLinkshell = dynamic_cast<CItemLinkshell*>(PSrcItem))
        {
            if (itemLinkshell->GetLSType() == LSTYPE_LINKSHELL)
            {
                breakLsid = itemLinkshell->GetLSID();
                return true;
            }
        }
        return false;
    }();

    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction || !transaction->take(container, slotID, quantity) || !transaction->commit())
    {
        db::preparedStmt("DELETE FROM dropped_casket_items WHERE casket_id = ? AND slot = ?", casket.id, itemSlot);
        if (createdNew)
        {
            deleteCasket(casket.id);
        }
        PChar->pushPacket<GP_SERV_COMMAND_MESSAGE>(PSrcItem->getID(), MsgStd::UnableToThrowAway);
        return true;
    }

    if (breakLS && breakLsid != 0)
    {
        CLinkshell* PLinkshell = linkshell::GetLinkshell(breakLsid);
        if (!PLinkshell)
        {
            PLinkshell = linkshell::LoadLinkshell(breakLsid);
        }
        if (PLinkshell)
        {
            PLinkshell->BreakLinkshell();
            linkshell::UnloadLinkshell(breakLsid);
        }
    }

    logDrop(PChar, PDropped->getID(), quantity);
    PChar->pushPacket<GP_SERV_COMMAND_MESSAGE>(nullptr, PDropped->getID(), quantity, MsgStd::ThrowAway);
    PChar->pushPacket<GP_SERV_COMMAND_ITEM_SAME>(PChar);

    if (createdNew)
    {
        spawnCasketLua(PZone, casket, true);
    }

    return true;
}

auto lootItem(CCharEntity* PChar, uint32 casketId, uint8 slot) -> uint8
{
    if (PChar == nullptr || casketId == 0)
    {
        return ERROR_SLOTID;
    }

    std::lock_guard<std::mutex> lock(g_mutex);

    const auto rset = db::preparedStmt(
        "SELECT itemId, quantity, signature, extra FROM dropped_casket_items WHERE casket_id = ? AND slot = ? LIMIT 1",
        casketId,
        slot);
    if (!rset || !rset->next())
    {
        return ERROR_SLOTID;
    }

    const uint16 itemId   = rset->get<uint16>("itemId");
    const uint32 quantity = rset->get<uint32>("quantity");

    auto PItem = xi::items::spawn(itemId);
    if (PItem == nullptr)
    {
        return ERROR_SLOTID;
    }

    PItem->setQuantity(quantity);
    PItem->setSignature(rset->get<std::string>("signature"));
    db::extractFromBlob(rset, "extra", PItem->m_extra);

    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        return ERROR_SLOTID;
    }

    const auto playerSlot = transaction->give(LOC_INVENTORY, std::move(PItem), Silence::Yes);
    if (!playerSlot || !transaction->commit())
    {
        return ERROR_SLOTID;
    }

    db::preparedStmt("DELETE FROM dropped_casket_items WHERE casket_id = ? AND slot = ?", casketId, slot);
    logLoot(PChar, casketId, itemId, quantity);

    if (countItemsInCasket(casketId) == 0)
    {
        deleteCasket(casketId);
        if (PChar->loc.zone)
        {
            despawnCasketLua(PChar->loc.zone, casketId);
        }
    }

    return *playerSlot;
}

void loadZone(CZone* PZone)
{
    if (!persistAcrossRestart() || PZone == nullptr)
    {
        return;
    }

    const uint16 zoneid = zoneIdOf(PZone);
    if (!g_loadedZones.insert(zoneid).second)
    {
        return;
    }

    for (const auto& row : fetchCasketsInZone(zoneid))
    {
        if (countItemsInCasket(row.id) == 0)
        {
            deleteCasket(row.id);
            continue;
        }
        spawnCasketLua(PZone, row, false);
    }
}

void cleanupAll()
{
    if (!cleanupAtConquest())
    {
        return;
    }

    std::lock_guard<std::mutex> lock(g_mutex);

    uint32 casketCount = 0;
    uint32 itemCount   = 0;

    if (const auto itemRset = db::preparedStmt("SELECT COUNT(*) AS cnt FROM dropped_casket_items"); itemRset && itemRset->next())
    {
        itemCount = itemRset->get<uint32>("cnt");
    }
    if (const auto casketRset = db::preparedStmt("SELECT COUNT(*) AS cnt FROM dropped_caskets"); casketRset && casketRset->next())
    {
        casketCount = casketRset->get<uint32>("cnt");
    }

    zoneutils::ForEachZone([](CZone* PZone) {
        despawnAllInZoneLua(PZone);
    });

    db::preparedStmt("DELETE FROM dropped_casket_items");
    db::preparedStmt("DELETE FROM dropped_caskets");
    g_loadedZones.clear();

    ShowInfoFmt("DroppedCasket CONQUEST_CLEANUP caskets={} items={}", casketCount, itemCount);
}

auto handleItemDump(CCharEntity* PChar, CBasicPacket& packet) -> bool
{
    const auto* dump = packet.as<GP_CLI_COMMAND_ITEM_DUMP>();
    if (dump == nullptr || PChar == nullptr)
    {
        return false;
    }

    if (dump->Category == LOC_INVENTORY && dump->ItemIndex == 0)
    {
        return false;
    }

    if (dump->ItemNum == 0)
    {
        return false;
    }

    CItem* PItem = PChar->getStorage(dump->Category)->GetItem(dump->ItemIndex);
    if (!PItem || PItem->isBusy() || PItem->getQuantity() < dump->ItemNum)
    {
        return false;
    }

    if (PItem->isStorageSlip())
    {
        int slipData = 0;
        for (int i = 0; i < static_cast<int>(CItem::extra_size); ++i)
        {
            slipData += PItem->m_extra[i];
        }
        if (slipData != 0)
        {
            return false;
        }
    }

    return tryPlayerDrop(PChar, dump->Category, dump->ItemIndex, dump->ItemNum);
}

} // namespace

class DroppedCasketModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua.set_function("DropCasketItem", [](CLuaBaseEntity PLuaEntity, uint32 casketId, uint8 slot) -> bool {
            auto* PChar = dynamic_cast<CCharEntity*>(PLuaEntity.GetBaseEntity());
            if (!PChar)
            {
                return false;
            }
            return lootItem(PChar, casketId, slot) != ERROR_SLOTID;
        });

        lua.set_function("GetDroppedCasketItems", [this](uint32 casketId) -> sol::table {
            sol::table out = lua.create_table();
            int        idx = 1;
            for (const auto& row : fetchCasketItems(casketId))
            {
                sol::table entry  = lua.create_table();
                entry["slot"]     = row.slot;
                entry["itemId"]   = row.itemId;
                entry["quantity"] = row.quantity;
                out[idx++]        = entry;
            }
            return out;
        });

        lua.set_function("CleanupDroppedCaskets", []() {
            cleanupAll();
        });

        ShowInfo("Imagine XI 2.0: dropped casket module loaded");
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        if (PChar && PChar->loc.zone)
        {
            loadZone(PChar->loc.zone);
        }
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;
        if (packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ITEM_DUMP))
        {
            return false;
        }

        return handleItemDump(PChar, packet);
    }
};

REGISTER_CPP_MODULE(DroppedCasketModule);
