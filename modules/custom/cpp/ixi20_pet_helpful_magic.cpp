/************************************************************************
 * Imagine XI 2.0: Cure / Protect / similar on player pets (module only).
 *
 * Stock CPetEntity::ValidTarget returns false whenever TARGET_PLAYER is
 * set and allegiances match. Healing spells include TARGET_PLAYER *and*
 * TARGET_NPC, so that early-out blocks Cure on wyverns and avatars
 * ("You cannot attack that target").
 *
 * Pets are not PCs. Strip TARGET_PLAYER and use CMobEntity rules so
 * TARGET_NPC (allied pet) still works. Core src is not modified.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/battle_entity.h"
#include "map/entities/pet_entity.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>

#include <cstring>
#include <memory>

namespace
{

auto vcallDispOffset(const uint8* bytes) -> int
{
    if (bytes == nullptr)
    {
        return -1;
    }

    // mov rax, [rcx]
    if (bytes[0] != 0x48 || bytes[1] != 0x8B || bytes[2] != 0x01)
    {
        return -1;
    }

    // jmp qword ptr [rax+imm8]
    if (bytes[3] == 0xFF && bytes[4] == 0x60)
    {
        return static_cast<int>(bytes[5]);
    }

    // jmp qword ptr [rax+imm32]
    if (bytes[3] == 0xFF && bytes[4] == 0xA0)
    {
        int32 disp = 0;
        std::memcpy(&disp, bytes + 5, sizeof(disp));
        return disp;
    }

    return -1;
}

auto petValidTargetPtr() -> uint8*
{
    using MFn = bool (CPetEntity::*)(CBattleEntity*, uint16);
    const MFn mfn = &CPetEntity::ValidTarget;
    uint8*    raw = nullptr;
    static_assert(sizeof(mfn) >= sizeof(raw), "member pointer smaller than a code pointer");
    std::memcpy(&raw, &mfn, sizeof(raw));
    return raw;
}

bool hookedPetValidTarget(CPetEntity* self, CBattleEntity* PInitiator, uint16 targetFlags)
{
    if (self == nullptr || PInitiator == nullptr)
    {
        return false;
    }

    // Pets are not PCs. Stock returns false on TARGET_PLAYER, which Cure sets.
    if (PInitiator->allegiance == self->allegiance)
    {
        targetFlags = static_cast<uint16>(targetFlags & ~TARGET_PLAYER);
    }

    return self->CMobEntity::ValidTarget(PInitiator, targetFlags);
}

auto patchPetValidTarget() -> bool
{
    uint8* mfnBytes = petValidTargetPtr();
    if (mfnBytes == nullptr)
    {
        return false;
    }

    auto probe = std::unique_ptr<CPetEntity>(new CPetEntity(PET_TYPE::WYVERN, 0));
    auto* vtable = *reinterpret_cast<void***>(probe.get());
    if (vtable == nullptr)
    {
        return false;
    }

    void** slot = nullptr;
    const int disp = vcallDispOffset(mfnBytes);
    if (disp >= 0 && (disp % static_cast<int>(sizeof(void*))) == 0)
    {
        slot = &vtable[disp / static_cast<int>(sizeof(void*))];
    }
    else
    {
        for (int i = 0; i < 160; ++i)
        {
            if (vtable[i] == mfnBytes)
            {
                slot = &vtable[i];
                break;
            }
        }
    }

    if (slot == nullptr || *slot == nullptr)
    {
        return false;
    }

    DWORD oldProtect = 0;
    if (VirtualProtect(slot, sizeof(void*), PAGE_EXECUTE_READWRITE, &oldProtect) == 0)
    {
        return false;
    }

    *slot = reinterpret_cast<void*>(&hookedPetValidTarget);

    DWORD ignored = 0;
    VirtualProtect(slot, sizeof(void*), oldProtect, &ignored);
    return true;
}

} // namespace

class Ixi20PetHelpfulMagicModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (patchPetValidTarget())
        {
            ShowInfo("Imagine XI 2.0: Cure and other helpful magic can target pets");
        }
        else
        {
            ShowError("Imagine XI 2.0: pet helpful-magic patch failed");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20PetHelpfulMagicModule);
