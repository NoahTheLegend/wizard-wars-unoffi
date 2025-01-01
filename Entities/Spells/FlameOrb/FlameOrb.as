#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("kill water spells");
	this.Tag("fire spell");
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("kill other spells");
	this.Tag("exploding");
	this.set_f32("explosive_radius", 8.0f);
	this.set_f32("explosive_damage", 0.1f);
	this.set_f32("map_damage_radius", 0.0f);
	this.set_f32("map_damage_ratio", -1.0f); //heck no!
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = false;
	this.getCurrentScript().tickFrequency = 1;

	this.getShape().SetGravityScale(0.0f);
	this.server_SetTimeToDie(3);
	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 211, 121, 224));
	this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
	this.getSprite().SetZ(1000.0f);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1)
	{
		this.getSprite().PlaySound("flame_slash_sound", 1.5f, 1.75f);
    	this.getSprite().PlaySound("MagicMissile.ogg", 0.33f, 1.0f + XORRandom(6)*0.01f);
	}
	sparks(this.getPosition(), 5, Vec2f_zero);
	if (this.isInWater()) this.server_Die();
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
	CMap@ map = getMap();
	if (solid)
	{
		this.getSprite().PlaySound("EnergyBounce" + (XORRandom(2)+1) + ".ogg", 0.15f, 0.5f + XORRandom(3)/10.0f);
		sparks(this.getPosition(), 8);
		
		if (isServer())
		{
			if (blob !is null && isEnemy(this, blob))
			{
				if(!blob.hasScript("BladedShell.as"))
				{
					this.server_Hit(blob, blob.getPosition(), Vec2f_zero, 0.01f, Hitters::fire, true);
					map.server_setFireWorldspace(blob.getPosition(), true);
					map.server_setFireWorldspace(this.getPosition(), true);
				}
				this.server_Die();
			}
			if (blob is null)
			{
				map.server_setFireWorldspace(this.getPosition(), true);
				this.server_Die();
			}
		}
	}
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 15);
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
void sparks(Vec2f pos, int amount, Vec2f gravity)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 255, 75+_sprk_r.NextRanged(75), _sprk_r.NextRanged(55)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.gravity = gravity;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}
