#include "Hitters.as";
#include "SpellCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = true;
	consts.bullet = false;
	shape.SetGravityScale(0.33f);

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	this.Tag("die_in_divine_shield");

	this.set_f32("damage", 0.5f);

	this.getSprite().SetZ(9.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(15.0f);

	CSprite@ sprite = this.getSprite();
	sprite.ScaleBy(Vec2f(1.15f, 1.15f));
	this.getSprite().ScaleBy(Vec2f(0.8f, 0.8f));
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated()==0)
	{
		// sound goes here
	}

	if (this.isOnGround())
	{
		this.getSprite().SetAnimation("ground");
		if (!this.hasTag("done")) this.server_SetTimeToDie(1.0f);
		this.Tag("done");
		return;
	}
	
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

	if(!isClient())
	{return;}

	if (getGameTime()%2==0)
	{
		for(int i = 0; i < 3; i ++)
		{
			float randomPVel = XORRandom(11) * 0.01f - 0.5f;
			Vec2f particleVel = Vec2f(randomPVel, 0).RotateBy(XORRandom(721));

    		CParticle@ p = ParticlePixelUnlimited(this.getPosition()+Vec2f(-0.5f, -3).RotateByDegrees(this.getAngleDegrees()), particleVel, SColor(255,255,75+XORRandom(76),XORRandom(51)), true);
   			if(p !is null)
    		{
    		    p.collides = false;
    		    p.gravity = Vec2f_zero;
    		    p.bounce = 1;
    		    p.lighting = false;
    		    p.timeout = 5+XORRandom(6);
				p.damping = 0.95f;
    		}
		}
	}
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
	if (this.getTickSinceCreated() < 3) return;
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
	map.getBlobsInRadius(this.getPosition(), 4.0f, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		if(blobsInRadius[i] is null)
		{continue;}

		CBlob@ radiusBlob = blobsInRadius[i];

		if (radiusBlob.getTeamNum() == this.getTeamNum())
		{continue;}

		this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f(0,0.1f), damage, Hitters::boulder, false);
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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}