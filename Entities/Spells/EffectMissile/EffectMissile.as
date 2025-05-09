#include "Hitters.as";	   
#include "LimitedAttacks.as";
#include "SpellUtils.as";
#include "SpellCommon.as";

const int LIFETIME = 4;
const int EXTENDED_LIFETIME = 6;
const f32 SEARCH_RADIUS = 64.0f;
const f32 HOMING_FACTOR = 6.0f;
const int HOMING_DELAY = 15;	

const int INIT_DELAY = 2;	//prevents initial seg pos to be at (0,0)

void onInit( CBlob @ this )
{
	this.Tag("phase through spells");
	this.Tag("counterable");
	
    //this.server_setTeamNum(1);
	this.Tag("medium weight");

	CShape@ shape = this.getShape();
	shape.SetGravityScale( 0.0f );
	shape.getConsts().bullet = true;
	shape.SetRotationsAllowed(false);
	
    //burning sound	    
	CSprite@ thisSprite = this.getSprite();
	thisSprite.getConsts().accurateLighting = false;
	
	this.set_bool("initialized", false);
	this.set_bool("segments updating", false);
	this.set_u32("dead segment", 0);
	this.set_u8("target_type", 3);
	this.set_u8("effect", 255);
	
	this.set_bool("target found", false);
	this.set_bool("dead", false);
	
	this.getShape().getConsts().mapCollisions = false;
}

void onTick( CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();
	Vec2f thisVel = this.getVelocity();

	u8 effectType = this.get_u8("effect");

	if(!this.exists("setupDone") || !this.get_bool("setupDone"))//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		this.set_bool("setupDone",true);
		u8 targetType = 3;

		switch(effectType)
		{
			case haste_effect_missile:
			case heal_effect_missile:
			case mana_effect_missile:
			case airblastShield_effect_missile:
			case fireProt_effect_missile:
			case regen_effect_missile:
			case dmgconnection_effect_missile:
			case cooldownreduce_effect_missile:
			case antidebuff_effect_missile:
			{
				targetType = 0;
			}
			break;
			
			case revive_effect_missile:
			case revive_knight_effect_missile:
			case unholyRes_effect_missile:
			{
				targetType = 1;
			}
			break;

			case slow_effect_missile:
			case healblock_effect_missile:
			{
				targetType = 2;
				this.Tag("projectile");
			}
			break;

			case manaburn_effect_missile:
			{
				targetType = 2;
				this.Tag("manaburn");
				this.Tag("projectile");
			}
			break;
				
			default: targetType = 3;
		}

		this.set_u8("target_type", targetType);
	}

	u8 targetType = this.get_u8("target_type");
	if ( this.get_bool("initialized") == false && this.getTickSinceCreated() > INIT_DELAY )
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor( 255, 255, 150, 0);
		this.SetLightColor( lightColor );
		if(!this.get_bool("silent"))
		{
			thisSprite.PlaySound("GenericProjectile1.ogg", 0.8f, 1.0f + XORRandom(3)/10.0f);
		}
		thisSprite.SetZ(500.0f);
		
		this.set_bool("initialized", true);
	}
	
	//targetting 
	if (this.getTickSinceCreated() > HOMING_DELAY)
	{	
		// try to find player target	
		CBlob@ target = getBlobByNetworkID(this.get_netid("target"));
		if (target is null)
		{
			CBlob@[] blobs;
			this.getMap().getBlobsInRadius( thisPos, SEARCH_RADIUS, @blobs );
			f32 best_dist = 99999999;
			for (uint step = 0; step < blobs.length; ++step)
			{
				//TODO: sort on proximity? done by engine?
				CBlob@ other = blobs[step];

				if (other is this)
				{continue;} //lets not run away from / try to eat ourselves...
				
				bool sameTeam = this.getTeamNum() == other.getTeamNum();
				
				switch(targetType) //does action according to targetting type
				{
					case 0: //follows allies
					{
						if (sameTeam && !isOwnerBlob(this, other) && other.hasTag("player") && !other.hasTag("dead")) //home in on living allies
						{
							Vec2f tpos = other.getPosition();									  
							f32 dist = (tpos - thisPos).getLength();
							if (dist < best_dist)
							{
								this.set_netid("target", other.getNetworkID());
								best_dist=dist;
								this.getShape().setDrag(2.0f);
							}
						}
					}
					break;
				
					case 1: //follows dead allies
					{
						if (sameTeam && other.hasTag("gravestone") ) //home in on gravestones
						{
							Vec2f tpos = other.getPosition();									  
							f32 dist = (tpos - thisPos).getLength();
							if (dist < best_dist)
							{
								this.set_netid("target", other.getNetworkID());
								best_dist=dist;
								this.getShape().setDrag(2.0f);
							}
						}
					}
					break;
				
					case 2: //follows enemies
					{
						if (!sameTeam && other.hasTag("player") && !other.hasTag("dead")) //home in on enemies
						{
							Vec2f tpos = other.getPosition();									  
							f32 dist = (tpos - thisPos).getLength();
							if (dist < best_dist)
							{
								this.set_netid("target", other.getNetworkID());
								best_dist=dist;
								this.getShape().setDrag(2.0f);
							}
						}
					}
					break;

					default:
					{
						this.Tag("mark_for_death");
						return;
					}
				} //switch end
			}
		}
		else
		{
			this.set_bool("target found", true);
		
			Vec2f tpos = target.getPosition();
			selectedTargetIndicator( this , tpos );
			Vec2f targetNorm = tpos - thisPos;
			targetNorm.Normalize();
			
			this.AddForce( targetNorm*HOMING_FACTOR );
			if (this.getDistanceTo(target) < target.getRadius())
			{
				setEffect(this, target);
			}
		}
	}
	
	//delayed death
	if  (this !is null)
	{
		if ( this.get_bool("target found") && this.getTickSinceCreated() > (LIFETIME + EXTENDED_LIFETIME)*30 )
		{
			this.Tag("mark_for_death");
		}
		else if ( !this.get_bool("target found") && this.getTickSinceCreated() > LIFETIME*30 )
		{
			this.Tag("mark_for_death");
		}
	}
}

void setEffect(CBlob@ this, CBlob@ blob)
{
	if (this.hasTag("set")) {return;}

	if (blob is null) {return;}
	bool sameTeam = blob.getTeamNum() == this.getTeamNum();

	Vec2f thisPos = this.getPosition();
	u8 effectType = this.get_u8("effect");
	u8 targetType = this.get_u8("target_type");

	if (blob.hasTag("player") && !blob.hasTag("set"))
	{
		if (sameTeam && targetType == 0 && !isOwnerBlob(this, blob))	//buff status effects
		{
			switch(effectType)
			{
				case haste_effect_missile:
				{
					Haste(blob, this.get_u16("effect_time"));
				}
				break;

				case heal_effect_missile:
				{
					Heal(this, blob, this.get_f32("heal_amount"));
				}
				break;

				case regen_effect_missile:
				{
					Regen(blob, this.get_u16("effect_time"));
				}
				break;

				case dmgconnection_effect_missile:
				{
					Connect(blob, this.get_u16("effect_time"), this.get_u16("link_id"));
				}
				break;

				case mana_effect_missile:
				{
					manaShot(blob, this.get_u8("mana_used"), this.get_u8("caster_mana"), this.get_bool("silent"), this.get_u8("direct_restore"));
				}
				break;
				
				case airblastShield_effect_missile:
				{
					AirblastShield(blob, this.get_u16("effect_time"));
				}
				break;

				case fireProt_effect_missile:
				{
					FireWard(blob, this.get_u16("effect_time"));
				}
				break;

				case cooldownreduce_effect_missile:
				{
					CooldownReduce(blob, this.get_u16("effect_time"), 0.5f);
				}
				break;

				case antidebuff_effect_missile:
				{
					AntiDebuff(blob, this.get_u16("effect_time"));
				}
				break;

				default: break; 
			} //switch end
			
			this.Tag("set");
			this.Tag("mark_for_death");
			return;
		}
		else if (!sameTeam && targetType == 2)	//curse status effects
		{
			if (effectType == slow_effect_missile)
			{
				Slow(blob, this.get_u16("effect_time"));
			}
			else if (effectType == manaburn_effect_missile)
			{
				ManaBurn(blob, this.get_u16("effect_time"));
			}
			else if (effectType == healblock_effect_missile)
			{
				HealBlock(blob, this.get_u16("effect_time"));
			}

			this.Tag("set");
			this.Tag("mark_for_death");
			return;
		}
	}
	else if (blob.getName() == "gravestone" && sameTeam && targetType == 1)	//ally revive spells
	{
		switch(effectType)
		{
			case revive_effect_missile:
			{
				Revive(blob);
			}
			break;

			case revive_knight_effect_missile:
			{
				ReviveKnight(blob);
			}
			break;
		
			case unholyRes_effect_missile:
			{
				UnholyRes(blob);
			}
			break;
			
			default: break;
		} //switch end

		this.Tag("set");
		this.Tag("mark_for_death");
		return;
	}
}

void onTick(CSprite@ this)
{
	if(!isClient())
	{return;}

	CBlob@ b = this.getBlob();
	if(b is null)
	{return;}

	Vec2f thisPos = b.getPosition();
	u8 effectType = b.get_u8("effect");

	if ( (!b.exists("spriteSetupDone") || !b.get_bool("spriteSetupDone")) && effectType != 255)//this is done instead of using onInit becuase onInit only runs once even if this script is removed and added again
	{
		this.SetFrame(effectType);
		if (b.exists("override_sprite_frame"))
			this.SetFrame(b.get_u8("override_sprite_frame"));
		b.set_bool("spriteSetupDone", true);
	}
	
	f32 angle = b.getVelocity().Angle();	//face towards moving direction
	this.ResetTransform();
	this.RotateBy( -angle, Vec2f(0,0) );
	
	sparks(b, thisPos, 1);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return ( blob.hasTag("solidblob") );
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (this.hasTag("dead") || this.getTickSinceCreated() < HOMING_DELAY) {return;}

	if (blob is null)
	return;
	
	CBlob@ target = getBlobByNetworkID(this.get_netid("target"));
	
	if(this.get_bool("target found") && target !is null && target is blob)
	{
		setEffect(this, blob);
	}
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	if ( target is null )
		return true;

	//easy check
	if (this.getDamageOwnerPlayer() is target.getPlayer())
		return true;

	if (!this.exists("explosive_parent")) { return false; }

	return (target.getNetworkID() == this.get_u16("explosive_parent"));
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel, const string filename = "Smoke")
{
	if(!getNet().isClient()) 
		return;
	//warn("making smoke");

	const f32 rad = 2.0f;
	Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
	CParticle@ p = ParticleAnimated( "MissileFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2, 0.0f, false );
	if ( p !is null)
	{
		p.bounce = 0;
    	p.fastcollision = true;
		p.Z = 300.0f;
	}
	
	//warn("smoke made");
}

void onDie( CBlob@ this )
{
	if(!isClient()) {return;}

	Vec2f initVec = Vec2f(2.0f,0);
	for(u16 i = 0; i < 45; i++)
	{
		Vec2f pVel = initVec.RotateByDegrees(i*8);

		CParticle@ p = ParticlePixelUnlimited(this.getPosition(), pVel, SColor( 255, 255, 255, 255), true);
    	if(p !is null)
		{
		    p.collides = false;
		    p.gravity = Vec2f_zero;
		    p.bounce = 0;
 			p.Z = 200;
 			p.timeout = 15;
			p.scale = 0.5f + _sprk_r.NextFloat();
			p.damping = 0.85f;
        }
	}
	
}

Random _sprk_r(2345);
void sparks(CBlob@ this, Vec2f pos, int amount)
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 0.5f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);
		
		int colorShade = 255 - _sprk_r.NextRanged(128);
		switch(this.get_u8("target_type"))
		{
			case 0: //allies
			case 1: //dead allies
			{
				CParticle@ p = ParticlePixelUnlimited(pos, vel, SColor( 255, colorShade, colorShade, colorShade ), true);
    		    if(p !is null)
		        {
		            p.fastcollision = true;
		            p.gravity = Vec2f_zero;
		            p.bounce = 0;
 					p.Z = 200;
 		        	p.timeout = 40 + _sprk_r.NextRanged(20);
					p.scale = 0.5f + _sprk_r.NextFloat();
					p.damping = 0.95f;
        		}
			}
			break;
		
			case 2: //enemies
			{
				bool is_manaburn = this.hasTag("manaburn");
				SColor color = SColor( 255, colorShade, colorShade, 0 );
				if (is_manaburn) {color = SColor(255, 180, 75, 255);}
				CParticle@ p = ParticlePixelUnlimited(pos, vel, color, true);
    		    if(p !is null)
		        {
		            p.fastcollision = true;
		            p.gravity = Vec2f_zero;
		            p.bounce = 0;
 					p.Z = 200;
 		        	p.timeout = 40 + _sprk_r.NextRanged(20);
					p.scale = 0.5f + _sprk_r.NextFloat();
					p.damping = 0.95f;
        		}
			}
			break;

			default: return;
		} //switch end
    }
}

void selectedTargetIndicator( CBlob@ this , Vec2f pos )
{
	if ( !isClient() ) {return;}

	Vec2f thisPos = this.getPosition();
	Vec2f targetPos = pos;
	Vec2f moveDir = targetPos - thisPos;
	float dist = moveDir.Length();
	Vec2f pVector = moveDir;
	pVector.Normalize();

	SColor color = SColor(255, 0, 0, 0);

	switch(this.get_u8("target_type"))
	{
		case 0: //allies
		case 1: //dead allies
		{
			color = SColor(255, 240, 240, 240);
		}
		break;

		case 2: //enemies
		{
			bool is_manaburn = this.hasTag("manaburn");
			if (is_manaburn)
				color = SColor(255, 225, 125, 255);
			else
				color = SColor( 255, 255, 165, 0 );
		}
		break;

		default: return;
	} //switch end

	for(int i = 0; i < dist; i += 2)
	{
		CParticle@ p = ParticlePixelUnlimited(thisPos + pVector*i, Vec2f_zero, color, true);
        if(p !is null)
        {
            p.fastcollision = true;
            p.gravity = Vec2f_zero;
            p.bounce = 0;
            p.Z = 200;
            p.timeout = _sprk_r.NextRanged(5);
			p.scale = 0.5f + _sprk_r.NextFloat();
			p.damping = 0.8f;
        }
	}
}