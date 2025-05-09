#include "SplashWater.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("kill other spells");
	this.Tag("counterable");
	this.Tag("water projectile");
	this.Tag("water spell");
	this.Tag("smashtoparticles_additive");
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().getConsts().bullet = true;
	
	CSprite@ thisSprite = this.getSprite();
	thisSprite.ScaleBy(Vec2f(0.9f, 0.9f));
	CSpriteLayer@ l = thisSprite.addSpriteLayer("l", "WaterBolt.png", 18, 18);
	if (l !is null)
	{
		l.ScaleBy(Vec2f(0.95f, 0.95f));

		Animation@ anim = l.addAnimation("default", 0, false);
		if (anim !is null)
		{
			int[] frames = {0,1,2,3};
			anim.AddFrames(frames);
			
			l.SetAnimation(anim);
			l.setRenderStyle(RenderStyle::additive);
			l.SetRelativeZ(101.0f);
		}
	}

	this.getShape().SetGravityScale(0.0f);
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ l = this.getSpriteLayer("l");
	if (l !is null)
	{
		l.animation.frame = this.animation.frame;
	}
}

void onTick(CBlob@ this)
{
	if (this.getVelocity().Length() > 0.01f) this.setAngleDegrees(-this.getVelocity().Angle());

	if (this.getTickSinceCreated() == 0)
	{
		this.server_SetTimeToDie(4);
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		this.SetLightColor(SColor(255, 114, 121, 224));
		this.getSprite().PlaySound("waterbolt_wave.ogg", 0.375f, 1.75f + XORRandom(11)*0.01f);
		this.getSprite().PlaySound("waterbolt_splash0.ogg", 0.375f, 1.75f + XORRandom(11)*0.01f);
		this.getSprite().SetZ(100.0f);
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door")
			|| target.getName() == "trap_block") || (target.hasTag("barrier") && target.getTeamNum() != this.getTeamNum()) )
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
	
	return ( isEnemy(this, blob) );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid || (blob !is null && blob.hasTag("kill water spells"))) this.Tag("mark_for_death");
	if (blob !is null && doesCollideWithBlob(this, blob))
	{
		if (isEnemy(this, blob))
		{
			this.server_Hit(blob, this.getPosition(), this.getVelocity() * 2, this.get_f32("damage"), Hitters::water, true);
		}

		this.Tag("mark_for_death");
	} 
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 50);
	this.getSprite().PlaySound("waterbolt_death.ogg", 0.375f, 1.5f + XORRandom(11)*0.01f);
	Splash(this, 1, 1, 0, false);
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

		u8 rnd = XORRandom(100);
        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 125+rnd, 125+rnd, 255), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
		p.setRenderStyle(RenderStyle::additive);
        p.damping = 0.95f;
    }
}
