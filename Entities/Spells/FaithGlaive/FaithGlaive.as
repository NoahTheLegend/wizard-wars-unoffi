#include "Hitters.as"
#include "TeamColour.as"
#include "RunnerCommon.as"

const u16 target_angle = 90;
const f32 start_angle = -15;
const f32 accel = 0.5f;
const Vec2f glaive_offset = Vec2f(-16,-12);
const Vec2f rotation_offset = Vec2f(16, 12);
const u8 glaive_death_delay = 2;

const f32 start_angle_jabs = 30;
const Vec2f jabs_offset = Vec2f(-12, 0);
const Vec2f[] jabs_positions_const = {Vec2f(-8,0),Vec2f(-32,16),Vec2f(-8,0),Vec2f(-32,-16),Vec2f(-8,0),Vec2f(-48,0)};
const u8 jabbing_time = 3;
const int mid_jab_angle = 45;
const int left_jab_angle = 45;
const int right_jab_angle = 45;

const f32 scale = 1.25f; // both for sprite and distance
const f32 extra_distance = 12; // attack distance

f32 getAimAngle(CBlob@ this)
{
	return (this.getAimPos() - this.getPosition()).Angle();
}

void onTick(CBlob@ this)
{
	RunnerMoveVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	this.set_bool("disable_dash", true);
	this.set_u32("teleport_disable", getGameTime()+3);
	u8 wait_time = this.get_u8("faithglaivewait");

	CSprite@ sprite = this.getSprite();
	s8 fl = this.isFacingLeft() ? -1 : 1;

	bool remove = this.hasTag("dead") || (this.exists("remove_glaive_time") && this.get_u32("remove_glaive_time") != 0 && getGameTime() >= this.get_u32("remove_glaive_time"));
	bool hit = false;
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

	CSpriteLayer@ glaive = sprite.getSpriteLayer("faithglaive");
	if (glaive is null)
	{
		@glaive = sprite.addSpriteLayer("faithglaive", "FaithGlaive.png", 32, 32);
		glaive.ScaleBy(Vec2f(scale, scale));
	}

	f32 jabs_angle = 0;
	f32 current_jab_distance = jabs_positions_const[5].x * scale + extra_distance;
	s8 jab_count = 0;
	if (this.hasTag("glaive_special"))
	{
		u8 state = 0;
		if (!this.exists("glaive_jab_state")) this.set_u8("glaive_jab_state", 0);
		state = this.get_u8("glaive_jab_state");

		u8 jabs_timer = 0;
		if (!this.exists("glaive_jab_timer")) this.set_u8("glaive_jab_timer", 0);
		jabs_timer = this.get_u8("glaive_jab_timer");

		Vec2f offset = jabs_offset;
		f32 jabs_factor = Maths::Clamp(f32(jabs_timer) / f32(jabbing_time), 0, 1);

		bool completed_jab = jabs_timer >= jabbing_time;
		if (!wait)
		{
			Vec2f[] jabs_positions = jabs_positions_const;
			
			jabs_timer++;
			if (state == 0) // move inside
			{
				jabs_angle = Maths::Lerp(0, mid_jab_angle * jabs_factor, jabs_factor);

				offset = Vec2f_lerp(offset, jabs_positions[0], jabs_factor);
				if (completed_jab)
				{
					jabs_timer = 0;
					state = 1;
				}	
			}
			else if (state == 1) // move outside more to right
			{
				jabs_angle = Maths::Lerp(mid_jab_angle, mid_jab_angle + right_jab_angle * jabs_factor, jabs_factor);

				offset = Vec2f_lerp(jabs_positions[0], jabs_positions[1], jabs_factor);
				if (completed_jab)
				{
					jabs_timer = 0;
					state = 2;
					hit = true;

					jab_count = 1;
					current_jab_distance = jabs_positions[1].x * scale + extra_distance;
				}
			}
			else if (state == 2) // move inside
			{
				jabs_angle = Maths::Lerp(mid_jab_angle + right_jab_angle, mid_jab_angle + right_jab_angle - right_jab_angle * jabs_factor, jabs_factor);

				offset = Vec2f_lerp(jabs_positions[1], jabs_positions[2], jabs_factor);
				if (completed_jab)
				{
					jabs_timer = 0;
					state = 3;
				}
			}
			else if (state == 3) // move outside more left
			{
				jabs_angle = Maths::Lerp(mid_jab_angle, mid_jab_angle - left_jab_angle * jabs_factor, jabs_factor);

				offset = Vec2f_lerp(jabs_positions[2], jabs_positions[3], jabs_factor);
				if (completed_jab)
				{
					jabs_timer = 0;
					state = 4;
					hit = true;

					jab_count = 2;
					current_jab_distance = jabs_positions[3].x * scale + extra_distance;
				}
			}
			else if (state == 4) // move inside
			{
				jabs_angle = Maths::Lerp(mid_jab_angle - left_jab_angle, mid_jab_angle - left_jab_angle + left_jab_angle * jabs_factor, jabs_factor);

				offset = Vec2f_lerp(jabs_positions[3], jabs_positions[4], jabs_factor);
				if (completed_jab)
				{
					jabs_timer = 0;
					state = 5;
				}
			}
			else if (state == 5) // move outside mid
			{
				jabs_angle = 15;
				
				offset = Vec2f_lerp(jabs_positions[4], jabs_positions[5], jabs_factor);
				if (completed_jab && (!this.exists("remove_glaive_time") || this.get_u32("remove_glaive_time") == 0))
				{
					hit = true;
					this.set_u32("remove_glaive_time", getGameTime() + glaive_death_delay);
				}
			}
			else remove = true;
		}

		this.set_u8("glaive_jab_state", state);
		this.set_u8("glaive_jab_timer", jabs_timer);

		offset.x *= fl;
		if (isClient())
		{
			if (hit) sprite.PlaySound("glaiveswipe.ogg", 1.0f, 1.15f+XORRandom(11)*0.01f);
			f32 angle = (start_angle_jabs + jabs_angle) * fl;

			glaive.ResetTransform();
			glaive.SetRelativeZ(510.0f);
			glaive.SetOffset(Vec2f(offset.x * fl, offset.y).RotateBy(-aimangle * fl));
			glaive.RotateBy(aimangle, Vec2f_zero);//(start_angle_jabs + jabs_angle) * fl
			glaive.RotateBy(angle, Vec2f_zero);
		}
	}
	else
	{
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
		}
	
		if (angle >= target_angle-1)
		{
			remove = true;
			hit = true;
		}
	}

	if (hit)
	{
		if (isServer())
		{
			CMap@ map = getMap();
			if (map !is null)
			{
				HitInfo@[] list;
				if (this.hasTag("glaive_special")) // ray
				{
					f32 angle = jab_count == 0 ? 0 : jab_count == 1 ? right_jab_angle * 0.5f : -left_jab_angle * 0.5f;
					map.getHitInfosFromArc(thispos, aimangle + angle + (this.isFacingLeft() ? 180 : 0), 35, extra_distance * 2 + Maths::Abs(current_jab_distance), this, @list);
				}
				else
					map.getHitInfosFromArc(thispos, aimangle + (this.isFacingLeft() ? 180-start_angle : start_angle), Maths::Abs(start_angle) + Maths::Abs(target_angle), extra_distance + 32 * scale, this, @list);

				for (u16 i = 0; i < list.size(); i++)
				{
					HitInfo@ info = list[i];

					CBlob@ b = info.blob;
					if (b is null || !isEnemy(this, b)) continue;

					this.server_Hit(b, b.getPosition(), Vec2f_zero, this.get_f32("faithglaivedamage"), Hitters::explosion, true);
				}
			}
		}
	}

	if (remove)
	{
		if (isClient())
		{
			sprite.RemoveSpriteLayer("faithglaive");
		}

		this.set_bool("disable_dash", false);
		this.set_u8("glaive_jab_state", 0);
		this.set_u8("glaive_jab_timer", 0);
		
		this.set_u32("remove_glaive_time", 0);
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