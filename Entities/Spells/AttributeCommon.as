#include "StatusCommon.as";

enum WizardSpellAttributes
{
    ORB,
    TELEPORT,
    COUNTER_SPELL,
    FROST_BALL,
    HEAL,
    FIREBOMB,
    FIRE_SPRITE,
    METEOR_STRIKE,
    REVIVE,
    MAGIC_BARRIER,
    SLOW,
    HASTE,
    LIGHTNING,
    MANA_DRAIN_CIRCLE,
    MAGICPLATFORM,
    NEGATISPHERE,
    PLASMA_SHOT,
    CHAINLIGHTNING,
    FLAMECIRCLE,
    EMPTY_SPELL
};

const uint[][] WizardSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // ORB
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT
    {}, // COUNTER_SPELL
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_FREEZING}, // FROST_BALL
    {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HEAL
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_FIRE}, // FIREBOMB
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HOMING_CURSOR}, // FIRE_SPRITE
    {SpellAttribute::SPELL_RAIN}, // METEOR_STRIKE
    {SpellAttribute::SPELL_REVIVE}, // REVIVE
    {SpellAttribute::SPELL_BARRIER}, // MAGIC_BARRIER
    {SpellAttribute::SPELL_CONTROL}, // SLOW
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HASTE
    {SpellAttribute::SPELL_RAIN, SpellAttribute::SPELL_ELECTRICITY}, // LIGHTNING
    {SpellAttribute::SPELL_CONTROL}, // MANA_DRAIN_CIRCLE
    {}, // MAGICPLATFORM
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_SHIFT, SpellAttribute::SPELL_CASTEREFFECT}, // NEGATISPHERE
    {SpellAttribute::SPELL_PROJECTILE}, // PLASMA_SHOT
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_ELECTRICITY}, // CHAINLIGHTNING
    {SpellAttribute::SPELL_FIRE}, // FLAMECIRCLE
    {} // EMPTY_SPELL
};

enum NecromancerSpells
{
    POISON_ARROW_RAIN,
    TELEPORT_NECROMANCER,
    COUNTER_SPELL_NECROMANCER,
    SLOW_NECROMANCER,
    ZOMBIE,
    BLACK_HOLE,
    ZOMBIE_KNIGHT,
    SKELETON_RAIN,
    ARROW_RAIN,
    RECALL_UNDEAD,
    UNHOLY_RESURRECTION,
    LEECH,
    FORCE_OF_NATURE,
    ARCANE_CIRCLE,
    BUNKER_BUSTER,
    NO_TELEPORT_BARRIER,
    MANA_BURN_NECROMANCER,
    TOME_OF_POISON,
    EMPTY_SPELL_NECROMANCER1,
    EMPTY_SPELL_NECROMANCER2
};

const uint[][] NecromancerSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // POISON_ARROW_RAIN
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_NECROMANCER
    {}, // COUNTER_SPELL_NECROMANCER
    {SpellAttribute::SPELL_CONTROL}, // SLOW_NECROMANCER
    {SpellAttribute::SPELL_SUMMON}, // ZOMBIE
    {SpellAttribute::SPELL_CONTROL}, // BLACK_HOLE
    {SpellAttribute::SPELL_SUMMON}, // ZOMBIE_KNIGHT
    {SpellAttribute::SPELL_SUMMON}, // SKELETON_RAIN
    {SpellAttribute::SPELL_RAIN}, // ARROW_RAIN
    {}, // RECALL_UNDEAD
    {SpellAttribute::SPELL_REVIVE}, // UNHOLY_RESURRECTION
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_VAMPIRISM}, // LEECH
    {SpellAttribute::SPELL_PROJECTILE}, // FORCE_OF_NATURE
    {}, // ARCANE_CIRCLE
    {SpellAttribute::SPELL_PROJECTILE}, // BUNKER_BUSTER
    {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CONTROL}, // NO_TELEPORT_BARRIER
    {SpellAttribute::SPELL_CONTROL}, // MANA_BURN_NECROMANCER
    {SpellAttribute::SPELL_PROJECTILE}, // TOME_OF_POISON
    {}, // EMPTY_SPELL_NECROMANCER1
    {}  // EMPTY_SPELL_NECROMANCER2
};


// --- DRUID ---

enum DruidSpells
{
    SPORE_SHOT,
    TELEPORT_DRUID,
    COUNTER_SPELL_DRUID,
    REVIVE_DRUID,
    NATURES_HELPERS,
    SPIKE_NUT,
    VINE_WAVER,
    ROCK_WALL,
    HEALING_PLANT,
    DANCING_SHROOM,
    ROCK_THROW,
    SLOW_DRUID,
    HASTE_DRUID,
    STONE_SPIKES,
    AIRBLAST_SHIELD,
    FIRE_WARD,
    VINE_TRAP,
    FOREST_TUNE,
    MOSSY_VEIL,
    EMPTY_SPELL_DRUID
};

const uint[][] DruidSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // SPORE_SHOT
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_DRUID
    {}, // COUNTER_SPELL_DRUID
    {SpellAttribute::SPELL_REVIVE}, // REVIVE_DRUID
    {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_SUMMON}, // NATURES_HELPERS
    {SpellAttribute::SPELL_PROJECTILE}, // SPIKE_NUT
    {SpellAttribute::SPELL_PROJECTILE}, // VINE_WAVER
    {SpellAttribute::SPELL_BARRIER}, // ROCK_WALL
    {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_GROUNDED}, // HEALING_PLANT
    {SpellAttribute::SPELL_SENTRY, SpellAttribute::SPELL_GROUNDED}, // DANCING_SHROOM
    {SpellAttribute::SPELL_PROJECTILE}, // ROCK_THROW
    {SpellAttribute::SPELL_CONTROL}, // SLOW_DRUID
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HASTE_DRUID
    {SpellAttribute::SPELL_GROUNDED}, // STONE_SPIKES
    {SpellAttribute::SPELL_KNOCKBACK, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // AIRBLAST_SHIELD
    {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // FIRE_WARD
    {SpellAttribute::SPELL_CONTROL, SpellAttribute::SPELL_GROUNDED}, // VINE_TRAP
    {SpellAttribute::SPELL_PROJECTILE}, // FOREST_TUNE
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_GROUNDED, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT, SpellAttribute::SPELL_CONTROL}, // MOSSY_VEIL
    {} // EMPTY_SPELL_DRUID
};

// --- SWORD CASTER ---

enum SwordCasterSpells
{
    IMPALER,
    TELEPORT_SWORDCASTER,
    COUNTER_SPELL_SWORDCASTER,
    EXECUTIONER,
    CRUSADER,
    EXPUNGER,
    BLADED_SHELL,
    HOOK,
    PARRY,
    VECTORIAL_DASH,
    FLAME_SLASH,
    NEMESIS,
    LYNCH,
    EMPTY_SPELL_SWORDCASTER1,
    EMPTY_SPELL_SWORDCASTER2,
    EMPTY_SPELL_SWORDCASTER3,
    EMPTY_SPELL_SWORDCASTER4,
    EMPTY_SPELL_SWORDCASTER5,
    EMPTY_SPELL_SWORDCASTER6,
    EMPTY_SPELL_SWORDCASTER7
};

const uint[][] SwordCasterSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // IMPALER
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_SWORDCASTER
    {}, // COUNTER_SPELL_SWORDCASTER
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_SHIFT}, // EXECUTIONER
    {SpellAttribute::SPELL_PROJECTILE}, // CRUSADER
    {SpellAttribute::SPELL_PROJECTILE}, // EXPUNGER
    {SpellAttribute::SPELL_CASTEREFFECT}, // BLADED_SHELL
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_MOVEMENT}, // HOOK
    {SpellAttribute::SPELL_KNOCKBACK}, // PARRY
    {SpellAttribute::SPELL_MOVEMENT}, // VECTORIAL_DASH
    {SpellAttribute::SPELL_MELEE, SpellAttribute::SPELL_FIRE, SpellAttribute::SPELL_CASTEREFFECT}, // FLAME_SLASH
    {SpellAttribute::SPELL_RAIN}, // NEMESIS
    {SpellAttribute::SPELL_CONTROL}, // LYNCH
    {}, // EMPTY_SPELL_SWORDCASTER1
    {}, // EMPTY_SPELL_SWORDCASTER2
    {}, // EMPTY_SPELL_SWORDCASTER3
    {}, // EMPTY_SPELL_SWORDCASTER4
    {}, // EMPTY_SPELL_SWORDCASTER5
    {}, // EMPTY_SPELL_SWORDCASTER6
    {}  // EMPTY_SPELL_SWORDCASTER7
};

// --- ENTROPIST ---

enum EntropistSpells
{
    ORB_ENTROPIST,
    TELEPORT_ENTROPIST,
    COUNTER_SPELL_ENTROPIST,
    DISRUPTION_WAVE,
    HASTE_ENTROPIST,
    SIDEWIND,
    VOLTAGE_FIELD,
    NOVA,
    BURN,
    NEGENTROPY,
    CRYSTALLIZE,
    DEMATERIALIZE,
    POLARITY,
    DISRUPTION_MINE,
    MAGIC_ARROWS,
    POLARITY_BREAKER,
    STELLAR_COLLAPSE,
    EMPTY_SPELL_ENTROPIST1,
    EMPTY_SPELL_ENTROPIST2,
    EMPTY_SPELL_ENTROPIST3
};

const uint[][] EntropistSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // ORB_ENTROPIST
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_ENTROPIST
    {}, // COUNTER_SPELL_ENTROPIST
    {SpellAttribute::SPELL_MELEE}, // DISRUPTION_WAVE
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HASTE_ENTROPIST
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT}, // SIDEWIND
    {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT}, // VOLTAGE_FIELD
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HOMING_CURSOR}, // NOVA
    {SpellAttribute::SPELL_CASTEREFFECT}, // BURN
    {SpellAttribute::SPELL_CASTEREFFECT}, // NEGENTROPY
    {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT}, // CRYSTALLIZE
    {SpellAttribute::SPELL_CASTEREFFECT}, // DEMATERIALIZE
    {SpellAttribute::SPELL_CASTEREFFECT}, // POLARITY
    {SpellAttribute::SPELL_GROUNDED}, // DISRUPTION_MINE
    {SpellAttribute::SPELL_PROJECTILE}, // MAGIC_ARROWS
    {}, // POLARITY_BREAKER
    {SpellAttribute::SPELL_RAIN}, // STELLAR_COLLAPSE
    {}, // EMPTY_SPELL_ENTROPIST1
    {}, // EMPTY_SPELL_ENTROPIST2
    {}  // EMPTY_SPELL_ENTROPIST3
};

// --- PRIEST ---

enum PriestSpells
{
    ORBITING_ORBS,
    TELEPORT_PRIEST,
    COUNTER_SPELL_PRIEST,
    HASTE_PRIEST,
    REVIVE_PRIEST,
    SLOW_PRIEST,
    MANA_TRANSFER,
    REGENERATION,
    HOLY_STRIKE,
    DIVINE_SHIELD,
    DIVINE_BEAM,
    SACRILEGE_FIRE,
    SINGULARITY,
    FIERY_STARS,
    EMERGENCY_TELEPORT,
    DAMAGE_AURA,
    MANA_BURN_PRIEST,
    EMPTY_SPELL_PRIEST1,
    EMPTY_SPELL_PRIEST2,
    EMPTY_SPELL_PRIEST3
};

const uint[][] PriestSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // ORBITING_ORBS
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_PRIEST
    {}, // COUNTER_SPELL_PRIEST
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HASTE_PRIEST
    {SpellAttribute::SPELL_REVIVE}, // REVIVE_PRIEST
    {SpellAttribute::SPELL_CONTROL}, // SLOW_PRIEST
    {SpellAttribute::SPELL_ALLYEFFECT}, // MANA_TRANSFER
    {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // REGENERATION
    {SpellAttribute::SPELL_PROJECTILE}, // HOLY_STRIKE
    {SpellAttribute::SPELL_BARRIER}, // DIVINE_SHIELD
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEAL}, // DIVINE_BEAM
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HOMING_CURSOR}, // SACRILEGE_FIRE
    {}, // SINGULARITY
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_SHIFT}, // FIERY_STARS
    {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_MOVEMENT}, // EMERGENCY_TELEPORT
    {SpellAttribute::SPELL_ALLYEFFECT}, // DAMAGE_AURA
    {SpellAttribute::SPELL_CONTROL}, // MANA_BURN_PRIEST
    {}, // EMPTY_SPELL_PRIEST1
    {}, // EMPTY_SPELL_PRIEST2
    {}  // EMPTY_SPELL_PRIEST3
};

// --- SHAMAN ---

enum ShamanSpells
{
    FLAME_ORB,
    TELEPORT_SHAMAN,
    COUNTER_SPELL_SHAMAN,
    HASTE_SHAMAN,
    WATER_BOLT,
    FIRE_WARD_SHAMAN,
    CHAIN_LIGHTNING_SHAMAN,
    TOTEM_OF_FIRE,
    TOTEM_OF_WATER,
    TOTEM_OF_EARTH,
    MASS_FREEZE,
    LAVA_SHOT,
    ARC_LIGHTNING,
    MAGIC_ICICLES,
    WATER_BARRIER,
    GLACIAL_SPIRIT,
    VOLCANO,
    LIGHTNING_BALL,
    EMPTY_SPELL_SHAMAN1,
    EMPTY_SPELL_SHAMAN2
};

const uint[][] ShamanSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // FLAME_ORB
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_SHAMAN
    {}, // COUNTER_SPELL_SHAMAN
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HASTE_SHAMAN
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_WATER}, // WATER_BOLT
    {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // FIRE_WARD_SHAMAN
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_ELECTRICITY}, // CHAIN_LIGHTNING_SHAMAN
    {SpellAttribute::SPELL_SENTRY, SpellAttribute::SPELL_GROUNDED, SpellAttribute::SPELL_FIRE}, // TOTEM_OF_FIRE
    {SpellAttribute::SPELL_SENTRY, SpellAttribute::SPELL_GROUNDED, SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_WATER, SpellAttribute::SPELL_KNOCKBACK}, // TOTEM_OF_WATER
    {SpellAttribute::SPELL_SENTRY, SpellAttribute::SPELL_GROUNDED, SpellAttribute::SPELL_CONTROL}, // TOTEM_OF_EARTH
    {SpellAttribute::SPELL_FREEZING, SpellAttribute::SPELL_CONTROL, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // MASS_FREEZE
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_FIRE}, // LAVA_SHOT
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_ELECTRICITY}, // ARC_LIGHTNING
    {SpellAttribute::SPELL_PROJECTILE}, // MAGIC_ICICLES
    {SpellAttribute::SPELL_WATER, SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT}, // WATER_BARRIER
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_FREEZING}, // GLACIAL_SPIRIT
    {SpellAttribute::SPELL_RAIN}, // VOLCANO
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_ELECTRICITY}, // LIGHTNING_BALL
    {}, // EMPTY_SPELL_SHAMAN1
    {}  // EMPTY_SPELL_SHAMAN2
};

// --- PALADIN ---

enum PaladinSpells
{
    TEMPLAR_HAMMER,
    TELEPORT_PALADIN,
    COUNTER_SPELL_PALADIN,
    HEAVENLY_CRUSH,
    AURA_TAU,
    AURA_SIGMA,
    AURA_OMEGA,
    HALLOWED_PROTECTION,
    HUMILITY,
    GLYPH_OF_MAJESTY,
    SEAL_OF_WISDOM,
    NOBLE_LANCE,
    SMITE,
    FAITH_GLAIVE,
    CIRCLE_OF_BLESS,
    KNIGHT_REVIVE,
    HOLY_ANGEL,
    EMPTY_SPELL_PALADIN1,
    EMPTY_SPELL_PALADIN2,
    EMPTY_SPELL_PALADIN3
};

const uint[][] PaladinSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // TEMPLAR_HAMMER
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_PALADIN
    {}, // COUNTER_SPELL_PALADIN
    {SpellAttribute::SPELL_KNOCKBACK, SpellAttribute::SPELL_GROUNDED}, // HEAVENLY_CRUSH
    {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // AURA_TAU
    {SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_CASTEREFFECT}, // AURA_SIGMA
    {SpellAttribute::SPELL_MELEE, SpellAttribute::SPELL_CASTEREFFECT}, // AURA_OMEGA
    {SpellAttribute::SPELL_BARRIER, SpellAttribute::SPELL_CASTEREFFECT}, // HALLOWED_PROTECTION
    {}, // HUMILITY
    {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // GLYPH_OF_MAJESTY
    {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // SEAL_OF_WISDOM
    {SpellAttribute::SPELL_PROJECTILE}, // NOBLE_LANCE
    {SpellAttribute::SPELL_RAIN}, // SMITE
    {SpellAttribute::SPELL_MELEE}, // FAITH_GLAIVE
    {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // CIRCLE_OF_BLESS
    {SpellAttribute::SPELL_REVIVE}, // KNIGHT_REVIVE
    {SpellAttribute::SPELL_SUMMON}, // HOLY_ANGEL
    {}, // EMPTY_SPELL_PALADIN1
    {}, // EMPTY_SPELL_PALADIN2
    {}  // EMPTY_SPELL_PALADIN3
};

// --- JESTER ---

enum JesterSpells
{
    REJOICING_GAS,
    TELEPORT_JESTER,
    COUNTER_SPELL_JESTER,
    FLOWER_PAD,
    ENCHANTED_MITTEN,
    BOB_OMB,
    GUMMY_BOMB,
    JESTER_DECK,
    AIR_HORN,
    BAT,
    POSSESSED_TOPHAT,
    BASHSTER,
    HASTE_JESTER,
    SHAPE_SHIFT,
    EMPTY_SPELL_JESTER1,
    EMPTY_SPELL_JESTER2,
    EMPTY_SPELL_JESTER3,
    EMPTY_SPELL_JESTER4,
    EMPTY_SPELL_JESTER5,
    EMPTY_SPELL_JESTER6
};

const uint[][] JesterSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE}, // REJOICING_GAS
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_JESTER
    {}, // COUNTER_SPELL_JESTER
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_GROUNDED}, // FLOWER_PAD
    {SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_SHIFT}, // ENCHANTED_MITTEN
    {SpellAttribute::SPELL_SUMMON}, // BOB_OMB
    {SpellAttribute::SPELL_PROJECTILE}, // GUMMY_BOMB
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_SHIFT, SpellAttribute::SPELL_HEAL, SpellAttribute::SPELL_CONTROL, SpellAttribute::SPELL_CASTEREFFECT}, // JESTER_DECK
    {SpellAttribute::SPELL_KNOCKBACK}, // AIR_HORN
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_KNOCKBACK}, // BAT
    {SpellAttribute::SPELL_SUMMON, SpellAttribute::SPELL_HEAL}, // POSSESSED_TOPHAT
    {SpellAttribute::SPELL_PROJECTILE}, // BASHSTER
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_CASTEREFFECT, SpellAttribute::SPELL_ALLYEFFECT}, // HASTE_JESTER
    {SpellAttribute::SPELL_CASTEREFFECT}, // SHAPE_SHIFT
    {}, // EMPTY_SPELL_JESTER1
    {}, // EMPTY_SPELL_JESTER2
    {}, // EMPTY_SPELL_JESTER3
    {}, // EMPTY_SPELL_JESTER4
    {}, // EMPTY_SPELL_JESTER5
    {}  // EMPTY_SPELL_JESTER6
};

// --- WARLOCK ---

enum WarlockSpells
{
    BLOOD_BOLTS,
    TELEPORT_WARLOCK,
    COUNTER_SPELL_WARLOCK,
    LEECH_WARLOCK,
    TOME_OF_BLOOD,
    SIGIL_OF_WARP,
    CHRONOMANTIC_TELEPORT,
    TOXIC_BOLT,
    CORRUPTION_SHARD,
    PLAGUE,
    SHADOW_BURST,
    SHADOW_SPEAR,
    CARNAGE,
    DARK_RITUAL,
    DEMONIC_PACT,
    FEAR,
    SILENCE,
    EMPTY_SPELL_WARLOCK1,
    EMPTY_SPELL_WARLOCK2,
    EMPTY_SPELL_WARLOCK3,
    EMPTY_SPELL_WARLOCK4
};

const uint[][] WarlockSpellAttributesCollection = {
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEALTHCOST}, // BLOOD_BOLTS
    {SpellAttribute::SPELL_MOVEMENT}, // TELEPORT_WARLOCK
    {}, // COUNTER_SPELL_WARLOCK
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_VAMPIRISM}, // LEECH_WARLOCK
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_HEALTHCOST}, // TOME_OF_BLOOD
    {SpellAttribute::SPELL_MOVEMENT}, // SIGIL_OF_WARP
    {SpellAttribute::SPELL_MOVEMENT, SpellAttribute::SPELL_HEALTHCOST}, // CHRONOMANTIC_TELEPORT
    {SpellAttribute::SPELL_PROJECTILE, SpellAttribute::SPELL_POISON}, // TOXIC_BOLT
    {SpellAttribute::SPELL_POISON, SpellAttribute::SPELL_CONTROL, SpellAttribute::SPELL_SENTRY, SpellAttribute::SPELL_GROUNDED}, // CORRUPTION_SHARD
    {SpellAttribute::SPELL_POISON, SpellAttribute::SPELL_SHIFT, SpellAttribute::SPELL_CASTEREFFECT}, // PLAGUE
    {SpellAttribute::SPELL_PROJECTILE}, // SHADOW_BURST
    {SpellAttribute::SPELL_PROJECTILE}, // SHADOW_SPEAR
    {SpellAttribute::SPELL_HEALTHCOST, SpellAttribute::SPELL_CASTEREFFECT}, // CARNAGE
    {SpellAttribute::SPELL_VAMPIRISM, SpellAttribute::SPELL_CASTEREFFECT}, // DARK_RITUAL
    {SpellAttribute::SPELL_HEALTHCOST, SpellAttribute::SPELL_SUMMON, SpellAttribute::SPELL_REVIVE}, // DEMONIC_PACT
    {SpellAttribute::SPELL_CONTROL}, // FEAR
    {SpellAttribute::SPELL_CONTROL}, // SILENCE
    {}, // EMPTY_SPELL_WARLOCK1
    {}, // EMPTY_SPELL_WARLOCK2
    {}, // EMPTY_SPELL_WARLOCK3
    {}  // EMPTY_SPELL_WARLOCK4
};

shared string[] SPELL_TOOLTIPS()
{
    string[] arr =
    {
        "Creates one or more projectiles",
        "Deals meelee damage",
        "Might ignite targets",
        "Might apply wet effect",
        "Might apply freezing effect or deal more damage to wet targets",
        "Might deal more damage to wet targets",
        "Might apply poison",
        "High knockback",
        "Creates a barrier",
        "Creates a sentry",
        "Lifesteal on hit",
        "Restores health, might require overcharge",
        "Summons an entity",
        "Cast from sky",
        "Pressing [SHIFT] key might activate something",
        "Following cursor",
        "Revives an ally from their gravestone",
        "Movement spell",
        "Affects the caster, might require overcharge",
        "Affects allies",
        "Affects enemy movement or spell casting",
        "Cast near ground",
        "Consumes health instead of mana"
    };

    return arr;
}

shared Attribute@ makeAttribute(u8 type = 0)
{
    string icon = "SpellAttributeIcons.png";
    Vec2f dim = Vec2f(32, 32);
    int duration = 0;
    f32 scale = 1.0f;

    return @Attribute(type, dim, icon, duration, scale);
}

shared Attribute@[] getAttributes()
{
    Attribute@[] attributes;
    for (u8 i = 0; i < SpellAttribute::TOTAL; i++)
    {
        Attribute@ attr = makeAttribute(i);
        attributes.push_back(attr);
    }

    return attributes;
}

shared enum SpellAttribute
{
    SPELL_PROJECTILE =          0,
    SPELL_MELEE =               1,
    SPELL_FIRE =                2,
    SPELL_WATER =               3,
    SPELL_FREEZING =            4,
    SPELL_ELECTRICITY =         5,
    SPELL_POISON =              6,
    SPELL_KNOCKBACK =           7,
    SPELL_BARRIER =             8,
    SPELL_SENTRY =              9,
    SPELL_VAMPIRISM =           10,
    SPELL_HEAL =                11,
    SPELL_SUMMON =              12,
    SPELL_RAIN =                13,
    SPELL_SHIFT =               14,
    SPELL_HOMING_CURSOR =       15,
    SPELL_REVIVE =              16,
    SPELL_MOVEMENT =            17,
    SPELL_CASTEREFFECT =        18,
    SPELL_ALLYEFFECT =          19,
    SPELL_CONTROL =             20,
    SPELL_GROUNDED =            21,
    SPELL_HEALTHCOST =          22,
    TOTAL
}

shared class Attribute : Status
{
    Attribute(u8 _type, Vec2f _dim, string _icon, int _duration, f32 _scale = 1.0f)
    {
        super(_type, _dim, _icon, _duration, _scale, true);
        string[] tooltips = SPELL_TOOLTIPS();
        @tooltip = @Tooltip(_type, tooltips[_type], Vec2f_zero, dim * scale);
        tooltip.tooltip_col = SColor(255, 255, 255, 255);
    }

    void tick() override
    {
        f32 df = getDeltaFactor();
        u8 tooltip_focus_time = getTooltipFocusTime();
        u8 max_fade = getMaxFade();

        if (hover)
        {
            if (cursor_focus_time < tooltip_focus_time) cursor_focus_time++;
        }
        else cursor_focus_time = 0;
        
        if (cursor_focus_time >= tooltip_focus_time)
        {
            if (tooltip_fade < max_fade) tooltip_fade++;
        }
        else if (tooltip_fade > 0) tooltip_fade--;

        if (tooltip !is null)
        {
            tooltip.fade = Maths::Lerp(tooltip.fade, f32(tooltip_fade) / f32(max_fade), df * 2);
            tooltip.pos = pos - Vec2f(16, 8);
        }
    }

    void render(Vec2f pos, f32 hiding_factor, Tooltip@[] &inout tooltip_fetcher) override
    {
        Vec2f tl = pos;
        Vec2f br = tl + dim * scale;

        GUI::DrawIcon("StatusSlotHud.png", 1, Vec2f(32, 32), tl - dim / 2, scale, scale, SColor(255, 255, 255, 255));
        GUI::DrawIcon(icon, type, dim, tl, scale / 2, SColor(255, 255, 255, 255));
        
        if (tooltip !is null)
        {
            tooltip_fetcher.push_back(tooltip);
        }

        if (hover) // select
        {
            GUI::DrawRectangle(tl, br, SColor(35 * (1.0f - hiding_factor), 0, 0, 0));
        }
    }
};