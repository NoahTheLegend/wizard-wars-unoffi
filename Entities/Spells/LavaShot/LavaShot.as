#include "Hitters.as";
#include "SpellCommon.as";

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

	this.set_u8("lavadrop_time", 75);
	this.set_u8("lavadrop_amount", 4);

	this.set_f32("damage", 1.0f);

	this.getSprite().SetZ(9.5f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

    this.server_SetTimeToDie(10);

	CSprite@ sprite = this.getSprite();
	sprite.ScaleBy(Vec2f(1.15f, 1.15f));
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated()==0)
	{
		this.getSprite().PlaySound("FireBlast4.ogg", 0.75f, 0.85f + XORRandom(16)*0.01f);
		this.getSprite().PlaySound("flame_slash_sound", 0.85f, 0.85f);
	}

	this.setAngleDegrees(Maths::Clamp(0, 360, -this.getVelocity().Angle()));
	//prevent leaving the map
	
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

	if (isServer())
	{
		if (this.getTickSinceCreated() > 15 && getGameTime()%this.get_u8("lavadrop_time")==0)
		{
			CBlob@ b = server_CreateBlob("lavadrop", this.getTeamNum(), this.getPosition());
			if (b !is null)
			{
				b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			}
		}
	}

	if(!isClient())
	{return;}

	for(int i = 0; i < 3; i ++)
	{
		float randomPVel = XORRandom(16) * 0.01f - 0.75f;
		Vec2f particleVel = Vec2f( randomPVel, 0).RotateByDegrees(this.getAngleDegrees()+(XORRandom(151)-75.0f));

    	CParticle@ p = ParticlePixelUnlimited(this.getPosition()+Vec2f(0, 1).RotateByDegrees(this.getAngleDegrees()), particleVel, SColor(255,255,75+XORRandom(76),XORRandom(51)), true);
   		if(p !is null)
    	{
    	    p.collides = false;
    	    p.gravity = Vec2f_zero;
    	    p.bounce = 1;
    	    p.lighting = false;
    	    p.timeout = 20+XORRandom(11);
			p.damping = 0.95;
    	}
	}
}

void onTick(CSprite@ this) //rotating sprite
{
	CBlob@ b = this.getBlob();
	if(this is null || b is null)
	{return;}
}

void Shatter(CBlob@ this, Vec2f normal)
{
	if (this.hasTag("dead")) return;
	if (!isServer()) return;
	for (u8 i = 0; i < this.get_u8("lavadrop_amount"); i++)
	{
		CBlob@ b = server_CreateBlob("lavadrop", this.getTeamNum(), this.getPosition());
		if (b !is null)
		{
			b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
			b.setVelocity((normal*(XORRandom(6)+3)).RotateBy(XORRandom(251)-125.0f));
			b.getShape().SetGravityScale(0.75f);
		}
	}
	this.Tag("dead");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{	
	if (blob !is null && this !is null)
	{
		if (isEnemy(this, blob))
		{
			Shatter(this, normal);
			this.server_Die();
		}
	}
	else if (solid && blob is null)
	{
		Shatter(this, normal);
		this.server_Die();
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 6.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericBlast5.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 0.75f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void onDie( CBlob@ this )
{
	if (isClient())
	{
		this.getSprite().PlaySound("MolotovExplosion.ogg", 1.0f, 0.65f+XORRandom(26)*0.01f);
		blast(this.getPosition()-Vec2f(0,8), 10);
	}
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
	map.getBlobsInRadius(this.getPosition(), 32.0f, @blobsInRadius);
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