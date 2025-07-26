#include "Hitters.as";
#include "HittersWW.as";
#include "MagicCommon.as";

const f32 explosion_radius = 24.0f;
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("poison projectile");
	//this.Tag("smashtoparticles_additive");
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().getConsts().bullet = true;
	
	CSprite@ thisSprite = this.getSprite();
	this.getShape().SetGravityScale(1.0f);
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ l = this.getSpriteLayer("l");
	if (l !is null)
	{
		l.animation.frame = this.animation.frame;
	}
}

void onTick(CBlob@ this)
{
	f32 vellen = this.getVelocity().Length();
	if (this.getShape().getElasticity() > 0.1 && vellen <= 0.1f)
		this.Tag("mark_for_death");
	else if (vellen > 0.01f && !this.hasTag("mark_for_death"))
		this.setAngleDegrees(-this.getVelocity().Angle());

	if (this.getTickSinceCreated() == 0)
	{
		this.getSprite().SetZ(100.0f);
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door")
			|| target.getName() == "trap_block") || (target.hasTag("barrier") && target.getTeamNum() != this.getTeamNum()))
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
	
	return (isEnemy(this, blob));
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if ((solid && this.getShape().getElasticity() <= 0.1f)
		|| (blob !is null && blob.hasTag("kill poison spells")))
			this.Tag("mark_for_death");

	if (blob !is null && doesCollideWithBlob(this, blob))
	{
		if (isServer() && isEnemy(this, blob))
		{
			if (blob !is null && isEnemy(this, blob))
		    {
		    	this.server_Hit(blob, this.getPosition(), this.getVelocity(), this.get_f32("damage"), HittersWW::poison, true);
		    }
		}

		this.Tag("mark_for_death");
	} 
}

void onDie(CBlob@ this)
{
	CParticle@ p = ParticleAnimated("ToxicGas.png", 
										this.getPosition(), 
										Vec2f(0, 0), 
										0.0f, 
										1.0f, 
										5, 
										0.0f, 
										false);
	if (p !is null)
	{
		p.Z = 1.0f;
		p.fastcollision = true;
		p.collides = false;
		p.setRenderStyle(RenderStyle::additive);
	}
	sparks(this.getPosition(), 20);
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

		u8 rnd = XORRandom(100);
		SColor col = SColor(255, 0+rnd/2, 255, 55+rnd);
        CParticle@ p = ParticlePixelUnlimited(pos + Vec2f(4,0).RotateBy(XORRandom(360)), vel, col, true);
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
		p.forcecolor = col;
        p.damping = 0.95f;
		p.gravity = Vec2f_zero;
		p.setRenderStyle(RenderStyle::additive);
    }
}
