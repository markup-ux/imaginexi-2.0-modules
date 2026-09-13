-----------------------------------
-- Imagine XI 2.0: NIN-main ninjutsu skill bonus for 75-cap
-- Stock windows are 99-era (San 275-500). San is learned at 37 here
-- and A+ caps at 276, so San sat at ~1.00x. V / M / I, Futae, Innin
-- gear, and NINJUTSU_POWER are unchanged. Sub NIN and other mains stay 1x.
-- FileWatcher drops addOverride; assignment wrap stays live.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/spells/damage_spell')
-----------------------------------

local m = Module:new('ixi20_ninjutsu_damage')

-- Tier = { min skill (1.0x), max skill }. Rate stays (skill - min) / 200.
-- Ichi keeps the stock 50-250 window (already 2.0x at 75 A+).
-- Ni / San start at 1.0x when learned (A+ 63 / 114) and top out at 75 A+ 276.
local skillCaps =
{
    [1] = {  50, 250 },
    [2] = {  63, 276 },
    [3] = { 114, 276 },
}

local function calculateNinSkillBonus(caster, spellId, skillType)
    if caster:getMainJob() ~= xi.job.NIN then
        return 1
    end

    if skillType ~= xi.skill.NINJUTSU then
        return 1
    end

    local spellTier = 3

    if spellId % 3 == 2 then
        spellTier = 1
    elseif spellId % 3 == 0 then
        spellTier = 2
    end

    local minSkill   = skillCaps[spellTier][1]
    local maxSkill   = skillCaps[spellTier][2]
    local skillLevel = utils.clamp(caster:getSkillLevel(xi.skill.NINJUTSU), minSkill, maxSkill)

    return 1 + (skillLevel - minSkill) / 200
end

m:addOverride('xi.spells.damage.calculateNinSkillBonus', calculateNinSkillBonus)

if not xi.spells.damage._ixi20NinjutsuDamage then
    xi.spells.damage._ixi20NinjutsuDamage = true
end

xi.spells.damage.calculateNinSkillBonus = calculateNinSkillBonus
