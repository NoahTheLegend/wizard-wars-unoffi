#include "Hitters.as"

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("exploding"); 
	this.set_f32("damage", 0.0f);
	this.Tag("bomb");

	this.set_f32("explosive_radius", 0.0f);
	this.set_f32("explosive_damage", 0.0f);
	this.set_f32("explode_radius", 32.0f);
	this.set_f32("map_damage_radius", 32.0f);
	this.set_f32("map_damage_ratio", 0.25f);
	this.set_string("custom_explosion_sound", "Whack"+(1+XORRandom(3))+".ogg");
	this.set_f32("explosion_pitch", 1.5f+XORRandom(21)*0.01f);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
	
	this.getShape().getConsts().bullet = true;
	this.getShape().SetRotationsAllowed(false);

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(100.0f);

	sprite.SetEmitSound("ticking.ogg");
	sprite.SetEmitSoundSpeed(1.75f);
	sprite.SetEmitSoundVolume(0.5f);
	sprite.SetEmitSoundPaused(false);

	CSpriteLayer@ decal = sprite.addSpriteLayer("decal", "BobombDecal.png", 16, 16);
	if (decal !is null)
	{
		Animation@ def = decal.addAnimation("default", 3, true);
		int[] frames = {0,1,2,3,4,5,6,7};
		def.AddFrames(frames);

		decal.SetRelativeZ(49.0f);
		decal.SetOffset(Vec2f(10, -4.5f));
		decal.SetAnimation(def);
	}	

	this.server_SetTimeToDie(4);
	this.set_s32("aliveTime", this.getTimeToDie());
	this.set_string("anim", "slow");
}

const f32 base_accel = 0.75f;
const f32 max_vel = 7.0f;
const f32 max_aggro_len = 256.0f;

void onTick(CBlob@ this)
{
	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.getShape().SetGravityScale(1.0f);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 230, 195, 24));
		this.getSprite().PlaySound("ObsessedSpellCreate", 0.85f, 1.33f);
	}

	CMap@ map = getMap();
	f32 vellen = this.getVelocity().Length();
	bool fl = this.isFacingLeft();
	f32 accel = base_accel / (1.0f+vellen);
	Vec2f force = Vec2f((fl ? -accel : accel) * this.getMass(), 0);

	bool onground = this.isOnGround() || hasSolidGround(this, this.getPosition()+Vec2f(0,8));

	bool wasonground = this.get_bool("was_on_ground");
	bool onwall = this.isOnWall();
	f32 jump = onwall && onground && vellen < 0.5f ? 4 : 0;

	Vec2f pos = this.getPosition();
	if (map is null) return;

	Vec2f nextpos = pos + this.getVelocity();
	if (nextpos.x < 8.0f) this.setPosition(Vec2f(map.tilemapwidth*8-this.getHeight(), pos.y));
	if (nextpos.x > map.tilemapwidth * 8 - 8.0f) this.setPosition(Vec2f(this.getHeight(), pos.y));
	if (nextpos.y > map.tilemapheight * 8 - 8.0f) this.setPosition(Vec2f(pos.x, 0));
	if (nextpos.y < 0.0f) this.setPosition(Vec2f(pos.x, map.tilemapheight * 8 - this.getHeight()));

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

		bool found_ground = false;
		if (!onground && wasonground && !onwall)
		{
			// 2.0f is one tile
			// search ledge next to bomb
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

					if (space >= 3 && map.rayCastSolid(step, step + Vec2f(0,32)))
					{
						found_ground = true;
						do_break = true;
						break;
					}
				}

				if (do_break)
					break;
			}

			if (target != Vec2f_zero)
			{
				f32 lateral_coef = Maths::Abs(Maths::Abs(target.x - Maths::Abs(pos.x))) / ((vellen+0.1f)*4);
				if (!found_ground || vellen < 1.0f) lateral_coef = 0;
				f32 vertical_coef = (target.y > pos.y ? 0 : (pos.y-target.y) * (8 / vellen));
				jump += vertical_coef / 8 + lateral_coef;

				//CParticle@ p = ParticleAnimated("GenericBlast6.png", 
				//	target, 
				//	Vec2f_zero, 
				//	float(XORRandom(360)), 
				//	1.0f, 
				//	2, 
				//	0.0f, 
				//	false);
				//p.scale = 0.5f;
				//printf(lateral_coef+" "+vertical_coef+" "+jump);
			}
		}

		if ((onground || wasonground || this.isInWater())
			&& vellen < max_vel)
		{
			this.AddForce(force);
			if ((getGameTime()+this.getNetworkID())%3==0) MakeDustParticle(this.getPosition() + Vec2f(0.0f, 11.0f), "/DustSmall.png");
		}
	}

	if (jump > 0)
	{
		this.setVelocity(Vec2f(this.getVelocity().x + (onwall ? (fl ? -jump : jump) : 0), -jump));
		MakeDustParticle(this.getPosition() + Vec2f(0.0f, 6.0f), "/dust.png");
	}

	this.set_bool("was_on_ground", onground);
	if (this.get_s32("aliveTime") < this.getTickSinceCreated()) this.server_Die();

	if (!isClient()) return;
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundSpeed(1.5f + (f32(this.getTickSinceCreated()) / this.get_s32("aliveTime")));
	if (onground)
	{
		sprite.SetAnimation("run");
		sprite.animation.time = 4 - Maths::Min(vellen/2, 2);
	}
	else if (this.getVelocity().y < 0.0f)
		sprite.SetAnimation("fly");
	else
		sprite.SetAnimation("fall");

	if (this.exists("aliveTime"))
	{
		int tsc = this.getTickSinceCreated();
		f32 ttdf = f32(tsc)/(this.get_s32("aliveTime")*30);
		Vec2f offset = Vec2f(-10 + 5*ttdf, -11 + 11 * (ttdf > 0.75f ? (ttdf-0.75f) : 0));
		if (fl) offset = Vec2f(-offset.x, offset.y);
		sparks(this.getPosition() + offset.RotateBy(this.get_f32("angle")), 2);
	}
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

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && target.getShape() !is null && !target.getShape().isStatic()
		&& (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
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

const u8 idle_time = 30;
const f32 max_lateral_angle = 10;
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
			sprite.PlaySound("GumBounce"+XORRandom(3)+".ogg", 0.75f, 2.25f + XORRandom(16)*0.01f);
		}
	}

	if (isServer() && this.get_u32("turn") + 5 < getGameTime())
	{
		f32 angle = max_lateral_angle;
		f32 ang = Maths::Abs(-normal.Angle());
		if (solid
			&& ((ang > 360-angle || ang < angle) || (ang > 180-angle && ang < 180+angle)))
		{
			this.SetFacingLeft(!this.isFacingLeft());
			this.setVelocity(Vec2f(-this.getVelocity().x, this.getVelocity().y));
			this.set_u32("turn", getGameTime());
		}
	}

	if(blob !is null && isEnemy(this, blob) && this.getTickSinceCreated() >= idle_time)
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
		smoke(this.getPosition(), 20);
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
				f32 dmg = this.get_f32("damage");
				if (b.getPlayer() !is null && b.getPlayer() is this.getDamageOwnerPlayer())
					dmg *= 0.25f;

				this.server_Hit(b, pos, Vec2f_zero, dmg, Hitters::explosion, isOwnerBlob(this, b));
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