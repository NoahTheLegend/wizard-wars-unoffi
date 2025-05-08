
#include "Hitters2.as";
#include "TeamColour.as";
#include "MakeDustParticle.as";

void onInit( CBlob@ this )
{
	this.getShape().SetGravityScale( 0.0f );
	this.server_SetTimeToDie(15);
	this.Tag("fire bolt");

    this.set_u8("custom_hitter", Hitters2::orb);
	this.Tag("exploding");
	
	this.Tag("kill other spells");
	this.Tag("counterable");
	
	this.set_f32("explosive_radius", 20.0f );
	this.set_f32("explosive_damage", 3.0f);
	this.set_f32("map_damage_radius", 15.0f);
	this.set_f32("map_damage_ratio", -1.0f); //heck no!
	this.set_u32("last smoke puff", 0 );

	this.addCommandID("aimpos sync");
}

void onTick( CBlob@ this )
{
	if(this.getCurrentScript().tickFrequency == 1)
	{
		this.SetLight( true );
		this.SetLightRadius( 32.0f );
		this.SetLightColor( getTeamColor(this.getTeamNum()) );
		this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
		this.getSprite().PlaySound("SpriteFire1.ogg", 0.2f, 1.5f + XORRandom(10)/10.0f);
		this.getSprite().SetZ(1000.0f);

		CBrain@ brain = this.getBrain();
		if (brain != null)
		{
			if (!brain.isActive())
			{
				//print ("activating brain");
				brain.server_SetActive(true);
			}
			else
			{
				//print ("brain was somehow already active");
			}
		}
		
		//makes a stupid annoying sound
		//ParticleZombieLightning( this.getPosition() );
		
		// done post init
		this.getCurrentScript().tickFrequency = 3;
	}
	
	const u32 gametime = getGameTime();
	u32 lastSmokeTime = this.get_u32("last smoke puff");
	int ticksTillSmoke = 2;
	int diff = gametime - (lastSmokeTime + ticksTillSmoke);
	if (diff > 0)
	{
		MakeParticle( this.getPosition(),
							"SmallSmoke1.png", 50.0 );
	
		lastSmokeTime = gametime;
		this.set_u32("last smoke puff", lastSmokeTime);
	}
	
	
	Vec2f target;
	bool targetSet;
	bool brake;
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		( target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door") || target.getName() == "trap_block") || target.hasTag("barrier") )
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}	

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
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
	
	return (
		isEnemy(this, blob) 
		|| blob.hasTag("door") 
		|| (blob.getPlayer() !is null 
			&& this.getDamageOwnerPlayer() !is null
			&& blob.getPlayer() is this.getDamageOwnerPlayer()
		|| blob.getName() == this.getName()
		)
	); 
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (solid || blob.hasTag("kill other spells"))
	{
		this.getSprite().PlaySound("SpriteFire3.ogg", 0.05f, 0.5f + XORRandom(10)/20.0f);
		if(blob !is null && (isEnemy(this, blob) || blob.hasTag("barrier")) )
		{
			this.Tag("mark_for_death");
		} 
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("aimpos sync"))
    {
        this.set_Vec2f("aimpos", params.read_Vec2f());
    }
}