#define CLIENT_ONLY

#include "MagicCommon.as";
#include "PaladinCommon.as";

void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null)
        return;

    // init empty to avoid jank memory values
    blob.set_s16("burn timer", 0);
    blob.set_u16("wet timer", 0);
    blob.set_u16("poisoned", 0);
    blob.set_u32("damage_boost", 0);
    blob.set_u16("focus", 0);
    blob.set_u32("overload mana regen", 0);
    blob.set_u16("hastened", 0);
    blob.set_u16("slowed", 0);
    blob.set_u16("airblastShield", 0);
    blob.set_u16("fireProt", 0);
    blob.set_u16("regen", 0);
    blob.set_u16("manaburn", 0);
    blob.set_u16("sidewinding", 0);
    blob.set_bool("burnState", false);
    blob.set_u16("dmgconnection", 0);
    blob.set_bool("manatohealth", false);
    blob.set_bool("damagetomana", false);
    blob.set_u16("hallowedbarrier", 0);
    blob.set_u16("healblock", 0);
    blob.set_u16("cdreduction", 0);
    blob.set_u16("antidebuff", 0);
    blob.set_u16("confused", 0);

    setBar(blob);
}

void setBar(CBlob@ blob)
{
    Vec2f elem_dim = Vec2f(64, 64);
    if (screen_size.x < 1024 || screen_size.y < 576)
    {
        elem_dim = Vec2f(32, 32);
    }
    else if (screen_size.x < 1280 || screen_size.y < 720)
    {
        elem_dim = Vec2f(48, 48);
    }

    Vec2f size = Vec2f(elem_dim.x * elements_per_row, elem_dim.y);
    StatusBar bar(Vec2f(screen_size.x / 2 + elem_dim.x / 2, screen_size.y), size, elem_dim);
    blob.set("status_bar", @bar);
}

void onTick(CSprite@ this)
{
    if (this is null)
        return;

    CBlob@ blob = this.getBlob();
    if (blob is null || !blob.isMyPlayer())
        return;

    CPlayer@ player = blob.getPlayer();
    if (player is null)
        return;

    StatusBar@ bar;
    if (!blob.get("status_bar", @bar))
        return;

    bar.tick();
    
    
    if (isClient() && isServer() && getControls().isKeyJustPressed(KEY_KEY_R))
    {
        setBar(blob);
    }

    /*
    if (getControls().isKeyJustPressed(KEY_KEY_H))
    {
        blob.add_u8("iter", 1);
        
        if(blob.get_u8("iter")==1)  blob.set_u16("poisoned", 240);
        if(blob.get_u8("iter")==2)  blob.set_u16("wet timer", 9000);
        if(blob.get_u8("iter")==3)  blob.set_s16("burn timer", 9000);
        if(blob.get_u8("iter")==4)  blob.set_u16("hastened", 9000);
        if(blob.get_u8("iter")==5)  blob.set_u16("slowed", 9000);
        if(blob.get_u8("iter")==6)  blob.set_u16("airblastShield", 9000);
        if(blob.get_u8("iter")==7)  blob.set_u32("damage_boost", getGameTime() + 9000);
        if(blob.get_u8("iter")==8)  blob.set_u16("focus", 9000);
        if(blob.get_u8("iter")==9)  blob.set_u32("overload mana regen", getGameTime() + 9000);
        if(blob.get_u8("iter")==10) blob.set_u16("fireProt", 9000);
        if(blob.get_u8("iter")==11) blob.set_u16("regen", 9000);
        if(blob.get_u8("iter")==12) blob.set_u16("manaburn", 9000);
        if(blob.get_u8("iter")==13) blob.set_u16("sidewinding", 9000);
        if(blob.get_u8("iter")==14) blob.set_bool("burnState", true);
        if(blob.get_u8("iter")==15) blob.set_u16("dmgconnection", 9000);
        if(blob.get_u8("iter")==16) blob.set_bool("manatohealth", true);
        if(blob.get_u8("iter")==17) blob.set_bool("damagetomana", true);
        if(blob.get_u8("iter")==18) blob.set_u16("hallowedbarrier", 9000);
        if(blob.get_u8("iter")==19) blob.set_u16("healblock", 9000);
        if(blob.get_u8("iter")==20) blob.set_u16("cdreduction", 9000);
        if(blob.get_u8("iter")==21) blob.set_u16("antidebuff", 9000);
        if(blob.get_u8("iter")==22) blob.set_u16("confused", 9000);
        if (blob.get_u8("iter") == 22)
        {
            blob.set_u8("iter", 0);
        }
    }
    else if (getControls().isKeyJustPressed(KEY_KEY_J))
    {
        blob.set_u16("poisoned", 0);
        blob.set_u16("wet timer", 0);
        blob.set_s16("burn timer", 0);
        blob.set_u16("hastened", 0);
        blob.set_u16("slowed", 0);
        blob.set_u16("airblastShield", 0);
        blob.set_u32("damage_boost", 0);
        blob.set_u16("focus", 0);
        blob.set_u32("overload mana regen", 0);
        blob.set_u16("fireProt", 0);
        blob.set_u16("regen", 0);
        blob.set_u16("manaburn", 0);
        blob.set_u16("sidewinding", 0);
        blob.set_bool("burnState", false);
        blob.set_u16("dmgconnection", 0);
        blob.set_bool("manatohealth", false);
        blob.set_bool("damagetomana", false);
        blob.set_u16("hallowedbarrier", 0);
        blob.set_u16("healblock", 0);
        blob.set_u16("cdreduction", 0);
        blob.set_u16("antidebuff", 0);
        blob.set_u16("confused", 0);
    }

    if (blob.get_u16("poisoned") > 0) blob.sub_u16("poisoned", 1);
    */
}

void onRender(CSprite@ this)
{
    if (this is null)
        return;

    CBlob@ blob = this.getBlob();
    if (blob is null || !blob.isMyPlayer())
        return;

    CPlayer@ player = blob.getPlayer();
    if (player is null)
        return;

    StatusBar@ bar;
    if (!blob.get("status_bar", @bar))
        return;

    bar.render();
}

// missing some paladin and jester debuffs & sprites, todo
enum StatusType
{
    IGNITED = 0,
    WET = 1,
    FROZEN = 2,
    POISON = 3,
    DAMAGE_BOOST = 4, // damage buff
    FOCUS = 5, // +1 mana regen
    HASTE = 6,
    SLOW = 7,
    AIRBLAST_SHIELD = 8,
    FIREPROOF_SHIELD = 9,
    HEAL = 10,
    MANABURN = 11,
    ENTROPIST_SIDEWIND = 12,
    ENTROPIST_BURN = 13,
    PALADIN_TAU = 14,
    PALADIN_SIGMA = 15,
    PALADIN_OMEGA = 16,
    PALADIN_HOLY_BARRIER = 17,
    PALADIN_HUMILITY = 18,
    PALADIN_MAJESTY = 19,
    PALADIN_WISDOM = 20,
    CONFUSED = 21,
    TOTAL
};

enum StatusSpecific
{
    DEBUFF = 0,
    BUFF = 1,
    HEAL = 2,
    PROTECTION = 3,
    CONTROL = 4,
    OTHER = 5
};

const u8[] TOOLTIPS_SPECIFIC =
{
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
    StatusSpecific::CONTROL // CONFUSED
};

const string[] TOOLTIPS =
{
    "Burning: physical DoT",
    "Wet: vulnerable to Ice and Electricity, resistant to Burning",
    "Frozen: immobilized",
    "Poisoned: magic DoT",
    "Damage Boost: enhanced spells",
    "Focus: +1 mana regeneration",
    "Haste: increased movement speed",
    "Slow: decreased movement speed",
    "Airblast Shield: blasting knockback upon taking damage",
    "Fireproof Shield: immune to Burning",
    "Heal: regenerating health",
    "Manaburn: losing Mana",
    "Entropist Sidewind: ignore collisions, increased movement speed",
    "Entropist Burn: free spells, diminished spell cast time, losing 30 mana per second",
    "Aura (Tau): take less damage and transfer some of it to the linked ally when nearby",
    "Aura (Sigma): restore health instead of mana, increases damage taken, disables mana replenishment at obelisks",
    "Aura (Omega): restore mana upon taking damage, returns some of the damage split between enemies nearby",
    "Hallowed Barrier: decreases damage taken",
    "Humility: disable healing",
    "Majesty: decreased spells cooldown",
    "Wisdom: wipe some of negative effects",
    "Confused: reversed controls"
};

Status@[] makeStatuses()
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

const Vec2f screen_size = getDriver().getScreenDimensions();
const u8 elements_per_row = 5;
const u8 threshold = 5;
const u8 max_fade = 5;
const u16 blink_timing = 210;
const u8 tooltip_focus_time = 7;
f32 df = 0;

Status@[] STATUSES;
class StatusBar
{
    Vec2f pos; // center
    Vec2f render_pos;
    Vec2f dim;
    Vec2f elem_dim;

    bool hiding;
    bool hidden;
    
    f32 hiding_factor;
    string tex_back;

    Status@[] s;
    u8[] active;
    f32 scale;

    f32 bar_dim_factor; 
    Vec2f bar_dim_current;
    Vec2f old_tl;

    StatusBar(Vec2f position, Vec2f dimensions, Vec2f element_dimensions, f32 _scale = 1.0f)
    {
        STATUSES = makeStatuses();
        df = 0.25f * getRenderDeltaTime() * 60.0f; // hack, kag doesnt have a proper delta time on localhost start up

        pos = position;
        render_pos = pos + Vec2f(0, dimensions.y / 2);
        
        dim = dimensions;
        elem_dim = element_dimensions;

        hiding = true;
        hidden = true;

        f32 hiding_factor = 1.0f;
        tex_back = "StatusBack.png";

        scale = _scale;
        active = array<u8>(StatusType::TOTAL, 255); // 255 means not active
        scale = 1.0f;
        
        bar_dim_factor = 0.0f;
        bar_dim_current = dim;
        old_tl = render_pos + Vec2f(elem_dim.x * 2 * scale + elem_dim.x / 2, bar_dim_current.y * scale);
    }

    void tick()
    {
        hiding = s.size() == 0;
        u8 hovered_status = getHoveredStatus();

        // tick all active statuses
        for (u8 i = 0; i < s.size(); i++)
        {
            if (s[i] is null)
                continue;
            
            s[i].active = s[i].duration > 0 || s[i].active_fade > 0;
            if (!s[i].active)
            {
                active[s[i].type] = 255;
                s.removeAt(i);
                rearrangeIndexes(i); // rearrange indexes after removal

                i--;
                continue;
            }

            if (s[i].duration > 1) s[i].duration = Maths::Max(s[i].duration - 1, 1); // fake decrement
            s[i].hover = hovered_status == s[i].type;
            s[i].tick();
        }

        // limit the tick rate of status bar updates
        u32 gt = getGameTime();
        if (gt % threshold != 0)
            return;

        CBlob@ blob = getLocalPlayerBlob();
        if (blob is null)
            return;

        ManaInfo@ manaInfo;
        if (!blob.get("manaInfo", @manaInfo))
            return;
    
        // clear effects / debuffs from despell hook, this hook is supposed to ensure first doesnt break and to update the duration
        s16 burn_timer = blob.get_s16("burn timer");
        u16 wet_timer = blob.get_u16("wet timer");
        u16 freeze_timer = 0; AttachmentPoint@ ap = blob.isAttached() ? blob.getAttachments().getAttachmentPoint("PICKUP2") : null; if (blob.isAttached() && ap !is null && ap.getOccupied() !is null) freeze_timer = ap.getOccupied().getTimeToDie() * 30;
        u16 poison_timer = blob.get_u16("poisoned");
        u16 damage_boost_timer = 0; u32 timer = blob.hasTag("extra_damage") ? blob.get_u32("damage_boost") : 0; if (blob.hasTag("extra_damage") && timer >= gt) damage_boost_timer = timer - gt;
        u16 focus_timer = (blob.get_u16("focus") > MIN_FOCUS_TIME * getTicksASecond() || blob.get_u32("overload mana regen") > getGameTime()) ? 1 : 0;
        u16 haste_timer = blob.get_u16("hastened");
        u16 slow_timer = blob.get_u16("slowed");
        u16 airblast_shield_timer = blob.get_u16("airblastShield");
        u16 fireproof_shield_timer = blob.get_u16("fireProt");
        u16 heal_timer = blob.get_u16("regen");
        u16 manaburn_timer = blob.get_u16("manaburn");
        u16 entropist_sidewind = blob.get_u16("sidewinding");
        u16 burn_state_count = blob.get_bool("burnState") ? 1 : 0;
        u16 paladin_tau_timer = blob.get_u16("dmgconnection");
        u16 paladin_sigma_timer = blob.get_bool("manatohealth") ? 1 : 0; // paladin sigma aura, always active
        u16 paladin_omega_timer = blob.get_bool("damagetomana") ? 1 : 0;
        u16 paladin_barriers_timer = blob.get_u16("hallowedbarrier");
        u16 humility_timer = blob.get_u16("healblock");
        u16 majesty_timer = blob.get_u16("cdreduction");
        u16 wisdom_timer = blob.get_u16("antidebuff");
        u16 confused_timer = blob.get_u16("confused");

        handleStatus(StatusType::IGNITED,                   burn_timer);
        handleStatus(StatusType::WET,                       wet_timer);
        handleStatus(StatusType::FROZEN,                    freeze_timer, true);
        handleStatus(StatusType::POISON,                    poison_timer);
        handleStatus(StatusType::DAMAGE_BOOST,              damage_boost_timer);
        handleStatus(StatusType::FOCUS,                     focus_timer);
        handleStatus(StatusType::HASTE,                     haste_timer);
        handleStatus(StatusType::SLOW,                      slow_timer);
        handleStatus(StatusType::AIRBLAST_SHIELD,           airblast_shield_timer);
        handleStatus(StatusType::FIREPROOF_SHIELD,          fireproof_shield_timer);
        handleStatus(StatusType::HEAL,                      heal_timer);
        handleStatus(StatusType::MANABURN,                  manaburn_timer);
        handleStatus(StatusType::ENTROPIST_SIDEWIND,        entropist_sidewind);
        handleStatus(StatusType::ENTROPIST_BURN,            burn_state_count);
        handleStatus(StatusType::PALADIN_TAU,               paladin_tau_timer);
        handleStatus(StatusType::PALADIN_SIGMA,            paladin_sigma_timer);
        handleStatus(StatusType::PALADIN_OMEGA,             paladin_omega_timer);
        handleStatus(StatusType::PALADIN_HOLY_BARRIER,      paladin_barriers_timer);
        handleStatus(StatusType::PALADIN_HUMILITY,          humility_timer);
        handleStatus(StatusType::PALADIN_MAJESTY,           majesty_timer);
        handleStatus(StatusType::PALADIN_WISDOM,            wisdom_timer);
        handleStatus(StatusType::CONFUSED,                  confused_timer);
    }

    u8 getHoveredStatus()
    {
        Vec2f mouse_pos = getControls().getMouseScreenPos();
        for (u8 i = 0; i < s.size(); i++)
        {
            if (s[i] is null || !s[i].active)
                continue;

            Vec2f tl = s[i].pos;
            Vec2f br = tl + s[i].dim * 2 * s[i].scale;

            if (mouse_pos.x >= tl.x && mouse_pos.x <= br.x && mouse_pos.y >= tl.y && mouse_pos.y <= br.y)
            {
                return s[i].type; // return the type of the hovered status
            }
        }

        return 255; // no status hovered
    }

    void rearrangeIndexes(int _from)
    {
        if (_from < 0 || _from >= s.size())
            return;
        
        for (u8 i = _from; i < s.size(); i++)
        {
            if (s[i] is null)
                continue;

            active[s[i].type] = i; // update the active index for this status type
        }
    }
    
    void handleStatus(u8 type, int duration, bool override_add = false)
    {
        if (duration == 0) // remove
        {
            if (active[type] == 255)
                return; // status not active, nothing to do

            s[active[type]].duration = 0; // set duration to 0 to fade out
            if (s[active[type]].active)
                return;

            s.removeAt(active[type]);
            rearrangeIndexes(active[type]); // rearrange indexes after removal
            active[type] = 255;
        }
        else // add
        {
            if (active[type] == 255 || override_add)
            {
                if (active[type] == 255) s.push_back(STATUSES[type]);
                addStatus(type, duration);
            }
            else
            {
                if (active[type] == 255) return; // status is not active, nothing to do
                s[active[type]].duration = duration; // update duration
            }
        }
    }

    void addStatus(u8 type, int duration)
    {
        Vec2f tl = render_pos - Vec2f(elem_dim.x * 2 * scale + elem_dim.x / 2, bar_dim_current.y * scale);
        f32 x = ((s.size() - 1) % elements_per_row) * elem_dim.x * scale;
        f32 y = Maths::Floor((s.size() - 1) / elements_per_row) * elem_dim.y * scale;
        Vec2f elem_pos = tl + Vec2f(x, y + 4);

        active[type] = s.size() - 1; // index of the newly added status
        s[active[type]].duration = duration;
        s[active[type]].pos = elem_pos; // set position to the element position
    }

    void render()
    {
        hide_or_open();

        if (hidden)
            return;

        f32 mod = s.size() != 0 ? Maths::Ceil((s.size() - 1) / elements_per_row) + 1 : 1;
        bar_dim_factor = Maths::Lerp(bar_dim_factor, mod, df);
        bar_dim_current = Vec2f(dim.x, dim.y * bar_dim_factor);
        
        bar_dim_current.x = Maths::Ceil(bar_dim_current.x);
        bar_dim_current.y = Maths::Ceil(bar_dim_current.y);

        Vec2f offset = Vec2f(elem_dim.x * 2 * scale + elem_dim.x / 2, bar_dim_current.y * scale);
        Vec2f tl = render_pos - offset;
        Vec2f delta_pos = tl - old_tl;
        old_tl = tl;
        Vec2f br = tl + bar_dim_current;

        Tooltip@[] tooltips;

        // draw background
        for (u8 i = 0; i < elements_per_row * mod; i++)
        {
            f32 x = (i % elements_per_row) * elem_dim.x * scale;
            f32 y = Maths::Floor(i / elements_per_row) * elem_dim.y * scale;

            Vec2f elem_pos = tl + Vec2f(x, y + 4);
            GUI::DrawIcon(tex_back, 0, Vec2f(32, 32), elem_pos, scale, scale, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));
        }

        for (u8 i = 0; i < s.size(); i++)
        {
            if (i >= s.size())
                continue; // no status to render in this slot

            if (s[i] is null)
                continue;

            if (!s[i].active)
                continue;

            f32 x = (i % elements_per_row) * elem_dim.x * scale;
            f32 y = Maths::Floor(i / elements_per_row) * elem_dim.y * scale;
            
            Vec2f elem_pos = tl + Vec2f(x, y + 4);

            s[i].pos = s[i].pos == Vec2f_zero ? elem_pos : Vec2f_lerp(s[i].pos, elem_pos, df) + delta_pos;
            s[i].render(s[i].pos, hiding_factor, tooltips);
        }

        // jends (frame borders)
        string jends_tex = "StatusJends.png";
        Vec2f jends_dim = Vec2f(8, 8);
        
        // top
        Vec2f top_left_pos = tl - Vec2f(jends_dim.x * scale, -jends_dim.y * scale / 2);
        Vec2f top_right_pos = Vec2f(br.x - jends_dim.x * scale, top_left_pos.y);

        // middle 
        Vec2f middle_left_pos = top_left_pos + Vec2f(0, jends_dim.y * scale);
        Vec2f middle_right_pos = top_right_pos + Vec2f(0, jends_dim.y * scale);

        // bottom
        Vec2f bottom_left_pos = top_left_pos + Vec2f(0, (bar_dim_current.y - jends_dim.y * 2 * scale));
        Vec2f bottom_right_pos = top_right_pos + Vec2f(0, (bar_dim_current.y - jends_dim.y * 2 * scale));

        f32 height = Maths::Abs(middle_left_pos.y - bottom_left_pos.y);
        f32 scale_y = height / (jends_dim.y * 2);

        GUI::DrawIcon(jends_tex, 0, jends_dim, top_left_pos, scale, scale, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));
        GUI::DrawIcon(jends_tex, 1, jends_dim, top_right_pos, scale, scale, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));
        
        GUI::DrawIcon(jends_tex, 2, jends_dim, middle_left_pos, scale, scale_y, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));
        GUI::DrawIcon(jends_tex, 3, jends_dim, middle_right_pos, scale, scale_y, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));

        GUI::DrawIcon(jends_tex, 4, jends_dim, bottom_left_pos, scale, scale, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));
        GUI::DrawIcon(jends_tex, 5, jends_dim, bottom_right_pos, scale, scale, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));

        // tooltips
        for (u8 i = 0; i < tooltips.size(); i++)
        {
            if (tooltips[i] is null)
                continue;

            tooltips[i].render();
        }
    }

    void hide_or_open()
    {
        if (hiding)
        {
            render_pos = Vec2f_lerp(render_pos, pos + Vec2f(0, bar_dim_current.y), df);
            hiding_factor = Maths::Lerp(hiding_factor, 1.0f, df);
        }
        else
        {
            render_pos = Vec2f_lerp(render_pos, pos, df);
            hiding_factor = Maths::Lerp(hiding_factor, 0.0f, df);
        }

        hidden = hiding_factor >= 0.99f;
    }
};

SColor getTooltipColor(u8 type)
{
    switch (TOOLTIPS_SPECIFIC[type])
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

class Status
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

    Status(u8 _type, Vec2f _dim, string _icon, int _duration, f32 _scale = 1.0f)
    {
        type = _type;
        pos = Vec2f_zero;
        dim = _dim;
        icon = _icon;
        duration = _duration;
        scale = _scale;

        @tooltip = @Tooltip(type, TOOLTIPS[type], Vec2f_zero, dim * scale);
        tooltip_fade = 0;
        cursor_focus_time = 0;
        hover = false;

        active = false;
        active_fade = 0;
        blink_sine = 0.0f;
    }

    void tick()
    {
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
        
        active_fade = Maths::Clamp(active_fade + (duration > 0 ? 1 : -1), 0, max_fade);
        if (duration <= 1 || duration > blink_timing) return;
        
        f32 frequency_speed = 2.0f - Maths::Min(f32(duration) / f32(blink_timing), 1.0f);
        blink_sine = Maths::Sin(f32(duration + 5) * frequency_speed * 0.75f) * 0.5f + 0.5f;
    }

    void render(Vec2f pos, f32 hiding_factor, Tooltip@[] &inout tooltip_fetcher)
    {
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
        if (duration <= 1 || duration > blink_timing) return;

        GUI::DrawRectangle(
            tl,
            br,
            SColor(100 * blink_sine, 255, 255, 255));

        //GUI::DrawRectangle(tl, tl+Vec2f(4,4), SColor(255, 255, 0, 0));
    }
}

class Tooltip
{
    u8 type;
    string text;
    Vec2f pos;
    Vec2f dim;
    f32 fade;
    Vec2f text_dim;

    Tooltip(u8 _type, string _text, Vec2f _pos, Vec2f _dim)
    {
        type = _type;
        text = _text;
        pos = _pos;
        dim = _dim;
        fade = 0.0f;
    }

    void render()
    {
        if (fade <= 0.01f)
            return;

        GUI::SetFont("menu");
        GUI::GetTextDimensions(text, text_dim);
        
        Vec2f tooltip_pos = pos - Vec2f(text_dim.x / 2 - dim.x + 4, text_dim.y + 8);
        GUI::DrawPane(tooltip_pos, tooltip_pos + text_dim + Vec2f(8, 8), SColor(uint8(200 * fade), 55, 55, 55));

        SColor tooltip_col = getTooltipColor(type);
        tooltip_col.setAlpha(uint8(255 * fade));
        GUI::DrawText(text, tooltip_pos + Vec2f(2, 2), tooltip_col);

        GUI::SetFont("default");
    }
};