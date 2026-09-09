/************************************************************************
 * Imagine XI 2.0: Call Wyvern on subjob DRG (module only).
 *
 * Stock LSB:
 *   - Call Wyvern / Dismiss / Spirit Link are ADDTYPE_MAIN_ONLY
 *   - petutils::LoadPet returns unless the master's main job is DRG
 *
 * This keeps core src untouched: MAIN_ONLY is cleared in memory after
 * abilities load, and LoadPet is hooked so /DRG can spawn the wyvern.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/ability.h"
#include "map/entities/battle_entity.h"
#include "map/utils/petutils.h"

#include "data/enums/job.h"

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

constexpr size_t HookSize = 12;

uint8 g_originalLoadPet[HookSize]{};
bool  g_hookInstalled = false;

auto loadPetBytes() -> uint8*
{
    return reinterpret_cast<uint8*>(&petutils::LoadPet);
}

auto writeHook(const uint8* bytes) -> bool
{
    auto* target = loadPetBytes();
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

auto installLoadPetHook() -> bool;
auto removeLoadPetHook() -> bool;

struct MainJobSpoof
{
    CBattleEntity* master;
    xi::Job        saved;

    explicit MainJobSpoof(CBattleEntity* PMaster)
    : master(PMaster)
    , saved(PMaster != nullptr ? PMaster->GetMJob() : xi::Job::NONE)
    {
        if (PMaster != nullptr)
        {
            PMaster->SetMJob(static_cast<uint8>(xi::Job::DRG));
        }
    }

    ~MainJobSpoof()
    {
        if (master != nullptr)
        {
            master->SetMJob(static_cast<uint8>(saved));
        }
    }

    MainJobSpoof(const MainJobSpoof&)            = delete;
    MainJobSpoof& operator=(const MainJobSpoof&) = delete;
};

void hookedLoadPet(CBattleEntity* PMaster, uint32 PetID, bool spawningFromZone)
{
    const bool subDrgWyvern = PMaster != nullptr &&
                              PetID == PETID_WYVERN &&
                              PMaster->GetMJob() != xi::Job::DRG &&
                              PMaster->GetSJob() == xi::Job::DRG;

    [[maybe_unused]] MainJobSpoof spoof{ subDrgWyvern ? PMaster : nullptr };

    if (!removeLoadPetHook())
    {
        return;
    }

    petutils::LoadPet(PMaster, PetID, spawningFromZone);
    installLoadPetHook();
}

auto installLoadPetHook() -> bool
{
    auto* target = loadPetBytes();
    if (target == nullptr)
    {
        return false;
    }

    if (!g_hookInstalled)
    {
        std::memcpy(g_originalLoadPet, target, HookSize);
    }

    uint8 jump[HookSize]{};
    jump[0] = 0x48; // mov rax, imm64
    jump[1] = 0xB8;
    const auto dest = reinterpret_cast<uint64>(hookedLoadPet);
    std::memcpy(jump + 2, &dest, sizeof(dest));
    jump[10] = 0xFF; // jmp rax
    jump[11] = 0xE0;

    if (!writeHook(jump))
    {
        return false;
    }

    g_hookInstalled = true;
    return true;
}

auto removeLoadPetHook() -> bool
{
    if (!g_hookInstalled)
    {
        return true;
    }

    if (!writeHook(g_originalLoadPet))
    {
        return false;
    }

    g_hookInstalled = false;
    return true;
}

void allowWyvernAbilitiesOnSubjob()
{
    constexpr uint16 abilityIds[] = {
        ABILITY_CALL_WYVERN,
        ABILITY_DISMISS,
        ABILITY_SPIRIT_LINK,
    };

    for (uint16 abilityId : abilityIds)
    {
        CAbility* PAbility = ability::GetAbility(abilityId);
        if (PAbility == nullptr)
        {
            ShowError("Imagine XI 2.0: subjob wyvern could not find ability %u", abilityId);
            continue;
        }

        const uint16 addType = PAbility->getAddType();
        if (addType & ADDTYPE_MAIN_ONLY)
        {
            PAbility->setAddType(static_cast<uint16>(addType & ~ADDTYPE_MAIN_ONLY));
        }
    }
}

} // namespace

class Ixi20SubjobWyvernModule : public CPPModule
{
public:
    void OnInit() override
    {
        allowWyvernAbilitiesOnSubjob();

        if (installLoadPetHook())
        {
            ShowInfo("Imagine XI 2.0: subjob DRG can Call Wyvern");
        }
        else
        {
            ShowError("Imagine XI 2.0: subjob wyvern module failed to patch LoadPet");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20SubjobWyvernModule);
