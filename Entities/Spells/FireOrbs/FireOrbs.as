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
    this.server_SetTimeToDie(60);

	this.set_f32("explosive_radius",48.0f);
	this.set_f32("explosive_damage",15.0f);
	this.set_string("custom_explosion_sound", "FireBlast8.ogg");
	this.set_f32("map_damage_radius", 0.0f);
	this.set_f32("map_damage_ratio", 0.0f);
	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", false);
    this.Tag("exploding");

    this.SetLight( true );
	this.SetLightRadius( 32.0f );
	this.getSprite().SetAnimation("default");
	this.getSprite().ScaleBy(Vec2f(0.75f, 0.75f));

	this.getSprite().PlaySound("FireBlast4.ogg", 1.0f, 2.5f + (XORRandom(10)/10.0f));
}	

void onTick( CBlob@ this )
{     
	CBlob@ shooter = getBlobByNetworkID(this.get_u16("shooter"));
	if (shooter is null)
	{
		this.Sync("shooter", true);
		@shooter = getBlobByNetworkID(this.get_u16("shooter"));
	}
	if (shooter is null)
	{
		if (isServer()) this.server_Die();
		return;
	}
	if (shooter.getPlayer() is null) return;
	this.Tag(""+shooter.getPlayer().getUsername());

	if (getMap() !is null && this.getPosition().y/8 >= getMap().tilemapheight-2)
	{
		this.setVelocity(Vec2f(this.getVelocity().x, 0));
		this.AddForce(Vec2f(0, -100));
	}

	bool has_target = false;

	Vec2f pos = this.getPosition();
	Vec2f tpos = shooter.getPosition();

	CBlob@[] orbs;
	u16[] orbs_id;
	getBlobsByTag(shooter.getPlayer().getUsername(), @orbs);
	u16 orb_count = orbs.length; 
	
	if (getGameTime() % 3 == 0)
	{
		for (u16 i = 0; i < orb_count; i++)
		{
			if (orbs[i] is null) continue;
			orbs_id.push_back(orbs[i].getNetworkID());
		}
		for (u16 i = 0; i < orb_count; i++)
		{
			for (u16 j = 0; j < orb_count; j++)
			{
				if (orbs_id[i] < orbs_id[j])
				{
					u16 temp = orbs_id[i];
					orbs_id[i] = orbs_id[j];
					orbs_id[j] = temp;
				}
			}
		}
		for (u16 i = 0; i < orb_count; i++)
		{
			if (this.getNetworkID() == orbs_id[i]) this.set_u16("orb_pos", i);
		}

		f32 dist = 99999.0f;
		for (u8 i = 0; i < getPlayersCount(); i++)
		{
			if (getPlayer(i) !is null && getPlayer(i).getBlob() !is null)
			{
				CBlob@ temp_target = getPlayer(i).getBlob();
				if (temp_target.getTeamNum() == this.getTeamNum() || temp_target.hasTag("dead") || this.getDistanceTo(temp_target) > 128.0f)
				{
					continue;
				}
				{
					f32 temp_dist = this.getDistanceTo(temp_target);
					if (temp_dist < dist)
					{
						dist = temp_dist;
						this.set_u16("tnetid", temp_target.getNetworkID());
					}	
				}
			}
		}
	}
	u16 netid = this.get_u16("tnetid");
	u16 orb_pos = this.get_u16("orb_pos");

	CBlob@ target = getBlobByNetworkID(netid);
	if (target !is null)
	{
		Vec2f move_to = target.getPosition();
		Vec2f vel = move_to-pos;

		this.AddForce(vel/2.5f);
		if (vel.Length() <= 1.0f) Boom( this );
	}
	else
	{
		Vec2f offset;
		u8 row_pos = orb_pos%3;
		switch (row_pos)
		{
			case 0:
			{
				offset = Vec2f(0.0f,-32.0f);
				break;
			}
			case 1:
			{
				offset = Vec2f(-16.0f,-24.0f);
				break;
			}
			case 2:
			{
				offset = Vec2f(16.0f,-24.0f);
				break;
			}
		}

		Vec2f move_to = tpos+Vec2f(offset.x,offset.y-Maths::Floor((8*orb_pos)/3)).RotateBy(Maths::Sin(getGameTime() / 15.0f) * 15.0f, Vec2f(0.0f, -offset.y+Maths::Floor((8*orb_pos)/3)));

		Vec2f vel = move_to-pos;
		//this.setVelocity(vel*(0.05f));
		this.setPosition(move_to);
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		target != null
		&& target.hasTag("counterable") //all counterables
		&& !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() //as long as they're on the enemy side
		&& !target.hasTag("black hole")  //as long as it's not a black hole, go as normal.
	);
}	

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return false;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if(blob is null || this is null){return;}

	if((blob.hasTag("flesh") || blob.hasTag("barrier")) && blob.getTeamNum() != this.getTeamNum())
	{
		if ( isClient() )
		{
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
		}
		Boom(this);
		this.server_Die();
	} 
}

void ExplodeWithFire(CBlob@ this)
{
    CMap@ map = getMap();
	Vec2f thisPos = this.getPosition();
    if (map is null)   return;
    for (int doFire = 0; doFire <= 2 * 8; doFire += 1 * 8) //8 - tile size in pixels
    {
        map.server_setFireWorldspace(Vec2f(thisPos.x, thisPos.y + doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x, thisPos.y - doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x + doFire, thisPos.y), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x - doFire, thisPos.y), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x + doFire, thisPos.y + doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x - doFire, thisPos.y - doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x + doFire, thisPos.y - doFire), true);
        map.server_setFireWorldspace(Vec2f(thisPos.x - doFire, thisPos.y + doFire), true);
    }
	
	CBlob@[] blobsInRadius;
	if (map.getBlobsInRadius(thisPos, 32.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is null)
			{
				Vec2f bPos = b.getPosition();
				{
					f32 damage = this.get_f32("damage");
					if(b.get_u16("fireProt") > 0)
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.0f, Hitters::fire, false);
					}
					else
					{
						this.server_Hit(b, bPos, bPos-thisPos, damage, XORRandom(3) == 0 ? Hitters::fire : Hitters::fire, false);
					}
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	death(this.getPosition());
}

Random _death_r(0x10003);
void death(Vec2f pos)
{
	if (!getNet().isClient())
		return;

    Vec2f vel = Vec2f_zero;

    CParticle@ p = ParticleAnimated(CFileMatcher("Implosion1.png").getFirst(), 
								pos, 
								vel, 
								0, 
								0.5f, 
								2, 
								0.0f, 
								false);
								
    if(p is null) return; //bail if we stop getting particles

    p.fastcollision = true;
    p.damping = 0.85f;
	p.Z = 50.0f;
	p.lighting = true;
    p.setRenderStyle(RenderStyle::additive);
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

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(6.0f + _smoke_r.NextFloat() * 6.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
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

void Boom( CBlob@ this )
{
	this.getSprite().PlaySound("FireBlast11.ogg", 0.8f, 2.0f + XORRandom(20)/10.0f);
	this.getSprite().PlaySound("FireBlast4.ogg", 0.8f, 1.0f + XORRandom(20)/10.0f);
	ExplodeWithFire(this);
	smoke(this.getPosition(), 5);	
	blast(this.getPosition(), 10);	
	
    this.server_Die();
}