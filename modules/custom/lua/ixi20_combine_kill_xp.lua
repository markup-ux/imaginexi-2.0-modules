-----------------------------------
-- Imagine XI 2.0: fold death-gil XP into the combat XP grant.
-- Chat merge of RoE / sparks / book XP is C++ ixi20_combine_kill_xp.cpp
-- (one 0x02D "gains X" per zone-tick burst). Only mobs that would drop
-- gil (beastmen / gil mods) add that half. Too Weak stays suppressed.
-- Assignment wrap survives FileWatcher.
-- Load after ixi20_share_xp and ixi20_gil_economy.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_economy')
-----------------------------------

local m = Module:new('ixi20_combine_kill_xp')

if not xi.ixi20_economy._rawKillExpCalculate then
    xi.ixi20_economy._rawKillExpCalculate = xi.experiencePoints.calculate
end

xi.experiencePoints.calculate = function(member, mob, data)
    local result = xi.ixi20_economy._rawKillExpCalculate(member, mob, data)
    return xi.ixi20_economy.addKillGilExp(member, mob, result)
end
