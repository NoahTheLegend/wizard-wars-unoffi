

const u8 charge_delay = 2;
const u8 activation_delay = 10;

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    if (this.get_u32("spikeburst_start") <= getGameTime()+5 && !this.hasTag("done"))
    {
        for (u8 i = 0; i < Maths::Min(24,this.get_u8("spikes")); i++)
        {
            CSpriteLayer@ spike = sprite.addSpriteLayer("spike"+i, "SpikeOrb.png", 8, 8);
            if (spike is null) return;
                    spike.SetVisible(false);
            spike.SetOffset(Vec2f(0, 14.0f).RotateBy(i*float(360/this.get_u8("spikes"))));
            spike.RotateBy(XORRandom(360), Vec2f(0,0));
            spike.SetRelativeZ(5.5f);
        }
        this.set_u32("spikeburst_activation", 0);
        this.Tag("done");
        return;
    }
    
    f32 level = float(getGameTime()-this.get_u32("spikeburst_start"))/float(this.get_u8("spikes")*charge_delay);

    for (u8 i = 0; i < Maths::Min(24,Maths::Floor(this.get_u8("spikes")*level)); i++)
    {
        CSpriteLayer@ spike = sprite.getSpriteLayer("spike"+i);
        if (spike !is null)
        {
            f32 rot = i*float(360/this.get_u8("spikes"));
            if (!spike.isVisible()) sprite.PlaySound("Rubble" + (XORRandom(2) + 1) + ".ogg", 0.85f, 1.15f);
            spike.SetFacingLeft(true);
            spike.SetVisible(true);
            spike.RotateBy(2, Vec2f(0,0));
            spike.SetOffset(Vec2f(0, 14.0f).RotateBy(rot));
        }
    }

    if (level >= 1.0f)
    {
        if (this.get_u32("spikeburst_activation") == 0)
        {
            this.set_u32("spikeburst_activation", getGameTime()+activation_delay);
        }
        if (this.get_u32("spikeburst_activation") > getGameTime()) return;
        

        if (isServer())
        {
            for (u8 i = 0; i < Maths::Min(24,this.get_u8("spikes")); i++)
            {
                CBlob@ orb = server_CreateBlob("spikeorb", this.getTeamNum(), this.getPosition()-Vec2f(0,2));
                if (orb !is null)
                {
                    orb.Tag("die_on_collide");
                    orb.Tag("no_spike_collision");
                    orb.setVelocity(Vec2f(0, -8).RotateBy(i*float(360/this.get_u8("spikes")))-Vec2f(0,2));
                    orb.SetDamageOwnerPlayer(this.getPlayer());
                }
            }
        }

        for (u8 i = 0; i < Maths::Min(24,Maths::Floor(this.get_u8("spikes")*level)); i++)
        {
            sprite.RemoveSpriteLayer("spike"+i);
        }
        this.RemoveScript("SpikeBurst.as");
    }
    this.Untag("done");
}