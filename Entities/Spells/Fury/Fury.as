#include "Hitters.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	this.set_f32("lerpfactor", 0);
	this.Tag("projectile");
    this.Tag("counterable");
	this.Tag("phase through spells");
	shape.SetGravityScale( 0.0f );

	this.set_f32("damage", 1.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
    this.server_SetTimeToDie(10);

	this.set_bool("has_target", false);
	this.set_u32("lock_time", 0);

	this.getSprite().SetRelativeZ(11.0f);
	this.getSprite().setRenderStyle(RenderStyle::additive);

	this.set_Vec2f("smashtoparticles_grav", Vec2f(0,0));
    this.set_Vec2f("smashtoparticles_grav_rnd", Vec2f(0,0));
	this.Tag("smashtoparticles_additive");
}

f32 cap_dist = 256.0f + 64.0f;
f32 angle_change_base = 4.0f;
f32 damping = 0.975f;
const f32 decel = 12;

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;

	this.SetFacingLeft(this.getVelocity().x < 0);
	if (this.getTickSinceCreated()==0)
	{
		this.getSprite().PlaySound("flame_slash_sound.ogg", 1.75f, 1.45f + XORRandom(16)*0.01f);
	}

	CMap@ map = getMap();
	if (map is null) return;
	if (this.getPosition().y > map.tilemapheight*8 - 16.0f)
		this.AddForce(Vec2f(0, -this.getMass() * 4));

	// find target
	if (this.getTickSinceCreated() < 5) return;

	f32 dist = cap_dist;
	u16 closest_id = 0;

	for (int i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p is null || p.getBlob() is null) continue;

		CBlob@ b = p.getBlob();
		if (!isEnemy(this, b)) continue;

		f32 cur_dist = this.getDistanceTo(b);
		if (cur_dist >= dist) continue;

		f32 dist = cur_dist;
		closest_id = b.getNetworkID();
	}

	CBlob@ closest = getBlobByNetworkID(closest_id);
	if (closest !is null)
	{
	    this.server_SetTimeToDie(5);
		
	    this.set_bool("has_target", true);
	    if (this.get_u32("lock_time") == 0)
			this.set_u32("lock_time", getGameTime());

		

	    Vec2f vel = this.getVelocity();
	    vel.Normalize();
	    int vel_angle = -vel.Angle();

	    Vec2f dir = closest.getPosition() - this.getPosition();
	    int dir_angle = -dir.Angle();

		f32 momentum = this.get_f32("momentum");
		f32 target_speed = Maths::Clamp(dir.Length() / decel, 2.0f, 10.0f);
		f32 speed_mod = Maths::Lerp(momentum, target_speed, 1.0f - damping);
	    int cross = vel.x * dir.y - vel.y * dir.x;

		this.set_f32("momentum", Maths::Max(speed_mod, target_speed));
	
	    f32 r = angle_change_base * Maths::Max(1.0f, speed_mod/4);
	    f32 angle_shift = (cross > 0) ? r : -r;

		if (vel == Vec2f_zero)
		{
			vel.x += 1.0f - XORRandom(3);
			vel.y += 1.0f - XORRandom(3);
		}
		if (getGameTime() - this.get_u32("lock_time") < 15)
		{
			f32 lerpfactor = this.get_f32("lerpfactor");
			lerpfactor = Maths::Min(lerpfactor, 1.0f);
			this.setPosition(Vec2f_lerp(this.getPosition(), closest.getPosition(), lerpfactor));
			lerpfactor += 0.005f;
			this.set_f32("lerpfactor", lerpfactor);
		}
		else this.setVelocity(vel.RotateBy(angle_shift) * speed_mod);

		if (isServer() && getGameTime() % this.get_f32("spawnrate") == 0)
		{
			Vec2f rndpos = this.getPosition() + Vec2f(this.getRadius(), 0).RotateBy(XORRandom(360));
			CBlob@ proj = server_CreateBlob("furyprojectile", this.getTeamNum(), rndpos);
			if (proj !is null)
			{
				proj.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
				proj.server_SetTimeToDie(2);
				proj.set_f32("damping", 0.95f);
				proj.set_f32("damage", 0.2f);
				proj.setVelocity(Vec2f(8.0f+XORRandom(21)*0.1f, 0).RotateBy(-(rndpos-this.getPosition()).Angle()+90));
			}
		}
	}
	else
	{
		this.set_bool("has_target", false);
	    this.set_u32("lock_time", 0);
		this.set_f32("lerpfactor", 0);
	}
	//this.setVelocity(Vec2f_zero);
}

void Particles(CBlob@ this, u8 amount, f32 force)
{
	if (this.hasTag("dead"))
	{return;}

	if(!isClient())
	{return;}
	
	CMap@ map = getMap();
	if (map is null)
	{return;}

	Vec2f pos = this.getOldPosition();
	for(int i = 0; i < amount; i++)
	{
		Vec2f rnd = Vec2f((XORRandom(amount*10)-amount*5)*0.1f, (XORRandom(amount*10)-amount*5)*0.1f);
		Vec2f pPos = pos+Vec2f(this.getRadius() * (i%2==0?-1:1), 0).RotateBy(getGameTime()%360 * 8)+rnd;
		Vec2f pVel = Vec2f(force, 0).RotateBy(-(pPos-pos).Angle()+90);

    	CParticle@ p = ParticlePixelUnlimited(pPos, pVel, SColor(255,255,75+XORRandom(155),XORRandom(85)), true);
   		if(p !is null)
    	{ // launch particles with angular velocity
    	    p.collides = false;
    	    p.gravity = Vec2f_zero;
    	    p.bounce = 1;
    	    p.lighting = false;
    	    p.timeout = 15;
			p.damping = 0.9f + XORRandom(61)*0.001f;
    	}
	}
}

void onTick(CSprite@ this) //rotating sprite
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	bool has_target = blob.get_bool("has_target");
	u32 lock_time = blob.get_u32("lock_time");

	f32 power = 8;
	f32 scale = 2;
	f32 mod = 5;

	if (!has_target)
	{
		this.animation.time = 3;

		//Particles(blob, 2, 1.0f);
	}
	else
	{
		this.animation.time = 2;

		int diff = Maths::Clamp(Maths::Min(power*scale*mod, getGameTime()-lock_time), 0, 50);
		f32 rot = power+diff/mod;

		//Particles(blob, 6, rot/power);
	}
}

void onDie(CBlob@ this)
{
	if (isClient()) 
	{
		Vec2f thisPos = this.getPosition();

		CMap@ map = getMap();
		if (map is null)
		{return;}

		this.getSprite().PlaySound("Whack"+(1+XORRandom(3))+".ogg", 1.5f, 1.0f + XORRandom(10)/10.0f);
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		target.getPlayer() !is null && target.getTeamNum() != this.getTeamNum() 
	);
}