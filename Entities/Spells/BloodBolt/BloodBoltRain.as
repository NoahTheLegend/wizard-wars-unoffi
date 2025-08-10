void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u8 delay = this.get_u8("bloodbolt_delay");
	u8 wait_time = this.get_u8("bloodbolt_wait");

    f32 level = f32(getGameTime()-this.get_u32("bloodbolt_start")) / f32(this.get_u8("bloodbolts") * delay);
    if (isServer() && getGameTime() % delay == 0)
    {
        this.add_u8("launched_bloodbolts", 1);

        Vec2f dir = this.get_Vec2f("bloodbolt_aimpos") - this.getPosition();
        f32 angle = -(dir - this.getPosition()).Angle();
        Vec2f offset = Vec2f(2 - XORRandom(4), 2 - XORRandom(4));

        Vec2f orbpos = this.getPosition() + offset;
        CBlob@ orb = server_CreateBlob("bloodbolt", this.getTeamNum(), orbpos);
        if (orb !is null)
        {
            orb.set_u8("count", this.get_u8("launched_bloodbolts"));
            orb.Sync("count", true);
            orb.set_Vec2f("dir", dir);

            orb.SetDamageOwnerPlayer(this.getPlayer());
            orb.server_SetTimeToDie(2.0f);

            orb.set_f32("damage", this.get_f32("bloodbolt_damage"));
            orb.set_f32("acceleration", this.hasTag("extra_damage") ? 16 : 12);
            orb.set_u32("acceleration_tsc_mod", 30);
            orb.set_f32("max_speed", 24.0f);
        }
    }

    if (level >= 1.0f)
    {
        this.set_u8("launched_bloodbolts", 0);
        this.RemoveScript("BloodBoltRain.as");
    }
}
