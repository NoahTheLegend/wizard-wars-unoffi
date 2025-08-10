#include "WarlockCommon.as";

shared Vec2f getScreenSize()
{
    return getDriver().getScreenDimensions();
}

shared u8 getElementsPerRow()
{
    return 5;
}

shared u8 getMaxFade()
{
    return 5;
}

shared u16 getBlinkTiming()
{
    return 210;
}

shared u8 getTooltipFocusTime()
{
    return 7;
}

shared f32 getDeltaFactor()
{
    return 0.25f * getRenderDeltaTime() * 60.0f;
}

shared Vec2f getElementDimensions()
{
    Vec2f screen_size = getScreenSize();
    Vec2f elem_dim = Vec2f(64, 64);

    if (screen_size.x < 1024 || screen_size.y < 576)
    {
        elem_dim = Vec2f(32, 32);
    }
    else if (screen_size.x < 1280 || screen_size.y < 720)
    {
        elem_dim = Vec2f(48, 48);
    }

    return elem_dim;
}

Status@[] STATUSES = makeStatuses();
shared Status@[] makeStatuses()
{
    Status@[] statuses;
    for (u8 i = 0; i < StatusType::TOTAL; i++)
    {
        string icon = "StatusIcons.png";
        Vec2f dim = Vec2f(32, 32);
        int duration = 0;
        f32 scale = 1.0f;

        statuses.push_back(@Status(i, dim, icon, duration, scale));
    }

    return statuses;
}

shared enum StatusType
{
    IGNITED =                   0,
    WET =                       1,
    FROZEN =                    2,
    POISON =                    3,
    DAMAGE_BOOST =              4, // damage buff
    FOCUS =                     5, // +1 mana regen
    HASTE =                     6,
    SLOW =                      7,
    AIRBLAST_SHIELD =           8,
    FIREPROOF_SHIELD =          9,
    HEAL =                      10,
    MANABURN =                  11,
    ENTROPIST_SIDEWIND =        12,
    ENTROPIST_BURN =            13,
    PALADIN_TAU =               14,
    PALADIN_SIGMA =             15,
    PALADIN_OMEGA =             16,
    PALADIN_HOLY_BARRIER =      17,
    PALADIN_HUMILITY =          18,
    PALADIN_MAJESTY =           19,
    PALADIN_WISDOM =            20,
    CONFUSED =                  21,
    PLAGUE =                    22,
    SILENCED =                  23,
    FEAR =                      24,
    CARNAGE =                   25,
    DARKRITUAL =                26,

    TOTAL
};

shared enum StatusSpecific
{
    DEBUFF = 0,
    BUFF = 1,
    HEAL = 2,
    PROTECTION = 3,
    CONTROL = 4,
    OTHER = 5
};

shared u8[] TOOLTIPS_SPECIFIC()
{
    const u8[] arr = {
        StatusSpecific::DEBUFF, // IGNITED
        StatusSpecific::OTHER, // WET
        StatusSpecific::CONTROL, // FROZEN
        StatusSpecific::DEBUFF, // POISON
        StatusSpecific::BUFF, // DAMAGE_BOOST
        StatusSpecific::BUFF, // FOCUS
        StatusSpecific::BUFF, // HASTE
        StatusSpecific::DEBUFF, // SLOW
        StatusSpecific::PROTECTION, // AIRBLAST_SHIELD
        StatusSpecific::PROTECTION, // FIREPROOF_SHIELD
        StatusSpecific::HEAL, // HEAL
        StatusSpecific::DEBUFF, // MANABURN
        StatusSpecific::OTHER, // ENTROPIST_SIDEWIND
        StatusSpecific::OTHER, // ENTROPIST_BURN
        StatusSpecific::PROTECTION, // PALADIN_TAU
        StatusSpecific::HEAL, // PALADIN_SIGMA
        StatusSpecific::OTHER, // PALADIN_OMEGA
        StatusSpecific::PROTECTION, // PALADIN_HOLY_BARRIER
        StatusSpecific::DEBUFF, // PALADIN_HUMILITY
        StatusSpecific::BUFF, // PALADIN_MAJESTY
        StatusSpecific::BUFF, // PALADIN_WISDOM
        StatusSpecific::CONTROL, // CONFUSED
        StatusSpecific::OTHER, // PLAGUE
        StatusSpecific::CONTROL, // SILENCED
        StatusSpecific::CONTROL, // FEAR
        StatusSpecific::BUFF, // CARNAGE
        StatusSpecific::OTHER // DARKRITUAL
    };
    
    return arr;
}

shared string[] TOOLTIPS()
{
    const string[] arr = {
        "Burning: physical DoT",
        "Wet: vulnerable to Ice and Electricity, resistant to Burning",
        "Frozen: immobilized",
        "Poisoned: magic DoT",
        "Damage Boost: enhanced spells",
        "Focus: +1 mana regeneration",
        "Haste: increased movement speed",
        "Slow: decreased movement speed",
        "Airblast Shield: blasting knockback on hit",
        "Fireproof Shield: immune to Burning",
        "Heal: regenerating health",
        "Manaburn: losing Mana",
        "Entropist Sidewind: ignore collisions, increased movement speed",
        "Entropist Burn: free spells, diminished spell cast time, losing 30 mana per second",
        "Aura (Tau): take less damage and transfer some of it to the linked ally when nearby",
        "Aura (Sigma): restore health instead of mana, increases damage taken, disables mana replenishment at obelisks",
        "Aura (Omega): restore mana on hit, returns some of the damage split between enemies nearby",
        "Hallowed Barrier: decreases damage taken",
        "Humility: disable healing",
        "Majesty: decreased spells cooldown",
        "Wisdom: wipe some of negative effects",
        "Confused: reversed controls",
        "Plague: permanently poisoned, taking damage poisons the enemy",
        "Silenced: unable to cast spells except teleport",
        "Fear: constantly running",
        "Carnage: decreased spell cast time, spells won't have cooldown on cast",
        "Dark Ritual: spells restore "+Maths::Round(darkritual_lifesteal_mod * 100.0f)+"% of damage dealt, you take damage in the end of the effect"
    };
    
    return arr;
}

shared class Status
{
    u8 type;
    Vec2f pos;
    Vec2f dim;
    string icon;
    int duration;
    f32 scale;

    Tooltip@ tooltip;
    u8 tooltip_fade;
    u8 cursor_focus_time;
    bool hover;

    bool active;
    s8 active_fade;
    f32 blink_sine;

    Status(u8 _type, Vec2f _dim, string _icon, int _duration, f32 _scale = 1.0f, bool _super = false)
    {
        type = _type;
        pos = Vec2f_zero;
        dim = _dim;
        icon = _icon;
        duration = _duration;
        scale = _scale;

        if (!_super)
        {
            string[] tooltips = TOOLTIPS();
            @tooltip = @Tooltip(type, tooltips[type], Vec2f_zero, dim * scale);
        }

        tooltip_fade = 0;
        cursor_focus_time = 0;
        hover = false;

        active = false;
        active_fade = 0;
        blink_sine = 0.0f;
    }

    void tick()
    {
        f32 df = getDeltaFactor();
        u16 blink_timing = getBlinkTiming();
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
            tooltip.desc_seconds = Maths::Round(duration * 10.0f / 30.0f) / 10;
        }
        
        active_fade = Maths::Clamp(active_fade + (duration > 0 ? 1 : -1), 0, max_fade);
        if (duration <= 1 || duration > blink_timing) return;
        
        f32 frequency_speed = 2.0f - Maths::Min(f32(duration) / f32(blink_timing), 1.0f);
        blink_sine = Maths::Sin(f32(duration + 5) * frequency_speed * 0.75f) * 0.5f + 0.5f;
    }

    void render(Vec2f pos, f32 hiding_factor, Tooltip@[] &inout tooltip_fetcher)
    {
        u8 max_fade = getMaxFade();

        f32 mod = 1.0f - scale;
        f32 fade = f32(active_fade) / f32(max_fade);

        Vec2f tl = pos + (dim - dim * mod) / 2;
        Vec2f br = tl + dim * scale;

        GUI::DrawIcon("StatusSlot.png", 1, Vec2f(32, 32), pos + Vec2f(32, 32) * mod / 2, scale, scale, SColor(255 * fade * (1.0f - hiding_factor), 255, 255, 255));
        GUI::DrawIcon(icon, type, dim, tl, scale / 2, SColor(255 * fade * (1.0f - hiding_factor), 255, 255, 255));
        
        blink(tl, br);

        if (tooltip !is null)
        {
            if (tooltip_fade > 0) tooltip_fetcher.push_back(tooltip);
        }

        if (hover) // select
        {
            GUI::DrawRectangle(tl, br, SColor(35 * fade * (1.0f - hiding_factor), 0, 0, 0));
        }
    }

    void blink(Vec2f tl, Vec2f br)
    {
        u16 blink_timing = getBlinkTiming();
        if (duration <= 1 || duration > blink_timing) return;

        GUI::DrawRectangle(
            tl,
            br,
            SColor(100 * blink_sine, 255, 255, 255));

        //GUI::DrawRectangle(tl, tl+Vec2f(4,4), SColor(255, 255, 0, 0));
    }
}

shared class Tooltip
{
    u8 type;
    string text;
    Vec2f pos;
    Vec2f dim;
    f32 fade;
    Vec2f text_dim;
    SColor tooltip_col;
    int desc_seconds;

    Tooltip(u8 _type, string _text, Vec2f _pos, Vec2f _dim)
    {
        type = _type;
        text = _text;
        pos = _pos;
        dim = _dim;
        fade = 0.0f;
        tooltip_col = getTooltipColor(type);
        desc_seconds = 0;
    }

    void render()
    {
        if (fade <= 0.05f)
            return;

        GUI::SetFont("menu");

        string seconds = desc_seconds > 0 ? " " + desc_seconds + "s" : "";
        Vec2f seconds_dim;
        GUI::GetTextDimensions(seconds, seconds_dim);

        GUI::GetTextDimensions(text, text_dim);
        text_dim.x += seconds_dim.x;
        
        Vec2f tooltip_pos = pos - Vec2f(text_dim.x / 2 - dim.x + 4, text_dim.y + 8);
        GUI::DrawPane(tooltip_pos, tooltip_pos + text_dim + Vec2f(8, 8), SColor(uint8(200 * fade), 55, 55, 55));

        tooltip_col.setAlpha(uint8(255 * fade));
        GUI::DrawText(text + seconds, tooltip_pos + Vec2f(2, 2), tooltip_col);
        GUI::SetFont("default");
    }

    SColor getTooltipColor(u8 type)
    {
        u8[] tooltips_specific = TOOLTIPS_SPECIFIC();
        switch (tooltips_specific[type])
        {
            case StatusSpecific::DEBUFF: return SColor(255, 255, 55, 55); // red
            case StatusSpecific::BUFF: return SColor(255, 155, 255, 155); // green
            case StatusSpecific::HEAL: return SColor(255, 0, 255, 0); // light green
            case StatusSpecific::PROTECTION: return SColor(255, 100, 180, 255); // blue
            case StatusSpecific::CONTROL: return SColor(255, 255, 85, 255); // purple
            case StatusSpecific::OTHER: return SColor(255, 255, 255, 0); // yellow
        }
    
        return SColor(255, 255, 255, 255); // default white
    }
};

void RenderTooltips(Tooltip@[] &in tooltips)
{
    if (tooltips is null || tooltips.size() == 0) // crashes the game on startup without this check
        return;

    for (u8 i = 0; i < tooltips.size(); i++)
    {
        if (tooltips[i] is null)
            continue;

        tooltips[i].render();
    }
}
