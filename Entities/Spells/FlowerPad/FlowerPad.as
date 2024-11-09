#include "Hitters.as"

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",900);
    this.Tag("counterable");
    this.Tag("totem");
    
    this.getSprite().SetZ(-10.0f);
    this.set_u16("smashtoparticles_probability", 1);
    this.SetFacingLeft(false);
    this.getSprite().setRenderStyle(RenderStyle::additive);
    this.addCommandID("spawn_gas");
}

void onTick(CBlob@ this)
{
    if(this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }

    if (isClient())
    {
        f32 time = 15;
        CSprite@ sprite = this.getSprite();
        sprite.SetOffset(Vec2f(0, -7 + Maths::Clamp(Maths::Round(16.0f * (1.0f-this.getTickSinceCreated()/10.0f)*10.0f)/time, 0, 16)));
    }

    if (isClient() && !this.hasTag("prep"))
    {
        this.Tag("prep");

        CSprite@ sprite = this.getSprite();
        sprite.setRenderStyle(RenderStyle::normal);

        for (u8 i = 0; i < 50 + XORRandom(100); i++)
        {
            CParticle@ p = makeGibParticle("GenericGibsVanilla", this.getPosition()+Vec2f(XORRandom(48)-24, XORRandom(32)-16), getRandomVelocity(100, 1 , 270), 
		    	7, 3 + XORRandom(4), Vec2f(8, 8), 1.0f, 0, "", 0);
            if (p !is null)
		    {
		    	p.gravity = Vec2f(0, 0.05f);
                p.timeout = 45+XORRandom(30);
		    }
        }
    }

    CMap@ map = getMap();
    if (map is null) return;

    CBlob@[] bs;
    getBlobsByTag("player", @bs);
    for (u8 i = 0; i < bs.size(); i++)
    {
        bool was_hit = false;

        CBlob@ b = bs[i];
        if (b is null) continue;

        Vec2f bpos = b.getPosition();
        Vec2f bvel = b.getVelocity();
        f32 angle = (-bvel).Angle();
        if (angle > 180 || angle < 1
            || ((bvel.Length() < 4.0f || bpos.y >= this.getPosition().y - 8)
                && (!b.isKeyPressed(key_up) || bvel.Length() < 2.0f))
                || (b.isKeyPressed(key_down) && !b.isKeyPressed(key_right) && !b.isKeyPressed(key_left))) continue;

        HitInfo@[] infos;
        map.getHitInfosFromRay(b.getPosition(), angle, bvel.Length() * 1.25f, b, infos);

        for (u16 j = 0; j < infos.size(); j++)
        {
            HitInfo@ info = infos[j];
            if (info is null) continue;

            if (info.blob is this)
                was_hit = true;
        }

        if (was_hit)
        {
            if (isClient())
            {
                CSprite@ sprite = this.getSprite();
                sprite.PlaySound("GrassWiggleWeak.ogg", Maths::Clamp(bvel.Length()/6, 1.0f, 2.0f), 0.9f + XORRandom(31)*0.01f);
                if (bvel.Length() >= 12.0f)
                    sprite.PlaySound("GrassWiggleStrong.ogg", 1.0f, 1.5f + XORRandom(21)*0.01f);

                sprite.animation.frame = 0;
                sprite.animation.timer = 0;
                sprite.SetAnimation("bounce");

                sparks(this.getPosition() - Vec2f(1.5f,8), Maths::Clamp(bvel.Length()*3, 10, 50), bvel);

                for (u8 i = 0; i < bvel.Length(); i++)
                {
                    CParticle@ p = makeGibParticle("GenericGibsVanilla", this.getPosition()+Vec2f(XORRandom(32)-16, XORRandom(8)), getRandomVelocity(100, 1 , 270), 
	                	7, 3 + XORRandom(4), Vec2f(8, 8), 1.0f, 0, "", 0);
                    if (p !is null)
	                {
	                	p.gravity = Vec2f(0, 0.05f);
                        p.timeout = 30+XORRandom(11);
	                }
                }
            }

            b.setVelocity(Vec2f(bvel.x, -b.getOldVelocity().y));
            if (b.isKeyPressed(key_up))
                b.AddForce(Vec2f(0,-(b.getMass() * Maths::Sqrt(b.getOldVelocity().Length()))));

            if (b.getTeamNum() != this.getTeamNum())
            {
                this.getSprite().PlayRandomSound("gasleak", 0.75f, 1.15f+XORRandom(26)*0.01f);
                if (isClient() && getLocalPlayerBlob().isMyPlayer())
                {
                    CBitStream params;
                    this.SendCommand(this.getCommandID("spawn_gas"), params);
                }
            }
        }
    }
}

void onInit(CShape@ this)
{
    this.SetStatic(true);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount, Vec2f bvel)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel = Vec2f(0, -1 - XORRandom(21)*0.1f);
        vel.RotateBy(-12+XORRandom(25));

        CParticle@ p = ParticlePixelUnlimited( pos + Vec2f(XORRandom(21)*0.1f, 0), vel, SColor( 255, 200+XORRandom(55), 25+XORRandom(55), 155+XORRandom(100)), true );
        if(p is null) return;

    	p.fastcollision = true;
		p.gravity = Vec2f(0.0f, 0.02f);
        p.timeout = 30 + _sprk_r.NextRanged(30);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.9f+XORRandom(Maths::Clamp(bvel.Length()*8, 11, 101))*0.001f;
    }
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	ParticlesFromSprite(this.getSprite());
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if(this.getCommandID("spawn_gas") == cmd)
    {    
        if (isServer())
        {
            for (u8 i = 0; i < 1 + XORRandom(3); i++)
            {
                CBlob@ orb = server_CreateBlob("jestergas");
	    	    if (orb !is null)
	    	    {
	    	    	orb.set_s8("hits", 1);
                    orb.set_f32("dmg", 0.2f);
                    orb.set_u8("ignore_time", 20+XORRandom(11));
	    	    	orb.IgnoreCollisionWhileOverlapped(this);
	    	    	orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
	    	    	orb.server_setTeamNum(this.getTeamNum());
	    	    	orb.setPosition(this.getPosition()-Vec2f(0,10));
	    	    	orb.setVelocity(Vec2f(0, -1-XORRandom(11)*0.1f).RotateBy(-20+XORRandom(41)));
	    	    	orb.server_SetTimeToDie(5+XORRandom(3));
	    	    }
            }
        }
    }
}