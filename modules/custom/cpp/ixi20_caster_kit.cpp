/************************************************************************
 * Imagine XI 2.0: caster kit (module only).
 *
 * - Damaging elemental / divine / ninjutsu magic can CLOSE an existing
 *   weaponskill skillchain. It never opens a new window. Failed closes
 *   leave the WS resonance alone. Immanence and BLU Chain Affinity stay
 *   the openers. SCH helix closes still stretch the burst window.
 * - Permanent Accession does not double MP or recast.
 * - Manifestation costs 0 charges (still a timed window in Lua).
 *
 * Pair with ixi20_caster_kit.lua / .sql. Rebuild xi_map.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"
#include "common/timer.h"
#include "common/xirand.h"

#include "map/ability.h"
#include "map/action/action.h"
#include "map/ai/states/magic_state.h"
#include "map/entities/battle_entity.h"
#include "map/entities/char_entity.h"
#include "map/lua/lua_action.h"
#include "map/lua/lua_base_entity.h"
#include "map/lua/lua_spell.h"
#include "map/modifier.h"
#include "map/spell.h"
#include "map/status_effect.h"
#include "map/status_effect_container.h"
#include "map/utils/battleutils.h"
#include "map/utils/zoneutils.h"

#include "data/enums/job.h"
#include "data/enums/status_effect.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>

#include <algorithm>
#include <cstring>
#include <list>

namespace
{

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

    bytes[0]        = 0x48;
    bytes[1]        = 0xB8;
    const auto addr = reinterpret_cast<uint64>(dest);
    std::memcpy(bytes + 2, &addr, sizeof(addr));
    bytes[10] = 0xFF;
    bytes[11] = 0xE0;

    DWORD ignored = 0;
    VirtualProtect(bytes, 16, oldProtect, &ignored);
    FlushInstructionCache(GetCurrentProcess(), bytes, 16);
    return true;
}

auto entityFromLua(lua_State* L, int index) -> CCharEntity*
{
    if (!sol::stack::check<CLuaBaseEntity*>(L, index))
    {
        return nullptr;
    }

    auto* wrapper = sol::stack::get<CLuaBaseEntity*>(L, index);
    if (wrapper == nullptr)
    {
        return nullptr;
    }

    return dynamic_cast<CCharEntity*>(wrapper->GetBaseEntity());
}

auto spellFromLua(lua_State* L, int index) -> CSpell*
{
    if (!sol::stack::check<CLuaSpell*>(L, index))
    {
        return nullptr;
    }

    auto* wrapper = sol::stack::get<CLuaSpell*>(L, index);
    return wrapper != nullptr ? wrapper->GetSpell() : nullptr;
}

auto actionFromLua(lua_State* L, int index) -> action_t*
{
    if (!sol::stack::check<CLuaAction*>(L, index))
    {
        return nullptr;
    }

    auto* wrapper = sol::stack::get<CLuaAction*>(L, index);
    return wrapper != nullptr ? wrapper->GetAction() : nullptr;
}

auto isPermanentAccession(CBattleEntity* PEntity) -> bool
{
    if (PEntity == nullptr || PEntity->StatusEffectContainer == nullptr)
    {
        return false;
    }

    auto* effect = PEntity->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Accession);
    return effect != nullptr && effect->GetDuration() == 0s;
}

auto propertyForElement(uint16 element) -> SKILLCHAIN_ELEMENT
{
    switch (element)
    {
        case ELEMENT_FIRE:
            return SC_LIQUEFACTION;
        case ELEMENT_ICE:
            return SC_INDURATION;
        case ELEMENT_WIND:
            return SC_DETONATION;
        case ELEMENT_EARTH:
            return SC_SCISSION;
        case ELEMENT_THUNDER:
            return SC_IMPACTION;
        case ELEMENT_WATER:
            return SC_REVERBERATION;
        case ELEMENT_LIGHT:
            return SC_TRANSFIXION;
        case ELEMENT_DARK:
            return SC_COMPRESSION;
        default:
            return SC_NONE;
    }
}

auto isHelixFamily(SPELLFAMILY family) -> bool
{
    switch (family)
    {
        case SPELLFAMILY_GEOHELIX:
        case SPELLFAMILY_HYDROHELIX:
        case SPELLFAMILY_ANEMOHELIX:
        case SPELLFAMILY_PYROHELIX:
        case SPELLFAMILY_CRYOHELIX:
        case SPELLFAMILY_IONOHELIX:
        case SPELLFAMILY_NOCTOHELIX:
        case SPELLFAMILY_LUMINOHELIX:
            return true;
        default:
            return false;
    }
}

auto isEnfeebleDotFamily(SPELLFAMILY family) -> bool
{
    switch (family)
    {
        case SPELLFAMILY_DIA:
        case SPELLFAMILY_DIAGA:
        case SPELLFAMILY_BIO:
        case SPELLFAMILY_ELE_DOT:
        case SPELLFAMILY_ABSORB:
        case SPELLFAMILY_DRAIN:
        case SPELLFAMILY_ASPIR:
            return true;
        default:
            return false;
    }
}

auto canCloseWithSpell(CSpell* PSpell) -> bool
{
    if (PSpell == nullptr || !PSpell->dealsDamage())
    {
        return false;
    }

    if (isEnfeebleDotFamily(PSpell->getSpellFamily()))
    {
        return false;
    }

    switch (PSpell->getSkillType())
    {
        case xi::SkillType::ElementalMagic:
        case xi::SkillType::DivineMagic:
        case xi::SkillType::Ninjutsu:
            return propertyForElement(PSpell->getElement()) != SC_NONE;
        default:
            return false;
    }
}

// Close an existing WS / chainbound window. Never opens, never replaces.
auto closeExistingSkillchain(CBattleEntity* PDefender, SKILLCHAIN_ELEMENT incoming) -> ActionProcSkillChain
{
    if (PDefender == nullptr || PDefender->StatusEffectContainer == nullptr || incoming == SC_NONE)
    {
        return ActionProcSkillChain::None;
    }

    CStatusEffect*     PSCEffect  = PDefender->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Skillchain, 0);
    CStatusEffect*     PCBEffect  = PDefender->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Chainbound, 0);
    SKILLCHAIN_ELEMENT skillchain = SC_NONE;

    if (PSCEffect == nullptr && PCBEffect == nullptr)
    {
        return ActionProcSkillChain::None;
    }

    std::list<SKILLCHAIN_ELEMENT>       resonanceProperties;
    const std::list<SKILLCHAIN_ELEMENT> skillProperties = { incoming, SC_NONE, SC_NONE };

    if (PCBEffect)
    {
        if (PCBEffect->GetStartTime() + 2s >= timer::now())
        {
            return ActionProcSkillChain::None;
        }

        if (PCBEffect->GetPower() > 1)
        {
            resonanceProperties.emplace_back(SC_LIGHT);
            resonanceProperties.emplace_back(SC_DARKNESS);
            resonanceProperties.emplace_back(SC_GRAVITATION);
            resonanceProperties.emplace_back(SC_FRAGMENTATION);
            resonanceProperties.emplace_back(SC_DISTORTION);
            resonanceProperties.emplace_back(SC_FUSION);
        }

        resonanceProperties.emplace_back(SC_LIQUEFACTION);
        resonanceProperties.emplace_back(SC_INDURATION);
        resonanceProperties.emplace_back(SC_REVERBERATION);
        resonanceProperties.emplace_back(SC_IMPACTION);
        resonanceProperties.emplace_back(SC_COMPRESSION);

        skillchain = battleutils::FormSkillchain(resonanceProperties, skillProperties);
        if (skillchain == SC_NONE)
        {
            return ActionProcSkillChain::None;
        }

        PDefender->StatusEffectContainer->AddStatusEffect(xi::StatusEffect::Skillchain, 0, 0, 0s, 10s, 0, 0, 0);
        PDefender->StatusEffectContainer->DelStatusEffect(xi::StatusEffect::Chainbound);
        PSCEffect = PDefender->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Skillchain, 0);
    }
    else if (PSCEffect && PSCEffect->GetStartTime() + 3s < timer::now())
    {
        if (PSCEffect->GetTier() == 0)
        {
            if (!PSCEffect->GetPower())
            {
                return ActionProcSkillChain::None;
            }

            const auto properties = PSCEffect->GetPower();
            resonanceProperties.emplace_back(static_cast<SKILLCHAIN_ELEMENT>(properties & 0b1111));
            resonanceProperties.emplace_back(static_cast<SKILLCHAIN_ELEMENT>((properties >> 4) & 0b1111));
            resonanceProperties.emplace_back(static_cast<SKILLCHAIN_ELEMENT>((properties >> 8) & 0b1111));
            skillchain = battleutils::FormSkillchain(resonanceProperties, skillProperties);
        }
        else
        {
            resonanceProperties.emplace_back(static_cast<SKILLCHAIN_ELEMENT>(PSCEffect->GetPower()));
            skillchain = battleutils::FormSkillchain(resonanceProperties, skillProperties);
        }
    }

    if (PSCEffect == nullptr || skillchain == SC_NONE)
    {
        return ActionProcSkillChain::None;
    }

    PSCEffect->SetStartTime(timer::now());
    PSCEffect->SetDuration(PSCEffect->GetDuration() - 1s);
    PSCEffect->SetTier(battleutils::GetSkillchainTier(skillchain));
    PSCEffect->SetPower(skillchain);
    PSCEffect->SetSubPower(std::min(PSCEffect->GetSubPower() + 1, 5));

    return battleutils::GetSkillchainSubeffect(skillchain);
}

auto luaIxi20TryMagicSkillchainClose(lua_State* L) -> int
{
    auto* PChar  = entityFromLua(L, 1);
    auto* PSpell = spellFromLua(L, 2);
    auto* action = actionFromLua(L, 3);
    int   closed = 0;

    if (PChar == nullptr || PSpell == nullptr || action == nullptr || !canCloseWithSpell(PSpell))
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    const auto incoming = propertyForElement(PSpell->getElement());
    const bool helix    = isHelixFamily(PSpell->getSpellFamily());
    const bool scholar  = PChar->GetMJob() == xi::Job::SCH || PChar->GetSJob() == xi::Job::SCH;

    for (auto&& actionTarget : action->targets)
    {
        auto* PTarget = dynamic_cast<CBattleEntity*>(zoneutils::GetEntity(actionTarget.actorId));
        if (PTarget == nullptr || PTarget->health.hp <= 0)
        {
            continue;
        }

        for (auto&& result : actionTarget.results)
        {
            if (result.param <= 0 || result.hasAdditionalEffect())
            {
                continue;
            }

            const auto effect = closeExistingSkillchain(PTarget, incoming);
            if (effect == ActionProcSkillChain::None)
            {
                break;
            }

            result.recordSkillchain(effect, battleutils::TakeSkillchainDamage(PChar, PTarget, result.param, nullptr));
            ++closed;

            if (scholar && helix)
            {
                if (auto* scEffect = PTarget->StatusEffectContainer->GetStatusEffect(xi::StatusEffect::Skillchain, 0))
                {
                    scEffect->SetDuration(scEffect->GetDuration() + 2s);
                }
            }

            break;
        }
    }

    lua_pushinteger(L, closed);
    return 1;
}

uint16 hookedCalculateSpellCost(CBattleEntity* PEntity, CSpell* PSpell)
{
    if (PSpell == nullptr)
    {
        ShowWarning("battleutils::CalculateMPCost Spell is nullptr");
        return 0;
    }

    if (!PSpell->hasMPCost())
    {
        return 0;
    }

    bool   applyArts = true;
    uint16 base      = PSpell->getMPCost();
    if (PSpell->getID() == SpellID::Embrava || PSpell->getID() == SpellID::Kaustra)
    {
        base = static_cast<uint16>(PEntity->health.maxmp * 0.2);
    }

    int16 cost = base;

    if (PSpell->getSpellGroup() == SPELLGROUP_BLACK)
    {
        if (PSpell->getAOE() == SPELLAOE_RADIAL_MANI && PEntity->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Manifestation))
        {
            cost *= 2;
            applyArts = false;
        }
        if (PEntity->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Parsimony))
        {
            cost /= 2;
            applyArts = false;
        }
        else if (applyArts)
        {
            cost += static_cast<int16>(base * (PEntity->getMod(xi::Mod::BLACK_MAGIC_COST) / 100.0f));
        }
    }
    else if (PSpell->getSpellGroup() == SPELLGROUP_WHITE)
    {
        if (PSpell->getAOE() == SPELLAOE_RADIAL_ACCE &&
            PEntity->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Accession) &&
            !isPermanentAccession(PEntity))
        {
            cost *= 2;
            applyArts = false;
        }
        if (PEntity->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Penury))
        {
            cost /= 2;
            applyArts = false;
        }
        else if (applyArts)
        {
            cost += static_cast<int16>(base * (PEntity->getMod(xi::Mod::WHITE_MAGIC_COST) / 100.0f));
        }
    }

    const auto mpCostReduction = PEntity->getMod(xi::Mod::MP_COST_REDUCTION);
    if (mpCostReduction > 0)
    {
        cost = static_cast<int16>(cost * (1.f - static_cast<float>(mpCostReduction) / 100.f));
    }

    if (xirand::GetRandomNumber(100) < (PEntity->getMod(xi::Mod::NO_SPELL_MP_DEPLETION)))
    {
        cost = 0;
    }

    return std::clamp<int16>(cost, 0, 9999);
}

struct MagicStatePeek : CMagicState
{
    static auto entity(const CMagicState* state) -> CBattleEntity*
    {
        return static_cast<const MagicStatePeek*>(state)->m_PEntity;
    }
};

auto hookedGetRecast(const CMagicState* state) -> timer::duration
{
    if (state == nullptr)
    {
        return 0s;
    }

    auto* PEntity = MagicStatePeek::entity(state);
    auto* PSpell  = state->GetSpell();
    if (PEntity == nullptr || PEntity->StatusEffectContainer == nullptr)
    {
        return 0s;
    }

    if (PEntity->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Chainspell) ||
        PEntity->StatusEffectContainer->HasStatusEffect(xi::StatusEffect::Spontaneity) ||
        state->IsInstantCast())
    {
        return 0s;
    }

    auto recast = battleutils::CalculateSpellRecastTime(PEntity, PSpell);
    if (PSpell != nullptr &&
        PSpell->getAOE() == SPELLAOE_RADIAL_ACCE &&
        isPermanentAccession(PEntity))
    {
        recast = PEntity->GetMJob() == xi::Job::SCH ? recast / 2 : recast / 3;
    }

    return recast;
}

void zeroManifestationChargeCost()
{
    if (auto* ability = ability::GetAbility(ABILITY_MANIFESTATION))
    {
        ability->setRecastTime(0s);
    }
}

} // namespace

class Ixi20CasterKitModule : public CPPModule
{
public:
    void OnInit() override
    {
        lua_State* L = lua.lua_state();
        if (L != nullptr)
        {
            lua_register(L, "Ixi20TryMagicSkillchainClose", luaIxi20TryMagicSkillchainClose);
        }

        zeroManifestationChargeCost();

        bool ok = true;
        if (!installJump(reinterpret_cast<void*>(&battleutils::CalculateSpellCost),
                         reinterpret_cast<const void*>(&hookedCalculateSpellCost)))
        {
            ShowError("Imagine XI 2.0: caster kit failed to patch spell cost");
            ok = false;
        }

        using RecastFn = timer::duration (CMagicState::*)() const;
        RecastFn recastFn = &CMagicState::GetRecast;
        void*    recastPtr = nullptr;
        static_assert(sizeof(recastFn) >= sizeof(recastPtr), "member pointer smaller than a code pointer");
        std::memcpy(&recastPtr, &recastFn, sizeof(recastPtr));
        if (!installJump(recastPtr, reinterpret_cast<const void*>(&hookedGetRecast)))
        {
            ShowError("Imagine XI 2.0: caster kit failed to patch spell recast");
            ok = false;
        }

        if (ok)
        {
            ShowInfo("Imagine XI 2.0: caster kit loaded (magic closes WS windows; Accession always-on has no tax; Manifestation is free)");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20CasterKitModule);
