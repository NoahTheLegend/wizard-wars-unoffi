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
    StatusBar bar(Vec2f(screen_size.x / 2, screen_size.y), size, elem_dim);
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
    
    if (getControls().isKeyJustPressed(KEY_KEY_R))
    {
        StatusBar newbar(Vec2f(screen_size.x / 2, screen_size.y), bar.dim, bar.elem_dim);
        blob.set("status_bar", @newbar);
    }

    if (getControls().isKeyJustPressed(KEY_LCONTROL)) bar.hiding = !bar.hiding;
    if (getControls().isKeyJustPressed(KEY_KEY_H))
    {
        blob.set_u16("poisoned", 240);
        blob.set_u16("wet timer", 9000);
        blob.set_s16("burn timer", 9000);
        blob.set_u16("hastened", 9000);
        blob.set_u16("slowed", 9000);
        blob.set_u16("airblastShield", 9000);
    }
    else if (getControls().isKeyJustPressed(KEY_KEY_J))
    {
        blob.set_u16("poisoned", 0);
        blob.set_u16("wet timer", 0);
        blob.set_s16("burn timer", 0);
        blob.set_u16("hastened", 0);
        blob.set_u16("slowed", 0);
        blob.set_u16("airblastShield", 0);
    }

    if (blob.get_u16("poisoned") > 0) blob.sub_u16("poisoned", 1);
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
const u8 max_fade = 5; // max fade in/out time
const u16 blink_timing = 210;
f32 df = 0;

Status@[] STATUSES = makeStatuses();
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
            s[i].hover = false; // reset hover state
            s[i].tick();
        }

        u8 hovered_status = getHoveredStatus();
        print(""+getControls().getInterpMouseScreenPos()+" "+hovered_status);
        if (hovered_status < StatusType::TOTAL)
        {
            if (active[hovered_status] != 255)
                s[active[hovered_status]].hover = true;
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
        u16 burn_state_count = blob.get_bool("burnState") ? manaInfo.mana / 30.0f + 1 : 0;
        u16 paladin_tau_timer = blob.get_u16("dmgconnection");

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
    }

    u8 getHoveredStatus() // todo: fix
    {
        Vec2f mouse_pos = getControls().getMouseScreenPos();
        for (u8 i = 0; i < s.size(); i++)
        {
            if (s[i] is null || !s[i].active)
                continue;

            Vec2f tl = s[i].pos;
            Vec2f br = tl + s[i].dim * s[i].scale;

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
        
        f32 mod = Maths::Ceil(s.size() / elements_per_row) + 1;
        
        bar_dim_factor = Maths::Lerp(bar_dim_factor, mod - 1, df);
        bar_dim_current = Vec2f(dim.x, dim.y + dim.y * bar_dim_factor);
        
        bar_dim_current.x = Maths::Ceil(bar_dim_current.x);
        bar_dim_current.y = Maths::Ceil(bar_dim_current.y);

        Vec2f offset = Vec2f(elem_dim.x * 2 * scale + elem_dim.x / 2, bar_dim_current.y * scale);
        Vec2f tl = render_pos - offset;
        Vec2f delta_pos = tl - old_tl;
        old_tl = tl;
        Vec2f br = tl + bar_dim_current;

        // draw background
        for (u8 i = 0; i < elements_per_row * mod; i++)
        {
            f32 x = (i % elements_per_row) * elem_dim.x * scale;
            f32 y = Maths::Floor(i / elements_per_row) * elem_dim.y * scale;

            Vec2f elem_pos = tl + Vec2f(x, y + 4);
            GUI::DrawIcon(tex_back, 0, Vec2f(32, 32), elem_pos, scale, scale, SColor(255 * (1.0f - hiding_factor), 255, 255, 255));

            if (i >= s.size())
                continue; // no status to render in this slot

            if (s[i] is null)
                continue;

            if (!s[i].active)
                continue;

            s[i].pos = s[i].pos == Vec2f_zero ? elem_pos : Vec2f_lerp(s[i].pos, elem_pos, df) + delta_pos;
            s[i].render(s[i].pos, hiding_factor);
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
    TOTAL
};

const string[] TOOLTIPS =
{
    "Burning - physical DoT",
    "Wet - Vulnerable to Ice and Electricity",
    "Frozen - Immobilized",
    "Poisoned - Magic DoT",
    "Damage Boost - Enhanced spells",
    "Focus - +1 mana regeneration",
    "Haste - Increased movement speed",
    "Slow - Decreased movement speed",
    "Airblast Shield - Blasting knockback upon taking damage",
    "Fireproof Shield - Immune to Burning",
    "Heal - Regenerating health",
    "Manaburn - Losing Mana",
    "Entropist Sidewind - Ignores collisions, Increased movement speed",
    "Entropist Burn - Free spells, Diminished spell cast time, Losing 30 mana per second",
    "Paladin Tau - take "+(connection_dmg_reduction * 100)+"% less damage and transfer "+(connection_dmg_transfer * 100)+"% of initial\ndamage to the linked ally when nearby"
};

class Status
{
    u8 type;
    Vec2f pos;
    Vec2f dim;
    string icon;
    int duration;
    f32 scale;

    string tooltip;
    u8 active_tooltip_fade;
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

        active = false;
        active_fade = 0;
        blink_sine = 0.0f;
    }

    void tick()
    {
        active_fade = Maths::Clamp(active_fade + (duration > 0 ? 1 : -1), 0, max_fade);
        if (duration <= 1 || duration > blink_timing) return;
        
        f32 frequency_speed = 2.0f-Maths::Min(f32(duration) / f32(blink_timing), 1.0f);
        blink_sine = Maths::Sin(f32(duration) * frequency_speed * 0.5f) * 0.5f + 0.5f;

        if (hover)
        {
            active_tooltip_fade = Maths::Clamp(active_tooltip_fade + 1, 0, max_fade);
            cursor_focus_time = 0; // reset cursor focus time
        }
        else
        {
            active_tooltip_fade = Maths::Clamp(active_tooltip_fade - 1, 0, max_fade);
            cursor_focus_time++;
        }
    }

    void render(Vec2f pos, f32 hiding_factor)
    {
        f32 mod = 1.0f - scale;
        f32 fade = f32(active_fade) / f32(max_fade);

        Vec2f tl = pos + (dim - dim * mod) / 2;
        Vec2f br = tl + dim * scale;

        GUI::DrawIcon("StatusSlot.png", 1, Vec2f(32, 32), pos + Vec2f(32, 32) * mod / 2, scale, scale, SColor(255 * fade * (1.0f - hiding_factor), 255, 255, 255));
        GUI::DrawIcon(icon, type, dim, tl, scale / 2, SColor(255 * fade * (1.0f - hiding_factor), 255, 255, 255));
        
        blink(tl, br);
    }

    void blink(Vec2f tl, Vec2f br)
    {
        if (duration <= 1 || duration > blink_timing) return;

        GUI::DrawRectangle(
            tl,
            br,
            SColor(125 * blink_sine, 255, 255, 255));

        //GUI::DrawRectangle(tl, tl+Vec2f(4,4), SColor(255, 255, 0, 0));
    }
}