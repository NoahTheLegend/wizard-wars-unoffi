#include "/Entities/Common/Attacks/Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";

const int pierce_amount = 8;

const f32 hit_amount_ground = 0.2f;
const f32 hit_amount_air = 3.0f;
const f32 hit_amount_cata = 10.0f;

void onInit( CBlob @ this )
{
	if (getNet().isClient()) //play game start sound
				Sound::Play("/Corneria.ogg");
    this.set_u8("launch team",255);
    this.server_setTeamNum(-1);
	this.Tag("medium weight");
    
    LimitedAttack_setup(this);
    
    this.set_u8( "blocks_pierced", 0 );
    u32[] tileOffsets;
    this.set( "tileOffsets", tileOffsets );
    
    // damage
    this.set_f32("hit dmg modifier", hit_amount_ground);
	this.set_f32("map dmg modifier", 0.0f); //handled in this script

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().tickFrequency = 3;
}

void onTick( CBlob@ this)
{
	//rock and roll mode
	if (!this.getShape().getConsts().collidable)
	{
		Vec2f vel = this.getVelocity();
		f32 angle = vel.Angle();
		Slam( this, angle, vel, this.getShape().vellen * 1.5f );
	}
	//normal mode
	else if (!this.isOnGround())
	{
		this.set_f32("hit dmg modifier", hit_amount_air);
	}
	else
	{
		this.set_f32("hit dmg modifier", hit_amount_ground);
	}
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint )
{
	if (detached.getName() == "catapult") // rock n' roll baby
	{
		this.getShape().getConsts().mapCollisions = false;
		this.getShape().getConsts().collidable = false;
		this.getCurrentScript().tickFrequency = 1;
		this.set_f32("hit dmg modifier", hit_amount_cata);
	}
	this.set_u8("launch team", detached.getTeamNum());
}

void Slam( CBlob @this, f32 angle, Vec2f vel, f32 vellen )
{
	if (vellen < 0.1f)
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
				if(this.getTimeToDie() < 0)
					this.server_SetTimeToDie( 1 ); // safety measure
				
				if (BoulderHitMap( this, hi.hitpos, hi.tileOffset, vel, dmg, Hitters::crush ))
					return;
            }
			else
			if (team != u8(hi.blob.getTeamNum()))
			{
				this.server_Hit( hi.blob, pos, vel, dmg, Hitters::crush, true);
				this.setVelocity(vel*0.9f); //damp

				// die when hit something large
				if (hi.blob.getRadius() > 32.0f) {
					this.server_Hit( this, pos, vel, 10, Hitters::crush, true);
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

    this.getSprite().PlaySound( "ArrowHitGroundFast.ogg" );
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
}
