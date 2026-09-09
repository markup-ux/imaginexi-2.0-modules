-----------------------------------
-- Imagine XI 2.0: Benediction also restores MP
-- Same level-scaled amount as the HP heal, on every party target.
-- Official HP / status / doom / enmity behavior is kept.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_benediction_mp')

local function restoreMp(player, target)
    local restore = (target:getMaxMP() * player:getMainLvl()) / target:getMainLvl()
    local maxRestore = target:getMaxMP() - target:getMP()

    if restore > maxRestore then
        restore = maxRestore
    end

    if restore > 0 then
        target:addMP(restore)
    end
end

m:addOverride('xi.job_utils.white_mage.useBenediction', function(player, target, ability)
    local heal = super(player, target, ability)
    restoreMp(player, target)
    return heal
end)
