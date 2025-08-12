#include "Hitters.as";
#include "TeamColour.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();

	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;

	this.Tag("barrier");
	this.Tag("counterable");

	this.set_Vec2f("smashtoparticles_grav", Vec2f(0, -0.05f));
	this.set_Vec2f("smashtoparticles_grav_rnd", Vec2f(0.1, 0));
	this.Tag("smashtoparticles_additive");

	this.getSprite().setRenderStyle(RenderStyle::additive);
	this.getSprite().SetZ(-50.0f);

	this.SetFacingLeft(XORRandom(2) == 0);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("DemonBarrierSpawn.ogg", 1.0f, 1.0f);	
		this.server_SetTimeToDie(3);
		
		CShape@ shape = this.getShape();
		shape.SetStatic(true);
	}
}

void onDie(CBlob@ this)
{
	shieldSparks(this.getPosition(), 3, this.getAngleDegrees(), this.getTeamNum());
	this.getSprite().PlaySound("EnergySound2.ogg", 1.0f, 1.25f + XORRandom(10) * 0.01f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return target.getTeamNum() != this.getTeamNum() && target.hasTag("projectile");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ b)
{
	return isEnemy(this, b);
}

Random _sprk_r(32432);
void shieldSparks(Vec2f pos, int amountPerFan, f32 orientation, int teamNum)
{
	if ( !getNet().isClient() )
		return;
	
	f32 fanAngle = 10.0f;
	for (int i = 0; i < amountPerFan; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(orientation - fanAngle/2.0f + _sprk_r.NextFloat()*fanAngle);
		
		SColor col = getTeamColor(teamNum);
		
        CParticle@ p = ParticlePixelUnlimited( pos, vel, col, true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(30);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.collides = false;
		p.Z = 510.0f;
    }

	for (int i = 0; i < amountPerFan; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(orientation + 180.0f - fanAngle/2.0f + _sprk_r.NextFloat()*fanAngle);
		
		SColor col = getTeamColor(teamNum);
		
        CParticle@ p = ParticlePixelUnlimited( pos, vel, col, false );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(30);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.collides = false;
		p.Z = 510.0f;
    }
}
