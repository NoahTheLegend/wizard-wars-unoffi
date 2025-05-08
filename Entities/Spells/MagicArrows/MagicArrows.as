#include "Hitters.as"

f32 max_angle = 67.5f; // max capture angle, actually doubled so this is 135 degree coverage
f32 vel = 6.0f;
f32 turn_rate = 0.15f;

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("die_in_divine_shield");

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	
	this.getShape().getConsts().bullet = true;

	this.getShape().SetGravityScale(0.0f);

	this.getSprite().PlaySound("WizardShoot.ogg", 2.0f, 2.5f);
	this.getSprite().SetZ(30.0f);
	this.set_u16("target_id", 0);
}

void onTick(CBlob@ this)
{
	f32 vel_angle = -this.getVelocity().Angle()+90.0f;
	if (vel_angle < 0.0f) vel_angle += 360.0f;
	if (vel_angle > 360.0f) vel_angle -= 360.0f;
	if (this.getVelocity().Length() > 0.1f) this.setAngleDegrees(vel_angle);

	if (this.getTickSinceCreated() == 1
		|| (this.get_u16("target_id") == 0))
	{
		f32 closest = 99999.0f;
		u16 id = 0;
		for (u8 i = 0; i < getPlayersCount(); i++)
		{
			if (getPlayer(i) is null) continue;
			CBlob@ b = getPlayer(i).getBlob();
			if (b is null || b.getTeamNum() == this.getTeamNum()) continue;
			if (getMap().rayCastSolidNoBlobs(this.getPosition(), b.getPosition())) continue;

			f32 angle = -(b.getPosition()-this.getPosition()).Angle()+90.0f;
			if (angle > 360.0f) angle -= 360.0f;
			if (angle < -0.0f) angle += 360.0f;

			//printf("a "+angle+" d "+this.getAngleDegrees());
			if ((Maths::Abs(angle-this.getAngleDegrees()) <= max_angle
				|| (angle <= max_angle/2 && this.getAngleDegrees() >= 360-max_angle/2)
				|| (angle >= 360-max_angle/2 && this.getAngleDegrees() <= max_angle/2))
				&& this.getDistanceTo(b) < closest)
			{
				closest = this.getDistanceTo(b);
				id = b.getNetworkID();
			}
		}
		this.set_u16("target_id", id);
	}
	
	CBlob@ target = getBlobByNetworkID(this.get_u16("target_id"));
	if (target !is null)
	{
		if (isServer() && this.getDistanceTo(target) <= 16.0f)
		{
			this.server_Hit(target, target.getPosition(), Vec2f(0,0.75f), this.get_f32("damage"), Hitters::arrow, true);
			this.Tag("mark_for_death");
		}
		Vec2f dir = target.getPosition() - this.getPosition();
		dir.Normalize();

		f32 angle = -(target.getPosition()-this.getPosition()).Angle()+90.0f;
		if (angle > 360.0f) angle -= 360.0f;
		if (angle < -0.0f) angle += 360.0f;

		if (this.getDistanceTo(target) > 16.0f
				&& !((Maths::Abs(angle-this.getAngleDegrees()) <= max_angle
				|| (angle <= max_angle/2 && this.getAngleDegrees() >= 360-max_angle/2)
				|| (angle >= 360-max_angle/2 && this.getAngleDegrees() <= max_angle/2))))
		{
			this.set_u16("target_id", 0);
		}

		if (angle < 1.0f || angle > 359.0f)
		{
			this.setAngleDegrees(0);
		}
		else if ((angle <= max_angle && this.getAngleDegrees() >= 360-max_angle)
			|| (angle >= 360-max_angle && this.getAngleDegrees() <= max_angle))
		{
			//printf("a "+angle+" d "+this.getAngleDegrees());
			this.setAngleDegrees((angle == 0 ? 180 : 0) + Maths::Lerp(this.getAngleDegrees()+(this.getPosition().x<=target.getPosition().x?90:-90), angle, turn_rate));
		}
		else
		{
			this.setAngleDegrees(Maths::Lerp(this.getAngleDegrees(), angle, turn_rate));
		}
	}

	this.setVelocity(Vec2f(0,-vel).RotateBy(this.getAngleDegrees()));

	if (this.getPosition().y < 0 || this.getPosition().x < 0
		|| this.getPosition().y > getMap().tilemapheight*8
		|| this.getPosition().x > getMap().tilemapwidth*8) this.Tag("mark_for_death");

	sparks(this.getPosition()+Vec2f(0,8).RotateBy(this.getAngleDegrees()), 30, Vec2f_zero,
		Vec2f(0,0.5f).RotateBy(this.getAngleDegrees()), 0.75f);
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 50, Vec2f_zero, Vec2f(0,0.5f), 0.99f);
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
	
	if(blob is null)
	{return false;}

	return this.get_u16("target_id") == blob.getNetworkID();
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (!isServer()) return;
	if (blob !is null && blob.getTeamNum() != this.getTeamNum() && (blob.hasTag("zombie") || blob.hasTag("barrier")))
	{
		this.Tag("mark_for_death");
	}
	if (blob !is null && this.get_u16("target_id") == blob.getNetworkID() && this.get_u16("target_id") != 0)
	{
		this.server_Hit(blob, blob.getPosition(), Vec2f(0,0.75f), this.get_f32("damage"), Hitters::arrow, true);
		this.Tag("mark_for_death");
	}
	if (blob is null && solid)
	{
		this.Tag("mark_for_death");
	}
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount, Vec2f gravity, Vec2f vel, f32 damping)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited(pos, vel, SColor( 255, 255, 255, 255), true);
        if(p is null) return;

    	p.fastcollision = true;
		p.gravity = gravity;
        p.timeout = 10 + _sprk_r.NextRanged(10);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = damping;
		p.Z = -1.0f;
    }
}