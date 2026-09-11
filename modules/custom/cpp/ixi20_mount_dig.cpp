/************************************************************************
 * Imagine XI 2.0: chocobo-dig on any mount, no Gysahl Greens.
 *
 * Stock 0x01A ChocoboDig requires MOUNT_CHOCOBO and spends a green.
 * This consumes that action, runs xi.chocoboDig.start, and plays the
 * dig animation. !dig is the Lua companion (ixi20_mount_dig.lua).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/enums/packet_c2s.h"
#include "map/lua/luautils.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x01a_action.h"
#include "map/packets/s2c/0x02f_dig.h"
#include "map/zone.h"

class Ixi20MountDigModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: mount dig without Gysahl Greens");
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || PChar->loc.zone == nullptr)
        {
            return false;
        }

        if (packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ACTION))
        {
            return false;
        }

        const auto* action = packet.as<GP_CLI_COMMAND_ACTION>();
        if (action == nullptr || action->ActionID != GP_CLI_COMMAND_ACTION_ACTIONID::ChocoboDig)
        {
            return false;
        }

        if (!PChar->isMounted())
        {
            return true;
        }

        if (!luautils::OnChocoboDig(PChar))
        {
            return true;
        }

        PChar->loc.zone->PushPacket(PChar, CHAR_INRANGE_SELF, std::make_unique<GP_SERV_COMMAND_DIG>(PChar));
        return true;
    }
};

REGISTER_CPP_MODULE(Ixi20MountDigModule);
