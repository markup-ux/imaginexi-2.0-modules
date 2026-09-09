/************************************************************************
 * Imagine XI 2.0 ninjutsu without inventory tools (module only)
 *
 * 1.0 skipped require + consume in CMagicState::HasCost / SpendCost.
 * Both paths call battleutils::HasNinjaTool. This module patches that
 * function at init so ninjutsu never needs or spends tools.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/battle_entity.h"
#include "map/spell.h"
#include "map/utils/battleutils.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>

#include <cstring>

namespace
{

bool hookedHasNinjaTool(CBattleEntity* PEntity, CSpell* PSpell, bool consumeTool)
{
    (void)consumeTool;

    if (PEntity == nullptr || PSpell == nullptr)
    {
        return false;
    }

    return true;
}

auto installNinjaToolHook() -> bool
{
    auto* target = reinterpret_cast<uint8*>(&battleutils::HasNinjaTool);
    if (target == nullptr)
    {
        return false;
    }

    DWORD oldProtect = 0;
    if (VirtualProtect(target, 16, PAGE_EXECUTE_READWRITE, &oldProtect) == 0)
    {
        return false;
    }

    // mov rax, imm64; jmp rax
    target[0] = 0x48;
    target[1] = 0xB8;
    const auto dest = reinterpret_cast<uint64>(hookedHasNinjaTool);
    std::memcpy(target + 2, &dest, sizeof(dest));
    target[10] = 0xFF;
    target[11] = 0xE0;

    DWORD ignored = 0;
    VirtualProtect(target, 16, oldProtect, &ignored);
    FlushInstructionCache(GetCurrentProcess(), target, 16);
    return true;
}

} // namespace

class Ixi20NinjaToolsModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (installNinjaToolHook())
        {
            ShowInfo("Imagine XI 2.0: ninja tools module loaded (ninjutsu does not require or consume tools)");
        }
        else
        {
            ShowError("Imagine XI 2.0: ninja tools module failed to patch HasNinjaTool");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20NinjaToolsModule);
