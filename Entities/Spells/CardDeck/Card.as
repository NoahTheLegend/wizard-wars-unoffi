#include "Hitters.as";
#include "ArcherCommon.as";
#include "SpellUtils.as";
#include "KnockedCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("switch_owner_pos");
	this.addCommandID("set_knocked");

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
	this.set_u32("disabled", 0);
	this.set_u8("collided", 0);

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	this.Tag("hidden");
	this.getSprite().ScaleBy(Vec2f(0.75f, 0.75f));
	this.getSprite().SetRelativeZ(510.0f);

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
const f32 spin_speed_base = 10;
const u8 shoot_delay = 5;
// effects
const u8 knock_time = 45;
const f32 heal_amount = 0.5f; // 5 hp
const u8 max_ricochets = 3;

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
	f32 spin_speed = spin_speed_base;
	f32 lerp = 0.25f;

	if (isClient())
	{
		borderParticles(this);
	}

	CPlayer@ damage_owner = this.getDamageOwnerPlayer();
	bool follow = false;
	if (this.hasTag("overcharge") && damage_owner !is null
		&& damage_owner.getBlob() !is null)
	{
		follow = true;
		origin = damage_owner.getBlob().getPosition();
		//spin_speed *= 1.5f;
		lerp = 0.33f;
	}

	if (state != 3)
	{
		if (state == 0) // unfolding from the deck
		{
			u16 timing = index*unfold_total_time_per_card + unpack_delay;
			if (tsc > timing)
			{
				f32 mtsc = f32(Maths::Min(unfold_maxtime - side_index * unfold_step, tsc-timing));
				this.setPosition(Vec2f_lerp(pos, origin + Vec2f(left * Maths::Sin(mtsc/unfold_decel) * unfold_dist.x, Maths::Cos(mtsc/unfold_decel) * unfold_dist.y), lerp));

				if (tsc-timing == unfold_timing-1)
				{
					smoke(this.getPosition(), 2);
					this.getSprite().PlaySound("CardReveal.ogg", 1.25f, 1.0f+XORRandom(11)*0.01f);
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
				bool in_range = (pos - tpos).Length() <= (follow ? 12.0f : 4.0f);
				if (in_range && !this.hasTag("hidden"))
				{
					this.Tag("hidden");
					smoke(this.getPosition(), 1);
				}
				else if (in_range && this.hasTag("hidden"))
				{
					this.set_u8("state", 2);
					this.set_u32("unpack_time", getGameTime());
				}

				this.setPosition(Vec2f_lerp(pos, tpos, 0.35f));
			}
		}
		else if (state == 2) // ready
		{
			if (damage_owner !is null)
			{
				CBlob@ owner = damage_owner.getBlob();
				if (owner is null || owner.hasTag("dead"))
				{
					this.server_Die();
					return;
				}

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
				
				bool ready = diff > unfold_total_time_per_card * cards + unpack_delay || follow;
				if (bigger_than == 0)
				{
					Vec2f offset = follow ? Vec2f(0, Maths::Abs(unfold_dist.y) + owner.getRadius()) : Vec2f_zero;
					
					if (ready && (((origin-offset)-pos).Length() <= 4.0f || follow))
					{
						if (this.hasTag("hidden"))
						{
							smoke(this.getPosition(), 1);
							this.Untag("hidden");
							this.set_u32("disabled", getGameTime() + shoot_delay);
						}

						if (owner.get_bool("shifting") && this.get_u32("disabled") < getGameTime())
						{
							if (isServer())
								this.set_Vec2f("dir", owner.getAimPos() - pos);

							this.set_u8("state", 3);
							this.getSprite().PlaySound("CardShoot.ogg", 0.65f, 1.0f+XORRandom(21)*0.01f);
						}
					}

					this.setPosition(Vec2f_lerp(pos, origin - offset, lerp));
				}
				else
				{
					this.Tag("hidden");
					if (ready)
					{
						this.setPosition(Vec2f_lerp(pos, origin +
							Vec2f(0, unfold_dist.y).RotateBy(
								360/Maths::Clamp(bc.size()-1-launched, 1, cards)
									* bigger_than + ((getGameTime()*spin_speed)%360)), lerp));
					}
				}
			}
		}

		f32 angle = Maths::Clamp(((this.getPosition()-this.getOldPosition()).x * lean_mod) % 360.0f, -45, 45);
		this.setAngleDegrees(angle);
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
		&& (target.getTeamNum() != this.getTeamNum() || this.get_u8("type") == effects::heal)
	);
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	smoke(this.getPosition(), 1);
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

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (this.hasTag("dead")) return;
	if (this.get_u8("state") != 3) return;
	u8 type = this.get_u8("type");

	if (isServer())
	{
		if (solid && blob is null)
		{
			if (type != effects::ricochet || this.get_u8("collided") > max_ricochets)
				this.server_Die();
			else
				this.add_u8("collided", 1);
		}
	}

	if (blob !is null && isEnemy(this, blob))
	{
		f32 dmg = this.get_f32("dmg");
		ApplyEffect(this, blob, type);

		if (isServer())
			this.server_Hit(blob, this.getPosition(), Vec2f_zero, dmg, type == effects::ignite ? Hitters::fire : Hitters::arrow, false);
		this.IgnoreCollisionWhileOverlapped(blob);
		this.getSprite().PlaySound("CardDie.ogg", 0.75f, 1.25f+XORRandom(16)*0.01f);

		if (type != effects::penetration)
		{
			this.server_Die();
			this.Tag("dead");
			return;
		}
	}
}

enum effects
{
	heal = 0,
	stun,
	penetration,
	ignite,
	ricochet,
	switch_pos
}

bool ApplyEffect(CBlob@ this, CBlob@ blob, u8 effect)
{
	if (blob is null)
		return false;
	bool applied = false;

	CPlayer@ owner_player = this.getDamageOwnerPlayer();
	if (owner_player is null || owner_player.getBlob() is null)
		return false;

	CBlob@ owner = owner_player.getBlob();
	switch (effect)
	{
		case effects::heal:
		{
			applied = true;
			Heal(blob, heal_amount);
		}
		break;
		case effects::stun:
		{
			applied = true;
			if (isServer())
			{
				CBitStream params;
				params.write_u16(blob.getNetworkID());
				this.SendCommand(this.getCommandID("set_knocked"), params);
			}
		}
		break;
		case effects::switch_pos:
		{
			applied = true;
			if (isServer())
			{
				CBitStream params;
				params.write_u16(owner.getNetworkID());
				params.write_u16(blob.getNetworkID());
				this.SendCommand(this.getCommandID("switch_owner_pos"), params);
			}
		}

		default: return false;
	}

	return applied;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("switch_owner_pos"))
	{
		u16 id = params.read_u16();
		u16 other_id = params.read_u16();

		CBlob@ owner = getBlobByNetworkID(id);
		CBlob@ other = getBlobByNetworkID(other_id);

		if (owner.getPlayer() is null || other.getPlayer() is null)
			return;

		if (owner !is null && other !is null)
		{
			Vec2f temp = owner.getPosition();
			owner.setPosition(other.getPosition());
			owner.IgnoreCollisionWhileOverlapped(other);

			other.setPosition(temp);
			other.IgnoreCollisionWhileOverlapped(owner);

			owner.getSprite().PlaySound("Teleport.ogg", 0.9f, 1.1f);
			other.getSprite().PlaySound("Teleport.ogg", 0.9f, 1.1f);

			other.set_u16("confused", (7+XORRandom(4))*30);
		}
	}
	else if (cmd == this.getCommandID("set_knocked"))
	{
		u16 id = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(id);
		if (blob !is null && blob.hasTag("player"))
		{
			setKnocked(blob, knock_time);
		}
	}
}

const u8 max_particles = 25;

void borderParticles(CBlob@ this)
{
    f32 vertical_max = 12.0f;
    f32 horizontal_max = 8.0f;
    f32 vertical_step = vertical_max / (max_particles * 0.25f);
    f32 horizontal_step = horizontal_max / (max_particles * 0.25f);

    Vec2f thisPos = this.getOldPosition();
    Vec2f startPos = Vec2f(-horizontal_max / 2, -vertical_max / 2);

    for (u8 i = 0; i < max_particles; i++)
    {
        f32 position_on_perimeter = float(i) / float(max_particles);
        f32 perimeter = 2.0f * (vertical_max + horizontal_max);
        f32 distance = position_on_perimeter * perimeter;

        Vec2f pos;
		bool up = false;
		bool right = false;
		bool down = false;
		bool left = false;

        if (distance <= horizontal_max)
        {
            pos = Vec2f(startPos.x + distance, startPos.y);
			up = true;
        }
        else if (distance <= horizontal_max + vertical_max)
        {
            pos = Vec2f(startPos.x + horizontal_max, startPos.y + (distance - horizontal_max));
			right = true;
        }
        else if (distance <= 2 * horizontal_max + vertical_max)
        {
            pos = Vec2f(startPos.x + horizontal_max - (distance - horizontal_max - vertical_max), startPos.y + vertical_max);
			down = true;
		}
        else
        {
            pos = Vec2f(startPos.x, startPos.y + vertical_max - (distance - 2 * horizontal_max - vertical_max));
			left = true;
        }

		f32 wave = Maths::Sin(getGameTime()*0.1f);
		int rnd = XORRandom(Maths::Abs(wave)*(2+(wave < 0 ? i%5 : (4-(i%5)))));
		//Vec2f rnd_pos = up || down ? Vec2f(0, up ? -rnd : rnd) : Vec2f(right ? rnd : -rnd, 0);
		Vec2f rnd_pos = !this.hasTag("hidden") && (right || left) ? Vec2f(right ? rnd : -rnd, 0) : Vec2f_zero;

        CParticle@ p = ParticlePixelUnlimited(thisPos+(rnd_pos+pos).RotateBy(this.getAngleDegrees()), Vec2f_zero, this.getTeamNum() == 0 ? SColor(255,35,70,230) : SColor(255,185,10,15), true);
        if (p is null) continue;

        p.collides = false;
        p.Z = 505.0f;
        p.setRenderStyle(RenderStyle::additive);
        p.gravity = Vec2f_zero;
        p.timeout = 1;
    }
}