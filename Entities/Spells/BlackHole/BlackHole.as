#include "Hitters.as";
#include "MagicCommon.as";
#include "CommonFX.as";

const f32 PULL_RADIUS = 192.0f;
const f32 MAX_FORCE = 100.0f;
const int LIFETIME = 16;

const int PARTICLE_TICKS = 6;
const f32 max_mod = 2.0f;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(LIFETIME+1);
	this.getShape().SetGravityScale(0.0);
	this.Tag("counterable");
	this.Tag("black hole");
	
	if( !CustomEmitEffectExists( "blackHoleEmit" ) )
	{
		SetupCustomEmitEffect( "blackHoleEmit", "BlackHole.as", "updateBlackHoleParticle", 10, 0, 120 );
		//SetupCustomEmitEffect( STRING name, STRING scriptfile, STRING scriptfunction, u8 hard_freq, u8 chance_freq, u16 timeout )
	}

	this.Tag("no trampoline collision");
	this.set_f32("mod", 1.0f);
	this.set_f32("old_mod", 1.0f);
	this.set_f32("base_mass", 500.0f);
}

void onInit(CSprite@ this)
{
	this.setRenderStyle(RenderStyle::subtractive);
	this.SetZ(-10.0f);
	this.SetEmitSound( "EnergyLoop1.ogg" );
	this.SetEmitSoundPaused( false );
	this.ScaleBy(Vec2f(0.5f, 0.5f));
}

void onTick(CSprite@ this)
{
	this.RotateBy(8.0, Vec2f_zero);
}

void onTick(CBlob@ this)
{
	Vec2f thisPos = this.getPosition();
	if (isServer())
	{
		this.Sync("mod", true);
		this.Sync("old_mod", true);
		this.Sync("base_mass", true);
		
		if (this.hasTag("extra_damage") && this.getTickSinceCreated() < 15)
		{
			this.Sync("extra_damage", true);
			this.set_f32("base_mass", this.getMass());
		}
	}

	CMap@ map = getMap();
	if (map is null)
		return;
	
	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("BlackHoleMake.ogg", 1.0f, 1.0f);	
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
		if (attractedblob is null || attractedblob is this)
			continue;

		Vec2f blobPos = attractedblob.getPosition();
		if (map.rayCastSolidNoBlobs(thisPos, blobPos)
			&& !(attractedblob.getName() == "force_of_nature" && attractedblob.hasTag("extra_damage")))
			continue;
		
		if ( ((attractedblob.getTeamNum() != this.getTeamNum() || attractedblob.hasTag("magic_circle")) && !attractedblob.hasTag("dead"))
		|| (attractedblob.hasTag("black hole")) )
		{
			Vec2f pullVec = thisPos - blobPos;
			Vec2f pullNorm = pullVec;
			pullNorm.Normalize();
			
			Vec2f forceVec = pullNorm*MAX_FORCE*mod;
			Vec2f finalForce = forceVec*(1.0f-pullVec.Length()/rad);

			f32 mass_factor = Maths::Clamp(attractedblob.getMass() / 80, 0.25f, 1.0f);
			finalForce *= mass_factor;

			if (!attractedblob.hasTag("cantmove"))
				attractedblob.AddForce(finalForce);

			if (attractedblob.getName() == "black_hole")
			{
				if (attractedblob.getDistanceTo(this) > 40.0f)
					attractedblob.set_u32("blackhole_force", getGameTime());

				if (this.isOverlapping(attractedblob)) onCollision(this, attractedblob, false);
				attractedblob.server_SetTimeToDie(Maths::Max(1.0f, attractedblob.getTimeToDie()));
			}
			
			ManaInfo@ manaInfo;
			if (attractedblob.get("manaInfo", @manaInfo) && (getGameTime() % 24 == 0))
			{
				s32 MANA_DRAIN = attractedblob.get_s32("mana regen rate") - 1;

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
					manaInfo.mana = 0;
				}
			}
		}
	}
	
	if ( this.getTickSinceCreated() > LIFETIME*30 + 15 )
	this.Tag("dead");
	
	if ( isClient() && getGameTime() % PARTICLE_TICKS == 0 )
	makeBlackHoleParticle( thisPos, Vec2f(0,0) );
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
		this.Tag("mark_for_death");
		blob.Tag("mark_for_death");

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

void updateBlackHoleParticle( CParticle@ p )
{
	if ( !getNet().isClient() )
	return;

	if(p is null)
	return;

	CBlob@[] blackHoles;
	if (getBlobsByName("black_hole", @blackHoles))
	{
		f32 extRadius = PULL_RADIUS*2;
	
		f32 best_dist = 99999999;
		for (uint step = 0; step < blackHoles.length; ++step)
		{
			CBlob@ bHole = blackHoles[step];
			if ( bHole is null )
				continue;
				
			Vec2f bPos = bHole.getPosition();
			Vec2f pPos = p.position;
			Vec2f forceVec = bPos - pPos;
			
			f32 dist = forceVec.getLength();
			if (dist == 0.0f) dist += 1.0f;
			if (dist < best_dist)
			{
				best_dist=dist;
				
				Vec2f forceNorm = forceVec;
				forceNorm.Normalize();
				p.gravity = forceNorm*(Maths::Pow(2.0f/dist+1, 2));
				
				Vec2f pVelNorm = p.velocity;
				pVelNorm.Normalize();
				p.rotation = -pVelNorm;
				//p.velocity *= 0.5f;
			}
			
			if (dist < 16.0f || (bHole !is null && bHole.hasTag("dead")) )
			{
				p.frame = 7;
				sparks(p.position, 2);
			}
		}
	}
	else
	p.frame = 7;
}

Random _sprk_r(1337);
void makeBlackHoleParticle( Vec2f pos, Vec2f vel )
{
	if ( !getNet().isClient() )
		return;

	u8 emitEffect = GetCustomEmitEffectID( "blackHoleEmit" );
	
	const f32 rad = 16.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	//Vec2f newPos = pos + random;
	Vec2f newPos = pos + Vec2f(rad,0).RotateBy(_sprk_r.NextRanged(360));
	Vec2f dirVec = newPos - pos;
	Vec2f dirNorm = dirVec;
	dirNorm.Normalize();
	Vec2f newVel = vel + dirNorm.RotateBy(60.0f)*12.0f;
	
	//CParticle@ p = ParticlePixelUnlimited( newPos, newVel, SColor( 255, 0, 0, 0), true );
	CParticle@ p = ParticleAnimated( "BlackStreak1.png", newPos, newVel, -newVel.getAngleDegrees(), 1.0f, 20, 0.0f, true );
	if(p !is null)
	{
		p.Z = 500.0f;
		p.bounce = 0.1f;
    	p.fastcollision = true;
		p.gravity = Vec2f(0,0);
		p.emiteffect = emitEffect;
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
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
									
        if(p is null) continue; //bail if we stop getting particles
		
        p.scale = 0.5f + _blast_r.NextFloat()*0.5f;
        p.damping = 0.9f;
    	p.fastcollision = true;
		p.Z = 200.0f;
		p.lighting = false;
    }
}

void sparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 0.5f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);
		
		int colorShade = _sprk_r.NextRanged(128);
        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, colorShade, colorShade, colorShade), true );
        if(p is null) continue; //bail if we stop getting particles
    	p.fastcollision = true;
        p.timeout = 40 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
		p.gravity = Vec2f(0,0);
    }
}

void onDie(CBlob@ this)
{
	blast(this.getPosition(), 20);
	this.getSprite().PlaySound("BlackHoleDie.ogg", 1.0f, 1.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return false;
}