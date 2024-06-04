#include "Hitters.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = true;
	consts.bullet = false;

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	shape.SetGravityScale( 0.375f );

	this.set_u8("lavadrop_time", 75);
	this.set_u8("lavadrop_amount", 4);

	this.set_f32("damage", 1.0f);

	this.getSprite().SetZ(9.5f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(10);

	CSprite@ sprite = this.getSprite();
	sprite.ScaleBy(Vec2f(1.15f, 1.15f));
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated()==0)
	{
		this.getSprite().PlaySound("FireBlast4.ogg", 0.75f, 0.85f + XORRandom(16)*0.01f);
		this.getSprite().PlaySound("flame_slash_sound", 0.85f, 0.85f);
	}

	this.setAngleDegrees(Maths::Clamp(0, 360, -this.getVelocity().Angle()));
	//prevent leaving the map
	
	Vec2f pos = this.getPosition();
	if ( pos.x < 0.1f ||
	pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

	CMap@ map = getMap();
	if (map is null)
	{return;}

	if (isServer())
	{
		if (this.getTickSinceCreated() > 15 && getGameTime()%this.get_u8("lavadrop_time")==0)
		{
			CBlob@ b = server_CreateBlob("lavadrop", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			}
		}
	}

	if(!isClient())
	{return;}

	{
		makeSmokePuff(this);
		if (getGameTime()%3==0) smoke(this.getPosition()-this.getVelocity(), 1, 3.0f);
	}

	for(int i = 0; i < 3; i ++)
	{
		float randomPVel = XORRandom(16) * 0.01f - 0.75f;
		Vec2f particleVel = Vec2f( randomPVel, 0).RotateByDegrees(this.getAngleDegrees()+(XORRandom(151)-75.0f));

    	CParticle@ p = ParticlePixelUnlimited(this.getPosition()+Vec2f(0, 1).RotateByDegrees(this.getAngleDegrees()), particleVel, SColor(255,255,75+XORRandom(76),XORRandom(51)), true);
   		if(p !is null)
    	{
    	    p.collides = false;
    	    p.gravity = Vec2f_zero;
    	    p.bounce = 1;
    	    p.lighting = false;
    	    p.timeout = 20+XORRandom(11);
			p.damping = 0.95;
    	}
	}
}

void onTick(CSprite@ this) //rotating sprite
{
	CBlob@ b = this.getBlob();
	
	if(this is null || b is null)
	{return;}
}

void Shatter(CBlob@ this, Vec2f normal)
{
	if (this.hasTag("dead")) return;
	if (!isServer()) return;
	for (u8 i = 0; i < this.get_u8("lavadrop_amount"); i++)
	{
		CBlob@ b = server_CreateBlob("lavadrop", this.getTeamNum(), this.getPosition());
		if (b !is null)
		{
			b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			b.setVelocity((normal*(XORRandom(6)+3)).RotateBy(XORRandom(251)-125.0f));
			b.getShape().SetGravityScale(0.75f);
		}
	}
	this.Tag("dead");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{	
	if (blob !is null && this !is null)
	{
		if (isEnemy(this, blob) || doesCollideWithBlob(this, blob))
		{
			Shatter(this, normal);
			this.setVelocity(Vec2f_zero);
			this.server_Die();
		}
	}
	else if (solid && blob is null)
	{
		Shatter(this, normal);
		this.setVelocity(Vec2f_zero);
		this.server_Die();
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 6.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericBlast5.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 0.75f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void onDie( CBlob@ this )
{
	#ifndef STAGING
	if (isClient())
	{
		this.getSprite().PlaySound("MolotovExplosion.ogg", 1.0f, 0.65f+XORRandom(26)*0.01f);
		blast(this.getPosition()-this.getVelocity()-Vec2f(0,8), 10);
		smoke(this.getPosition()-this.getVelocity(), 5);	
	}
	#endif
	if(!this.hasTag("exploding"))
	{
		return;
	}	

	Vec2f thisPos = this.getPosition();
	//Vec2f othPos = blob.getPosition();
	//Vec2f kickDir = othPos - selfPos;

	float damage = this.get_f32("damage");

	CMap@ map = getMap();
	if (map is null)
	{return;}

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(this.getPosition(), 32.0f, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		if (blobsInRadius[i] is null)
		{
			continue;
		}

		CBlob@ radiusBlob = blobsInRadius[i];

		CPlayer@ player = this.getDamageOwnerPlayer();
		if(player !is null)
		{
			CBlob@ caster = player.getBlob();
			if(caster !is null && radiusBlob is caster)
			{
				this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::fire, true);
				continue;
			}
		}

		if (radiusBlob.getTeamNum() == this.getTeamNum())
		{
			continue;
			}

		this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::fire, false);
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(
			target.hasTag("barrier") || (target.hasTag("flesh") && !target.hasTag("dead") )
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(this is null || blob is null)
	{return false;}

	if (blob.getShape() !is null && blob.getShape().isStatic())
	{
		if (blob.hasTag("door") && blob.isCollidable())
		{
			return true;
		}
		
		ShapePlatformDirection@ plat = blob.getShape().getPlatformDirection(0);
		if (plat !is null)
		{
			Vec2f pos = this.getPosition();
			Vec2f bpos = blob.getPosition();

			Vec2f dir = plat.direction;
			if ((dir.x > 0 && pos.x > bpos.x)
				|| (dir.x < 0 && pos.x < bpos.x)
				|| (dir.y > 0 && pos.y > bpos.y)
				|| (dir.y < 0 && pos.y < bpos.y))
			{
				return true;
			}
		}
	}

	return false;
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if( !getNet().isClient() ) 
		return;
	//warn("making smoke");

	const f32 rad = 4.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "RocketFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 300.0f;
	}
	
	//warn("smoke made");
}

void makeSmokePuff(CBlob@ this, const f32 velocity = 3.0f, const int smallparticles = 10, const bool sound = true)
{
	f32 randomness = (XORRandom(24) + 24)*0.015625f * 0.5f + 0.75f;
	Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
	makeSmokeParticle(this, vel);
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount, f32 vellen = 6.0f)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(vellen + _smoke_r.NextFloat() * vellen, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 1.0f + _smoke_r.NextFloat()*0.5f;
        p.damping = 0.8f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}