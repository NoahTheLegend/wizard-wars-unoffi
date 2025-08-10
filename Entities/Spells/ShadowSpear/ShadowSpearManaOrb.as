#include "MagicCommon.as"
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("kill other spells");
	this.Tag("counterable");
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;
    this.addCommandID("add_mana");

	this.set_Vec2f("smashtoparticles_grav", Vec2f(0, 0.0f));
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 0)
	{
		this.getShape().SetGravityScale(0.0f);
		this.server_SetTimeToDie(15);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 211, 121, 224));
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().SetZ(1000.0f);
		this.getSprite().PlaySound("mana_smooth.ogg", 0.85f, 1.0f + XORRandom(10) * 0.01f);
	}

	{
		u16 id = this.get_u16("target");
		if (id != 0xffff && id != 0)
		{
			CBlob@ b = getBlobByNetworkID(id);
			if (b !is null)
			{
				Vec2f vel = this.getVelocity();
				if (vel.LengthSquared() < 9.0f)
				{
					Vec2f dir = b.getPosition() - this.getPosition();
					dir.Normalize();


					this.setVelocity(vel + dir * 3.0f);
				}
			}
		}
	}

	if (isClient() && this.getVelocity().Length() > 0.01f)
	{
        CParticle@ p = ParticleAnimated("ShadowSpearManaOrb.png", this.getPosition(), Vec2f_zero, this.getAngleDegrees(), 0.75f, 3, 0.0f, true);
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

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
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
	
	return ( isEnemy(this, blob) || blob.hasTag("barrier") );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid || blob.hasTag("kill other spells"))
	{
		this.getSprite().PlaySound("EnergyBounce" + (XORRandom(2)+1) + ".ogg", 0.35f, 0.75f + XORRandom(3)/10.0f);
		sparks(this.getPosition(), 4);
	}
    if (blob !is null && blob.hasTag("player") && blob.getTeamNum() == this.getTeamNum() && isServer())
    {
		if (this.hasTag("added")) return;

        CBitStream params;
		params.write_u16(blob.getNetworkID());
		this.SendCommand(this.getCommandID("add_mana"), params);
    } 
}
void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add_mana"))
	{
		u16 id = params.read_u16();
		CBlob@ b = getBlobByNetworkID(id);

		if (b is null) return;
		ManaInfo@ manaInfo;
		if (b.get("manaInfo", @manaInfo))
		{
			//print("add mana from " + b.getName() + " " + manaInfo.mana);
			if (manaInfo.mana < manaInfo.maxMana)
			{
				int mana = this.get_s32("mana_stored");
				if (b.getPlayer() !is this.getDamageOwnerPlayer()) mana *= 2;
				
				manaInfo.mana = Maths::Min(manaInfo.mana + mana, manaInfo.maxMana);

                this.Tag("mark_for_death");
				this.Tag("added");
			}
		}
	}
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 10);

	if (isServer())
	{
		u16 countered_by_id = this.get_u16("countered_by_id");
		CBlob@ countered_by = getBlobByNetworkID(countered_by_id);
		if (countered_by !is null)
		{
			CBitStream params;
			params.write_u16(countered_by.getNetworkID());
			this.SendCommand(this.getCommandID("add_mana"), params);
		}
	}

	this.getSprite().PlaySound("mana_smooth.ogg", 0.75f, 0.75f + XORRandom(10) * 0.01f);
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 255, 128+_sprk_r.NextRanged(128), _sprk_r.NextRanged(128)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}
