/************************************************************************
 * Imagine XI 2.0: persist buffs stay only while the caster is in party.
 *
 * Lua ixi20_enhancing_persist.lua owns the rule. This module fires
 * listeners after party list updates and after a real main-job change.
 * No trampolines.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/ai/ai_container.h"
#include "map/entities/char_entity.h"
#include "map/enums/packet_c2s.h"
#include "map/enums/packet_s2c.h"
#include "map/packets/basic.h"

#include <unordered_map>

namespace
{

std::unordered_map<uint32, uint8> g_pendingMainJob;

void fireListener(CCharEntity* PChar, const char* eventName)
{
    if (PChar == nullptr || PChar->PAI == nullptr)
    {
        return;
    }

    PChar->PAI->EventHandler.triggerListener(eventName, PChar);
}

} // namespace

class Ixi20PersistPartyModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: persist party hook loaded (caster must stay in party)");
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        fireListener(PChar, "IXI20_PERSIST_AUDIT");
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr)
        {
            return;
        }

        const uint16 type = packet->getType();
        if (type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_GROUP_TBL))
        {
            fireListener(PChar, "IXI20_PERSIST_AUDIT");
            return;
        }

        if (type != static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_JOB_INFO))
        {
            return;
        }

        const auto pending = g_pendingMainJob.find(PChar->id);
        if (pending == g_pendingMainJob.end())
        {
            return;
        }

        const uint8 oldMain = pending->second;
        g_pendingMainJob.erase(pending);

        if (static_cast<uint8>(PChar->GetMJob()) != oldMain)
        {
            fireListener(PChar, "IXI20_PERSIST_JOB");
        }
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_MYROOM_JOB))
        {
            return false;
        }

        g_pendingMainJob[PChar->id] = static_cast<uint8>(PChar->GetMJob());
        return false;
    }
};

REGISTER_CPP_MODULE(Ixi20PersistPartyModule);
