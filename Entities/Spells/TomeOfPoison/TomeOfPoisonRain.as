const f32 radius = 86.0f;
const f32 min_radius = 32.0f;
const f32 width = 32.0f;

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u8 delay = this.get_u8("tomepoison_delay");
	u8 wait_time = this.get_u8("tomepoison_wait");

    u8 projectiles = this.get_u8("tomepoison_projectiles");
    f32 level = float(getGameTime()-this.get_u32("tomepoison_start"))/float(projectiles*delay);
    if (isServer() && getGameTime() % delay == 0)
    {
        this.add_u8("launched_tomepoison_projectiles", 1);
        Vec2f aimpos = this.get_Vec2f("tomepoison_aimpos");
        Vec2f offset = Vec2f(width - XORRandom(width * 2), -64.0f);

        Vec2f orbpos = aimpos + offset;
        CBlob@ orb = server_CreateBlob("poisonarrow", this.getTeamNum(), orbpos);
        if (orb !is null)
        {
            orb.set_u8("count", this.get_u8("launched_tomepoison_projectiles"));
            orb.Sync("count", true);
            
            orb.set_Vec2f("target_pos", orbpos + Vec2f(-offset.x / 2, 64.0f + XORRandom(64)));
            orb.SetDamageOwnerPlayer(this.getPlayer());
            orb.server_SetTimeToDie(3.0f);

            orb.set_f32("speed", this.hasTag("extra_damage") ? 7.5f : 6.0f);
            orb.set_f32("damage", this.get_f32("tomepoison_damage"));

            orb.Sync("target_pos", true);
            orb.Sync("speed", true);
        }
    }

    if (level >= 1.0f)
    {
        this.set_u8("launched_tomepoison_projectiles", 0);
        this.RemoveScript("TomeOfPoisonRain.as");
    }
}