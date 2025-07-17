#include "StatusCommon.as";

shared string[] SPELL_TOOLTIPS()
{
    string[] arr =
    {
        "Magic Damage: deals magic damage",
        "Physical Damage: deals physical damage",
        "Fire: might ignite targets",
        "Water: might apply wet effect",
        "Freezing: might apply freezing effect or deal more damage to wet targets",
        "Electricity: might deal more damage to wet targets",
        "Poison: might apply poisont",
        "Knockback: high knockback",
        "Barrier: creates a barrier",
        "Sentry: creates a sentry",
        "Vampirism: lifesteal on hit",
        "Heal: restores health, might require overcharge",
        "Summon: summons an entity",
        "Rain: creates the spell at sky",
        "Double-Stage: pressing [SHIFT] key might activate something",
        "Homing Cursor: following cursor projectile",
        "Revive: revives an ally from their gravestone",
        "Movement: movement spell",
        "Caster Effect: effects on the caster, might require overcharge",
        "Ally Effect: effects on allies"
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
    SPELL_MAGIC_DAMAGE =        0,
    SPELL_PHYSICAL_DAMAGE =     1,
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
    TOTAL =                     20
}

shared class Attribute : Status
{
    Attribute(u8 _type, Vec2f _dim, string _icon, int _duration, f32 _scale = 1.0f)
    {
        super(_type, _dim, _icon, _duration, _scale);
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
            tooltip.pos = pos;
        }
    }

    void blink(Vec2f tl, Vec2f br) override {}
};