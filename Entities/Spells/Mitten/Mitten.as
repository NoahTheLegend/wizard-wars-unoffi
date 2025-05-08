#include "Hitters.as";
#include "MakeDustParticle.as";
#include "MagicCommon.as";
#include "TextureCreation.as";

// pistol
const Vec2f follow_offset = Vec2f(-32.0f, -32.0f);
const Vec2f fire_offset = Vec2f(32.0f,-8.0f);
const u32 shoot_delay = 12;
const f32 max_bullet_angle_deviation = 2.5f;
const f32 max_visual_recoil = 20.0f;
const f32 recoil_falloff_accel = 2;
const f32 recoil_time = 120; // affected by recoil_falloff_accel
const f32 recoil_falloff_delay = 8;
const f32 bullet_mana_cost = 1;
// slam & swipe
const f32 min_dmg = 0.5f;
const f32 max_dmg = 5.0f;
const f32 base_radius = 32.0f;
const f32 damp = 2.0f;
const f32 horizontal_acceleration = 1.5f;

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("cantparry");
	this.Tag("follower");
	this.Tag("cantmove");
	this.Tag("phase through spells");
	this.addCommandID("shoot_fx");

	CShape@ shape = this.getShape();
    shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	shape.getConsts().net_threshold_multiplier = 0.25f;
	this.getSprite().SetZ(510);
	
	this.set_Vec2f("target_pos", Vec2f_zero);
	this.getSprite().setRenderStyle(RenderStyle::additive);

	this.set_u32("last_shot", 0);
	this.set_bool("was_fl", this.isFacingLeft());
	this.set_u8("state", 0);
	this.set_u32("running", 0);
	this.Tag("no trampoline collision");
	
	if (isClient())
	{
		this.getSprite().PlaySound("8bit_spray", 1.0f, 0.9f + XORRandom(11)*0.01f);
		int cb_id = Render::addBlobScript(Render::layer_prehud, this, "Mitten.as", "laserEffects");
	}
}	

void onTick( CBlob@ this )
{
	this.Tag("counterable");
	CBlob@ caster = getBlobByNetworkID(this.get_u16("caster"));
	if (caster is null || caster.hasTag("dead"))
	{
		this.Tag("mark_for_death");
		return;
	}

	if (caster.getPlayer() is null) return;
	if (this.get_u8("state") == 0)
		this.Tag("mitten_"+caster.getPlayer().getUsername());

	Vec2f pos = this.getPosition();
	Vec2f cpos = caster.getPosition();
	u32 gt = getGameTime();

	f32 lerp = 0.25f;
	f32 lerp_angle = Maths::Min(0.5f, this.getTickSinceCreated()/10.0f);
	f32 rotate_diff_lerp = 30; // actual lerp_angle idk im bad at math

	Vec2f caimpos = caster.getAimPos();
	bool was_fl = this.get_bool("was_fl");
	bool fl = caster.isFacingLeft();
	f32 wave_speed = 0.075f;

	if ((fl && !was_fl) || (!fl && was_fl))
		rotate_diff_lerp = 360;

	Vec2f cpos_idle = cpos + Vec2f(fl ? -follow_offset.x : follow_offset.x, follow_offset.y); // idle
	cpos_idle += Vec2f(0, Maths::Sin(gt*wave_speed)*2);

	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.set_Vec2f("target_pos", cpos);
	}

	u8 state = this.get_u8("state");

	if (state == 0) // gun
	{
		Vec2f dir = caimpos-(pos+Vec2f(0, fire_offset.y));
		dir.Normalize();

		f32 currentAngle = this.get_f32("target_angle");
		f32 targetAngle = (fl ? 180.0f : 0.0f) - dir.Angle();

		while (currentAngle < 0.0f) currentAngle += 360.0f;
		while (currentAngle >= 360.0f) currentAngle -= 360.0f;

		while (targetAngle < 0.0f) targetAngle += 360.0f;
		while (targetAngle >= 360.0f) targetAngle -= 360.0f;

		f32 angleDiff = targetAngle - currentAngle;

		if (angleDiff > 180.0f) angleDiff -= 360.0f;
		else if (angleDiff < -180.0f) angleDiff += 360.0f;

		if (angleDiff > rotate_diff_lerp) angleDiff = rotate_diff_lerp;
		else if (angleDiff < -rotate_diff_lerp) angleDiff = -rotate_diff_lerp;

		f32 angle = currentAngle + angleDiff * lerp_angle;

		while (angle < 0.0f) angle += 360.0f;
		while (angle >= 360.0f) angle -= 360.0f;

		u32 time_diff = gt-this.get_u32("last_shot");

		f32 max_visual_recoil_new = max_visual_recoil;
		f32 recoil_falloff_accel_new = recoil_falloff_accel;
		f32 recoil_time_new = recoil_time; 
		f32 recoil_falloff_delay_new = recoil_falloff_accel;

		int shoot_delay_new = shoot_delay;
		if (caster.hasTag("extra_damage"))
		{
			this.Tag("extra_damage");
			shoot_delay_new /= 2;
			wave_speed *= 2;
			max_visual_recoil_new /= 1;
			recoil_falloff_accel_new *= 1;
			recoil_time_new /= 4;
			recoil_falloff_delay_new /= 4;
		}
		else this.Untag("extra_damage");

		f32 extra_angle = (fl ? 1 : -1) * (time_diff < recoil_falloff_delay_new ? max_visual_recoil_new : Maths::Max(0, Maths::Min(
			max_visual_recoil_new,max_visual_recoil_new*(1.0f-Maths::Pow((time_diff-recoil_falloff_delay_new), recoil_falloff_accel_new)/recoil_time_new))));

		this.set_f32("target_angle", angle);
		if (isServer()) this.setAngleDegrees(angle + extra_angle);

		Vec2f tpos = this.get_Vec2f("target_pos");
		Vec2f move_to = Vec2f_lerp(tpos, cpos_idle, lerp);
		this.set_Vec2f("target_pos", move_to);
		if (isServer()) this.setPosition(move_to);

		Vec2f bullet_offset = fire_offset;
		if (fl)
		{
			bullet_offset.y *= -1;
			angle += 180;
		}
		Vec2f shoot_pos = pos+bullet_offset.RotateBy(angle);

		if (isClient())
		{
			if (gt%3==0 && time_diff < shoot_delay_new)
				smoke(shoot_pos, 2+XORRandom(2), 1, 3, true);

			if (time_diff == shoot_delay_new)
				this.getSprite().PlaySound("HandReload", 0.75f, 1.1f+XORRandom(6)*0.01f);
		}

		if (isServer())
		{
			this.server_setTeamNum(caster.getTeamNum());
			if (caster.get_bool("shift_shoot") && this.get_u32("last_shot") + shoot_delay_new < gt
				&& this.getTickSinceCreated() >= shoot_delay_new)
			{
				CBlob@ bullet = shoot(this, shoot_pos);
				if (bullet !is null)
				{
					int angle_deviation = max_bullet_angle_deviation;
					f32 angle_diff = -angle_deviation+XORRandom((angle_deviation*2+1)*10)/10.0f;
					bullet.setAngleDegrees(angle + angle_diff);
					bullet.setVelocity(Vec2f(XORRandom(vel_rnd*10)/10+bullet_vel,0).RotateBy(angle + angle_diff));
					bullet.server_SetTimeToDie(2);
					bullet.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					this.set_u32("last_shot", gt);

					CBitStream params;
					params.write_u32(gt);
					this.SendCommand(this.getCommandID("shoot_fx"), params);
				}
			}
		}

		if (isServer()) this.SetFacingLeft(fl);
	}
	else if (state == 1 || state == 3) // move for special attack
	{
		this.Untag("cantparry");

		Vec2f aimpos = this.get_Vec2f("aimpos");
		Vec2f move_to = Vec2f_lerp(this.getPosition(), aimpos, lerp);
		if ((pos-aimpos).Length() < 4.0f)
			this.set_u8("state", state == 1 ? 2 : 4);

		if (isServer())
		{
			this.setPosition(move_to);
			bool force_fl = this.get_bool("force_fl");
			this.SetFacingLeft(force_fl);

			f32 vellen = (this.getOldPosition() - this.getPosition()).Length() / 2;
			this.setAngleDegrees(Maths::Clamp(force_fl ? -vellen : vellen, -35, 35));
			
			this.getShape().checkCollisionsAgain = true;
		}
	}
	else if (state == 2) // fall to slam
	{
		if (isServer())
		{
			this.getShape().SetGravityScale(3.0f);
			bool force_fl = this.get_bool("force_fl");
			this.SetFacingLeft(force_fl);
			this.setAngleDegrees(0);
		}
	}
	else if (state == 4)
	{
		this.add_u32("running", 2);
		if (isClient())
			Setup(SColor(Maths::Min(255, this.get_u32("running")), 255, 255, 255), "mitten", false, true);

		this.setPosition(Vec2f_lerp(this.getPosition(), Vec2f(this.getPosition().x, this.get_Vec2f("aimpos").y + Maths::Sin(this.get_u32("running") / 2 * 0.1f) * 16.0f), 0.5f));

		if (isServer())
		{
			bool force_fl = this.get_bool("force_fl");
			this.AddForce(Vec2f(force_fl ? -this.getMass()/damp * horizontal_acceleration : this.getMass()/damp * horizontal_acceleration, 0));
			this.SetFacingLeft(force_fl);
			this.setAngleDegrees(0);

			CMap@ map = getMap();
			if (map !is null)
			{
				if (this.getPosition().x < this.getRadius()
					|| this.getPosition().x > map.tilemapwidth * 8 - this.getRadius())
						this.Tag("mark_for_death");
			}
		}
	}

	if (this.get_u8("state") != 0)
	{
		this.getSprite().SetAnimation("transform");
	}
	this.set_bool("was_fl", fl);
}

const f32 bullet_vel = 6.0f;
const f32 vel_rnd = 2.0f;
CBlob@ shoot(CBlob@ this, Vec2f pos)
{
	return server_CreateBlob("bullet", this.getTeamNum(), pos);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shoot_fx"))
	{
		if (isClient())
		{
			u32 gt = params.read_u32();
			this.set_u32("last_shot", gt);

			bool fl = this.isFacingLeft();
			f32 angle = this.getAngleDegrees();
			Vec2f bullet_offset = fire_offset;

			if (fl)
			{
				bullet_offset.y *= -1;
				angle += 180;
			}

			Vec2f shoot_pos = this.getPosition()+bullet_offset.RotateBy(angle);
			smoke(shoot_pos, 4+XORRandom(3), 1, 6, false);
			blast(shoot_pos, 2+XORRandom(3));

			CSprite@ sprite = this.getSprite();
			sprite.SetAnimation("fire");
			sprite.PlaySound("HandShoot", 1.0f+XORRandom(26)*0.01f, 1.5f+XORRandom(16)*0.01f);

			CBlob@ caster = getBlobByNetworkID(this.get_u16("caster"));
			if (caster is null || caster.hasTag("dead"))
			{
				this.Tag("mark_for_death");
				return;
			}

			ManaInfo@ manaInfo;
			if (!caster.get( "manaInfo", @manaInfo )) {
				return;
			}

			manaInfo.mana -= bullet_mana_cost;
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && isEnemy(this, blob) && this.get_u8("state") != 0)
	{
		f32 vellen = this.getVelocity().Length()/5;
		f32 extra = this.hasTag("extra_damage") ? 2.0f : 1.0f;
		f32 dmg = Maths::Clamp(vellen, min_dmg, max_dmg+extra);

		if (isServer())
		{
			this.IgnoreCollisionWhileOverlapped(blob, 30);
			this.server_Hit(blob, this.getPosition(), Vec2f_zero, dmg, Hitters::crush, false);
		}

		if (isClient())
			this.getSprite().PlaySound("8bit_bounce", 1.0f, 1.1f + XORRandom(16)*0.01f);
	}
}

void onDie(CBlob@ this)
{
	if (isClient())
	{
		blast(this.getPosition(), 3+XORRandom(3), 4, true);
		this.getSprite().PlaySound("8bit_disappear", 1.5f, 1.1f + XORRandom(16)*0.01f);
	}
	/*
	if (isServer() && this.get_u8("state") == 2)
	{
		CMap@ map = this.getMap();
		if (map is null) return;

		f32 vellen = this.getVelocity().Length();
		f32 extra = this.hasTag("extra_damage") ? 1.0f : 0;
		f32 dmg = Maths::Clamp(vellen, min_dmg, max_dmg+extra);
		//printf(""+vellen);

		CBlob@[] bs;
		map.getBlobsInRadius(this.getPosition(), base_radius * dmg, @bs);

		for (u16 i = 0; i < bs.size(); i++)
		{
			CBlob@ b = bs[i];
			if (b is null) continue;
			
			if (isEnemy(this, b))
				this.server_Hit(b, this.getPosition(), Vec2f_zero, dmg, Hitters::crush, false); 
		}
	}
	*/
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

bool doesCollideWithBlob(CBlob@ this, CBlob@ b)
{
	return false;
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount, f32 pvel = 1.0f, f32 pvel_rnd = 6.0f, bool transparent = false)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel = Vec2f(pvel + pvel_rnd*_smoke_r.NextFloat(), 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
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
        p.damping = 0.8f;
		p.Z = 500.0f;
		p.lighting = false;
		if (transparent)
			p.setRenderStyle(RenderStyle::additive);
    }
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount, f32 pvel = 1.0f, bool death_effect = false)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * pvel, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericBlast5.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles
		f32 extra = 0;

		if (death_effect)
		{
			p.setRenderStyle(RenderStyle::additive);
			extra = 0.5f;
			p.timeout = 10;
		}

    	p.fastcollision = true;
        p.scale = 0.75f + _blast_r.NextFloat()*0.5f + extra;
        p.damping = 0.85f;
		p.Z = 501.0f;
		p.lighting = false;
    }
}

void laserEffects(CBlob@ this, int id)
{
    if (this.get_u8("state") != 4
		|| this.get_u32("running") == 0) return;

    Vec2f thisPos = this.getPosition();
    u32 gt = getGameTime();
	
    Vec2f aimPos;
	Vec2f aimVec = aimPos - thisPos;
	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();

	Vec2f currSegPos = thisPos;				
	Vec2f prevSegPos = aimPos;

	Vec2f followVec = currSegPos - prevSegPos;
	Vec2f followNorm = followVec;
	followNorm.Normalize();

	f32 followDist = followVec.Length();
	f32 laserLength = followDist;
    f32 deg = 0;
    u32 tick = 0;

	Vec2f[] v_pos;
	Vec2f[] v_uv;

    {
		bool force_fl = this.get_bool("force_fl");
        f32 deg = this.getAngleDegrees();
        f32 size = 0.5f;
		CMap@ map = getMap();
		f32 edge = (force_fl ? this.getPosition().x : map.tilemapwidth*8-this.getPosition().x);
	    v_pos.push_back(currSegPos + Vec2f( (force_fl ? -1 : 0) * Maths::Min(edge, followDist * laserLength),-size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(0,0));//Top left?
	    v_pos.push_back(currSegPos + Vec2f( (force_fl ? 0 : 1)  * Maths::Min(edge, followDist * laserLength),-size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(1,0));//Top right?
	    v_pos.push_back(currSegPos + Vec2f( (force_fl ? 0 : 1)  * Maths::Min(edge, followDist * laserLength), size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(1,1));//Bottom right?
	    v_pos.push_back(currSegPos + Vec2f( (force_fl ? -1 : 0) * Maths::Min(edge, followDist * laserLength), size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(0,1));//Bottom left?

	    Render::Quads("mitten", -6.0f, v_pos, v_uv);

	    v_pos.clear();
	    v_uv.clear();
    }
}