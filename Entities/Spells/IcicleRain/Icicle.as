#include "Hitters.as";
#include "LimitedAttacks.as";

void onInit(CBlob@ this)
{
	this.Tag("silent");
	this.getSprite().PlaySound("IceCracking.ogg", 0.76f, 0.95f+XORRandom(36)*0.01f);
	
	this.Tag("kill other spells");
	this.Tag("counterable");
	this.Tag("projectile");

	this.getSprite().PlaySound("WizardShoot.ogg", 0.76f, 1.7f+XORRandom(16)*0.01f);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(6.0f);

	this.getShape().SetGravityScale(0.0f);
	this.setAngleDegrees(-Vec2f(0,-8).Angle()-90);
}

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CShape@ shape = this.getShape();


	if (!this.exists("moveTo") || !this.exists("aimPos"))
	{
		this.server_Die();
		return;
	}
	
	Vec2f targetPos = this.get_Vec2f("moveTo");
	Vec2f aimPos = this.get_Vec2f("aimPos");
	if (((this.getPosition()-targetPos).Length() < 4.0f || this.getPosition().y < targetPos.y) && !this.hasTag("arrived"))
	{
		if (!this.exists("aim_vel"))
		{
			Vec2f aim_vel = Vec2f(0,-12).RotateBy(-(aimPos-this.getPosition()).Angle()-90);
			this.set_Vec2f("aim_vel", -aim_vel);
			this.Tag("arrived");
			this.set_u32("arrival_time", getGameTime());
		}
		this.set_u32("launch_delay", getGameTime()+this.get_u8("wait_time"));

		if (this.getTickSinceCreated() > 1) this.setAngleDegrees(Maths::Clamp(0, 360, -this.getVelocity().Angle()-90));
	}
	else if (!this.hasTag("arrived"))
	{
		string particleName = "IcicleFire.png";
		CParticle@ p2 = ParticleAnimated( particleName , targetPos, Vec2f_zero, getGameTime()%360*(0.3f+0.15f*Maths::Sin(getGameTime())), 0.5f, 6, 0.0f, false );
		if ( p2 !is null)
		{
			p2.bounce = 0;
    		p2.fastcollision = true;
			p2.Z = -1.0f;
			p2.frame = 3;
			p2.scale = 1.3f;
		}
		sparks(this.getPosition()+Vec2f(0,-10).RotateBy(this.getAngleDegrees()), 5, Vec2f_zero, Vec2f(0,0.5f).RotateBy(this.getAngleDegrees()));

		this.setVelocity(Vec2f(0,-4).RotateBy(-(this.getPosition()-this.get_Vec2f("moveTo")).Angle()-90));

		if (this.getTickSinceCreated() > 1) this.setAngleDegrees(Maths::Clamp(0, 360, -this.getVelocity().Angle()-90));
	}
	else
	{
		if (this.get_u32("launch_delay") <= getGameTime())
		{
			if (!this.hasTag("had_sound"))
			{
				this.getSprite().PlaySound("ManaGain.ogg", 0.5f, 1.7f + XORRandom(26)*0.01f);
				this.Tag("had_sound");
			}
			this.setVelocity(this.get_Vec2f("aim_vel"));
			this.setAngleDegrees(Maths::Clamp(0, 360, -this.getVelocity().Angle()-90));
		}
		else
		{
			f32 this_angle = this.getAngleDegrees();
			f32 aim_at = -(aimPos-this.getPosition()).Angle();
			f32 aim_angle = aim_at-90;
			if (aim_angle > 360.0f) aim_angle -= 360.0f;
			if (aim_angle < 0.0f && aim_at <= -90.0f) aim_angle += 360.0f;
			this.setVelocity(Vec2f_zero);
			this.setAngleDegrees(Maths::Lerp(this_angle, aimPos.x > this.getPosition().x ? 360-Maths::Abs(aim_angle) : Maths::Abs(aim_angle), 0.25f));
			Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
			sparks(this.getPosition()+Vec2f(0,-11.0f).RotateBy(this.getAngleDegrees()), 1, Vec2f_zero, Vec2f(0,0.33f).RotateBy(this.getAngleDegrees()));
		}
	}
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 30, Vec2f_zero, Vec2f(0,4));
	sparks(this.getPosition(), 20, Vec2f_zero, Vec2f(0,3.33f));
	this.getSprite().PlaySound("IceImpact" + (XORRandom(3)+1) + ".ogg", 0.8f, 1.0f);
	this.getSprite().Gib();
}

void onInit(CSprite@ this)
{
	f32 rand = XORRandom(21)*0.01f;
	this.ScaleBy(Vec2f(0.4f+rand,0.4f+rand));
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob is null || blob.getTeamNum() == this.getTeamNum()) return false;
	return blob.hasTag("kill other spells") || blob.hasTag("flesh") || blob.hasTag("zombie") || blob.hasTag("barrier");
}


void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid || doesCollideWithBlob(this, blob))
	{
		if (blob !is null)
		{
			if (blob.hasScript("BladedShell.as") || blob.hasScript("VoltageField"))
			{
				this.server_Die();
				return;
			}
			f32 dmg = 0.33f;
			if (blob.get_u16("waterbarrier") > 0) dmg *= 2.5f;
			this.server_Hit(blob, blob.getPosition(), Vec2f(0,0.1f), dmg, Hitters::arrow, true);
		}
		this.server_Hit(this, this.getPosition(), this.getVelocity(), 99.0f, Hitters::builder, true);
	}
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount, Vec2f gravity, Vec2f vel)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 75, 100+_sprk_r.NextRanged(100), 225+_sprk_r.NextRanged(30)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.gravity = gravity;
        p.timeout = 10 + _sprk_r.NextRanged(10);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.985f;
		p.Z = -1.0f;
    }
}
