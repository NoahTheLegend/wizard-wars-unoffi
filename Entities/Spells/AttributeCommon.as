#include "StatusCommon.as";

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
        "Might apply poisont",
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