#include "Hitters.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // we have our own map collision
	consts.bullet = true;
	consts.net_threshold_multiplier = 1.25f;
	shape.SetGravityScale(0.0f);
	//shape.SetStatic(true);

	this.Tag("counterable");
	this.Tag("die_in_divine_shield");

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(500.0f);
	sprite.SetEmitSound("MagnaCannonChargeLoop.ogg");

	if (!this.exists("damage")) this.set_f32("damage", 0.5f);
	this.set_u8("mode", 0);
	this.set_u16("hold_time", 0);
	this.set_f32("scale", 1.0f);
}

const u16 max_hold_time = 90;
const f32 dmg_per_step = 0.03f;
const f32 scale = 0.01f;
const u8 prep_time = 9;

void onTick(CBlob@ this)
{
	CPlayer@ ownerplayer = this.getDamageOwnerPlayer();
	if (ownerplayer is null || ownerplayer.getBlob() is null)
	{
		this.Tag("mark_for_death");
		return;
	}

	CBlob@ owner = ownerplayer.getBlob();
	owner.set_u32("NOLMB", getGameTime()+10);
	owner.set_u32("teleport_disable", getGameTime()+3);

	CSprite@ sprite = this.getSprite();

	bool holding = owner.isKeyPressed(key_action1);
	Vec2f aimpos = owner.getAimPos()+Vec2f(0,3);
	Vec2f dir = aimpos-owner.getPosition();

	Vec2f ownerpos = owner.getPosition();
	bool fl = aimpos.x < ownerpos.x;
	
	f32 accel = (f32(this.getTickSinceCreated())/prep_time);
	f32 aimangle = -dir.Angle();
	f32 new_deg = fl ? aimangle + 180.0f : aimangle;
	this.setAngleDegrees(new_deg);

	this.setPosition(owner.getPosition() + Vec2f(12,0).RotateBy(aimangle));
	Vec2f pos = this.getPosition();

	if (!this.hasTag("prep"))
	{
		this.Tag("prep");
		//smoke(pos, 6, 1, 2, true);
	}

	f32 deg = this.getAngleDegrees();
	this.SetFacingLeft(fl);
	u16 hold_time = this.get_u16("hold_time");

	if (this.get_u8("mode") == 1)
	{
		if (holding)
		{
			this.add_u16("hold_time", 1);
		}
	}

	if (hold_time > max_hold_time || (!holding && this.getTickSinceCreated() > 15))
	{		
		if (isServer())
		{
			f32 damage = this.get_f32("damage");
			damage += hold_time*dmg_per_step;

			CBlob@ orb = server_CreateBlob("plasmabullet", this.getTeamNum(), this.getPosition());
			if (orb !is null)
			{
				orb.SetDamageOwnerPlayer(ownerplayer);
				orb.set_f32("damage", damage);
				orb.Sync("damage", true);
				orb.set_Vec2f("target_dir", dir);
				orb.Sync("target_dir", true);
				orb.set_f32("scale", this.get_f32("scale"));
				orb.Sync("scale", true);
			}

			this.Tag("mark_for_death");
		}
	}

	if (isServer())
	{
		if (getGameTime() <= this.get_u32("ready_time") + 5)
		{
			this.add_f32("scale", 2.0f);
		}

		if (holding)
		{
			this.add_f32("scale", 1.0f+scale);
		}
	}

	if (isClient())
	{
		sprite.SetEmitSoundPaused(false);
		sprite.SetEmitSoundVolume(Maths::Min((1.25f + hold_time * 0.01f)*Maths::Min(this.getTickSinceCreated()/30.0f, 1.0f), 2.0f));

		u8 rnd = hold_time * 0.001f;
		sprite.SetEmitSoundSpeed(1.5f + hold_time*0.01f + (XORRandom(rnd)-rnd*0.5f));

		sprite.ResetTransform();

		CSpriteLayer@ muzzle = sprite.getSpriteLayer("muzzle");
		if (muzzle !is null)
		{
			muzzle.ResetTransform();
			muzzle.SetVisible(true);
			muzzle.setRenderStyle(RenderStyle::additive);

			if (getGameTime() <= this.get_u32("ready_time") + 5)
			{
				muzzle.ScaleBy(Vec2f(2.0f, 2.0f));
			}

			if (holding)
			{
				muzzle.ScaleBy(Vec2f(1.0f + scale, 1.0f + scale));
			}

			muzzle.SetOffset(Vec2f(-16,-3).RotateBy(aimangle, Vec2f(fl?-16:-16,-3)));
			muzzle.RotateBy(getGameTime()%360 * (1.0f + f32(hold_time)/max_hold_time * 10), Vec2f_zero);

			Vec2f pistol_offset = pos - ownerpos;
			sparks(pos + Vec2f(16,fl?3:-3).RotateBy(aimangle), 1, this, this.getTeamNum() == 0, 1.0f + hold_time*0.025f);
		}
	}

	if (this.getTickSinceCreated() > prep_time && this.get_u8("mode") == 0)
	{
		CSpriteLayer@ muzzle = sprite.addSpriteLayer("muzzle", "BashsterMuzzle.png", 16, 16);
		if (muzzle !is null)
		{
			muzzle.SetRelativeZ(502.0f);
			muzzle.SetVisible(false);
			muzzle.ScaleBy(Vec2f(0.01f, 0.01f));
		}

		this.set_u32("ready_time", getGameTime());
		this.set_u8("mode", 1);
	}
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	
	sprite.PlaySound("MagnaCannonShot.ogg", 2.0f, 1.0f+XORRandom(11)*0.01f);
	sprite.SetEmitSoundPaused(true);
}

Random _sprk_r(1265);
void sparks(Vec2f Pos, int amount, CBlob@ this, bool blue, f32 speed = 1.0f)
{
	if (!getNet().isClient())
		return;

	CParticle@[] particleList;
	this.get("ParticleList",particleList);
	for(int a = 0; a < 3; a++)
	{	
		Vec2f rnd_pos = Vec2f(4+XORRandom(16),0).RotateBy(XORRandom(360));
		CParticle@ p = ParticleAnimated("BashsterParticle.png", Pos + rnd_pos, Vec2f_zero, XORRandom(360), 1.0f, 1+XORRandom(2), 0.0f, true);

		if(p !is null)
		{
			p.collides = false;
			p.Z = 501.0f;
			p.gravity = Vec2f(0,0);
			p.lighting = true;
			p.setRenderStyle(RenderStyle::additive);
			p.scale = 0.25f;
			p.deadeffect = -1;
			p.diesonanimate = true;
			p.alivetime = 10;
			p.Z = 1.02f;

			particleList.push_back(p);
		}
	}
	for(int a = 0; a < particleList.length(); a++)
	{
		CParticle@ particle = particleList[a];
		//check
		if(particle is null || particle.alivetime == 0 || particle.Z != 1.02f)
		{
			particleList.erase(a);
			a--;
			continue;
		}
		particle.alivetime--;

		//Gravity
		Vec2f tempGrav = Vec2f(0,0);
		tempGrav.x = -(particle.position.x - Pos.x);
		tempGrav.y = -(particle.position.y - Pos.y);

		//Colour
		SColor col = particle.colour;

		//set stuff
		particle.colour = col;
		particle.forcecolor = col;
		particle.gravity = tempGrav / (40/speed);//tweak the 20 till your heart is content

		//particleList[a] = @particle;
	}

	this.set("ParticleList", particleList);
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			target.hasTag("projectile") ||
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
		p.Z = 500.0f;
		p.lighting = false;
		if (transparent)
			p.setRenderStyle(RenderStyle::additive);
    }
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount, f32 pvel = 1.0f, bool death_effect = false)
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
		f32 extra = 0;

		if (death_effect)
		{
			p.setRenderStyle(RenderStyle::additive);
			extra = 0.5f;
			p.timeout = 10;
		}

    	p.fastcollision = true;
        p.scale = 0.75f + _blast_r.NextFloat()*0.5f + extra;
        p.damping = 0.85f;
		p.Z = 501.0f;
		p.lighting = false;
    }
}