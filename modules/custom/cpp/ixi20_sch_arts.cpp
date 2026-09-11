/************************************************************************
 * Imagine XI 2.0: Scholar Light/Dark Arts stratagems (module only)
 *
 * Stock CheckAbilityAddtype requires Light Arts for light stratagems and
 * Dark Arts for dark ones. With either Arts (or either Addendum) active,
 * both sets can be used. Rebuilds the command list the same way Tabula
 * Rasa does, so macros and the ability menu both work.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/ability.h"
#include "map/entities/char_entity.h"
#include "map/entities/pet_entity.h"
#include "map/status_effect_container.h"
#include "map/merit.h"
#include "map/utils/charutils.h"
#include "map/utils/petutils.h"

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

auto hasAnyArts(CCharEntity* PChar) -> bool
{
    if (PChar == nullptr || PChar->StatusEffectContainer == nullptr)
    {
        return false;
    }

    return PChar->StatusEffectContainer->HasStatusEffect({ xi::StatusEffect::LightArts, xi::StatusEffect::AddendumWhite,
                                                           xi::StatusEffect::DarkArts, xi::StatusEffect::AddendumBlack });
}

auto hookedCheckAbilityAddtype(CCharEntity* PChar, const CAbility* PAbility) -> bool
{
    if (PChar == nullptr || PAbility == nullptr)
    {
        return false;
    }

    if (PAbility->getAddType() & ADDTYPE_MERIT)
    {
        if (!PChar->PMeritPoints->GetMerit(static_cast<xi::Merit>(PAbility->getMeritModID())))
        {
            ShowWarning("charutils::CheckAbilityAddtype: Attempt to add invalid Merit Ability (%d).", PAbility->getMeritModID());
            return false;
        }

        if (!(PChar->PMeritPoints->GetMerit(static_cast<xi::Merit>(PAbility->getMeritModID()))->count > 0))
        {
            return false;
        }
    }

    if (PAbility->getAddType() & ADDTYPE_ASTRAL_FLOW)
    {
        if (!PChar->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::AstralFlow))
        {
            return false;
        }
    }

    if (PAbility->getAddType() & ADDTYPE_LEARNED)
    {
        if (!charutils::hasLearnedAbility(PChar, PAbility->getID()))
        {
            return false;
        }
    }

    if (PAbility->getAddType() & (ADDTYPE_LIGHT_ARTS | ADDTYPE_DARK_ARTS))
    {
        if (!hasAnyArts(PChar))
        {
            return false;
        }
    }

    if ((PAbility->getAddType() & (ADDTYPE_JUGPET | ADDTYPE_CHARMPET)) == (ADDTYPE_JUGPET | ADDTYPE_CHARMPET))
    {
        if (!PChar->PPet || !(PChar->PPet->objtype == TYPE_MOB ||
                              (PChar->PPet->objtype == TYPE_PET && static_cast<CPetEntity*>(PChar->PPet)->getPetType() == PET_TYPE::JUG_PET)))
        {
            return false;
        }
    }

    if ((PAbility->getAddType() & (ADDTYPE_JUGPET | ADDTYPE_CHARMPET)) == ADDTYPE_JUGPET)
    {
        if (!PChar->PPet || PChar->PPet->objtype != TYPE_PET || static_cast<CPetEntity*>(PChar->PPet)->getPetType() != PET_TYPE::JUG_PET)
        {
            return false;
        }
    }

    if ((PAbility->getAddType() & (ADDTYPE_JUGPET | ADDTYPE_CHARMPET)) == ADDTYPE_CHARMPET)
    {
        if (!PChar->PPet || PChar->PPet->objtype != TYPE_MOB)
        {
            return false;
        }
    }

    if (PAbility->getAddType() & ADDTYPE_AVATAR)
    {
        if (!PChar->PPet || PChar->PPet->objtype != TYPE_PET || static_cast<CPetEntity*>(PChar->PPet)->getPetType() != PET_TYPE::AVATAR)
        {
            return false;
        }

        const auto* petEntity = static_cast<CPetEntity*>(PChar->PPet);
        if (petEntity->petID() == PETID_ALEXANDER || petEntity->petID() == PETID_ODIN || petEntity->petID() == PETID_ATOMOS)
        {
            return false;
        }
    }

    if (PAbility->getAddType() & ADDTYPE_AUTOMATON)
    {
        if (!PChar->PPet || PChar->PPet->objtype != TYPE_PET || static_cast<CPetEntity*>(PChar->PPet)->getPetType() != PET_TYPE::AUTOMATON)
        {
            return false;
        }
    }

    return true;
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

class Ixi20SchArtsModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (installJump(reinterpret_cast<void*>(&charutils::CheckAbilityAddtype),
                        reinterpret_cast<const void*>(&hookedCheckAbilityAddtype)))
        {
            ShowInfo("Imagine XI 2.0: SCH arts module loaded (Light or Dark Arts unlocks both stratagems)");
        }
        else
        {
            ShowError("Imagine XI 2.0: SCH arts module failed to patch CheckAbilityAddtype");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20SchArtsModule);
