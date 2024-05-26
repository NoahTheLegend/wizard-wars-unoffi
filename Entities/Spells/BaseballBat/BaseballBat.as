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
	this.Tag("counterable");
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
    this.server_SetTimeToDie(60);
	this.setAngleDegrees(180);

	if (!this.exists("damage")) this.set_f32("damage", 0.25f);
}

const u8 spinup_time = 240;
const f32 max_spin_speed = 30.0f;
const f32 move_lerp = 0.33f;
const f32 base_hit_power = 12.5f;
const f32 swing_deatheffect_power = 2;

void onTick(CBlob@ this)
{
	if(this.get_u8("despelled") >= 2)
    {
        this.server_Die();
		return;
    }

	this.SetFacingLeft(false);
	Vec2f pos = this.getPosition();
	Vec2f dest = this.get_Vec2f("target_pos");
	bool fl = this.get_bool("fl");
	u32 gt = getGameTime();
	f32 deg = this.getAngleDegrees();
	f32 hit_angle = 20;

	f32 old_angle = this.get_f32("old_angle");
	this.set_f32("angle_diff", Maths::Abs(deg-old_angle) * swing_deatheffect_power);

	if (this.hasTag("swing")
		&& Maths::Abs(this.getAngleDegrees()-(fl?360-hit_angle:hit_angle)) <= 8.0f)
	{
		//this.Tag("disable_smashtoparticles");
		//makeParticlesFromSpriteAccurate(this, this.getSprite(), this.get_u16("smashtoparticles_probability"));

		this.server_Die();
		return;
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
		}
	}
	if (this.hasTag("ready"))
	{
		u32 ready_time = this.get_u32("ready_time");
		u32 diff = gt-ready_time;
		Vec2f ready_pos = this.get_Vec2f("ready_pos");

		if (this.hasTag("overcharge"))
		{
			CShape@ shape = this.getShape();
			ShapeConsts@ consts = shape.getConsts();
			shape.SetStatic(true);

			f32 factor = f32(Maths::Min(diff, spinup_time))/spinup_time;
			this.set_f32("hit_power", factor);

			this.setAngleDegrees((deg + (fl ? 1 : -1) * (max_spin_speed*factor))%360);
			this.setAngleDegrees(0);
		}
		else
		{
			this.Tag("swing");
			Vec2f target = ready_pos + Vec2f(fl ? 48 : -48, 32);
			if (diff < 30)
			{
				this.setPosition(Vec2f_lerp(pos, target, diff*0.01f));
				this.setAngleDegrees(Lerp(deg, fl ? 180-65 : 180+65, 0.1f)%360);
			}
			else
			{
				this.Tag("swinging");
				this.setAngleDegrees(Lerp(deg, fl ? 360-hit_angle : hit_angle, Maths::Min(0.0f+(diff-30)*0.05f, 1))%360);
				deg = this.getAngleDegrees();
				Vec2f arc = Vec2f(0, -this.getRadius()).RotateBy(deg);
				this.setPosition(ready_pos + arc);
			}
		}
	}

	this.set_f32("old_angle", deg);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	this.server_SetTimeToDie(60);
	if (blob !is null)
	{
		f32 hp = this.get_f32("hit_power");
		if (!isEnemy(this, blob) && this.hasTag("ready") && (!this.hasTag("swing") || this.hasTag("swinging")))
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
			
			f32 deg = Maths::Abs(this.getAngleDegrees());
			f32 angle = deg;
			angle = angle%360;

			// both sides push you in one side when overcharged (lower part shoul be opposite)

			if (this.hasTag("overcharge"))
			{
				
			}

			f32 side = this.hasTag("overcharge") ? 0 : (fl?0:180);
			blob.AddForce(Vec2f(blob.getMass() * power, 0).RotateBy(angle + side));

			if (isServer())
			{
				//this.server_Hit(blob, blob.getPosition(), this.getVelocity(), dmg, Hitters::crush, true);
			}
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
            MakeParticle(pos + offset, pvel, px_col, 500, sin, hp == 0.0f ? Vec2f(0, 1) : Vec2f_zero);
        }

        return true;
    }

    return false;
}

void MakeParticle(Vec2f pos, Vec2f vel, SColor col, f32 layer, f32 damp, Vec2f grav)
{
    CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
    if(p !is null)
    {
        p.bounce = 0.15f + XORRandom(26)*0.01f;
        p.fastcollision = true;
		p.collides = false;
        p.gravity = Vec2f(0, 0.5f);
        p.timeout = 10+XORRandom(20);
        p.Z = layer;
		p.gravity = grav;
		p.damping = 0.85f+damp;
    }
}