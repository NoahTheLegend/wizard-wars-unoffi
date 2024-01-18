void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	this.set_f32("explosive_radius", 12.0f);
	this.set_f32("explosive_damage", 1.0f);
	this.set_f32("map_damage_radius", 16.0f);
	this.set_f32("map_damage_ratio", -1.0f);

	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	CShape@ shape = this.getShape();
	shape.getConsts().net_threshold_multiplier = 0.5f;
	
	shape.getConsts().bullet = true;
	shape.getConsts().mapCollisions = false;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	if (sprite.animation !is null)
	{
		sprite.animation.frame = XORRandom(sprite.animation.getFramesCount());
	}
	sprite.ScaleBy(Vec2f(1.25f, 1.25f));
}

void onTick(CBlob@ this)
{
	if (isServer() && this.hasTag("accelerate"))
	{
		this.setVelocity(this.getVelocity()*1.05f);
	}

	if (this.getTickSinceCreated() == 0)
	{
		this.getShape().SetGravityScale(0.0f);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 211, 211, 211));
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("WizardShoot.ogg", 2.5f, 1.1f);
		this.getSprite().SetZ(1000.0f);
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	if (this.getTickSinceCreated() < 2) return false;
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && (target.hasTag("door") || target.getName() == "trap_block"))
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
	if (blob.hasTag("projectile")) return false;
	return this.getTickSinceCreated() > 30 && (isEnemy(this, blob) || blob.hasTag("barrier"));
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null) return;

	if (doesCollideWithBlob(this, blob))
	{
		this.server_Die();
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    if ((hitterBlob.getName() == this.getName() || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
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
