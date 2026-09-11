-----------------------------------
-- Imagine XI 2.0: !dig on any mount, no Gysahl Greens.
-- Native chocobo-dig action is handled by ixi20_mount_dig.cpp.
-- Command file only: do not call Module:new (no overrides).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/hobbies/chocobo_digging/logic')
-----------------------------------

local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if not player:hasStatusEffect(xi.effect.MOUNTED) then
        player:printToPlayer('You must be mounted to dig.', xi.msg.channel.SYSTEM_3)
        return
    end

    xi.chocoboDig.start(player)
end

xi.module.registerCommand('dig', commandObj)
xi.commands = xi.commands or {}
xi.commands.dig = commandObj
