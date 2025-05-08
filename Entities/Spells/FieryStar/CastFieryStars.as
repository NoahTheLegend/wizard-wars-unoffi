
void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    bool caster = this.getName() == "fierystarcaster";
    u32 start_time = this.get_u32("fierystars_time");
    u8 max = this.get_u8("fierystars_amount");
    u8 delay = this.get_u8("fierystars_delay");
    u8 current = this.get_u8("fierystars_current");
    f32 fluctuation_factor = this.get_f32("fierystars_fluctuation_factor");

    Vec2f aimPos;
    if (!caster)
    {
        aimPos = this.getAimPos();
    }
    else
    {
        aimPos = this.get_Vec2f("aimpos");
    }
    Vec2f thisPos = this.getPosition();

    if ((getGameTime() - start_time) % delay == 0 || current == max)
    {
        this.set_u8("fierystars_current", current-1);
        if (isServer())
        {
            CBlob@ orb = server_CreateBlob("fiery_star", this.getTeamNum(), thisPos+Vec2f(0,8).RotateBy(-(aimPos-thisPos).Angle()-90));
            if (orb !is null)
            {
                orb.setAngleDegrees(-(aimPos-thisPos).Angle()+90);
                orb.set_f32("speed", this.get_f32("fierystars_speed"));
                orb.set_f32("damage", this.get_f32("fierystars_damage"));
                orb.set_f32("fluctuation_factor", fluctuation_factor);
                orb.set_bool("left", current % 2 == 0);
                orb.SetDamageOwnerPlayer(this.getPlayer() !is null ? this.getPlayer() : this.getDamageOwnerPlayer());

                if (caster) orb.Tag("instantly_collide");
                orb.server_SetTimeToDie(1.5f);
            }
        }
    }
    if (current <= 0)
    {
        this.RemoveScript("Castfierystars.as");

        if (caster)
            this.Tag("mark_for_death");
    }
}