#include "Hitters.as";       
#include "LimitedAttacks.as";
#include "TextureCreation.as";
#include "ShieldCommon.as";

const f32 RANGE = 172.0f;
const f32 DAMAGE = 2.0f; // 1.0f is 5 hp
const f32 base_chain_radius = 128.0f;
const f32 chain_radius_falloff = 0.2f;
const f32 chain_radius_falloff_barrier = 0.4f;
const f32 min_chain_radius = 0.33f;

const f32 LIFETIME = 0.33f;

const int MAX_LASER_POSITIONS = 35;
const int LASER_UPDATE_TIME = 10;

const f32 TICKS_PER_SEG_UPDATE = 1;
const f32 LASER_WIDTH = 0.66f;

Random@ _laser_r = Random(0x10001);

void onInit(CBlob@ this)
{
	this.Tag("phase through spells");
	this.Tag("counterable");

	//dont collide with edge of the map
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) );
	
	CShape@ shape = this.getShape();
	shape.SetStatic(true);
	shape.SetGravityScale( 0.0f );
	shape.SetRotationsAllowed(false);
	
	this.set_bool("initialized", false);
	this.server_SetTimeToDie(LIFETIME);

	if (!this.exists("chain_radius")) this.set_f32("chain_radius", base_chain_radius);

	if (!isClient()) return;
	if (this is null) return;

	CSprite@ thisSprite = this.getSprite();
	thisSprite.getConsts().accurateLighting = false;
	thisSprite.PlaySound("lightning_impact.ogg", 1.5f, 1.35f + XORRandom(26)*0.01f);
	
	Setup(SColor(255, 155, 155, 255), "rend4", false);
	Setup(SColor(255, 190, 220, 245), "rend5", false);
	Setup(SColor(255, 255, 245, 255), "rend6", false);
	Setup(SColor(255, 195, 195, 255), "rend7", false);
	int cb_id = Render::addBlobScript(Render::layer_objects, this, "ChainLightning.as", "laserEffects");
}

void setPositionToOwner(CBlob@ this)
{
	if (this.hasTag("secondary")) return;
	
	CPlayer@ ownerPlayer = this.getDamageOwnerPlayer();
	if ( ownerPlayer !is null )
	{
		CBlob@ ownerBlob = ownerPlayer.getBlob();
		if ( ownerBlob !is null )
			this.setPosition( ownerBlob.getPosition() );
	}
}

void updateLaserPositions(CBlob@ this)
{
	Vec2f thisPos = this.getPosition();
	
	Vec2f aimPos = this.get_Vec2f("aim pos");
	Vec2f aimVec = aimPos - thisPos;
	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();
	
	Vec2f destination = aimPos;
	
	Vec2f shootVec = destination-thisPos;
	
	Vec2f normal = (Vec2f(aimVec.y, -aimVec.x));
	normal.Normalize();
	
	array<Vec2f> laser_positions;
	
	float[] positions;
	positions.push_back(0);
	for (int i = 0; i < MAX_LASER_POSITIONS; i++)
	{
		positions.push_back( _laser_r.NextFloat() );
	}		
	positions.sortAsc();
	
	const f32 sway = 10.0f;
	const f32 jaggedness = 1.0f/(4.0f*sway);
	
	Vec2f prevPoint = thisPos;
	f32 prevDisplacement = 0.0f;
	for (int i = 1; i < positions.length; i++)
	{
		float pos = positions[i];
 
		// used to prevent sharp angles by ensuring very close positions also have small perpendicular variation.
		float scale = (shootVec.Length() * jaggedness) * (pos - positions[i - 1]);
 
		// defines an envelope. Points near the middle of the bolt can be further from the central line.
		float envelope = pos > 0.95f ? 20 * (1 - pos) : 1;
 
		float displacement = _laser_r.NextFloat()*sway*2.0f - sway;
		displacement -= (displacement - prevDisplacement) * (1 - scale);
		displacement *= envelope;
 
		Vec2f point = thisPos + shootVec*pos + normal*displacement;
		
		laser_positions.push_back(prevPoint);
		prevPoint = point;
		prevDisplacement = displacement;
	}
	laser_positions.push_back(destination);
	
	this.set("laser positions", laser_positions);
	
	array<Vec2f> laser_vectors;
	for (int i = 0; i < laser_positions.length-1; i++)
	{
		laser_vectors.push_back(laser_positions[i+1] - laser_positions[i]);
	}		
	this.set("laser vectors", laser_vectors);	
}

void laserEffects(CBlob@ this, int id)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	//laser effects	
	if ( this.getTickSinceCreated() > 1 )	//delay to prevent rendering lasers leading from map origin
	{
		Vec2f[]@ laser_positions;
		this.get( "laser positions", @laser_positions );
		
		Vec2f[]@ laser_vectors;
		this.get( "laser vectors", @laser_vectors );
		
		if ( laser_positions is null || laser_vectors is null )
			return; 
		int laserPositions = laser_positions.length;
		
		f32 ticksTillUpdate = getGameTime() % TICKS_PER_SEG_UPDATE;
		
		int lastPosArrayElement = laser_positions.length-1;
		int lastVecArrayElement = laser_vectors.length-1;
		
		/*for (int i = 0; i < laser_positions.length; i++)
		{
			thisSprite.RemoveSpriteLayer("laser"+i);
		}*/
		
		
		f32 z = thisSprite.getZ() - 0.4f;
		for (int i = laser_positions.length - laserPositions; i < lastVecArrayElement; i++)
		{
			Vec2f currSegPos = laser_positions[i];				
			Vec2f prevSegPos = laser_positions[i+1];
			Vec2f followVec = currSegPos - prevSegPos;
			Vec2f followNorm = followVec;
			followNorm.Normalize();
			
			f32 followDist = followVec.Length();
			f32 laserLength = (followDist+3.6f) / 16.0f;		
			
			/*Vec2f netTranslation = Vec2f(0,0);
			for (int t = i+1; t < lastVecArrayElement; t++)
			{	
				netTranslation = netTranslation - laser_vectors[t]; 
			}*/
			
			//Vec2f movementOffset = laser_positions[lastPosArrayElement-1] - thisPos;
			
			Vec2f[] v_pos;
			Vec2f[] v_uv;
			
			v_pos.push_back(currSegPos + Vec2f(-followDist * laserLength + 2,-LASER_WIDTH).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(0,0));//Top left?
			v_pos.push_back(currSegPos + Vec2f( followDist * laserLength + 2,-LASER_WIDTH).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(1,0));//Top right?
			v_pos.push_back(currSegPos + Vec2f( followDist * laserLength + 4, LASER_WIDTH).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(1,1));//Bottom right?
			v_pos.push_back(currSegPos + Vec2f(-followDist * laserLength + 4, LASER_WIDTH).RotateBy(-followNorm.Angle(), Vec2f())	); v_uv.push_back(Vec2f(0,1));//Bottom left?
				
			Render::Quads("rend"+(XORRandom(4)+4), z, v_pos, v_uv);
			
			v_pos.clear();
			v_uv.clear();
		}
	}
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();

	if (isServer() && this.exists("follow_id") && !this.hasTag("secondary"))
	{
		CBlob@ b = getBlobByNetworkID(this.get_u16("follow_id"));
		if (b !is null)
		{
			this.setPosition(b.getPosition());
		}
	}
	
	//setPositionToOwner(this);
	
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > 1 )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 0, 150, 255);
		this.SetLightColor( lightColor );
		thisSprite.SetZ(500.0f);
		
		Vec2f aimPos = this.get_Vec2f("aim pos");
		Vec2f aimVec = aimPos - thisPos;
		Vec2f aimNorm = aimVec;
		aimNorm.Normalize();
		
		Vec2f shootVec = aimNorm*RANGE;
		
		Vec2f destination = thisPos+shootVec;
		
		CMap@ map = this.getMap();
		f32 shortestHitDist = 9999.9f;
		HitInfo@[] hitInfos;
		int attackAngle = -aimNorm.getAngle();
		bool hasHit = map.getHitInfosFromRay(thisPos, attackAngle, RANGE, this, @hitInfos);
		if ( hasHit )
		{
			bool damageDealt = false;
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				
				if (hi.blob !is null) // blob
				{
					CBlob@ target = hi.blob;
					if (target is this || target.get_u32("strike_by_lightning") > getGameTime() || target.getTeamNum() == this.getTeamNum() || (!target.hasTag("barrier") && !target.hasTag("flesh")) )
					{
						continue;
					}
					else if ( damageDealt == false )
					{
                        f32 extraDamage = 1.0f;
                        if(this.hasTag("extra_damage"))
                    	{extraDamage +=0.5;}
						Vec2f attackVector = Vec2f(1,0).RotateBy(attackAngle);
						if (target.hasTag("shielded") && blockAttack(target, attackVector, 0.0f)) //knight blocks with shield
						{
							extraDamage = 0;
							if(isClient())
                    		{target.getSprite().PlaySound("ShieldHit.ogg");}
						}

						f32 dmg = this.get_f32("damage") * extraDamage;
						if (target.get_bool("waterbarrier")) dmg *= 1.5f;

						this.server_Hit(target, hi.hitpos, Vec2f(0,0), dmg, Hitters::explosion, true);
						// reduce length greatly when hit barrier
						if (target.hasTag("barrier"))
							this.set_f32("chain_radius", Maths::Max(min_chain_radius, this.get_f32("chain_radius") * (1.0f - chain_radius_falloff_barrier)));

						if (isServer() && this.get_u8("targets") != 0)
						{
							u16 id;
							f32 closest = 999.0f;
							CBlob@[] list;

							f32 chain_radius = this.get_f32("chain_radius");
							getMap().getBlobsInRadius(hi.hitpos, chain_radius, @list);

							for (u16 i = 0; i < list.length; i++)
							{
								CBlob@ l = list[i];
								if (l is null || !l.hasTag("flesh") || l.hasTag("dead") || l.getTeamNum() == this.getTeamNum()
								|| l is target || l.get_u32("strike_by_lightning") > getGameTime()
								|| getMap().rayCastSolidNoBlobs(hi.hitpos, l.getPosition()))
									continue;

								f32 dist = (l.getPosition() - hi.hitpos).Length();
								if (dist < closest)
								{
									id = l.getNetworkID();
									closest = dist;
								}
							}
							CBlob@ t = getBlobByNetworkID(id);
							if (t !is null)
							{
								CBlob@ orb = server_CreateBlob("chainlightning", this.getTeamNum(), hi.hitpos); 
								if (orb !is null)
								{
            				        if(this.hasTag("extra_damage"))
            				            orb.Tag("extra_damage");

									f32 new_chain_radius = Maths::Max(min_chain_radius,
										this.get_f32("chain_radius") * (1.0f - chain_radius_falloff));

									orb.set_f32("chain_radius", new_chain_radius);
									orb.set_f32("damage", this.get_f32("damage"));

									if (this.get_u8("targets") > 0) orb.set_u8("targets", this.get_u8("targets")-1);
									orb.set_Vec2f("aim pos", t.getPosition() + t.getVelocity());

									orb.set_u16("follow_id", target.getNetworkID());
									orb.Tag("secondary");

									orb.IgnoreCollisionWhileOverlapped(this);
									orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
								}
							}
						}
						
						target.set_u32("strike_by_lightning", getGameTime()+10);
						damageDealt = true;
					}
				}
				
				Vec2f hitPos = hi.hitpos;
				f32 distance = hi.distance;
				if ( shortestHitDist > distance )
				{
					shortestHitDist = distance;
					destination = hitPos;
				}
			}
		}
		this.set_Vec2f("aim pos", destination);
		
		Vec2f normal = (Vec2f(aimVec.y, -aimVec.x));
		normal.Normalize();
		
		updateLaserPositions(this);
		
		if ( shortestHitDist < RANGE )
			ChainLightningSparks(destination - aimNorm*4.0f, 20);
		
		this.set_bool("initialized", true);
	}
	
	//laserEffects(this);
	if ( this.getTickSinceCreated() > 1 && getGameTime() % TICKS_PER_SEG_UPDATE == 0 )	//delay to prevent rendering lasers leading from map origin
	{
		Vec2f[]@ laser_positions;
		this.get( "laser positions", @laser_positions );
		
		Vec2f[]@ laser_vectors;
		this.get( "laser vectors", @laser_vectors );
		
		if ( laser_positions is null || laser_vectors is null )
			return; 
		
		updateLaserPositions(this);
	}
	
}

Random@ _sprk_r = Random(23453);
void ChainLightningSparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;
		
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 155, _sprk_r.NextRanged(100), 128+_sprk_r.NextRanged(100), 255), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 20 + _sprk_r.NextRanged(20);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}