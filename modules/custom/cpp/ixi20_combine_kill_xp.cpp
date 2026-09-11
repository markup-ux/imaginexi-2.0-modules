/************************************************************************
 * Imagine XI 2.0: one "gains X experience points" line per kill burst.
 *
 * Combat, RoE exp, sparks-as-XP, gil-as-XP, and book XP each call
 * AddExperiencePoints on their own. Fold those 0x02D messages into the
 * first one in the same zone tick so the client only prints a total.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/enums/msg_basic.h"
#include "map/enums/packet_s2c.h"
#include "map/packets/basic.h"

#include <unordered_map>

namespace
{

// GP_SERV_HEADER (4) + UniqueNoCas/Tar (8) + ActIndexCas/Tar (4) + Data (4)
constexpr std::size_t kExpParamOffset    = 16;
constexpr std::size_t kExpChainOffset    = 20;
constexpr std::size_t kMessageNumOffset  = 24;

std::unordered_map<uint32, CBasicPacket*> g_xpAnchor;

auto isXpGainMessage(MsgBasic message) -> bool
{
    switch (message)
    {
        case MsgBasic::ExperiencePointsGained:
        case MsgBasic::ExpChain:
        case MsgBasic::LimitPointsGained:
        case MsgBasic::LimitChain:
            return true;
        default:
            return false;
    }
}

auto collapseToPlainGain(MsgBasic message) -> MsgBasic
{
    switch (message)
    {
        case MsgBasic::LimitChain:
        case MsgBasic::LimitPointsGained:
            return MsgBasic::LimitPointsGained;
        default:
            return MsgBasic::ExperiencePointsGained;
    }
}

auto dropPacket(const std::unique_ptr<CBasicPacket>& packet) -> void
{
    // Size 0 is omitted from the wire copy, so the client never sees it.
    packet->setSize(0);
}

} // namespace

class Ixi20CombineKillXpModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: kill XP chat combine loaded");
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr)
        {
            return;
        }

        if (packet->getType() != static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_BATTLE_MESSAGE2))
        {
            return;
        }

        const auto message = static_cast<MsgBasic>(packet->ref<uint16>(kMessageNumOffset));
        if (!isXpGainMessage(message))
        {
            return;
        }

        const uint32 exp = packet->ref<uint32>(kExpParamOffset);
        if (exp == 0)
        {
            dropPacket(packet);
            return;
        }

        auto& anchor = g_xpAnchor[PChar->id];
        if (anchor == nullptr || anchor == packet.get())
        {
            anchor = packet.get();
            return;
        }

        anchor->ref<uint32>(kExpParamOffset) += exp;
        anchor->ref<uint32>(kExpChainOffset)  = 0;
        anchor->ref<uint16>(kMessageNumOffset) =
            static_cast<uint16>(collapseToPlainGain(static_cast<MsgBasic>(anchor->ref<uint16>(kMessageNumOffset))));
        dropPacket(packet);
    }

    void OnZoneTick(CZone* PZone) override
    {
        (void)PZone;
        g_xpAnchor.clear();
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        if (PChar)
        {
            g_xpAnchor.erase(PChar->id);
        }
    }
};

REGISTER_CPP_MODULE(Ixi20CombineKillXpModule);
