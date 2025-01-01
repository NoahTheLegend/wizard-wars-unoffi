#include "Hitters.as"

f32 max_angle = 45.0f; // max capture angle, actually doubled so this is 135 degree coverage
const f32 angle_lerp = 0.35f;

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("die_in_divine_shield");
	this.Tag("ice spell");

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	CSprite@ thisSprite = this.getSprite();

	this.getShape().getConsts().bullet = true;
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	thisSprite.SetZ(550.0f);
	thisSprite.SetRelativeZ(550.0f);
	this.set_u16("target_id", 0);

	thisSprite.SetEmitSound("ChimeLoop.ogg");
    thisSprite.SetEmitSoundVolume(2.5f);
	thisSprite.SetEmitSoundSpeed(0.75f);
    thisSprite.SetEmitSoundPaused(false);
	thisSprite.setRenderStyle(RenderStyle::light);
}

void onTick(CSprite@ this)
{
	if (this.animation !is null)
	{
		if (this.animation.name == "default" && this.animation.ended())
		{
			this.SetAnimation("fly");
		}
	}
}

void onTick(CBlob@ this)
{
	if (isClient() && this.getTickSinceCreated() > 1)
	{
		CSprite@ thisSprite = this.getSprite();
		if (this.getTickSinceCreated() < 1)
		{
			this.SetLight(true);
			this.SetLightRadius(24.0f);
			this.SetLightColor(SColor(255, 255, 255, 0));
			this.set_string("custom_explosion_sound", "FireBlast2.ogg");
			thisSprite.PlaySound("IceShoot.ogg", 0.5f, 1.25f + XORRandom(11)*0.01f);
			thisSprite.SetZ(50.0f);
		}

		thisSprite.SetFacingLeft(this.getVelocity().x < 0);
		thisSprite.ResetTransform();
		thisSprite.RotateBy(this.isFacingLeft() ? 90 : -90, Vec2f());
		thisSprite.setRenderStyle(RenderStyle::light);

		CParticle@ p = ParticleAnimated( "IceBlast" + (XORRandom(3)+1) + ".png", 
		this.getOldPosition() - Vec2f(0, -16).RotateBy(this.getAngleDegrees()), 
		Vec2f(0,0), 
		0.0f, 
		1.0f, 
		2 + XORRandom(4), 
		0.0f, 
		false );

		if (p !is null)
		{
			p.Z = 520.0f;
			p.setRenderStyle(RenderStyle::additive);
			p.growth = -0.05f;
			p.scale = 0.75f;
		}
	}

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
	    Vec2f dir = target.getPosition() - this.getPosition();
	    dir.Normalize();


	    f32 angle = -(target.getPosition() - this.getPosition()).Angle() + 90.0f;

	    while (angle < 0) angle += 360.0f;
	    while (angle >= 360) angle -= 360.0f;

	    if (this.getDistanceTo(target) > 16.0f &&
	        !((Maths::Abs(angle - this.getAngleDegrees()) <= max_angle) ||
	          (angle <= max_angle / 2 && this.getAngleDegrees() >= 360 - max_angle / 2) ||
	          (angle >= 360 - max_angle / 2 && this.getAngleDegrees() <= max_angle / 2)))
	    {
	        this.set_u16("target_id", 0);
	        return;
	    }

	    f32 currentAngle = this.getAngleDegrees();
	    f32 deltaAngle = angle - currentAngle;

	    if (deltaAngle > 180.0f) deltaAngle -= 360.0f;
	    if (deltaAngle < -180.0f) deltaAngle += 360.0f;

	    this.setAngleDegrees(currentAngle + deltaAngle * 0.1f);
	}

	this.setVelocity(Vec2f(0,-2.0f * (1.0f + Maths::Min(5.0f, (this.getTickSinceCreated() / 30.0f)))).RotateBy(this.getAngleDegrees()));

	if (this.getPosition().y < 0 || this.getPosition().x < 0
		|| this.getPosition().y > getMap().tilemapheight*8
		|| this.getPosition().x > getMap().tilemapwidth*8) this.server_Die();
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("IceImpact" + (XORRandom(3)+1) + ".ogg", 1.5f, 1.33f);
	blast(this.getPosition(), 5);
	this.getSprite().SetEmitSoundPaused(true);
	sparks(this.getPosition(), 50, Vec2f_zero, Vec2f(0,0.5f), 0.99f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(blob is null)
	{return false;}

	return this.get_u16("target_id") == blob.getNetworkID();
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	bool spellDeath = false;

	if ( solid || (blob !is null && blob.hasTag("barrier") && blob.getTeamNum() != this.getTeamNum()) )
	{
		this.getSprite().PlaySound("IceImpact" + (XORRandom(3)+1) + ".ogg", 0.8f, 1.0f);
		spellDeath = true;
	}

	if (blob !is null)
	{
		if (this.get_u16("target_id") == blob.getNetworkID() )
		{
			f32 damage = this.get_f32("damage");
			if (blob.get_bool("waterbarrier") || blob.isInWater()) damage *= 1.25f;

			this.server_Hit(blob, blob.getPosition(), this.getVelocity(), damage, Hitters::water, true);
			Freeze(blob, 1.5f+XORRandom(11)*0.1f);
			
			spellDeath = true;
		}
	}
	else
	{
		if(isServer())
		{
			CBlob@ icePrison = server_CreateBlob( "ice_prison", this.getTeamNum(), this.getPosition() );
			if ( icePrison !is null )
			{
				icePrison.AddScript("CheapFakeRolling.as");
			}
		}
	}

	if(spellDeath)
	{
		this.server_Die();
	}
}

void Freeze(CBlob@ blob, f32 frozenTime)
{	
	blob.getShape().getConsts().collideWhenAttached = false;

	Vec2f blobPos = blob.getPosition();
	if(isServer())
	{
		CBlob@ icePrison = server_CreateBlob( "ice_prison", blob.getTeamNum(), blobPos );
		if ( icePrison !is null )
		{
			AttachmentPoint@ ap = icePrison.getAttachments().getAttachmentPointByName("PICKUP2");
			if ( ap !is null )
			{
				icePrison.setVelocity(blob.getVelocity()*0.5f);
				icePrison.server_AttachTo(blob, "PICKUP2");
			}
			
			//CSpriteLayer@ iceLayer = icePrison.getSprite().getSpriteLayer( "IcePrison" );
			//if(iceLayer !is null)
			//{			
			//	iceLayer.ScaleBy(Vec2f( (blobRadius + 4.0f)/prisonRadius, (blobRadius + 4.0f)/prisonRadius));
			//}
			
			icePrison.server_SetTimeToDie(frozenTime);
		}
	}

}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(!getNet().isClient()) 
		return;
	//warn("making smoke");

	const f32 rad = 4.0f;
	f32 freezeRatio = this.get_f32("freeze_power");
	freezeRatio++;
	float freezeParticlePos = freezeRatio*64;
	Vec2f random = Vec2f( XORRandom(freezeParticlePos*2)-freezeParticlePos, XORRandom(freezeParticlePos*2)-freezeParticlePos ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "Sparkle" + (XORRandom(3)+1) + ".png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), freezeRatio, 2 + XORRandom(3), 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 520.0f;
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {									
		const f32 rad = 16.0f;
		Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
        CParticle@ p = ParticleAnimated( "IceBlast" + (XORRandom(3)+1) + ".png", 
									pos + random, 
									Vec2f(0,0), 
									0.0f, 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles
		
    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 520.0f;
		p.lighting = false;
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
		p.Z = 519.0f;
    }
}