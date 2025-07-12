
void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u8 delay = this.get_u8("poisonarrow_delay");
	u8 wait_time = this.get_u8("poisonarrow_wait");

    f32 level = float(getGameTime()-this.get_u32("poisonarrow_start"))/float(this.get_u8("poisonarrows")*delay);

    if (isServer() && getGameTime() % delay == 0)
    {
        this.add_u8("launched_poisonarrows", 1);

        Vec2f orbpos = this.getPosition() + Vec2f(24 - XORRandom(48), 24 - XORRandom(48));
        CBlob@ orb = server_CreateBlob("poisonarrow", this.getTeamNum(), orbpos);
        if (orb !is null)
        {
            orb.set_u8("count", this.get_u8("launched_poisonarrows"));
            orb.Sync("count", true);

            Vec2f dir = this.get_Vec2f("poisonarrow_aimpos");
            Vec2f len = dir - this.getPosition();
            if (len.Length() < 48)
            {
                len.Normalize();
                dir += len * 48;
            }

            Vec2f extra_dir = dir - orbpos;

            extra_dir.Normalize();
            extra_dir *= 8 * this.get_u8("launched_poisonarrows");

            if (extra_dir.Length() > dir.Length() - 48) extra_dir = Vec2f_zero;

            orb.set_Vec2f("target_pos", dir - extra_dir);

            orb.SetDamageOwnerPlayer(this.getPlayer());
            orb.server_SetTimeToDie(5.0f);

            orb.set_f32("speed", this.hasTag("extra_damage") ? 10.0f : 8.0f);
            orb.set_f32("damage", this.get_f32("poisonarrow_damage"));

            orb.Sync("target_pos", true);
            orb.Sync("speed", true);
        }
    }

    if (level >= 1.0f)
    {
        this.set_u8("launched_poisonarrows", 0);
        this.RemoveScript("PoisonArrowRain.as");
    }
}