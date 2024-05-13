#include "Hitters.as";
#include "MakeDustParticle.as";

const Vec2f follow_offset = Vec2f(-32.0f, -32.0f);
const Vec2f fire_offset = Vec2f(32.0f,-8.0f);
const u32 shoot_delay = 30;
const f32 max_bullet_angle_deviation = 5.0f;
const f32 max_visual_recoil = 20.0f;
const f32 recoil_falloff_accel = 2;
const f32 recoil_time = 120; // affected by recoil_falloff_accel
const f32 recoil_falloff_delay = 8;

void onInit(CBlob@ this)
{
	this.Tag("cantparry");
	this.addCommandID("shoot_fx");

    this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(510);
	
	this.set_Vec2f("target_pos", Vec2f_zero);
	this.getSprite().setRenderStyle(RenderStyle::additive);

	this.set_u32("last_shot", 0);
	this.set_bool("was_fl", this.isFacingLeft());
}	

void onTick( CBlob@ this )
{     
	CBlob@ caster = getBlobByNetworkID(this.get_u16("caster"));
	if (caster is null || caster.hasTag("dead"))
	{
		this.server_Die();
		return;
	}

	if (caster.getPlayer() is null) return;
	this.Tag(""+caster.getPlayer().getUsername());

	Vec2f pos = this.getPosition();
	Vec2f cpos = caster.getPosition();
	u32 gt = getGameTime();

	f32 lerp = 0.25f;
	f32 lerp_angle = Maths::Min(0.75f, this.getTickSinceCreated()/10.0f);
	f32 angle_max_diff = 30;

	bool was_fl = this.get_bool("was_fl");
	bool fl = caster.isFacingLeft();
	f32 wave_speed = 0.075f;

	Vec2f cpos_wof = cpos + Vec2f(fl ? -follow_offset.x : follow_offset.x, follow_offset.y); // idle
	cpos_wof += Vec2f(0, Maths::Sin(gt*wave_speed)*2);
	this.SetFacingLeft(fl);

	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.set_Vec2f("target_pos", cpos);
	}

	Vec2f caimpos = caster.getAimPos();
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

	if (angleDiff > angle_max_diff) angleDiff = angle_max_diff;
	else if (angleDiff < -angle_max_diff) angleDiff = -angle_max_diff;

	f32 angle = currentAngle + angleDiff * lerp_angle;

	while (angle < 0.0f) angle += 360.0f;
	while (angle >= 360.0f) angle -= 360.0f;

	u32 time_diff = gt-this.get_u32("last_shot");
	f32 extra_angle = (fl ? 1 : -1) * (time_diff < recoil_falloff_delay ? max_visual_recoil : Maths::Max(0, Maths::Min(
		max_visual_recoil,max_visual_recoil*(1.0f-Maths::Pow((time_diff-recoil_falloff_delay), recoil_falloff_accel)/recoil_time))));

	this.set_f32("target_angle", angle);
	this.setAngleDegrees(angle + extra_angle);
	//if ((fl && !was_fl) || (!fl && was_fl))
	//	this.setAngleDegrees(this.getAngleDegrees()+180);

	Vec2f tpos = this.get_Vec2f("target_pos");
	Vec2f move_to = Vec2f_lerp(tpos, cpos_wof, lerp);
	this.set_Vec2f("target_pos", move_to);
	this.setPosition(move_to);

	Vec2f bullet_offset = fire_offset;
	if (fl)
	{
		bullet_offset.y *= -1;
		angle += 180;
	}
	Vec2f shoot_pos = pos+bullet_offset.RotateBy(angle);

	if (isClient())
	{
		if (gt%3==0 && time_diff < shoot_delay)
			smoke(shoot_pos, 2+XORRandom(2), 1, 3, true);
		
		if (time_diff == shoot_delay)
			this.getSprite().PlaySound("HandReload", 0.75f, 1.1f+XORRandom(6)*0.01f);
	}

	if (isServer())
	{
		this.server_setTeamNum(caster.getTeamNum());
		if (caster.get_bool("shifting") && this.get_u32("last_shot") + shoot_delay < gt)
		{
			CBlob@ bullet = shoot(this, shoot_pos);
			if (bullet !is null)
			{
				int angle_deviation = max_bullet_angle_deviation;
				f32 angle_diff = -angle_deviation+XORRandom((angle_deviation*2+1)*10)/10.0f;
				bullet.setAngleDegrees(angle + angle_diff);
				bullet.setVelocity(Vec2f(XORRandom(vel_rnd*10)/10+bullet_vel,0).RotateBy(angle + angle_diff));
				bullet.server_SetTimeToDie(2);
				this.set_u32("last_shot", gt);
				
				CBitStream params;
				params.write_u32(gt);
				this.SendCommand(this.getCommandID("shoot_fx"), params);
			}
		}
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
			sprite.PlaySound("HandShoot", 1.0f+XORRandom(26)*0.01f, 1.1f+XORRandom(11)*0.01f);
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		target != null
		&& target.hasTag("player") //all counterables
		&& !target.hasTag("dead") 
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
		p.Z = 200.0f;
		p.lighting = false;
		if (transparent) p.setRenderStyle(RenderStyle::additive);
    }
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount, f32 pvel = 1.0f)
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

    	p.fastcollision = true;
        p.scale = 0.75f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
		//p.setRenderStyle(RenderStyle::additive);
    }
}