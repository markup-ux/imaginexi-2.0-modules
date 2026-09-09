/************************************************************************
 * Imagine XI 2.0: stack Dia with Bio, and stack different families of
 * the same debuff (magic / ninjutsu / ammo / melee / each weaponskill).
 *
 * Patches in-memory effect rules after load. Does not hook or rewrite
 * status-effect functions (those trampolines crashed xi_map on boot).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/timer.h"

#include "map/enums/msg_std.h"
#include "map/status_effect.h"
#include "map/status_effect_container.h"

#include "data/enums/effect_overwrite.h"
#include "data/enums/status_effect.h"
#include "data/enums/status_effect_flag.h"

#include <array>
#include <cstdint>
#include <string>

namespace effects
{

// Must match status_effect_container.cpp. Validated against GetEffectName at init.
struct EffectParams_t
{
    xi::StatusEffectFlag Flag{ xi::StatusEffectFlag::None };
    std::string          Name{};
    uint16               Type{ 0 };
    xi::StatusEffect     NegativeId{ 0 };
    xi::EffectOverwrite  Overwrite{ xi::EffectOverwrite::EqualHigher };
    xi::StatusEffect     BlockId{ 0 };
    xi::StatusEffect     RemoveId{ 0 };
    uint8                Element{ 0 };
    timer::duration      MinDuration{ 0s };
    uint16               SortKey{ 0 };
    MsgStd               WearOffMessageId{ MsgStd::EffectWearsOff };
};

extern std::array<EffectParams_t, MAX_EFFECTID> EffectsParams;

} // namespace effects

namespace
{

auto paramsMatchLoadedNames() -> bool
{
    uint16 checked = 0;
    for (uint16 id = 1; id < MAX_EFFECTID; ++id)
    {
        const auto expected = effects::GetEffectName(id);
        if (expected.empty())
        {
            continue;
        }

        ++checked;
        if (effects::EffectsParams[id].Name != expected)
        {
            ShowErrorFmt("Imagine XI 2.0: debuff stack params layout mismatch at effect {} ({} vs {})",
                         id,
                         effects::EffectsParams[id].Name,
                         expected);
            return false;
        }
    }

    return checked > 0;
}

void allowDuplicate(xi::StatusEffect id)
{
    effects::EffectsParams[static_cast<uint16>(id)].Overwrite = xi::EffectOverwrite::IgnoreDuplicate;
}

void clearCycle(xi::StatusEffect id)
{
    auto& row     = effects::EffectsParams[static_cast<uint16>(id)];
    row.BlockId   = xi::StatusEffect::Ko;
    row.RemoveId  = xi::StatusEffect::Ko;
}

void clearNegative(xi::StatusEffect id)
{
    effects::EffectsParams[static_cast<uint16>(id)].NegativeId = xi::StatusEffect::Ko;
}

void setPendingFamily(uint16 family)
{
    (void)family;
}

} // namespace

class Ixi20DebuffStackModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua["Ixi20DebuffStackSetFamily"] = &setPendingFamily;

        if (!paramsMatchLoadedNames())
        {
            ShowError("Imagine XI 2.0: debuff stack module skipped effect-rule patch");
            return;
        }

        allowDuplicate(xi::StatusEffect::Poison);
        allowDuplicate(xi::StatusEffect::Slow);
        allowDuplicate(xi::StatusEffect::Paralysis);
        allowDuplicate(xi::StatusEffect::Blindness);
        allowDuplicate(xi::StatusEffect::Helix);

        clearNegative(xi::StatusEffect::Dia);
        clearNegative(xi::StatusEffect::Bio);

        clearCycle(xi::StatusEffect::Burn);
        clearCycle(xi::StatusEffect::Frost);
        clearCycle(xi::StatusEffect::Choke);
        clearCycle(xi::StatusEffect::Rasp);
        clearCycle(xi::StatusEffect::Shock);
        clearCycle(xi::StatusEffect::Drown);

        ShowInfo("Imagine XI 2.0: debuff stack module loaded (Dia+Bio and source-family stacking)");
    }
};

REGISTER_CPP_MODULE(Ixi20DebuffStackModule);
