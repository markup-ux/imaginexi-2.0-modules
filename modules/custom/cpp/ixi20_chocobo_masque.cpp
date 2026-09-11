/************************************************************************
 * Imagine XI 2.0: Chocobo Masque +1 reuse is always ready (module only)
 *
 * Stock item_usable recast is 20 hours. Patch the item template so every
 * spawned copy has a 0s reuse. Lua supplies the missing onItemUse warp.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/timer.h"

#include "map/entities/char_entity.h"
#include "map/item_container.h"
#include "map/items/item_usable.h"
#include "map/map_constants.h"
#include "map/utils/itemutils.h"

namespace
{

constexpr uint16 ChocoboMasqueP1 = 27760;
constexpr uint16 ChocoboMasque   = 27765;

void zeroMasqueReuse(uint16 itemId)
{
    auto* item = const_cast<CItemUsable*>(xi::items::lookup<CItemUsable>(itemId));
    if (item == nullptr)
    {
        ShowErrorFmt("Imagine XI 2.0: chocobo masque item {} not loaded", itemId);
        return;
    }

    item->setReuseDelay(0s);
}

void readyMasque(CItemUsable* item)
{
    if (item == nullptr)
    {
        return;
    }

    const auto id = item->getID();
    if (id != ChocoboMasqueP1 && id != ChocoboMasque)
    {
        return;
    }

    item->setReuseDelay(0s);
    item->setLastUseTime(timer::time_point{});
    if (item->getMaxCharges() > 0)
    {
        item->setCurrentCharges(item->getMaxCharges());
    }
}

} // namespace

class Ixi20ChocoboMasqueModule : public CPPModule
{
public:
    void OnInit() override
    {
        zeroMasqueReuse(ChocoboMasqueP1);
        zeroMasqueReuse(ChocoboMasque);
        ShowInfo("Imagine XI 2.0: Chocobo Masque warp recast disabled");
    }

    void OnCharZoneIn(CCharEntity* PChar) override
    {
        if (PChar == nullptr)
        {
            return;
        }

        for (uint8 loc = 0; loc < CONTAINER_ID::MAX_CONTAINER_ID; ++loc)
        {
            CItemContainer* container = PChar->getStorage(loc);
            if (container == nullptr)
            {
                continue;
            }

            for (uint8 slot = 0; slot <= container->GetSize(); ++slot)
            {
                readyMasque(dynamic_cast<CItemUsable*>(container->GetItem(slot)));
            }
        }
    }
};

REGISTER_CPP_MODULE(Ixi20ChocoboMasqueModule);
