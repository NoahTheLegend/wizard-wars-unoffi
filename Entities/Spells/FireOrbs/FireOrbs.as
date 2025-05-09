#include "Hitters.as";
#include "MakeDustParticle.as";
#include "SpellHashDecoder.as";

const f32 distance = 54.0f;
const f32 distance_fluctuation = 16.0f;
const f32 rot_speed_base = 6;
const f32 rot_speed_fluctuation = 1;

void onInit( CBlob@ this )
{
	this.Tag("counterable");
	this.set_bool("launch", false);

	this.set_Vec2f("caster", Vec2f_zero);
	this.set_Vec2f("target", Vec2f_zero);
	this.set_s8("lifepoints", 10);
	this.Tag("kill water spells");
	this.Tag("fire spell");
	this.Tag("die_in_divine_shield");

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

	this.SetMapEdgeFlags(CBlob::map_collide_none | CBlob::map_collide_nodeath);

    this.SetLight( true );
	this.SetLightRadius( 32.0f );
	this.getSprite().SetAnimation("default");
	this.getSprite().ScaleBy(Vec2f(0.75f, 0.75f));

	this.getSprite().PlaySound("FireBlast4.ogg", 1.0f, 2.5f + (XORRandom(10)/10.0f));
}	

void onTick(CBlob@ this)
{     
	CBlob@ shooter = getBlobByNetworkID(this.get_u16("shooter"));
	if (shooter is null)
	{
		this.Sync("shooter", true);
		@shooter = getBlobByNetworkID(this.get_u16("shooter"));
	}
	if (shooter is null)
	{
		if (isServer()) this.Tag("mark_for_death");
		return;
	}

	if (shooter.getTeamNum() != this.getTeamNum())
	{
		CPlayer@ p = this.getDamageOwnerPlayer();
		if (p !is null)
		{
			CBlob@ pb = p.getBlob();
			if (pb !is null && pb.getTeamNum() != this.getTeamNum())
			{
				@shooter = pb;
				this.set_u16("shooter", pb.getNetworkID());
				// known issue kept as a feature - bypassing orbs limit
			}
		}
	}
	
	if (shooter.getPlayer() is null)
	{
		if (XORRandom(100) == 0) this.Tag("mark_for_death");
		return;
	}
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
	}

	u16 orb_pos = this.get_u16("orb_pos");
	s8 face = this.getTeamNum() == 1 ? -1 : 1;
	f32 rot_speed = shooter.hasTag("extra_damage") ? rot_speed_base * 1.25f : rot_speed_base; 
	Vec2f target_radius_pos = tpos + Vec2f(0, -distance - Maths::Sin(getGameTime() / distance_fluctuation) * (distance_fluctuation + XORRandom(rot_speed_fluctuation * 10) * 0.1f)).RotateBy(face * ((shooter.getTickSinceCreated() * rot_speed) % 360 + 360/orb_count * orb_pos));

	Vec2f vel = target_radius_pos-pos;
	this.setVelocity(vel/4);

	if (isClient())
	{
		//sinusoidal ray of particles
		u8 pc = v_fastrender ? 5 : 15;
		for (u8 i = 0; i < pc; i++)
		{
			f32 t = float(i) / pc;
			Vec2f pPos = shooter.getPosition() * (1.0f - t) + this.getPosition() * t;

			Vec2f direction = (this.getPosition() - shooter.getPosition());
			direction.Normalize();
			Vec2f perpendicular = Vec2f(-direction.y, direction.x);
			f32 sideOffset = Maths::Sin(t * Maths::Pi * 1.0f) * 12.0f * face;
			Vec2f sideAdjustment = perpendicular * sideOffset;

			Vec2f pVel = (this.getPosition() - pPos) * 0.1f;
			pPos += sideAdjustment;

			u8 alpha = u8(t * 255.0f);
			CParticle@ p = ParticlePixelUnlimited(pPos, pVel, SColor(alpha, 180 + XORRandom(40), 180 + XORRandom(50), XORRandom(175)), true);
			if (p is null) return;

			p.collides = false;
			p.fastcollision = true;
			p.bounce = 0.0f;
			p.timeout = 1 + 10 * Maths::Pow(f32(i) / f32(pc), 2.5f);
			p.damping = 0.95;
			p.gravity = Vec2f(0, 0);
			p.Z = -50.0f;
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	return 
	(
		(target !is null && target.getTeamNum() != this.getTeamNum() && (target.hasTag("barrier") || target.hasTag("flesh")))
		||
		(target !is null
		&& target.hasTag("flesh")
		&& !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum())
	);
}	

bool doesCollideWithBlob(CBlob@ this, CBlob@ b)
{
	return isEnemy(this, b);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null || this is null) {return;}
	if (this.getTickSinceCreated() < 30) {return;}

	if (isEnemy(this, blob))
	{
		if (isClient())
		{
			Vec2f dispelPos = this.getPosition();
			CParticle@ p = ParticleAnimated( "Flash2.png",
					dispelPos,
					Vec2f(0,0),
					0,
					0.25f, 
					8, 
					0.0f, true); 	
									
			if (p !is null)
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
	} 
}

void ExplodeWithFire(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	
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
			CBlob@ b = blobsInRadius[i];
			if (b !is null && isEnemy(this, b))
			{
				Vec2f bPos = b.getPosition();
				{
					f32 damage = this.get_f32("damage");
					if (b.get_u16("fireProt") > 0)
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.0f, Hitters::explosion, false);
					}
					else
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.0f, Hitters::fire, false);
						this.server_Hit(b, bPos, bPos-thisPos, damage, Hitters::explosion, false);
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
	CBlob@ owner = getBlobByNetworkID(this.get_u16("shooter"));
	if (owner !is null && this.getDistanceTo(owner) >= distance * 2)
	{
		return;
	}

	this.getSprite().PlaySound("FireBlast11.ogg", 0.8f, 2.0f + XORRandom(20)/10.0f);
	this.getSprite().PlaySound("FireBlast4.ogg", 0.8f, 1.0f + XORRandom(20)/10.0f);
	ExplodeWithFire(this);
	smoke(this.getPosition(), 5);	
	blast(this.getPosition(), 10);	
	
    this.Tag("mark_for_death");
}