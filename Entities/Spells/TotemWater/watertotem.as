#include "SplashWater.as";

const f32 heal_radius = 128.0f;
const f32 heal_amount = 0.5f; // 1.0f is 5 HP
const f32 max_charges = 8;
const u32 heal_rate = 75;

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",1500);
    this.set_s32("nextHeal",getGameTime());
    this.Tag("totem");
    this.Tag("cantparry");
    this.set_u8("despelled", 0);
    this.set_u8("spheres", 1);
    this.set_u32("heal_delay", getGameTime()+heal_rate);
    this.set_u16("charge_delay", 180);
    
    this.getSprite().PlaySound("WizardShoot.ogg", 2.0f, 0.75f);
    this.addCommandID("sync");
    if (isClient())
    {
        CBitStream params;
        params.write_bool(true);
        this.SendCommand(this.getCommandID("sync"), params);
    }
    sparks(this.getPosition()-Vec2f(-0.5f,16.5f), 35, Vec2f_zero);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync"))
    {
        bool init = params.read_bool();
        if (init && isServer())
        {
            CBitStream stream;
            stream.write_bool(false);
            stream.write_u16(this.get_u16("charge_delay"));
        }
        else if (!init && isClient())
        {
            u16 val = params.read_u16();
            this.set_u16("charge_delay", val);
        }
    }
}

void onTick(CBlob@ this)
{
    //////////
    if(this.get_u8("despelled") >= 2 || this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }

    u16 charge_delay = this.get_u16("charge_delay");
    if (this.getTickSinceCreated() > charge_delay && this.get_u8("spheres") < max_charges && getGameTime() % charge_delay == 0)
    {
        this.getSprite().PlaySound("WizardShoot.ogg", 1.5f, 1.33f);
        sparks(this.getPosition()-Vec2f(-0.5f,16.5f), 35, Vec2f_zero);
        if (this.get_u8("spheres") == 0) this.set_u32("heal_delay", getGameTime()+heal_rate);
        this.set_u8("spheres", Maths::Min(this.get_u8("spheres")+1, max_charges));
        this.set_u32("had_heal", getGameTime());
    }

    if ((getGameTime()+this.getNetworkID())%5==0 || this.get_u8("spheres") == 0)
    {
        f32 weakest = 9999.0f;
        u16 id = 0;
        CBlob@[] list;
        for (u8 i = 0; i < getPlayersCount(); i++)
        {
            if (getPlayer(i) !is null && getPlayer(i).getBlob() !is null)
            {
                CBlob@ b = getPlayer(i).getBlob();
                if (this.getDistanceTo(b) > heal_radius || b.getTeamNum() != this.getTeamNum()) continue;
                if (b.getHealth() > b.getInitialHealth() - heal_amount) continue;
                if (b.get_u32("watertotem_effect") >= getGameTime() && b.get_u16("watertotem_id") != this.getNetworkID()) continue;

                if (b.getHealth() < weakest)
                {
                    weakest = b.getHealth();
                    id = b.getNetworkID();
                }
            }
        }
        if (id == 0)
            this.set_u32("heal_delay", getGameTime()+heal_rate);
        if (this.get_u32("had_heal")+heal_rate < getGameTime() || this.get_u8("spheres") == 0)
            this.set_u32("circle_effect", getGameTime()+heal_rate);
            
        this.set_u16("follow_id", id);
        if (id != 0 && getGameTime() >= this.get_u32("heal_delay") && this.get_u8("spheres") > 0)
        {
            CBlob@ blob = getBlobByNetworkID(id);
            if (blob !is null)
            {
                if (blob.getHealth() + heal_amount >= blob.getInitialHealth())
                    blob.server_SetHealth(blob.getInitialHealth());
                else
                    blob.server_Heal(heal_amount);

                blob.set_u32("watertotem_effect", getGameTime()+heal_rate+5);
                blob.set_u16("watertotem_id", this.getNetworkID());
                
                this.set_u32("heal_delay", getGameTime()+heal_rate);
                this.set_u32("circle_effect", getGameTime()+heal_rate);
                this.add_u8("spheres", -1);
                sparksv(this.getPosition()-Vec2f(-0.5f,16.5f), 50, Vec2f_zero, Vec2f(0,6).RotateBy(-(blob.getPosition()-this.getPosition()-Vec2f(-0.5f, -16.5f)).Angle()-90));

                this.set_u32("had_heal", getGameTime());

                if (blob.isMyPlayer()) SetScreenFlash(50,0,255,0,0.75f);
                blob.getSprite().PlaySound("Heal.ogg", 0.75f, 1.15f+XORRandom(16)*0.01f);
            }
        }
    }

    if (isClient() && getGameTime() <= this.get_u32("circle_effect")) ////
    {
        u16 id = this.get_u16("follow_id");
        CBlob@ blob = getBlobByNetworkID(id);
        //@blob = @getPlayerByUsername("NoahTheLegend").getBlob(); ////
        if (blob !is null && (blob.get_u16("watertotem_id") == 0 || blob.get_u16("watertotem_id") == this.getNetworkID()))
        {
            if (this.getDistanceTo(blob) > heal_radius || blob.getHealth() > blob.getInitialHealth()-heal_amount)
            {
                this.set_u16("follow_id", 0);
                return;
            }
            //if(blob.isKeyJustPressed(key_down)) this.set_u32("circle_effect", getGameTime()+heal_rate); ////
            bool gt = getGameTime()%2==0;
            for (int i = 1; i <= 60; i++)
	    	{
                bool rotate = i%2==0 && gt;
	    		SColor color = SColor(255,100+(rotate?33:XORRandom(76)),100+(rotate?66:XORRandom(76)), 255);
                
                f32 step = this.get_u32("circle_effect") - getGameTime();

                int deg = getGameTime()%360;
	    		Vec2f pbPos = blob.getPosition() + Vec2f(0, rotate ? -14.0f - (step<25?(25-step)*0.5f:0) : -16.0f+Maths::Min(16, 1*(step < 30 ? 30-step : 0))).RotateBy(i*6+(rotate && step < 25 ? 0 : deg)).RotateBy(
                    heal_rate-step*(step/heal_rate)
                );

	    		CParticle@ pb = ParticlePixelUnlimited( pbPos , Vec2f_zero , color , true );
	    		if (pb !is null)
	    		{
	    			pb.timeout = 2.0f;
	    			pb.gravity = Vec2f_zero;
	    			pb.damping = 0.9;
	    			pb.collides = false;
	    			pb.fastcollision = true;
	    			pb.bounce = 0;
	    			pb.lighting = false;
	    			pb.Z = 500;
	    		}
	    	}
        }
    }
}

void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

void onInit(CSprite@ this)
{
    this.getBlob().set_s32("frame",0);
    this.SetZ(-10.0f);
    this.SetOffset(Vec2f(0, -15.0f));

    for (u8 i = 0; i < max_charges; i++) // 2 front, 2 back orbs
    {
        CSpriteLayer@ orb = this.addSpriteLayer("orb"+i, "watertotem.png", 4, 4);
        if (orb !is null)
        {
            orb.SetRelativeZ(1.0f);
            Animation@ anim = orb.addAnimation("default", 3, true);
            Animation@ animback = orb.addAnimation("defaultback", 3, true);
            if (anim !is null && animback !is null)
            {
                int[] frames = {4,5,6,7};
                int[] framesback = {8,9,10,11};
                anim.AddFrames(frames);
                animback.AddFrames(framesback);

                orb.SetAnimation(anim);
            }
            orb.SetVisible(false);
        }
    }
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    u32 gameTime = getGameTime() + blob.getNetworkID();
    u8 s = blob.get_u8("spheres");

    for (u8 i = 0; i < s; i++) // 2 front, 2 back orbs
    {
        CSpriteLayer@ orb = this.getSpriteLayer("orb"+i);
        if (orb !is null)
        {
            orb.SetVisible(true);
            f32 x = Maths::Round(Maths::Sin((gameTime+i*6) * 0.25f) * 11);
            f32 y = 1 + Maths::Round(-3 + Maths::Cos((gameTime+i*6) * 0.125f) * 6);
    
            Vec2f offset = Vec2f(-0.75f, -13.5f) + Vec2f(x, y);

            if (y < -5.0f || y > 2)
            {
                orb.SetRelativeZ(-1.0f);
                orb.SetAnimation("defaultback");
            }
            else
            {
                orb.SetRelativeZ(1.0f);
                orb.SetAnimation("default");
            }

            orb.SetOffset(offset);
        }
    }
    for (u8 i = s; i < max_charges; i++) // 2 front, 2 back orbs
    {
        CSpriteLayer@ orb = this.getSpriteLayer("orb"+i);
        if (orb !is null)
        {
            orb.SetVisible(false);
        }
    }
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount, Vec2f gravity)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        f32 rand = _sprk_r.NextRanged(50);
        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 125+rand, 150+rand, 255), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.gravity = gravity+Vec2f(0.0f, 0.01f);
        p.timeout = 20 + _sprk_r.NextRanged(15);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.99f;
    }
}
void sparksv(Vec2f pos, int amount, Vec2f gravity, Vec2f velocity = Vec2f(0,0))
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        f32 rand = _sprk_r.NextRanged(50);
        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 125+rand, 150+rand, 255), true );
        if(p is null) return; //bail if we stop getting particles

    	p.collides = false;
        p.velocity = (velocity*(0.5f+XORRandom(26)*0.01f)).RotateBy(XORRandom(21)-10.0f);
		p.gravity = gravity;
        p.timeout = 30 + _sprk_r.NextRanged(15);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.99f;
    }
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 50, Vec2f(0.0f, 0.0f));
    Splash(this, 4, 4, 0, false);
    if (getMap() is null) return;

    CBlob@[] blobs;
    getMap().getBlobsInRadius(this.getPosition(), 80.0f, @blobs);

    for (u16 i = 0; i < blobs.length; i++)
    {
        CBlob@ b = blobs[i];
        if (b is null) continue;
        b.AddForce(Vec2f(0, (Maths::Max(32.0f, 80.0f-(b.getPosition()-this.getPosition()-Vec2f(0,8)).Length())) * 16.0f).RotateBy(-(b.getPosition()-this.getPosition()-Vec2f(0,8)).Angle()-90));
    }
}