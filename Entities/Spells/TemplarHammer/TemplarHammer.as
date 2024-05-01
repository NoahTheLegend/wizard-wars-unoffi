#include "Hitters.as";

const f32 add_grav = 0.1f;
const f32 max_grav = 1.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = true;
	consts.bullet = false;

	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale(0.0f);

	this.set_f32("damage", 0.6f + XORRandom(3)*0.1f); // 3-4
	this.getSprite().SetZ(9.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
    this.server_SetTimeToDie(3);
	CSprite@ sprite = this.getSprite();
	this.set_u16("smashtoparticles_probability", 1); // 1 is 100%, 2 is 50% and so on
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1)
	{
		this.getSprite().PlaySound("hammercast.ogg", 1.0f, 1.15f+XORRandom(6)*0.01f);
	}
	this.setAngleDegrees(-this.getOldVelocity().Angle());
	
	if (isServer() && !this.get_bool("smite") && this.getTickSinceCreated() > 5)
	{
		this.getShape().SetGravityScale(Maths::Min(this.getShape().getGravityScale()+add_grav, max_grav));
	}
	for(int i = 0; i < 3; i ++)
	{
		float randomPVel = XORRandom(16) * 0.01f - 0.75f;
		Vec2f particleVel = Vec2f(randomPVel, 0).RotateByDegrees(this.getAngleDegrees()+(XORRandom(151)-75.0f));

    	CParticle@ p = ParticlePixelUnlimited(this.getPosition()+Vec2f(XORRandom(8), XORRandom(16)-8).RotateByDegrees(this.getAngleDegrees()), particleVel, SColor(255,100+XORRandom(155),255,255), true);
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
	
	CMap@ map = getMap();
	if (map is null) return;

	HitInfo@[] bs;
	if (map.getHitInfosFromRay(this.getPosition(), this.getAngleDegrees(), this.getVelocity().Length(), this, @bs))
	{
		for (u16 i = 0; i < bs.size(); i++)
		{
			CBlob@ b = bs[i].blob;
			if (b is null) continue;

			onCollision(this, b, false);
		}
	}
}

void onTick(CSprite@ this) //rotating sprite
{
	CBlob@ b = this.getBlob();
	if(this is null || b is null)
	{return;}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	bool swordDeath = false;
	bool enemy = true;

	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float damage = this.get_f32("damage");
			if (!this.hasTag("collided"))
			{
				if (blob.hasTag("barrier"))
				{
					damage += 1.5f;
				}
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::boulder, true);
				this.Tag("collided");
				swordDeath = true;
			}
			else
			{
				swordDeath = true;
				enemy = false;
			}
		}
	}

	if ((solid && enemy) || swordDeath)
	{ this.server_Die(); }
}

void onDie(CBlob@ this)
{
	Vec2f thisPos = this.getPosition();
	float damage = this.get_f32("damage");
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