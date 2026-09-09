-----------------------------------
-- 1.0 mobskill defense scaling (module helper). Used by HNM ward stoneskin.
-----------------------------------
require('scripts/utils/utils')
-----------------------------------
xi = xi or {}
xi.ixi20HnmDefense = xi.ixi20HnmDefense or {}

local function tierMultiplier(mob)
    if mob:isNM() then
        return 2.85
    end

    if mob:getMobMod(xi.mobMod.CHECK_AS_NM) > 0 then
        return 1.70
    end

    return 1.0
end

xi.ixi20HnmDefense.diamondhide = function(mob)
    local lvl   = mob:getMainLvl()
    local maxHp = math.max(1, mob:getMaxHP())
    local tier  = tierMultiplier(mob)
    local absorb = utils.clamp(math.floor((200 + lvl * 12 + maxHp * 0.011) * tier), 400, 20000)
    local duration = 300

    if tier >= 2.85 then
        duration = 420
    elseif tier >= 1.70 then
        duration = 360
    end

    return absorb, duration
end

return xi.ixi20HnmDefense
