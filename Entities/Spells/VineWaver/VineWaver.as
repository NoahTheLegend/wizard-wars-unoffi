#include "TeamColour.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("die_in_divine_shield");
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	CShape@ shape = this.getShape();
	//shape.getConsts().net_threshold_multiplier = 2.0f;

	shape.SetGravityScale(0);
	shape.getConsts().bullet = true;
	shape.getConsts().mapCollisions = false;

	this.set_bool("back", false);

	this.getSprite().SetRelativeZ(501.0f);
	this.getSprite().PlayRandomSound("VineReveal", 1.5f, 1.65f+XORRandom(16)*0.1f);
}

f32 pi = 3.14f;
const f32 angle_change = 65.0f;
f32 dev = 0.15f; // deviation speed

void onTick(CBlob@ this)
{
	if (isServer())
	{
		bool back = this.get_bool("back");
		
		Vec2f vel = this.get_Vec2f("initvel");
		f32 t = this.getTickSinceCreated()-angle_change*dev;
		f32 sin = Maths::Sin(t*dev)*angle_change;

		vel.RotateBy(back ? -sin : sin);
		this.setVelocity(vel);
		this.setAngleDegrees(-this.getVelocity().Angle());

		CMap@ map = getMap();
		if (map !is null && getGameTime()%3==0)
		{
			CBlob@[] bs;
			map.getBlobsInRadius(this.getPosition(), this.getRadius()*2, @bs);
			for (u16 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null) continue;
				if (isEnemy(this, b))
				{
					this.server_Hit(b, b.getPosition(), Vec2f_zero, this.get_f32("dmg"), Hitters::fall, false);
				}
			}
		}
	}

	if (isClient())
	{
		sparks(this, this.getPosition(), 4);

		if (getGameTime()%2==0)
		{
			CParticle@ p = ParticleAnimated("VineWaver.png", this.getPosition(), Vec2f_zero, this.getAngleDegrees(), 1.0f, 0, 0.0f, false);
			if (p !is null)
			{
				p.bounce = 0;
				p.Z = 501.0f;
				p.collides = false;
				p.fastcollision = true;
				p.timeout = 30;
				p.frame = this.getSprite().animation.frame;
				p.deadeffect = -1;
				p.diesonanimate = false;
			}
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	if (this.getTickSinceCreated() < 2) return false;
	return 
	(
		(
			(target.hasTag("flesh")  || target.hasTag("zombie"))
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

Random _sprk_r(21342);
void sparks(CBlob@ this, Vec2f pos, int amount)
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 0.75f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

		SColor col = SColor(255, 0, 75 + _sprk_r.NextRanged(125), 0);
		if (XORRandom(10) == 0)
		{
			col = getTeamColor(this.getTeamNum());
		}

        CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.collides = false;
		p.gravity = Vec2f(0,0);
        p.timeout = 30 + _sprk_r.NextRanged(10);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
		p.Z = 501.5f;
    }
}
