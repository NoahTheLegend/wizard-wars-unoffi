#include "Hitters.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = true;
	consts.net_threshold_multiplier = 0.25f;
	shape.SetGravityScale(0.0f);

	this.Tag("projectile");
	this.Tag("die_in_divine_shield");
	this.Tag("cantparry");
	this.set_u8("despelled", 0);
	this.Tag("multi_despell");

	this.set_f32("hit_power", 0);
	this.set_f32("angle_diff", 0);
	this.set_f32("old_angle", 0);

	this.getSprite().SetRelativeZ(501.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
	this.setAngleDegrees(180);

	if (!this.exists("damage")) this.set_f32("damage", 0.25f);
}

const u8 spinup_time = 225;
const f32 max_spin_speed = 30.0f;
const f32 move_lerp = 0.33f;
const f32 base_hit_power = 15.0f;
const f32 swing_deatheffect_power = 2.5f;

void onTick(CBlob@ this)
{
	if(this.get_u8("despelled") >= 2)
    {
        this.server_Die();
		return;
    }

	if (this.getTickSinceCreated() == 0)
	{
		CShape@ shape = this.getShape();
		shape.SetStatic(true);
	}

	CSprite@ sprite = this.getSprite();

	this.SetFacingLeft(false);
	Vec2f pos = this.getPosition();
	Vec2f dest = this.get_Vec2f("target_pos");
	bool fl = this.get_bool("fl");
	u32 gt = getGameTime();
	f32 deg = this.getAngleDegrees();
	f32 hit_angle = 20;
	f32 old_angle = this.get_f32("old_angle");

	if (this.hasTag("swing"))
	{
		if (Maths::Abs(this.getAngleDegrees()-(fl?360-hit_angle:hit_angle)) <= 8.0f)
		{
			this.server_Die();
			return;
		}
	}

	bool ready = this.hasTag("ready");
	if (!ready)
	{
		this.setPosition(Vec2f_lerp(pos, dest, move_lerp));
		pos = this.getPosition();
		if ((pos-dest).Length()<8.0f)
		{
			this.set_u32("ready_time", gt);
			this.set_Vec2f("ready_pos", pos);
			this.Tag("ready");

			if (this.hasTag("overcharge"))
			{
				sprite.SetEmitSound("bat_swing.ogg");
				sprite.SetEmitSoundSpeed(0.0f);
				sprite.SetEmitSoundVolume(0.0f);
				sprite.SetEmitSoundPaused(false);
			}	
		}
	}
	if (this.hasTag("ready"))
	{
		u32 ready_time = this.get_u32("ready_time");
		u32 diff = gt-ready_time;
		Vec2f ready_pos = this.get_Vec2f("ready_pos");

		if (this.hasTag("overcharge"))
		{
			f32 factor = f32(Maths::Min(diff, spinup_time))/spinup_time;
			this.set_f32("hit_power", factor);

			this.setAngleDegrees((deg + (fl ? 1 : -1) * (max_spin_speed*factor))%360);
			sprite.SetEmitSoundVolume(0.5f * factor);
			f32 speed = 1.0f * factor;
			if (speed > 0.9f) speed += XORRandom(11)*0.01f;
			sprite.SetEmitSoundSpeed(speed);
		}
		else
		{
			Vec2f offset = Vec2f(fl ? 48 : -48, 32);
			this.Tag("swing");
			Vec2f target = ready_pos + offset;
			if (diff < 30)
			{
				this.setPosition(Vec2f_lerp(pos, target, diff*0.01f));
				this.setAngleDegrees(Lerp(deg, fl ? 180-65 : 180+65, 0.1f)%360);
			}
			else
			{
				this.Tag("swinging");

				f32 rot_lerp = Maths::Min(0.1f+(diff-30)*0.05f, 1);
				this.setAngleDegrees(Lerp(deg, fl ? 360-hit_angle : hit_angle, rot_lerp)%360);
				deg = this.getAngleDegrees();
				Vec2f arc = Vec2f(0, -this.getRadius()).RotateBy(deg);
				this.setPosition(ready_pos + arc);
				pos = this.getPosition();

				f32 arc_diff = Maths::Abs(deg-old_angle);
				f32 arc_angle = (arc_diff*2)%360;
				f32 rot = deg + (fl ? -arc_angle/2 : arc_angle/2) - 90;

				//print(arc_angle+" < arc, rot > "+rot);

				HitInfo@[] infos;
				getMap().getHitInfosFromArc(ready_pos, rot, arc_angle, this.getHeight(), this, false, @infos);

				u16[] ignore_ids;
				this.get("ignore_ids", ignore_ids);
				for (u16 i = 0; i < infos.size(); i++)
				{
					HitInfo@ info = infos[i];
					if (info is null) continue;

					CBlob@[] bs;
					getMap().getBlobsInRadius(info.hitpos, 8.0f, @bs);
					for (u16 j = 0; j < bs.size(); j++)
					{
						CBlob@ b = bs[j];
						if (b is null || b is this) continue;
						if (ignore_ids.find(b.getNetworkID()) != -1) continue;

						ignore_ids.push_back(b.getNetworkID());
						onCollision(this, b, false);
					}
				}
				this.set("ignore_ids", ignore_ids);
			}
		}
	}

	this.set_f32("angle_diff", Maths::Abs(deg-old_angle) * swing_deatheffect_power);
	this.set_f32("old_angle", deg);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	bool active = this.hasTag("overcharge") ? this.hasTag("ready") : this.hasTag("swinging");
	if (!active) return;
	if (blob !is null)
	{
		f32 hp = Maths::Max(0.5f, this.get_f32("hit_power"));
		if (isEnemy(this, blob))
		{
			f32 dmg = this.get_f32("damage");
			f32 power = base_hit_power*(this.hasTag("swinging")?1.0f:hp);
			bool fl = this.get_bool("fl");

			Vec2f bp = blob.getPosition();
			Vec2f tp = this.getPosition();
			f32 dist_factor = (bp-tp).Length()/(this.getRadius()*2);

			if (this.hasTag("overcharge"))
			{
				dmg *= dist_factor;
				power *= dist_factor;
			}
			else
			{
				this.IgnoreCollisionWhileOverlapped(blob, 30);
			}
			
			f32 deg = this.getAngleDegrees();
			f32 angle = Maths::Abs(deg);
			angle = angle%360;

			Vec2f def_force = Vec2f(blob.getMass() * power, 0).RotateBy(angle + (fl?0:180));
			Vec2f ovr_force = Vec2f(blob.getMass() * power, 0).RotateBy(deg + (fl?180:0));
			Vec2f force = this.hasTag("overcharge") ? ovr_force : def_force;
			
			this.IgnoreCollisionWhileOverlapped(blob, 5);
			if (this.hasTag("overcharge"))
			{
				Vec2f side = Vec2f(0,48).RotateBy(deg);
				f32 len1 = ((tp-side)-bp).Length();
				f32 len2 = ((tp+side)-bp).Length();
				if (len1 <= len2) force.RotateBy(180);

				/*Vec2f fr = force;
				fr.Normalize();
				for (u8 i = 0; i < 50; i++)
				{
					CParticle@ p = ParticlePixelUnlimited(blob.getPosition() + fr * Maths::Pow(i, 1), Vec2f_zero, SColor(255,255,255,0), true);
					if(p !is null)
					{
						p.collides = false;
					    p.gravity = Vec2f(0,0);
					    p.timeout = 15;
					    p.Z = 555;
					}
				}*/
			}

			blob.AddForce(force);

			if (isClient())
				this.getSprite().PlaySound("bat_hit.ogg", 1.0f, 1.0f);
			if (isServer() && !blob.hasTag("projectile"))
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), dmg, Hitters::crush, true);
		}
	}
}

f32 Lerp(f32 a, f32 b, f32 t)
{
	return (1.0f - t) * a + b * t;
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			target.hasTag("projectile") ||
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

void onDie(CBlob@ this)
{
	if (this.hasTag("disable_smashtoparticles"))
		return;
	
	if (isClient())
		this.getSprite().PlaySound("bat_slice.ogg", 1.25f, 1.5f+XORRandom(11)*0.01f);

    if (!makeParticlesFromSpriteAccurate(this, this.getSprite(), this.get_u16("smashtoparticles_probability")))
    {
        ParticlesFromSprite(this.getSprite());
    }
}

const int[] cols = {0xff2cafde,0xff1d85ab,0xff1a4e83,0xff222760,0xffd5543f,0xffb73333,0xff941b1b,0xff3b1406};

SColor blueRedSwap(SColor oldcol, u8 t)
{
    int newcol = oldcol.color;
    if (t > 1) return SColor(newcol);

    if (t == 1 && oldcol.getRed() < 125)
    {
        int idx = cols.find(oldcol.color);
        if (idx+4 < cols.size()-1) newcol = cols[idx+4];
    }
    
    return SColor(newcol);
}

bool makeParticlesFromSpriteAccurate(CBlob@ this, CSprite@ sprite, u16 probability)
{
	if (!isClient())
		return false;

    CFileImage@ image;
    @image = CFileImage(sprite.getConsts().filename);

	if (image.isLoaded())
	{
        sprite.SetVisible(false); // force disable sprite visibility to prevent dublicate in rendering
        Vec2f pos = this.getOldPosition();
        Vec2f vel = this.getOldVelocity();
        f32 deg = this.getAngleDegrees();
        bool fl = this.isFacingLeft();
        f32 layer = sprite.getZ();

        int w = image.getWidth(); 
        int h = image.getHeight();

		bool rotate_left = this.get_bool("fl");
		f32 rad = h/2;
        
        Vec2f center = Vec2f(-w/2, -h/2) + sprite.getOffset(); // shift it to upper left corner for 1/2 of sprite size
		f32 hp = this.get_f32("hit_power");

		int i = 0;
        while(image.nextPixel() && w != 0 && h != 0)
		{
			i++;
			SColor px_col = image.readPixel();
            if (XORRandom(probability) != 0) continue;
            if (px_col.getAlpha() != 255) continue;
            px_col = blueRedSwap(px_col, this.getTeamNum());

            Vec2f px_pos = image.getPixelPosition();
            if (fl) px_pos.x = w-px_pos.x;

            Vec2f offset = center + px_pos;
            offset.RotateBy(deg);
			f32 len, distfactor, spin_force, sin;
			Vec2f pvel;
			if (this.hasTag("swing"))
			{
				len = h - Maths::Floor(px_pos.y);
				distfactor = len/h;
				spin_force = this.get_f32("angle_diff") * distfactor;
				spin_force = Maths::Sin(Maths::Pow(spin_force*0.05f,2))*25;
				pvel = Vec2f(rotate_left ? spin_force : -spin_force, 0).RotateBy(deg);
			}
			else
			{
				len = (Vec2f(w/2, px_pos.y)+center).Length();
				distfactor = Maths::Min(len, rad)/rad;
				spin_force = max_spin_speed * distfactor * hp;
				sin = Maths::Sin(px_pos.y*0.5f)*0.1f;
				pvel = (px_pos.y > rad ? Vec2f(rotate_left ? -spin_force : spin_force, 0)
					: Vec2f(rotate_left ? spin_force : -spin_force, 0)).RotateBy(deg);
			}

			pvel += vel;
            MakeParticle(pos + offset, pvel, px_col, 500, sin, hp == 0.0f ? Vec2f(0, 1) : Vec2f_zero, hp == 0.0f ? 5 : 30);
        }

        return true;
    }

    return false;
}

void MakeParticle(Vec2f pos, Vec2f vel, SColor col, f32 layer, f32 damp, Vec2f grav, int time)
{
    CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
    if(p !is null)
    {
        p.bounce = 0.15f + XORRandom(26)*0.01f;
        p.fastcollision = true;
		p.collides = false;
        p.timeout = time+XORRandom(15);
        p.Z = layer;
		p.gravity = grav;
		p.damping = 0.75f+damp;
    }
}