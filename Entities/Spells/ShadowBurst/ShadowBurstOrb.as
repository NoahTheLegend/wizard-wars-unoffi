#include "Hitters.as";
#include "HittersWW.as";
#include "TextureCreation.as";

const f32 angle_change_base = 5.0f;
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("kill other spells");
	this.Tag("counterable");
	
	//dont collide with edge of the map
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	Vec2f[] old_pos;
	old_pos.push_back(this.getPosition());
	this.set("old_positions", @old_pos);

	this.set_Vec2f("aimpos", Vec2f_zero);
	this.addCommandID("aimpos sync");

	if (!isClient()) return;

	for (int i = 0; i < 2+XORRandom(6); i++)
    {
		Vec2f vel(1.0f + XORRandom(20) * 0.01f, 0);
		vel.RotateBy(XORRandom(100) * 0.01f * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke"+(1+XORRandom(2))+".png").getFirst(), 
									this.getPosition(), 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );

        if (p is null) break;

    	p.fastcollision = true;
        p.scale = 1.0f;
        p.damping = 0.925f;
		p.Z = 600.0f;
		p.lighting = false;
		p.colour = SColor(255, 200+XORRandom(55), 85+XORRandom(50), 200+XORRandom(55));
		p.forcecolor = SColor(255, 200+XORRandom(55), 85+XORRandom(50), 200+XORRandom(55));
		p.setRenderStyle(RenderStyle::additive);
    }

	Vec2f frameSize = Vec2f(32, 32);
	this.getSprite().SetVisible(false);

	SetupImage("ShadowBurstOrb.png", SColor(255, 255, 255, 255), "sb_rend0", false, false, Vec2f(0, 0), frameSize);
	SetupImage("ShadowBurstOrb.png", SColor(255, 255, 255, 255), "sb_rend1", false, false, Vec2f(0, 32), frameSize);
	SetupImage("ShadowBurstOrb.png", SColor(255, 255, 255, 255), "sb_rend2", false, false, Vec2f(0, 64), frameSize);
	SetupImage("ShadowBurstOrb.png", SColor(255, 255, 255, 255), "sb_rend3", false, false, Vec2f(0, 32), frameSize);

	int cb_id = Render::addBlobScript(Render::layer_prehud, this, "ShadowBurstOrb.as", "laserEffects");
}

const int positions_save_time_in_seconds = 15;
const u8 old_positions_save_threshold = 3;

const f32 ticks_noclip = 0;
void onTick(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = this.getTickSinceCreated() >= ticks_noclip;

	if (this.getTickSinceCreated() % old_positions_save_threshold == 0)
	{
		Vec2f[]@ positions;
		if (this.get("old_positions", @positions))
		{
			if (positions.size() > positions_save_time_in_seconds * Maths::Round(f32(getTicksASecond()) / f32(old_positions_save_threshold)))
			{
				positions.erase(positions.size() - 1);
			}

			positions.insertAt(0, this.getPosition());
		}
	}

	if (!this.hasTag("no_projectiles"))
	{
		Vec2f aimpos = this.get_Vec2f("aimpos");

		CPlayer@ p = this.getDamageOwnerPlayer();
		if (p !is null)
		{
			CBlob@ b = p.getBlob();
			if (b !is null)
			{
				if (p.isMyPlayer())
				{
					aimpos = b.getAimPos();

					CBitStream params;
					params.write_Vec2f(aimpos);
					this.SendCommand(this.getCommandID("aimpos sync"), params);
				}
			}
		}

		if (this.hasTag("aiming"))
		{
			Vec2f pos = this.getPosition();
			Vec2f vel = this.getVelocity();

			if (vel == Vec2f_zero)
			{
				vel.x += 1.0f - XORRandom(3);
				vel.y += 1.0f - XORRandom(3);
			}

			Vec2f dir = aimpos - pos;
			dir.Normalize();

			f32 current_angle = vel.Angle();
			f32 target_angle = dir.Angle();
			f32 angle_diff = target_angle - current_angle;

			while (angle_diff > 180.0f) angle_diff -= 360.0f;
			while (angle_diff < -180.0f) angle_diff += 360.0f;

			f32 correction = Maths::Clamp(angle_diff, -angle_change_base, angle_change_base);
			Vec2f new_vel = vel.RotateBy(-correction);

			// Keep speed consistent
			new_vel.Normalize();
			new_vel *= Maths::Clamp(vel.Length(), 2.0f, 10.0f);

			this.setVelocity(new_vel);
		}
	}

	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	if (getGameTime() % 1 == 0 && this.getTickSinceCreated() > 3)
    {
        CParticle@ p = ParticleAnimated("ShadowBurstOrb.png", this.getPosition(), Vec2f_zero, this.getAngleDegrees(), 0.5f, 3, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
			p.fastcollision = true;
			p.timeout = 30;
            p.growth = -0.05f;
	    	p.Z = -1.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
    }
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door")
		|| target.getName() == "trap_block") || (target.hasTag("barrier") && target.getTeamNum() != this.getTeamNum()))
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
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
	
	return (isEnemy(this, blob));
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f p1, Vec2f p2)
{
	if (solid && blob is null)
	{
		this.Tag("mark_for_death");
		CMap@ map = this.getMap();
		
		if (this.hasTag("no_projectiles")) return;
		
		Vec2f pdir = normal;
		pdir.Normalize();
		Vec2f pdirNormal = pdir;

		f32 t = 8;
		pdir *= this.getRadius() * 2;

		Vec2f[] checks = {Vec2f(t, 0), Vec2f(-t, 0), Vec2f(0, t), Vec2f(0, -t)};
		Vec2f[] dirs;

		Vec2f pos = p2 + pdir;
		Vec2f offset = Vec2f_zero;
		pos = Vec2f(Maths::Floor(pos.x / 8) * 8, Maths::Floor(pos.y / 8) * 8) + Vec2f(4, 4);

		for (u8 i = 0; i < checks.length; i++)
		{
			Vec2f check_pos = pos + checks[i];
			Vec2f opposite_pos = pos - checks[i];

			bool opposite_is_solid = map.isTileSolid(opposite_pos);
			u8 solid_count = 0;
			
			for (u8 j = 0; j < checks.length; j++)
			{
				Vec2f other_pos = p2 + checks[j];
				if (map.isTileSolid(other_pos))
				{
					solid_count++;
					if (solid_count >= 2) break;
				}
			}
			offset += opposite_is_solid ? checks[i] : Vec2f_zero;

			if (!map.isTileSolid(check_pos) && (!opposite_is_solid || solid_count == 2))
			{
				dirs.push_back(checks[i]);
			}
		}

		if (isServer())
		{
			for (u8 i = 0; i < dirs.length; i++)
			{
				CBlob@ orb = server_CreateBlob("shadowburstorb", this.getTeamNum(), pos);
				if (orb !is null)
				{
					Vec2f dir = dirs[i];
					dir.Normalize();
					orb.setVelocity(dir * 8.0f);
					orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					orb.server_SetTimeToDie(5.0f);

					orb.set_f32("damage", this.get_f32("damage"));
					orb.Tag("no_projectiles");
					orb.Sync("no_projectiles", true);
				}
			}
		}
	}
	
	if (blob !is null && doesCollideWithBlob(this, blob) && !this.hasTag("mark_for_death"))
	{
		this.Tag("mark_for_death");

		if (isServer())
		{
			f32 damage = this.get_f32("damage");
			if (blob.hasTag("barrier")) damage *= 10;

			this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::explosion, true);
		}

		if (!this.hasTag("no_projectiles"))
		{
			Vec2f[]@ positions;
			if (!this.get("old_positions", @positions))
			{
				return;
			}

			u8 ticks_warp = 3;
			int index = Maths::Min(positions.length-1, ticks_warp * old_positions_save_threshold);
			Vec2f at = positions[index];

			this.getSprite().PlaySound("ShadowBurstShoot.ogg", 0.75f, 1.5 + XORRandom(11) * 0.01f);
			for (int i = 0; i < 2+XORRandom(6); i++)
    		{
				Vec2f vel(1.0f + XORRandom(20) * 0.01f, 0);
				vel.RotateBy(XORRandom(100) * 0.01f * 360.0f);

    		    CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke"+(1+XORRandom(2))+".png").getFirst(), 
											at, 
											vel, 
											float(XORRandom(360)), 
											1.0f, 
											4 + XORRandom(8), 
											0.0f, 
											false );

    		    if (p is null) break;

    			p.fastcollision = true;
    		    p.scale = 1.0f;
    		    p.damping = 0.925f;
				p.Z = 600.0f;
				p.lighting = false;
				p.colour = SColor(255, 200+XORRandom(55), 85+XORRandom(50), 200+XORRandom(55));
				p.forcecolor = SColor(255, 200+XORRandom(55), 85+XORRandom(50), 200+XORRandom(55));
				p.setRenderStyle(RenderStyle::additive);
    		}

			if (isServer())
			{
				CBlob@ orb = server_CreateBlob("shadowburstorb", this.getTeamNum(), at);
				if (orb !is null)
				{
					Vec2f dir = blob.getPosition() - at;
					dir.Normalize();

					orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					orb.setVelocity(dir * 8.0f);
					orb.server_SetTimeToDie(2.5f + XORRandom(51) * 0.01f);

					orb.set_f32("damage", this.get_f32("damage"));
					orb.Tag("no_projectiles");
					orb.Sync("no_projectiles", true);
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (!this.hasTag("no_projectiles"))
		this.getSprite().PlaySound("CardDie.ogg", 0.5f, 0.45f+XORRandom(11) * 0.01f);
	else
		this.getSprite().PlaySound("exehit.ogg", 0.75f, 1.25f + XORRandom(10) * 0.1f);

	Boom(this);
	sparks(this.getPosition(), 50);
}

void Boom(CBlob@ this)
{
	makeSmokeParticle(this);
	if (!isServer()) return;
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel = Vec2f_zero, const string filename = "GenericBlast")
{
	const f32 rad = 2.0f;
	Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64) * 0.015625f * rad;
	{
		CParticle@ p = ParticleAnimated(this.hasTag("no_projectiles") ? filename + "6.png" : filename + "5.png", 
										this.getPosition(), 
										vel, 
										float(XORRandom(360)), 
										1.0f + XORRandom(50) * 0.01f,
										3, 
										0.0f, 
										false);

		if (p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			p.colour = SColor(255, 200+XORRandom(55), 85+XORRandom(50), 200+XORRandom(55));
			p.forcecolor = SColor(255, 200+XORRandom(55), 85+XORRandom(50), 200+XORRandom(55));
			p.setRenderStyle(RenderStyle::additive);
			p.Z = 1.5f;
		}
	}
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

		u8 rnd = XORRandom(100);
		SColor col = SColor(255, 200+XORRandom(55), 55+rnd, 155+rnd);
        CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
        if (p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
		p.forcecolor = col;
        p.damping = 0.95f;
		p.gravity = Vec2f_zero;
		p.setRenderStyle(RenderStyle::additive);
    }
}

const string[] anim_loop = {
	"sb_rend0",
	"sb_rend1",
	"sb_rend2",
    "sb_rend3"
};
const u8 anim_time = 2;

void laserEffects(CBlob@ this, int id)
{
    int ts = this.getTickSinceCreated();
    string rendname = anim_loop[ts / anim_time % anim_loop.length];
    f32 z = 50.0f;

	f32 t = this.hasTag("no_projectiles") ? 5 : 10;
	f32 mod = Maths::Min(f32(ts) / t, 1.0f);
	u8 alpha = mod * 255;
	f32 s = this.hasTag("no_projectiles") ? 8.0f : 12.0f;

    Vec2f[] v_pos;
    Vec2f[] v_uv;
    SColor[] v_col;

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-s, -s) * mod);
    v_uv.push_back(Vec2f(0, 0));
    v_col.push_back(SColor(alpha, 150, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(s, -s) * mod);
    v_uv.push_back(Vec2f(1, 0));
    v_col.push_back(SColor(alpha, 150, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(s, s) * mod);
    v_uv.push_back(Vec2f(1, 1));
    v_col.push_back(SColor(alpha, 150, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-s, s) * mod);
    v_uv.push_back(Vec2f(0, 1));
    v_col.push_back(SColor(alpha, 150, 255, 255));

    Render::QuadsColored(rendname, z, v_pos, v_uv, v_col);
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("aimpos sync"))
    {
        this.set_Vec2f("aimpos", params.read_Vec2f());
    }
}