/************************************************************************
 * Imagine XI 2.0: pixie rescue raise-accept hook (module only).
 *
 * Stock LSB has no onPlayerRaiseAccept. 1.0 calls Lua on the same tick as
 * Raise() so sneak/invis/full HP land before roam/aggro. This intercepts
 * the raise-menu packet when a rescue ticket is pending, then:
 *   - Raise()
 *   - snap HP/MP to current max (weakness stays)
 *   - xi.pixieRescue.onPlayerRaiseAccept
 *
 * Homepoint / zone-out despawn an abandoned spirit.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/enums/packet_c2s.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x01a_action.h"

namespace
{

constexpr const char* TicketVar   = "PIXIE_RESCUE_TICKET";
constexpr const char* PostDoneVar = "PIXIE_RESCUE_POST_DONE";

auto hasPendingRescue(CCharEntity* PChar) -> bool
{
    return PChar != nullptr && PChar->GetLocalVar(TicketVar) != 0U && PChar->GetLocalVar(PostDoneVar) == 0U;
}

void snapRescueResources(CCharEntity* PChar)
{
    const int32 maxHp = PChar->GetMaxHP();
    if (maxHp > PChar->health.hp)
    {
        PChar->addHP(maxHp - PChar->health.hp);
    }

    const int32 maxMp = PChar->GetMaxMP();
    if (maxMp > PChar->health.mp)
    {
        PChar->addMP(maxMp - PChar->health.mp);
    }

    PChar->m_unkillable = true;
    PChar->updatemask |= UPDATE_HP;
}

void callRescueLua(sol::state& lua, CCharEntity* PChar, const char* funcName)
{
    sol::protected_function fn = lua["xi"]["pixieRescue"][funcName];
    if (!fn.valid())
    {
        ShowWarning("Imagine XI 2.0: xi.pixieRescue.%s missing", funcName);
        return;
    }

    auto result = fn(CLuaBaseEntity(PChar));
    if (!result.valid())
    {
        ShowError("Imagine XI 2.0: xi.pixieRescue.%s failed", funcName);
    }
}

} // namespace

class Ixi20PixieRescueModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: pixie rescue raise-accept hook loaded");
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        if (hasPendingRescue(PChar))
        {
            callRescueLua(lua, PChar, "cleanupAbandonedRescue");
        }
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_ACTION))
        {
            return false;
        }

        const auto* action = packet.as<GP_CLI_COMMAND_ACTION>();
        if (action == nullptr)
        {
            return false;
        }

        if (action->ActionID == GP_CLI_COMMAND_ACTION_ACTIONID::HomepointMenu && hasPendingRescue(PChar))
        {
            callRescueLua(lua, PChar, "cleanupAbandonedRescue");
            return false;
        }

        if (action->ActionID != GP_CLI_COMMAND_ACTION_ACTIONID::RaiseMenu)
        {
            return false;
        }

        if (!hasPendingRescue(PChar) || !PChar->m_hasRaise)
        {
            return false;
        }

        if (action->HomepointMenu.StatusId != GP_CLI_COMMAND_ACTION_HOMEPOINTMENU::Accept)
        {
            return false;
        }

        PChar->Raise();
        snapRescueResources(PChar);
        callRescueLua(lua, PChar, "onPlayerRaiseAccept");
        return true;
    }
};

REGISTER_CPP_MODULE(Ixi20PixieRescueModule);
