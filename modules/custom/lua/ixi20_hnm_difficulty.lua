-----------------------------------
-- Imagine XI 2.0 world-HNM difficulty.
-- Injects 1.0 anti-melt + healer pressure and allowlist HP/stat boosts.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('modules/custom/lua/ixi20_hnm_roster')
require('modules/custom/lua/ixi20_hnm_anti_melt')
require('modules/custom/lua/ixi20_healer_pressure')
-----------------------------------

local m = Module:new('ixi20_hnm_difficulty')

local STAT_MODS =
{
    xi.mod.STR,
    xi.mod.DEX,
    xi.mod.VIT,
    xi.mod.AGI,
    xi.mod.INT,
    xi.mod.MND,
    xi.mod.CHR,
}

local function setting(key, fallback)
    local map = xi.settings and xi.settings.map
    if map and map[key] ~= nil then
        return map[key]
    end

    return fallback
end

local function applyAllowlistStats(mob)
    if mob:getLocalVar('[ixi20Hnm]statsApplied') == 1 then
        return
    end

    local hpMult   = setting('IMAGINEXI_HNM_HP_MULTIPLIER', 3.0)
    if xi.ixi20Sky and xi.ixi20Sky.hpMultiplier then
        local custom = xi.ixi20Sky.hpMultiplier(mob)
        if custom then
            hpMult = custom
        end
    end

    local statMult = setting('IMAGINEXI_HNM_STAT_MULTIPLIER', 2.0)
    local storeTp  = setting('IMAGINEXI_HNM_STORE_TP', 60)

    if hpMult and hpMult > 1.0 then
        local newHp = math.max(1, math.floor(mob:getMaxHP() * hpMult))
        mob:setMaxHP(newHp)
        mob:setHP(newHp)
    end

    if statMult and statMult > 1.0 then
        local extra = statMult - 1.0
        for _, stat in ipairs(STAT_MODS) do
            local current = mob:getMod(stat)
            if current ~= 0 then
                mob:addMod(stat, math.floor(current * extra))
            end
        end
    end

    if storeTp and storeTp > 0 then
        mob:addMod(xi.mod.STORETP, storeTp)
    end

    mob:setLocalVar('[ixi20Hnm]statsApplied', 1)
end

for _, target in ipairs(xi.ixi20Hnm.worldTargets) do
    if xi.ixi20Hnm.isPackageTarget(target) then
        m:addOverride(xi.ixi20Hnm.overridePath(target.zone, target.mob, 'onMobInitialize'), function(mob)
            super(mob)
            xi.hnmAntiMelt.attach(mob)
            xi.healerPressure.attach(mob)
        end)

        m:addOverride(xi.ixi20Hnm.overridePath(target.zone, target.mob, 'onMobSpawn'), function(mob)
            super(mob)
            applyAllowlistStats(mob)
            xi.hnmAntiMelt.applyBase(mob)
            xi.healerPressure.onSpawn(mob)
        end)
    end
end
