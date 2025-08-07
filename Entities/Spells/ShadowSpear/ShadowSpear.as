#include "Hitters.as";
#include "TeamColour.as";
#include "MagicCommon.as"

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	consts.net_threshold_multiplier = 1.0f;
	this.Tag("projectile");
	this.Tag("counterable");
	shape.SetGravityScale(0.0f);
	
	this.set_f32("lifetime",0);
	this.Tag("no trampoline collision");
	this.Tag("smashtoparticles_additive");
	
    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(60);
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(1500.0f);
	sprite.setRenderStyle(RenderStyle::additive);
	this.getSprite().RotateBy(+45, Vec2f_zero);
	u16[] ids;
	this.set("hit_ids", @ids);
	this.addCommandID("stole_mana");
}

//f32 stoprange = 48.0f;
const f32 ticks_noclip = 10;
void onTick(CBlob@ this)
{
	this.setAngleDegrees(-this.getVelocity().Angle());

	this.setAngleDegrees(-this.getVelocity().Angle());

    bool has_solid = this.getShape().isOverlappingTileSolid(true);
    if (!this.hasTag("solid") && getMap() !is null && !has_solid)
    {
        this.getShape().getConsts().mapCollisions = true;
        if (has_solid) this.Tag("mark_for_death");
        this.Tag("solid");
    }
    else if (!this.hasTag("solid") && this.getTickSinceCreated() > ticks_noclip)
        this.Tag("mark_for_death");
	/*Vec2f pos = this.getPosition();
	Vec2f target_pos = this.get_Vec2f("target_pos");
	bool back = this.get_bool("back");
	f32 dist = (pos-target_pos).Length();
	Vec2f dir = target_pos-pos;
	dir.Normalize();

	Vec2f vel = this.getVelocity();
	f32 speed = this.get_f32("speed");
	f32 factor = 1.0f * Maths::Min(dist, stoprange) / stoprange;

	// particles
	if (isClient())
	{
		u8 t = this.getTeamNum();
		for (u8 i = 0; i < 2; i++)
		{
			Vec2f dir = Vec2f(-4, 4 * (i%2==0?-1:1)).RotateBy(this.getAngleDegrees());
			Vec2f ppos = this.getOldPosition()+dir;
			Vec2f vel = this.getVelocity() + dir/4;
			CParticle@ p = ParticlePixelUnlimited(ppos, vel, getTeamColor(t), true);
    		if(p !is null)
			{
    			p.fastcollision = true;
    			p.timeout = 15 + XORRandom(11);
    			p.damping = 0.85f+XORRandom(101)*0.001f;
				p.gravity = Vec2f(0,0);
				p.collides = false;
				p.Z = 510.0f;
				p.setRenderStyle(RenderStyle::additive);
			}
		}
	}
	
	this.setVelocity(dir * speed * factor);

	if (dist < stoprange && vel.Length() < 1.0f)
	{
		if (back) this.Tag("mark_for_death");
		this.set_bool("back", true);
		back = true;

		CPlayer@ p = this.getDamageOwnerPlayer();
		if (p is null || p.getBlob() is null)
		{
			this.Tag("mark_for_death");
		}
		else
		{
			this.set_Vec2f("target_pos", p.getBlob().getPosition());
		}
	}
	if (vel.Length() >= 1.0f) this.setAngleDegrees(-this.getVelocity().Angle() + (back?180:0));*/
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float damage = this.get_f32("damage");
			this.getSprite().PlaySound("exehit.ogg", 1.5f, 1.5f+XORRandom(26)*0.01f);

			if (isServer())
			{
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::arrow, true);

				if (blob.hasTag("barrier"))
				{
					this.Tag("mark_for_death");
				}
				u16[]@ ids;
				if (this.get("hit_ids", @ids) && ids.find(blob.getNetworkID()) == -1){
					CBitStream params;
					params.write_u16(blob.getNetworkID());
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
		CBlob@ b = getBlobByNetworkID(id);
		if (b is null) return;
		ManaInfo@ manaInfo;
		if (b.get("manaInfo", @manaInfo)) {
			print("stole mana from " + b.getName() + " " + manaInfo.mana);
			if (manaInfo.mana >= 1){
				int steal = Maths::Min(10, manaInfo.mana);
				manaInfo.mana -= steal;
				if (b is null) return;
				CBlob@ orb = server_CreateBlob("shadowspearmanaorb", this.getTeamNum(), b.getPosition());
				orb.setVelocity(Vec2f(1+XORRandom(25)*0.1f, 0).RotateBy(XORRandom(360)));
				orb.server_setTeamNum( this.getTeamNum() );
				orb.set_s32("mana_stored", steal);
			}
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
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