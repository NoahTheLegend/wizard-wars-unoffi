void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("kill other spells");
	this.Tag("counterable");
	this.Tag("exploding");
	this.set_f32("explosive_radius", 24.0f);
	this.set_f32("explosive_damage", 1.0f);
	this.set_f32("map_damage_radius", 0.0f);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	CShape@ shape = this.getShape();
	shape.getConsts().bullet = true;
	shape.SetGravityScale(0.0f);
	shape.ResolveInsideMapCollision();
	shape.checkCollisionsAgain = true;
}

void onTick(CBlob@ this)
{
	this.setAngleDegrees(-this.getVelocity().Angle());

	if (isClient())
	{
		smoke(this, this.getOldPosition(), 1);
		if (!this.hasTag("prep"))
		{
			this.Tag("prep");
			this.SetLight(true);
			this.SetLightRadius(24.0f);
			this.SetLightColor(SColor(255, 211, 121, 224));
			this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
			this.getSprite().SetZ(1000.0f);
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
	return ( isEnemy(this, blob) || blob.hasTag("barrier") );
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid || blob.hasTag("kill other spells"))
	{
		sparks(this.getPosition(), 4);
		
		bool die = true;
		if(blob !is null)
		{
			die = isEnemy(this, blob);
			if(die && blob.hasScript("BladedShell.as"))
			{
				die = false;
			}
		}

		if (die)
			this.server_Die();
	}
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

Random _smoke_r(0x10001);
void smoke(CBlob@ this, Vec2f pos, int amount)
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel = -this.getVelocity()/4+Vec2f(XORRandom(1.0f - (XORRandom(21)*0.1f)), 1.0f - (XORRandom(21)*0.1f));

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2, 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 0.75f;
		p.growth = -0.05f;
		p.timeout = 30+XORRandom(6);
        p.damping = 0.9f;
		p.Z = 200.0f;
		p.lighting = false;
		p.setRenderStyle(RenderStyle::additive);
    }
}