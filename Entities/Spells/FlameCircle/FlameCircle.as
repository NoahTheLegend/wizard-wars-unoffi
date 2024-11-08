#include "Hitters.as";

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");

    this.SetLightRadius(effectRadius);
    this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);
}

const int effectRadius = 10*10;

void onTick(CBlob@ this)
{
    if (this.isInWater()) this.Tag("reverse");
    bool fullCharge = this.hasTag("fullCharge");
    bool reverse = this.hasTag("reverse");

    if((!this.hasTag("finished") || reverse) && getGameTime() % 4 == 0)
    {
        this.add_u8("frame", reverse ? -1 : 1);
        if(this.get_u8("frame") == 11)
        {
            this.Tag("finished");
        }
    }

    if(reverse && this.get_u8("frame") < 1) this.server_Die();
    if(!this.hasTag("finished") || reverse) return;

    Vec2f pos = this.getInterpolatedPosition();
    CMap@ map = getMap();
    CBlob@[] blobs;
    map.getBlobsInRadius(pos,effectRadius,@blobs);

    if(getGameTime() % (fullCharge ? 5 : 10) == 0 && !this.hasTag("reverse"))
    {
        for(float i = 0; i < blobs.length; i++)
        {
            CBlob@ b = blobs[i];
            if (b is null || b.hasTag("burning")) continue;
            if (b.exists("fireProt") && b.get_u16("fireProt") > 0) continue;
            if (b.isInWater()) continue;
            
            if((b.getName() != "skeleton" && b.getName() != "zombie" && b.getName() != "zombieknight" && b.getPlayer() is null ) || b.getTeamNum() == this.getTeamNum()) continue;
            Vec2f bPos = b.getInterpolatedPosition();

            Vec2f norm = bPos-pos;
            norm.Normalize();

            this.getSprite().PlaySound("flame_slash_sound", 1.5f, 1.35f + XORRandom(26)*0.01f);
            if(getNet().isServer())
            {
                uint8 t = 11;
                float dmg = 0.5f;
                b.server_Hit(b, bPos, Vec2f(0,0), dmg,Hitters::hits::fire);
            }
        }
    }
}

void onInit(CSprite@ this)
{
    this.ScaleBy(Vec2f(0.25f, 0.25f));
    this.setRenderStyle(RenderStyle::additive);
    //{
    //    CSpriteLayer@ s = this.addSpriteLayer("circle", "team_color_circle.png", 100, 100);
    //    s.setRenderStyle(RenderStyle::Style::light);
    //    s.ScaleBy(Vec2f(1.562f, 1.562f));
    //    s.SetRelativeZ(-2);
    //}
    {
        CSpriteLayer@ s = this.addSpriteLayer("l0","flameCircleLayers.png",200,200);
        s.SetRelativeZ(55);

        Animation@ anim = s.addAnimation("default", 0, false);
        if (anim !is null)
        {
            anim.AddFrame(0);
            s.SetAnimation(anim);
        }
    }
    {
        CSpriteLayer@ s = this.addSpriteLayer("l1","flameCircleLayers.png",200,200);
        s.SetRelativeZ(56);

        Animation@ anim = s.addAnimation("default", 0, false);
        if (anim !is null)
        {
            anim.AddFrame(1);
            s.SetAnimation(anim);
        }
    }
    {
        CSpriteLayer@ s = this.addSpriteLayer("l2","flameCircleLayers.png",200,200);
        s.SetRelativeZ(57);

        Animation@ anim = s.addAnimation("default", 0, false);
        if (anim !is null)
        {
            anim.AddFrame(2);
            s.SetAnimation(anim);
        }
    }
    {
        CSpriteLayer@ s = this.addSpriteLayer("l3","flameCircleLayers.png",200,200);
        s.SetRelativeZ(58);

        Animation@ anim = s.addAnimation("default", 0, false);
        if (anim !is null)
        {
            anim.AddFrame(3);
            s.SetAnimation(anim);
        }
    }
    {
        CSpriteLayer@ s = this.addSpriteLayer("l4","flameCircleLayers.png",200,200);
        s.SetRelativeZ(59);

        Animation@ anim = s.addAnimation("default", 0, false);
        if (anim !is null)
        {
            anim.AddFrame(4);
            s.SetAnimation(anim);
        }
    }

    this.RotateBy(XORRandom(360), Vec2f_zero);
    for (u8 i = 0; i < 5; i++)
    {
        CSpriteLayer@ l = this.getSpriteLayer("l"+i);
        if (l !is null)
        {
            l.RotateBy(XORRandom(360), Vec2f_zero);
            l.SetVisible(false);
            l.setRenderStyle(RenderStyle::additive);
        }
    }

    this.PlaySound("flame_slash_sound.ogg", 3.0f, 0.55f+XORRandom(11)*0.01f);
}

Random _rnd(53124); //with the seed, I extract a float ranging from 0 to 1 for random events

void onTick(CSprite@ this)
{
    bool reverse = this.getBlob().hasTag("reverse");
    CBlob@ b = this.getBlob();

    if (b.getTickSinceCreated() <= 44)
    {
        f32 n = 1.0320082797342096;
        this.ScaleBy(Vec2f(n,n));
    }

    bool hide = false;
    if(b.get_u8("frame") != 11 || reverse)
    {
        this.SetFrame(b.get_u8("frame"));
        hide = true;
    }

    if(isClient())
    {
        float pRot = 220.0f * (f32(b.get_u8("frame")) / 11.0f);
        Vec2f pVel = Vec2f_zero;
        f32 gt = getGameTime();
        for(int i = 0; i < (v_fastrender ? 15 : 30); i++) //particle splash
        {
            pRot = 360.0f * _rnd.NextFloat();
            pVel = Vec2f(2.5f*(1.0f + _rnd.NextFloat()), 0 );
            pVel.RotateByDegrees(pRot);
            u16 pTimeout = 10 * _rnd.NextFloat();

            CParticle@ p = ParticlePixelUnlimited(b.getPosition() + Vec2f(Maths::Sin(gt*0.1f)*8, 0).RotateBy((gt * 2.0f) % 360), b.getVelocity() + pVel, SColor(255, 200+XORRandom(55), 55+XORRandom(155), 25+XORRandom(25)), true);
            if(p !is null)
            {
                p.gravity = Vec2f(0,0);
                p.collides = false;
                p.bounce = 0;
                p.fastcollision = true;
                p.damping = 0.95f;
                p.timeout = pTimeout + 30;
                p.setRenderStyle(RenderStyle::additive);
                p.Z = 205.0f;
            }
        }
    }

    {
        f32 speed = b.hasTag("fullCharge") ? 4 : 3;
        speed *= Maths::Min(1.5f, b.getTickSinceCreated() / 30.0f);

        this.RotateByDegrees(speed / (b.get_u8("despelled") + 1) ,Vec2f(0,0));
        if (reverse) this.ScaleBy(Vec2f(0.935f, 0.935f));

        u16 netid = b.getNetworkID();
        for (u8 i = 0; i < 2; i++)
        {
            CSpriteLayer@ l = this.getSpriteLayer("l"+i);
            if (l !is null)
            {
                if (!hide) l.SetVisible(true);
                l.RotateBy(speed - i*2, Vec2f_zero);
                if (reverse) l.ScaleBy(Vec2f(0.935f, 0.935f));
            }
        }
    }
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("flame_slash_sound.ogg", 3.5f, 0.6f);
    blast(this.getPosition(), 1, 1.0f);
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount, f32 scale = 1.0f)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel = Vec2f_zero;

        CParticle@ p = ParticleAnimated(CFileMatcher("Implosion1.png").getFirst(), 
									pos, 
									vel, 
									0, 
									scale, 
									2, 
									0.0f, 
									false);
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = true;
        p.setRenderStyle(RenderStyle::additive);
    }
}