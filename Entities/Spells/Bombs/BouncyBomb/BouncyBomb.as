#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("standingup");
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("exploding"); 
	this.Tag("bomb");
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
	CSpriteLayer@ l = sprite.addSpriteLayer("layer", "BouncyBomb.png", 32, 32);
	if (l is null) return;
	l.setRenderStyle(RenderStyle::additive);
	int[] frames = {1, 2, 2, 1, 0};
	Animation@ anim = l.addAnimation("default", 0, false);
	if (anim is null) return;
	anim.AddFrames(frames);

	sprite.SetEmitSound("/Sparkle.ogg");
	sprite.SetEmitSoundSpeed(2.0f);
	sprite.SetEmitSoundVolume(0.5f);
	sprite.SetEmitSoundPaused(false);

	this.Tag("rotate_spritelayers");
	sprite.PlaySound("BombCreate.ogg", 1.0f, 1.35f+XORRandom(21)*0.01f);
}

void onTick(CBlob@ this)
{
	this.SetFacingLeft(false);

	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.getShape().SetGravityScale(1.0f);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 230, 195, 24));
	}

	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();

	if (this.exists("aliveTime"))
	{
		int tsc = this.getTickSinceCreated();
		f32 ttdf = f32(tsc)/(this.get_s32("aliveTime")*30);
		Vec2f offset = Vec2f(-10 + 5*ttdf, -10 + 10 * (ttdf > 0.75f ? (ttdf-0.75f) : 0));
		sparks(this.getPosition() + this.getVelocity() + offset.RotateBy(this.get_f32("angle")), 2);
	}

	int rnd = XORRandom(56);
	f32 count = 5;
	for (u8 i = 0; i < count; i++)
	{
		Vec2f offset = i == 0 ? Vec2f_zero : Vec2f(0.5f, 0).RotateBy(i*(360.0f/(count-1)));
		CParticle@ p = ParticlePixelUnlimited(this.getOldPosition() + offset, Vec2f_zero, SColor(255,200+rnd,200+rnd,200+rnd), true);
    	if(p is null) return;

    	p.collides = false;
    	p.timeout = 30;
    	p.Z = -20.0f;
    	p.gravity = Vec2f_zero;
	}

	CSpriteLayer@ l = sprite.getSpriteLayer("layer");
	if (l is null) return;
	l.ResetTransform();
	l.setRenderStyle(RenderStyle::additive);
	l.SetFacingLeft(this.isFacingLeft());
	l.animation.frame = sprite.animation.frame;
	l.SetRelativeZ(-10.0f);
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && ((target.hasTag("door") && target.isCollidable()) || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
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
			sprite.PlaySound("GumBounce"+XORRandom(3)+".ogg", 0.75f, 1.0f + XORRandom(11)*0.01f);
			sprite.SetAnimation("collide");
			sprite.animation.timer = 0;
			sprite.animation.frame = 0;

			CSpriteLayer@ l = sprite.getSpriteLayer("layer");
			if (l !is null)
			{
				l.animation.frame = sprite.animation.frame;
			}
		}
	}

	if (solid)
	{
		if (blob is null)
		{
			if (isServer() && this.getVelocity().Length() > 50.0f)
				this.server_Die();
			else
				this.AddForce(Vec2f(this.getMass(), 0).RotateBy(-normal.Angle()));
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
		smoke(this.getPosition(), 10);
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
				this.server_Hit(b, pos, Vec2f_zero, this.get_f32("damage"), Hitters::explosion, isOwnerBlob(this, b));
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
        Vec2f vel(6.0f + _smoke_r.NextFloat() * 6.0f, 0);
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