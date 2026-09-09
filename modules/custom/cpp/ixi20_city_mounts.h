/************************************************************************
 * Imagine XI 2.0: city list that 1.0 marked MISC_MOUNT.
 *
 * 1.0 ORed 0x0004 onto zone_settings.misc. 2.0 loads misc from
 * data/zones/<zone>/zone.yaml, so SQL cannot enable this. Modules use
 * this list instead of editing core YAML.
 ************************************************************************/

#pragma once

#include "data/enums/zone.h"
#include "data/enums/zone_misc.h"

#include "map/zone.h"

namespace ixi20
{

// Same zones as CursorXI server/sql/z_imagine_xi_90_world_qol.sql
// ("Enable mounts in all main cities").
inline constexpr xi::ZoneId kMainCityMountZones[] = {
    xi::ZoneId::SouthernSanDoria,
    xi::ZoneId::NorthernSanDoria,
    xi::ZoneId::PortSanDoria,
    xi::ZoneId::ChateauDoraguille,
    xi::ZoneId::BastokMines,
    xi::ZoneId::BastokMarkets,
    xi::ZoneId::PortBastok,
    xi::ZoneId::Metalworks,
    xi::ZoneId::WindurstWaters,
    xi::ZoneId::WindurstWalls,
    xi::ZoneId::PortWindurst,
    xi::ZoneId::WindurstWoods,
    xi::ZoneId::HeavensTower,
    xi::ZoneId::RuludeGardens,
    xi::ZoneId::UpperJeuno,
    xi::ZoneId::LowerJeuno,
    xi::ZoneId::PortJeuno,
    xi::ZoneId::AlZahbi,
    xi::ZoneId::AhtUrhganWhitegate,
    xi::ZoneId::WesternAdoulin,
    xi::ZoneId::EasternAdoulin,
    xi::ZoneId::Rabao,
    xi::ZoneId::Selbina,
    xi::ZoneId::Mhaura,
    xi::ZoneId::Kazham,
    xi::ZoneId::HallOfTheGods,
    xi::ZoneId::Norg,
};

inline auto isMainCityMountZone(xi::ZoneId zoneId) -> bool
{
    for (const auto id : kMainCityMountZones)
    {
        if (id == zoneId)
        {
            return true;
        }
    }

    return false;
}

inline auto zoneAllowsIxi20Mount(const CZone* zone) -> bool
{
    if (zone == nullptr)
    {
        return false;
    }

    return zone->CanUseMisc(xi::ZoneMisc::Mount) || isMainCityMountZone(zone->GetID());
}

} // namespace ixi20
