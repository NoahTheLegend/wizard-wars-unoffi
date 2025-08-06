#define CLIENT_ONLY

#include "StatusCommon.as";
#include "MagicCommon.as";
#include "PaladinCommon.as";

const u8 threshold = 5;
void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null)
        return;

    u8 dr = 0;
    if (blob.getName() == "necromancer") dr = 1;
    if (blob.getName() == "druid") dr = 2;
    if (blob.getName() == "swordcaster") dr = 3;
    if (blob.getName() == "entropist") dr = 4;
    if (blob.getName() == "priest") dr = 5;
    if (blob.getName() == "shaman") dr = 6;
    if (blob.getName() == "paladin") dr = 7;
    if (blob.getName() == "jester") dr = 8;
    if (blob.getName() == "warlock") dr = 9;
    blob.set_u8("disabled_row", dr);

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
    Vec2f screen_size = getScreenSize();
    u8 elements_per_row = getElementsPerRow();

    Vec2f elem_dim = getElementDimensions();
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

enum SPELL_INDEX
{
    BURN,
    WET,
    FREEZE,
    POISON,
    DAMAGE_BOOST,
    FOCUS,
    HASTE,
    SLOW,
    AIRBLAST_SHIELD,
    FIREPROOF_SHIELD,
    HEAL,
    MANABURN,
    ENTROPIST_SIDEWIND,
    ENTROPIST_BURN_STATE,
    PALADIN_TAU,
    PALADIN_SIGMA,
    PALADIN_OMEGA,
    PALADIN_BARRIERS,
    HUMILITY,
    MAJESTY,
    WISDOM,
    CONFUSED
};

u8[][] disabled_for_classes =
        {
            {}, // wizard
            {}, // necromancer
            {}, // druid
            {}, // swordcaster
            {}, // entropist
            {}, // priest
            {}, // shaman
            {}, // paladin
            {}, // jester
            {5} // warlock
        };

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

        u8 disabled_row = blob.get_u8("disabled_row");

        u16 poison = blob.get_u16("poisoned");

        // clear effects / debuffs from despell hook, this hook is supposed to ensure first doesnt break and to update the duration
        s16 burn_timer = blob.get_s16("burn timer");
        u16 wet_timer = blob.get_u16("wet timer");
        u16 freeze_timer = 0; AttachmentPoint@ ap = blob.isAttached() ? blob.getAttachments().getAttachmentPoint("PICKUP2") : null; if (blob.isAttached() && ap !is null && ap.getOccupied() !is null) freeze_timer = ap.getOccupied().getTimeToDie() * 30;
        u16 poison_timer = poison > 10 ? poison : poison != 0 ? 1 : 0;
        u16 damage_boost_timer = 0; u32 timer = blob.hasTag("extra_damage") ? blob.get_u32("damage_boost") : 0; if (blob.hasTag("extra_damage") && timer >= gt) damage_boost_timer = timer - gt;
        u16 focus_timer = disabled_for_classes[disabled_row].find(SPELL_INDEX::FOCUS) != -1 ? 0 : (blob.get_u16("focus") > MIN_FOCUS_TIME * getTicksASecond() || blob.get_u32("overload mana regen") > getGameTime()) ? 1 : 0;
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
        u8 elements_per_row = getElementsPerRow();
        
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

        u8 elements_per_row = getElementsPerRow();
        f32 df = getDeltaFactor();
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
        RenderTooltips(tooltips);
    }

    void hide_or_open()
    {
        f32 df = getDeltaFactor();

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