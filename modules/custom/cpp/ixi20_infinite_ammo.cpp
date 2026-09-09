/************************************************************************
 * Imagine XI 2.0 unlimited combat ammo (module only)
 *
 * Lua player:removeAmmo is a no-op when map.DISABLE_AMMO_CONSUMPTION.
 * C++ RemoveAmmo (ranged auto-attack, Daken+Sange) is reversed after ITEM_SAME.
 * Fishing bait is left alone. Recycle-as-Snapshot is not ported.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/enums/chat_message_type.h"
#include "map/enums/packet_c2s.h"
#include "map/item_container.h"
#include "map/items/item_weapon.h"
#include "map/items/transactions/item_claim.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x01a_action.h"
#include "map/packets/s2c/0x017_chat_std.h"
#include "map/utils/charutils.h"

#include "data/enums/job.h"
#include "enums/packet_s2c.h"

#include <mutex>
#include <unordered_map>

namespace
{

struct AmmoTrack
{
    uint16   itemId        = 0;
    uint32   quantity      = 0;
    bool     pendingCombat = false;
    bool     restoring     = false;
    bool     seenJobs      = false;
    xi::Job  lastMainJob   = xi::Job::NONE;
    xi::Job  lastSubJob    = xi::Job::NONE;
};

std::mutex                           g_mutex;
std::unordered_map<uint32, AmmoTrack> g_tracks;

auto ammoDisabled() -> bool
{
    return settings::get<bool>("map.DISABLE_AMMO_CONSUMPTION");
}

auto usesAmmoSlotJob(xi::Job job) -> bool
{
    return job == xi::Job::RNG || job == xi::Job::COR || job == xi::Job::NIN;
}

auto isCombatAmmo(const CItem* PItem) -> bool
{
    const auto* weapon = dynamic_cast<const CItemWeapon*>(PItem);
    return weapon != nullptr && weapon->isRanged();
}

auto currentCombatAmmo(CCharEntity* PChar) -> CItemWeapon*
{
    if (PChar == nullptr)
    {
        return nullptr;
    }

    auto* PAmmo = dynamic_cast<CItemWeapon*>(PChar->getEquip(SLOT_AMMO));
    if (!isCombatAmmo(PAmmo))
    {
        return nullptr;
    }

    return PAmmo;
}

auto trackOf(uint32 charId) -> AmmoTrack&
{
    return g_tracks[charId];
}

void snapshotAmmo(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    std::lock_guard lock(g_mutex);
    auto&           track = trackOf(PChar->id);
    if (const auto* PAmmo = currentCombatAmmo(PChar))
    {
        track.itemId   = PAmmo->getID();
        track.quantity = PAmmo->getQuantity();
    }
    else
    {
        track.itemId   = 0;
        track.quantity = 0;
    }
}

void acceptPlayerAmmoChange(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    std::lock_guard lock(g_mutex);
    auto&           track = trackOf(PChar->id);
    track.pendingCombat   = false;
    if (const auto* PAmmo = currentCombatAmmo(PChar))
    {
        track.itemId   = PAmmo->getID();
        track.quantity = PAmmo->getQuantity();
    }
    else
    {
        track.itemId   = 0;
        track.quantity = 0;
    }
}

void markPendingCombat(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    std::lock_guard lock(g_mutex);
    auto&           track = trackOf(PChar->id);
    if (const auto* PAmmo = currentCombatAmmo(PChar))
    {
        track.itemId        = PAmmo->getID();
        track.quantity      = PAmmo->getQuantity();
        track.pendingCombat = true;
    }
}

auto tryMergeAmmo(CCharEntity* PChar, CItemWeapon* PAmmo, uint32 missing) -> bool
{
    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        return false;
    }

    const uint8 loc     = PAmmo->getLocationID();
    const uint8 slot    = PAmmo->getSlotID();
    const auto  tmpSlot = transaction->give(LOC_INVENTORY, PAmmo->getID(), missing);
    return tmpSlot.has_value() &&
           transaction->moveBetween(LOC_INVENTORY, *tmpSlot, loc, slot, missing) &&
           transaction->commit();
}

auto tryGiveAndEquip(CCharEntity* PChar, uint16 itemId, uint32 quantity) -> bool
{
    auto transaction = ItemClaimTransaction::start(PChar);
    if (!transaction)
    {
        return false;
    }

    const auto newSlot = transaction->give(LOC_INVENTORY, itemId, quantity);
    if (!newSlot || !transaction->commit())
    {
        return false;
    }

    charutils::EquipItem(PChar, *newSlot, SLOT_AMMO, LOC_INVENTORY);
    return true;
}

void restoreCombatAmmo(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    uint16 itemId   = 0;
    uint32 quantity = 0;

    {
        std::lock_guard lock(g_mutex);
        auto&           track = trackOf(PChar->id);
        if (track.restoring || !track.pendingCombat || track.itemId == 0 || track.quantity == 0)
        {
            return;
        }

        itemId          = track.itemId;
        quantity        = track.quantity;
        track.restoring = true;
    }

    auto* PAmmo = dynamic_cast<CItemWeapon*>(PChar->getEquip(SLOT_AMMO));
    bool  ok    = true;

    if (PAmmo && PAmmo->getID() == itemId)
    {
        if (PAmmo->getQuantity() < quantity)
        {
            const uint32 missing = quantity - PAmmo->getQuantity();
            ok                   = tryMergeAmmo(PChar, PAmmo, missing);
            if (!ok)
            {
                ok = tryGiveAndEquip(PChar, itemId, quantity);
            }
        }
    }
    else if (PAmmo == nullptr)
    {
        ok = tryGiveAndEquip(PChar, itemId, quantity);
    }

    {
        std::lock_guard lock(g_mutex);
        auto&           track = trackOf(PChar->id);
        track.restoring       = false;
        if (ok)
        {
            if (const auto* restored = currentCombatAmmo(PChar))
            {
                track.itemId   = restored->getID();
                track.quantity = restored->getQuantity();
            }
        }
    }

    if (!ok)
    {
        ShowWarningFmt("Ixi20InfiniteAmmo: could not restore ammo {} x{} for {}", itemId, quantity, PChar->getName());
    }
}

void maybeRemindJobChange(CCharEntity* PChar)
{
    if (PChar == nullptr || !ammoDisabled())
    {
        return;
    }

    const xi::Job mj = PChar->GetMJob();
    const xi::Job sj = PChar->GetSJob();
    bool          print = false;

    {
        std::lock_guard lock(g_mutex);
        auto&           track = trackOf(PChar->id);
        if (!track.seenJobs)
        {
            track.seenJobs    = true;
            track.lastMainJob = mj;
            track.lastSubJob  = sj;
            return;
        }

        if (track.lastMainJob == mj && track.lastSubJob == sj)
        {
            return;
        }

        track.lastMainJob = mj;
        track.lastSubJob  = sj;
        print             = usesAmmoSlotJob(mj) || usesAmmoSlotJob(sj);
    }

    if (print)
    {
        PChar->pushPacket<GP_SERV_COMMAND_CHAT_STD>(PChar, MESSAGE_SYSTEM_3, "Imagine: Ammo is not consumed here.");
    }
}

auto isCombatAction(const CBasicPacket& packet) -> bool
{
    const auto* action = packet.as<GP_CLI_COMMAND_ACTION>();
    if (action == nullptr)
    {
        return false;
    }

    switch (action->ActionID)
    {
        case GP_CLI_COMMAND_ACTION_ACTIONID::Shoot:
        case GP_CLI_COMMAND_ACTION_ACTIONID::Attack:
        case GP_CLI_COMMAND_ACTION_ACTIONID::Weaponskill:
        case GP_CLI_COMMAND_ACTION_ACTIONID::JobAbility:
            return true;
        default:
            return false;
    }
}

auto isPlayerItemIntent(uint16 packetType) -> bool
{
    switch (packetType)
    {
        case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ITEM_DUMP):
        case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ITEM_MOVE):
        case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ITEM_TRANSFER):
        case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_EQUIP_SET):
        case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_EQUIPSET_SET):
        case static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_FISHING):
            return true;
        default:
            return false;
    }
}

} // namespace

class Ixi20InfiniteAmmoModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (lua["CBaseEntity"].valid())
        {
            lua["CBaseEntity"]["removeAmmo"] = [](CLuaBaseEntity entity, sol::optional<sol::object> ammoUsed) {
                if (ammoDisabled())
                {
                    return;
                }

                entity.removeAmmo(ammoUsed ? *ammoUsed : sol::object());
            };
        }
        else
        {
            ShowWarning("Ixi20InfiniteAmmo: CBaseEntity usertype missing; removeAmmo wrap skipped");
        }

        ShowInfo("Imagine XI 2.0: infinite ammo module loaded");
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        snapshotAmmo(PChar);
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        if (PChar == nullptr)
        {
            return;
        }

        std::lock_guard lock(g_mutex);
        g_tracks.erase(PChar->id);
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr || !ammoDisabled())
        {
            return;
        }

        const uint16 type = packet->getType();
        if (type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_JOB_INFO))
        {
            maybeRemindJobChange(PChar);
            return;
        }

        if (type != static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_ITEM_SAME))
        {
            return;
        }

        restoreCombatAmmo(PChar);
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || !ammoDisabled())
        {
            return false;
        }

        const uint16 type = packet.getType();
        if (type == static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ACTION))
        {
            if (isCombatAction(packet))
            {
                markPendingCombat(PChar);
            }
            else if (packet.as<GP_CLI_COMMAND_ACTION>() &&
                     packet.as<GP_CLI_COMMAND_ACTION>()->ActionID == GP_CLI_COMMAND_ACTION_ACTIONID::Fish)
            {
                acceptPlayerAmmoChange(PChar);
            }

            return false;
        }

        if (isPlayerItemIntent(type))
        {
            acceptPlayerAmmoChange(PChar);
        }

        return false;
    }
};

REGISTER_CPP_MODULE(Ixi20InfiniteAmmoModule);
