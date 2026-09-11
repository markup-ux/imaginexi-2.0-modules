/************************************************************************
 * Imagine XI 2.0: /anon disabled (1.0 core 0x0DC behavior, module only).
 *
 * Clears the anon bit on 0x0DC (/anon) and 0x0DB (config dump) so
 * official handlers never store it. Zone-in strips a leftover DB flag.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/enums/msg_std.h"
#include "map/enums/packet_c2s.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x0db_config_language.h"
#include "map/packets/c2s/0x0dc_config.h"
#include "map/packets/s2c/0x053_systemmes.h"
#include "map/utils/charutils.h"

namespace
{

// SAVE_CONF.AnonymityFlg is bit 2 of the first byte / first uint32.
constexpr uint32 AnonBit = 1u << 2;

void clearSavedAnon(CCharEntity* PChar)
{
    if (PChar == nullptr || !PChar->playerConfig.AnonymityFlg)
    {
        return;
    }

    PChar->playerConfig.AnonymityFlg = false;
    charutils::SavePlayerSettings(PChar);
}

} // namespace

class Ixi20DisableAnonModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: /anon is disabled");
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        clearSavedAnon(PChar);
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr)
        {
            return false;
        }

        const uint16 type = packet.getType();

        if (type == static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_CONFIG))
        {
            auto* config = packet.as<GP_CLI_COMMAND_CONFIG>();
            if (config != nullptr && config->AnonymityFlg)
            {
                config->AnonymityFlg = 0;
                clearSavedAnon(PChar);
                PChar->pushPacket<GP_SERV_COMMAND_SYSTEMMES>(0, 0, MsgStd::CharacterInfoShown);
            }

            return false;
        }

        if (type == static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_CONFIG_LANGUAGE))
        {
            auto* language = packet.as<GP_CLI_COMMAND_CONFIG_LANGUAGE>();
            if (language != nullptr)
            {
                language->ConfigSys[0] &= ~AnonBit;
            }

            clearSavedAnon(PChar);
            return false;
        }

        return false;
    }
};

REGISTER_CPP_MODULE(Ixi20DisableAnonModule);
