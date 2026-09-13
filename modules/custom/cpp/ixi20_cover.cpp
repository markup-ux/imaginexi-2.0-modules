/************************************************************************
 * Imagine XI 2.0: Cover intercepts without facing / in-line / in-front
 * (module only). Core GetCoverAbilityUser still requires melee range of
 * the mob, closer than the Covered player, and areInLine.
 *
 * This keeps party / alive / Cover-buff / COVER_ABILITY_TARGET, then
 * uses the Cover JA range (16 yalms + hitboxes) as a leash to the
 * Covered player so a distant pull cannot dump onto the Paladin.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/utils.h"

#include "map/entities/battle_entity.h"
#include "map/status_effect_container.h"
#include "map/utils/battleutils.h"

#include "data/enums/status_effect.h"

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

constexpr size_t HookSize     = 12;
constexpr float  kCoverRange  = 16.0f; // abilities.range for Cover

uint8 g_original[HookSize]{};
bool  g_hookInstalled = false;

auto getCoverBytes() -> uint8*
{
    return reinterpret_cast<uint8*>(&battleutils::GetCoverAbilityUser);
}

auto writeHook(const uint8* bytes) -> bool
{
    auto* target = getCoverBytes();
    if (target == nullptr)
    {
        return false;
    }

    DWORD oldProtect = 0;
    if (VirtualProtect(target, HookSize, PAGE_EXECUTE_READWRITE, &oldProtect) == 0)
    {
        return false;
    }

    std::memcpy(target, bytes, HookSize);

    DWORD ignored = 0;
    VirtualProtect(target, HookSize, oldProtect, &ignored);
    FlushInstructionCache(GetCurrentProcess(), target, HookSize);
    return true;
}

auto hookedGetCoverAbilityUser(CBattleEntity* PCoverAbilityTarget, CBattleEntity* PMob) -> CBattleEntity*
{
    (void)PMob;

    if (PCoverAbilityTarget == nullptr || PCoverAbilityTarget->PParty == nullptr)
    {
        return nullptr;
    }

    const uint32 coverAbilityTargetID = PCoverAbilityTarget->id;
    CBattleEntity* PCoverAbilityUser  = nullptr;

    for (auto* PMember : PCoverAbilityTarget->PParty->members)
    {
        if (PMember == nullptr || PMember->StatusEffectContainer == nullptr)
        {
            continue;
        }

        if (coverAbilityTargetID == PMember->GetLocalVar("COVER_ABILITY_TARGET") &&
            PMember->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Cover) &&
            PMember->isAlive())
        {
            PCoverAbilityUser = PMember;
            break;
        }
    }

    if (PCoverAbilityUser == nullptr)
    {
        return nullptr;
    }

    if (PCoverAbilityUser->getZone() != PCoverAbilityTarget->getZone())
    {
        return nullptr;
    }

    const float maxRange = kCoverRange + PCoverAbilityUser->modelHitboxSize + PCoverAbilityTarget->modelHitboxSize;
    if (distance(PCoverAbilityUser->loc.p, PCoverAbilityTarget->loc.p) > maxRange)
    {
        return nullptr;
    }

    return PCoverAbilityUser;
}

auto installHook() -> bool
{
    auto* target = getCoverBytes();
    if (target == nullptr)
    {
        return false;
    }

    if (!g_hookInstalled)
    {
        std::memcpy(g_original, target, HookSize);
    }

    uint8 jump[HookSize]{};
    jump[0] = 0x48; // mov rax, imm64
    jump[1] = 0xB8;
    const auto addr = reinterpret_cast<uint64>(&hookedGetCoverAbilityUser);
    std::memcpy(jump + 2, &addr, sizeof(addr));
    jump[10] = 0xFF; // jmp rax
    jump[11] = 0xE0;

    if (!writeHook(jump))
    {
        return false;
    }

    g_hookInstalled = true;
    return true;
}

} // namespace

class Ixi20CoverModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (installHook())
        {
            ShowInfo("Imagine XI 2.0: Cover intercepts within 16 yalms, no facing / in-line check");
        }
        else
        {
            ShowError("Imagine XI 2.0: Cover module failed to hook GetCoverAbilityUser");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20CoverModule);
