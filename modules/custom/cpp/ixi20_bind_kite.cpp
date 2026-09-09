/************************************************************************
 * Imagine XI 2.0: Bind holds through a few hits so it is useful for
 * kiting (module only). Core BindBreakCheck is 95% per instance.
 *
 * BindBreakCheck is in battleutils.cpp and may be inlined there, so this
 * hooks both the break check and DelStatusEffect(Bind). Lua
 * delStatusEffect (Erase items, scripts) still removes Bind immediately.
 *
 * Hit 1: 20%  Hit 2: 40%  Hit 3: 65%  Hit 4+: 90%
 * Count is stored on the effect subPower (power is the saved walk speed).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/xirand.h"

#include "map/entities/battle_entity.h"
#include "map/lua/lua_base_entity.h"
#include "map/status_effect.h"
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

#include <algorithm>
#include <array>
#include <cstring>
#include <limits>

namespace
{

constexpr size_t HookSize = 12;

// 0-1000 scale, same as stock BindBreakCheck.
constexpr std::array<uint16, 4> kBreakChanceByHit = { 200, 400, 650, 900 };

thread_local int g_bindForceDelete = 0;

struct ForceBindDelete
{
    ForceBindDelete()
    {
        ++g_bindForceDelete;
    }

    ~ForceBindDelete()
    {
        --g_bindForceDelete;
    }

    ForceBindDelete(const ForceBindDelete&)            = delete;
    ForceBindDelete& operator=(const ForceBindDelete&) = delete;
};

struct Trampoline
{
    uint8* target = nullptr;
    uint8  original[HookSize]{};
    bool   installed = false;

    auto write(const uint8* bytes) -> bool
    {
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

    auto install(void* dest) -> bool
    {
        if (target == nullptr || dest == nullptr)
        {
            return false;
        }

        if (!installed)
        {
            std::memcpy(original, target, HookSize);
        }

        uint8 jump[HookSize]{};
        jump[0] = 0x48; // mov rax, imm64
        jump[1] = 0xB8;
        const auto addr = reinterpret_cast<uint64>(dest);
        std::memcpy(jump + 2, &addr, sizeof(addr));
        jump[10] = 0xFF; // jmp rax
        jump[11] = 0xE0;

        if (!write(jump))
        {
            return false;
        }

        installed = true;
        return true;
    }

    auto remove() -> bool
    {
        if (!installed)
        {
            return true;
        }

        if (!write(original))
        {
            return false;
        }

        installed = false;
        return true;
    }
};

Trampoline g_bindBreakHook;
Trampoline g_delStatusHook;
Trampoline g_luaDelHook;

template <typename MFn>
auto memberFnBytes(MFn mfn) -> uint8*
{
    uint8* raw = nullptr;
    static_assert(sizeof(mfn) >= sizeof(raw), "member pointer smaller than a code pointer");
    std::memcpy(&raw, &mfn, sizeof(raw));
    return raw;
}

auto reinstallDelStatusHook() -> bool;
auto reinstallLuaDelHook() -> bool;

auto applyBindBreakRamp(CStatusEffectContainer* self) -> bool
{
    if (self == nullptr)
    {
        return false;
    }

    CStatusEffect* PEffect = self->GetStatusEffect(xi::StatusEffect::Bind);
    if (PEffect == nullptr)
    {
        return false;
    }

    uint16 hits = PEffect->GetSubPower();
    if (hits < std::numeric_limits<uint16>::max())
    {
        ++hits;
        PEffect->SetSubPower(hits);
    }

    const size_t index  = static_cast<size_t>(std::min<uint16>(hits, static_cast<uint16>(kBreakChanceByHit.size()))) - 1;
    const uint16 chance = kBreakChanceByHit[index];

    if (chance > xirand::GetRandomNumber(1000))
    {
        ForceBindDelete force;
        if (!g_delStatusHook.remove())
        {
            return false;
        }

        using DelFn = bool (CStatusEffectContainer::*)(xi::StatusEffect);
        const DelFn delFn   = static_cast<DelFn>(&CStatusEffectContainer::DelStatusEffect);
        const bool  removed = (self->*delFn)(xi::StatusEffect::Bind);
        reinstallDelStatusHook();
        return removed;
    }

    return false;
}

void hookedBindBreakCheck([[maybe_unused]] CBattleEntity* PAttacker, CBattleEntity* PDefender)
{
    if (PDefender == nullptr || PDefender->StatusEffectContainer == nullptr)
    {
        return;
    }

    if (!PDefender->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Bind))
    {
        return;
    }

    // Always ask to remove; the DelStatusEffect hook applies the ramp.
    PDefender->StatusEffectContainer->DelStatusEffect(xi::StatusEffect::Bind);
}

auto hookedDelStatusEffect(CStatusEffectContainer* self, xi::StatusEffect statusId) -> bool
{
    if (statusId == xi::StatusEffect::Bind && g_bindForceDelete == 0)
    {
        return applyBindBreakRamp(self);
    }

    if (!g_delStatusHook.remove())
    {
        return false;
    }

    using DelFn = bool (CStatusEffectContainer::*)(xi::StatusEffect);
    const DelFn delFn   = static_cast<DelFn>(&CStatusEffectContainer::DelStatusEffect);
    const bool  removed = self != nullptr && (self->*delFn)(statusId);
    reinstallDelStatusHook();
    return removed;
}

auto hookedLuaDelStatusEffect(CLuaBaseEntity* self,
                              xi::StatusEffect statusId,
                              const sol::object& subType,
                              const sol::object& sourceType,
                              const sol::object& sourceTypeParam) -> bool
{
    ForceBindDelete force;

    if (!g_luaDelHook.remove())
    {
        return false;
    }

    const bool removed = self != nullptr && self->delStatusEffect(statusId, subType, sourceType, sourceTypeParam);
    reinstallLuaDelHook();
    return removed;
}

auto installJump(Trampoline& hook, uint8* target, void* dest) -> bool
{
    hook.target = target;
    return hook.install(dest);
}

auto reinstallDelStatusHook() -> bool
{
    return g_delStatusHook.install(reinterpret_cast<void*>(&hookedDelStatusEffect));
}

auto reinstallLuaDelHook() -> bool
{
    return g_luaDelHook.install(reinterpret_cast<void*>(&hookedLuaDelStatusEffect));
}

auto installHooks() -> bool
{
    auto* bindBreakBytes = reinterpret_cast<uint8*>(&battleutils::BindBreakCheck);
    using DelFn          = bool (CStatusEffectContainer::*)(xi::StatusEffect);
    auto* delBytes       = memberFnBytes(static_cast<DelFn>(&CStatusEffectContainer::DelStatusEffect));
    auto* luaDelBytes    = memberFnBytes(&CLuaBaseEntity::delStatusEffect);

    const bool bindOk = installJump(g_bindBreakHook, bindBreakBytes, reinterpret_cast<void*>(&hookedBindBreakCheck));
    const bool delOk  = installJump(g_delStatusHook, delBytes, reinterpret_cast<void*>(&hookedDelStatusEffect));
    const bool luaOk  = installJump(g_luaDelHook, luaDelBytes, reinterpret_cast<void*>(&hookedLuaDelStatusEffect));

    if (!delOk)
    {
        ShowError("Imagine XI 2.0: bind kite failed to hook DelStatusEffect");
        return false;
    }

    if (!luaOk)
    {
        ShowError("Imagine XI 2.0: bind kite failed to hook delStatusEffect");
        return false;
    }

    if (!bindOk)
    {
        ShowWarning("Imagine XI 2.0: bind kite could not hook BindBreakCheck (inlined?); DelStatusEffect ramp still active");
    }

    return true;
}

} // namespace

class Ixi20BindKiteModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (installHooks())
        {
            ShowInfo("Imagine XI 2.0: Bind breaks on a ramp (20/40/65/90) for kiting");
        }
        else
        {
            ShowError("Imagine XI 2.0: bind kite module failed to install");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20BindKiteModule);
