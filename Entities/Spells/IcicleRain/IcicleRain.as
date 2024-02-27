
void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u8 delay = this.get_u8("icicle_delay");
	u8 wait_time = this.get_u8("icicle_wait");

    f32 level = float(getGameTime()-this.get_u32("icicle_start"))/float(this.get_u8("icicles")*delay);

    if (isServer() && getGameTime() % delay == 0)
    {
        CBlob@ orb = server_CreateBlob("icicle", this.getTeamNum(), this.getPosition()-Vec2f(0,16));
        if (orb !is null)
        {
            orb.set_Vec2f("moveTo", this.getPosition()-Vec2f(XORRandom(48)-24, XORRandom(48)-24)-Vec2f(0, 32));
            orb.set_u8("wait_time", this.get_u8("icicle_wait"));
            orb.set_u32("launch_time", this.get_u8("icicle_launch_delay")+getGameTime()+this.get_u32("icicles_launched") + this.get_u8("icicle_launch_delay"));
            this.add_u32("icicles_launched", this.get_u8("icicle_launch_delay"));

            orb.set_Vec2f("aimPos", this.getAimPos());
            if (this.get_bool("static"))
            {
                orb.set_Vec2f("aimPos", this.get_Vec2f("icicles_aimPos"));
            }

            orb.SetDamageOwnerPlayer(this.getPlayer());
            orb.server_SetTimeToDie(30.0f);
        }
    }

    if (level >= 1.0f) this.RemoveScript("IcicleRain.as");
}