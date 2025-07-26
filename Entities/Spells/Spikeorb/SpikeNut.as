#include "Hitters.as"

const f32 AOE = 12.0f;//radius
const int min_detonation_time = 3;
const f32 max_vel = 2.5f;

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("exploding");
	this.set_f32("damage", 0.4f);

	this.set_bool("explosive_teamkill", false);
	this.set_bool("dont_damage_owner", true);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().getConsts().bullet = true;

	this.getCurrentScript().tickFrequency = 2;
	this.set_u16("picked_target", 0);
	this.set_Vec2f("oldvel", Vec2f_zero);
}

void onTick(CBlob@ this)
{
	if (this.getCurrentScript().tickFrequency == 2)
	{
		this.getShape().SetGravityScale(1.0f);
		this.server_SetTimeToDie(30);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 211, 121, 224));
		this.set_string("custom_explosion_sound", "SpikeOrbExplosion.ogg");
		this.getSprite().PlaySound("WizardShoot.ogg", 1.0f);
		this.getSprite().SetZ(1000.0f);

		this.getCurrentScript().tickFrequency = 1;
	}

	Vec2f pos = this.getPosition();
	bool search = true;
	string animation = "idle";

	Vec2f oldvel = this.get_Vec2f("oldvel");
	Vec2f vel = this.getVelocity();
	this.SetFacingLeft(vel.x <= -0.1f ? true : vel.x >= 0.1f ? false : XORRandom(100) == 0 ? !this.isFacingLeft() : this.isFacingLeft());

	if (vel.y > 0.1f) animation = "fall";
	else if (Maths::Abs(vel.x) > 0.1f) animation = "move";

	// find targets to move at
	f32 radius = 96.0f;
	u16 targetID = this.get_u16("picked_target");
	if (targetID > 0)
	{
		CBlob@ target = getBlobByNetworkID(targetID);
		if (target !is null && target.getDistanceTo(this) <= radius)
		{
			search = false;
			Vec2f targetPos = target.getPosition();
			f32 diff = Maths::Abs(targetPos.x - pos.x);

			if (!this.isOnWall())
			{
				if (targetPos.x < pos.x)
					this.setVelocity(Vec2f(Maths::Lerp(oldvel.x, Maths::Max(-max_vel, -diff), 0.15f), vel.y));
				else
					this.setVelocity(Vec2f(Maths::Lerp(oldvel.x, Maths::Min(max_vel, diff), 0.15f), vel.y));
			}

			this.set_Vec2f("oldvel", this.getVelocity());
			if ((diff < max_vel || this.isOnWall()) && this.isOnGround()) // try to jump
			{
				Vec2f jumpVel = this.getVelocity();
				if (targetPos.y < pos.y)
					jumpVel.y = -Maths::Max(2.0f, Maths::Abs(targetPos.y - pos.y) * 0.15f);
				else
					jumpVel.y = Maths::Max(2.0f, Maths::Abs(targetPos.y - pos.y) * 0.15f);

				f32 seed = this.getNetworkID() % 5;
				this.getSprite().PlaySound("GumBounce"+XORRandom(3)+".ogg", 0.25f, 3.0f + seed * 0.1f + XORRandom(21)*0.01f);
				this.setVelocity(jumpVel);
			}
		}
	}

	if (isClient())
	{
		this.getSprite().SetAnimation(animation);
	}

	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(this.getPosition(), radius, @blobsInRadius))
	{
		bool extra_damage = this.hasTag("extra_damage");

		for (int i = 0; i < blobsInRadius.length; i++)
		{
			if (XORRandom(30) != 0 && !extra_damage) continue;

			CBlob@ blob = blobsInRadius[i];
			if (blob is null || blob.hasTag("dead") || !blob.hasTag("flesh") || blob.getTeamNum() == this.getTeamNum())
				continue;

			if (blob.getDistanceTo(this) <= radius && !getMap().rayCastSolidNoBlobs(pos, blob.getPosition()))
			{
				this.set_u16("picked_target", blob.getNetworkID());
				break;
			}
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		target.getTeamNum() != this.getTeamNum()
		&&
		(
			target.hasTag("standingup")
			||
			target.hasTag("kill other spells") 
			||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead")
			)
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
		blob.getName() == this.getName()
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

	bool causeSparks = false;
	bool blobDeath = false;

	if (solid)
	{
		if (blob is null && isServer() && this.hasTag("die_on_collide"))
		{
			this.Tag("mark_for_death");
		}
	}

	if (blob !is null && isEnemy(this, blob))
	{
		causeSparks = true;
		if (this.getTickSinceCreated() > min_detonation_time)	
		{
			blobDeath = true;
		}
	}

	if(causeSparks)
	{sparks(this.getPosition(), 4);}

	if(blobDeath)
	{this.Tag("mark_for_death");}
}

void onDie( CBlob@ this )
{
	if(this is null)
	{return;}
	if(!this.hasTag("exploding"))
	{return;}

	Vec2f pos = this.getPosition();
	
	if ( isServer() )
	{
		CMap@ map = getMap();
		if(map is null)
		{return;}

		CBlob@[] aoeBlobs;

		map.getBlobsInRadius( pos, AOE, @aoeBlobs );
		for ( u8 i = 0; i < aoeBlobs.length(); i++ )
		{
			CBlob@ b = aoeBlobs[i]; //standard null check for blobs in radius
			if (b is null || b.getName() == "spikes")
			{continue;}

			if (!isEnemy(this, b))
			{continue;}

			if (!map.rayCastSolidNoBlobs(pos, b.getPosition()))
			{
				this.server_Hit(b, pos, Vec2f_zero, this.get_f32("damage"), Hitters::crush, false);
			}
		}
	}
	sparks(pos, 10);
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

Random _sprk_r(13424);
void sparks(Vec2f pos, int amount)
{
	if ( !isClient() )
	{return;}

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}
