void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	this.set_f32("explosive_radius", 12.0f);
	this.set_f32("explosive_damage", 0.5f);
	this.set_f32("map_damage_radius", 16.0f);
	this.set_f32("map_damage_ratio", -1.0f); //heck no!

	if (!this.exists("count")) this.set_u8("count", 0);
	if (!this.exists("id")) this.set_u16("id", 0);
	if (!this.exists("orbs")) this.set_u8("orbs", 0);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	CShape@ shape = this.getShape();
	shape.getConsts().net_threshold_multiplier = 2.0f;
	
	this.getShape().getConsts().bullet = true;

	bool is_main = this.getName() == "epicorbmain";
	if (is_main)
	{
		this.getShape().getConsts().mapCollisions = true;
		if (isServer())
		{
			for (u8 i = 0; i < this.get_u8("orbs"); i++)
			{
				CBlob@ nice = server_CreateBlob("epicorb", this.getTeamNum(), this.getPosition());
				if (nice !is null)
				{
					nice.set_u8("count", i);
					nice.set_u16("id", this.getNetworkID());
					nice.set_u8("orbs", this.get_u8("orbs"));
					nice.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					nice.IgnoreCollisionWhileOverlapped( this );
				} 
			}
		}
	}
	else this.getShape().getConsts().mapCollisions = false;
}

void onTick(CBlob@ this)
{
	bool is_main = this.getName() == "epicorbmain";
	if (this.getTickSinceCreated() == 0)
	{
		this.getShape().SetGravityScale(0.0f);
		this.server_SetTimeToDie(3.1);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 211, 211, 0));
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("WizardShoot.ogg", 2.5f, 1.25f);
		this.getSprite().SetZ(1000.0f);
		if (isClient())
		{ // REMINDER: test without sync on mp
			this.Sync("count", true);
			this.Sync("id", true);
			this.Sync("orbs", true);
			if (is_main)
			{
				this.getSprite().ScaleBy(Vec2f(0.5f,0.5f));
			}
		}
	}
	else
	{
		CBlob@ main = getBlobByNetworkID(this.get_u16("id"));
		if (main !is null)
		{
			if (isServer()) this.server_setTeamNum(main.getTeamNum());
			Vec2f thisPos = this.getPosition();
			if (!is_main)
			{
				Vec2f mainPos = main.getPosition();
				u8 count = this.get_u8("count");
				u8 orbs = this.get_u8("orbs");

				f32 spinAmount = 20-(orbs*(orbs>5?2:3));
				f32 spinMult = (main.getVelocity().x < 0.0f) ? -spinAmount : spinAmount;
				f32 spin = (getGameTime()*spinMult) % 360.0f;

				f32 rot = 360.0f/(orbs);
				rot *= count;
				Vec2f targetPos = mainPos+Vec2f(0,-Maths::Min(4.0f+(orbs*2), 16.0f));
				targetPos.RotateBy(rot+spin, mainPos);

				this.setPosition(targetPos);
			}
		}	
		else if (isServer() && !is_main) this.server_Die();
	}
	/*
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
	*/
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	if (this.getTickSinceCreated() < 2) return false;
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") )
		||
		(
			(target.hasTag("flesh")  || target.hasTag("zombie"))
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "epicorbmain") return false;
	if (this.getName() == "epicorb" && (blob.hasTag("flesh") || blob.hasTag("zombie"))) return true; 
	return ( isEnemy(this, blob) || blob.hasTag("barrier") );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (this.getName() == "epicorbmain") return;
	if (solid || (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("kill other spells")))
	{
		this.getSprite().PlaySound("EnergyBounce" + (XORRandom(2)+1) + ".ogg", 0.3f, 1.0f + XORRandom(3)/10.0f);
		sparks(this.getPosition(), 4);
		
		if(blob !is null && isEnemy(this, blob))
		{
			if(!blob.hasScript("BladedShell.as"))
			{
				this.server_Die();
			}
		} 
	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (( hitterBlob.getName() == this.getName() || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;
    return damage;
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 10);
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
