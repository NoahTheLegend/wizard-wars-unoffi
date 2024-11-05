void onInit(CBlob@ this)
{
    this.set_u8("despelled",0);
    this.Tag("multi_despell");
    this.Tag("projectile");

    this.getShape().getConsts().mapCollisions = false;
    this.getShape().SetGravityScale(0.0f);
    this.getSprite().SetZ(525.0f);

    this.set_Vec2f("origin", this.getPosition());
    this.SetFacingLeft(true);
    this.setAngleDegrees(180);
    this.getShape().SetRotationsAllowed(false);

    this.set_u32("next", getGameTime() + spawn_rate + XORRandom(spawn_rate+1));
}

const f32 amplitude_time = 0.075f;
const Vec2f amplitude = Vec2f(80.0f, 12.5f);
const u16 spawn_rate = 15;
u8 min_blobs = 3;
u8 rnd_blobs = 1;

void onTick(CBlob@ this)
{
    if (this.get_u8("despelled") >= 2)
        this.server_Die();

    Vec2f origin = this.get_Vec2f("origin");
    u32 t = (getGameTime() + this.getNetworkID());
    f32 gt = t * amplitude_time;
    this.setPosition(Vec2f_lerp(this.getPosition(), origin + Vec2f(amplitude.x * Maths::Sin(gt), amplitude.y * Maths::Sin(2 * gt)), 0.33f));

    if (this.get_u32("next") < t && this.getTickSinceCreated() > spawn_rate)
    {
        this.set_u32("next", t + spawn_rate + XORRandom(spawn_rate+1));
        this.setPosition(this.getPosition()+Vec2f(0,6));

        if (isClient())
        {
            CSprite@ sprite = this.getSprite();
            sprite.SetAnimation("shoot");

            for (u8 i = 0; i < 10+XORRandom(5); i++)
            {
                CParticle@ p = ParticleAnimated(CFileMatcher("GenericSmoke2.png").getFirst(), 
									this.getPosition() - Vec2f(0,8), 
									Vec2f(2-XORRandom(41)*0.1f+(this.getPosition().x - this.getOldPosition().x)/2, -6 - XORRandom(3) - Maths::Abs(this.getVelocity().y)/2), 
									float(XORRandom(360)), 
									1.0f, 
									3+XORRandom(2), 
									0.5f, 
									false);

                if (p is null) continue;

            	p.collides = false;
                p.scale = 1.0f + XORRandom(51)*0.01f;
                p.growth = -0.005f;
		        p.Z = 550.0f;
		        p.lighting = true;
                p.deadeffect = -1;
		        p.setRenderStyle(RenderStyle::additive);
            }            
        }
        if (isServer())
        {
            for (u8 i = 0; i < min_blobs + XORRandom(rnd_blobs+1); i++)
            {
                u8 rnd = XORRandom(100);
                string bname = rnd < 20 ? "bouncybomb" : rnd < 90 ? "jesterbomb" : "healorb";
                CBlob@ blob = server_CreateBlob(bname, this.getTeamNum(), this.getPosition());
                if (blob !is null)
                {
                    blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
                    blob.setVelocity(Vec2f(3-XORRandom(61)*0.1f+(this.getPosition().x - this.getOldPosition().x)/3, -6 - XORRandom(3) - Maths::Abs(this.getVelocity().y)/2));

                    blob.Tag("die_on_collide");
                    blob.set_f32("damage", 1.0f);
                    blob.set_f32("explode_radius", 32.0f);

                    if (bname != "healorb")
                        blob.server_SetTimeToDie(2.0f+XORRandom(6)*0.1f);
                }
            }
        }
    }

    string source = "TophatParticle.png";
    #ifdef STAGING
    source = "TophatParticle_staging.png";
    #endif

    if (isClient())
    {
        CParticle@ p = ParticleAnimated(source, this.getPosition() - Vec2f(0,8), Vec2f_zero, 180, 0.75f, 2, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
            p.growth = -0.025f;
	    	p.Z = -1.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
    }
}

void onDie(CBlob@ this)
{
    string source = "TophatParticle.png";
    #ifdef STAGING
    source = "TophatParticle_staging.png";
    #endif
    
    this.getSprite().PlaySound("ObsessedSpellDie.ogg", 1.0f, 1.0f+XORRandom(11)*0.01f);

    for (u8 i = 0; i < 10+XORRandom(5); i++)
    {
        if (isClient())
        {
            CParticle@ p = ParticleAnimated(source, this.getPosition() - Vec2f(0,8), Vec2f(0, -6-XORRandom(5)).RotateBy(XORRandom(360)), 180 + (45 - XORRandom(91)), 1.0f, 2+XORRandom(3), 0.0f, true);
	        if (p !is null)
	        {
	        	p.bounce = 0;
            	p.collides = false;
                p.growth = -0.025f;
	        	p.Z = -1.0f;
	        	p.gravity = Vec2f_zero;
                p.damping = 0.925f + XORRandom(51)*0.001f;
	        	p.deadeffect = -1;
                p.setRenderStyle(RenderStyle::additive);
	        }
        }
    }
}

void onTick(CSprite@ this)
{
    if (this.isAnimationEnded() && this.animation !is null
        && this.animation.name == "shoot")
    {
        this.SetAnimation("default");
    }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return false;
}