#include "Hitters.as"

const f32 max_dist = 384.0f; // 48 blocks

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",900);
    this.set_s32("nextorb", getGameTime());
    this.Tag("counterable");
    this.set_u16("fire_delay", 120);

    this.Tag("exploding");
	this.set_f32("explosive_radius", 32.0f);
	this.set_f32("explosive_damage", 4.0f);
	this.set_f32("map_damage_radius", 15.0f);
	this.set_f32("map_damage_ratio", -1.0f);
    this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
	

    this.getSprite().PlaySound("WizardShoot.ogg", 2.0f, 0.75f);
    this.addCommandID("sync");
    if (isClient())
    {
        CBitStream params;
        params.write_bool(true);
        this.SendCommand(this.getCommandID("sync"), params);
    }

    CSprite@ thisSprite = this.getSprite();
    thisSprite.SetEmitSound("MolotovBurning.ogg");
    thisSprite.SetEmitSoundVolume(1.0f);
    thisSprite.SetEmitSoundSpeed(0.75f);
    thisSprite.SetEmitSoundPaused(false);
    thisSprite.SetZ(-10.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync"))
    {
        bool init = params.read_bool();
        if (init && isServer())
        {
            CBitStream stream;
            stream.write_bool(false);
            stream.write_u16(this.get_u16("fire_delay"));
        }
        else if (!init && isClient())
        {
            u16 val = params.read_u16();
            this.set_u16("fire_delay", val);
        }
    }
}

void onTick(CBlob@ this)
{
    if(this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }
    if (getGameTime()%5==0)sparks(this.getPosition()-Vec2f(0,22), 2, Vec2f_zero);

    if(getGameTime() >= this.get_s32("nextorb"))
    {
        f32 dist = 99999.0f;
        u16 id = 0;
        for (u8 i = 0; i < getPlayersCount(); i++)
        {
            if (getPlayer(i) is null || getPlayer(i).getBlob() is null) continue;
            CBlob@ b = getPlayer(i).getBlob();
            if (b.getTeamNum() != this.getTeamNum() && b.getDistanceTo(this) < max_dist
            && !getMap().rayCastSolidNoBlobs(b.getPosition(), this.getPosition()-Vec2f(0,20)))
            {
                if (b.getDistanceTo(this) < dist)
                {
                    dist = b.getDistanceTo(this);
                    id = b.getNetworkID();
                }
            }
        }

        CBlob@ b = getBlobByNetworkID(id);
        if (b !is null && id != 0)
        {
            if (isClient())
            {
                //this.getSprite().PlaySound("flame_slash_sound", 2.0f, 1.65f);
                //this.getSprite().PlaySound("MagicMissile.ogg", 0.5f, 1.0f + XORRandom(11)*0.01f);
            }
            if (isServer())
            {
                f32 orbspeed = 8.0f;
			    Vec2f orbPos = this.getPosition() - Vec2f(0.0f, 20.0f);
                f32 predict = (b.getPosition()-orbPos).Length()/16;

                Vec2f hitpos = Vec2f(0,0);
                Vec2f orbVel = (b.getPosition()+(b.getVelocity()*predict) - orbPos);

                if (this.getDistanceTo(b) < 48.0f)
                {
                    hitpos = b.getPosition();
                }
                else
                {
                    HitInfo@[] infos;
                    if (getMap().getHitInfosFromRay(b.getPosition(), -b.getVelocity().Angle(), b.getVelocity().Length()*predict, this, @infos))
                    {
                        for (u16 i = 0; i < infos.length; i++)
                        {
                            HitInfo@ info = infos[i];
                            if (info is null) continue;
                            if (info.blob is b) continue;
                            if (info.blob !is null && info.blob.getShape().getConsts().collidable && info.blob.doesCollideWithBlob(b))
                            {
                                hitpos = info.blob.getPosition();
                                break;
                            }
                            else if (info.blob is null && info.tileOffset != 0 && info.tileOffset <= getMap().tilemapwidth*getMap().tilemapheight)
                            {
                                hitpos = info.hitpos;
                                break;
                            }
                        }
                    }
                    if (hitpos.x != 0 || hitpos.y != 0)
                    {
                        orbVel = hitpos - Vec2f(0,12) - orbPos;
                    }
                }

			    orbVel.Normalize();
			    orbVel *= orbspeed;
			    CBlob@ orb = server_CreateBlob( "flameorb" );
			    if (orb !is null)
			    {
			    	orb.IgnoreCollisionWhileOverlapped( this );
			    	orb.SetDamageOwnerPlayer( this.getDamageOwnerPlayer() );
			    	orb.server_setTeamNum( this.getTeamNum() );
			    	orb.setPosition( orbPos );
			    	orb.setVelocity( orbVel );
			    }
            }
            this.set_s32("nextorb",getGameTime() + this.get_u16("fire_delay"));
        }
    }

}
void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

void onInit(CSprite@ this)
{
    this.getBlob().set_s32("frame",0);
}

void onTick(CSprite@ this)
{
    if(getGameTime() % 4 == 0)
        this.getBlob().add_s32("frame",1);
    this.SetFrame(this.getBlob().get_s32("frame")%6);
    this.SetOffset(Vec2f(0,-15));
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount, Vec2f gravity)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 255, 75+_sprk_r.NextRanged(125), _sprk_r.NextRanged(55)), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
		p.gravity = gravity+Vec2f(0.0f, 0.01f);
        p.timeout = 15 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}

void onDie(CBlob@ this)
{
	sparks(this.getPosition(), 15, Vec2f(0.0f, 0.1f));
    Boom(this);
}

void Boom( CBlob@ this )
{
	this.getSprite().PlaySound("FireBlast11.ogg", 0.8f, 2.0f + XORRandom(20)/10.0f);
	ExplodeWithFire(this);
	smoke(this.getPosition()-Vec2f(0,8), 5);	
	blast(this.getPosition()-Vec2f(0,8), 10);	
	
    this.server_Die();
}

void ExplodeWithFire(CBlob@ this)
{
    CMap@ map = getMap();
	Vec2f thisPos = this.getPosition();
    if (map is null)   return;
	
	CBlob@[] blobsInRadius;
	if (map.getBlobsInRadius(thisPos, 40.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is null)
			{
				Vec2f bPos = b.getPosition();
				if ( !map.rayCastSolid(thisPos-Vec2f(0,8), bPos) )
				{
					if(b.get_u16("fireProt") > 0)
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.25f, Hitters::explosion, false);
					}
					else
					{
						this.server_Hit(b, bPos, bPos-thisPos, 0.25f, Hitters::fire, false);
					}
				}
			}
		}
	}
	
    this.getSprite().PlaySound("MolotovExplosion.ogg", 1.2f, 1.2f);
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