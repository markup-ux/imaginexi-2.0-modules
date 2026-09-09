/************************************************************************
 * Imagine XI 2.0 always-succeed synthesis / desynthesis (module only)
 *
 * Valid recipes never break. The 15-level skill cancel is ignored.
 * Skill-ups still roll. HQ still uses the player's real craft level.
 * Items with no desynth recipe still cannot be desynthed.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/settings.h"
#include "common/xirand.h"

#include "map/entities/char_entity.h"
#include "map/enums/synthesis_effect.h"
#include "map/items.h"
#include "map/items/craft_state.h"
#include "map/items/transactions/synth.h"
#include "map/packets/s2c/0x030_effect.h"
#include "map/utils/synthutils.h"
#include "map/zone.h"

#include "data/enums/mod.h"
#include "data/enums/skill_type.h"

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
#include <memory>

namespace
{

constexpr size_t HookSize      = 12;
// Official difficulty uses uint8(skill / 10). 3000 tenths becomes 44 and high recipes
// still "break" for the start animation. 2550 tenths = displayed 255, passes every gate.
constexpr uint16 PassSkillGate = 2550;

constexpr uint8 RESULT_SUCCESS = 0x00;
constexpr uint8 RESULT_HQ      = 0x02;

uint8  g_originalStartSynth[HookSize]{};
bool   g_hookInstalled = false;

auto skillIndex(uint8 skillID) -> uint8
{
    return static_cast<uint8>(skillID - static_cast<uint8>(xi::SkillType::Woodworking));
}

auto getSynthDifficulty(CCharEntity* PChar, uint8 skillID) -> int16
{
    xi::Mod modId = xi::Mod::NONE;

    switch (static_cast<xi::SkillType>(skillID))
    {
        case xi::SkillType::Woodworking:
            modId = xi::Mod::WOOD;
            break;
        case xi::SkillType::Smithing:
            modId = xi::Mod::SMITH;
            break;
        case xi::SkillType::Goldsmithing:
            modId = xi::Mod::GOLDSMITH;
            break;
        case xi::SkillType::Clothcraft:
            modId = xi::Mod::CLOTH;
            break;
        case xi::SkillType::Leathercraft:
            modId = xi::Mod::LEATHER;
            break;
        case xi::SkillType::Bonecraft:
            modId = xi::Mod::BONE;
            break;
        case xi::SkillType::Alchemy:
            modId = xi::Mod::ALCHEMY;
            break;
        case xi::SkillType::Cooking:
            modId = xi::Mod::COOK;
            break;
        default:
            break;
    }

    const uint8 charSkill  = static_cast<uint8>(PChar->RealSkills.skill[skillID] / 10);
    const int16 difficulty = static_cast<int16>(PChar->craftState().skillRequired(skillIndex(skillID)) - charSkill - PChar->getMod(modId));
    return difficulty;
}

auto canSynthesizeHQ(CCharEntity* PChar, uint8 skillID) -> bool
{
    xi::Mod modId = xi::Mod::NONE;

    switch (static_cast<xi::SkillType>(skillID))
    {
        case xi::SkillType::Woodworking:
            modId = xi::Mod::SYNTH_ANTI_HQ_WOODWORKING;
            break;
        case xi::SkillType::Smithing:
            modId = xi::Mod::SYNTH_ANTI_HQ_SMITHING;
            break;
        case xi::SkillType::Goldsmithing:
            modId = xi::Mod::SYNTH_ANTI_HQ_GOLDSMITHING;
            break;
        case xi::SkillType::Clothcraft:
            modId = xi::Mod::SYNTH_ANTI_HQ_CLOTHCRAFT;
            break;
        case xi::SkillType::Leathercraft:
            modId = xi::Mod::SYNTH_ANTI_HQ_LEATHERCRAFT;
            break;
        case xi::SkillType::Bonecraft:
            modId = xi::Mod::SYNTH_ANTI_HQ_BONECRAFT;
            break;
        case xi::SkillType::Alchemy:
            modId = xi::Mod::SYNTH_ANTI_HQ_ALCHEMY;
            break;
        case xi::SkillType::Cooking:
            modId = xi::Mod::SYNTH_ANTI_HQ_COOKING;
            break;
        default:
            break;
    }

    return PChar->getMod(modId) == 0;
}

auto rollHQUpgrade(uint8 finalHQTier) -> uint8
{
    if (finalHQTier <= 1)
    {
        return synthutils::SYNTHESIS_HQ;
    }

    uint8 allowedUpgrades = (finalHQTier == 2 ? 1 : 2);
    uint8 upgradeHQ       = 0;
    for (uint8 tries = 0; tries < allowedUpgrades; ++tries)
    {
        if (xirand::GetRandomNumber(0.0, 100.0) <= 25.0)
        {
            upgradeHQ = upgradeHQ + 1;
        }
        else
        {
            break;
        }
    }

    return static_cast<uint8>(synthutils::SYNTHESIS_HQ + upgradeHQ);
}

// Official calculateSynthResult without the break roll.
auto calculateAlwaysSucceedSynth(CCharEntity* PChar) -> uint8
{
    uint8 finalHQTier = 4;
    bool  canHQ       = true;

    for (uint8 skillID = static_cast<uint8>(xi::SkillType::Woodworking); skillID <= static_cast<uint8>(xi::SkillType::Cooking); ++skillID)
    {
        if (PChar->craftState().skillRequired(skillIndex(skillID)) == 0)
        {
            continue;
        }

        const int16 synthDifficulty = getSynthDifficulty(PChar, skillID);
        uint8       currentHQTier   = 0;

        if (synthDifficulty >= 1)
        {
            canHQ = false;
        }
        else if (synthDifficulty >= -10)
        {
            currentHQTier = 1;
        }
        else if (synthDifficulty >= -30)
        {
            currentHQTier = 2;
        }
        else if (synthDifficulty >= -50)
        {
            currentHQTier = 3;
        }
        else
        {
            currentHQTier = 4;
        }

        if (currentHQTier < finalHQTier)
        {
            finalHQTier = currentHQTier;
        }

        if (!canSynthesizeHQ(PChar, skillID))
        {
            canHQ = false;
        }
    }

    if (!canHQ)
    {
        return synthutils::SYNTHESIS_SUCCESS;
    }

    double chanceHQ = 0.0;
    switch (finalHQTier)
    {
        case 4:
            chanceHQ = 50.0;
            break;
        case 3:
            chanceHQ = 25.0;
            break;
        case 2:
            chanceHQ = 6.25;
            break;
        case 1:
            chanceHQ = 1.5625;
            break;
        default:
            chanceHQ = 0.0;
            break;
    }

    chanceHQ = (chanceHQ + 100.0 * static_cast<double>(PChar->getMod(xi::Mod::SYNTH_HQ_RATE)) / 512.0) * settings::get<double>("map.CRAFT_HQ_CHANCE_MULTIPLIER");
    chanceHQ = std::min(chanceHQ, 80.0);

    if (xirand::GetRandomNumber(0.0, 100.0) > chanceHQ)
    {
        return synthutils::SYNTHESIS_SUCCESS;
    }

    return rollHQUpgrade(finalHQTier);
}

// Official calculateDesynthResult without the break roll.
auto calculateAlwaysSucceedDesynth(CCharEntity* PChar) -> uint8
{
    bool canHQ = true;

    for (uint8 skillID = static_cast<uint8>(xi::SkillType::Woodworking); skillID <= static_cast<uint8>(xi::SkillType::Cooking); ++skillID)
    {
        if (PChar->craftState().skillRequired(skillIndex(skillID)) == 0)
        {
            continue;
        }

        if (!canSynthesizeHQ(PChar, skillID))
        {
            canHQ = false;
        }
    }

    if (!canHQ)
    {
        return synthutils::SYNTHESIS_SUCCESS;
    }

    double chanceHQ = (60.0 + 100.0 * static_cast<double>(PChar->getMod(xi::Mod::SYNTH_HQ_RATE)) / 512.0) * settings::get<double>("map.CRAFT_HQ_CHANCE_MULTIPLIER");
    chanceHQ        = std::min(chanceHQ, 80.0);

    if (xirand::GetRandomNumber(0.0, 100.0) > chanceHQ)
    {
        return synthutils::SYNTHESIS_SUCCESS;
    }

    uint8 upgradeHQ = 0;
    if (xirand::GetRandomNumber(0.0, 100.0) < 50.0)
    {
        upgradeHQ = 1;
        if (xirand::GetRandomNumber(0.0, 100.0) < (100.0 / 3.0))
        {
            upgradeHQ = 2;
        }
    }

    return static_cast<uint8>(synthutils::SYNTHESIS_HQ + upgradeHQ);
}

auto crystalEffect(uint16 itemId) -> SynthesisEffect
{
    switch (itemId)
    {
        case FIRE_CRYSTAL:
        case INFERNO_CRYSTAL:
        case PYRE_CRYSTAL:
            return SynthesisEffect::Fire;
        case ICE_CRYSTAL:
        case GLACIER_CRYSTAL:
        case FROST_CRYSTAL:
            return SynthesisEffect::Ice;
        case WIND_CRYSTAL:
        case CYCLONE_CRYSTAL:
        case VORTEX_CRYSTAL:
            return SynthesisEffect::Wind;
        case EARTH_CRYSTAL:
        case TERRA_CRYSTAL:
        case GEO_CRYSTAL:
            return SynthesisEffect::Earth;
        case LIGHTNING_CRYSTAL:
        case PLASMA_CRYSTAL:
        case BOLT_CRYSTAL:
            return SynthesisEffect::Lightning;
        case WATER_CRYSTAL:
        case TORRENT_CRYSTAL:
        case FLUID_CRYSTAL:
            return SynthesisEffect::Water;
        case LIGHT_CRYSTAL:
        case AURORA_CRYSTAL:
        case GLIMMER_CRYSTAL:
            return SynthesisEffect::Light;
        case DARK_CRYSTAL:
        case TWILIGHT_CRYSTAL:
        case SHADOW_CRYSTAL:
            return SynthesisEffect::Dark;
        default:
            return SynthesisEffect::None;
    }
}

auto effectParam(uint8 synthResult) -> uint8
{
    switch (synthResult)
    {
        case synthutils::SYNTHESIS_HQ:
        case synthutils::SYNTHESIS_HQ2:
        case synthutils::SYNTHESIS_HQ3:
            return RESULT_HQ;
        default:
            return RESULT_SUCCESS;
    }
}

void applyAlwaysSucceedResult(CCharEntity* PChar, uint16 crystalItemId)
{
    if (PChar == nullptr || PChar->activeTransaction<SynthTransaction>() == nullptr)
    {
        return;
    }

    const uint8 result = PChar->craftState().craftMode() == CRAFT_DESYNTHESIS
                             ? calculateAlwaysSucceedDesynth(PChar)
                             : calculateAlwaysSucceedSynth(PChar);

    PChar->craftState().setResult(result);

    if (PChar->loc.zone != nullptr)
    {
        PChar->loc.zone->PushPacket(
            PChar,
            CHAR_INRANGE_SELF,
            std::make_unique<GP_SERV_COMMAND_EFFECT>(PChar, crystalEffect(crystalItemId), effectParam(result)));
    }
}

struct SkillGatePass
{
    CCharEntity*           PChar{};
    std::array<uint16, 8> saved{};

    explicit SkillGatePass(CCharEntity* player)
    : PChar(player)
    {
        for (uint8 i = 0; i < 8; ++i)
        {
            const uint8 skillID = static_cast<uint8>(xi::SkillType::Woodworking) + i;
            saved[i]            = PChar->RealSkills.skill[skillID];
            PChar->RealSkills.skill[skillID] = PassSkillGate;
        }
    }

    ~SkillGatePass()
    {
        if (PChar == nullptr)
        {
            return;
        }

        for (uint8 i = 0; i < 8; ++i)
        {
            const uint8 skillID              = static_cast<uint8>(xi::SkillType::Woodworking) + i;
            PChar->RealSkills.skill[skillID] = saved[i];
        }
    }

    SkillGatePass(const SkillGatePass&)            = delete;
    SkillGatePass& operator=(const SkillGatePass&) = delete;
};

auto startSynthBytes() -> uint8*
{
    return reinterpret_cast<uint8*>(&synthutils::startSynth);
}

auto writeHook(const uint8* bytes) -> bool
{
    auto* target = startSynthBytes();
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

auto installStartSynthHook() -> bool;
auto removeStartSynthHook() -> bool;

void hookedStartSynth(CCharEntity* PChar, const SynthOffer& offer)
{
    if (PChar == nullptr)
    {
        return;
    }

    {
        SkillGatePass pass(PChar);
        if (!removeStartSynthHook())
        {
            return;
        }

        synthutils::startSynth(PChar, offer);
        installStartSynthHook();
    }

    applyAlwaysSucceedResult(PChar, offer.crystal.itemId);
}

auto installStartSynthHook() -> bool
{
    auto* target = startSynthBytes();
    if (target == nullptr)
    {
        return false;
    }

    if (!g_hookInstalled)
    {
        std::memcpy(g_originalStartSynth, target, HookSize);
    }

    uint8 jump[HookSize]{};
    jump[0] = 0x48; // mov rax, imm64
    jump[1] = 0xB8;
    const auto dest = reinterpret_cast<uint64>(hookedStartSynth);
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

auto removeStartSynthHook() -> bool
{
    if (!g_hookInstalled)
    {
        return true;
    }

    if (!writeHook(g_originalStartSynth))
    {
        return false;
    }

    g_hookInstalled = false;
    return true;
}

} // namespace

class Ixi20CraftAlwaysSucceedModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (installStartSynthHook())
        {
            ShowInfo("Imagine XI 2.0: craft module loaded (synth/desynth never fail; HQ and skill-ups unchanged)");
        }
        else
        {
            ShowError("Imagine XI 2.0: craft module failed to patch startSynth");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20CraftAlwaysSucceedModule);
