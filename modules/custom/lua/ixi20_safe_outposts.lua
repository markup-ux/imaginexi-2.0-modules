-----------------------------------
-- Imagine XI 2.0: move 1.0 outpost-adjacent trash off the camp.
-- YAML owns field spawns, so this relocates at zone init (not SQL).
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_safe_outposts')

local MATCH_RADIUS = 15

-- old xyz = 1.0 outpost camp. new xyz = safer 1.0 landing.
local moves =
{
    {
        zone   = 'Valkurm_Dunes',
        name   = 'Goblin_Leecher',
        old    = { 184.673, -7.710, 106.691 },
        new    = { 210.481, -6.946, 101.274 },
    },
    {
        zone   = 'Buburimu_Peninsula',
        name   = 'Goblin_Shepherd',
        old    = { -166.429, 7.910, -105.478 },
        new    = { -396.957, -32.261, 44.893 },
    },
    {
        zone   = 'Buburimu_Peninsula',
        name   = 'Goblin_Bandit',
        old    = { -134.000, 7.000, -96.000 },
        new    = { -411.430, -31.429, 3.221 },
    },
    {
        zone   = 'Cape_Teriggan',
        name   = 'Goblin_Mercenary',
        old    = { -139.706, 7.167, -61.223 },
        new    = { -75.189, -1.413, -130.057 },
    },
    {
        zone   = 'Cape_Teriggan',
        name   = 'Goblin_Mercenary',
        old    = { -144.000, 8.000, -21.000 },
        new    = { -7.247, 0.161, 0.709 },
    },
    {
        zone   = 'Cape_Teriggan',
        name   = 'Goblin_Bandit',
        old    = { -154.915, 7.554, -38.958 },
        new    = { -61.728, -1.335, -99.354 },
    },
    {
        zone   = 'Cape_Teriggan',
        name   = 'Goblin_Robber',
        old    = { -239.932, 8.205, -222.775 },
        new    = { -37.084, 0.000, -37.121 },
    },
    {
        zone   = 'Cape_Teriggan',
        name   = 'Goblin_Robber',
        old    = { -232.230, 7.024, -273.263 },
        new    = { -24.580, 0.737, -82.615 },
    },
    {
        zone   = 'Eastern_Altepa_Desert',
        name   = 'Goblin_Ambusher',
        old    = { -521.287, -32.811, 85.324 },
        new    = { -325.870, 7.453, -196.602 },
    },
    {
        zone   = 'Eastern_Altepa_Desert',
        name   = 'Goblin_Butcher',
        old    = { -482.059, -31.970, 67.880 },
        new    = { -146.846, 8.510, -239.809 },
    },
    {
        zone   = 'Yuhtunga_Jungle',
        name   = 'Goblin_Furrier',
        old    = { -224.306, -1.550, -358.469 },
        new    = { -190.317, -0.048, -340.674 },
    },
    {
        zone   = 'Yuhtunga_Jungle',
        name   = 'Goblin_Furrier',
        old    = { -238.298, -0.420, -366.293 },
        new    = { -291.329, -0.013, -351.107 },
    },
    {
        zone   = 'Yhoator_Jungle',
        name   = 'Tonberry_Hexer',
        old    = { 236.941, -0.50, -82.527 },
        new    = { 244.705, 0.000, -162.007 },
    },
    {
        zone   = 'Yhoator_Jungle',
        name   = 'Tonberry_Creeper',
        old    = { 236.445, 0.017, -99.661 },
        new    = { 230.252, 0.600, -190.586 },
    },
    {
        zone   = 'Yhoator_Jungle',
        name   = 'Tonberry_Harasser',
        old    = { 231.520, -0.125, -101.445 },
        new    = { 207.793, 0.594, -174.136 },
    },
}

local function dist2(mob, xyz)
    local dx = mob:getXPos() - xyz[1]
    local dy = mob:getYPos() - xyz[2]
    local dz = mob:getZPos() - xyz[3]
    return dx * dx + dy * dy + dz * dz
end

local function relocate(zone, move)
    if not zone or not zone.queryEntitiesByName then
        return 0
    end

    local mobs = zone:queryEntitiesByName(move.name)
    if not mobs then
        return 0
    end

    local radius2 = MATCH_RADIUS * MATCH_RADIUS
    local moved   = 0

    for _, mob in ipairs(mobs) do
        if mob and mob.getXPos and dist2(mob, move.old) <= radius2 then
            mob:setSpawn(move.new[1], move.new[2], move.new[3])
            if mob.setPos then
                mob:setPos(move.new[1], move.new[2], move.new[3])
            end

            moved = moved + 1
        end
    end

    return moved
end

local byZone = {}
for _, move in ipairs(moves) do
    byZone[move.zone] = byZone[move.zone] or {}
    table.insert(byZone[move.zone], move)
end

for zoneName, zoneMoves in pairs(byZone) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', zoneName), function(zone)
        super(zone)
        for _, move in ipairs(zoneMoves) do
            relocate(zone, move)
        end
    end)
end
