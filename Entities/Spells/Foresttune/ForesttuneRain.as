const f32 radius = 86.0f;
const f32 min_radius = 32.0f;
const f32 width = 32.0f;

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u8 delay = this.get_u8("foresttune_delay");
	u8 wait_time = this.get_u8("foresttune_wait");

    u8 projectiles = this.get_u8("foresttune_projectiles");
    f32 level = float(getGameTime()-this.get_u32("foresttune_start"))/float(projectiles*delay);
    if (isServer() && getGameTime() % delay == 0)
    {
        this.add_u8("launched_foresttune_projectiles", 1);
        Vec2f aimpos = this.get_Vec2f("foresttune_aimpos");
        Vec2f offset = Vec2f(width - XORRandom(width * 2), 32.0f);

        Vec2f orbpos = aimpos + offset;
        CBlob@ orb = server_CreateBlob("foresttune", this.getTeamNum(), orbpos);
        if (orb !is null)
        {
            orb.set_u8("count", this.get_u8("launched_foresttune_projectiles"));
            orb.Sync("count", true);
            
            orb.set_Vec2f("target_pos", orbpos - Vec2f(0, 32.0f + XORRandom(64)));
            orb.SetDamageOwnerPlayer(this.getPlayer());
            orb.server_SetTimeToDie(3.0f);

            orb.set_f32("speed", this.hasTag("extra_damage") ? 7.5f : 6.0f);
            orb.set_f32("damage", this.get_f32("foresttune_damage"));

            orb.Sync("target_pos", true);
            orb.Sync("speed", true);
        }
    }

    if (level >= 1.0f)
    {
        this.set_u8("launched_foresttune_projectiles", 0);
        this.RemoveScript("ForesttuneRain.as");
    }
}