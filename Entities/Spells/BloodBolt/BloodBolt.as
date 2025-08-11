#include "Hitters.as";
#include "TeamColour.as";
#include "SpellUtils.as";

void onInit(CBlob@ this)
{
	this.getSprite().PlaySound("swordsummon.ogg", 0.75f, 1.25f+XORRandom(21)*0.01f);
	this.getSprite().PlaySound("glaiveswipe.ogg", 0.75f, 1.75f+XORRandom(21)*0.01f);

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.bullet = true;
	consts.net_threshold_multiplier = 2.0f;

	this.Tag("projectile");
	this.Tag("counterable");

	shape.SetGravityScale(0.0f);
	this.set_f32("lifetime",0);

	this.SetMapEdgeFlags(CBlob::map_collide_none);
    this.server_SetTimeToDie(3);

	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	
	sprite.SetZ(750.0f);
	//sprite.setRenderStyle(RenderStyle::additive);

	CSpriteLayer@ l = sprite.addSpriteLayer("BloodBolt.png", 16, 16);
	if (l !is null)
	{
		l.SetRelativeZ(751.0f);
		l.setRenderStyle(RenderStyle::additive);
	}
}

const f32 ticks_noclip = 5;
void onTick(CBlob@ this)
{
	bool has_solid = this.getShape().isOverlappingTileSolid(true);
	if (!this.hasTag("solid") && getMap() !is null && !has_solid)
	{
		this.getShape().getConsts().mapCollisions = true;
		if (has_solid) this.Tag("mark_for_death");
		this.Tag("solid");
	}

	Vec2f pos = this.getPosition();
	Vec2f target_pos = this.get_Vec2f("target_pos");

	SColor col = SColor(155+XORRandom(55), 125+XORRandom(55), 10+XORRandom(25), 0);
	if (this.getTeamNum() == 0) col = SColor(155+XORRandom(55), 10+XORRandom(25), 0, 125+XORRandom(55));

	Vec2f vel = this.getVelocity();
	Vec2f dir = this.getTickSinceCreated() < 3 ? this.get_Vec2f("dir") : vel;
	f32 dist = dir.Length();
	dir.Normalize();

	f32 accel_mod = Maths::Clamp(f32(this.getTickSinceCreated()) / f32(this.get_u32("acceleration_tsc_mod")), 0.0f, 1.0f);
	f32 accel = this.get_f32("acceleration") * accel_mod;

	if (vel.Length() < this.get_f32("max_speed")) this.AddForce(dir * accel);
	if (vel.Length() >= 0.1f) this.setAngleDegrees(-this.getVelocity().Angle());

	// particles
	if (isClient() && this.getTickSinceCreated() == 1)
	{
		f32 circle_amo = v_fastrender ? 15 : 30;
		for (u8 i = 0; i < circle_amo; i++)
		{
			Vec2f offset = Vec2f(8,0).RotateBy((360/circle_amo) * i);
			offset.x *= 0.5f;
			offset.RotateBy(-dir.Angle());

			Vec2f ppos = pos + offset;
			Vec2f pvel = pos-ppos;
			pvel *= 0.275f;
			
			CParticle@ p = ParticlePixelUnlimited(ppos, pvel, col, true);
    		if(p !is null)
			{
    			p.fastcollision = true;
    			p.timeout = 5;
    			p.damping = 0.9f;
				p.gravity = Vec2f(0,0);
				p.collides = false;
				p.Z = 510.0f;
				p.setRenderStyle(RenderStyle::additive);
			}
		}
	}

	if (isClient() && this.getTickSinceCreated() >= 3)
	{
		u8 trail_size = 3;
		f32 trail_gap = 2.0f;

		SColor col = SColor(255, 255, 255, 255);
		if (this.getTeamNum() == 0)
		{
			col = SColor(255, 15+XORRandom(25), 15+XORRandom(55), 225 + XORRandom(25));
		}
		for (u8 i = 0; i < trail_size; i++)
    	{
    	    CParticle@ p = ParticleAnimated("BloodBolt.png", this.getPosition() - Vec2f(4 + i * trail_gap, 0).RotateBy(this.getAngleDegrees()), vel, this.getAngleDegrees(), 1.0f, 5, 0.0f, true);
		    if (p !is null)
		    {
		    	p.bounce = 0;
    	    	p.collides = true;
				p.fastcollision = true;
				p.timeout = 30;
    	        p.growth = -0.05f;
		    	p.Z = -1.0f;
		    	p.gravity = Vec2f_zero;
		    	p.deadeffect = -1;
    	        p.setRenderStyle(RenderStyle::additive);

				p.colour = col;
				p.forcecolor = col;
		    }
    	}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float damage = this.get_f32("damage");
			this.getSprite().PlaySound("exehit.ogg", 1.0f, 1.5f+XORRandom(26)*0.01f);

			if (isServer())
			{
				if (!this.hasTag("was_hit")) this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::arrow, true);
				this.Tag("mark_for_death");
			}

			this.Tag("was_hit");
		}
	}
	else if (solid)
	{
		if (this.getTimeToDie() <= 0.25f) this.Tag("mark_for_death");
		else this.server_SetTimeToDie(this.getTimeToDie() - 0.25f);

		this.getSprite().PlaySound("BloodBoltBounce.ogg", 0.5f, 1.0f + XORRandom(11) * 0.01f);
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
				&& (friend is null
					|| friend.getTeamNum() != this.getTeamNum()
					)
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}