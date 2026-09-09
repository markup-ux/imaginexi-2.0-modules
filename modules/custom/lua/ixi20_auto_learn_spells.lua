-----------------------------------
-- Grant level-eligible spells after the C++ hook (login / job change)
-- and again on level-up. Level-up also names newly unlocked spells,
-- job abilities, and traits in chat. Skips trusts.
--
-- This module can only teach spells on the server. The native magic
-- Available list is client DAT (ROM/118/114.DAT), rebuilt from
-- ixi20_job_progression_37cap.sql by:
--   tools/scripts/ixi20_sync_menu_spell_levels.py
--   tools/scripts/deploy_ixi20_spell_menu_114.ps1  (Administrator)
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_auto_learn_spells')

local function grant(player, announce)
    if Ixi20GrantSpells then
        Ixi20GrantSpells(player, announce)
    end
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    grant(player, false)
end)

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)
    grant(player, true)
end)
