/************************************************************************
 * Imagine XI 2.0: mounts usable at main level 10 (module only).
 *
 * Stock LSB rejects /mount below 20. 1.0 lowered that check to 10.
 * This intercepts Mount packets under 20 so core src stays untouched.
 ************************************************************************/

#include "ixi20_city_mounts.h"

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/enums/key_items.h"
#include "map/enums/msg_basic.h"
#include "map/enums/packet_c2s.h"
#include "map/enums/recast.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x01a_action.h"
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

constexpr uint8 MountMinLevel = 10;

void tryMountAtTen(CCharEntity* PChar, uint32 mountId)
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

    if (!ixi20::zoneAllowsIxi20Mount(PChar->loc.zone))
    {
        PChar->pushPacket<GP_SERV_COMMAND_BATTLE_MESSAGE>(PChar, PChar, 0, 0, MsgBasic::CannotUseInArea);
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

} // namespace

class Ixi20MountLevelModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: mounts usable at level %u", MountMinLevel);
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ACTION))
        {
            return false;
        }

        const auto* action = packet.as<GP_CLI_COMMAND_ACTION>();
        if (action == nullptr || action->ActionID != GP_CLI_COMMAND_ACTION_ACTIONID::Mount)
        {
            return false;
        }

        // Stock handler still requires 20. Handle 1-19 here so 10-19 can mount.
        if (PChar->GetMLevel() >= 20)
        {
            return false;
        }

        tryMountAtTen(PChar, action->Mount.MountId);
        return true;
    }
};

REGISTER_CPP_MODULE(Ixi20MountLevelModule);
