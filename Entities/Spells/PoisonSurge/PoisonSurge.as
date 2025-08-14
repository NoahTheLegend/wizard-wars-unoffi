#include "Hitters.as";
#include "HittersWW.as";
#include "MagicCommon.as";
#include "SpellUtils.as";

const f32 explosion_radius = 32.0f;
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("kill other spells");
	this.Tag("counterable");
	this.Tag("poison projectile");

	this.set_u32("sound_at", 0);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().SetGravityScale(0.0f);
	
	CSprite@ thisSprite = this.getSprite();
	CSpriteLayer@ l = thisSprite.addSpriteLayer("l", "PoisonSurge.png", 24, 16);
	if (l !is null)
	{
		l.ScaleBy(Vec2f(0.95f, 0.95f));

		Animation@ anim = l.addAnimation("default", 0, false);
		if (anim !is null)
		{
			int[] frames = {0,1,2,3};
			anim.AddFrames(frames);
			
			l.SetAnimation(anim);
			l.setRenderStyle(RenderStyle::additive);
			l.SetRelativeZ(-0.5f);
		}
	}
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
	if (this.exists("vel") && this.get_Vec2f("vel") != Vec2f_zero)
	{
		this.setVelocity(this.get_Vec2f("vel"));
		this.set_Vec2f("vel", Vec2f_zero);
	}

	if (isServer())
	{
		if (this.getVelocity().Length() > 0.01f && !this.hasTag("mark_for_death"))
			this.setAngleDegrees(-this.getVelocity().Angle());
		else this.Tag("mark_for_death");
		if (this.hasTag("mark_for_death")) this.setVelocity(Vec2f_zero);
	}

	if (this.getTickSinceCreated() == 0)
	{
		CSprite@ sprite = this.getSprite();
		sprite.PlaySound("PoisonSurge"+XORRandom(3)+".ogg", 1.5f, 1.2f + XORRandom(11) * 0.01f);
		sprite.SetZ(-1.0f);
		sprite.SetRelativeZ(-1.0f);
	}

	if (this.getTickSinceCreated() > 8)
	{
		this.Tag("no_bounce");
	}

	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	if (getGameTime() % 1 == 0 && this.getTickSinceCreated() > 3)
    {
        CParticle@ p = ParticleAnimated("PoisonSurgeParticle.png", this.getPosition(), Vec2f_zero, this.getAngleDegrees(), 1.0f, 5, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
			p.fastcollision = true;
			p.timeout = 30;
            p.growth = -0.05f;
	    	p.Z = -1.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
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

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f p1)
{
	if (solid || (blob !is null && blob.hasTag("kill poison spells")))
	{
		bool bounce = !this.hasTag("no_bounce");
		if (!bounce)
		{
			this.Tag("no_shrapnel");
			this.Tag("mark_for_death");
		}
		else
		{
			if (this.get_u32("sound_at") + 5 < getGameTime())
			{
				this.set_u32("sound_at", getGameTime());
				this.getSprite().PlaySound("PoisonSurgeReflect.ogg", 0.5f, 0.9f + XORRandom(11) * 0.01f);
			}
		}
	}

	if (blob !is null && isEnemy(this, blob))
	{
		this.Tag("no_shrapnel");
		this.Tag("mark_for_death");
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("SplatExplosion.ogg", 1.5f, 1.0f+XORRandom(11) * 0.01f);
	Boom(this);
	sparks(this.getPosition(), 50);
}

void Boom(CBlob@ this)
{
	makeSmokeParticle(this);
	if (!isServer()) return;

	CBlob@[] bs;
	getMap().getBlobsInRadius(this.getPosition(), explosion_radius, @bs);

	CPlayer@ owner = this.getDamageOwnerPlayer();
	CBlob@ hitter = owner !is null && owner.getBlob() !is null ? owner.getBlob() : null;

	for (int i = 0; i < bs.length; i++)
	{
		CBlob@ blob = bs[i];
		if (blob !is null && ((hitter !is null && blob is hitter) || isEnemy(this, blob) || blob.hasTag("plant")))
		{
			Vec2f dir = blob.getPosition() - this.getPosition();
			f32 dir_len = dir.Length();

			dir.Normalize();
			dir *= explosion_radius * 2 - dir_len;
			
			this.server_Hit(blob, this.getPosition(), dir, this.get_f32("damage"), Hitters::explosion, true);
			Poison(blob, this.get_u32("poison_time"), hitter);
		}
	}

	if (this.hasTag("no_shrapnel"))
	{
		return;
	}

	u8 shrapnel_count = this.get_u8("shrapnel_count");
	u8 angle = this.get_u8("shrapnel_angle");
	if (shrapnel_count > 0)
	{
		for (int i = 0; i < shrapnel_count; i++)
		{
			Vec2f vel = Vec2f(8, 0).RotateBy(this.getAngleDegrees() + -angle * 0.5f + (i * (angle / (shrapnel_count - 1))));
			vel.y -= 2.0f;
			
			CBlob@ shrapnel = server_CreateBlob("poisonsurgeshrapnel", this.getTeamNum(), this.getPosition());
			if (shrapnel !is null)
			{
				if (this.hasTag("shrapnel_bouncy"))
				{
					shrapnel.getShape().setElasticity(0.33f);
					shrapnel.getShape().setFriction(0.25f + XORRandom(51) * 0.01f);
				}

				shrapnel.setVelocity(vel);
				shrapnel.set_f32("damage", this.get_f32("shrapnel_damage"));
				shrapnel.server_SetTimeToDie(3);
			}
		}
	}
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel = Vec2f_zero, const string filename = "Smoke")
{
	const f32 rad = 2.0f;
	Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64) * 0.015625f * rad;
	{
		CParticle@ p = ParticleAnimated("GenericBlast5.png", 
										this.getPosition(), 
										vel, 
										float(XORRandom(360)), 
										1.0f + XORRandom(50) * 0.01f,
										5, 
										0.0f, 
										false);

		if (p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			p.colour = SColor(255, 55+XORRandom(25), 255, 55+XORRandom(25));
			p.forcecolor = SColor(255, 55+XORRandom(25), 255, 55+XORRandom(25));
			p.setRenderStyle(RenderStyle::additive);
			p.Z = 1.5f;
		}
	}
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
        CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
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
