-----------------------------------
-- Imagine XI 1.0 hybrid wyvern (module only)
-- Always DD + party support; ignores subjob OFFENSIVE / DEFENSIVE / MULTI.
-- Dual pets are not ported. Official wyvern damage multiplier is kept.
-- At 0 HP the wyvern idles (unkillable at 1 HP) instead of despawning.
-- Idle uses the same sit pose as /sit (and /heal rest). Healed above 1 HP, it returns to combat.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/dragoon')
-----------------------------------

local m = Module:new('ixi20_hybrid_wyvern')

local BREATH_RANGE_YALMS      = 14
local SUPPORT_COMBAT_INTERVAL = 10
local IDLE_VAR                = 'IXI20_WYVERN_IDLE'

local function isIdle(wyvern)
    return wyvern and wyvern:getLocalVar(IDLE_VAR) == 1
end

-- /heal puts the wyvern in HEALING; /sit copies SIT. PetIsHealing() clears HEALING
-- whenever the master is not resting, so injured idle uses SIT (same downed pose).
local function isRestPose(anim)
    return anim == xi.animation.SIT or anim == xi.animation.HEALING
end

local function applyIdlePose(wyvern)
    if not wyvern then
        return
    end

    if isRestPose(wyvern:getAnimation()) then
        return
    end

    wyvern:setAnimation(xi.animation.SIT)
end

local function clearIdlePose(wyvern, master)
    if not wyvern then
        return
    end

    local masterAnim = master and master.getAnimation and master:getAnimation()
    if isRestPose(masterAnim) then
        wyvern:setAnimation(masterAnim)
        return
    end

    if isRestPose(wyvern:getAnimation()) then
        wyvern:setAnimation(xi.animation.NONE)
    end
end

local function enterIdle(wyvern)
    if not wyvern or isIdle(wyvern) then
        return
    end

    wyvern:setLocalVar(IDLE_VAR, 1)
    wyvern:setAutoAttackEnabled(false)
    wyvern:setMobAbilityEnabled(false)
    -- Keep targetable so Cure / Spirit Link can raise it above 1 HP.
    -- setUntargetable is a no-op on TYPE_PET.

    local master = wyvern:getMaster()
    if master and master.isPC and master:isPC() then
        master:petRetreat()
        master:printToPlayer('Your wyvern is too injured to fight.', xi.msg.channel.SYSTEM_3)
    end

    applyIdlePose(wyvern)
end

local function leaveIdle(wyvern)
    if not wyvern or not isIdle(wyvern) then
        return
    end

    wyvern:setLocalVar(IDLE_VAR, 0)
    wyvern:setAutoAttackEnabled(true)
    wyvern:setMobAbilityEnabled(true)

    local master = wyvern:getMaster()
    clearIdlePose(wyvern, master)

    if not master or not master.isPC or not master:isPC() then
        return
    end

    master:printToPlayer('Your wyvern returns to battle.', xi.msg.channel.SYSTEM_3)

    if master:isEngaged() then
        local target = master:getTarget()
        if target then
            master:petAttack(target)
        end
    end
end

local function syncIdleState(wyvern)
    if not wyvern then
        return
    end

    local hp = wyvern:getHP()
    if hp <= 1 then
        enterIdle(wyvern)
        applyIdlePose(wyvern)
    elseif isIdle(wyvern) and hp > 1 then
        leaveIdle(wyvern)
    end
end

local function healingBreathIdForLevel(player)
    if player:getMainLvl() >= 80 then
        return xi.jobAbility.HEALING_BREATH_IV
    elseif player:getMainLvl() >= 40 then
        return xi.jobAbility.HEALING_BREATH_III
    elseif player:getMainLvl() >= 20 then
        return xi.jobAbility.HEALING_BREATH_II
    end

    return xi.jobAbility.HEALING_BREATH
end

local function inBreathRange(pet, target)
    return pet:getZoneID() == target:getZoneID() and pet:checkDistance(target) <= BREATH_RANGE_YALMS
end

local function pickBreathHealTarget(player, divisor)
    local pet = player:getPet()
    if not pet then
        return nil
    end

    local best     = nil
    local bestLoss = -1

    for _, member in pairs(player:getPartyWithTrusts()) do
        if not member:isDead() and inBreathRange(pet, member) then
            local maxHp = member:getMaxHP()
            local hp    = member:getHP()
            if hp <= math.floor(maxHp / divisor) then
                local loss = maxHp - hp
                if loss > bestLoss then
                    bestLoss = loss
                    best     = member
                end
            end
        end
    end

    return best
end

local function tryHealingBreath(player, divisor)
    local target = pickBreathHealTarget(player, divisor)
    if not target then
        return false
    end

    player:getPet():usePetAbility(healingBreathIdForLevel(player), target)
    return true
end

local function doStatusBreath(target, player)
    local wyvern = player:getPet()
    if not wyvern then
        return false
    end

    local removeBreathTable =
    {
        { 40, xi.jobAbility.REMOVE_PARALYSIS, { xi.effect.PARALYSIS } },
        { 60, xi.jobAbility.REMOVE_CURSE,     { xi.effect.CURSE_I, xi.effect.BANE, xi.effect.DOOM } },
        { 80, xi.jobAbility.REMOVE_DISEASE,   { xi.effect.DISEASE, xi.effect.PLAGUE } },
        { 20, xi.jobAbility.REMOVE_BLINDNESS, { xi.effect.BLINDNESS } },
        {  1, xi.jobAbility.REMOVE_POISON,    { xi.effect.POISON } },
    }

    for _, v in pairs(removeBreathTable) do
        if wyvern:getMainLvl() >= v[1] then
            for _, effect in pairs(v[3]) do
                if target:hasStatusEffect(effect) and wyvern:checkDistance(target) <= BREATH_RANGE_YALMS then
                    wyvern:usePetAbility(v[2], target)
                    return true
                end
            end
        end
    end

    return false
end

local function tryPartyStatusBreaths(master)
    if doStatusBreath(master, master) then
        return true
    end

    for _, member in pairs(master:getPartyWithTrusts()) do
        if member:getID() ~= master:getID() and doStatusBreath(member, master) then
            return true
        end
    end

    return false
end

-- Official wyvern.lua has no onMobFight / onMobRoam; stub so addOverride can wrap them.
xi.module.ensureTable('xi.pets.wyvern')
if type(xi.pets.wyvern.onMobFight) ~= 'function' then
    xi.pets.wyvern.onMobFight = function() end
end

if type(xi.pets.wyvern.onMobRoam) ~= 'function' then
    xi.pets.wyvern.onMobRoam = function() end
end

m:addOverride('xi.pets.wyvern.onMobSpawn', function(mob)
    -- Official 2014+ wyvern damage; 1.0 omitted this line.
    mob:setMobMod(xi.mobMod.BASE_DAMAGE_MULTIPLIER, 50)
    mob:setUnkillable(true)
    mob:setLocalVar(IDLE_VAR, 0)

    local master = mob:getMaster()
    if not master then
        return
    end

    -- TAKE_DAMAGE fires before HP is applied. Defer so unkillable clamp to 1 is visible.
    mob:addListener('TAKE_DAMAGE', 'IXI20_WYVERN_IDLE_HIT', function(wyvern, amount)
        wyvern:timer(1, function(wyvernArg)
            syncIdleState(wyvernArg)
        end)
    end)

    mob:addListener('COMBAT_TICK', 'IXI20_WYVERN_IDLE_COMBAT', function(wyvern)
        syncIdleState(wyvern)
        if isIdle(wyvern) and wyvern.isEngaged and wyvern:isEngaged() then
            local owner = wyvern:getMaster()
            if owner and owner.isPC and owner:isPC() then
                owner:petRetreat()
            end
        end
    end)

    mob:addListener('ROAM_TICK', 'IXI20_WYVERN_IDLE_ROAM', function(wyvern)
        syncIdleState(wyvern)
    end)

    mob:addListener('EFFECTS_TICK', 'IXI20_WYVERN_IDLE_TICK', function(wyvern)
        syncIdleState(wyvern)
    end)

    if master:getMod(xi.mod.WYVERN_SUBJOB_TRAITS) > 0 then
        mob:addWyvernJobTraits(master:getSubJob(), master:getSubLvl())
    end

    master:addListener('WEAPONSKILL_USE', 'PET_WYVERN_WS', function(player, target, skill, tp, action, damage)
        local pet = player:getPet()
        if not pet or isIdle(pet) then
            return
        end

        if not tryPartyStatusBreaths(player) then
            xi.job_utils.dragoon.pickAndUseDamageBreath(player, target)
        end
    end)

    master:addListener('MAGIC_USE', 'PET_WYVERN_MAGIC', function(player, target, spell, action)
        local pet = player:getPet()
        if not pet then
            return
        end

        if target and target.getID and pet.getID and target:getID() == pet:getID() then
            pet:timer(1, function(wyvernArg)
                syncIdleState(wyvernArg)
            end)
        end

        if isIdle(pet) then
            return
        end

        local divisor = 4
        if player:getMod(xi.mod.WYVERN_EFFECTIVE_BREATH) > 0 then
            divisor = 3
        end

        tryHealingBreath(player, divisor)
    end)

    master:addListener('ATTACK', 'PET_WYVERN_ENGAGE', function(player, target, action)
        local pet = player:getPet()
        if not pet or isIdle(pet) then
            return
        end

        local engageTarget = nil
        if target and (target:isMob() or target:isPet()) then
            engageTarget = target
        else
            for _, member in pairs(player:getPartyWithTrusts()) do
                if member:getID() ~= player:getID() and not member:isDead() then
                    local memberTarget = member:getTarget()
                    if
                        memberTarget and
                        memberTarget:isMob() and
                        member:checkDistance(memberTarget) < 30 and
                        player:checkDistance(memberTarget) < 30
                    then
                        engageTarget = memberTarget
                        break
                    end
                end
            end
        end

        if engageTarget == nil then
            return
        end

        if pet:getTarget() == nil or engageTarget:getID() ~= pet:getTarget():getID() then
            player:petAttack(engageTarget)
        end
    end)

    master:addListener('DISENGAGE', 'PET_WYVERN_DISENGAGE', function(player)
        player:petRetreat()
    end)

    master:addListener('EXPERIENCE_POINTS', 'PET_WYVERN_EXP', function(playerObj, mobObj, exp)
        xi.job_utils.dragoon.addWyvernExp(playerObj, exp)
    end)

    master:addListener('ABILITY_USE', 'IXI20_WYVERN_HEAL', function(player, target, ability)
        if not ability or ability:getID() ~= xi.jobAbility.SPIRIT_LINK then
            return
        end

        local pet = player:getPet()
        if not pet then
            return
        end

        -- Spirit Link addHP runs in OnAbility, just before this listener.
        pet:timer(1, function(wyvernArg)
            syncIdleState(wyvernArg)
        end)
    end)
end)

m:addOverride('xi.pets.wyvern.onMobFight', function(wyvern, target)
    syncIdleState(wyvern)

    local master = wyvern:getMaster()
    if not master or not master:isPC() or isIdle(wyvern) then
        return
    end

    local phase = wyvern:getLocalVar('WYVERN_SUPPORT_PHASE') + 1
    wyvern:setLocalVar('WYVERN_SUPPORT_PHASE', phase)
    if phase % SUPPORT_COMBAT_INTERVAL ~= 0 then
        return
    end

    if not wyvern:canUseAbilities() then
        return
    end

    if tryPartyStatusBreaths(master) then
        return
    end

    local emergency  = nil
    local worstRatio = 1.0

    for _, member in pairs(master:getPartyWithTrusts()) do
        if not member:isDead() and inBreathRange(wyvern, member) then
            local ratio = member:getHP() / math.max(1, member:getMaxHP())
            if ratio <= 0.20 and ratio < worstRatio then
                worstRatio = ratio
                emergency  = member
            end
        end
    end

    if emergency then
        wyvern:usePetAbility(healingBreathIdForLevel(master), emergency)
    end
end)

m:addOverride('xi.pets.wyvern.onMobRoam', function(wyvern)
    syncIdleState(wyvern)
end)

m:addOverride('xi.pets.wyvern.onMobDeath', function(mob, player)
    super(mob, player)
    local master = mob:getMaster() or player
    if master and master.removeListener then
        master:removeListener('IXI20_WYVERN_HEAL')
    end
end)

return m
