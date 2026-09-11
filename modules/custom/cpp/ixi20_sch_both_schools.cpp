/************************************************************************
 * Imagine XI 2.0: SCH addendum spells do not need Addendum White/Black
 *
 * Cure IV / Stoneskin / the other addendum-only spells check SPELLREQ_ADDENDUM_*.
 * Strip those flags so known SCH spells of either school can be cast with
 * Light Arts, Dark Arts, or neither. Rebuild xi_map.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"

#include "map/spell.h"

namespace
{

void clearAddendumRequirements()
{
    uint16 cleared = 0;
    for (uint16 id = 0; id < MAX_SPELL_ID; ++id)
    {
        auto* PSpell = spell::GetSpell(static_cast<SpellID>(id));
        if (PSpell == nullptr)
        {
            continue;
        }

        const uint8 requirements = PSpell->getRequirements();
        const uint8 addendum     = static_cast<uint8>(SPELLREQ_ADDENDUM_BLACK | SPELLREQ_ADDENDUM_WHITE);
        if ((requirements & addendum) != 0)
        {
            PSpell->setRequirements(static_cast<uint8>(requirements & ~addendum));
            ++cleared;
        }
    }

    ShowInfoFmt("Imagine XI 2.0: SCH both-schools module cleared addendum requirements on {} spells", cleared);
}

} // namespace

class Ixi20SchBothSchoolsModule : public CPPModule
{
public:
    void OnInit() override
    {
        clearAddendumRequirements();
    }
};

REGISTER_CPP_MODULE(Ixi20SchBothSchoolsModule);
