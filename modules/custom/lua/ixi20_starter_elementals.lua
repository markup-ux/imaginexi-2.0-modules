-----------------------------------
-- Imagine XI 2.0: starter-zone elementals (1.0 imagine_starter_elementals).
-- Same-zone SQL groups (not Beaucedine 38) so insertDynamicEntity stays
-- on the path starter HNM / pixie already use. 1.0 disabled the old
-- cross-zone dynamic IDs after client ACCESS_VIOLATION.
-- Needs custom/sql/ixi20_starter_elementals.sql.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
-----------------------------------

local m = Module:new('ixi20_starter_elementals')

local RESPAWN_SECONDS = 900
local MIN_LEVEL       = 4
local MAX_LEVEL       = 9

-- groupId is per-zone (38-45). See ixi20_starter_elementals.sql.
local ELEMENT =
{
    FIRE    = 38,
    ICE     = 39,
    AIR     = 40,
    EARTH   = 41,
    THUNDER = 42,
    WATER   = 43,
    LIGHT   = 44,
    DARK    = 45,
}

local zones =
{
    {
        zoneId     = xi.zone.WEST_RONFAURE,
        zoneScript = 'West_Ronfaure',
        entries    =
        {
            { packetName = 'Fire Elemental',    groupId = ELEMENT.FIRE,    x = -338.0, y = -60.0, z = 258.0, rot = 96  },
            { packetName = 'Water Elemental',   groupId = ELEMENT.WATER,   x = -120.0, y = -60.0, z = 142.0, rot = 160 },
            { packetName = 'Air Elemental',     groupId = ELEMENT.AIR,     x = -45.0,  y = -60.0, z = 356.0, rot = 32  },
            { packetName = 'Earth Elemental',   groupId = ELEMENT.EARTH,   x = -274.0, y = -59.0, z = 20.0,  rot = 208 },
            { packetName = 'Ice Elemental',     groupId = ELEMENT.ICE,     x = -218.0, y = -60.0, z = 404.0, rot = 8   },
            { packetName = 'Thunder Elemental', groupId = ELEMENT.THUNDER, x = -390.0, y = -59.0, z = 104.0, rot = 128 },
        },
    },
    {
        zoneId     = xi.zone.NORTH_GUSTABERG,
        zoneScript = 'North_Gustaberg',
        entries    =
        {
            { packetName = 'Light Elemental',  groupId = ELEMENT.LIGHT,  x = 510.0, y =  0.0, z = 126.0, rot = 64  },
            { packetName = 'Dark Elemental',   groupId = ELEMENT.DARK,   x = 670.0, y =  0.0, z = 338.0, rot = 196 },
            { packetName = 'Fire Elemental',   groupId = ELEMENT.FIRE,   x = 380.0, y = -8.0, z = -10.0, rot = 24  },
            { packetName = 'Water Elemental',  groupId = ELEMENT.WATER,  x = 740.0, y = -7.0, z =  40.0, rot = 222 },
            { packetName = 'Air Elemental',    groupId = ELEMENT.AIR,    x = 540.0, y =  0.0, z = 420.0, rot = 144 },
        },
    },
    {
        zoneId     = xi.zone.EAST_SARUTABARUTA,
        zoneScript = 'East_Sarutabaruta',
        entries    =
        {
            { packetName = 'Earth Elemental',   groupId = ELEMENT.EARTH,   x = -318.0, y = -3.0, z = -225.0, rot = 48  },
            { packetName = 'Ice Elemental',     groupId = ELEMENT.ICE,     x =  -58.0, y = -3.0, z = -420.0, rot = 184 },
            { packetName = 'Thunder Elemental', groupId = ELEMENT.THUNDER, x = -420.0, y = -3.0, z = -520.0, rot = 110 },
            { packetName = 'Light Elemental',   groupId = ELEMENT.LIGHT,   x =  -15.0, y = -3.0, z = -190.0, rot = 12  },
            { packetName = 'Dark Elemental',    groupId = ELEMENT.DARK,    x = -260.0, y = -3.0, z = -640.0, rot = 236 },
        },
    },
}

local function spawnOne(zone, zoneId, entry)
    local level = math.random(MIN_LEVEL, MAX_LEVEL)
    local mob   = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        name                 = entry.packetName:gsub(' ', '_'),
        packetName           = entry.packetName,
        groupId              = entry.groupId,
        groupZoneId          = zoneId,
        minLevel             = level,
        maxLevel             = level,
        x                    = entry.x,
        y                    = entry.y,
        z                    = entry.z,
        rotation             = entry.rot,
        respawn              = RESPAWN_SECONDS,
        releaseIdOnDisappear = false,
    })

    if not mob then
        printf('[ixi20_starter_elementals] spawn failed zone=%u %s', zoneId, entry.packetName)
        return
    end

    mob:setSpawn(entry.x, entry.y, entry.z, entry.rot)
    mob:setRespawnTime(RESPAWN_SECONDS)
    mob:spawn()
end

local function spawnZone(zone, cfg)
    if not zone or not zone.insertDynamicEntity then
        return
    end

    for _, entry in ipairs(cfg.entries) do
        spawnOne(zone, cfg.zoneId, entry)
    end
end

for _, cfg in ipairs(zones) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', cfg.zoneScript), function(zone)
        super(zone)
        spawnZone(zone, cfg)
    end)
end
