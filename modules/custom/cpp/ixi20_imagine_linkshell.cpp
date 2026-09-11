/************************************************************************
 * Imagine XI 2.0: server linkshell "Imagine"
 *
 * Forest green with a hint of navy. Created on map start if missing.
 * Lua grants a pearl on create / login.
 *
 * Color packing matches 0x0C4: (a << 12) | (b << 8) | (g << 4) | r
 *   r=2, g=11, b=5, a=10  ->  0xA5B2
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/database.h"
#include "common/logging.h"

#include "map/linkshell.h"

namespace
{

constexpr const char* LsName = "Imagine";
constexpr uint16      LsColor = 0xA5B2;

} // namespace

class Ixi20ImagineLinkshellModule : public CPPModule
{
public:
    void OnInit() override
    {
        const auto existing = db::preparedStmt("SELECT linkshellid FROM linkshells WHERE name = ? AND broken != 1 LIMIT 1", LsName);
        if (existing && existing->rowsCount() > 0)
        {
            ShowInfo("Imagine XI 2.0: server linkshell Imagine already exists");
            return;
        }

        const auto id = linkshell::RegisterNewLinkshell(LsName, LsColor);
        if (id != 0)
        {
            ShowInfoFmt("Imagine XI 2.0: created server linkshell Imagine (id {})", id);
        }
        else
        {
            ShowError("Imagine XI 2.0: failed to create server linkshell Imagine");
        }
    }
};

REGISTER_CPP_MODULE(Ixi20ImagineLinkshellModule);
