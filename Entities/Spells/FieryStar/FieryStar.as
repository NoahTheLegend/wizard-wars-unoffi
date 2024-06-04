#include "Hitters.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = true;
	consts.bullet = false;

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	shape.SetGravityScale( 0.0f );
	this.Tag("die_in_divine_shield");

	this.set_f32("damage", 1.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(8);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(this is null || blob is null)
	{return false;}

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

	return false;
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated()==0)
	{
		this.getSprite().PlaySound("FireBlast4.ogg", 0.8f, 1.15f + XORRandom(21)*0.01f);
	}
	
	if (this.getVelocity().Length() <= 0.5f)
		this.setVelocity(Vec2f(1.0f + XORRandom(11)*0.1f, 0).RotateBy((getGameTime()*8+this.getNetworkID())%360));

	Vec2f pos = this.getPosition();
	if ( pos.x < 0.1f ||
	pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

	CMap@ map = getMap();
	if (map is null)
	{return;}

	if(getGameTime() % 5 == 0)
	{
		CBlob@[] blobsInRadius;
		map.getBlobsInRadius(this.getPosition(), 20.0f, @blobsInRadius);
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			if(blobsInRadius[i] is null)
			{continue;}

			CBlob@ radiusBlob = blobsInRadius[i];

			if (radiusBlob.getTeamNum() == this.getTeamNum() || radiusBlob.hasTag("burning"))
			{continue;}

			this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, 0.2f, Hitters::fire, false);
		}
	}

	if(!isClient())
	{return;}

	for(int i = 0; i < 5; i ++)
	{
		float randomPVel = XORRandom(10) / 10.0f;
		Vec2f particleVel = Vec2f( randomPVel ,0).RotateByDegrees(XORRandom(360));
		particleVel += this.getVelocity();

    	CParticle@ p = ParticlePixelUnlimited(this.getPosition(), particleVel, SColor(255,255,255,0), true);
   		if(p !is null)
    	{
    	    p.collides = false;
    	    p.gravity = Vec2f_zero;
    	    p.bounce = 1;
    	    p.lighting = false;
    	    p.timeout = 60;
			p.damping = 0.95;
    	}
	}
}

void onTick(CSprite@ this) //rotating sprite
{
	CBlob@ b = this.getBlob();
	if(this is null || b is null)
	{return;}

	if(!b.exists("spriteSetupDone") || !b.get_bool("spriteSetupDone"))
	{
		CSpriteLayer@ layer = this.addSpriteLayer("shine","spriteback_alpha.png",150,150,b.getTeamNum(),0);
		if(layer is null)
		{return;}
        layer.SetRelativeZ(-1.0f);
		layer.setRenderStyle(RenderStyle::additive);
		layer.ScaleBy(0.3f, 0.3f);
		b.set_bool("spriteSetupDone",true);
	}
	else
	{
    	CSpriteLayer@ layer = this.getSpriteLayer("shine");
		if(layer is null)
		{return;}
	
    	layer.RotateByDegrees(7,Vec2f_zero);

		this.RotateByDegrees(-7,Vec2f_zero);
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("shine");
	if(layer is null)
	{return;}
	layer.setRenderStyle(RenderStyle::additive);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (blob !is null && this !is null)
	{
		if (isEnemy(this, blob))
		{
			this.server_Die();
		}
	}
}

void onDie( CBlob@ this )
{
	if(!this.hasTag("exploding"))
	{return;}

	Vec2f thisPos = this.getPosition();
	//Vec2f othPos = blob.getPosition();
	//Vec2f kickDir = othPos - selfPos;

	float damage = this.get_f32("damage");

	CMap@ map = getMap();
	if (map is null)
	{return;}

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(this.getPosition(), 50.0f, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		if(blobsInRadius[i] is null)
		{continue;}

		CBlob@ radiusBlob = blobsInRadius[i];

		CPlayer@ player = this.getDamageOwnerPlayer();
		if(player !is null)
		{
			CBlob@ caster = player.getBlob();
			if(caster !is null && radiusBlob is caster)
			{
				this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::fire, true);
				continue;
			}
		}

		if (radiusBlob.getTeamNum() == this.getTeamNum())
		{continue;}

		this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::fire, false);
	}
			
	if ( isClient() ) 
	{
		this.getSprite().PlaySound("GenericExplosion1.ogg", 0.8f, 0.8f + XORRandom(10)/10.0f);

		//particles front

		CParticle@ pa = ParticleAnimated( "fiery_boom.png",
			this.getPosition(),
			Vec2f(0,0),
			0,
			1.0f, 
			3, 
			0.0f, true );    
		if ( pa !is null)
		{
			pa.bounce = 0;
    		pa.fastcollision = true;
			pa.Z = 10.0f;
			pa.setRenderStyle(RenderStyle::additive);
		}

		//particles back
	
		CParticle@ pb = ParticleAnimated( "fiery_boom_back.png",
			this.getPosition(),
			Vec2f(0,0),
			0,
			1.0f, 
			3, 
			0.0f, true );    
		if ( pb !is null)
		{
			pb.bounce = 0;
    		pb.fastcollision = true;
			pb.Z = -10.0f;
			pb.setRenderStyle(RenderStyle::additive);
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(
			target.hasTag("barrier") || (target.hasTag("flesh") && !target.hasTag("dead") )
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}