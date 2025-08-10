void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    f32 pitch = 0.55f;

    u32 gt = getGameTime();
    u32 cast_time = this.get_u32("shadowburst_cast_time");
    u8 period = this.get_u8("shadowburst_period");

    int diff = gt - cast_time;
    bool cast_blob = diff % period == 0;

    u8 max_count = this.get_u8("shadowburst_count");
    u8 count = this.get_u8("shadowburst_current_count");
    f32 level = float(count) / float(max_count);

    if (cast_blob) this.set_u8("shadowburst_current_count", count + 1);
    if (diff % period == 0) sprite.PlaySound("ShadowBurstCast.ogg", 1.0f, pitch + XORRandom(11) * 0.01f);

    CSpriteLayer@ castFront = sprite.getSpriteLayer("shadowburst_front");
    CSpriteLayer@ castBack = sprite.getSpriteLayer("shadowburst_back");

    if (isClient())
    {
        if (castFront is null)
        {
            @castFront = @sprite.addSpriteLayer("shadowburst_front", "ShadowBurst.png", 64, 48);
            
            Animation@ anim = castFront.addAnimation("default", 2, false);
            int[] frames = {0, 1, 2, 3, 3, 4, 5, 6, 7, 8, 9};
            anim.AddFrames(frames);
            castFront.SetAnimation(anim);
            castFront.SetRelativeZ(75.0f);
        }
        
        if (castBack is null)
        {
            @castBack = @sprite.addSpriteLayer("shadowburst_back", "ShadowBurstBackLayer.png", 64, 48);
            Animation@ anim = castBack.addAnimation("default", 2, false);
            int[] frames = {0, 1, 2, 3, 3, 4, 5, 6, 7, 8, 9};
            anim.AddFrames(frames);
            castBack.SetAnimation(anim);
            castBack.SetRelativeZ(-0.1f);
        }

        if (castFront !is null && castBack !is null)
        {
            if (this.hasTag("shadowburst_cast"))
            {
                castFront.animation.frame = 0;
                castBack.animation.frame = 0;

                this.Untag("shadowburst_cast");
            }
            
            Vec2f pos = this.getPosition();
            Vec2f aimpos = this.getAimPos();
            Vec2f dir = aimpos - pos;
            f32 angle = dir.Angle();

            castFront.ResetTransform();
            castBack.ResetTransform();

            bool fl = this.isFacingLeft();
            castFront.SetFacingLeft(fl);
            castBack.SetFacingLeft(fl);

            Vec2f offset = Vec2f(-12, 0);
            if (fl)
            {
                angle += 180;
            }

            s8 fs = (fl ? -1 : 1);
            castFront.RotateBy(-angle, -offset * fs);
            castBack.RotateBy(-angle, -offset * fs);

            castFront.SetOffset(offset);
            castBack.SetOffset(offset);

            if (cast_blob)
            {
                if (count < max_count)
                {
                    this.Tag("shadowburst_cast");
                }

                sprite.PlaySound("ShadowBurstShoot.ogg", 1.0f, pitch + XORRandom(11) * 0.01f);
            }
        }
    }

    if (isServer())
    {
        if (cast_blob)
        {
            CBlob@ orb = server_CreateBlob("shadowburstorb", this.getTeamNum(), this.getPosition());
            if (orb !is null)
            {
                Vec2f dir = this.getAimPos() - this.getPosition();
                dir.Normalize();

                orb.SetDamageOwnerPlayer(this.getPlayer());
                orb.setVelocity(dir * this.get_f32("shadowburst_speed"));
                orb.set_f32("damage", this.get_f32("shadowburst_damage"));
                orb.server_SetTimeToDie(2.0f + XORRandom(25) * 0.01f);
            }
        }
    }

    if (level >= 1.0f)
    {
        this.RemoveScript("ShadowBurstCast.as");

        sprite.RemoveSpriteLayer("shadowburst_front");
        sprite.RemoveSpriteLayer("shadowburst_back");
    }
}