/************************************************************************
 * Imagine XI 2.0: mounts usable in main cities (module only).
 *
 * 1.0 set MISC_MOUNT on city zone_settings rows. 2.0 reads misc from
 * YAML and CZone::m_miscMask is private, so this:
 *   - handles /mount in those cities (stock CanUseMisc rejects)
 *   - remounts after CharZoneIn strips the effect
 *   - lets rental chocobos zone into those cities
 ************************************************************************/

#include "ixi20_city_mounts.h"

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/timer.h"

#include "map/entities/char_entity.h"
#include "map/enums/key_items.h"
#include "map/enums/msg_basic.h"
#include "map/enums/packet_c2s.h"
#include "map/enums/recast.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x01a_action.h"
#include "map/packets/c2s/0x05e_maprect.h"
#include "map/packets/s2c/0x029_battle_message.h"
#include "map/packets/s2c/0x119_abil_recast.h"
#include "map/recast_container.h"
#include "map/status_effect.h"
#include "map/status_effect_container.h"
#include "map/utils/charutils.h"
#include "map/zone.h"

#include "data/enums/animation.h"
#include "data/enums/zone_misc.h"

#include <chrono>

using namespace std::chrono_literals;

namespace
{

constexpr const char* MountPowerVar    = "ixi20CityMountP";
constexpr const char* MountSubPowerVar = "ixi20CityMountS";
constexpr const char* MountSecondsVar  = "ixi20CityMountT";

constexpr uint8 MountMinLevel = 10;

void snapshotMount(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    const auto* effect = PChar->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Mounted);
    if (effect == nullptr)
    {
        PChar->setCharVar(MountPowerVar, 0);
        PChar->setCharVar(MountSubPowerVar, 0);
        PChar->setCharVar(MountSecondsVar, 0);
        return;
    }

    auto remaining = effect->GetDuration() - (timer::now() - effect->GetStartTime());
    if (remaining < 1s)
    {
        remaining = 1s;
    }

    PChar->setCharVar(MountPowerVar, effect->GetPower());
    PChar->setCharVar(MountSubPowerVar, effect->GetSubPower());
    PChar->setCharVar(MountSecondsVar, static_cast<int32>(timer::count_seconds(remaining)));
}

void clearMountSnapshot(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    PChar->setCharVar(MountPowerVar, 0);
    PChar->setCharVar(MountSubPowerVar, 0);
    PChar->setCharVar(MountSecondsVar, 0);
}

void remountFromSnapshot(CCharEntity* PChar)
{
    if (PChar == nullptr || PChar->getCharVar(MountSecondsVar) <= 0)
    {
        return;
    }

    if (PChar->isMounted() || PChar->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Mounted))
    {
        clearMountSnapshot(PChar);
        return;
    }

    const auto power    = static_cast<uint16>(PChar->getCharVar(MountPowerVar));
    const auto subPower = static_cast<uint16>(PChar->getCharVar(MountSubPowerVar));
    auto       seconds  = PChar->getCharVar(MountSecondsVar);
    if (seconds <= 0)
    {
        seconds = 1;
    }

    PChar->m_mountId = static_cast<uint8>(power);
    PChar->StatusEffectContainer->AddStatusEffectSilent(
        xi::StatusEffect::Mounted,
        static_cast<uint16>(xi::StatusEffect::Mounted),
        power,
        0s,
        std::chrono::seconds(seconds),
        0,
        subPower);

    luautils::OnPlayerMount(PChar);
    clearMountSnapshot(PChar);
}

void tryMountInCity(CCharEntity* PChar, uint32 mountId)
{
    if (PChar == nullptr || PChar->loc.zone == nullptr)
    {
        return;
    }

    const uint32 maxMountId = 3108 - static_cast<uint16_t>(KeyItem::CHOCOBO_COMPANION);
    if (mountId > maxMountId)
    {
        return;
    }

    const auto mountKeyItem = static_cast<KeyItem>(static_cast<uint16_t>(KeyItem::CHOCOBO_COMPANION) + mountId);

    if (PChar->animation != xi::Animation::None || PChar->StatusEffectContainer->HasPreventActionEffect())
    {
        PChar->pushPacket<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::CannotPerformAction);
        return;
    }

    if (PChar->GetMLevel() < MountMinLevel)
    {
        PChar->pushPacket<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, MountMinLevel, 0, MsgBasic::MountRequiredLevel);
        return;
    }

    if (!charutils::hasKeyItem(PChar, mountKeyItem))
    {
        return;
    }

    if (PChar->PRecastContainer->HasRecast(RECAST_ABILITY, Recast::Mount, 60s))
    {
        PChar->pushPacket<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::WaitLonger);
        return;
    }

    if (PChar->hasEnmityEXPENSIVE())
    {
        PChar->pushPacket<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::YourMountRefuses);
        return;
    }

    PChar->m_mountId = mountId ? mountId + 1 : 0;
    PChar->StatusEffectContainer->AddStatusEffectSilent(
        xi::StatusEffect::Mounted,
        static_cast<uint16>(xi::StatusEffect::Mounted),
        mountId ? mountId + 1 : 0,
        0s,
        30min,
        0,
        0x40);

    PChar->PRecastContainer->Add(RECAST_ABILITY, Recast::Mount, 60s);
    PChar->pushPacket<GP_SERV_COMMAND_ABIL_RECAST>(PChar);
    luautils::OnPlayerMount(PChar);
}

auto allowRentalIntoCity(CCharEntity* PChar, CBasicPacket& packet) -> bool
{
    const auto* maprect = packet.as<GP_CLI_COMMAND_MAPRECT>();
    if (maprect == nullptr || PChar == nullptr || PChar->loc.zone == nullptr)
    {
        return false;
    }

    auto* effect = PChar->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Mounted);
    if (effect == nullptr || effect->GetPower() != MOUNT_CHOCOBO || effect->GetSubPower() != 0)
    {
        return false;
    }

    const auto* zoneLine = PChar->loc.zone->GetZoneLine(maprect->RectID);
    if (zoneLine == nullptr || !ixi20::isMainCityMountZone(zoneLine->destinationZoneId))
    {
        return false;
    }

    // Stock maprect denies rental chocobos when the dest YAML lacks mount.
    // Mark this ride as a personal mount for that one check.
    effect->SetSubPower(0x40);
    return false;
}

} // namespace

class Ixi20CityMountsModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: mounts usable in main cities");
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        if (PChar == nullptr)
        {
            return;
        }

        const bool mounted = PChar->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Mounted);
        const auto dest    = PChar->loc.destination;
        const bool destCity = dest != xi::ZoneId::Unknown && ixi20::isMainCityMountZone(dest);
        const bool logoutInCity = dest == xi::ZoneId::Unknown && PChar->loc.zone != nullptr &&
                                  ixi20::isMainCityMountZone(PChar->loc.zone->GetID());

        if (mounted && (destCity || logoutInCity))
        {
            snapshotMount(PChar);
            return;
        }

        clearMountSnapshot(PChar);
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        if (PChar == nullptr || PChar->loc.zone == nullptr)
        {
            return;
        }

        if (ixi20::isMainCityMountZone(PChar->loc.zone->GetID()))
        {
            remountFromSnapshot(PChar);
            return;
        }

        clearMountSnapshot(PChar);
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr)
        {
            return false;
        }

        const auto packetType = packet.getType();
        if (packetType == static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_MAPRECT))
        {
            return allowRentalIntoCity(PChar, packet);
        }

        if (packetType != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ACTION))
        {
            return false;
        }

        const auto* action = packet.as<GP_CLI_COMMAND_ACTION>();
        if (action == nullptr || action->ActionID != GP_CLI_COMMAND_ACTION_ACTIONID::Mount)
        {
            return false;
        }

        if (PChar->loc.zone == nullptr || !ixi20::isMainCityMountZone(PChar->loc.zone->GetID()))
        {
            return false;
        }

        if (PChar->loc.zone->CanUseMisc(xi::ZoneMisc::Mount))
        {
            return false;
        }

        tryMountInCity(PChar, action->Mount.MountId);
        return true;
    }
};

REGISTER_CPP_MODULE(Ixi20CityMountsModule);
