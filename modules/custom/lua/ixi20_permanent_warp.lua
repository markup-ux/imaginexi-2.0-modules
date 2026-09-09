-----------------------------------
-- Scroll of Instant Warp (4181) is not consumed on use.
-- Consume commits after onItemUse; restore on the next tick, before the 3s teleport.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_permanent_warp')

local WARP_SCROLL = xi.item.SCROLL_OF_INSTANT_WARP

m:addOverride('xi.items.scroll_of_instant_warp.onItemUse', function(target, user, item, action)
    super(target, user, item, action)

    if not user or not user.isPC or not user:isPC() then
        return
    end

    user:timer(100, function(playerArg)
        if not playerArg or not playerArg.isPC or not playerArg:isPC() then
            return
        end

        if playerArg:hasItem(WARP_SCROLL) then
            return
        end

        playerArg:addItem({ id = WARP_SCROLL, silent = true })
    end)
end)
