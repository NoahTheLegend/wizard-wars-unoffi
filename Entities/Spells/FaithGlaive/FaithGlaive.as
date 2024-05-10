#include "Hitters.as"
#include "TeamColour.as";

const u16 target_angle = 90;
const f32 start_angle = -15;
const f32 accel = 0.5f;
const u8 wait_time = 20;
const Vec2f glaive_offset = Vec2f(-12,-8);
const Vec2f rotation_offset = Vec2f(12, 6);
const u8 particles_starttime = 3;
const u8 particles_endtime = 3;
const u8 particles_angle_rnd = 45;
const f32 scale = 1.25f; // both for sprite and distance
const f32 extra_distance = 8; // attack distance

f32 getAimAngle(CBlob@ this)
{
	return (this.getAimPos() - this.getPosition()).Angle();
}

void onTick(CBlob@ this)
{
	this.set_u32("teleport_disable", getGameTime()+5);

	bool remove = this.hasTag("dead");
	u32 timing = this.get_u32("faithglaivetiming");
	f32 diff = getGameTime() - timing;
	Vec2f thispos = this.getPosition();
	
	bool wait = diff < wait_time;
	f32 aimangle = -getAimAngle(this);
	if (this.isFacingLeft()) aimangle += 180;
	
	f32 last_angle = this.get_f32("faithglaiverotation");
	f32 angle = wait ? start_angle : Maths::Lerp(last_angle, target_angle, accel);
	this.set_f32("faithglaiverotation", angle);

	f32 angle_factor = Maths::Max(0, angle / target_angle);

	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ glaive = sprite.getSpriteLayer("faithglaive");
	if (glaive is null)
	{
		@glaive = sprite.addSpriteLayer("faithglaive", "FaithGlaive.png", 32, 32);
		glaive.ScaleBy(Vec2f(scale, scale));
	}

	s8 fl = this.isFacingLeft() ? -1 : 1;

	if (isClient())
	{
		if (!wait && this.get_bool("faithglaiveplaysound"))
		{
			this.set_bool("faithglaiveplaysound", false);
			sprite.PlaySound("glaiveswipe.ogg", 1.0f, 0.95f+XORRandom(11)*0.01f);
		}

		if (glaive !is null)
		{
			glaive.SetRelativeZ(510.0f);

			glaive.ResetTransform();
			glaive.SetOffset(glaive_offset);
			glaive.RotateBy(fl*(start_angle+angle) + aimangle, Vec2f(fl*rotation_offset.x,rotation_offset.y));
		}

		if (angle >= target_angle-particles_endtime || diff < particles_starttime)
		{
			u8 t = this.getTeamNum();
			Vec2f offset = Vec2f(glaive_offset.x*fl, glaive_offset.y).RotateBy(angle*fl);
			
			u16 pamount = 32;
			for (int i = 0; i < pamount; i++)
    		{
				f32 dist = XORRandom(28);
				Vec2f poffset = Vec2f(6*fl * angle_factor + (XORRandom(31)-15.0f)*0.1f, -8 - dist).RotateBy(angle*fl);

				f32 left = i < pamount/2 ? -1 : 1;
    		    Vec2f vel = Vec2f(0,-2.0f).RotateBy(angle + 90*left);

				f32 angle_diff = particles_angle_rnd;
				Vec2f ppos = thispos + poffset;
				SColor col = getTeamColor(t);

				if (dist > 16)
				{
					angle_diff *= 2;
					col = SColor(255, 155+XORRandom(100), 155+XORRandom(100), 25+XORRandom(25));
				}

				vel.RotateBy(XORRandom(angle_diff) - angle_diff/2);

    		    CParticle@ p = ParticlePixelUnlimited(ppos, vel, col, true);
    		    if(p !is null)
				{
    				p.fastcollision = true;
    		    	p.timeout = 15 + XORRandom(11);
    		    	p.damping = 0.85f+XORRandom(101)*0.001f;
					p.gravity = Vec2f(0,0);
					p.collides = false;
					p.Z = 510.0f;
				}
    		}
		}
	}

	if (angle >= target_angle-1) remove = true;

	if (remove)
	{
		if (isServer())
		{
			CMap@ map = getMap();
			if (map !is null)
			{
				HitInfo@[] list;
				map.getHitInfosFromArc(thispos + Vec2f(0 * fl, 0), aimangle + (this.isFacingLeft() ? 180-start_angle : start_angle), Maths::Abs(start_angle) + Maths::Abs(target_angle), extra_distance + 32 * scale, this, @list);

				for (u16 i = 0; i < list.size(); i++)
				{
					HitInfo@ info = list[i];

					CBlob@ b = info.blob;
					if (b is null || !isEnemy(this, b)) continue;

					this.server_Hit(b, b.getPosition(), this.getVelocity(), this.get_f32("faithglaivedamage"), Hitters::sword);
				}
			}
		}

		sprite.RemoveSpriteLayer("faithglaive");
		this.RemoveScript("FaithGlaive.as");
	}
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

void MakeParticle(Vec2f pos, Vec2f vel, SColor col, f32 layer)
{
    CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
    if(p !is null)
    {
        p.bounce = 0.15f + XORRandom(26)*0.01f;
        p.fastcollision = true;
        p.gravity = Vec2f(0, 0.5f);
        p.timeout = 15+XORRandom(30);
        p.Z = layer;
    }
}