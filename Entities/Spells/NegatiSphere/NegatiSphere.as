#include "Hitters.as";
#include "MakeDustParticle.as";
#include "SpellHashDecoder.as";

void onInit( CBlob@ this )
{
	this.Tag("counterable");
	this.set_bool("launch", false);

	this.set_Vec2f("caster", Vec2f_zero);
	this.set_Vec2f("target", Vec2f_zero);
	this.set_s8("lifepoints", 10);

    this.getShape().SetGravityScale( 0.0f );
	this.getShape().getConsts().mapCollisions = false;
	this.getSprite().SetZ(1450);// draw over ground
    this.server_SetTimeToDie(180);

    this.SetLight( true );
	this.SetLightRadius( 32.0f );
}	

void onTick( CBlob@ this )
{     
	if(this.getCurrentScript().tickFrequency == 1)
	{
		if(isClient())
		this.getSprite().PlaySound("SpriteFire1.ogg", 0.2f, 1.5f + XORRandom(10)/10.0f);
		// done post init
		this.getCurrentScript().tickFrequency = 2;
	}

	if ((getGameTime()+Maths::Pow(this.getNetworkID(), 2)) % 60 == 0
		&& !this.get_bool("launch"))
		this.AddForce(Vec2f(this.getMass(), 0).RotateBy(XORRandom(360)));

	if(!this.get_bool("launch"))
	{
		CPlayer@ p = this.getDamageOwnerPlayer();
		if( p !is null)	{
			CBlob@ b = p.getBlob();
			if( b !is null)	
			{
				if(b.get_bool("shifting"))
				{
					if(!b.get_bool("shiftCooldown"))
					{
						b.set_bool("shiftCooldown", true);
						this.set_Vec2f("target", b.getAimPos());
						this.set_bool("launch", true);
					}
				}
				else
				{
					if(b.get_bool("shiftCooldown"))
					b.set_bool("shiftCooldown", false);
					this.set_Vec2f("target", b.getPosition());
				}
			}
			else
			{
				this.server_Die();
			}
		}
	}
	
	if(this.get_bool("launch") && !this.hasTag("cruiseMode"))
	{
		Vec2f dir = this.get_Vec2f("target")-this.getPosition();
		dir.Normalize();
		this.setVelocity(Vec2f_zero);
		this.set_Vec2f("dir", dir);
		this.Tag("cruiseMode");
		this.server_SetTimeToDie(5);
	}

	if(!this.get_bool("launch"))
	{
		Vec2f dir = this.get_Vec2f("target")-this.getPosition();
		dir.RotateBy(15 + XORRandom(6));
		dir.Normalize();
		this.set_Vec2f("dir", dir);
	}

	Vec2f vel = this.getVelocity();
	Vec2f finaldir = this.get_Vec2f("dir");
	float dirmult = this.hasTag("cruiseMode") ? 1.5f : 0.75f;
	vel += finaldir * dirmult;
	this.setVelocity(vel);

}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		target != null
		&& (target.hasTag("counterable") || target.hasTag("totem")) //all counterables
		&& !target.hasTag("dead")
		&& target.getTeamNum() != this.getTeamNum() //as long as they're on the enemy side
		&& !target.hasTag("black hole")  //as long as it's not a black hole, go as normal.
		&& !target.hasTag("follower")
		&& !target.hasTag("magic_circle")
	);
}	

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return false;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if(blob is null || this is null){return;}
	if (this.getSprite() is null) return;

	if( isEnemy( this , blob ) ) //will not affect same team negatispheres
	{
		if ( isClient() ) //temporary Counterspell effect
		{
			this.getSprite().PlaySound("SpriteFire3.ogg", 0.5f, 0.75f + XORRandom(10)/20.0f);
			Vec2f dispelPos = this.getPosition();
			CParticle@ p = ParticleAnimated( "Flash2.png",
					dispelPos,
					Vec2f(0,0),
					0,
					0.25f, 
					8, 
					0.0f, true ); 	
									
			if ( p !is null)
			{
				p.bounce = 0;
   				p.fastcollision = true;
				p.Z = 600.0f;
			}
			CParticle@ pb = ParticleAnimated( "Shockwave2.png",
					dispelPos,
					Vec2f(0,0),
					float(XORRandom(360)),
					0.25f, 
					2, 
					0.0f, true );    
			if ( pb !is null)
			{
				pb.bounce = 0;
   				pb.fastcollision = true;
				pb.Z = -10.0f;
			}
			this.getSprite().PlaySound("CounterSpell.ogg", 0.8f, 1.0f);
		}

		if(blob.getName() == this.getName())
		{
			this.server_Die();
		}
		else
		{
			decreaseNegatisphereLife( this , blob );
			if(blob.hasTag("exploding"))
			{
				blob.Untag("exploding");
			}

			blob.server_Die();

			if (this.get_s8("lifepoints") <= 0)
			{
				this.server_Die();
			}
		}
	} 
}