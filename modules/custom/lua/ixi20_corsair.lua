-----------------------------------
-- Imagine XI 2.0 Corsair (module only)
-- - All Phantom Rolls are learned (no dice) on create / login
-- - Pair with ixi20_corsair.sql so every roll unlocks at level 1
-- - Quick Draw shots do not require or consume cards
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')
require('scripts/globals/job_utils/corsair')
-----------------------------------

local m = Module:new('ixi20_corsair')

local PHANTOM_ROLLS =
{
    xi.jobAbility.FIGHTERS_ROLL,
    xi.jobAbility.MONKS_ROLL,
    xi.jobAbility.HEALERS_ROLL,
    xi.jobAbility.WIZARDS_ROLL,
    xi.jobAbility.WARLOCKS_ROLL,
    xi.jobAbility.ROGUES_ROLL,
    xi.jobAbility.GALLANTS_ROLL,
    xi.jobAbility.CHAOS_ROLL,
    xi.jobAbility.BEAST_ROLL,
    xi.jobAbility.CHORAL_ROLL,
    xi.jobAbility.HUNTERS_ROLL,
    xi.jobAbility.SAMURAI_ROLL,
    xi.jobAbility.NINJA_ROLL,
    xi.jobAbility.DRACHEN_ROLL,
    xi.jobAbility.EVOKERS_ROLL,
    xi.jobAbility.MAGUSS_ROLL,
    xi.jobAbility.CORSAIRS_ROLL,
    xi.jobAbility.PUPPET_ROLL,
    xi.jobAbility.DANCERS_ROLL,
    xi.jobAbility.SCHOLARS_ROLL,
    xi.jobAbility.BOLTERS_ROLL,
    xi.jobAbility.CASTERS_ROLL,
    xi.jobAbility.COURSERS_ROLL,
    xi.jobAbility.BLITZERS_ROLL,
    xi.jobAbility.TACTICIANS_ROLL,
    xi.jobAbility.ALLIES_ROLL,
    xi.jobAbility.MISERS_ROLL,
    xi.jobAbility.COMPANIONS_ROLL,
    xi.jobAbility.AVENGERS_ROLL,
    xi.jobAbility.NATURALISTS_ROLL,
    xi.jobAbility.RUNEISTS_ROLL,
}

local function grantPhantomRolls(player)
    if not player or not player.isPC or not player:isPC() then
        return
    end

    local learnedAny = false
    for _, abilityId in ipairs(PHANTOM_ROLLS) do
        if abilityId and not player:hasLearnedAbility(abilityId) then
            player:addLearnedAbility(abilityId)
            learnedAny = true
        end
    end

    if learnedAny then
        player:recalculateAbilitiesTable()
    end
end

m:addOverride('xi.player.charCreate', function(player)
    super(player)
    grantPhantomRolls(player)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    grantPhantomRolls(player)
end)

-- addOverride is discarded on FileWatcher reload; assignment wrap is not.
if xi.job_utils and xi.job_utils.corsair then
    if not xi.job_utils.corsair._ixi20NoCardShots then
        xi.job_utils.corsair._ixi20NoCardShots = true

        xi.job_utils.corsair.checkQuickDraw = function(player, ability)
            local data = xi.job_utils.corsair.quickDrawDataTable[ability:getID()]
            if not data then
                return xi.msg.basic.CANNOT_PERFORM, 0
            end

            if
                player:getWeaponSkillType(xi.slot.RANGED) ~= xi.skill.MARKSMANSHIP or
                player:getWeaponSkillType(xi.slot.AMMO) ~= xi.skill.MARKSMANSHIP
            then
                return xi.msg.basic.NO_RANGED_WEAPON, 0
            end

            return 0, 0
        end

        local rawUseElementalShot = xi.job_utils.corsair.useElementalShot
        xi.job_utils.corsair.useElementalShot = function(actor, target, ability, action)
            local abilityId = ability:getID()
            local data      = xi.job_utils.corsair.quickDrawDataTable[abilityId]
            if not data then
                return rawUseElementalShot(actor, target, ability, action)
            end

            -- No card consume. Remainder matches stock useElementalShot.
            action:setRecast(math.max(0, action:getRecast() - actor:getMod(xi.mod.QUICK_DRAW_RECAST)))
            target:updateClaim(actor)

            local params =
            {
                skillType      = xi.skill.MARKSMANSHIP,
                magicalElement = data.element,
                actorStat      = xi.mod.AGI,
                bonusAcc       = actor:getMerit(xi.merit.QUICK_DRAW_ACCURACY) + actor:getMod(xi.mod.QUICK_DRAW_MACC),
            }
            local resist = xi.combat.magicHitRate.calculateResistRate(actor, target, params)

            local damage = 0
            if data.canDamage then
                damage = xi.job_utils.corsair.handleQuickDrawDamage(actor, target, action, data.element, resist)
            end

            if damage > 0 then
                actor:addTP(xi.combat.tp.getSingleRangedHitTPReturn(actor))
                actor:trySkillUp(xi.skill.MARKSMANSHIP, target:getMainLvl())
            end

            if damage < 0 then
                ability:setMsg(xi.msg.basic.JA_RECOVERS_HP)
                return damage
            end

            xi.job_utils.corsair.handleQuickDrawEffectBoost(actor, target, abilityId, data.multiplier)

            if data.applyEffectId > 0 then
                if
                    xi.data.statusEffect.isTargetImmune(target, data.applyEffectId, data.element) or
                    xi.data.statusEffect.isTargetResistant(actor, target, data.applyEffectId) or
                    not xi.data.statusEffect.isResistRateSuccessfull(data.applyEffectId, resist, 0)
                then
                    ability:setMsg(xi.msg.basic.JA_MISS_2)
                    return data.applyEffectId
                end

                if data.applyEffectId == xi.effect.SLEEP_I then
                    if target:addStatusEffect(xi.effect.SLEEP_I, { power = 1, duration = math.floor(90 * resist), subPower = data.element, origin = actor }) then
                        ability:setMsg(xi.msg.basic.JA_ENFEEB_IS)
                    else
                        ability:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
                    end

                    return xi.effect.SLEEP_I
                end

                ability:setMsg(xi.msg.basic.JA_REMOVE_EFFECT_2)

                local dispelledEffect = target:dispelStatusEffect()
                if dispelledEffect == xi.effect.NONE then
                    ability:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
                end

                return dispelledEffect
            end

            return damage
        end
    end
end
