/************************************************************************
 * Imagine XI 2.0: keep gear on while Level Sync / restriction is below
 * the item's req level, and scale every stat to the effective level.
 *
 * Stock LSB already leaves the set equipped when map.DISABLE_GEAR_SCALING
 * is false, but retail under-level math zeroes haste / fast cast / most
 * mods and harshly nerfs DEF/ATT. This module overlays the difference
 * after stock applies: wanted = full * mLevel / itemReqLevel (nearest).
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/lua.h"
#include "common/settings.h"

#include "map/entities/char_entity.h"
#include "map/enums/packet_s2c.h"
#include "map/items/item_weapon.h"
#include "map/latent_effect_container.h"
#include "map/lua/lua_base_entity.h"
#include "map/packets/basic.h"
#include "map/packets/s2c/0x061_clistatus.h"
#include "map/utils/charutils.h"
#include "map/zone.h"

#include "data/enums/latent.h"
#include "data/enums/status.h"

#include <algorithm>
#include <array>
#include <unordered_map>
#include <unordered_set>

namespace
{

constexpr uint8 EquipSlotCount = 16;

struct OverlayState
{
    uint32                             fingerprint = 0;
    std::unordered_map<int32, int16>   mods;
    std::array<bool, EquipSlotCount>   latentSlots{};
};

std::unordered_map<uint32, OverlayState> g_overlays;
std::unordered_set<uint32>               g_refreshing;

auto wantedScale(int32 amount, uint8 mLevel, uint8 itemLevel) -> int16
{
    if (itemLevel == 0 || mLevel >= itemLevel)
    {
        return static_cast<int16>(amount);
    }

    if (amount >= 0)
    {
        return static_cast<int16>((amount * static_cast<int32>(mLevel) + itemLevel / 2) / itemLevel);
    }

    return static_cast<int16>((amount * static_cast<int32>(mLevel) - itemLevel / 2) / itemLevel);
}

auto stockScale(int16 amount, uint8 mLevel, uint8 itemLevel, xi::Mod mod) -> int16
{
    if (itemLevel == 0 || mLevel >= itemLevel)
    {
        return amount;
    }

    int16 modAmount = mLevel * amount;
    switch (mod)
    {
        case xi::Mod::DEF:
        case xi::Mod::MAIN_DMG_RATING:
        case xi::Mod::SUB_DMG_RATING:
        case xi::Mod::RANGED_DMG_RATING:
            modAmount *= 3;
            modAmount /= 4;
            break;
        case xi::Mod::HP:
        case xi::Mod::MP:
            modAmount /= 2;
            break;
        case xi::Mod::STR:
        case xi::Mod::DEX:
        case xi::Mod::VIT:
        case xi::Mod::AGI:
        case xi::Mod::INT:
        case xi::Mod::MND:
        case xi::Mod::CHR:
        case xi::Mod::ATT:
        case xi::Mod::RATT:
        case xi::Mod::ACC:
        case xi::Mod::RACC:
        case xi::Mod::MATT:
        case xi::Mod::MACC:
            modAmount /= 3;
            break;
        default:
            modAmount = 0;
            break;
    }

    return static_cast<int16>(modAmount / itemLevel);
}

auto stockWeaponDmg(uint16 base, uint8 mLevel, uint8 reqLvl) -> uint16
{
    if (reqLvl == 0 || mLevel >= reqLvl)
    {
        return base;
    }

    uint16 dmg = base;
    dmg *= mLevel * 3;
    dmg /= 4;
    dmg /= reqLvl;
    return dmg;
}

auto applySlotMod(CCharEntity* PChar, uint8 slot, xi::Mod mod, int16 amount, OverlayState& state) -> void
{
    if (PChar == nullptr || amount == 0 || mod == xi::Mod::NONE)
    {
        return;
    }

    if (slot == SLOT_SUB && mod == xi::Mod::MAIN_DMG_RANK)
    {
        mod = xi::Mod::SUB_DMG_RANK;
    }

    PChar->addModifier(mod, amount);
    state.mods[static_cast<int32>(mod)] = static_cast<int16>(state.mods[static_cast<int32>(mod)] + amount);
}

auto addWeaponDmgOverlay(CCharEntity* PChar, uint8 slot, CItemEquipment* PItem, uint8 mLevel, OverlayState& state) -> void
{
    auto* weapon = dynamic_cast<CItemWeapon*>(PItem);
    if (weapon == nullptr)
    {
        return;
    }

    const uint8  req    = weapon->getReqLvl();
    const uint16 wanted = static_cast<uint16>(std::max<int16>(0, wantedScale(weapon->getDamage(), mLevel, req)));
    const uint16 stock  = stockWeaponDmg(weapon->getDamage(), mLevel, req);
    if (wanted <= stock)
    {
        return;
    }

    const int16 extra = static_cast<int16>(wanted - stock);
    switch (slot)
    {
        case SLOT_MAIN:
            applySlotMod(PChar, slot, xi::Mod::MAIN_DMG_RATING, extra, state);
            break;
        case SLOT_SUB:
            applySlotMod(PChar, slot, xi::Mod::SUB_DMG_RATING, extra, state);
            break;
        case SLOT_RANGED:
        case SLOT_AMMO:
            applySlotMod(PChar, slot, xi::Mod::RANGED_DMG_RATING, extra, state);
            break;
        default:
            break;
    }
}

auto equipFingerprint(CCharEntity* PChar) -> uint32
{
    uint32 fp = PChar->GetMLevel();
    fp        = (fp * 16777619u) ^ PChar->m_LevelRestriction;
    for (uint8 slot = 0; slot < EquipSlotCount; ++slot)
    {
        CItemEquipment* PItem = PChar->getEquip(static_cast<SLOTTYPE>(slot));
        const uint32    id    = PItem != nullptr ? PItem->getID() : 0;
        fp                    = (fp * 16777619u) ^ (id + (static_cast<uint32>(slot) << 16));
    }

    return fp;
}

auto clearOverlay(CCharEntity* PChar) -> void
{
    if (PChar == nullptr)
    {
        return;
    }

    const auto it = g_overlays.find(PChar->id);
    if (it == g_overlays.end())
    {
        return;
    }

    for (const auto& [modId, amount] : it->second.mods)
    {
        if (amount != 0)
        {
            PChar->delModifier(static_cast<xi::Mod>(modId), amount);
        }
    }

    for (uint8 slot = 0; slot < EquipSlotCount; ++slot)
    {
        if (!it->second.latentSlots[slot])
        {
            continue;
        }

        CItemEquipment* PItem = PChar->getEquip(static_cast<SLOTTYPE>(slot));
        const uint8     req   = PItem != nullptr ? PItem->getReqLvl() : 0;
        PChar->PLatentEffectContainer->DelLatentEffects(req, slot);
        if (PItem != nullptr)
        {
            PChar->PLatentEffectContainer->AddLatentEffects(PItem->latentList, PItem->getReqLvl(), slot);
            PChar->PLatentEffectContainer->CheckLatentsEquip(slot);
        }
    }

    g_overlays.erase(it);
}

auto applyScaledGear(CCharEntity* PChar, bool pushStatus) -> void
{
    if (PChar == nullptr || PChar->status == xi::Status::Disappear || PChar->PLatentEffectContainer == nullptr)
    {
        return;
    }

    if (settings::get<bool>("map.DISABLE_GEAR_SCALING"))
    {
        clearOverlay(PChar);
        return;
    }

    const uint32 fingerprint = equipFingerprint(PChar);
    const auto   existing    = g_overlays.find(PChar->id);
    if (existing != g_overlays.end() && existing->second.fingerprint == fingerprint)
    {
        return;
    }

    clearOverlay(PChar);

    OverlayState state;
    state.fingerprint = fingerprint;

    const uint8 mLevel = PChar->GetMLevel();
    bool        added  = false;

    for (uint8 slot = 0; slot < EquipSlotCount; ++slot)
    {
        CItemEquipment* PItem = PChar->getEquip(static_cast<SLOTTYPE>(slot));
        if (PItem == nullptr)
        {
            continue;
        }

        const uint8 req = PItem->getReqLvl();
        if (req == 0 || mLevel >= req)
        {
            continue;
        }

        for (auto& mod : PItem->modList)
        {
            const int16 wanted = wantedScale(mod.getModAmount(), mLevel, req);
            const int16 stock  = stockScale(mod.getModAmount(), mLevel, req, mod.getModID());
            const int16 delta  = static_cast<int16>(wanted - stock);
            if (delta != 0)
            {
                applySlotMod(PChar, slot, mod.getModID(), delta, state);
                added = true;
            }
        }

        addWeaponDmgOverlay(PChar, slot, PItem, mLevel, state);

        for (auto& latent : PItem->latentList)
        {
            if (latent.ConditionsValue == static_cast<uint16>(xi::Latent::JobLevelAbove))
            {
                continue;
            }

            const int16 power = wantedScale(latent.ModPower, mLevel, req);
            PChar->PLatentEffectContainer->AddLatentEffect(latent.ConditionsID, latent.ConditionsValue, latent.ModValue, power);
            state.latentSlots[slot] = true;
            added                   = true;
        }

        if (state.latentSlots[slot])
        {
            PChar->PLatentEffectContainer->CheckLatentsEquip(slot);
        }
    }

    if (!state.mods.empty() || added)
    {
        PChar->UpdateHealth();
        g_overlays[PChar->id] = std::move(state);

        if (pushStatus && PChar->status != xi::Status::Disappear && g_refreshing.count(PChar->id) == 0)
        {
            g_refreshing.insert(PChar->id);
            PChar->pushPacket<GP_SERV_COMMAND_CLISTATUS>(PChar);
            g_refreshing.erase(PChar->id);
        }
    }
}

auto applyScaledGear(CCharEntity* PChar) -> void
{
    applyScaledGear(PChar, true);
}

} // namespace

class Ixi20GearSyncScalingModule : public CPPModule
{
public:
    void OnInit() override
    {
        if (!lua["CBaseEntity"].valid())
        {
            ShowWarning("Ixi20GearSyncScaling: CBaseEntity usertype missing");
            return;
        }

        sol::function prevLevelRestriction = lua["CBaseEntity"]["levelRestriction"];
        lua["CBaseEntity"]["levelRestriction"] = [prevLevelRestriction](CLuaBaseEntity entity, sol::object level) -> uint8 {
            uint8 result = 0;
            if (prevLevelRestriction.valid())
            {
                result = prevLevelRestriction(entity, level);
            }
            else
            {
                result = entity.levelRestriction(level);
            }

            applyScaledGear(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()));
            return result;
        };

        // Optional container/slot: stock and tests call equipItem(id), equipItem(id, nil, slot),
        // or 3 args. Required sol::object rejects Lua nil ("stack index 4, received nil").
        lua["CBaseEntity"]["equipItem"] = [](CLuaBaseEntity entity, uint16 itemID, sol::optional<sol::object> container, sol::optional<sol::object> equipSlot) {
            entity.equipItem(itemID, container.value_or(sol::object()), equipSlot.value_or(sol::object()));
            applyScaledGear(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()));
        };

        lua["CBaseEntity"]["unequipItem"] = [](CLuaBaseEntity entity, uint8 slotID) {
            entity.unequipItem(slotID);
            applyScaledGear(dynamic_cast<CCharEntity*>(entity.GetBaseEntity()));
        };

        lua["CBaseEntity"]["getGearModFromSlot"] = [](CLuaBaseEntity entity, uint8 slot, xi::Mod modId) -> int16 {
            auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
            if (PChar == nullptr)
            {
                return entity.getGearModFromSlot(slot, modId);
            }

            CItemEquipment* PItem = PChar->getEquip(static_cast<SLOTTYPE>(slot));
            if (PItem == nullptr)
            {
                return 0;
            }

            return wantedScale(PItem->getModifier(modId), PChar->GetMLevel(), PItem->getReqLvl());
        };

        lua["CBaseEntity"]["getMaxGearMod"] = [](CLuaBaseEntity entity, xi::Mod modId) -> int16 {
            auto* PChar = dynamic_cast<CCharEntity*>(entity.GetBaseEntity());
            if (PChar == nullptr)
            {
                return entity.getMaxGearMod(modId);
            }

            int16 maxVal = 0;
            for (uint8 slot = 0; slot < SLOT_BACK; ++slot)
            {
                CItemEquipment* PItem = PChar->getEquip(static_cast<SLOTTYPE>(slot));
                if (PItem == nullptr)
                {
                    continue;
                }

                const int16 value = wantedScale(PItem->getModifier(modId), PChar->GetMLevel(), PItem->getReqLvl());
                if (value > maxVal)
                {
                    maxVal = value;
                }
            }

            return maxVal;
        };

        ShowInfo("Imagine XI 2.0: level-sync gear scaling loaded");
    }

    void OnZoneTick(CZone* PZone) override
    {
        if (PZone == nullptr)
        {
            return;
        }

        PZone->ForEachChar([](CCharEntity* PChar) {
            applyScaledGear(PChar, false);
        });
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        applyScaledGear(PChar);
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        clearOverlay(PChar);
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr || g_refreshing.count(PChar->id) != 0)
        {
            return;
        }

        const uint16 type = packet->getType();
        if (type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_EQUIP_LIST) ||
            type == static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_CLISTATUS))
        {
            applyScaledGear(PChar);
        }
    }
};

REGISTER_CPP_MODULE(Ixi20GearSyncScalingModule);
