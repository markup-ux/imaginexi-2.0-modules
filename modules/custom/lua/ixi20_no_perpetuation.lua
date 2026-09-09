-----------------------------------
-- Imagine XI 2.0: no avatar perpetuation MP cost (module only).
-- 1.0 returned 0 from PerpetuationCost(). Core src is left alone;
-- this zeros AVATAR_PERPETUATION after spawn / login. C++ module
-- also clears it on zone tick (level restriction recalcs the cost).
-- Gear with Avatar perpetuation cost is remapped in ixi20_no_perpetuation.sql.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_no_perpetuation')

local function stripPerpetuation(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    if player:getMod(xi.mod.AVATAR_PERPETUATION) ~= 0 then
        player:setMod(xi.mod.AVATAR_PERPETUATION, 0)
    end
end

m:addOverride('xi.pets.avatar.onMobSpawn', function(pet)
    super(pet)
    stripPerpetuation(pet:getMaster())
end)

m:addOverride('xi.pet.spawnPet', function(caster, petID, state, target)
    super(caster, petID, state, target)
    stripPerpetuation(caster)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    stripPerpetuation(player)
end)
