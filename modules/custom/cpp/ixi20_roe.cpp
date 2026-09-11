/************************************************************************
 * Imagine XI 2.0: all implemented RoE records are active (module only)
 *
 * Stock LSB tracks 30 current + 1 timed. This module treats every
 * implemented, non-hidden record as active, stores overflow progress in
 * char vars, and skips the 30-slot cap. Unity day/leader and timed-slot
 * rules still apply. Chat progress/start packets stay filtered in Lua.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/entities/mob_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/luautils.h"
#include "map/roe.h"
#include "map/utils/charutils.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>

#include <algorithm>
#include <cstring>
#include <fmt/format.h>
#include <optional>
#include <string>
#include <variant>

namespace
{

auto progressVar(uint16 recordID) -> std::string
{
    return fmt::format("ixr{}", recordID);
}

auto recordIsTrackable(CCharEntity* PChar, uint16 recordID) -> bool
{
    if (PChar == nullptr || recordID == 0 || recordID >= 4096)
    {
        return false;
    }

    if (!roeutils::RoeSystem.ImplementedRecords.test(recordID))
    {
        return false;
    }

    if (roeutils::RoeSystem.HiddenRecords.test(recordID))
    {
        return false;
    }

    if (roeutils::RoeSystem.TimedRecords.test(recordID))
    {
        return PChar->m_eminenceLog.active[30] == recordID;
    }

    if (!roeutils::IsUnitySharedRecordAvailable(recordID))
    {
        return false;
    }

    if (!roeutils::IsUnityLeaderRecordAvailable(recordID, PChar->profile.unity_leader))
    {
        return false;
    }

    if (roeutils::GetEminenceRecordCompletion(PChar, recordID) && !roeutils::RoeSystem.RepeatableRecords.test(recordID))
    {
        return false;
    }

    return true;
}

auto slotOf(const CCharEntity* PChar, uint16 recordID) -> int
{
    for (int i = 0; i < 31; ++i)
    {
        if (PChar->m_eminenceLog.active[i] == recordID)
        {
            return i;
        }
    }

    return -1;
}

auto hookedGetEminenceRecordProgress(const CCharEntity* PChar, uint16 recordID) -> uint32
{
    if (PChar == nullptr)
    {
        return 0;
    }

    const int slot = slotOf(PChar, recordID);
    if (slot >= 0)
    {
        return PChar->m_eminenceLog.progress[slot];
    }

    return static_cast<uint32>(std::max(0, charutils::GetCharVar(const_cast<CCharEntity*>(PChar), progressVar(recordID))));
}

auto hookedSetEminenceRecordProgress(CCharEntity* PChar, uint16 recordID, uint32 progress) -> bool
{
    if (PChar == nullptr)
    {
        return false;
    }

    const int slot = slotOf(PChar, recordID);
    if (slot >= 0)
    {
        if (PChar->m_eminenceLog.progress[slot] == progress)
        {
            return true;
        }

        PChar->m_eminenceLog.progress[slot] = progress;
        charutils::SaveEminenceData(PChar);
        return true;
    }

    charutils::SetCharVar(PChar, progressVar(recordID), static_cast<int32>(progress));
    return true;
}

void callOnRecordTrigger(CCharEntity* PChar, uint16 recordID, const RoeDatagramList& payload)
{
    auto onRecordTrigger = lua["xi"]["roe"]["onRecordTrigger"];
    if (!onRecordTrigger.valid())
    {
        return;
    }

    auto params        = lua.create_table();
    params["progress"] = hookedGetEminenceRecordProgress(PChar, recordID);

    for (auto& datagram : payload)
    {
        if (auto value = std::get_if<uint32>(&datagram.data))
        {
            params[datagram.luaKey] = *value;
        }
        else if (auto PMob = std::get_if<CMobEntity*>(&datagram.data))
        {
            params[datagram.luaKey] = *PMob;
        }
        else if (auto text = std::get_if<std::string>(&datagram.data))
        {
            params[datagram.luaKey] = *text;
        }
    }

    auto result = onRecordTrigger(CLuaBaseEntity(PChar), recordID, params);
    if (!result.valid())
    {
        sol::error err = result;
        ShowError("ixi20_roe onRecordTrigger: %s", err.what());
    }
}

auto hookedEvent(ROE_EVENT eventID, CCharEntity* PChar, const RoeDatagramList& payload) -> bool
{
    if (!settings::get<bool>("main.ENABLE_ROE") || PChar == nullptr || PChar->objtype != TYPE_PC)
    {
        return false;
    }

    if (eventID <= 0 || eventID >= ROE_NONE)
    {
        return false;
    }

    RoeCheckHandler& handler = RoeHandlers[eventID];

    for (uint16 recordID = 1; recordID < 4096; ++recordID)
    {
        if (handler.bitmap.test(recordID) && recordIsTrackable(PChar, recordID))
        {
            callOnRecordTrigger(PChar, recordID, payload);
        }
    }

    return true;
}

auto hookedEventOne(ROE_EVENT eventID, CCharEntity* PChar, const RoeDatagram& payload) -> bool
{
    return hookedEvent(eventID, PChar, RoeDatagramList{ payload });
}

auto installJump(void* target, const void* dest) -> bool
{
    auto* bytes = static_cast<uint8*>(target);
    if (bytes == nullptr || dest == nullptr)
    {
        return false;
    }

    DWORD oldProtect = 0;
    if (VirtualProtect(bytes, 16, PAGE_EXECUTE_READWRITE, &oldProtect) == 0)
    {
        return false;
    }

    bytes[0] = 0x48;
    bytes[1] = 0xB8;
    const auto addr = reinterpret_cast<uint64>(dest);
    std::memcpy(bytes + 2, &addr, sizeof(addr));
    bytes[10] = 0xFF;
    bytes[11] = 0xE0;

    DWORD ignored = 0;
    VirtualProtect(bytes, 16, oldProtect, &ignored);
    FlushInstructionCache(GetCurrentProcess(), bytes, 16);
    return true;
}

} // namespace

class Ixi20RoeModule : public CPPModule
{
public:
    void OnInit() override
    {
        bool ok = true;
        ok = installJump(reinterpret_cast<void*>(static_cast<uint32 (*)(const CCharEntity*, uint16)>(&roeutils::GetEminenceRecordProgress)),
                         reinterpret_cast<const void*>(&hookedGetEminenceRecordProgress)) &&
             ok;
        ok = installJump(reinterpret_cast<void*>(static_cast<bool (*)(CCharEntity*, uint16, uint32)>(&roeutils::SetEminenceRecordProgress)),
                         reinterpret_cast<const void*>(&hookedSetEminenceRecordProgress)) &&
             ok;
        ok = installJump(reinterpret_cast<void*>(static_cast<bool (*)(ROE_EVENT, CCharEntity*, const RoeDatagramList&)>(&roeutils::event)),
                         reinterpret_cast<const void*>(&hookedEvent)) &&
             ok;
        ok = installJump(reinterpret_cast<void*>(static_cast<bool (*)(ROE_EVENT, CCharEntity*, const RoeDatagram&)>(&roeutils::event)),
                         reinterpret_cast<const void*>(&hookedEventOne)) &&
             ok;

        if (lua["CBaseEntity"].valid())
        {
            lua["CBaseEntity"]["setEminenceProgress"] = [](CLuaBaseEntity entity, uint16 recordID, uint32 progress, sol::object) {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                return hookedSetEminenceRecordProgress(PChar, recordID, progress);
            };

            lua["CBaseEntity"]["getEminenceProgress"] = [](CLuaBaseEntity entity, uint16 recordID) -> sol::optional<uint32> {
                auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
                if (PChar == nullptr || !recordIsTrackable(PChar, recordID))
                {
                    return sol::nullopt;
                }

                return hookedGetEminenceRecordProgress(PChar, recordID);
            };
        }

        if (ok)
        {
            ShowInfo("Imagine XI 2.0: RoE module loaded (all implemented records, no 30-slot cap)");
        }
        else
        {
            ShowError("Imagine XI 2.0: RoE module failed to patch one or more roeutils functions");
        }
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        if (PChar == nullptr || !settings::get<bool>("main.ENABLE_ROE"))
        {
            return;
        }

        for (uint16 recordID = 1; recordID < 4096; ++recordID)
        {
            if (recordIsTrackable(PChar, recordID))
            {
                PChar->m_eminenceCache.activemap.set(recordID);
            }
        }
    }
};

REGISTER_CPP_MODULE(Ixi20RoeModule);
