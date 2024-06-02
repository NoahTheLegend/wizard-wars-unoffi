#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("standingup");
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("exploding"); 
	this.Tag("die_in_divine_shield");
	this.set_f32("damage", 0.0f);

	this.set_f32("explosive_radius", 0.0f);
	this.set_f32("explosive_damage", 0.0f);
	this.set_f32("map_damage_radius", 32.0f);
	this.set_f32("map_damage_ratio", 0.25f);
	this.set_string("custom_explosion_sound", "Whack"+(1+XORRandom(3))+".ogg");
	this.set_f32("explosion_pitch", 1.5f+XORRandom(21)*0.01f);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;
	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(-15.0f);

	sprite.SetEmitSound("/Sparkle.ogg");
	sprite.SetEmitSoundSpeed(1.5f);
	sprite.SetEmitSoundVolume(0.5f);
	sprite.SetEmitSoundPaused(false);

	this.server_SetTimeToDie(4);
	this.set_s32("aliveTime", this.getTimeToDie());
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.getShape().SetGravityScale(1.0f);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 230, 195, 24));
		this.getSprite().PlaySound("BombCreate.ogg", 1.0f, 1.0f);
	}

	if (!isClient()) return;

	if (this.exists("aliveTime"))
	{
		int tsc = this.getTickSinceCreated();
		f32 ttdf = f32(tsc)/(this.get_s32("aliveTime")*30);
		Vec2f offset = Vec2f(-10 + 5*ttdf, -11 + 11 * (ttdf > 0.75f ? (ttdf-0.75f) : 0));
		sparks(this.getPosition() + this.getVelocity() + offset.RotateBy(this.get_f32("angle")), 2);
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
		||
		(
			target.getPlayer() !is null
			&& target.getPlayer() is this.getDamageOwnerPlayer()
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(this is null || blob is null)
	{return false;}

	if (this.hasTag("no_spike_collision") && blob.hasTag("projectile")) return false;
	return 
	( 
		blob.hasTag("standingup")
		||
		(
			blob.hasTag("barrier") && blob.getTeamNum() != this.getTeamNum()
		)
	);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if(this is null)
	{return;}

	bool blobDeath = false;

	if (isClient() && ((solid && blob is null) || (blob !is null && this.doesCollideWithBlob(blob))))
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.PlaySound("BombBounce.ogg", 1.0f, 1.0f + XORRandom(11)*0.01f);
		}
	}

	if (solid)
	{
		if (blob is null)
		{
			if (isServer() && (this.hasTag("die_on_collide") || this.getVelocity().Length() > 50.0f))
				this.server_Die();
		}
	}

	if(blob !is null && isEnemy(this, blob))
	{
		blobDeath = true;
	}

	if(blobDeath)
	{this.server_Die();}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();

	if (isClient())
	{
		makeSmokePuff(this);
		smoke(this.getPosition(), 20);
	}
	
	if (isServer())
	{
		CMap@ map = getMap();
		if(map is null)
		{return;}

		CBlob@[] aoeBlobs;

		map.getBlobsInRadius(pos, this.get_f32("explode_radius"), @aoeBlobs);
		for (u16 i = 0; i < aoeBlobs.length(); i++)
		{
			CBlob@ b = aoeBlobs[i]; //standard null check for blobs in radius
			if (b is null)
			{continue;}

			if (!isEnemy(this, b))
			{continue;}
			
			if (!map.rayCastSolidNoBlobs(pos, b.getPosition()))
			{
				f32 dmg = this.get_f32("damage");
				if (b.getPlayer() !is null && b.getPlayer() is this.getDamageOwnerPlayer())
					dmg *= 0.25f;

				this.server_Hit(b, pos, Vec2f_zero, dmg, Hitters::explosion, isOwnerBlob(this, b));
			}
		}
	}
}

void makeSmokePuff(CBlob@ this, const f32 velocity = 1.0f)
{
	Vec2f vel = Vec2f_zero;
	makeSmokeParticle(this, vel);
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	const f32 rad = 2.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	{
		CParticle@ p = ParticleAnimated("GenericBlast6.png", 
										this.getPosition(), 
										vel, 
										float(XORRandom(360)), 
										1.0f, 
										2, 
										0.0f, 
										false );
		if (p !is null)
		{
			p.bounce = 0;
			p.scale = 3.0f;
    		p.fastcollision = true;
			p.Z = 30.0f;
			p.setRenderStyle(RenderStyle::additive);
		}
	}
	{
		CParticle@ p = ParticleAnimated("GenericBlast5.png", 
										this.getPosition(), 
										vel, 
										float(XORRandom(360)), 
										1.0f, 
										2, 
										0.0f, 
										false );
		if (p !is null)
		{
			p.bounce = 0;
			p.scale = 2.0f;
    		p.fastcollision = true;
			p.Z = 20.0f;
		}
	}
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(5.0f + _smoke_r.NextFloat() * 5.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke"+(3+XORRandom(2))+".png").getFirst(), 
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
		p.setRenderStyle(RenderStyle::additive);
    }
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	//easy check
	if (this.getDamageOwnerPlayer() is target.getPlayer())
	{
		return true;
	}
	return false;
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true);
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(10);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.85f;
		p.gravity = Vec2f(0, -0.5f);
    }
}