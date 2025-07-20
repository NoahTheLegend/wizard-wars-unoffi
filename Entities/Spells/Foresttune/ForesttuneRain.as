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
    if (getGameTime() % delay == 0)
    {
        if (isClient())
        {
            sprite.PlaySound("leaf-cast-"+(this.get_u8("launched_foresttune_projectiles") % 3), 0.175f, 1.4f + XORRandom(10) * 0.01f);
        }

        if (isServer())
        {
            this.add_u8("launched_foresttune_projectiles", 1);
            Vec2f aimdir = this.get_Vec2f("foresttune_aimdir");
            Vec2f offset = Vec2f(width - XORRandom(width * 2), 32.0f);

            f32 r = 48.0f;
            Vec2f rand = Vec2f(XORRandom(r) - r/2, XORRandom(r/2) - r/8);
            Vec2f orbpos = this.getPosition() + rand;
            Vec2f dir = aimdir;

            dir.Normalize();

            CBlob@ orb = server_CreateBlob("foresttune", this.getTeamNum(), orbpos);
            if (orb !is null)
            {
                orb.set_u8("count", this.get_u8("launched_foresttune_projectiles"));
                orb.Sync("count", true);

                orb.SetDamageOwnerPlayer(this.getPlayer());
                orb.server_SetTimeToDie(this.get_u8("foresttune_duration"));

                s32 max_side_threshold = 90;
                orb.set_s32("side_threshold", dir.x < 0 ? -max_side_threshold : max_side_threshold);
                orb.set_f32("speed", 6.0f);
                orb.set_f32("damage", this.get_f32("foresttune_damage"));

                orb.setVelocity(dir * orb.get_f32("speed"));
            }
        }
    }

    if (level >= 1.0f)
    {
        this.set_u8("launched_foresttune_projectiles", 0);
        this.RemoveScript("ForesttuneRain.as");
    }
}