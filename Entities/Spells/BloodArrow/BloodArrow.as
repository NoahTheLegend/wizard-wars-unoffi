#include "Hitters.as";
#include "TeamColour.as";
#include "SpellUtils.as";

void onInit(CBlob@ this)
{
	this.getSprite().PlaySound("swordsummon.ogg", 0.75f, 1.4f+XORRandom(21)*0.01f);
	this.getSprite().PlaySound("glaiveswipe.ogg", 0.75f, 1.4f+XORRandom(21)*0.01f);

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	consts.net_threshold_multiplier = 1.0f;
	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale(0.0f);
	
	this.set_f32("lifetime",0);
    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(60);
	this.set_f32("stoprange", stoprange_base + XORRandom(stoprange_random));

	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(750.0f);
	sprite.ScaleBy(Vec2f(0.33f, 0.33f));
	//sprite.setRenderStyle(RenderStyle::additive);

	CSpriteLayer@ l = sprite.addSpriteLayer("BloodArrow.png", 48, 16);
	if (l !is null)
	{
		l.ScaleBy(Vec2f(0.5f, 0.5f));
		l.SetRelativeZ(751.0f);
		l.setRenderStyle(RenderStyle::additive);
	}
}

const f32 stoprange_base = 24.0f;
const f32 stoprange_random = 24.0f;

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	Vec2f target_pos = this.get_Vec2f("target_pos");

	SColor col = SColor(155+XORRandom(55), 125+XORRandom(55), 10+XORRandom(25), 0);
	if (this.getTeamNum() == 3) col = SColor(155+XORRandom(55), 10+XORRandom(25), 0, 125+XORRandom(55));
	
	bool stop = this.get_bool("stop");
	f32 stoprange = this.get_f32("stoprange");

	Vec2f dir = target_pos-pos;
	f32 dist = dir.Length();

	dir.Normalize();

	Vec2f vel = this.getVelocity();
	f32 speed = this.get_f32("speed");
	f32 factor = 1.0f * Maths::Min(dist, stoprange) / stoprange;

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
		u8 t = this.getTeamNum();
		for (u8 i = 0; i < 2; i++)
		{
			Vec2f dir = Vec2f(0, 4 * (i % 2 == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees());
			Vec2f ppos = this.getOldPosition()+dir;
			Vec2f pvel = this.getVelocity() + (-dir/5);
			
			CParticle@ p = ParticlePixelUnlimited(ppos, pvel, col, true);
    		if(p !is null)
			{
    			p.fastcollision = true;
    			p.timeout = 8 + XORRandom(8);
    			p.damping = 0.8f+XORRandom(101)*0.001f;
				p.gravity = Vec2f(0,0);
				p.collides = false;
				p.Z = 510.0f;
				p.setRenderStyle(RenderStyle::additive);
			}
		}
	}

	this.setVelocity(dir * speed * factor);

	if (dist < stoprange && vel.Length() < 1.0f)
	{
		this.set_bool("stop", true);

		if (this.getTimeToDie() > 1.5f)
		{
			this.server_SetTimeToDie(0.5f+XORRandom(51)*0.01f);
		}
	}
	if (vel.Length() >= 1.0f) this.setAngleDegrees(-this.getVelocity().Angle());
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
				this.server_Die();
			}

			this.Tag("was_hit");
		}
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