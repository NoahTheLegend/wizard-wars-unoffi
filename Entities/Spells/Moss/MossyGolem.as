#include "Hitters.as";
#include "BrainPathing.as";
#include "PlayerPrefsCommon.as";

const u8 mossy_golem_cooldown = 8; // in seconds

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.getShape().getConsts().bullet = true;

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(100.0f);

	this.set_bool("turning_at_corner", false);
	this.set_u32("turning_at_corner_time", 0);
	this.set_Vec2f("gravity", Vec2f(0, grav_const));
	this.set_u32("not_on_ground_time", 0);
	this.set_u16("target_id", 0);
	this.set_u32("following_target", 0);
	this.set_u16("idle_time", 0);
	this.server_SetTimeToDie(30);

	if (isServer())
	{
		BrainPath pather(this, Path::GROUND);
		this.set("brain_path", @pather);
	}
}

const u8 idle_time = 30;
const f32 base_accel = 1.0f;
const f32 base_accel_opposite = 2.0f;
const f32 stopping_damp_base = 0.7f;
const f32 max_vel = 8.0f;
const f32 max_aggro_len = 128.0f;
const f32 max_aggro_len_los = 256.0f;
const int max_not_on_ground_time = 10;

const f32 wall_raycast_dist = 4.0f;
const f32 grav_const = 9.81f;
const u16 max_idle_time = 150;
const f32 explosion_radius = 32.0f;
const f32 damage = 1.0f;

/*void onRender(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;

	// debug render

	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();

	Vec2f debug_last_turn_next_wall = this.exists("debug_last_turn_next_wall") ? getDriver().getScreenPosFromWorldPos(this.get_Vec2f("debug_last_turn_next_wall")) : Vec2f_zero;
	Vec2f debug_last_turn_pos = this.exists("debug_last_turn_pos") ? getDriver().getScreenPosFromWorldPos(this.get_Vec2f("debug_last_turn_pos")) : Vec2f_zero;
	Vec2f debug_last_turn_velNorm = this.exists("debug_last_turn_velNorm") ? getDriver().getScreenPosFromWorldPos(this.get_Vec2f("debug_last_turn_velNorm")) : Vec2f_zero;
	Vec2f debug_last_turn_wall_surface = this.exists("debug_last_turn_wall_surface") ? getDriver().getScreenPosFromWorldPos(this.get_Vec2f("debug_last_turn_wall_surface")) : Vec2f_zero;

	GUI::DrawRectangle(debug_last_turn_next_wall - Vec2f(4, 4), debug_last_turn_next_wall + Vec2f(4, 4), SColor(255, 255, 0, 0));
	GUI::DrawRectangle(debug_last_turn_pos - Vec2f(4, 4), debug_last_turn_pos + Vec2f(4, 4), SColor(255, 0, 255, 0));
	//GUI::DrawLine2D(debug_last_turn_pos, debug_last_turn_pos + debug_last_turn_velNorm, SColor(255, 0, 0, 255));
	GUI::DrawRectangle(debug_last_turn_wall_surface - Vec2f(4, 4), debug_last_turn_wall_surface + Vec2f(4, 4), SColor(255, 255, 255, 0));

	f32 deg = this.getAngleDegrees();
	Vec2f ground_norm = Vec2f(0, 1).RotateBy(deg);
	bool onground = hasSolidGround(this, this.getPosition() + ground_norm * 8);

	GUI::SetFont("menu");
	GUI::DrawText("Position: " + pos, Vec2f(50, 235), SColor(255, 255, 255, 0));
	GUI::DrawText("Turning at corner: " + (this.get_bool("turning_at_corner") ? "true" : "false"), Vec2f(50, 250), SColor(255, 255, 255, 0));
	GUI::DrawText("Turning time: " + this.get_u32("turning_at_corner_time"), Vec2f(50, 265), SColor(255, 255, 255, 0));
	GUI::DrawText("Climbing up: " + (this.get_bool("climbing_up") ? "true" : "false"), Vec2f(50, 280), SColor(255, 255, 255, 0));
	GUI::DrawText("Gravity: " + this.get_Vec2f("gravity"), Vec2f(50, 295), SColor(255, 255, 255, 0));
	GUI::DrawText("Velocity: " + vel, Vec2f(50, 310), SColor(255, 255, 255, 0));
	GUI::DrawText("On ground: " + (onground ? "true" : "false"), Vec2f(50, 325), SColor(255, 255, 255, 0));
	GUI::DrawText("Ground normal: " + ground_norm, Vec2f(50, 340), SColor(255, 255, 255, 0));

	Vec2f velNorm = clampToCardinal(vel);
	f32 vellen = vel.Length();
	GUI::DrawLine(pos, pos + velNorm * wall_raycast_dist * vellen, SColor(255, 255, 255, 255));

	BrainPath@ pather;
	if (!this.get("brain_path", @pather)) return;

	pather.Render();
}
*/

Vec2f clampToCardinal(Vec2f vel)
{
	if (vel.Length() < 0.1f) return Vec2f_zero;

	Vec2f norm = vel;
	norm.Normalize();

	if (Maths::Abs(norm.x) > Maths::Abs(norm.y))
	{
		norm.y = 0;
		norm.x = norm.x > 0 ? 1 : -1;
	}
	else
	{
		norm.x = 0;
		norm.y = norm.y > 0 ? 1 : -1;
	}

	return norm;
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		this.getShape().SetGravityScale(0.0f); // we have own gravity
		this.getSprite().PlaySound("TreeGrow", 1.0f, 0.8f+XORRandom(10)*0.01f);

		CPlayer@ owner = this.getDamageOwnerPlayer();
		if (owner !is null)
		{
			PlayerPrefsInfo@ playerPrefsInfo;
			if (!owner.get("playerPrefsInfo", @playerPrefsInfo))
			{
				return;
			}

			playerPrefsInfo.spell_cooldowns[9] = mossy_golem_cooldown*30;
			print("Mossy Golem cooldown set: " + playerPrefsInfo.spell_cooldowns[9]);
		}
	}
	
	//if (isClient() && isServer())
	//{
	//	if (getControls().isKeyJustPressed(KEY_KEY_R))
	//	{
	//		this.setPosition(getPlayerByUsername("NoahTheLegend").getBlob().getPosition());
	//	}
	//	if (getControls().isKeyJustPressed(KEY_KEY_K))
	//		this.server_Die();
	//}

	CMap@ map = getMap();
	if (map is null) return;
	
	f32 vellen = this.getVelocity().Length();
	bool fl = this.isFacingLeft();
	
	f32 accel = base_accel / (1.0f+vellen);
	f32 stopping_damp = stopping_damp_base;

	f32 deg = this.getAngleDegrees();
	Vec2f ground_norm = Vec2f(0, 1).RotateBy(deg);

	bool onground = hasSolidGround(this, this.getPosition() + ground_norm * 8);
	bool wasonground = this.get_bool("was_on_ground");

	this.set_u32("not_on_ground_time", onground ? 0 : Maths::Min(this.get_u32("not_on_ground_time") + 1, max_not_on_ground_time));
	if (this.get_u32("not_on_ground_time") >= max_not_on_ground_time) this.set_Vec2f("gravity", Vec2f(0, grav_const));

	u16 idle_time = this.get_u16("idle_time");
	bool turning_at_corner = this.get_bool("turning_at_corner");

	Vec2f grav = this.get_Vec2f("gravity");
	this.setAngleDegrees(-grav.getAngleDegrees() - 90);

	if (onground && turning_at_corner && this.get_u32("turning_at_corner_time") + 8 < getGameTime())
	{
		this.set_bool("turning_at_corner", false);
		this.set_u32("turning_at_corner_time", 0);
		return;
	}

	Vec2f pos = this.getPosition();
	if (map is null) return;

	Vec2f vel = this.getVelocity();
	Vec2f velNorm = clampToCardinal(vel);

	Vec2f nextpos = pos + vel;
	Vec2f next_wall = Vec2f_zero;

	if (!turning_at_corner && map.rayCastSolidNoBlobs(pos, pos + velNorm * wall_raycast_dist * vellen * 2, next_wall))
	{
		Vec2f dist = next_wall - pos;
		if (dist.Length() <= 16.0f)
		{
			Vec2f wall_surface = clampToCardinal(dist);
			wall_surface.RotateBy(-90);
			setTurningAtCorner(this, wall_surface);

			//this.set_Vec2f("debug_last_turn_velNorm", velNorm);
			//this.set_Vec2f("debug_last_turn_pos", pos);
			//this.set_Vec2f("debug_last_turn_next_wall", next_wall);
			//this.set_Vec2f("debug_last_turn_wall_surface", wall_surface);
		}
	}

	f32 stop_before_cliff = 1;
	if (!turning_at_corner && !map.rayCastSolidNoBlobs(pos + velNorm * 16, pos + velNorm * 16 + ground_norm * 16))
	{
		// check floor
		Vec2f wall_surface = clampToCardinal(velNorm);
		wall_surface.RotateBy(90);

		if (!wasonground)
		{
			setTurningAtCorner(this, wall_surface);
			this.setVelocity(this.getVelocity() + (fl ? -wall_surface.RotateBy(-45) : wall_surface.RotateBy(45) * 4));
		}
	}

	if (isServer())
	{
		Vec2f target = Vec2f_zero;

		BrainPath@ pather;
		if (!this.get("brain_path", @pather)) return;
		pather.Tick();
		pather.SetSuggestedKeys();
		pather.SetSuggestedAimPos();

		u16 target_id = this.get_u16("target_id");
		u32 following_time = this.get_u32("following_target");
		bool has_target = target_id > 0 || following_time > getGameTime();

		if (has_target)
		{
			CBlob@ found = getBlobByNetworkID(target_id);
			if (found is null)
			{
				has_target = false;
				
				this.set_u16("target_id", 0);
				this.set_u32("following_target", 0);
			}
			else
			{
				target = found.getPosition();
				this.set_u32("following_target", getGameTime() + 90);
			}
		}

		if (!has_target && this.getTickSinceCreated() >= idle_time)
		{
			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p !is null && p.getBlob() !is null)
				{
					CBlob@ b = p.getBlob();
					if (b.getTeamNum() == this.getTeamNum())
							continue;

					if (b.getDistanceTo(this) > max_aggro_len_los)
						continue;

					bool raycast = map.rayCastSolidNoBlobs(pos, b.getPosition(), next_wall);
					if (raycast && b.getDistanceTo(this) > max_aggro_len)
						continue;

					fl = b.getPosition().x < pos.x;
					this.SetFacingLeft(fl);
					target = b.getPosition();
				}
			}
		}

		//if (isClient() && isServer())
		//{
		//	if (getControls().isKeyPressed(KEY_KEY_X))
		//		target = getPlayerByUsername("NoahTheLegend").getBlob().getPosition();
		//}

		bool found_ground = false;
		if (!onground && wasonground)
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

					if (map.rayCastSolidNoBlobs(pos - Vec2f(0, this.getRadius()), step-Vec2f(0, 8)))
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

		this.AddForce(Vec2f(0, grav_const).RotateBy(this.getAngleDegrees()) * this.getMass() / 30);
		if (target == Vec2f_zero)
		{
			if (idle_time < max_idle_time) this.add_u16("idle_time", 1);

			pather.EndPath();
			Vec2f rot_vel = vel;

			rot_vel.RotateBy(-deg);
			this.setVelocity(Vec2f(rot_vel.x * stopping_damp, rot_vel.y).RotateBy(deg));
		}
		else if (onground && vellen < max_vel)
		{
			this.set_u16("idle_time", 0);

			if (!pather.isPathing()) pather.SetPath(pos, target);
			Vec2f target_dir = pather.path.size() > 0 ? pather.path[0] - pos : target - pos;

			target_dir.Normalize();
			target_dir.RotateBy(-deg);

			Vec2f rot_vel = vel;
			rot_vel.RotateBy(-deg);

			if ((target_dir.x < 0 && rot_vel.x > 0) || (target_dir.x > 0 && rot_vel.x < 0))
				accel *= base_accel_opposite;

			Vec2f forward = Vec2f(1, 0).RotateBy(deg);
			Vec2f force = forward * stop_before_cliff * (target_dir.x < 0 ? -accel : target_dir.x > 0 ? accel : 0) * this.getMass();
			this.AddForce(force);

			if (vel.Length() > 0.1f) this.SetFacingLeft(target_dir.x < 0);
		}
	}

	this.set_bool("was_on_ground", onground);
	if (!isClient()) return;
	
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	string anim_name = sprite.animation.name;
	bool anim_ended = sprite.isAnimationEnded();

	if (turning_at_corner || (anim_name.find("cl") != -1 && !anim_ended))
	{
		sprite.SetAnimation(this.get_bool("climbing_up") ? "climb_down" : "climb_up");
	}
	else if (idle_time == max_idle_time)
	{
		sprite.SetAnimation("sleep");
	}
	else if (onground)
	{
		sprite.SetAnimation(vel.Length() > 0.25f ? "run" : "idle");
		sprite.animation.time = 6 - Maths::Min(vellen/2, 3);
	}
	else
	{
		Vec2f grav = this.get_Vec2f("gravity");
		Vec2f vel = this.getVelocity();

		f32 grav_dir = grav.Angle();
		f32 vel_proj = vel.RotateBy(-grav_dir).y;
		if (vel_proj > 0.0f)
			sprite.SetAnimation("fall");
		else
			sprite.SetAnimation("jump");
	}
}

void setTurningAtCorner(CBlob@ this, Vec2f dir)
{
	Vec2f ground_norm = Vec2f(0, 1).RotateBy(this.getAngleDegrees());
	this.set_bool("climbing_up", Maths::Abs(dir.Angle()) - Maths::Abs(ground_norm.Angle()) > 0);

	this.set_bool("turning_at_corner", true);
	this.set_u32("turning_at_corner_time", getGameTime());

	Vec2f grav = Vec2f(0, grav_const).RotateBy(-dir.Angle());
	grav.x = Maths::Round(grav.x * 100.0f) / 100.0f; // round to 2 decimals
	grav.y = Maths::Round(grav.y * 100.0f) / 100.0f;
	this.set_Vec2f("gravity", grav);
}

bool hasSolidGround(CBlob@ this, Vec2f pos)
{
	CMap@ map = getMap();
	if (map is null) return false;

	TileType tile = map.getTile(pos).type;
	if (map.isTileSolid(tile))
		return true;

	CBlob@[] bs;
	map.getBlobsAtPosition(pos, @bs);

	for (u8 k = 0; k < bs.size(); k++)
	{
		CBlob@ b = bs[k];
		if (b is null) continue;

		if (b.hasTag("door") && b.isCollidable())
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
		blob.getName() == this.getName()
		||
		(
			blob.hasTag("barrier") && blob.getTeamNum() != this.getTeamNum()
		)
	);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if(this is null)
	{return;}

	bool blobDeath = false;
	if (blob !is null && isEnemy(this, blob) && this.getTickSinceCreated() >= idle_time)
	{
		blobDeath = true;
	}

	if (blobDeath && isServer())
	{
		this.Tag("mark_for_death");

		CBlob@[] bs;
		getMap().getBlobsInRadius(this.getPosition(), explosion_radius, @bs);

		for (int i = 0; i < bs.length; i++)
		{
			CBlob@ blob = bs[i];
			if (blob !is null && isEnemy(this, blob))
			{
				Vec2f dir = blob.getPosition() - this.getPosition();
				f32 dir_len = dir.Length();

				dir.Normalize();
				dir *= explosion_radius * 2 - dir_len;

				this.server_Hit(blob, this.getPosition(), dir, damage, Hitters::explosion, true);
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.hasTag("counterspelled")) return;
	Vec2f pos = this.getPosition();
	u8 spores_count = 6 + XORRandom(7);
	
	if (isServer())
	{
		for (u8 i = 0; i < spores_count; i++)
		{
			Vec2f vel(0, -1.0f - XORRandom(31) * 0.1f);
			vel.RotateBy(this.getAngleDegrees() - 90 + XORRandom(180));
			Vec2f rnd = Vec2f(XORRandom(16) - 8, XORRandom(16) - 8);

			CBlob@ spore = server_CreateBlob("sporeshot", this.getTeamNum(), pos + rnd);
			if (spore !is null)
			{
				spore.setVelocity(vel);
				spore.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
				spore.set_f32("damage", 0.4f);
			}
		}
	}
	this.getSprite().PlaySound("WizardShoot.ogg", 1.0f);

	if (isServer())
	{
		u8 bees = 3+XORRandom(4);
		for (u8 i = 0; i < bees; i++)
		{
			Vec2f vel(0, -2.0f - XORRandom(3));
			vel.RotateBy(this.getAngleDegrees() - 90 + XORRandom(180));
			Vec2f rnd = Vec2f(XORRandom(16) - 8, XORRandom(16) - 8);

			CBlob@ bee = server_CreateBlob("bee", this.getTeamNum(), pos + rnd);
			if (bee !is null)
			{
				bee.setVelocity(vel);
				bee.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

				bee.set_f32("damage", 0.4f);
				bee.set_f32("heal_amount", 0.1f);
			}
		}
		this.getSprite().PlaySound("bee-0"+(XORRandom(3)+1), 0.4f, 0.9f + XORRandom(10) * 0.01f);
	}
	
	if (isClient()) smoke(this.getPosition(), 15);
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(2.0f + _smoke_r.NextFloat() * 2.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated(CFileMatcher("GenericSmoke"+(1+XORRandom(2))+".png").getFirst(), 
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
		p.colour = SColor(255, 100+XORRandom(55), 200+XORRandom(55), 125+XORRandom(35));
		p.forcecolor = SColor(255, 100+XORRandom(55), 200+XORRandom(55), 125+XORRandom(35));
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