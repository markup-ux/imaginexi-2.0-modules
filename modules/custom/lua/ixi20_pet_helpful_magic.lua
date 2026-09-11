-----------------------------------
-- Imagine XI 2.0: Cure actually heals player pets (module only).
-- C++ ixi20_pet_helpful_magic.cpp lets Cure / Protect *target* pets.
-- Stock isValidHealTarget omits PET, so Cure still reports
-- "<caster>'s Cure has no effect on Wyvern" after a successful cast.
-- Same allegiance + PET covers wyvern / avatar / jug / automaton.
-- Enemy pets keep a different allegiance, so they stay invalid.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_pet_helpful_magic')

m:addOverride('isValidHealTarget', function(caster, target)
    if super(caster, target) then
        return true
    end

    return target:getAllegiance() == caster:getAllegiance() and target:isPet()
end)

return m
