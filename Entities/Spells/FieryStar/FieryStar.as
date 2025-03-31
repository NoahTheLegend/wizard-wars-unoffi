#include "Hitters.as";

const f32 fluctuation_speed = 0.25f;
const f32 max_fluctuation = 25.0f / fluctuation_speed;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.bullet = false;
	consts.mapCollisions = false;

	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("exploding");
	this.Tag("kill water spells");
	this.Tag("fire spell");
	
	shape.SetGravityScale(0.0f);
	this.Tag("die_in_divine_shield");
	this.set_f32("damage", 1.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
    this.server_SetTimeToDie(2);

	bool left = this.get_bool("left");
	this.set_f32("fluctuation", left ? -max_fluctuation : max_fluctuation);
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated()==0)
	{
		this.getSprite().PlaySound("FireBlast4.ogg", 1.0f, 1.8f + XORRandom(11)*0.01f);
		this.getSprite().PlaySound("WizardShoot.ogg", 1.0f, 0.7f);
		blast(this.getPosition(), 2 + XORRandom(3));
	}

	if(isClient())
		sparks(this, 20);

	bool has_solid = this.getShape().isOverlappingTileSolid(true);
	if (!this.hasTag("solid") && getMap() !is null && !has_solid)
	{
		this.getShape().getConsts().mapCollisions = true;
		if (has_solid) this.server_Die();
		this.Tag("solid");
	}
	else if (!this.hasTag("solid") && this.getTickSinceCreated() > ticks_noclip)
		this.server_Die();
	
	if (this.isInWater()) this.server_Die();

	Vec2f pos = this.getPosition();
	if (pos.x < 0.1f ||
	pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f)
	{
		this.server_Die();
		return;
	}

	f32 face = this.get_bool("left") ? -1 : 1;
	f32 fluctuation = Maths::Sin(this.getTickSinceCreated() * fluctuation_speed) * max_fluctuation * face * this.get_f32("fluctuation_factor");
	this.set_f32("fluctuation", fluctuation);	

	f32 angle = this.getAngleDegrees();
	f32 next_angle = angle + fluctuation * fluctuation_speed;

	if (isServer()) this.setVelocity(Vec2f(0, -1).RotateByDegrees(next_angle) * this.get_f32("speed"));
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
		this.SetZ(600.0f);
        layer.SetRelativeZ(601.0f);
		layer.setRenderStyle(RenderStyle::additive);
		layer.ScaleBy(0.15f, 0.15f);
		this.ScaleBy(Vec2f(0.5f, 0.5f));
		b.set_bool("spriteSetupDone",true);
	}
	else
	{
    	CSpriteLayer@ layer = this.getSpriteLayer("shine");
		if(layer is null)
		{return;}

		f32 rot = 16;
		if (b.getNetworkID() % 2 == 0) rot = -rot;
    	layer.RotateByDegrees(rot, Vec2f_zero);
		this.RotateByDegrees(-rot,Vec2f_zero);
	}
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	CSpriteLayer@ layer = this.getSprite().getSpriteLayer("shine");
	if(layer is null)
	{return;}
	layer.setRenderStyle(RenderStyle::additive);
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


void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	if ((solid && blob is null) || isEnemy(this, blob))
	{
		this.server_Die();
	}
}

const f32 ticks_noclip = 15;
void onDie(CBlob@ this)
{
	if(!this.hasTag("exploding"))
	{return;}

	Vec2f thisPos = this.getPosition();
	float damage = this.get_f32("damage");

	CMap@ map = getMap();
	if (map is null)
	{return;}
	
	if (isClient()) this.getSprite().PlaySound("FireBlast11.ogg", 0.8f, 1.5f + XORRandom(20)/100.0f);

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(this.getPosition(), 32.0f, @blobsInRadius);
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		if(blobsInRadius[i] is null)
		{continue;}

		CBlob@ radiusBlob = blobsInRadius[i];

		if (radiusBlob.getTeamNum() == this.getTeamNum() && radiusBlob.getPlayer() !is this.getDamageOwnerPlayer())
		{continue;}

		if (radiusBlob.getDistanceTo(this) > 16.0f) damage *= 0.5f;
		this.server_Hit(radiusBlob, radiusBlob.getPosition(), Vec2f_zero, damage, Hitters::explosion, false);
	}
			
	if (isClient()) 
	{
		blast(thisPos, 6+XORRandom(3));
		smoke(thisPos, 4+XORRandom(3));
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericBlast5.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									0.5f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 0.33f + _blast_r.NextFloat()*0.17f;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}


Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(2.0f + _smoke_r.NextFloat() * 2.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									0.75f, 
									4 + XORRandom(8), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 1.0f + _smoke_r.NextFloat()*0.5f;
        p.damping = 0.8f;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void sparks(CBlob@ this, int amount)
{
	if (!getNet().isClient())
		return;

	Vec2f pos = this.getPosition();
	Vec2f thisVel = this.getVelocity();
	const int width = 16;
	for (int i = 0; i < amount; i++)
	{
		float factor = 4 * (1.0f - Maths::Abs((i - width / 2.0f) / (width / 2.0f)));
		Vec2f vel = thisVel * -0.1f * factor + getRandomVelocity(-thisVel.Angle(), 1 * factor, 4);
		vel *= 0.1f;
		Vec2f offset = Vec2f(0, -1).RotateByDegrees(-thisVel.Angle()) * ((i - width / 2.0f) * 0.5f);
		CParticle@ p = ParticlePixel(pos + offset, vel, SColor(255, 255, 225 + XORRandom(30), 50 + XORRandom(50)), true);
		if (p !is null)
		{
			p.timeout = (factor * 2) + XORRandom(3);
			p.damping = 0.85f + XORRandom(15) * 0.01f;
			p.fastcollision = true;
			p.collides = false;
			p.gravity = Vec2f_zero;
		}
	}
}

Random _sprk_r(21342);
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