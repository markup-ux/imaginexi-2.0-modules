/************************************************************************
 * Imagine XI 2.0: no avatar perpetuation MP cost (module only).
 *
 * 1.0 made petutils::PerpetuationCost() return 0. This keeps core src
 * untouched and zeros AVATAR_PERPETUATION after spawn / zone / level
 * restriction recalcs. Lua ixi20_no_perpetuation.lua covers scripted
 * summons. Gear remaps live in ixi20_no_perpetuation.sql.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/entities/char_entity.h"
#include "map/modifier.h"
#include "map/zone.h"

namespace
{

void stripPerpetuation(CCharEntity* PChar)
{
    if (PChar == nullptr)
    {
        return;
    }

    if (PChar->getMod(xi::Mod::AVATAR_PERPETUATION) != 0)
    {
        PChar->setModifier(xi::Mod::AVATAR_PERPETUATION, 0);
    }
}

} // namespace

class Ixi20NoPerpetuationModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: avatar perpetuation cost disabled");
    }

    void OnZoneTick(CZone* PZone) override
    {
        if (PZone == nullptr)
        {
            return;
        }

        PZone->ForEachChar([](CCharEntity* PChar) {
            stripPerpetuation(PChar);
        });
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        stripPerpetuation(PChar);
    }
};

REGISTER_CPP_MODULE(Ixi20NoPerpetuationModule);
