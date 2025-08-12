#include "Hitters.as";
#include "TeamColour.as";
#include "MagicCommon.as";
#include "TextureCreation.as";

const f32 rad = 156.0f;
const f32 afterdeath_time = 0.1f;
const f32 accel_mod = 1.5f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();

	consts.mapCollisions = false;
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	shape.SetGravityScale(0.0f);

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("no trampoline collision");
	this.Tag("smashtoparticles_additive");

	this.set_f32("lifetime", 0);
	this.SetMapEdgeFlags(CBlob::map_collide_none | CBlob::map_collide_nodeath);
	this.server_SetTimeToDie(1);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(1500.0f);
	sprite.setRenderStyle(RenderStyle::additive);
	sprite.RotateBy(45, Vec2f_zero);

	this.set_f32("smashtoparticles_extra_rot", 45);
	this.set_Vec2f("smashtoparticles_grav", Vec2f_zero);

	u16[] ids;
	this.set("hit_ids", @ids);
	this.addCommandID("stole_mana");

	if (!isClient()) return;
	const Vec2f frameSize(48, 48);

    SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend0",  false, false, Vec2f(0, 0),    frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend1",  false, false, Vec2f(48, 0),   frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend2",  false, false, Vec2f(96, 0),   frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend3",  false, false, Vec2f(144, 0),  frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend4",  false, false, Vec2f(192, 0),  frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend5",  false, false, Vec2f(240, 0),  frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend6",  false, false, Vec2f(0, 48), 	 frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend7",  false, false, Vec2f(48, 48),	 frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend8",  false, false, Vec2f(96, 48),	 frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend9",  false, false, Vec2f(144, 48), frameSize);
	SetupImage("ShadowSpear.png", SColor(255, 255, 255, 255), "ss_rend10", false, false, Vec2f(192, 48), frameSize);

    int cb_id = Render::addBlobScript(Render::layer_prehud, this, "ShadowSpear.as", "laserEffects");
}

void onTick(CBlob@ this)
{
	Vec2f dir = this.getVelocity();
	this.setAngleDegrees(-dir.Angle());

	dir.Normalize();
	this.AddForce(dir * this.getMass() * accel_mod);

	if (this.getTickSinceCreated() == 0)
	{
		s8 remaining_repeats = this.get_s8("remaining_repeats");

		u8 real_id = this.get_u8("real_id");
		if (remaining_repeats != real_id)
		{
			this.server_SetHealth(1.0f);
			this.Tag("fake_blob");
		}
		
		u16 targetID = this.get_u16("follow_id");
		if (targetID != 0)
		{
			CBlob@ target = getBlobByNetworkID(targetID);
			if (target !is null)
			{
				if (isClient())
				{
					string sound = this.getHealth() == 1.0f ? "ShadowCastEmpty.ogg" : "ShadowCast.ogg";
					if (target.getSprite() !is null) target.getSprite().PlaySound(sound, 1.0f, 1.0f + XORRandom(16) * 0.01f);
				}

				if (!isServer()) return;
				this.setPosition(target.getPosition() + Vec2f(rad + XORRandom(rad), 0).RotateBy(XORRandom(360)));

				Vec2f dir = target.getPosition() + target.getVelocity() - this.getPosition();
				dir.Normalize();
				dir *= this.get_f32("speed");

				this.setVelocity(dir);
				this.setAngleDegrees(-dir.Angle());
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			this.server_SetTimeToDie(afterdeath_time);
			f32 damage = this.get_f32("damage");
			this.getSprite().PlaySound("exehit.ogg", 1.5f, 1.5f+XORRandom(26)*0.01f);

			if (isServer() && !this.hasTag("fake_blob"))
			{
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::arrow, true);

				if (blob.hasTag("barrier"))
				{
					this.Tag("mark_for_death");
				}
				
				u16[]@ ids;
				if (this.get("hit_ids", @ids) && ids.find(blob.getNetworkID()) == -1)
				{
					CBitStream params;
					params.write_u16(blob.getNetworkID());
					params.write_u8(this.get_u8("max_mana_steal"));

					this.SendCommand(this.getCommandID("stole_mana"), params);
					ids.push_back(blob.getNetworkID());
				}
			}
		}
	}

	if (blob is null && solid)
	{
		this.Tag("mark_for_death");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("stole_mana"))
	{
		u16 id = params.read_u16();
		u8 max_steal = params.read_u8();

		CBlob@ b = getBlobByNetworkID(id);
		if (b is null) return;
		
		ManaInfo@ manaInfo;
		if (b.get("manaInfo", @manaInfo))
		{
			//print("stole mana from " + b.getName() + " " + manaInfo.mana);
			if (manaInfo.mana > 0)
			{
				int steal = Maths::Min(max_steal, manaInfo.mana);
				manaInfo.mana -= steal;

				if (!isServer() || b is null) return;
				CBlob@ orb = server_CreateBlob("shadowspearmanaorb", this.getTeamNum(), b.getPosition());
				if (orb !is null)
				{
					orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					orb.setVelocity(Vec2f(1 + XORRandom(25) * 0.1f, 0).RotateBy(XORRandom(360)));
					orb.server_setTeamNum(this.getTeamNum());
					orb.set_s32("mana_stored", steal);
				}
			}
		}
		else
		{
			int steal = max_steal;

			if (!isServer() || b is null) return;
			CBlob@ orb = server_CreateBlob("shadowspearmanaorb", this.getTeamNum(), b.getPosition());

			orb.setVelocity(Vec2f(1 + XORRandom(25) * 0.1f, 0).RotateBy(XORRandom(360)));
			orb.server_setTeamNum(this.getTeamNum());
			orb.set_s32("mana_stored", steal);
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	u16 targetID = this.get_u16("follow_id");
	if (targetID == 0) return false;

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
				&& target.getNetworkID() == targetID
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}

void onDie(CBlob@ this)
{
	if (!isServer()) return;

	bool fake_blob = this.hasTag("fake_blob");
	if (!fake_blob) return;

	s8 remaining = this.get_s8("remaining_repeats") - 1;
	if (remaining < 0) return;

	u16 targetID = this.get_u16("follow_id");

	Vec2f orbPos = Vec2f(0, -1028.0f); // teleports at target
	CBlob@ orb = server_CreateBlob("shadowspear", this.getTeamNum(), orbPos);
	if (orb !is null)
	{
		orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

		orb.set_f32("damage", this.get_f32("damage"));
		orb.set_f32("speed", this.get_f32("speed"));
		orb.set_u8("max_mana_steal", this.get_u8("max_mana_steal"));
		orb.set_s8("remaining_repeats", remaining);
		orb.set_u8("real_id", this.get_u8("real_id"));
		orb.set_u16("follow_id", targetID);
    }
}

const string[] anim_loop = {
	"ss_rend0",
	"ss_rend1",
	"ss_rend2",
    "ss_rend3",
	"ss_rend4",
	"ss_rend5",
	"ss_rend6",
	"ss_rend7",
	"ss_rend8",
	"ss_rend9",
	"ss_rend10"
};

const u8 anim_time = 3;
void laserEffects(CBlob@ this, int id)
{
    int ts = this.getTickSinceCreated();
    string rendname = anim_loop[ts / anim_time % anim_loop.length];
    f32 z = 100.0f;

    Vec2f[] v_pos;
    Vec2f[] v_uv;
    SColor[] v_col;

	f32 s = 24;
	f32 mod = Maths::Min(f32(ts) / 8, 1.0f);
	u8 alpha = 255 * mod;
	f32 angle = this.getAngleDegrees() + 45;

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-s, -s).RotateBy(angle));
    v_uv.push_back(Vec2f(0, 0));
    v_col.push_back(SColor(alpha, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(s, -s).RotateBy(angle));
    v_uv.push_back(Vec2f(1, 0));
    v_col.push_back(SColor(alpha, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(s, s).RotateBy(angle));
    v_uv.push_back(Vec2f(1, 1));
    v_col.push_back(SColor(alpha, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-s, s).RotateBy(angle));
    v_uv.push_back(Vec2f(0, 1));
    v_col.push_back(SColor(alpha, 255, 255, 255));

    Render::QuadsColored(rendname, z, v_pos, v_uv, v_col);
}