#include "Hitters.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();

	consts.mapCollisions = false;
	consts.bullet = true;
	consts.net_threshold_multiplier = 2.0f;

	this.Tag("projectile");
	this.Tag("counterable");

	shape.SetGravityScale(g);
	this.set_f32("damage", 0.2f);

    //dont collide with top of the map
	this.set_u16("fly_up_power", XORRandom(max_fly_up_power / 2) + max_fly_up_power / 2);

	this.set_bool("facing_left", false);
	this.set_s32("side_threshold", 0);

	this.set_bool("falling", false);
	this.SetFacingLeft(XORRandom(100) < 50);

	this.Tag("smashtoparticles_no_colorswap");
}

const u16 max_fly_up_power = 15; // in ticks
const f32 max_side_threshold = 30;
const f32 fly_factor = 5;
const u16 fly_up_power_restoration_fall = 1;
const f32 max_vel_x_per_tick = 8.0f;
const f32 g = 0.5f; // gravity scale

void onTick(CBlob@ this)
{
	bool facing_left = this.get_bool("facing_left");
    CShape@ shape = this.getShape();

	bool collides = this.getTickSinceCreated() > 60;
	shape.getConsts().mapCollisions = collides;
	shape.SetGravityScale(g);

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	if (pos.x < 8.0f || pos.x > getMap().tilemapwidth * 8.0f - 8.0f || pos.y < 8.0f || pos.y > getMap().tilemapheight * 8.0f - 8.0f)
	{
		// if outside the map, mark for death
		this.Tag("mark_for_death");
		return;
	}

	f32 lifetime_factor = Maths::Min(1.0f, this.getTickSinceCreated() / max_side_threshold);
	bool falling = this.get_bool("falling");
	s32 side_threshold = this.get_s32("side_threshold");

	if (vel.x > 0.5f) side_threshold = Maths::Min(side_threshold + 1, max_side_threshold);
	else if (vel.x < -0.5f) side_threshold = Maths::Max(side_threshold - 1, -max_side_threshold);

	this.set_bool("facing_left", side_threshold < 0);
	this.set_s32("side_threshold", side_threshold);

	f32 remaining = this.get_u16("fly_up_power");
	f32 fly_up_power = remaining / f32(max_fly_up_power);

	int seed = this.getNetworkID() % 10;
	f32 absx = Maths::Abs(vel.x);
	f32 force_up = Maths::Min(absx, max_vel_x_per_tick) * fly_factor * fly_up_power / Maths::Max(1.0f, fly_factor + (Maths::Sin(this.getTickSinceCreated()) * 0.5f + 0.5f) - vel.y);

	if (isClient())
	{
		string source = "Leaf.png";

        CParticle@ p = ParticleAnimated(source, this.getPosition() - this.getVelocity(), Vec2f_zero, 180, 0.5f, 2, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
            p.growth = -0.05f;
	    	p.Z = -1.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
	}

	if (!falling)
	{
		remaining--;
		if (remaining == 0) falling = true;

		f32 x_damp = Maths::Clamp(vel.x, -max_vel_x_per_tick, max_vel_x_per_tick) * lifetime_factor;
		f32 x_force = -x_damp * 0.5f + (facing_left ? 1.0f : -1.0f);

		this.AddForce(Vec2f(x_force, -Maths::Abs(force_up * (2.0f-lifetime_factor))));
	}
	else
	{
		if (vel.y >= 0.0f)
		{
			remaining += fly_up_power_restoration_fall;
			if (remaining >= max_fly_up_power) falling = false;
		}

		if (remaining > max_fly_up_power)
		{
			remaining = max_fly_up_power;
		}

		if (side_threshold != 0 && absx < fly_factor)
		{
			f32 side_vel = facing_left ? -fly_up_power : fly_up_power;
			this.AddForce(Vec2f(side_vel * Maths::Clamp(2.0f * (absx/(vel.y+0.0001f)), 1.0f, 2.0f) * 2 * Maths::Min(max_vel_x_per_tick, Maths::Abs(vel.y) * fly_factor), vel.y > 0 ? -vel.y * (1.0f - (f32(remaining) / f32(max_fly_up_power))) : 0));
		}
	}

	CBlob@[] bs;
	if (getMap().getBlobsInRadius(pos, 64.0f, bs))
	{
		for (uint i = 0; i < bs.length; i++)
		{
			CBlob@ b = bs[i];
			if (b is null) continue;
			if (!isEnemy(this, b)) continue;

			Vec2f dir = b.getPosition() - pos;
			dir.Normalize();

			this.AddForce(dir * 2);
			break;
		}
	}

	this.set_bool("falling", falling);
	this.set_u16("fly_up_power", remaining);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	bool death = false;

	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float damage = this.get_f32("damage");

			if (!this.hasTag("collided") && this.getTickSinceCreated() > 10)
			{
				if (blob.hasTag("barrier"))
				{
					damage += 1.0f;
					death = true;
				}

				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::arrow, true);
				this.Tag("collided");
			}
			else
			{
				death = true;
			}
		}
	}
	else if (solid) death = true;

	if (death)
	{ this.Tag("mark_for_death"); }
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	this.getSprite().PlaySound("leaf-0", 0.15f, 0.9f + XORRandom(10) * 0.01f);
}

bool isEnemy( CBlob@ this, CBlob@ target )
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