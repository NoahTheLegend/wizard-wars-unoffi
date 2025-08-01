// Knockback on hit - put before any damaging things but after any scalers
#include "Hitters.as"
#include "HittersWW.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 x_side = 0.0f;
	f32 y_side = 0.0f;
	//if (hitterBlob !is null)
	{
		//Vec2f dif = hitterBlob.getPosition() - this.getPosition();
		if (velocity.x > 0.7)
		{
			x_side = 1.0f;
		}
		else if (velocity.x < -0.7)
		{
			x_side = -1.0f;
		}

		if (velocity.y > 0.5)
		{
			y_side = 1.0f;
		}
		else
		{
			y_side = -1.0f;
		}
	}
	f32 scale = 1.0f;

	//scale per hitter
	switch (customData)
	{
		case Hitters::fall:
		case Hitters::drown:
		case Hitters::burn:
		case Hitters::crush:
		case Hitters::spikes:
		case HittersWW::poison:
		case HittersWW::electricity:
			scale = 0.0f; break;

		case Hitters::arrow:
			scale = 0.0f; break;

		default: break;
	}

	if(this.get_u16("stoneSkin") > 0) // stone skin knockback nullifier
	{
		scale = 0.0f;
	}

	Vec2f f(x_side, y_side);

	if (damage > 0.125f && customData != 41 && velocity.y != -0.69f)
	{
		this.AddForce(f * 40.0f * scale * Maths::Log(2.0f * (10.0f + (damage * 2.0f))));
	}

	return damage; //damage not affected
}
