#include "Hitters.as";
#include "MagicCommon.as";
#include "CommonFX.as";

// this blob is made with power of 2 other blobs
const f32 PULL_RADIUS = 256.0f/2;
const f32 MAX_FORCE = 128.0f/2;
const int LIFETIME = 20;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(LIFETIME);
	this.getShape().SetGravityScale(0.0);
	this.Tag("black hole");
	this.Tag("multi_despell");
	this.set_u8("despelled", 0);
	
	this.server_setTeamNum(-1);
	this.set_f32("mod", 1.0f);
	this.set_f32("old_mod", 1.0f);
	this.set_f32("base_mass", 500.0f);
}

void onInit(CSprite@ this)
{
	this.setRenderStyle(RenderStyle::subtractive);
	this.SetZ(-10.0f);
	this.SetEmitSound( "EnergyLoop1.ogg" );
	this.SetEmitSoundSpeed(0.5f);
	this.SetEmitSoundPaused( false );
}

void onTick(CSprite@ this)
{
	this.RotateBy(8.0, Vec2f_zero);
}

void onTick(CBlob@ this)
{
	if (isServer() && this.hasTag("extra_damage") && this.getTickSinceCreated() < 1)
	{
		this.Sync("extra_damage", true);
		this.set_f32("base_mass", this.getMass());
	}

	if(this.get_u8("despelled") >= 2)
    {
        this.server_Die();
    }
	Vec2f thisPos = this.getPosition();

	CMap@ map = getMap();
	if (map is null)
	return;

	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("BlackHoleMake.ogg", 1.0f, 0.5f);	
	}

	f32 mod = this.get_f32("mod");
	if (this.exists("mod")) mod = this.get_f32("mod");

	f32 old_mod = this.get_f32("old_mod");
	this.SetMass(this.get_f32("base_mass"));
	if (isClient()) this.getSprite().ScaleBy(Vec2f(1.0f / old_mod, 1.0f / old_mod));

	if (this.hasTag("extra_damage"))
	{
		mod = mod + (this.getTickSinceCreated() * 0.0025f);
		this.SetMass(this.getMass() * mod);
	}
	
	this.set_f32("old_mod", mod);

	if (this.get_u32("blackhole_force") + 5 > getGameTime())
		this.getShape().setDrag(0.33f);
	else
		this.getShape().setDrag(1.0f);

	if (isClient()) this.getSprite().ScaleBy(Vec2f(mod, mod));

	f32 rad = mod * PULL_RADIUS;
	CBlob@[] attracted;
	map.getBlobsInRadius( thisPos, rad, @attracted );
	
	for (uint i = 0; i < attracted.size(); i++)
	{
		CBlob@ attractedblob = attracted[i];
		if (attractedblob is null)
		continue;

		Vec2f blobPos = attractedblob.getPosition();
		
		if ( !attractedblob.hasTag("dead") )
		{
			Vec2f pullVec = thisPos - blobPos;
			Vec2f pullNorm = pullVec;
			pullNorm.Normalize();
			
			Vec2f forceVec = pullNorm*MAX_FORCE*mod;
			Vec2f finalForce = forceVec*(1.0f-pullVec.Length()/rad);

			if (!attractedblob.hasTag("cantmove"))
				attractedblob.AddForce(finalForce);

			if (attractedblob.getName() == "black_hole")
			{
				if (attractedblob.getDistanceTo(this) > 24.0f)
					attractedblob.set_u32("blackhole_force", getGameTime());
				else onCollision(this, attractedblob, false);
				attractedblob.server_SetTimeToDie(Maths::Max(1.0f, attractedblob.getTimeToDie()));
			}
			
			ManaInfo@ manaInfo;
			if ( (getGameTime() % 24 == 0) && attractedblob.get("manaInfo", @manaInfo) && !map.rayCastSolidNoBlobs(thisPos, blobPos) )
			{
				s32 MANA_DRAIN = attractedblob.get_s32("mana regen rate") + 1;

				/*if (attractedblob.getName() == "entropist")
				{
					if(manaInfo.mana > 2)
					{
						manaInfo.mana -= 2;
					}
					else
					{
						manaInfo.mana = 0;
					}
				}
				else*/

				if (MANA_DRAIN < 1) //normalizer
				{
					MANA_DRAIN = 1;
				}

				if (manaInfo.mana > MANA_DRAIN)
				{
					manaInfo.mana -= MANA_DRAIN;
					
					attractedblob.getSprite().PlaySound("ManaDraining.ogg", 0.5f, 1.0f + XORRandom(2)/10.0f);
					makeManaDrainParticles( blobPos, 30 );
				}
				else
				{
					manaInfo.mana = 0.0;
				}
			}
		}
	}
	
	if ( this.getTickSinceCreated() > LIFETIME*getTicksASecond() - 15 )
	this.Tag("dead");
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
	if(this is null || blob is null)
	return;

	if(this.hasTag("dead") || blob.hasTag("dead"))
	return;

	if ( blob.hasTag("black hole") ) //combine with other black holes
	{
		Vec2f thisPos = this.getPosition();
		this.Tag("dead");
		blob.Tag("dead");
		this.server_Die();
		blob.server_Die();

		CBlob@ b = server_CreateBlob( "black_hole_big", -1, thisPos ); // moved down here so we dont accidently make a blob before killing the last 2
		if (b !is null)
		{
			b.SetMass(this.getMass() + blob.getMass());
			b.set_f32("mod", this.get_f32("old_mod") + blob.get_f32("old_mod"));
			b.Sync("mod", true);

			if (this.hasTag("extra_damage") || blob.hasTag("extra_damage"))
			{
				b.Tag("extra_damage");
				b.Sync("extra_damage", true);
			}
		}
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 14.0f, 0);
        vel.RotateBy(_blast_r.NextFloat() * 360.0f);
		Vec2f velNorm = vel;
		velNorm.Normalize();

        CParticle@ p = ParticleAnimated( "BlackStreak2.png", 
									pos, 
									vel, 
									-velNorm.Angle(), 
									1.0f, 
									2 + XORRandom(4), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles
		
        p.scale = 1.0f + _blast_r.NextFloat()*1.0f;
        p.damping = 0.9f;
    	p.fastcollision = true;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

Random _sprk_r(2354);
void sparks(Vec2f pos, int amount)
{
	if ( !isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 0.5f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);
		
		int colorShade = _sprk_r.NextRanged(128);
        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, colorShade, colorShade, colorShade), true );
        if(p is null) return; //bail if we stop getting particles

        p.timeout = 40 + _sprk_r.NextRanged(20);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    	p.fastcollision = true;
		p.gravity = Vec2f(0,0);
    }
}

void onDie(CBlob@ this)
{
	blast(this.getPosition(), 20);
	this.getSprite().PlaySound("BlackHoleDie.ogg", 1.0f, 0.5f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return false;
}