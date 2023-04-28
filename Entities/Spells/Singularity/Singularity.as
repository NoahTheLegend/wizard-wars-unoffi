#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";

const int pierce_amount = 8;

const f32 hit_amount_ground = 0.2f;
const f32 hit_amount_air = 3.0f;
const f32 hit_amount_cata = 10.0f;

void onInit( CBlob @ this )
{
	this.Tag("projectile");
	this.Tag("invincible");
	this.Tag("magic_circle");

    this.set_u8("launch team",255);
    //this.server_setTeamNum(1);
	this.Tag("medium weight");
    
    LimitedAttack_setup(this);
    
    this.set_u8( "blocks_pierced", 0 );
    u32[] tileOffsets;
    this.set( "tileOffsets", tileOffsets );

	this.server_SetTimeToDie(60.0f);
    
    // damage
    this.set_f32("hit dmg modifier", hit_amount_ground);
	this.set_f32("map dmg modifier", 0.0f); //handled in this script
	this.set_u8("hurtoncollide hitter", Hitters::boulder);

	this.getShape().SetRotationsAllowed(true);
	this.getShape().SetGravityScale( 0.0f );
	this.getShape().getVars().waterDragScale = 8.0f;
	this.getShape().getConsts().collideWhenAttached = true;
	
	this.set_f32("explosive_radius",352.0f);
	this.set_f32("explosive_damage",20.0f);
	this.set_string("custom_explosion_sound", "FireBlast8.ogg");
	this.set_f32("map_damage_radius", 156.0f);
	this.set_f32("map_damage_ratio", 0.3f);
	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", true);
    this.Tag("exploding");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		Animation@ animdef = sprite.addAnimation("default", 0, false);
		if (animdef !is null)
		{
			animdef.AddFrame(4);
			sprite.SetFrameIndex(0);
			sprite.SetAnimation(animdef);
			sprite.ScaleBy(Vec2f(0.25f,0.25f));
		}
		CSpriteLayer@ spin1 = sprite.addSpriteLayer("spin1", "Singularity.png", 64, 64);
		if (spin1 !is null)
		{
			spin1.SetVisible(true);
			Animation@ anim = spin1.addAnimation("default", 0, false);
			if (anim !is null)
			{
				anim.AddFrame(5);
				spin1.SetFrameIndex(0);
				spin1.SetAnimation(anim);
				spin1.SetRelativeZ(-99.95f);
				spin1.ScaleBy(Vec2f(0.25f,0.25f));
			}
		}
		CSpriteLayer@ spin2 = sprite.addSpriteLayer("spin2", "Singularity.png", 64, 64); 
		if (spin2 !is null)
		{
			spin2.SetVisible(true);
			Animation@ anim = spin1.addAnimation("default", 0, false);
			if (anim !is null)
			{
				anim.AddFrame(6);
				spin2.SetFrameIndex(0);
				spin2.SetAnimation(anim);
				spin2.SetRelativeZ(-99.75f);
				spin2.ScaleBy(Vec2f(0.25f,0.25f));
			}
		}
		CSpriteLayer@ spin3 = sprite.addSpriteLayer("spin3", "Singularity.png", 64, 64);
		if (spin3 !is null)
		{
			spin3.SetVisible(true);
			Animation@ anim = spin1.addAnimation("default", 0, false);
			if (anim !is null)
			{
				anim.AddFrame(7);
				spin3.SetFrameIndex(0);
				spin3.SetAnimation(anim);
				spin3.SetRelativeZ(-99.5f);
				spin3.ScaleBy(Vec2f(0.25f,0.25f));
			}
		}
	}
	this.addCommandID("sync");
}


void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if(this.getCommandID("sync") == cmd)
    {
        f32 time = params.read_f32();
		this.set_f32("lifetime", time);
    }
}

void onTick(CBlob@ this)
{
	//printf(""+this.get_f32("lifetime"));
 	if (this.get_f32("lifetime") > 0) this.add_f32("lifetime", -1.0f*0.03f);
	if (this.getTickSinceCreated() < 1)
	{
		if (isClient()) this.Sync("lifetime", true);
		//CBitStream params;
		//if (isServer()) params.write_f32(this.get_f32("lifetime"));
		//this.SendCommand(this.getCommandID("sync"), params);
	}
    SColor lightColor = SColor( 255, 255, 150, 0);
    this.SetLightColor( lightColor );

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		if (this.get_f32("lifetime") <= 0.133f && this.getTickSinceCreated() > 90)
		{
			Boom(this);
			smoke(this.getPosition(), 45);	
			blast(this.getPosition(), 60);
		}

		CSpriteLayer@ spin1 = sprite.getSpriteLayer("spin1");
		CSpriteLayer@ spin2 = sprite.getSpriteLayer("spin2");
		CSpriteLayer@ spin3 = sprite.getSpriteLayer("spin3");

		if (this.get_f32("lifetime") >= 0.5f && spin1 !is null && spin2 !is null && spin3 !is null)
		{
			f32 formula = (12.5f-(12.5f*(this.get_f32("lifetime")/12.5f))) / 1.5;
			sprite.RotateBy(3.0f * formula, Vec2f(0,0));
			spin1.RotateBy( 2.0f * formula, Vec2f(0,0));
			spin2.RotateBy( 1.25f * formula, Vec2f(0,0));
			spin3.RotateBy( 0.75f * formula, Vec2f(0,0));

			if (this.get_f32("lifetime") <= 7.5f)
			{
				sprite.ScaleBy(Vec2f(0.99875f, 0.99875f));
				spin1.ScaleBy(Vec2f(0.99875f, 0.99875f));
				spin2.ScaleBy(Vec2f(0.99875f, 0.99875f));
				spin3.ScaleBy(Vec2f(0.99875f, 0.99875f));
			}
			if (this.getTickSinceCreated() < 10)
			{
				sprite.ScaleBy(Vec2f(1.15f, 1.15f));
				spin1.ScaleBy(Vec2f( 1.15f, 1.15f));
				spin2.ScaleBy(Vec2f( 1.15f, 1.15f));
				spin3.ScaleBy(Vec2f( 1.15f, 1.15f));
				makeSmokeParticle(this, Vec2f(XORRandom(32)-16.0f, XORRandom(32)-16.0f));
				makeSmokePuff(this, 16.0f);
			}
		}
		else if (this.get_f32("lifetime") < 0.5f)
		{
			if (spin1 !is null && spin2 !is null && spin3 !is null)
			{
				spin1.SetVisible(false);
				spin2.SetVisible(false);
				spin3.SetVisible(false);
			}

			if (sprite.getAnimation("explosion") is null)
			{
				Animation@ expl = sprite.addAnimation("explosion", 3, false);
				if (expl !is null)
				{
					int[] frames = {0,1,2,3};
					expl.AddFrames(frames);
					sprite.ResetTransform();
					sprite.ScaleBy(Vec2f(1.75f,1.75f));
					sprite.SetAnimation(expl);
					sprite.SetFrameIndex(0);
				}
			}
		}
	}
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_blast_r.NextFloat() * 18.0f, 0);
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
        Vec2f vel(12.0f + _smoke_r.NextFloat() * 12.0f, 0);
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

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(!getNet().isClient()) return;
	//warn("making smoke");

	const f32 rad = 6.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "GenericBlast6.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = -10.0f;
	}
	
	//warn("smoke made");
}


bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void makeSmokePuff(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 2, const bool sound = true)
{

	//makeSmokeParticle(this, Vec2f(), "Smoke");
	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		makeSmokeParticle(this, vel);
	}
}

void Boom( CBlob@ this )
{
    this.server_SetHealth(-1.0f);
    this.server_Die();
}

void Slam( CBlob @this, f32 angle, Vec2f vel, f32 vellen )
{
	if(vellen < 0.1f)
		return;

	CMap@ map = this.getMap();
	Vec2f pos = this.getPosition();
    HitInfo@[] hitInfos;
	u8 team = this.get_u8("launch team");

    if (map.getHitInfosFromArc( pos, -angle, 30, vellen, this, false, @hitInfos ))
    {
        for (uint i = 0; i < hitInfos.length; i++)
        {
            HitInfo@ hi = hitInfos[i];
            f32 dmg = 2.0f;

            if (hi.blob is null) // map
            {
            	if (BoulderHitMap( this, hi.hitpos, hi.tileOffset, vel, dmg, Hitters::cata_boulder ))
					return;
            }
			else if(team != u8(hi.blob.getTeamNum()))
			{
				this.server_Hit( hi.blob, pos, vel, dmg, Hitters::cata_boulder, true);
				this.setVelocity(vel*0.9f); //damp

				// die when hit something large
				if (hi.blob.getRadius() > 32.0f) {
					this.server_Hit( this, pos, vel, 10, Hitters::cata_boulder, true);
				}
			}
        }
    }

	// chew through backwalls

	Tile tile = map.getTile( pos );	 
	if (map.isTileBackgroundNonEmpty( tile ) )
	{			   
		if (map.getSectorAtPosition( pos, "no build") !is null) {
			return;
		}
		map.server_DestroyTile( pos + Vec2f( 7.0f, 7.0f), 10.0f, this );
		map.server_DestroyTile( pos - Vec2f( 7.0f, 7.0f), 10.0f, this );
	}
}

bool BoulderHitMap( CBlob@ this, Vec2f worldPoint, int tileOffset, Vec2f velocity, f32 damage, u8 customData )
{
    //check if we've already hit this tile
    u32[]@ offsets;
    this.get( "tileOffsets", @offsets );

    if( offsets.find(tileOffset) >= 0 ) { return false; }

    f32 angle = velocity.Angle();
    CMap@ map = getMap();
    TileType t = map.getTile(tileOffset).type;
    u8 blocks_pierced = this.get_u8( "blocks_pierced" );
    bool stuck = false;

    if ( map.isTileCastle(t) || map.isTileWood(t) )
    {
		Vec2f tpos = this.getMap().getTileWorldPosition(tileOffset);
		if (map.getSectorAtPosition( tpos, "no build") !is null) {
			return false;
		}

		//make a shower of gibs here
		
        map.server_DestroyTile( tpos, 100.0f, this );
        Vec2f vel = this.getVelocity();
        this.setVelocity(vel*0.8f); //damp
        this.push( "tileOffsets", tileOffset );

        if (blocks_pierced < pierce_amount)
        {
            blocks_pierced++;
            this.set_u8( "blocks_pierced", blocks_pierced );
        }
        else {
            stuck = true;
        }
    }
    else
    {
        stuck = true;
    }

	if (velocity.LengthSquared() < 5)
		stuck = true;		

    if (stuck)
    {
       this.server_Hit( this, worldPoint, velocity, 10, Hitters::crush, true);
    }

	return stuck;
}

//sprite

void onInit( CSprite@ this )
{
    this.animation.frame = (this.getBlob().getNetworkID()%4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
	this.SetRelativeZ(-100.0f);

	this.SetEmitSound("SingularityCharge.ogg");
	this.SetEmitSoundSpeed(0.85f);
	this.SetEmitSoundVolume(0.75f);
	this.SetEmitSoundPaused(false);
}
