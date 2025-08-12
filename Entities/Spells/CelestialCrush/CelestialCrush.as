#include "Hitters.as";
#include "ArcherCommon.as";

// rotation
const f32 startdeg = 165;
const f32 falldeg = 255;
const f32 fallend = 400;
const f32 decel = 0.15f;
// attack
u8 radius = 12; // n tiles in both sides
f32 force = 235.0f;
f32 depth = 64.0f;
f32 hitradius = 12.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 2.0f;

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("die_in_divine_shield");

	shape.SetGravityScale(0.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
    this.server_SetTimeToDie(5);
	
	this.setAngleDegrees(this.isFacingLeft() ? -startdeg : startdeg);
	this.set_f32("angle", this.getAngleDegrees());

	if (!this.exists("damage")) this.set_f32("damage", 0.25f); // each floor tile in radius damages us
	if (!this.exists("hitradius")) this.set_f32("hitradius", hitradius);
	if (!this.exists("deceleration")) this.set_f32("deceleration", decel);
}

void onTick(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	shape.SetStatic(true);

	u32 gt = getGameTime();
	f32 deg = this.get_f32("angle");
	
	if (deg < falldeg)
	{
	    f32 target = falldeg+2;
	    deg = Lerp(deg, target, this.get_f32("deceleration"));
	}
	else
	{
	    deg *= 1.0f + ((deg-falldeg)/((fallend-deg)+1)) * this.get_f32("deceleration");
		if (deg > fallend) deg = fallend;
	}
	this.set_f32("angle", deg);

	bool die = deg == fallend;
	if (deg > 360.0f) deg -= 360.0f;
	if (deg < -360.0f) deg += 360.0f;
	this.setAngleDegrees(this.isFacingLeft() ? -deg : deg);

	if (die)
	{
		if (this.getTimeToDie() > 1.0f)
		{
			this.server_SetTimeToDie(0.1f);
		}

		Smash(this);
	}
}

f32 Lerp(f32 a, f32 b, f32 t)
{
	return (1.0f - t) * a + b * t;
}

void Smash(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	this.Tag("dead");

	this.getSprite().PlaySound("smash.ogg", 2.0f, 0.95f+XORRandom(21)*0.01f);
	f32 radius = this.get_f32("hitradius");

	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	if (map is null) return;

	for (s8 i = -radius/2; i < radius/2; i++)
	{
		Vec2f castpos = this.getPosition() + Vec2f(8.0f*i, 0);
		if (map.isTileSolid(map.getTile(castpos).type)) continue;

		Vec2f endpoint;
		if (map.rayCastSolidNoBlobs(castpos, castpos+Vec2f(0, depth), endpoint))
		{
			endpoint.y -= 8;
			if (isServer())
			{ 
				CBlob@[] bs;
				map.getBlobsInRadius(endpoint, radius, @bs);
				for (u16 i = 0; i < bs.length; i++)
				{
					CBlob@ b = bs[i];
					if (b is null || !isEnemy(this, b)) continue;

					this.server_Hit(b, b.getPosition(), Vec2f_zero, this.get_f32("damage"), Hitters::arrow, false);
				}
			}
			if (isClient())
			{
				CBlob@ local = getLocalPlayerBlob();
				if (local !is null) // hack? i dont fucking care! :)
				{
					if ((local.getPosition() - endpoint).Length() < radius)
					{
						local.AddForce(Vec2f(0, -force));
					} 
				}

				CParticle@ temp = ParticleAnimated("dust.png", endpoint, Vec2f(0,0), 0.0f, 0.3f+XORRandom(31)*0.01f, 2+XORRandom(3), 0.0f, false);
	
   				if (temp !is null)
   				{
   				    temp.width = 8;
   				    temp.height = 8;
					temp.Z = 5;
					temp.rotates = true;
   					temp.fastcollision = true;
   				}
			}
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