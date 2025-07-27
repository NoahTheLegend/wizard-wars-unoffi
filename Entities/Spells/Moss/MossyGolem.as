#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.getShape().getConsts().bullet = true;

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(100.0f);

	this.set_bool("mode", false);
	this.set_Vec2f("gravity", Vec2f_zero);
}

const u8 idle_time = 30;
const f32 base_accel = 1.0f;
const f32 base_accel_opposite = 2.0f;
const f32 stopping_damp_base = 0.7f;
const f32 max_vel = 7.5f;
const f32 max_aggro_len = 128.0f;

const f32 wall_raycast_dist = 32.0f;
const f32 grav_const = 9.81f;

void onTick(CBlob@ this)
{
	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.getShape().SetGravityScale(0.0f); // we have own gravity
	}

	if (isClient() && isServer())
	{
		if (getControls().isKeyJustPressed(KEY_KEY_R))
			this.set_bool("mode", !this.get_bool("mode"));

		if (getControls().isKeyJustPressed(KEY_KEY_K))
			this.server_Die();
	}
	if (this.get_bool("mode")) return;

	CMap@ map = getMap();
	if (map is null) return;
	
	f32 vellen = this.getVelocity().Length();
	bool fl = this.isFacingLeft();
	
	f32 accel = base_accel / (1.0f+vellen);
	f32 stopping_damp = stopping_damp_base;

	f32 deg = this.getAngleDegrees();
	bool onground = this.isOnGround() || hasSolidGround(this, this.getPosition() + Vec2f(0, 8).RotateBy(deg));
	bool wasonground = this.get_bool("was_on_ground");
	bool onwall = this.isOnWall();

	Vec2f pos = this.getPosition();
	if (map is null) return;

	Vec2f vel = this.getVelocity();
	Vec2f velNorm = vel;
	velNorm.Normalize();

	Vec2f nextpos = pos + vel;
	Vec2f next_wall = Vec2f_zero;

	if (map.rayCastSolidNoBlobs(pos, pos + velNorm * wall_raycast_dist, next_wall))
	{
		// slow down here
	}

	if (isServer())
	{
		Vec2f target = Vec2f_zero;
		if (this.getTickSinceCreated() >= idle_time)
		{
			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p !is null && p.getBlob() !is null)
				{
					CBlob@ b = p.getBlob();
					if (b.getTeamNum() == this.getTeamNum()
						|| b.getDistanceTo(this) > max_aggro_len)
							continue;

					if (map.rayCastSolidNoBlobs(pos, b.getPosition()))
						continue;

					fl = b.getPosition().x < pos.x;
					this.SetFacingLeft(fl);
					target = b.getPosition();
				}
			}
		}

		if (isClient() && isServer())
		{
			if (getControls().isKeyPressed(KEY_KEY_X))
				target = getPlayerByUsername("NoahTheLegend").getBlob().getPosition();
		}

		bool found_ground = false;
		if (!onground && wasonground && !onwall)
		{
			// 2.0f is one tile
			// search ledge next to golem to slow down
			Vec2f origin = pos + Vec2f(0, 12);
			f32 w = 20;
			f32 h = w;
			for (u8 i = 0; i < w; i++)
			{
				bool do_break = false;
				u8 space = 0;

				for (u8 j = 0; j < h; j++)
				{
					Vec2f step = origin + Vec2f((fl ? -8 : 8) * i, -h*8 + (8*j));
					TileType t = map.getTile(step).type;
					target = step;
					
					bool has_solid = hasSolidGround(this, step);
					if (!map.isTileSolid(t) && !has_solid)
						space++;

					if (map.rayCastSolidNoBlobs(pos - Vec2f(0,this.getRadius()), step-Vec2f(0,8)))
					{
						space = 0;

						//CParticle@ p = ParticleAnimated("GenericBlast6.png", 
						//target, 
						//Vec2f_zero, 
						//float(XORRandom(360)), 
						//1.0f, 
						//2, 
						//0.0f, 
						//false);
						//	p.scale = 0.5f;
						//	p.setRenderStyle(RenderStyle::additive);
					}

					if (space >= 3 && map.rayCastSolid(step, step + Vec2f(0, 32)))
					{
						found_ground = true;
						do_break = true;
						break;
					}
				}

				if (do_break)
					break;
			}
		}

		if (target == Vec2f_zero)
		{
			this.setVelocity(vel * stopping_damp);
		}
		else if (vellen < max_vel)
		{
			Vec2f grav = this.get_Vec2f("gravity");
			Vec2f target_dir = target - pos;
			target_dir.Normalize();
			target_dir.RotateBy(-deg);

			Vec2f rot_vel = vel.RotateBy(-deg);
			if ((target_dir.x < 0 && rot_vel.x > 0) || (target_dir.x > 0 && rot_vel.x < 0))
				accel *= base_accel_opposite;

			Vec2f force = Vec2f(target_dir.x < 0 ? -accel : target_dir.x > 0 ? accel : 0, 0) * this.getMass();
			this.AddForce(force + grav);

			if (vel.Length() > 0.1f) this.SetFacingLeft(this.getVelocity().x < 0);
		}
	}

	this.set_bool("was_on_ground", onground);
	if (!isClient()) return;
	
	CSprite@ sprite = this.getSprite();
	if (onground)
	{
		sprite.SetAnimation(vel.Length() > 0.25f ? "run" : "idle");
		sprite.animation.time = 6 - Maths::Min(vellen/2, 3);
	}
	else if (this.getVelocity().y > 0.0f)
		sprite.SetAnimation("fall");
}

bool hasSolidGround(CBlob@ this, Vec2f pos)
{
	CMap@ map = getMap();
	CBlob@[] bs;
	map.getBlobsAtPosition(pos, @bs);

	for (u8 k = 0; k < bs.size(); k++)
	{
		CBlob@ b = bs[k];
		if (b is null) continue;

		if (b !is null
			&& (b.hasTag("door") && b.isCollidable()))
				return true;
		
		if (b.getShape() is null || !b.getShape().isStatic()) continue;
		
		ShapePlatformDirection@ plat = b.getShape().getPlatformDirection(0);
		if (plat !is null)
		{
			Vec2f dir = plat.direction;
			return dir.y < 0;
		}
	}

	return false;
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && target.getShape() !is null && !target.getShape().isStatic()
		&& (target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

void MakeDustParticle(Vec2f pos, string file)
{
	CParticle@ temp = ParticleAnimated(file, pos - Vec2f(0, 8), Vec2f(0, 0), 0.0f, 1.0f, 3, 0.0f, false);

	if (temp !is null)
	{
		temp.width = 8;
		temp.height = 8;
	}
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
	if (blob.hasTag("door")) return blob.isCollidable();

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
		bool onground = this.isOnGround() || hasSolidGround(this, this.getPosition()+Vec2f(0,8));

		CSprite@ sprite = this.getSprite();
		if (sprite !is null && !onground)
		{
			//sprite.PlaySound("GumBounce"+XORRandom(3)+".ogg", 0.75f, 2.25f + XORRandom(16)*0.01f);
		}
	}

	if (blob !is null && isEnemy(this, blob) && this.getTickSinceCreated() >= idle_time)
	{
		blobDeath = true;
	}

	if (blobDeath && isServer())
	{this.Tag("mark_for_death");}
}

void onDie(CBlob@ this)
{
	Vec2f pos = this.getPosition();

	if (isClient())
	{
		makeSmokePuff(this);
		smoke(this.getPosition(), 20);
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
										false);
		if (p !is null)
		{
			p.bounce = 0;
			p.scale = 3.0f;
    		p.fastcollision = true;
			p.Z = 55.0f;
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

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke"+(1+XORRandom(2))+".png").getFirst(), 
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
        p.damping = 0.925f;
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