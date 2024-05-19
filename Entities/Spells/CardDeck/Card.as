#include "Hitters.as";
#include "ArcherCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	consts.net_threshold_multiplier = 0.5f;

	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale(0.0f);

	this.set_f32("damage", 0.5f);
	this.set_u8("index", 0);
	this.set_Vec2f("origin", Vec2f_zero);
	this.set_u32("pack_time", 0);
	this.set_u32("unpack_time", 0);

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
    this.server_SetTimeToDie(30);

	this.Tag("hidden");
	this.getSprite().ScaleBy(Vec2f(0.75f, 0.75f));
	this.getSprite().SetRelativeZ(50.0f);

	this.set_u8("state", 0);
}

const u8 cards = 6;
const u8 unfold_total_time_per_card = 4;
const Vec2f unfold_dist = Vec2f(16, -20);
const u8 unfold_maxtime = 12;
const u8 unfold_step = 4;
const f32 unfold_decel = 5;
const u8 unfold_timing = cards*unfold_step;
const f32 lean_mod = 5;
const u8 show_time = 45;
const u8 unpack_delay = 10;
const f32 spin_speed = 10;

void onTick(CBlob@ this)
{
	this.SetFacingLeft(true);

    u8 index = this.get_u8("index");
	Vec2f origin = this.get_Vec2f("origin");
	Vec2f pos = this.getPosition();
	s8 left = index < cards/2 ? -1 : 1;

	u8 state = this.get_u8("state");
	u32 tsc = this.getTickSinceCreated();
	u8 side_index = index % (cards/2);
	bool hidden = this.hasTag("hidden");

	CPlayer@ damage_owner = this.getDamageOwnerPlayer();

	if (state != 3)
	{
		if (state == 0) // unfolding from the deck
		{
			u16 timing = index*unfold_total_time_per_card + unpack_delay;
			if (tsc > timing)
			{
				f32 mtsc = f32(Maths::Min(unfold_maxtime - side_index * unfold_step, tsc-timing));
				this.setPosition(Vec2f_lerp(pos, origin + Vec2f(left * Maths::Sin(mtsc/unfold_decel) * unfold_dist.x, Maths::Cos(mtsc/unfold_decel) * unfold_dist.y), 0.25f));

				if (tsc-timing == unfold_timing-1)
				{
					smoke(this.getPosition(), 2);
					// playsoundhere
				}
				if (tsc-timing >= unfold_timing && hidden)
				{
					this.Untag("hidden");

					this.set_u32("pack_time", getGameTime());
					this.set_u8("state", 1);
				}
			}
		}
		else if (state == 1) // packing back
		{
			u32 pack_time = this.get_u32("pack_time");
			int diff = getGameTime() - pack_time;
			if (diff > unfold_step * index + show_time)
			{
				Vec2f tpos = hidden ? origin : origin + Vec2f(0, unfold_dist.y);
				bool in_range = (pos - tpos).Length() <= 1.0f;
				if (in_range && !this.hasTag("hidden"))
				{
					this.Tag("hidden");
					smoke(this.getPosition(), 1);
					// playsoundhere
				}
				else if (in_range && this.hasTag("hidden"))
				{
					this.set_u8("state", 2);
					this.set_u32("unpack_time", getGameTime());
					// playsoundhere ???
				}

				this.setPosition(Vec2f_lerp(pos, tpos, 0.35f));
			}
		}
		else if (state == 2) // ready
		{
			if (damage_owner !is null)
			{
				u32 unpack_time = this.get_u32("unpack_time");
				int diff = getGameTime() - unpack_time;

				CBlob@[] bc;
				getBlobsByTag("card_"+damage_owner.getUsername(), bc);

				u8 bigger_than = 0;
				u8 launched = 0;
				for (u8 i = 0; i < bc.size(); i++)
				{
					CBlob@ another = bc[i];
					if (another is null) continue;
					if (another.get_u8("state") == 3)
					{
						launched++;
						continue;
					}

					if (another.get_u8("index") < this.get_u8("index"))
					{
						bigger_than++;
					}
				}
				
				bool ready = diff > unfold_total_time_per_card * cards + unpack_delay;
				if (bigger_than == 0)
				{
					if (ready && (origin-pos).Length() <= 1.0f)
					{
						if (this.hasTag("hidden"))
							smoke(this.getPosition(), 1);
						this.Untag("hidden");

						CBlob@ owner = damage_owner.getBlob();
						if (owner !is null && owner.get_bool("shifting"))
						{
							if (isServer())
								this.set_Vec2f("dir", owner.getAimPos() - pos);

							this.set_u8("state", 3);
							// playsoundhere
						}
					}

					this.setPosition(Vec2f_lerp(pos, origin, 0.25f));
				}
				else
				{
					this.Tag("hidden");
					if (ready)
					{
						this.setPosition(Vec2f_lerp(pos, origin +
							Vec2f(0, unfold_dist.y).RotateBy(
								360/Maths::Clamp(bc.size()-1-launched, 1, cards)
									* bigger_than + ((getGameTime()*spin_speed)%360)), 0.25f));
					}
				}
			}
		}

		this.setAngleDegrees(((this.getPosition()-this.getOldPosition()).x * lean_mod) % 360.0f);
	}
	else
	{
		if (!this.hasTag("prep"))
		{
			this.Tag("prep");
			this.Untag("hidden");
			CShape@ shape = this.getShape();
			ShapeConsts@ consts = shape.getConsts();
			consts.mapCollisions = true;

			if (isServer())
			{
				Vec2f dir = this.get_Vec2f("dir");
				this.setVelocity(this.get_Vec2f("vel").RotateBy(-dir.Angle()));
				this.server_SetTimeToDie(10);
			}
		}

		s8 ff = this.getVelocity().x < 0 ? -1 : 1;
		this.setAngleDegrees((this.getAngleDegrees() + ff * (this.getVelocity().Length()*(spin_speed/2))) % 360);
	}

	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	
	u8 type = this.get_u8("type");
	if (this.hasTag("hidden"))
	{
		sprite.animation.frame = type % 3;
	}
	else
	{
		sprite.animation.frame = type + 3;
	}

	sprite.setRenderStyle(hidden ? RenderStyle::additive : RenderStyle::normal);
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

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer())
	{
		if (solid && blob is null)
		{
			this.server_Die();
		}
	}

	if (blob !is null && isEnemy(this, blob))
	{
		f32 dmg = this.get_f32("dmg");
		if (isServer())
			this.server_Hit(blob, this.getPosition(), Vec2f_zero, dmg, Hitters::arrow, false);
		// playsoundhere
	}
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	smoke(this.getPosition(), 1);
	// playsoundhere
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									Vec2f_zero, 
									float(XORRandom(360)), 
									1.0f, 
									2, 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.Z = 100.0f;
		p.lighting = false;
		p.setRenderStyle(RenderStyle::additive);
    }
}

enum effects
{
	switch_pos = 0,
	ignite,
	stun,
	ricochet,
	penetration,
	speed
}