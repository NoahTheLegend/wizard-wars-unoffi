
void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u32 start_time = this.get_u32("magicarrows_time");
    u8 max = this.get_u8("magicarrows_amount");
    u8 delay = this.get_u8("magicarrows_delay");
    u8 current = this.get_u8("magicarrows_current");

    Vec2f aimPos = this.getAimPos();
    Vec2f thisPos = this.getPosition();

    if (getGameTime() % delay == 0)
    {
        this.set_u8("magicarrows_current", current-1);
        if (isServer())
        {
            CBlob@ orb = server_CreateBlob("magicarrow", this.getTeamNum(), thisPos+Vec2f(0,8).RotateBy(-(aimPos-thisPos).Angle()-90));
            if (orb !is null)
            {
                orb.setAngleDegrees(-(aimPos-thisPos).Angle()+90);
                orb.set_f32("damage", this.get_f32("magicarrows_damage"));
                orb.SetDamageOwnerPlayer(this.getPlayer());

                orb.server_SetTimeToDie(5.0f);
            }
        }
    }
    if (current <= 0) this.RemoveScript("CastMagicArrows.as");
}