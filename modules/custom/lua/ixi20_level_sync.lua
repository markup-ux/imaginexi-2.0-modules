-----------------------------------
-- Imagine XI 1.0 bidirectional Level Sync (module only).
-- Party members match the designee's stored main job (up or down).
-- Combat/magic skills are capped for the synced level by ixi20_level_sync.cpp.
-- Zone/instance level_restriction is unchanged (down only).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_level_sync')

m:addOverride('xi.effects.level_sync.onEffectGain', function(target, effect)
    if Ixi20LevelSyncPrepare then
        Ixi20LevelSyncPrepare(target, effect)
    end

    super(target, effect)
end)
