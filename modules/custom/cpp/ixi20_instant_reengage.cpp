/************************************************************************
 * Imagine XI 2.0: instant re-engage after disengage (1.0 module).
 *
 * Stock attack lockout shows "wait longer" if you /attack immediately
 * after disengaging. Reset the last-attack clock so the next Attack
 * packet can engage. Official handler still runs (return false).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/timer.h"

#include "map/ai/ai_container.h"
#include "map/ai/controllers/player_controller.h"
#include "map/entities/char_entity.h"
#include "map/enums/packet_c2s.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x01a_action.h"

#include <chrono>

class Ixi20InstantReengageModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: instant re-engage after disengage");
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || PChar->PAI == nullptr)
        {
            return false;
        }

        if (packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ACTION))
        {
            return false;
        }

        const auto* action = packet.as<GP_CLI_COMMAND_ACTION>();
        if (action == nullptr || action->ActionID != GP_CLI_COMMAND_ACTION_ACTIONID::Attack)
        {
            return false;
        }

        if (PChar->PAI->IsEngaged())
        {
            return false;
        }

        if (auto* controller = dynamic_cast<CPlayerController*>(PChar->PAI->GetController()))
        {
            controller->setLastAttackTime(timer::now() - std::chrono::milliseconds(PChar->GetWeaponDelay(false)));
        }

        return false;
    }
};

REGISTER_CPP_MODULE(Ixi20InstantReengageModule);
