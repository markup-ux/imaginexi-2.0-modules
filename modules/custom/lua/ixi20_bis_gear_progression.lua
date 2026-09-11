-----------------------------------
-- Imagine XI 2.0 helper (not a Module). Level-banded BiS progression.
-- Used by custom/lua/ixi20_bis.lua (!bis). Not auto-drop.
-- Reference lists from 75-era job guides: FFXIclopedia, BG-Wiki, GameFAQs.
-- Playstyle focus per role:
--   Casters: MP, skill, fastcast, job stats
--   Melee TP: Store TP, haste, acc, STR/DEX
--   Tanks: enmity, DEF/VIT, shield
--   Ranged: RACC/RATT, snapshot
--   SMN: MP + perpetuation (Carbuncle Mitts @20)
--   BST/PUP: pet stats + melee
--   BRD: CHR, singing/string
-----------------------------------
xi = xi or {}
xi.bis_gear_progression = xi.bis_gear_progression or {}

local I = xi.item

-- Item IDs from item_equipment.sql / item_weapon.sql (when xi.item lacks the constant).
local G =
{
    HERMITS_WAND         = 17413,
    CARBUNCLE_MITTS      = 14062,
    BLACK_TUNIC          = 12609,
    CEREMONIAL_DAGGER    = 16753,
    PILGRIMS_WAND        = 18394,
    WILLOW_WAND_P1       = 17138,
    HOLLY_STAFF          = 17089,
    PESTLE               = 18599,
    FREESWORDS_STAFF     = 17130,
    MOHBWA_SASH_P1       = 15906,
    FASTING_RING         = 15546,
    SILVER_HAIRPIN_P1    = 12531,
    HEKO_OBI_P1          = 13190,
    BRONZE_ZAGHNAL       = 16768,
    LEGIONNAIRES_AXE     = 16648,
    BRONZE_HARNESS       = 12576,
    BRASS_HARNESS        = 12577,
    LGN_HARNESS          = 12629,
    LGN_SUBLIGAR         = 12881,
    BONE_SUBLIGAR        = 12834,
    POLE_GRIP            = 19025,
    SWIFT_BELT           = 15457,
    VELOCIOUS_BELT       = 15899,
    RAJAS_RING           = 15543,
    BRUTAL_EARRING       = 14813,
    WARRIORS_BELT        = 13194,
    SEERS_CROWN          = 15163,
    SEERS_TUNIC          = 14424,
    YEW_WAND_P1          = 17140,
    HEALING_STAFF        = 17108,
    LIGHT_STAFF          = 17557,
    DARK_STAFF           = 17559,
    DESTROYERS           = 17509,
    FAITH_BAGHNAKHS      = 18360,
    SHINOBI_GATANA       = 16919,
    ANJU                 = 17771,
    SUPPANOMIMI          = 14739,
    POWER_BOW            = 17161,
    CROSSBOW             = 17217,
    WAR_HOOP             = 19203,
    TURBO_ANIMATOR       = 17858,
    KOENIG_SHIELD        = 12387,
    VALOR_CORONET        = 15078,
    ASSASSINS_BONNET     = 15077,
    DRACHEN_ARMET        = 12519,
    MIRAGE_KEFFIYEH      = 11465,
    GARRISON_SALLET      = 15147,
    GARRISON_TUNICA      = 13818,
    ANUS_TIARA           = 16097,
    PUFFIN_RING          = 11654,
    BIRD_WHISTLE         = 13072,
    FRIARS_ROPE          = 13211,
    KNOWLEDGE_EARRING    = 13375,
    BESIEGERS_MANTLE     = 11528,
    LIFE_BELT            = 13231,
    POTENT_BELT          = 15884,
    SOLDIERS_RING        = 13286,
    OPTICAL_EARRING      = 14803,
    RELAXING_EARRING     = 14792,
    HEALERS_CAP          = 13855,
    HEALERS_BLIAUT       = 12640,
    GOLIARD_CHAPEAU      = 16108,
    NOBLES_TUNIC         = 12605,
    BYAKKOS_HAIDATE      = 12818,
    FUMA_SUNE_ATE        = 15327,
    WALAHRA_TURBAN       = 15270,
    HAGUN                = 17829,
    SOBORO               = 17813,
    PERDU_BLADE          = 18425,
    YOICHINOYUMI         = 18348,
    MARTIAL_BHUJ         = 18221,
    JAMBIYA              = 18023,
    THUGS_JAMBIYA_P1     = 19106,
    BOMB_CORE            = 18139,
    SMART_GRENADE        = 19202,
    STAFF_STRAP          = 19023,
    LIGHT_GRIP           = 19037,
    NUMINOUS_SHIELD      = 12409,
    TRUMP_GUN            = 18702,
    CORSAIRS_TRICORNE    = 15266,
    ACAD_MORTARBOARD     = 27683,
    GEOMANCY_GALERO      = 27786,
    RUNEIST_BANDEAU      = 27787,
    EVOKERS_HORN         = 12520,
    PANTIN_TAJ           = 11471,
    HUNTERS_BERET        = 12518,
    SCOUTS_BERET         = 15082,
    CHORAL_ROUNDLET      = 13857,
    SAOTOME_KABUTO       = 15083,
    KOGA_HATSUBURI       = 15084,
    THICK_MUFFLERS       = 12684,
    CORAL_EARRING        = 13312,
    WARWOLF_BELT         = 15294,
    PEACOCK_AMULET       = 15515,
    ANCIENT_TORQUE       = 16275,
    TRIUMPH_EARRING      = 13408,
    FOWLING_EARRING      = 15979,
    WALKURE_MASK         = 15185,
    BARONE_COSCIALES     = 14317,
    TARASQUE_MITTS       = 14067,
    BHUJ                 = 16707,
    GAWAINS_AXE          = 18211,
    PERDU_VOULGE         = 18491,
    PERDU_SWORD          = 16602,
    PERDU_STAFF          = 18588,
    PERDU_BOW            = 18717,
    PERDU_HANGER         = 17741,
    PERDU_CROSSBOW       = 18718,
    TEMPLAR_MACE         = 18841,
    MUSE_TARIQAH         = 16175,
    AMEMET_MANTLE_P1     = 13646,
    CERBERUS_MANTLE      = 16212,
    FORAGERS_MANTLE      = 13690,
    AJARI_NECKLACE       = 13175,
    CHIVALROUS_CHAIN     = 15523,
    JUSTICE_TORQUE       = 15508,
    CLERICS_BELT         = 15872,
    HIERARCH_BELT        = 15295,
    MACE_BELT            = 15273,
    STAFF_BELT           = 15274,
    HEALERS_TORQUE       = 11990,
    HEALERS_MANTLE       = 13661,
    HEALERS_EARRING      = 13437,
    SORCERERS_RING       = 13289,
    EVOKERS_RING         = 14625,
    MERCENARYS_POLE      = 17103,
    SOLID_WAND           = 17141,
    HIGH_MANA_WAND       = 18403,
    BLESSED_HAMMER       = 17422,
    DOLPHIN_STAFF        = 17134,
    CHANTERS_STAFF       = 17133,
    HOLY_MACE            = 17041,
    BRONZE_MACE          = 17034,
    SCENTLESS_ARMLETS    = 12749,
    STURDY_SLACKS        = 15611,
    LIGHT_SOLEAS         = 13052,
    BOMB_RING            = 13506,
    SAINTLY_RING         = 13282,
    SAINTLY_RING_P1      = 13283,
    MIST_SILK_CAPE       = 13607,
    CAPE_P1              = 13605,
    SCALE_GORGET         = 13071,
    FEDERATION_EARRING   = 16041,
    PRIESTS_EARRING      = 15982,
    ANUS_DOUBLET         = 14559,
    ANUS_GAGES           = 14974,
    ANUS_BRAIS           = 15638,
    ANUS_GAITERS         = 15724,
    SEERS_MITTS          = 14856,
    SEERS_SLACKS         = 14325,
    SEERS_PUMPS          = 15313,
    HEALERS_MITTS         = 13963,
    HEALERS_DUCKBILLS    = 14091,
    YIGIT_SERAWEELS      = 15606,
    GOLIARD_TREWS        = 15649,
    GOLIARD_CLOGS        = 15735,
    NASHIRA_TURBAN       = 15241,
    NASHIRA_GAGES        = 14906,
    NASHIRA_SERAWEELS    = 15577,
    NASHIRA_CRACKOWS     = 15662,
    PRIESTS_ROBE         = 13729,
    MERCENARYS_POLE_STAFF = 17103,
    SHINOBIGATANA_P1     = 16920,
    WOODSMAN_RING        = 14675,
    MACE                 = 17035,
    KIRINS_POLE          = 17567,
    SEERS_CROWN_P1       = 15166,
    SEERS_TUNIC_P1       = 14427,
    SEERS_MITTS_P1       = 14859,
    SEERS_SLACKS_P1      = 14328,
    SEERS_PUMPS_P1       = 15316,
    BRONZE_SWORD         = 16535,
    BRONZE_POLEARM       = 16768,
    BRONZE_GS            = 16583,
    GUNROMARU            = 17820,
    NODACHI              = 16982,
    UCHIGATANA           = 16960,
    CRUEL_SPEAR          = 16863,
    BRASS_SPEAR          = 16834,
    BRONZE_SPEAR         = 16833,
    GIMLET_SPEAR         = 18117,
    TACHI                = 16966,
    WOODEN_KATANA        = 17830,
    LEATHER_BANDANA      = 12440,
    COPPER_HAIRPIN       = 12496,
    LEATHER_GLOVES       = 12696,
    BRONZE_MITTENS       = 12704,
    BRONZE_SUBLIGAR      = 12832,
    LEATHER_TROUSERS     = 12824,
    BRONZE_LEGGINGS      = 12960,
    LEATHER_HIGHBOOTS    = 12952,
    LEATHER_BELT         = 13192,
    MOLDAVITE_EARRING    = 14724,
    MORION_EARRING_P1    = 14721,
    UGGLALEPIH_PENDANT   = 13145,
    ELEMENTAL_TORQUE     = 13156,
    PHILOMATH_STOLE      = 13176,
    WINDURSTIAN_SCARF    = 13142,
    MORGANAS_CHOKER      = 16269,
    TAMAS_RING           = 15545,
    OMEGA_RING           = 15800,
    SNOW_RING            = 14640,
    DIAMOND_RING         = 13450,
    LOQUACIOUS_EARRING   = 14812,
    NOVIO_EARRING        = 14808,
    NOVIA_EARRING        = 14809,
    PHANTOM_EARRING      = 14727,
    ASTRAL_EARRING       = 14782,
    PENITENTS_ROPE       = 15292,
    SORCERERS_BELT       = 15874,
    RAINBOW_CAPE         = 13587,
    MERCIFUL_CAPE        = 15471,
    INTENSIFYING_CAPE    = 15492,
    IXION_CAPE           = 16242,
    MAHATMA_CAPE         = 13657,
    CHATOYANT_STAFF      = 18633,
    PHANTOM_TATHLUM      = 18140,
}

xi.bis_gear_progression.starterItemIds =
{
    [17104] = true, -- onion staff
    [17049] = true, -- maple wand
    [17088] = true, -- ash staff
    [12635] = true, -- tarutaru kaftan
    [12756] = true, -- tarutaru mitts
    [12886] = true, -- tarutaru braccae
    [13007] = true, -- tarutaru clomps
    [13496] = true, -- windurstian ring
    [14430] = true, -- federation aketon
    [12634] = true, -- hume vest
    [12633] = true, -- elvaan chainmail
    [12636] = true, -- mithra vest
    [12637] = true, -- galka dinga
    [12619] = true, -- onion harness
}

local function list(...)
    return { ... }
end

local function slots(def)
    return def
end

local function merge(base, override)
    local out = {}
    for slot, candidates in pairs(base) do
        out[slot] = candidates
    end
    if override then
        for slot, candidates in pairs(override) do
            out[slot] = candidates
        end
    end
    return out
end

local function tier(minLevel, slotLists)
    return { minLevel = minLevel, slots = slotLists }
end

-- Shared accessory pools
local earlyNeck  = list(G.SCALE_GORGET, G.BIRD_WHISTLE, G.CHIVALROUS_CHAIN)
local earlyWaist = list(G.LEATHER_BELT, G.WARRIORS_BELT, G.FRIARS_ROPE, G.LIFE_BELT)
local earlyEar   = list(G.KNOWLEDGE_EARRING, G.FEDERATION_EARRING, G.PRIESTS_EARRING, G.BRUTAL_EARRING)
local earlyRing  = list(G.PUFFIN_RING, G.SAINTLY_RING_P1, G.SAINTLY_RING, G.FASTING_RING)
local earlyBack  = list(G.BESIEGERS_MANTLE, G.CAPE_P1, G.MIST_SILK_CAPE)

local midNeck  = list(G.PEACOCK_AMULET, G.AJARI_NECKLACE, G.CHIVALROUS_CHAIN, G.HEALERS_TORQUE)
local midWaist = list(G.SWIFT_BELT, G.VELOCIOUS_BELT, G.WARRIORS_BELT, G.STAFF_BELT, G.FRIARS_ROPE, G.LIFE_BELT)
local midEar   = list(G.BRUTAL_EARRING, G.RELAXING_EARRING, G.OPTICAL_EARRING, G.HEALERS_EARRING)
local midRing  = list(G.WOODSMAN_RING, G.RAJAS_RING, G.SORCERERS_RING, G.PUFFIN_RING, G.FASTING_RING)
local midBack  = list(G.HEALERS_MANTLE, G.BESIEGERS_MANTLE)

local lateNeck  = list(G.AJARI_NECKLACE, G.JUSTICE_TORQUE, G.CHIVALROUS_CHAIN, G.ANCIENT_TORQUE)
local lateWaist = list(G.SWIFT_BELT, G.VELOCIOUS_BELT, G.CLERICS_BELT, G.HIERARCH_BELT, G.POTENT_BELT, G.LIFE_BELT)
local lateEar   = list(G.BRUTAL_EARRING, G.OPTICAL_EARRING, G.RELAXING_EARRING, G.TRIUMPH_EARRING)
local lateRing  = list(G.RAJAS_RING, G.SORCERERS_RING, G.WOODSMAN_RING, G.SOLDIERS_RING)
local lateBack  = list(G.AMEMET_MANTLE_P1, G.FORAGERS_MANTLE, G.CERBERUS_MANTLE)

local meleeAcc = { neck = earlyNeck, waist = earlyWaist, ear = earlyEar, ring = earlyRing, back = earlyBack }
local meleeAccMid = { neck = midNeck, waist = midWaist, ear = midEar, ring = midRing, back = midBack }
local meleeAccLate = { neck = lateNeck, waist = lateWaist, ear = lateEar, ring = lateRing, back = lateBack }

-- Melee TP jobs only (no healer/caster accessories on WAR/SAM/etc.).
local meleeTpAccMid =
{
    neck  = list(G.PEACOCK_AMULET, G.AJARI_NECKLACE, G.CHIVALROUS_CHAIN, G.JUSTICE_TORQUE),
    waist = list(G.SWIFT_BELT, G.VELOCIOUS_BELT, G.WARRIORS_BELT, G.POTENT_BELT, G.FRIARS_ROPE, G.LIFE_BELT),
    ear   = list(G.BRUTAL_EARRING, G.RELAXING_EARRING, G.OPTICAL_EARRING, G.TRIUMPH_EARRING),
    ring  = list(G.WOODSMAN_RING, G.RAJAS_RING, G.SOLDIERS_RING, G.PUFFIN_RING, G.FASTING_RING),
    back  = list(G.FORAGERS_MANTLE, G.BESIEGERS_MANTLE, G.AMEMET_MANTLE_P1),
}

-- Caster / healer accessories (WHM and jobs that inherit WHM lists).
-- MP, MND, magic skill, fastcast. No melee TP pieces (Rajas, Brutal, Swift Belt).
local casterAcc =
{
    neck  = list(G.WINDURSTIAN_SCARF, G.SCALE_GORGET, G.BIRD_WHISTLE),
    waist = list(G.FRIARS_ROPE, G.HEKO_OBI_P1, G.MOHBWA_SASH_P1, G.LEATHER_BELT),
    ear   = list(G.KNOWLEDGE_EARRING, G.PRIESTS_EARRING, G.FEDERATION_EARRING, G.RELAXING_EARRING),
    ring  = list(G.SAINTLY_RING_P1, G.SAINTLY_RING, G.FASTING_RING),
    back  = list(G.CAPE_P1, G.MIST_SILK_CAPE),
}

local casterAccMid =
{
    neck  = list(G.HEALERS_TORQUE, G.PHILOMATH_STOLE, G.WINDURSTIAN_SCARF),
    waist = list(G.FRIARS_ROPE, G.STAFF_BELT, G.MOHBWA_SASH_P1, G.HEKO_OBI_P1),
    ear   = list(G.MOLDAVITE_EARRING, G.MORION_EARRING_P1, G.HEALERS_EARRING, G.RELAXING_EARRING, G.KNOWLEDGE_EARRING),
    ring  = list(G.TAMAS_RING, G.SAINTLY_RING_P1, G.SORCERERS_RING, G.FASTING_RING),
    back  = list(G.HEALERS_MANTLE, G.RAINBOW_CAPE, G.CAPE_P1),
}

local casterAccLate =
{
    neck  = list(G.HEALERS_TORQUE, G.MORGANAS_CHOKER, G.PHILOMATH_STOLE, G.ELEMENTAL_TORQUE),
    waist = list(G.CLERICS_BELT, G.HIERARCH_BELT, G.PENITENTS_ROPE, G.FRIARS_ROPE),
    ear   = list(G.LOQUACIOUS_EARRING, G.NOVIA_EARRING, G.HEALERS_EARRING, G.RELAXING_EARRING),
    ring  = list(G.TAMAS_RING, G.OMEGA_RING, G.SAINTLY_RING_P1, G.SORCERERS_RING),
    back  = list(G.RAINBOW_CAPE, G.MERCIFUL_CAPE, G.HEALERS_MANTLE),
}

-- BLM nuke: INT, MAB, elemental skill, fastcast.
local blmAcc =
{
    neck  = list(G.WINDURSTIAN_SCARF, G.SCALE_GORGET),
    waist = list(G.HEKO_OBI_P1, G.MOHBWA_SASH_P1, G.FRIARS_ROPE),
    ear   = list(G.KNOWLEDGE_EARRING, G.FEDERATION_EARRING, G.RELAXING_EARRING),
    ring  = list(G.FASTING_RING, G.SAINTLY_RING_P1, G.SAINTLY_RING),
    back  = list(G.CAPE_P1, G.MIST_SILK_CAPE),
}

local blmAccMid =
{
    neck  = list(G.PHILOMATH_STOLE, G.WINDURSTIAN_SCARF, G.ELEMENTAL_TORQUE),
    waist = list(G.MOHBWA_SASH_P1, G.HEKO_OBI_P1, G.STAFF_BELT, G.FRIARS_ROPE),
    ear   = list(G.MOLDAVITE_EARRING, G.MORION_EARRING_P1, G.PHANTOM_EARRING, G.KNOWLEDGE_EARRING),
    ring  = list(G.TAMAS_RING, G.SORCERERS_RING, G.DIAMOND_RING, G.FASTING_RING),
    back  = list(G.INTENSIFYING_CAPE, G.CAPE_P1, G.MIST_SILK_CAPE),
}

local blmAccLate =
{
    neck  = list(G.ELEMENTAL_TORQUE, G.UGGLALEPIH_PENDANT, G.PHILOMATH_STOLE, G.MORGANAS_CHOKER),
    waist = list(G.PENITENTS_ROPE, G.SORCERERS_BELT, G.HIERARCH_BELT),
    ear   = list(G.LOQUACIOUS_EARRING, G.MOLDAVITE_EARRING, G.NOVIO_EARRING, G.PHANTOM_EARRING, G.MORION_EARRING_P1),
    ring  = list(G.TAMAS_RING, G.OMEGA_RING, G.SORCERERS_RING, G.SNOW_RING, G.DIAMOND_RING),
    back  = list(G.MERCIFUL_CAPE, G.INTENSIFYING_CAPE, G.RAINBOW_CAPE, G.IXION_CAPE, G.MAHATMA_CAPE),
}

local brdAccLate =
{
    neck  = list(G.BIRD_WHISTLE, G.HEALERS_TORQUE),
    waist = list(G.SWIFT_BELT, G.VELOCIOUS_BELT, G.MOHBWA_SASH_P1, G.FRIARS_ROPE, G.HEKO_OBI_P1),
    ear   = list(I.MUSICAL_EARRING, I.LOQUACIOUS_EARRING, I.SINGING_EARRING, I.MINSTRELS_EARRING, G.KNOWLEDGE_EARRING),
    ring  = list(I.MINSTRELS_RING, G.TAMAS_RING, G.RAJAS_RING, G.FASTING_RING),
    back  = list(G.MIST_SILK_CAPE, G.RAINBOW_CAPE, G.HEALERS_MANTLE, G.CAPE_P1),
}

local rangedAccLate =
{
    neck  = list(G.PEACOCK_AMULET, G.AJARI_NECKLACE),
    waist = list(G.SWIFT_BELT, G.VELOCIOUS_BELT, G.POTENT_BELT),
    ear   = list(G.FOWLING_EARRING, G.TRIUMPH_EARRING, G.BRUTAL_EARRING),
    ring  = list(G.WOODSMAN_RING, G.RAJAS_RING, G.SOLDIERS_RING),
    back  = list(G.FORAGERS_MANTLE, G.AMEMET_MANTLE_P1),
}

local function withAcc(slotDef, acc)
    return merge(slotDef, {
        [xi.slot.NECK]  = acc.neck,
        [xi.slot.WAIST] = acc.waist,
        [xi.slot.EAR1]  = acc.ear,
        [xi.slot.RING1] = acc.ring,
        [xi.slot.BACK]  = acc.back,
    })
end

-----------------------------------
-- WHM: cure potency, MND, -enmity
-----------------------------------
local whm1_20 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.WILLOW_WAND_P1, G.PILGRIMS_WAND, G.HOLLY_STAFF),
    [xi.slot.HEAD]  = list(G.ANUS_TIARA, G.GARRISON_SALLET),
    [xi.slot.BODY]  = list(G.ANUS_DOUBLET, G.PRIESTS_ROBE, G.GARRISON_TUNICA),
    [xi.slot.HANDS] = list(G.ANUS_GAGES, I.GARRISON_GLOVES),
    [xi.slot.LEGS]  = list(G.ANUS_BRAIS, I.GARRISON_HOSE),
    [xi.slot.FEET]  = list(G.ANUS_GAITERS, I.GARRISON_BOOTS),
}, casterAcc)

local whm21_35 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.YEW_WAND_P1, G.SOLID_WAND, G.DOLPHIN_STAFF),
    [xi.slot.HEAD]  = list(G.SEERS_CROWN_P1, G.SEERS_CROWN, G.ANUS_TIARA),
    [xi.slot.BODY]  = list(G.SEERS_TUNIC_P1, G.SEERS_TUNIC),
    [xi.slot.HANDS] = list(G.SEERS_MITTS_P1, G.SEERS_MITTS),
    [xi.slot.LEGS]  = list(G.SEERS_SLACKS_P1, G.SEERS_SLACKS),
    [xi.slot.FEET]  = list(G.SEERS_PUMPS_P1, G.SEERS_PUMPS),
}, casterAccMid)

local whm36_50 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.HIGH_MANA_WAND, G.BLESSED_HAMMER, G.HEALING_STAFF),
    [xi.slot.HEAD]  = list(G.HEALERS_CAP, G.SEERS_CROWN_P1),
    [xi.slot.BODY]  = list(G.HEALERS_BLIAUT, G.SEERS_TUNIC_P1),
    [xi.slot.HANDS] = list(G.HEALERS_MITTS, G.SEERS_MITTS_P1),
    [xi.slot.LEGS]  = list(I.HEALERS_PANTALOONS, G.SEERS_SLACKS_P1),
    [xi.slot.FEET]  = list(G.HEALERS_DUCKBILLS, G.SEERS_PUMPS_P1),
}, casterAccMid)

local whm51_67 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.LIGHT_STAFF, G.TEMPLAR_MACE, G.HEALING_STAFF),
    [xi.slot.SUB]   = list(G.STAFF_STRAP, G.MUSE_TARIQAH),
    [xi.slot.HEAD]  = list(I.HEALERS_CAP_P1, G.HEALERS_CAP),
    [xi.slot.BODY]  = list(G.NOBLES_TUNIC, G.HEALERS_BLIAUT, I.GOLIARD_SAIO),
    [xi.slot.HANDS] = list(I.HEALERS_MITTS_P1, G.HEALERS_MITTS),
    [xi.slot.LEGS]  = list(G.YIGIT_SERAWEELS, G.GOLIARD_TREWS),
    [xi.slot.FEET]  = list(G.GOLIARD_CLOGS, G.HEALERS_DUCKBILLS),
}, casterAccLate)

local whm68_75 = withAcc(slots
{
    [xi.slot.MAIN]  = list(I.MJOLLNIR_75, G.LIGHT_STAFF, G.TEMPLAR_MACE),
    [xi.slot.SUB]   = list(G.MUSE_TARIQAH, G.NUMINOUS_SHIELD, G.STAFF_STRAP),
    [xi.slot.HEAD]  = list(I.GOLIARD_CHAPEAU, I.HEALERS_CAP_P1, G.NASHIRA_TURBAN),
    [xi.slot.BODY]  = list(G.NOBLES_TUNIC, I.GOLIARD_SAIO, I.CLERICS_BLIAUT_P1),
    [xi.slot.HANDS] = list(I.HEALERS_MITTS_P1, I.CLERICS_MITTS, I.GOLIARD_CUFFS),
    [xi.slot.LEGS]  = list(G.GOLIARD_TREWS, G.NASHIRA_SERAWEELS, G.YIGIT_SERAWEELS),
    [xi.slot.FEET]  = list(G.GOLIARD_CLOGS, I.CLERICS_DUCKBILLS),
}, casterAccLate)

local whmTiers = { tier(1, whm1_20), tier(21, whm21_35), tier(36, whm36_50), tier(51, whm51_67), tier(68, whm68_75) }

-----------------------------------
-- BLM: INT, MAB, fastcast, element staves
-----------------------------------
local blm1_20 = withAcc(merge(whm1_20, slots
{
    [xi.slot.MAIN] = list(G.HOLLY_STAFF, G.WILLOW_WAND_P1, G.PILGRIMS_WAND),
}), blmAcc)

local blm21_35 = withAcc(merge(whm21_35, slots
{
    [xi.slot.MAIN] = list(G.DOLPHIN_STAFF, G.CHANTERS_STAFF, G.YEW_WAND_P1, G.SOLID_WAND),
}), blmAccMid)

local blm36_50 = withAcc(merge(whm36_50, slots
{
    [xi.slot.MAIN] = list(G.DOLPHIN_STAFF, G.HIGH_MANA_WAND, G.CHANTERS_STAFF),
}), blmAccMid)

local blm51_67 = withAcc(merge(whm51_67, slots
{
    [xi.slot.MAIN]  = list(G.DARK_STAFF, I.CAPRICORN_STAFF, G.LIGHT_STAFF),
    [xi.slot.SUB]   = list(G.STAFF_STRAP, G.LIGHT_GRIP),
    [xi.slot.HEAD]  = list(I.WIZARDS_PETASOS, I.SORCERERS_PETASOS, I.HEALERS_CAP_P1),
    [xi.slot.BODY]  = list(I.SORCERERS_COAT, I.WIZARDS_COAT, G.NOBLES_TUNIC),
    [xi.slot.AMMO]  = list(G.PHANTOM_TATHLUM),
}), blmAccLate)

local blm68_75 = withAcc(merge(whm68_75, slots
{
    [xi.slot.MAIN]  = list(G.CHATOYANT_STAFF, G.KIRINS_POLE, I.CAPRICORN_STAFF, G.DARK_STAFF),
    [xi.slot.SUB]   = list(G.STAFF_STRAP, G.LIGHT_GRIP),
    [xi.slot.HEAD]  = list(I.SORCERERS_PETASOS_P1, I.WIZARDS_PETASOS_P1),
    [xi.slot.BODY]  = list(I.SORCERERS_COAT_P1, I.WIZARDS_COAT_P1),
    [xi.slot.HANDS] = list(I.SORCERERS_GLOVES_P1, I.WIZARDS_GLOVES_P1),
    [xi.slot.LEGS]  = list(I.SORCERERS_TONBAN_P1, I.WIZARDS_TONBAN_P1),
    [xi.slot.FEET]  = list(I.SORCERERS_SABOTS_P1, I.WIZARDS_SABOTS_P1),
    [xi.slot.AMMO]  = list(G.PHANTOM_TATHLUM),
}), blmAccLate)

local blmTiers = { tier(1, blm1_20), tier(21, blm21_35), tier(36, blm36_50), tier(51, blm51_67), tier(68, blm68_75) }

-----------------------------------
-- SMN: MP stack, perpetuation, Hermit's Wand, Carbuncle Mitts @20
-----------------------------------
local smn1_20 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.HERMITS_WAND, G.CEREMONIAL_DAGGER, G.PILGRIMS_WAND, G.PESTLE, G.FREESWORDS_STAFF),
    [xi.slot.HEAD]  = list(G.SILVER_HAIRPIN_P1, G.ANUS_TIARA, G.GARRISON_SALLET),
    [xi.slot.BODY]  = list(G.BLACK_TUNIC, G.ANUS_DOUBLET, G.GARRISON_TUNICA),
    [xi.slot.HANDS] = list(G.CARBUNCLE_MITTS, G.SCENTLESS_ARMLETS, G.ANUS_GAGES),
    [xi.slot.LEGS]  = list(G.STURDY_SLACKS, G.ANUS_BRAIS, I.GARRISON_HOSE),
    [xi.slot.FEET]  = list(G.LIGHT_SOLEAS, G.ANUS_GAITERS, I.GARRISON_BOOTS),
    [xi.slot.WAIST] = list(G.HEKO_OBI_P1, G.MOHBWA_SASH_P1, G.FRIARS_ROPE),
}, casterAcc)

local smn21_35 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.HERMITS_WAND, G.HIGH_MANA_WAND, G.SOLID_WAND, G.MERCENARYS_POLE),
    [xi.slot.HEAD]  = list(G.SILVER_HAIRPIN_P1, G.SEERS_CROWN_P1, G.EVOKERS_HORN),
    [xi.slot.BODY]  = list(G.BLACK_TUNIC, G.SEERS_TUNIC_P1, G.SEERS_TUNIC),
    [xi.slot.HANDS] = list(G.CARBUNCLE_MITTS, G.SEERS_MITTS_P1, G.TARASQUE_MITTS),
    [xi.slot.LEGS]  = list(G.BARONE_COSCIALES, G.SEERS_SLACKS_P1),
    [xi.slot.FEET]  = list(G.LIGHT_SOLEAS, G.SEERS_PUMPS_P1),
    [xi.slot.WAIST] = list(G.MOHBWA_SASH_P1, G.HEKO_OBI_P1, G.STAFF_BELT),
}, casterAccMid)

local smn36_50 = withAcc(slots
{
    [xi.slot.MAIN]  = list(G.HEALING_STAFF, G.DARK_STAFF, G.HIGH_MANA_WAND),
    [xi.slot.HEAD]  = list(G.EVOKERS_HORN, G.HEALERS_CAP, G.GOLIARD_CHAPEAU),
    [xi.slot.BODY]  = list(I.EVOKERS_DOUBLET, G.HEALERS_BLIAUT, I.GOLIARD_SAIO),
    [xi.slot.HANDS] = list(G.CARBUNCLE_MITTS, I.EVOKERS_BRACERS, G.HEALERS_MITTS),
    [xi.slot.LEGS]  = list(I.EVOKERS_SPATS, G.GOLIARD_TREWS),
    [xi.slot.FEET]  = list(I.EVOKERS_PIGACHES, G.GOLIARD_CLOGS),
}, merge(casterAccMid, { ring = list(G.EVOKERS_RING, G.TAMAS_RING, G.FASTING_RING) }))

local smn51_67 = merge(whm51_67, slots
{
    [xi.slot.MAIN] = list(I.NIRVANA_75, G.DARK_STAFF, G.KIRINS_POLE, G.LIGHT_STAFF),
    [xi.slot.HEAD] = list(G.EVOKERS_HORN, I.GOLIARD_CHAPEAU),
    [xi.slot.BODY] = list(I.EVOKERS_DOUBLET, G.NOBLES_TUNIC),
    [xi.slot.HANDS] = list(I.EVOKERS_BRACERS, G.CARBUNCLE_MITTS),
    [xi.slot.LEGS] = list(I.EVOKERS_SPATS, G.GOLIARD_TREWS),
    [xi.slot.FEET] = list(I.EVOKERS_PIGACHES, G.GOLIARD_CLOGS),
    [xi.slot.RING1] = list(G.EVOKERS_RING, G.TAMAS_RING, G.SORCERERS_RING),
})

local smn68_75 = merge(whm68_75, slots
{
    [xi.slot.MAIN]  = list(I.NIRVANA_75, G.KIRINS_POLE, G.CHATOYANT_STAFF, G.DARK_STAFF),
    [xi.slot.HEAD]  = list(I.EVOKERS_HORN_P1, I.GOLIARD_CHAPEAU),
    [xi.slot.BODY]  = list(I.EVOKERS_DOUBLET, G.NOBLES_TUNIC),
    [xi.slot.HANDS] = list(I.EVOKERS_BRACERS, G.CARBUNCLE_MITTS),
    [xi.slot.LEGS]  = list(I.EVOKERS_SPATS, G.GOLIARD_TREWS),
    [xi.slot.FEET]  = list(I.EVOKERS_PIGACHES, G.GOLIARD_CLOGS),
    [xi.slot.RING1] = list(G.EVOKERS_RING, G.TAMAS_RING, G.SORCERERS_RING),
})

local smnTiers = { tier(1, smn1_20), tier(21, smn21_35), tier(36, smn36_50), tier(51, smn51_67), tier(68, smn68_75) }

-----------------------------------
-- Melee TP jobs (WAR/MNK/THF/DRK/SAM/NIN/DRG/DNC/BLU): acc, haste, Store TP
-----------------------------------
local function meleeTier1(mainList)
    return withAcc(slots
    {
        [xi.slot.MAIN]  = mainList,
        [xi.slot.HEAD]  = list(G.LEATHER_BANDANA, G.COPPER_HAIRPIN, G.GARRISON_SALLET, I.GARRISON_SALLET),
        [xi.slot.BODY]  = list(G.BRONZE_HARNESS, G.LGN_HARNESS, G.BRASS_HARNESS, G.GARRISON_TUNICA),
        [xi.slot.HANDS] = list(G.LEATHER_GLOVES, G.BRONZE_MITTENS, I.GARRISON_GLOVES, G.TARASQUE_MITTS),
        [xi.slot.LEGS]  = list(G.BRONZE_SUBLIGAR, G.LEATHER_TROUSERS, G.LGN_SUBLIGAR, G.BONE_SUBLIGAR, I.GARRISON_HOSE, G.BARONE_COSCIALES),
        [xi.slot.FEET]  = list(G.LEATHER_HIGHBOOTS, G.BRONZE_LEGGINGS, I.GARRISON_BOOTS, G.LIGHT_SOLEAS),
    }, meleeAcc)
end

local function meleeTierMid(mainList, headList)
    return withAcc(slots
    {
        [xi.slot.MAIN]  = mainList,
        [xi.slot.HEAD]  = headList or list(G.WALKURE_MASK, G.GARRISON_SALLET, G.WALAHRA_TURBAN),
        -- Dusk / Tarasque / Barone are 68–72; list them last so 21–50 actually equips.
        [xi.slot.BODY]  = list(G.BRASS_HARNESS, G.LGN_HARNESS, G.GARRISON_TUNICA, 12555, I.ASKAR_KORAZIN),
        [xi.slot.HANDS] = list(I.GARRISON_GLOVES, G.LEATHER_GLOVES, G.THICK_MUFFLERS, G.TARASQUE_MITTS),
        [xi.slot.LEGS]  = list(G.LGN_SUBLIGAR, G.BONE_SUBLIGAR, I.GARRISON_HOSE, G.BARONE_COSCIALES, 12879),
        [xi.slot.FEET]  = list(I.GARRISON_BOOTS, G.LIGHT_SOLEAS, 12957),
    }, meleeTpAccMid)
end

local function meleeTierLate(mainList, headList, bodyList, jobHands, subList)
    local def =
    {
        [xi.slot.MAIN]  = mainList,
        [xi.slot.HEAD]  = headList or list(G.WALAHRA_TURBAN, 13915), -- optical hat
        [xi.slot.BODY]  = bodyList or list(12555, 12562), -- haubergeon, kirin's osode
        [xi.slot.HANDS] = jobHands or list(12701, 14876), -- dusk gloves, hachiman kote
        [xi.slot.LEGS]  = list(G.BYAKKOS_HAIDATE, 12879),
        [xi.slot.FEET]  = list(G.FUMA_SUNE_ATE, 15330), -- hachiman sune-ate
    }
    if subList ~= false then
        def[xi.slot.SUB] = subList or list(G.POLE_GRIP, I.POLE_GRIP, I.ROSE_STRAP)
    end

    return withAcc(slots(def), meleeTpAccMid)
end

local warTiers =
{
    tier(1,  meleeTier1(list(G.LEGIONNAIRES_AXE, G.BRONZE_ZAGHNAL, G.GAWAINS_AXE))),
    tier(21, meleeTierMid(list(G.GAWAINS_AXE, G.BHUJ), list(I.FIGHTERS_MASK, G.WALKURE_MASK))),
    tier(36, meleeTierMid(list(G.BHUJ, G.GAWAINS_AXE, G.PERDU_VOULGE), list(I.FIGHTERS_MASK_P1, I.FIGHTERS_MASK))),
    tier(51, meleeTierLate(list(G.PERDU_VOULGE, G.BHUJ, I.MARTIAL_BHUJ), list(I.FIGHTERS_MASK_P1, G.WALAHRA_TURBAN), list(I.FIGHTERS_LORICA_P1, 12555), list(I.FIGHTERS_MUFFLERS_P1, 12701))),
    tier(68, meleeTierLate(list(I.BRAVURA_75, I.PERDU_VOULGE, I.MARTIAL_BHUJ), list(I.FIGHTERS_MASK_P1, G.WALAHRA_TURBAN), list(I.FIGHTERS_LORICA_P1, 12555), list(I.FIGHTERS_MUFFLERS_P1, I.OCHIUDOS_KOTE))),
}

local mnkTiers =
{
    tier(1,  meleeTier1(list(G.DESTROYERS, G.FAITH_BAGHNAKHS, G.BRONZE_MACE))),
    tier(21, meleeTierMid(list(G.DESTROYERS, G.FAITH_BAGHNAKHS), list(I.TEMPLE_CROWN, G.WALKURE_MASK))),
    tier(36, meleeTierMid(list(I.DESTROYERS, I.FAITH_BAGHNAKHS), list(I.TEMPLE_CROWN_P1, I.MELEE_CROWN))),
    tier(51, meleeTierLate(list(I.DESTROYERS, I.FAITH_BAGHNAKHS, I.KOENIGS_KNUCKLES), list(I.MELEE_CROWN_P1, I.TEMPLE_CROWN_P1), list(I.MELEE_CYCLAS_P1, I.TEMPLE_CYCLAS_P1), list(I.MELEE_GLOVES_P1, I.TEMPLE_GLOVES_P1), false)),
    tier(68, meleeTierLate(list(I.SPHARAI_75, I.DESTROYERS, I.FAITH_BAGHNAKHS), list(I.MELEE_CROWN_P1, G.WALAHRA_TURBAN), list(I.MELEE_CYCLAS_P1, I.TEMPLE_CYCLAS_P1), list(I.MELEE_GLOVES_P1, 12701), false)),
}

local samTiers =
{
    tier(1,  meleeTier1(list(G.WOODEN_KATANA, G.TACHI, G.UCHIGATANA, G.NODACHI, G.GUNROMARU))),
    tier(21, meleeTierMid(list(G.SOBORO, G.NODACHI, G.UCHIGATANA, G.HAGUN), list(I.SAOTOME_KABUTO, G.WALKURE_MASK))),
    tier(36, meleeTierMid(list(G.HAGUN, G.SOBORO, G.NODACHI), list(I.SAOTOME_KABUTO, I.SAOTOME_KABUTO_P1))),
    tier(51, merge(meleeTierLate(list(G.HAGUN, G.SOBORO, I.AMANOMURAKUMO_75), list(I.SAOTOME_KABUTO_P1, G.WALAHRA_TURBAN), list(I.SAOTOME_DOMARU_P1, 12555), list(I.SAOTOME_KOTE_P1, 12701)), {
        [xi.slot.RANGED] = list(G.SMART_GRENADE, G.BOMB_CORE),
    })),
    tier(68, merge(meleeTierLate(list(I.AMANOMURAKUMO_75, I.HAGUN, G.SOBORO), list(I.SAOTOME_KABUTO_P1, G.WALAHRA_TURBAN), list(I.SAOTOME_DOMARU_P1, 12555), list(I.SAOTOME_KOTE_P1, 12701)), {
        [xi.slot.RANGED] = list(I.SMART_GRENADE, I.BOMB_CORE),
    })),
}

local ninTiers =
{
    tier(1,  merge(meleeTier1(list(G.SHINOBI_GATANA, I.BRONZE_MACE)), { [xi.slot.SUB] = list(G.SHINOBI_GATANA) })),
    tier(21, merge(meleeTierMid(list(G.SHINOBI_GATANA), list(G.KOGA_HATSUBURI)), { [xi.slot.SUB] = list(G.ANJU, G.SUPPANOMIMI) })),
    tier(36, merge(meleeTierMid(list(G.SHINOBI_GATANA, I.KIKOKU_75), list(G.KOGA_HATSUBURI, I.KOGA_HATSUBURI)), {
        [xi.slot.SUB] = list(G.ANJU, G.SUPPANOMIMI, I.ANJU),
        [xi.slot.BODY] = list(I.KOGA_CHAINMAIL, 12555),
        [xi.slot.HANDS] = list(I.KOGA_TEKKO, 12701),
        [xi.slot.LEGS] = list(I.KOGA_HAKAMA, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.KOGA_KYAHAN, G.FUMA_SUNE_ATE),
    })),
    tier(51, merge(meleeTierLate(list(I.KIKOKU_75, I.PERDU_BLADE), list(I.KOGA_HATSUBURI_P1, G.KOGA_HATSUBURI), list(I.KOGA_CHAINMAIL_P1, I.USUKANE_HARAMAKI), list(I.KOGA_TEKKO_P1, I.USUKANE_GOTE), list(I.ANJU, I.ZUSHIO)), {
        [xi.slot.LEGS] = list(I.KOGA_HAKAMA_P1, I.USUKANE_HIZAYOROI),
        [xi.slot.FEET] = list(I.KOGA_KYAHAN_P1, I.USUKANE_SUNE_ATE),
    })),
    tier(68, merge(meleeTierLate(list(I.KIKOKU_75, I.PERDU_BLADE), list(I.KOGA_HATSUBURI_P1, I.USUKANE_SOMEN), list(I.KOGA_CHAINMAIL_P1, I.USUKANE_HARAMAKI), list(I.KOGA_TEKKO_P1, I.USUKANE_GOTE), list(I.ANJU, I.ZUSHIO)), {
        [xi.slot.LEGS] = list(I.KOGA_HAKAMA_P1, I.USUKANE_HIZAYOROI),
        [xi.slot.FEET] = list(I.KOGA_KYAHAN_P1, I.USUKANE_SUNE_ATE),
    })),
}

local drkTiers =
{
    tier(1,  meleeTier1(list(G.BRONZE_ZAGHNAL, I.SCYTHE, G.BRONZE_GS))),
    tier(21, meleeTierMid(list(I.SCYTHE, G.BRONZE_GS, G.GAWAINS_AXE), list(I.CHAOS_BURGEONET, G.WALKURE_MASK))),
    tier(36, meleeTierMid(list(I.APOCALYPSE_75, I.SCYTHE, I.RAGNAROK_75), list(I.CHAOS_BURGEONET_P1, I.CHAOS_BURGEONET))),
    tier(51, meleeTierLate(list(I.APOCALYPSE_75, I.RAGNAROK_75, G.PERDU_VOULGE), list(I.CHAOS_BURGEONET_P1, G.WALAHRA_TURBAN), list(I.CHAOS_CUIRASS_P1, 12555), list(I.CHAOS_GAUNTLETS_P1, 12701))),
    tier(68, meleeTierLate(list(I.APOCALYPSE_75, I.RAGNAROK_75, I.PERDU_VOULGE), list(I.CHAOS_BURGEONET_P1, G.WALAHRA_TURBAN), list(I.CHAOS_CUIRASS_P1, 12555), list(I.CHAOS_GAUNTLETS_P1, 12701))),
}

local thfTiers =
{
    tier(1,  merge(meleeTier1(list(G.JAMBIYA, I.DAGGER, G.CEREMONIAL_DAGGER)), { [xi.slot.SUB] = list(G.SUPPANOMIMI) })),
    tier(21, merge(meleeTierMid(list(G.JAMBIYA, I.MANDAU_75), list(G.ASSASSINS_BONNET)), { [xi.slot.SUB] = list(G.SUPPANOMIMI, G.ANJU) })),
    tier(36, merge(meleeTierMid(list(I.MANDAU_75, G.JAMBIYA), list(G.ASSASSINS_BONNET, I.ASSASSINS_BONNET)), {
        [xi.slot.BODY] = list(I.ASSASSINS_VEST, 12555),
        [xi.slot.SUB] = list(G.SUPPANOMIMI, G.ANJU),
    })),
    tier(51, merge(meleeTierLate(list(I.MANDAU_75, G.JAMBIYA), list(I.ASSASSINS_BONNET_P1, I.ASSASSINS_BONNET), list(I.ASSASSINS_VEST_P1, I.ASSASSINS_VEST), list(I.ASSASSINS_ARMLETS_P1, 12701), list(I.SUPPANOMIMI, I.ANJU)), {
        [xi.slot.LEGS] = list(I.ASSASSINS_CULOTTES_P1, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.ASSASSINS_POULAINES_P1, G.FUMA_SUNE_ATE),
    })),
    tier(68, merge(meleeTierLate(list(I.MANDAU_75, G.JAMBIYA), list(I.ASSASSINS_BONNET_P1), list(I.ASSASSINS_VEST_P1, 12555), list(I.ASSASSINS_ARMLETS_P1, 12701), list(I.SUPPANOMIMI, I.ANJU)), {
        [xi.slot.LEGS] = list(I.ASSASSINS_CULOTTES_P1, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.ASSASSINS_POULAINES_P1, G.FUMA_SUNE_ATE),
    })),
}

local drgTiers =
{
    tier(1,  meleeTier1(list(G.CRUEL_SPEAR, G.BRASS_SPEAR, G.BRONZE_SPEAR, G.GIMLET_SPEAR))),
    tier(21, meleeTierMid(list(I.PEREGRINE, G.CRUEL_SPEAR, G.BRASS_SPEAR), list(G.DRACHEN_ARMET))),
    tier(36, merge(meleeTierMid(list(I.ROYAL_KNIGHT_ARMY_LANCE, I.PEREGRINE, I.KAMAYARI), list(G.DRACHEN_ARMET, I.DRACHEN_ARMET)), {
        [xi.slot.BODY] = list(I.DRACHEN_MAIL, 12555),
        [xi.slot.HANDS] = list(I.DRACHEN_FINGER_GAUNTLETS, 12701),
        [xi.slot.LEGS] = list(I.DRACHEN_BRAIS, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.DRACHEN_GREAVES, G.FUMA_SUNE_ATE),
    })),
    tier(51, merge(meleeTierLate(list(I.WYVERN_SPEAR, I.DREIZACK, I.SCHILTRON_SPEAR), list(I.DRACHEN_ARMET_P1, I.WYRM_ARMET), list(I.DRACHEN_MAIL_P1, I.WYRM_MAIL_P1), list(I.DRACHEN_FINGER_GAUNTLETS_P1, I.WYRM_FINGER_GAUNTLETS_P1)), {
        [xi.slot.LEGS] = list(I.DRACHEN_BRAIS_P1, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.DRACHEN_GREAVES_P1, G.FUMA_SUNE_ATE),
    })),
    tier(68, merge(meleeTierLate(list(I.GUNGNIR_75, I.GAE_ASSAIL, I.WYVERN_SPEAR, I.DREIZACK), list(I.WYRM_ARMET_P1, I.DRACHEN_ARMET_P1), list(I.WYRM_MAIL_P1, I.DRACHEN_MAIL_P1), list(I.WYRM_FINGER_GAUNTLETS_P1, 12701)), {
        [xi.slot.LEGS] = list(I.WYRM_BRAIS_P1, I.DRACHEN_BRAIS_P1),
        [xi.slot.FEET] = list(I.WYRM_GREAVES_P1, G.FUMA_SUNE_ATE),
    })),
}

local dncTiers =
{
    -- Mandau 75 / Jambiya 73 / Etoile 60 are not wearable in the 50 band.
    -- Sub is a second dagger. Anju is a katana; Suppanomimi is an earring.
    tier(1,  merge(meleeTier1(list(G.THUGS_JAMBIYA_P1, I.DAGGER, G.CEREMONIAL_DAGGER)), {
        [xi.slot.SUB] = list(G.CEREMONIAL_DAGGER, I.DAGGER),
        [xi.slot.RANGED] = list(G.WAR_HOOP),
    })),
    tier(21, merge(meleeTierMid(list(I.MARAUDERS_KNIFE, G.THUGS_JAMBIYA_P1, I.ACID_KNIFE), list(G.WALKURE_MASK, G.GARRISON_SALLET)), {
        [xi.slot.SUB] = list(G.THUGS_JAMBIYA_P1, I.ACID_KNIFE, G.CEREMONIAL_DAGGER),
        [xi.slot.RANGED] = list(G.WAR_HOOP),
    })),
    tier(36, merge(meleeTierMid(list(I.MARAUDERS_KNIFE, I.KIDNEY_DAGGER, I.ACID_KNIFE), list(I.DANCERS_TIARA_M_P1, I.DANCERS_TIARA_F_P1, I.DANCERS_TIARA_M, I.DANCERS_TIARA_F)), {
        [xi.slot.BODY] = list(I.DANCERS_CASAQUE_M_P1, I.DANCERS_CASAQUE_F_P1, I.DANCERS_CASAQUE_M, I.DANCERS_CASAQUE_F),
        [xi.slot.HANDS] = list(I.DANCERS_BANGLES_M_P1, I.DANCERS_BANGLES_F_P1, I.DANCERS_BANGLES_M, I.DANCERS_BANGLES_F),
        [xi.slot.LEGS] = list(I.DANCERS_TIGHTS_M_P1, I.DANCERS_TIGHTS_F_P1, I.DANCERS_TIGHTS_M, I.DANCERS_TIGHTS_F),
        [xi.slot.FEET] = list(I.DANCERS_TOE_SHOES_M_P1, I.DANCERS_TOE_SHOES_F_P1, I.DANCERS_TOE_SHOES_M, I.DANCERS_TOE_SHOES_F),
        [xi.slot.SUB] = list(G.THUGS_JAMBIYA_P1, I.ACID_KNIFE, G.CEREMONIAL_DAGGER),
        [xi.slot.RANGED] = list(G.WAR_HOOP),
    })),
    tier(51, merge(meleeTierLate(list(I.KIDNEY_DAGGER, I.MARAUDERS_KNIFE, I.MANDAU_75, G.JAMBIYA), list(I.ETOILE_TIARA_P1, I.DANCERS_TIARA_M_P1, I.DANCERS_TIARA_F_P1), list(I.ETOILE_CASAQUE_P1, I.DANCERS_CASAQUE_M_P1, I.DANCERS_CASAQUE_F_P1), list(I.ETOILE_BANGLES_P1, I.DANCERS_BANGLES_M_P1, I.DANCERS_BANGLES_F_P1), list(I.MARAUDERS_KNIFE, G.THUGS_JAMBIYA_P1, I.ACID_KNIFE)), {
        [xi.slot.LEGS] = list(I.ETOILE_TIGHTS_P1, I.DANCERS_TIGHTS_M_P1, I.DANCERS_TIGHTS_F_P1),
        [xi.slot.FEET] = list(I.ETOILE_TOE_SHOES_P1, I.DANCERS_TOE_SHOES_M_P1, I.DANCERS_TOE_SHOES_F_P1),
        [xi.slot.RANGED] = list(G.WAR_HOOP),
    })),
    tier(68, merge(meleeTierLate(list(I.MANDAU_75, G.JAMBIYA, I.KIDNEY_DAGGER), list(I.ETOILE_TIARA_P1, I.DANCERS_TIARA_M_P1), list(I.ETOILE_CASAQUE_P1, I.DANCERS_CASAQUE_M_P1), list(I.ETOILE_BANGLES_P1, I.DANCERS_BANGLES_M_P1), list(I.KIDNEY_DAGGER, I.MARAUDERS_KNIFE, G.THUGS_JAMBIYA_P1)), {
        [xi.slot.LEGS] = list(I.ETOILE_TIGHTS_P1, G.BYAKKOS_HAIDATE, I.DANCERS_TIGHTS_M_P1),
        [xi.slot.FEET] = list(I.ETOILE_TOE_SHOES_P1, G.FUMA_SUNE_ATE, I.DANCERS_TOE_SHOES_M_P1),
        [xi.slot.RANGED] = list(G.WAR_HOOP),
    })),
}

local bluMeleeTiers =
{
    tier(1,  merge(meleeTier1(list(G.BRONZE_SWORD, I.JOYEUSE, G.TEMPLAR_MACE)), { [xi.slot.SUB] = list(G.NUMINOUS_SHIELD) })),
    tier(21, merge(meleeTierMid(list(I.JOYEUSE, G.PERDU_HANGER), list(G.MIRAGE_KEFFIYEH)), { [xi.slot.SUB] = list(G.NUMINOUS_SHIELD) })),
    tier(36, merge(meleeTierMid(list(I.JOYEUSE, G.PERDU_HANGER, I.EXCALIBUR_75), list(G.MIRAGE_KEFFIYEH, I.MIRAGE_KEFFIYEH)), {
        [xi.slot.BODY] = list(I.MIRAGE_JUBBAH, 12555),
        [xi.slot.SUB] = list(G.NUMINOUS_SHIELD, I.JOYEUSE),
    })),
    tier(51, merge(meleeTierLate(list(I.EXCALIBUR_75, I.JOYEUSE, G.PERDU_HANGER), list(I.MIRAGE_KEFFIYEH_P1, I.MIRAGE_KEFFIYEH), list(I.MIRAGE_JUBBAH_P1, I.MIRAGE_JUBBAH), list(I.MIRAGE_BAZUBANDS_P1, 12701), list(G.NUMINOUS_SHIELD, I.JOYEUSE)), {
        [xi.slot.LEGS] = list(I.MIRAGE_SHALWAR_P1, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.MIRAGE_CHARUQS_P1, G.FUMA_SUNE_ATE),
    })),
    tier(68, merge(meleeTierLate(list(I.EXCALIBUR_75, I.JOYEUSE, G.PERDU_HANGER), list(I.MIRAGE_KEFFIYEH_P1), list(I.MIRAGE_JUBBAH_P1), list(I.MIRAGE_BAZUBANDS_P1), list(G.NUMINOUS_SHIELD, I.JOYEUSE)), {
        [xi.slot.LEGS] = list(I.MIRAGE_SHALWAR_P1, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET] = list(I.MIRAGE_CHARUQS_P1, G.FUMA_SUNE_ATE),
    })),
}

local bluMageTiers =
{
    tier(1,  merge(whm1_20, { [xi.slot.MAIN] = list(G.WILLOW_WAND_P1, G.PILGRIMS_WAND, G.HOLLY_STAFF) })),
    tier(21, merge(whm21_35, { [xi.slot.MAIN] = list(G.YEW_WAND_P1, G.SOLID_WAND, G.DOLPHIN_STAFF) })),
    tier(36, merge(whm36_50, {
        [xi.slot.MAIN] = list(G.HIGH_MANA_WAND, G.DOLPHIN_STAFF, G.CHATOYANT_STAFF),
        [xi.slot.HEAD] = list(G.MIRAGE_KEFFIYEH, G.HEALERS_CAP),
        [xi.slot.BODY] = list(I.MIRAGE_JUBBAH, G.HEALERS_BLIAUT),
    })),
    tier(51, merge(whm51_67, {
        [xi.slot.MAIN] = list(G.CHATOYANT_STAFF, G.LIGHT_STAFF, G.DARK_STAFF),
        [xi.slot.HEAD] = list(I.MIRAGE_KEFFIYEH, I.HEALERS_CAP_P1),
        [xi.slot.BODY] = list(I.MIRAGE_JUBBAH, G.NOBLES_TUNIC),
    })),
    tier(68, merge(whm68_75, {
        [xi.slot.MAIN] = list(G.CHATOYANT_STAFF, I.CLAUSTRUM_75, G.DARK_STAFF),
        [xi.slot.HEAD] = list(I.MIRAGE_KEFFIYEH_P1, I.MIRAGE_KEFFIYEH),
        [xi.slot.BODY] = list(I.MIRAGE_JUBBAH_P1, I.MIRAGE_JUBBAH),
        [xi.slot.SUB] = list(G.STAFF_STRAP, G.MUSE_TARIQAH),
    })),
}

local bluTiers = bluMeleeTiers

-----------------------------------
-- Tank (PLD/RUN): enmity, DEF, shield
-----------------------------------
local function tankTier1()
    return withAcc(slots
    {
        [xi.slot.MAIN]  = list(G.HOLY_MACE, G.BRONZE_MACE, G.BRONZE_SWORD),
        [xi.slot.SUB]   = list(G.KOENIG_SHIELD, G.NUMINOUS_SHIELD),
        [xi.slot.HEAD]  = list(G.GARRISON_SALLET, G.VALOR_CORONET),
        [xi.slot.BODY]  = list(G.BRASS_HARNESS, G.LGN_HARNESS),
        [xi.slot.HANDS] = list(G.TARASQUE_MITTS, I.GARRISON_GLOVES),
        [xi.slot.LEGS]  = list(G.LGN_SUBLIGAR, G.BONE_SUBLIGAR, I.GARRISON_HOSE, G.BARONE_COSCIALES),
        [xi.slot.FEET]  = list(I.GARRISON_BOOTS),
    }, merge(meleeAcc, { ring = list(G.SOLDIERS_RING, G.PUFFIN_RING) }))
end

local function tankTierLate(headList)
    return withAcc(slots
    {
        [xi.slot.MAIN]  = list(I.EXCALIBUR_75, I.JOYEUSE, I.BURTGANG_75),
        [xi.slot.SUB]   = list(I.AEGIS_75, G.KOENIG_SHIELD, I.RELIC_SHIELD, G.NUMINOUS_SHIELD),
        [xi.slot.HEAD]  = headList or list(I.VALOR_CORONET_P1, G.VALOR_CORONET, G.WALAHRA_TURBAN),
        [xi.slot.BODY]  = list(I.VALOR_SURCOAT_P1, I.KOENIG_CUIRASS, 12555),
        [xi.slot.HANDS] = list(I.VALOR_GAUNTLETS_P1, I.KOENIG_HANDSCHUHS, 12701),
        [xi.slot.LEGS]  = list(I.VALOR_BREECHES_P1, I.KOENIG_DIECHLINGS, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET]  = list(I.VALOR_LEGGINGS_P1, I.KOENIG_SCHUHS, G.FUMA_SUNE_ATE),
    }, merge(meleeAccLate, { ring = list(G.SOLDIERS_RING, G.RAJAS_RING) }))
end

local pldTiers =
{
    tier(1,  tankTier1()),
    tier(21, tankTier1()),
    tier(36, tankTierLate(list(G.VALOR_CORONET, I.GENBUS_KABUTO))),
    tier(51, tankTierLate(list(I.VALOR_CORONET_P1, I.GENBUS_KABUTO))),
    tier(68, tankTierLate(list(I.VALOR_CORONET_P1, I.GENBUS_KABUTO, G.WALAHRA_TURBAN))),
}

local runTiers =
{
    tier(1,  tankTier1()),
    tier(21, tankTier1()),
    tier(36, tankTierLate(list(I.RUNEIST_BANDEAU, I.FUTHARK_BANDEAU, G.VALOR_CORONET))),
    tier(51, tankTierLate(list(I.RUNEIST_BANDEAU_P1, I.FUTHARK_BANDEAU_P1, I.RUNEIST_BANDEAU))),
    tier(68, merge(tankTierLate(list(I.FUTHARK_BANDEAU_P1, I.RUNEIST_BANDEAU_P1, G.WALAHRA_TURBAN)), {
        [xi.slot.BODY]  = list(I.FUTHARK_COAT_P1, I.RUNEIST_COAT_P1, I.KOENIG_CUIRASS),
        [xi.slot.HANDS] = list(I.FUTHARK_MITONS_P1, I.RUNEIST_MITONS_P1, I.KOENIG_HANDSCHUHS),
        [xi.slot.LEGS]  = list(I.FUTHARK_TROUSERS_P1, I.RUNEIST_TROUSERS_P1),
        [xi.slot.FEET]  = list(I.FUTHARK_BOOTS_P1, I.RUNEIST_BOTTES_P1),
        [xi.slot.MAIN]  = list(I.EXCALIBUR_75, I.JOYEUSE, I.BURTGANG_75),
        [xi.slot.SUB]   = list(G.KOENIG_SHIELD, I.AEGIS_75, G.NUMINOUS_SHIELD),
    })),
}

-----------------------------------
-- RDM: enfeeble / fastcast, sword + shield
-----------------------------------
local rdmTiers =
{
    tier(1,  merge(whm1_20, { [xi.slot.MAIN] = list(G.WILLOW_WAND_P1, G.HOLY_MACE, I.JOYEUSE), [xi.slot.SUB] = list(G.NUMINOUS_SHIELD) })),
    tier(21, merge(whm21_35, { [xi.slot.MAIN] = list(G.YEW_WAND_P1, I.JOYEUSE, G.SOLID_WAND), [xi.slot.SUB] = list(G.NUMINOUS_SHIELD) })),
    tier(36, merge(whm36_50, {
        [xi.slot.MAIN] = list(I.JOYEUSE, G.PERDU_HANGER, I.EXCALIBUR_75),
        [xi.slot.SUB]  = list(G.NUMINOUS_SHIELD, G.MUSE_TARIQAH),
        [xi.slot.HEAD] = list(I.WARLOCKS_CHAPEAU, G.NASHIRA_TURBAN),
        [xi.slot.BODY] = list(I.WARLOCKS_TABARD, I.NASHIRA_MANTEEL),
    })),
    tier(51, merge(whm51_67, {
        [xi.slot.MAIN] = list(I.EXCALIBUR_75, I.JOYEUSE, G.PERDU_HANGER),
        [xi.slot.SUB]  = list(G.NUMINOUS_SHIELD, G.MUSE_TARIQAH),
        [xi.slot.HEAD] = list(I.WARLOCKS_CHAPEAU_P1, G.NASHIRA_TURBAN),
        [xi.slot.BODY] = list(I.WARLOCKS_TABARD_P1, I.WARLOCKS_TABARD),
        [xi.slot.HANDS] = list(I.WARLOCKS_GLOVES_P1, G.NASHIRA_GAGES),
        [xi.slot.LEGS] = list(I.WARLOCKS_TIGHTS_P1, G.NASHIRA_SERAWEELS),
        [xi.slot.FEET] = list(I.WARLOCKS_BOOTS_P1, G.NASHIRA_CRACKOWS),
        [xi.slot.EAR1] = list(I.LOQUACIOUS_EARRING, I.WARLOCKS_EARRING, G.MOLDAVITE_EARRING),
        [xi.slot.BACK] = list(I.WARLOCKS_MANTLE, G.RAINBOW_CAPE),
    })),
    tier(68, merge(whm68_75, {
        [xi.slot.MAIN] = list(I.EXCALIBUR_75, I.JOYEUSE, G.PERDU_HANGER),
        [xi.slot.SUB]  = list(G.NUMINOUS_SHIELD, G.MUSE_TARIQAH),
        [xi.slot.HEAD] = list(I.WARLOCKS_CHAPEAU_P1, G.NASHIRA_TURBAN),
        [xi.slot.BODY] = list(I.WARLOCKS_TABARD_P1, I.NASHIRA_MANTEEL),
        [xi.slot.HANDS] = list(I.WARLOCKS_GLOVES_P1, G.NASHIRA_GAGES),
        [xi.slot.LEGS] = list(I.WARLOCKS_TIGHTS_P1, G.NASHIRA_SERAWEELS),
        [xi.slot.FEET] = list(I.WARLOCKS_BOOTS_P1, G.NASHIRA_CRACKOWS),
        [xi.slot.EAR1] = list(I.LOQUACIOUS_EARRING, I.WARLOCKS_EARRING, G.MOLDAVITE_EARRING),
        [xi.slot.BACK] = list(I.WARLOCKS_MANTLE, G.RAINBOW_CAPE, G.MERCIFUL_CAPE),
    })),
}

-----------------------------------
-- BST: pet acc/atk, CHR, Reward; axe main
-----------------------------------
local bstTiers =
{
    tier(1,  meleeTier1(list(G.LEGIONNAIRES_AXE, G.GAWAINS_AXE))),
    tier(21, meleeTierMid(list(G.GAWAINS_AXE, I.GUTTLER_75), list(G.HUNTERS_BERET, I.BEAST_HELM))),
    tier(36, merge(meleeTierMid(list(G.GAWAINS_AXE, I.GUTTLER_75), list(I.HUNTERS_BERET, I.BEAST_HELM)), {
        [xi.slot.HEAD] = list(I.HUNTERS_BERET, I.BEAST_HELM),
        [xi.slot.BODY] = list(I.HUNTERS_JERKIN, I.BEAST_JACKCOAT),
        [xi.slot.MAIN] = list(G.GAWAINS_AXE, I.GUTTLER_75),
    })),
    tier(51, merge(meleeTierLate(list(I.GUTTLER_75, G.GAWAINS_AXE), list(I.BEAST_HELM_P1, I.HUNTERS_BERET_P1), list(I.BEAST_JACKCOAT_P1, I.HUNTERS_JERKIN_P1), list(I.BEAST_GLOVES_P1, I.HUNTERS_BRACERS_P1), false), {
        [xi.slot.LEGS] = list(I.BEAST_TROUSERS_P1, I.HUNTERS_BRACCAE_P1),
        [xi.slot.FEET] = list(I.BEAST_GAITERS_P1, I.HUNTERS_SOCKS_P1),
    })),
    tier(68, merge(meleeTierLate(list(I.GUTTLER_75, G.GAWAINS_AXE), list(I.BEAST_HELM_P1, I.ASKAR_ZUCCHETTO), list(I.BEAST_JACKCOAT_P1, I.ASKAR_KORAZIN), list(I.BEAST_GLOVES_P1, I.ASKAR_MANOPOLAS), false), {
        [xi.slot.LEGS] = list(I.BEAST_TROUSERS_P1, I.HUNTERS_BRACCAE_P1),
        [xi.slot.FEET] = list(I.BEAST_GAITERS_P1, I.HUNTERS_SOCKS_P1),
    })),
}

-----------------------------------
-- BRD: CHR, singing/string, haste songs; dagger main
-----------------------------------
local brdTiers =
{
    tier(1,  withAcc(merge(whm1_20, {
        [xi.slot.MAIN] = list(I.MINSTRELS_DAGGER, G.JAMBIYA, G.CEREMONIAL_DAGGER),
        [xi.slot.SUB]  = list(G.SUPPANOMIMI),
    }), brdAccLate)),
    tier(21, withAcc(merge(whm21_35, {
        [xi.slot.MAIN] = list(I.MINSTRELS_DAGGER, G.JAMBIYA),
        [xi.slot.HEAD] = list(G.CHORAL_ROUNDLET, I.CHORAL_ROUNDLET),
        [xi.slot.RANGED] = list(I.GJALLARHORN_75),
    }), brdAccLate)),
    tier(36, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.MINSTRELS_DAGGER, I.MANDAU_75, G.JAMBIYA),
        [xi.slot.SUB]    = list(G.SUPPANOMIMI),
        [xi.slot.RANGED] = list(I.GJALLARHORN_75),
        [xi.slot.HEAD]   = list(I.CHORAL_ROUNDLET, I.CHORAL_ROUNDLET_P1),
        [xi.slot.BODY]   = list(I.CHORAL_JUSTAUCORPS, G.NASHIRA_TURBAN),
        [xi.slot.HANDS]  = list(I.CHORAL_CUFFS, G.NASHIRA_GAGES),
        [xi.slot.LEGS]   = list(I.CHORAL_CANNIONS, G.NASHIRA_SERAWEELS),
        [xi.slot.FEET]   = list(I.CHORAL_SLIPPERS, G.NASHIRA_CRACKOWS),
    }, brdAccLate)),
    tier(51, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.MINSTRELS_DAGGER, I.MANDAU_75),
        [xi.slot.SUB]    = list(G.SUPPANOMIMI),
        [xi.slot.RANGED] = list(I.GJALLARHORN_75),
        [xi.slot.HEAD]   = list(I.CHORAL_ROUNDLET_P1, G.NASHIRA_TURBAN),
        [xi.slot.BODY]   = list(I.CHORAL_JUSTAUCORPS_P1, I.CHORAL_JUSTAUCORPS),
        [xi.slot.HANDS]  = list(I.CHORAL_CUFFS_P1, G.NASHIRA_GAGES),
        [xi.slot.LEGS]   = list(I.CHORAL_CANNIONS_P1, G.NASHIRA_SERAWEELS),
        [xi.slot.FEET]   = list(I.CHORAL_SLIPPERS_P1, G.NASHIRA_CRACKOWS),
    }, brdAccLate)),
    tier(68, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.MINSTRELS_DAGGER, I.MANDAU_75),
        [xi.slot.SUB]    = list(G.SUPPANOMIMI),
        [xi.slot.RANGED] = list(I.GJALLARHORN_75),
        [xi.slot.HEAD]   = list(I.CHORAL_ROUNDLET_P1, G.NASHIRA_TURBAN),
        [xi.slot.BODY]   = list(I.CHORAL_JUSTAUCORPS_P1),
        [xi.slot.HANDS]  = list(I.CHORAL_CUFFS_P1, G.NASHIRA_GAGES),
        [xi.slot.LEGS]   = list(I.CHORAL_CANNIONS_P1, G.NASHIRA_SERAWEELS),
        [xi.slot.FEET]   = list(I.CHORAL_SLIPPERS_P1, G.NASHIRA_CRACKOWS),
        [xi.slot.WAIST]  = list(G.SWIFT_BELT, G.VELOCIOUS_BELT),
    }, brdAccLate)),
}

-----------------------------------
-- RNG / COR: RACC, RATT, snapshot
-----------------------------------
local function rangedTier1(rangedList)
    return withAcc(slots
    {
        [xi.slot.MAIN]   = list(G.JAMBIYA, G.CEREMONIAL_DAGGER),
        [xi.slot.RANGED] = rangedList,
        [xi.slot.HEAD]   = list(G.GARRISON_SALLET, G.SCOUTS_BERET),
        [xi.slot.BODY]   = list(G.GARRISON_TUNICA, G.LGN_HARNESS),
        [xi.slot.HANDS]  = list(I.GARRISON_GLOVES, G.TARASQUE_MITTS),
        [xi.slot.LEGS]   = list(G.LGN_SUBLIGAR, G.BONE_SUBLIGAR, I.GARRISON_HOSE, G.BARONE_COSCIALES),
        [xi.slot.FEET]   = list(I.GARRISON_BOOTS),
    }, merge(meleeAcc, { ear = list(G.FOWLING_EARRING, G.TRIUMPH_EARRING, G.BRUTAL_EARRING) }))
end

local rngTiers =
{
    tier(1,  rangedTier1(list(G.POWER_BOW, G.CROSSBOW))),
    tier(21, merge(rangedTier1(list(G.POWER_BOW, G.CROSSBOW)), { [xi.slot.AMMO] = list(I.YOICHIS_ARROW) })),
    tier(36, withAcc(slots
    {
        [xi.slot.MAIN]   = list(G.JAMBIYA, G.PERDU_HANGER),
        [xi.slot.RANGED] = list(I.YOICHINOYUMI_75, G.PERDU_BOW),
        [xi.slot.AMMO]   = list(I.YOICHIS_ARROW),
        [xi.slot.HEAD]   = list(I.SCOUTS_BERET, G.SCOUTS_BERET),
        [xi.slot.BODY]   = list(I.SCOUTS_JERKIN, 12555),
        [xi.slot.HANDS]  = list(I.SCOUTS_BRACERS, 12701),
        [xi.slot.LEGS]   = list(I.SCOUTS_BRACCAE, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET]   = list(I.SCOUTS_SOCKS, G.FUMA_SUNE_ATE),
    }, rangedAccLate)),
    tier(51, withAcc(slots
    {
        [xi.slot.MAIN]   = list(G.JAMBIYA, G.PERDU_HANGER),
        [xi.slot.RANGED] = list(I.YOICHINOYUMI_75, I.ANNIHILATOR_75, I.PERDU_BOW),
        [xi.slot.AMMO]   = list(I.YOICHIS_ARROW),
        [xi.slot.HEAD]   = list(I.SKADIS_VISOR, I.SCOUTS_BERET_P1),
        [xi.slot.BODY]   = list(I.SKADIS_CUIRIE, I.SCOUTS_JERKIN_P1),
        [xi.slot.HANDS]  = list(I.SKADIS_BAZUBANDS, I.SCOUTS_BRACERS_P1),
        [xi.slot.LEGS]   = list(I.SKADIS_CHAUSSES, I.SCOUTS_BRACCAE_P1),
        [xi.slot.FEET]   = list(I.SKADIS_JAMBEAUX, I.SCOUTS_SOCKS_P1),
    }, rangedAccLate)),
    tier(68, withAcc(slots
    {
        [xi.slot.MAIN]   = list(G.JAMBIYA, G.PERDU_HANGER),
        [xi.slot.RANGED] = list(I.YOICHINOYUMI_75, I.ANNIHILATOR_75, I.PERDU_BOW),
        [xi.slot.AMMO]   = list(I.YOICHIS_ARROW),
        [xi.slot.HEAD]   = list(I.SKADIS_VISOR, I.SCOUTS_BERET_P1),
        [xi.slot.BODY]   = list(I.SKADIS_CUIRIE, I.SCOUTS_JERKIN_P1),
        [xi.slot.HANDS]  = list(I.SKADIS_BAZUBANDS, I.SCOUTS_BRACERS_P1),
        [xi.slot.LEGS]   = list(I.SKADIS_CHAUSSES, I.SCOUTS_BRACCAE_P1),
        [xi.slot.FEET]   = list(I.SKADIS_JAMBEAUX, I.SCOUTS_SOCKS_P1),
    }, rangedAccLate)),
}

local corTiers =
{
    tier(1,  rangedTier1(list(G.CROSSBOW, G.TRUMP_GUN))),
    tier(21, merge(rangedTier1(list(G.TRUMP_GUN, G.CROSSBOW)), { [xi.slot.RANGED] = list(G.TRUMP_GUN) })),
    tier(36, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.JOYEUSE, G.PERDU_HANGER, G.JAMBIYA),
        [xi.slot.RANGED] = list(G.TRUMP_GUN, G.PERDU_CROSSBOW),
        [xi.slot.HEAD]   = list(G.CORSAIRS_TRICORNE, I.CORSAIRS_TRICORNE),
        [xi.slot.BODY]   = list(I.CORSAIRS_FRAC, 12555),
        [xi.slot.HANDS]  = list(I.CORSAIRS_GANTS, 12701),
        [xi.slot.LEGS]   = list(G.BYAKKOS_HAIDATE, I.SCOUTS_BRACCAE),
        [xi.slot.FEET]   = list(I.CORSAIRS_BOTTES, G.FUMA_SUNE_ATE),
    }, rangedAccLate)),
    tier(51, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.JOYEUSE, G.PERDU_HANGER),
        [xi.slot.RANGED] = list(I.TRUMP_GUN, I.PERDU_CROSSBOW),
        [xi.slot.HEAD]   = list(I.CORSAIRS_TRICORNE_P1, I.CORSAIRS_TRICORNE),
        [xi.slot.BODY]   = list(I.CORSAIRS_FRAC_P1, I.CORSAIRS_FRAC),
        [xi.slot.HANDS]  = list(I.CORSAIRS_GANTS_P1, I.CORSAIRS_GANTS),
        [xi.slot.FEET]   = list(I.CORSAIRS_BOTTES_P1, I.CORSAIRS_BOTTES),
    }, rangedAccLate)),
    tier(68, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.JOYEUSE, G.PERDU_HANGER),
        [xi.slot.RANGED] = list(I.TRUMP_GUN, I.PERDU_CROSSBOW),
        [xi.slot.HEAD]   = list(I.CORSAIRS_TRICORNE_P1, G.WALAHRA_TURBAN),
        [xi.slot.BODY]   = list(I.CORSAIRS_FRAC_P1, I.CORSAIRS_FRAC),
        [xi.slot.HANDS]  = list(I.CORSAIRS_GANTS_P1, 12701),
        [xi.slot.FEET]   = list(I.CORSAIRS_BOTTES_P1, G.FUMA_SUNE_ATE),
    }, rangedAccLate)),
}

-----------------------------------
-- PUP: automaton, H2H, pet stats
-----------------------------------
local pupTiers =
{
    tier(1,  withAcc(slots
    {
        [xi.slot.MAIN]   = list(G.DESTROYERS, G.FAITH_BAGHNAKHS, G.BRONZE_MACE),
        [xi.slot.RANGED] = list(G.TURBO_ANIMATOR, G.WAR_HOOP),
        [xi.slot.HEAD]   = list(G.PANTIN_TAJ, I.PANTIN_TAJ),
        [xi.slot.BODY]   = list(I.PANTIN_TOBE, G.GARRISON_TUNICA),
        [xi.slot.HANDS]  = list(I.PANTIN_DASTANAS, G.TARASQUE_MITTS),
        [xi.slot.LEGS]   = list(I.PANTIN_CHURIDARS, G.BARONE_COSCIALES),
        [xi.slot.FEET]   = list(I.PANTIN_BABOUCHES, G.LIGHT_SOLEAS),
    }, meleeAcc)),
    tier(21, withAcc(slots
    {
        [xi.slot.MAIN]   = list(G.DESTROYERS, G.FAITH_BAGHNAKHS),
        [xi.slot.RANGED] = list(G.TURBO_ANIMATOR, G.WAR_HOOP),
        [xi.slot.HEAD]   = list(I.PANTIN_TAJ, G.PANTIN_TAJ),
        [xi.slot.BODY]   = list(I.PANTIN_TOBE, 12555),
        [xi.slot.HANDS]  = list(I.PANTIN_DASTANAS, 12701),
        [xi.slot.LEGS]   = list(I.PANTIN_CHURIDARS, G.BARONE_COSCIALES),
        [xi.slot.FEET]   = list(I.PANTIN_BABOUCHES, G.LIGHT_SOLEAS),
    }, meleeTpAccMid)),
    tier(36, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.DESTROYERS, I.FAITH_BAGHNAKHS),
        [xi.slot.RANGED] = list(I.TURBO_ANIMATOR, G.WAR_HOOP),
        [xi.slot.HEAD]   = list(I.PANTIN_TAJ, I.PANTIN_TAJ_P1),
        [xi.slot.BODY]   = list(I.PANTIN_TOBE, I.PANTIN_TOBE_P1),
        [xi.slot.HANDS]  = list(I.PANTIN_DASTANAS, 12701),
        [xi.slot.LEGS]   = list(I.PANTIN_CHURIDARS, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET]   = list(I.PANTIN_BABOUCHES, G.FUMA_SUNE_ATE),
    }, meleeTpAccMid)),
    tier(51, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.DESTROYERS, I.KOENIGS_KNUCKLES),
        [xi.slot.RANGED] = list(I.TURBO_ANIMATOR, I.WAR_HOOP),
        [xi.slot.HEAD]   = list(I.PANTIN_TAJ_P1, I.PANTIN_TAJ),
        [xi.slot.BODY]   = list(I.PANTIN_TOBE_P1, I.PANTIN_TOBE),
        [xi.slot.HANDS]  = list(I.PANTIN_DASTANAS_P1, I.PANTIN_DASTANAS),
        [xi.slot.LEGS]   = list(I.PANTIN_CHURIDARS_P1, I.PANTIN_CHURIDARS),
        [xi.slot.FEET]   = list(I.PANTIN_BABOUCHES_P1, I.PANTIN_BABOUCHES),
    }, meleeTpAccMid)),
    tier(68, withAcc(slots
    {
        [xi.slot.MAIN]   = list(I.DESTROYERS, I.SPHARAI_75, I.KOENIGS_KNUCKLES),
        [xi.slot.RANGED] = list(I.TURBO_ANIMATOR, I.WAR_HOOP),
        [xi.slot.HEAD]   = list(I.PANTIN_TAJ_P1, G.WALAHRA_TURBAN),
        [xi.slot.BODY]   = list(I.PANTIN_TOBE_P1, I.PANTIN_TOBE),
        [xi.slot.HANDS]  = list(I.PANTIN_DASTANAS_P1, 12701),
        [xi.slot.LEGS]   = list(I.PANTIN_CHURIDARS_P1, G.BYAKKOS_HAIDATE),
        [xi.slot.FEET]   = list(I.PANTIN_BABOUCHES_P1, G.FUMA_SUNE_ATE),
    }, meleeTpAccMid)),
}

-----------------------------------
-- SCH / GEO: scholar caster + geomancer skill
-----------------------------------
local schTiers =
{
    tier(1,  merge(whm1_20, { [xi.slot.MAIN] = list(G.HOLLY_STAFF, G.WILLOW_WAND_P1) })),
    tier(21, whm21_35),
    tier(36, merge(whm36_50, {
        [xi.slot.HEAD] = list(G.ACAD_MORTARBOARD, I.SCHOLARS_MORTARBOARD, G.HEALERS_CAP),
        [xi.slot.BODY] = list(I.SCHOLARS_GOWN, I.ARGUTE_GOWN),
    })),
    tier(51, merge(whm51_67, {
        [xi.slot.MAIN]  = list(I.TUPSIMATI_75, G.DARK_STAFF, G.LIGHT_STAFF),
        [xi.slot.SUB]   = list(G.STAFF_STRAP, G.LIGHT_GRIP),
        [xi.slot.HEAD]  = list(I.ARGUTE_MORTARBOARD_P1, I.SCHOLARS_MORTARBOARD),
        [xi.slot.BODY]  = list(I.ARGUTE_GOWN_P1, I.SCHOLARS_GOWN),
        [xi.slot.HANDS] = list(I.ARGUTE_BRACERS_P1, I.SCHOLARS_BRACERS_P1),
        [xi.slot.LEGS]  = list(I.ARGUTE_PANTS_P1, G.GOLIARD_TREWS),
        [xi.slot.FEET]  = list(I.ARGUTE_LOAFERS_P1, I.SCHOLARS_LOAFERS_P1),
    })),
    tier(68, merge(whm68_75, {
        [xi.slot.MAIN]  = list(I.TUPSIMATI_75, I.CLAUSTRUM_75, G.CHATOYANT_STAFF),
        [xi.slot.SUB]   = list(G.STAFF_STRAP, G.LIGHT_GRIP),
        [xi.slot.HEAD]  = list(I.ARGUTE_MORTARBOARD_P1, I.SCHOLARS_MORTARBOARD),
        [xi.slot.BODY]  = list(I.ARGUTE_GOWN_P1, I.SCHOLARS_GOWN),
        [xi.slot.HANDS] = list(I.ARGUTE_BRACERS_P1, I.SCHOLARS_BRACERS_P1),
        [xi.slot.LEGS]  = list(I.ARGUTE_PANTS_P1, G.GOLIARD_TREWS),
        [xi.slot.FEET]  = list(I.ARGUTE_LOAFERS_P1, G.GOLIARD_CLOGS),
    })),
}

local geoTiers =
{
    tier(1,  merge(whm1_20, { [xi.slot.MAIN] = list(G.HOLLY_STAFF, G.WILLOW_WAND_P1) })),
    tier(21, whm21_35),
    tier(36, merge(whm36_50, {
        [xi.slot.HEAD] = list(G.GEOMANCY_GALERO, I.BAGUA_GALERO, G.GOLIARD_CHAPEAU),
        [xi.slot.BODY] = list(I.GEOMANCY_TUNIC, I.GOLIARD_SAIO),
    })),
    tier(51, merge(whm51_67, {
        [xi.slot.MAIN]  = list(G.DARK_STAFF, I.CLAUSTRUM_75, G.CHATOYANT_STAFF),
        [xi.slot.SUB]   = list(G.STAFF_STRAP, G.LIGHT_GRIP),
        [xi.slot.HEAD]  = list(I.GEOMANCY_GALERO_P1, I.BAGUA_GALERO_P1, G.GEOMANCY_GALERO),
        [xi.slot.BODY]  = list(I.GEOMANCY_TUNIC_P1, I.BAGUA_TUNIC_P1, I.GOLIARD_SAIO),
        [xi.slot.HANDS] = list(I.GEOMANCY_MITAINES_P1, I.BAGUA_MITAINES_P1),
        [xi.slot.LEGS]  = list(I.GEOMANCY_PANTS_P1, I.BAGUA_PANTS_P1),
        [xi.slot.FEET]  = list(I.GEOMANCY_SANDALS_P1, I.BAGUA_SANDALS_P1),
    })),
    tier(68, merge(whm68_75, {
        [xi.slot.MAIN]  = list(I.CLAUSTRUM_75, G.CHATOYANT_STAFF, G.DARK_STAFF),
        [xi.slot.SUB]   = list(G.STAFF_STRAP, G.LIGHT_GRIP),
        [xi.slot.HEAD]  = list(I.BAGUA_GALERO_P1, I.GEOMANCY_GALERO_P1, G.GEOMANCY_GALERO),
        [xi.slot.BODY]  = list(I.BAGUA_TUNIC_P1, I.GEOMANCY_TUNIC_P1, I.GOLIARD_SAIO),
        [xi.slot.HANDS] = list(I.BAGUA_MITAINES_P1, I.GEOMANCY_MITAINES_P1),
        [xi.slot.LEGS]  = list(I.BAGUA_PANTS_P1, I.GEOMANCY_PANTS_P1),
        [xi.slot.FEET]  = list(I.BAGUA_SANDALS_P1, I.GEOMANCY_SANDALS_P1),
    })),
}

xi.bis_gear_progression.byJob =
{
    [xi.job.WAR]  = warTiers,
    [xi.job.MNK]  = mnkTiers,
    [xi.job.WHM]  = whmTiers,
    [xi.job.BLM]  = blmTiers,
    [xi.job.RDM]  = rdmTiers,
    [xi.job.THF]  = thfTiers,
    [xi.job.PLD]  = pldTiers,
    [xi.job.DRK]  = drkTiers,
    [xi.job.BST]  = bstTiers,
    [xi.job.BRD]  = brdTiers,
    [xi.job.RNG]  = rngTiers,
    [xi.job.SMN]  = smnTiers,
    [xi.job.NIN]  = ninTiers,
    [xi.job.SAM]  = samTiers,
    [xi.job.DRG]  = drgTiers,
    [xi.job.BLU]  = bluTiers,
    [xi.job.COR]  = corTiers,
    [xi.job.PUP]  = pupTiers,
    [xi.job.DNC]  = dncTiers,
    [xi.job.SCH]  = schTiers,
    [xi.job.GEO]  = geoTiers,
    [xi.job.RUN]  = runTiers,
}

xi.bis_gear_progression.bluMeleeTiers = bluMeleeTiers
xi.bis_gear_progression.bluMageTiers  = bluMageTiers

---@param job integer
---@param level integer
---@param slot integer
---@param endgameCandidates integer[]|nil
---@return integer[]
function xi.bis_gear_progression.getCandidates(job, level, slot, endgameCandidates)
    local merged = {}
    local seen   = {}

    local function append(listToAppend)
        if not listToAppend then
            return
        end

        for _, itemId in ipairs(listToAppend) do
            if itemId and itemId > 0 and not seen[itemId] then
                seen[itemId] = true
                table.insert(merged, itemId)
            end
        end
    end

    local tiers = xi.bis_gear_progression.byJob[job]
    if tiers then
        local chosen = nil
        for i = #tiers, 1, -1 do
            if level >= tiers[i].minLevel then
                chosen = tiers[i].slots[slot]
                break
            end
        end
        append(chosen)
    end

    if level >= 68 then
        append(endgameCandidates)
    end

    return merged
end

--- Candidates from every unlocked tier, highest first (current BiS, then older fallbacks).
---@param job integer
---@param level integer
---@param slot integer
---@return integer[]
function xi.bis_gear_progression.getCandidatesAcrossTiers(job, level, slot)
    local merged = {}
    local seen   = {}
    local tiers  = xi.bis_gear_progression.byJob[job]
    if not tiers then
        return merged
    end

    for i = #tiers, 1, -1 do
        if level >= tiers[i].minLevel then
            local list = tiers[i].slots[slot]
            if list then
                for _, itemId in ipairs(list) do
                    if itemId and itemId > 0 and not seen[itemId] then
                        seen[itemId] = true
                        table.insert(merged, itemId)
                    end
                end
            end
        end
    end

    return merged
end

--- Highest progression tier minLevel the player has unlocked for this job.
---@param job integer
---@param level integer
---@return integer
function xi.bis_gear_progression.getTierMinLevel(job, level)
    local tiers = xi.bis_gear_progression.byJob[job]
    if not tiers then
        return 1
    end

    local chosen = 1
    for i = 1, #tiers do
        if level >= tiers[i].minLevel then
            chosen = tiers[i].minLevel
        end
    end

    return chosen
end

return xi.bis_gear_progression
