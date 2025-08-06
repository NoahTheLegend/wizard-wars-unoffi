#include "MagicCommon.as";
#include "Hitters.as";
#include "PlayerPrefsCommon.as";
#include "SpellHashDecoder.as";
#include "HoverMessage.as";
#include "PaladinCommon.as";

Random _spell_common_r(26784);

const u16 defaultPoisonTime = 300; // 10 seconds
const u8  poisonThreshold = 60; // 2 seconds
const f32 poisonDamage = 0.2f; // 1 HP

void Freeze(CBlob@ blob, f32 frozenTime)
{	
	blob.getShape().getConsts().collideWhenAttached = false;

	Vec2f blobPos = blob.getPosition();
	if (isServer())
	{
		CBlob@ icePrison = server_CreateBlob("ice_prison", blob.getTeamNum(), blobPos);
		if ( icePrison !is null )
		{
			AttachmentPoint@ ap = icePrison.getAttachments().getAttachmentPointByName("PICKUP2");
			if (ap !is null)
			{
				icePrison.setVelocity(blob.getVelocity()*0.5f);
				icePrison.server_AttachTo(blob, "PICKUP2");
			}
			
			icePrison.set_f32("frozenTime", frozenTime);
			icePrison.Sync("frozenTime", true);
			
			icePrison.server_SetTimeToDie(frozenTime);
		}
	}
}

void CastNegentropy( CBlob@ this )
{
	ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo ))
	{return;}

	CMap@ map = getMap(); //standard map check
	if(map is null)
	{return;}

	u32 gatheredMana = 0;

	Vec2f thisPos = this.getPosition();
	Vec2f aimVec = this.getAimPos() - thisPos;
	float aimAngle = aimVec.getAngleDegrees();

	float negentropyRange = 64.0f;
	float negentropyRangeInner = 20.0f;
	float negentropyAngle = 90.0f;

	float arcLimitDegrees = (negentropyAngle/2)+5.0f;

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(thisPos, negentropyRange, @blobsInRadius);
	
	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b is null)
		{continue;}
		if (this.getTeamNum() == b.getTeamNum())
		{continue;}

		Vec2f bPos = b.getPosition();
		Vec2f bVec = bPos - thisPos;
		float bAngle = bVec.getAngleDegrees();

		float angleDiff = bAngle - aimAngle;
		angleDiff = (angleDiff + 180) % 360 - 180;

		if( (angleDiff > arcLimitDegrees || angleDiff < -arcLimitDegrees) && bVec.getLength() > negentropyRangeInner)
		{
			continue;
		}
		
		bool incompatible = false;
		bool kill = true;
		s8 absorbed = negentropyDecoder(b);

		if ( absorbed == -1 && !b.hasTag("flesh") && !b.hasScript("BladedShell.as") )
		{continue;}
		if ( absorbed == -2 )
		{
			absorbed = 10;
			incompatible = true;
			kill = false;
		}
		if ( absorbed == -3 )
		{
			absorbed = 5;
			kill = false;
		}

		if ( b.hasTag("flesh") )
		{
			absorbed = 3;
			kill = false;
		}

		if ( b.hasScript("BladedShell.as") )
		{
			absorbed = 8;
			kill = false;
		}

		if (isServer())
		{
			CBlob@ orb = server_CreateBlob( "lightning2", this.getTeamNum(), this.getPosition() ); 
			if (orb !is null)
			{
				orb.set_Vec2f("aim pos", bPos);
				orb.set_f32("lifetime", 0.4f);
				orb.Tag("stick"); //enables stick-to-blob code in lightning2.as
				if(incompatible)
				{
					orb.set_bool("repelled", true);
				}
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
			}
		}
				
		if (b is null || this is null)
		{continue;}

		if(incompatible)
		{
			Vec2f velocity = this.getPosition() - b.getPosition();
			velocity.Normalize();
			velocity *= 5;
			b.server_Hit(this, this.getPosition(), velocity, 1.0f, Hitters::water, true);
		}
		
		if (kill)
		{
			b.Untag("exploding");
			b.Tag("mark_for_death");
		}
		gatheredMana += absorbed;
		
	}

	if ( !isClient() )
	{return;}

	u8 maxMana = manaInfo.maxMana;
	if(this.hasTag("focused")) //extra mana if focus mode
	{
		gatheredMana *= 1.3f;
		this.Untag("focused");
		this.set_u16("focus",0);
	}
	if (manaInfo.mana + gatheredMana >= maxMana)
	{manaInfo.mana = maxMana;}
	else
	{manaInfo.mana += gatheredMana;}
	
	CSprite@ sprite = this.getSprite();
	if (gatheredMana == 0)
	{
		sprite.PlaySound("no_discharge.ogg", 3.0f);
	}
	else if (gatheredMana < 40)
	{
		sprite.PlaySound("discharge1.ogg", 3.0f);
	}
	else
	{
		sprite.PlaySound("discharge2.ogg", 3.0f);
	}

	u8 blue = (190.0f * _spell_common_r.NextFloat());

	SColor color = SColor(255, 255, 255, blue);
	for(int i = 0; i < 90; i ++)
	{
		float particleDegrees = -aimAngle + i - 45;
		Vec2f particlePos = Vec2f(64.0f * _spell_common_r.NextFloat() , 0).RotateByDegrees(particleDegrees);
		Vec2f particleVel = Vec2f( 0.4f ,0).RotateByDegrees( 360.0f * _spell_common_r.NextFloat());
		u32 pTimeout = 15.0f + (15.0f * _spell_common_r.NextFloat());

		CParticle@ p = ParticlePixelUnlimited( this.getPosition() + particlePos , particleVel , color , false );
		if(p !is null)
		{
			p.gravity = Vec2f_zero;
			p.damping = 0.9;
			p.collides = false;
			p.fastcollision = true;
			p.bounce = 0;
			p.lighting = false;
			p.Z = 500;
			p.timeout = pTimeout;
		}
	}
}


void SummonZombie(CBlob@ this, string name, Vec2f pos, int team)
{
    ParticleZombieLightning( pos );
    if (isServer())
	{
        CBlob@ summoned = server_CreateBlob( name, team, pos );
		if ( summoned !is null )
		{
			summoned.SetDamageOwnerPlayer( this.getPlayer() );
		}
	}
}

void Heal( CBlob@ this, CBlob@ blob, f32 healAmount, bool flash = true, bool sound = true, f32 particles_factor = 1.0f)
{
	f32 health = blob.getHealth();
	f32 initHealth = blob.getInitialHealth();

	if (health >= initHealth) return;
	healAmount = Maths::Min(initHealth - health, healAmount);
	
	if (isServer())
	{
		if ( (health + healAmount) > initHealth )
			blob.server_SetHealth(initHealth);
		else
			blob.server_SetHealth(health + healAmount);
	}
		
    if (flash && blob.isMyPlayer())
    {
        SetScreenFlash( 75, 0, 225, 0 );
	}

	if (this.getDamageOwnerPlayer() is getLocalPlayer() && blob !is getLocalPlayerBlob())
	{
		CRules@ rules = getRules();
		if (rules !is null && rules.get_bool("hovermessages_enabled"))
			add_message(HealDealtMessage(healAmount));

		// crashes the game!
		//if (getRules().get_bool("hovermessages_enabled"))
		//	add_message(HealDealtMessage(healAmount));
	}
	
	if (isClient())
	{
		if (sound) blob.getSprite().PlaySound("Heal.ogg", 0.8f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );
		makeHealParticles(blob, 1.0f, 12 * particles_factor, sound);
	}
}

void makeHealParticles(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 12, const bool sound = true)
{
	if ( !isClient() ){
		return;	
	}

	//makeSmokeParticle(this, Vec2f(), "Smoke");
	for (int i = 0; i < smallparticles; i++)
	{	
		f32 randomness = (XORRandom(33) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		
		const f32 rad = 12.0f;
		Vec2f random = Vec2f( XORRandom(129)-64, XORRandom(129)-64 ) * 0.015625f * rad;
		CParticle@ p = ParticleAnimated( "HealParticle.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(361)), 1.0f, 2 + XORRandom(3), 0.0f, false );
		if ( p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			if ( XORRandom(2) == 0 )
				p.Z = 10.0f;
			else
				p.Z = -10.0f;
		}
	}
}

void Revive(CBlob@ blob)
{			
	int playerId = blob.get_u16( "owner_player" );
	CPlayer@ deadPlayer = getPlayerByNetworkId( playerId );
	
	if( isServer() && deadPlayer !is null )
	{
		PlayerPrefsInfo@ playerPrefsInfo;
		if ( !deadPlayer.get( "playerPrefsInfo", @playerPrefsInfo ) || playerPrefsInfo is null )
		{
			return;
		}
	
		CBlob @newBlob = server_CreateBlob( playerPrefsInfo.classConfig, deadPlayer.getTeamNum(), blob.getPosition() );		
		if( newBlob !is null )
		{
			f32 health = newBlob.getHealth();
			f32 initHealth = newBlob.getInitialHealth();
	
			newBlob.server_SetPlayer( deadPlayer );
			newBlob.server_SetHealth( initHealth*0.2f );
			
			ManaInfo@ manaInfo;
			if ( newBlob.get( "manaInfo", @manaInfo ) ) 
			{
				manaInfo.mana = 0;
			}			
			
			makeReviveParticles(newBlob);
			
			blob.Tag("mark_for_death");
		}
	}
		
	blob.getSprite().PlaySound("Revive.ogg", 0.8f, 1.0f);
	makeReviveParticles(blob);
}

void ReviveKnight(CBlob@ blob)
{			
	int playerId = blob.get_u16("owner_player");
	CPlayer@ deadPlayer = getPlayerByNetworkId(playerId);
	
	if (isServer() && deadPlayer !is null)
	{
		CBlob @newBlob = server_CreateBlob("knight", deadPlayer.getTeamNum(), blob.getPosition());		
		if(newBlob !is null)
		{
			f32 health = newBlob.getHealth();
			f32 initHealth = newBlob.getInitialHealth();
	
			newBlob.server_SetPlayer(deadPlayer);
			
			ManaInfo@ manaInfo;
			if (newBlob.get( "manaInfo", @manaInfo)) 
			{
				manaInfo.mana = 0;
			}			
			
			makeReviveParticles(newBlob);
			
			blob.Tag("mark_for_death");
		}
	}
		
	blob.getSprite().PlaySound("Revive.ogg", 0.8f, 1.0f);
	makeReviveParticles(blob);
}

void UnholyRes(CBlob@ blob)
{			
	int playerId = blob.get_u16( "owner_player" );
	CPlayer@ deadPlayer = getPlayerByNetworkId( playerId );
	
	if( isServer() && deadPlayer !is null )
	{
		CBlob @newBlob = server_CreateBlob( "wraith", deadPlayer.getTeamNum(), blob.getPosition() );		
		if( newBlob !is null )
		{
			newBlob.server_SetPlayer( deadPlayer );
			
			ManaInfo@ manaInfo;
			if ( newBlob.get( "manaInfo", @manaInfo ) ) 
			{
				manaInfo.mana = 0;
			}			
			
			makeReviveParticles(newBlob);
			
			blob.Tag("mark_for_death");
		}
	}
		
	blob.getSprite().PlaySound("Summon2.ogg", 0.8f, 1.0f);
	ParticleZombieLightning( blob.getPosition() );
}

void makeReviveParticles(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 12, const bool sound = true)
{
	if ( !isClient() ){
		return;
	}
		
	//makeSmokeParticle(this, Vec2f(), "Smoke");
	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32)*0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity( -90, velocity * randomness, 360.0f );
		
		const f32 rad = 12.0f;
		Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
		CParticle@ p = ParticleAnimated( "MissileFire3.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
		if ( p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			if ( XORRandom(2) == 0 )
				p.Z = 10.0f;
			else
				p.Z = -10.0f;
		}
	}
}

void counterSpell( CBlob@ caster , Vec2f aimpos, Vec2f thispos)
{		
	CMap@ map = getMap(); //standard map check
	if(map is null)
	{return;}

	Vec2f aimVec = aimpos - thispos;
	float aimAngle = aimVec.getAngleDegrees();

	float counterspellRange = 64.0f;
	float counterspellRangeInner = 20.0f;
	float counterspellArc = 90.0f;

	float arcLimitDegrees = (counterspellArc/2)+6.0f;

	CBlob@[] blobsInRadius;
	map.getBlobsInRadius(thispos, counterspellRange, @blobsInRadius);

	for (uint i = 0; i < blobsInRadius.length; i++)
	{
		CBlob@ b = blobsInRadius[i];
		if (b !is null)
		{
			Vec2f bPos = b.getPosition();
			Vec2f bVec = bPos - thispos;
			float bAngle = bVec.getAngleDegrees();

			float angleDiff = bAngle - aimAngle;
			angleDiff = (angleDiff + 180) % 360 - 180;
			
			if( ((angleDiff > arcLimitDegrees
				|| angleDiff < -arcLimitDegrees)
					&& bVec.getLength() > counterspellRangeInner) || b.hasTag("invincible"))
			{
				continue;
			}

			bool sameTeam = b.getTeamNum() == caster.getTeamNum();
			bool countered = false;
			bool retribution = false;

			// spells
			if (b.hasTag("counterable") && (!sameTeam || b.hasTag("alwayscounter")))
			{
				b.Untag("exploding");
				b.Tag("just_countered");
				b.Tag("mark_for_death");
				b.Tag("counterspelled");

				if (b.getName() == "plant_aura")
				{retribution = true;}
					
				countered = true;
			}

			// debuffs
			if ( b.get_u16("slowed") > 0 && sameTeam )
			{				
				b.set_u16("slowed", 1);
				b.Sync("slowed", true);
					
				countered = true;
			}
			if ( b.get_u16("poisoned") > 0 && (!b.exists("plague") || !b.get_bool("plague")) && sameTeam )
			{
				b.set_u16("poisoned", 1);
				b.Sync("poisoned", true);

				countered = true;
			}
			if (b.get_u16("confused") > 0 && sameTeam)
			{
				b.set_u16("confused", 1);
				b.Sync("confused", true);
					
				countered = true;
			}
			if ( b.get_u16("manaburn") > 0 && sameTeam )
			{				
				b.set_u16("manaburn", 1);
				b.Sync("manaburn", true);
					
				countered = true;
			}
			if ( b.get_u16("healblock") > 0 && sameTeam )
			{				
				b.set_u16("healblock", 1);
				b.Sync("healblock", true);
					
				countered = true;
			}
			
			// enemy buffs
			if (
			(b.get_u16("hastened") > 0
			 || b.get_u16("regen") > 0
			 || b.get_u16("fireProt") > 0 
			 || b.get_u16("airblastShield") > 0 
			 || b.get_u16("stoneSkin") > 0
			 || b.get_bool("waterbarrier")
			 || b.get_bool("damageaura")
			 || b.get_u16("dmgconnection") > 0
			 || b.get_u16("cdreduction") > 0
			 || b.get_u16("antidebuff") > 0
			 )
			 && !sameTeam )
			{
				if(b.get_u16("hastened") > 0)
				{
					b.set_u16("hastened", 1);
					b.Sync("hastened", true);
				}

				if(b.get_u16("regen") > 0)
				{
					b.set_u16("regen", 1);
					b.Sync("regen", true);
				}

				if(b.get_u16("fireProt") > 0)
				{
					b.set_u16("fireProt", 1);
					b.Sync("fireProt", true);
				}

				if(b.get_u16("airblastShield") > 0)
				{
					b.set_u16("airblastShield", 1);
					b.Sync("airblastShield", true);
				}

				if(b.get_u16("stoneSkin") > 0)
				{
					b.set_u16("stoneSkin", 1);
					b.Sync("stoneSkin", true);
				}

				if (b.get_bool("waterbarrier"))
				{
					b.set_bool("waterbarrier", false);
					b.Sync("waterbarrier", true);
				}

				if (b.get_bool("damageaura"))
				{
					b.set_bool("damageaura", false);
					b.Sync("damageaura", true);
				}

				if (b.get_u16("dmgconnection") > 0)
				{
					b.set_u16("dmgconnection", 1);
					b.Sync("dmgconnection", true);
				}

				if (b.get_u16("cdreduction") > 0)
				{
					b.set_u16("cdreduction", 1);
					b.Sync("cdreduction", true);
				}

				if (b.get_u16("antidebuff") > 0)
				{
					b.set_u16("antidebuff", 1);
					b.Sync("antidebuff", true);
				}
					
				countered = true;
			}
			else if ( b.hasTag("zombie") && !sameTeam )
			{
				float damage = undeadCounterspellDamage(b);
				if(damage == 0)
				{return;}

				caster.server_Hit(b, b.getPosition(), Vec2f(0, 0), damage, Hitters::explosion, true);
					
				countered = true;
			}
			else if(!sameTeam && (b.hasTag("multi_despell")))
			{
				b.add_u8("despelled",1);
				countered = true;
			}
			if (retribution)
			{
				/*ManaInfo@ manaInfo;
				if (!caster.get( "manaInfo", @manaInfo )) {
					return;
				}
				manaInfo.mana += 10;*/
				if(caster !is null)
				{Heal(caster, caster, 1.0f);}
			}

			if ( countered )
			{
				if ( isClient() )
				{
					Vec2f bPos = b.getPosition();
					CParticle@ p = ParticleAnimated( "Flash2.png",
									bPos,
									Vec2f(0,0),
									0,
									1.0f, 
									8, 
									0.0f, true ); 	
									
					if ( p !is null)
					{
						p.bounce = 0;
    					p.fastcollision = true;
						p.Z = 2000.0f;
					}
				}
			}
		}
	}
	
	
	if ( isClient() )
	{
		CParticle@ p = ParticleAnimated( "Shockwave90deg.png",
						thispos,
						Vec2f(0,0),
						-aimAngle + 45,
						1.0f, 
						2, 
						0.0f, true );    
		if ( p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			p.Z = -10.0f;
		}
		
		caster.getSprite().PlaySound("CounterSpell.ogg", 0.8f, 1.0f);
	}
	
}

void Slow(CBlob@ blob, u16 slowTime)
{
	if (blob.get_u16("hastened") > 0)
	{
		blob.set_u16("hastened", 1);
		blob.Sync("hastened", true);
	}
	else
	{
		blob.set_u16("slowed", slowTime);
		blob.Sync("slowed", true);
		blob.getSprite().PlaySound("SlowOn.ogg", 0.8f, 1.0f);
	}
}

void Shapeshift(CBlob@ this, CBlob@ blob, u16 time)
{	
	if (isServer())
	{
		CBitStream params;
		params.write_bool(false);
		params.write_u16(this.getNetworkID());
		params.write_u16(blob.getNetworkID());
		getRules().SendCommand(getRules().getCommandID("shapeshift_gatherstats"), params);
	}
}

void Poison(CBlob@ blob, u16 poisonTime = defaultPoisonTime, CBlob@ hitter = null, f32 sound_volume = 1.0f)
{
	if (hitter !is null)
	{
		blob.set_u16("last_poison_owner_id", hitter.getNetworkID());
		blob.Sync("last_poison_owner_id", true);
	}

	if (blob.get_u16("poisoned") == 0) blob.getSprite().PlaySound("SlowOn.ogg", 0.6f * sound_volume, 0.75f + XORRandom(1)/10.0f);
	blob.set_u16("poisoned", poisonTime);
	blob.Sync("poisoned", true);
}

void Confuse( CBlob@ blob, u16 confuseTime )
{	
	blob.set_u16("confused", confuseTime);
	blob.Sync("confused", true);
	blob.getSprite().PlaySound("SlowOn.ogg", 0.8f, 1.0f);
}

void ManaBurn( CBlob@ blob, u16 burnTime )
{	
	blob.set_u16("manaburn", burnTime);
	blob.Sync("manaburn", true);
	blob.getSprite().PlaySound("SlowOn.ogg", 0.8f, 1.15f + XORRandom(1)/10.0f);
}

void HealBlock( CBlob@ blob, u16 hbTime )
{
	blob.set_u16("healblock", hbTime);
	blob.Sync("healblock", true);
	blob.getSprite().PlaySound("SlowOn.ogg", 0.8f, 1.35f + XORRandom(1)/10.0f);
	blob.getSprite().PlaySound("sidewind_init", 0.5f, 0.8f);
}

void Haste( CBlob@ blob, u16 hasteTime )
{	
	if ( blob.get_u16("slowed") > 0 )
	{
		blob.set_u16("slowed", 1);
		blob.Sync("slowed", true);
	}
	else
	{
		blob.set_u16("hastened", hasteTime);
		blob.Sync("hastened", true);
		if(isClient())
		{blob.getSprite().PlaySound("HasteOn.ogg", 0.8f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );}
	}
}

void Regen( CBlob@ blob, u16 regenTime )
{	
	blob.set_u16("regen", regenTime);
	blob.Sync("regen", true);
	blob.getSprite().PlaySound("Heal.ogg", 0.75f, 1.15f + XORRandom(1)/10.0f);
}

void CooldownReduce(CBlob@ blob, u16 time, f32 power)
{	
	blob.set_u16("cdreduction", time);
	blob.Sync("cdreduction", true);

	blob.set_f32("majestyglyph_cd_reduction", glyph_cooldown_reduction);
	blob.Sync("majestyglyph_cd_reduction", true);

	blob.getSprite().PlaySound("negentropySound.ogg", 0.75f, 2.5f + XORRandom(1)/10.0f);
	blob.getSprite().PlaySound("SlowOff.ogg", 0.75f, 1.5f + XORRandom(1)/10.0f);
}

void AntiDebuff(CBlob@ blob, u16 time)
{	
	blob.set_u16("antidebuff", time);
	blob.Sync("antidebuff", true);

	blob.getSprite().PlaySound("PlantShotLaunch.ogg", 1.0f, 1.0f + XORRandom(16)*0.01f);
}

void Sidewind( CBlob@ blob, u16 windTime )
{	
	blob.set_u16("sidewinding", windTime);
	blob.Sync("sidewinding", true);
	if(isClient())
	{blob.getSprite().PlaySound("sidewind_init.ogg", 2.5f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );}
}

void DamageAura(CBlob@ blob, bool enable)
{
	if(isClient())
	{
		if (!blob.get_bool("damageaura"))
			blob.getSprite().PlaySound("PlantShotLaunch.ogg", 4.0f, 0.35f + (0.15f * _spell_common_r.NextFloat()));
		else
			blob.getSprite().PlaySound("sidewind_init.ogg", 0.75f, 1.5f);
	}

	blob.set_u32("damageauratiming", getGameTime());
	blob.set_u32("origindamageauratiming", getGameTime());
	blob.set_bool("damageaura", enable);
}

void ManaToHealth(CBlob@ blob, bool enable)
{
	if(isClient())
	{
		if (!blob.get_bool("manatohealth"))
			blob.getSprite().PlaySound("EnergySound1.ogg", 1.0f, 1.35f + (0.15f * _spell_common_r.NextFloat()));
		else
			blob.getSprite().PlaySound("sidewind_exit.ogg", 0.75f, 1.5f);
	}

	blob.set_u32("manatohealthtiming", getGameTime());
	blob.set_u32("originmanatohealthtiming", getGameTime());
	blob.set_bool("manatohealth", enable);
}

void DamageToMana(CBlob@ blob, bool enable)
{
	if(isClient())
	{
		if (!blob.get_bool("damagetomana"))
			blob.getSprite().PlaySound("EnergySound1.ogg", 1.0f, 1.35f + (0.15f * _spell_common_r.NextFloat()));
		else
			blob.getSprite().PlaySound("sidewind_exit.ogg", 0.75f, 1.5f);
	}

	blob.set_u32("damagetomanatiming", getGameTime());
	blob.set_u32("origindamagetomanatiming", getGameTime());
	blob.set_bool("damagetomana", enable);
}

void Barrier(CBlob@ blob, u16 time, u8 amount)
{
	if(isClient())
	{
		CSprite@ sprite = blob.getSprite();
		
		sprite.PlaySound("Homerun.ogg", 1.15f, 1.75f + (0.05f * _spell_common_r.NextFloat()));
		
		for (u8 i = 0; i < 16; i++)
		{
			string n = "hallowedbarrier_segment"+i;
			CSpriteLayer@ l = sprite.getSpriteLayer(n);
			if (l is null) continue;

			ParticlesFromSprite(l, l.getWorldTranslation(), Vec2f(0, -0.75f).RotateBy(XORRandom(360)), 0, 3);
			sprite.RemoveSpriteLayer(n);
		}
	}

	blob.set_u16("hallowedbarrier", time);
	blob.set_u32("hallowedbarriertiming", getGameTime());
	blob.set_u8("hallowedbarriermax", amount);
	blob.set_u8("hallowedbarrieramount", amount);
	blob.set_bool("hallowedbarrierfacing", blob.isFacingLeft());
}

void AirblastShield( CBlob@ blob, u16 airshieldTime )
{	
	blob.set_u16("airblastShield", airshieldTime);
	blob.Sync("airblastShield", true);
	//if(isClient())
	//{blob.getSprite().PlaySound("sidewind_init.ogg", 2.5f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );}
}
void FireWard( CBlob@ blob, u16 firewardTime )
{	
	blob.set_u16("fireProt", firewardTime);
	blob.Sync("fireProt", true);
	//if(isClient())
	//{blob.getSprite().PlaySound("sidewind_init.ogg", 2.5f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );}
}

void Connect(CBlob@ blob, u16 time, u16 link_id)
{
	blob.set_u16("dmgconnection_id", link_id);
	blob.Sync("dmgconnection_id", true);
	blob.set_u16("dmgconnection", time);
	blob.Sync("dmgconnection", true);

	if (isClient())
	{
		blob.getSprite().PlaySound("shield_create.ogg", 1.15f, 1.5f);
	}
}

void WaterBarrier(CBlob@ blob, bool enable)
{
	blob.set_u32("waterbarriertiming", getGameTime());
	blob.set_u32("originwaterbarrier", getGameTime());
	blob.set_bool("waterbarrier", enable);
	blob.Sync("waterbarrier", true);
}

void Plague(CBlob@ blob, bool enable)
{
	blob.set_u32("plaguetiming", getGameTime());
	blob.set_u32("originplaguetiming", getGameTime());

	blob.set_bool("plague", enable);
	blob.Sync("plague", true);
}

void StoneSkin( CBlob@ blob, u16 stoneskinTime )
{	
	blob.set_u16("stoneSkin", stoneskinTime);
	blob.Sync("stoneSkin", true);
	//if(isClient())
	//{blob.getSprite().PlaySound("sidewind_init.ogg", 2.5f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );}
}

void manaShot( CBlob@ blob, u8 manaUsed, u8 casterMana, bool silent = false, const u8 direct_restore = 0)
{	
	if(blob !is null)
	{
		ManaInfo@ manaInfo;
		if (!blob.get( "manaInfo", @manaInfo )) {return;}

		s32 currentMana = manaInfo.mana;
		s32 maxMana = manaInfo.maxMana;
		s32 manaReg = blob.get_s32("mana regen rate");

		if (direct_restore == 0)
		{
			if(manaReg < 1)
			{
				manaReg = 1;
			}
			float manaEquivalent = manaReg / casterMana;
			s32 manaAmount = manaUsed * manaEquivalent;

			if( (currentMana + manaAmount) > maxMana)
			{
				manaInfo.mana = maxMana;
			}
			else
			{
				manaInfo.mana += manaAmount;
			}
		}
		else
		{
			if( (currentMana + direct_restore) > maxMana)
			{
				manaInfo.mana = maxMana;
			}
			else
			{
				manaInfo.mana += direct_restore;
			}
		}

		if(!silent)
		{
			blob.getSprite().PlaySound("manaShot.ogg", 1.8f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );
		}
	}
}

Random _sprk_r2(12345);
void teleSparks(Vec2f pos, int amount, Vec2f pushVel = Vec2f(0,0))
{
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r2.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r2.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel + pushVel, SColor( 255, 180+XORRandom(40), 0, 255), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r2.NextRanged(20);
        p.scale = 0.5f + _sprk_r2.NextFloat();
        p.damping = 0.95f;
		p.gravity = Vec2f(0,0);
    }
}

u32 getLandHeight(Vec2f pos)
{
	CMap@ map = getMap(); //standard map check
	if(map is null)
	{return 0;}

	u16 tilesdown = 0;
	
	u32 pos_y = pos.y - pos.y % map.tilesize;//Store the y pos floored to the nearest top of a tile
	while(true)//Loop until stopped inside
	{
		if(map.tilemapheight * map.tilesize < pos_y + tilesdown * map.tilesize)//If we are checking below the map itself
		{
			break;
		}
		if(map.isTileSolid(Vec2f(pos.x, pos_y + map.tilesize * tilesdown)))//if this current point has a solid tile
		{
			return(pos_y + tilesdown * map.tilesize);//The current blobs pos plus one or more tiles down
		}
		tilesdown += 1;
	}
	return 0;
}

int closestBlobIndex(CBlob@ this, CBlob@[] blobs, bool friendly)
{
    f32 bestDistance = 99999999;
    int bestIndex = -1;

	if(friendly)
	{
		for(int i = 0; i < blobs.length; i++)
		{
			CBlob@ currentBlob = blobs[i];
    	    if(currentBlob is null || currentBlob is this || currentBlob.getTeamNum() != this.getTeamNum())
			{continue;}

    		//f32 dist = this.getDistanceTo(currentBlob);
			f32 dist = Vec2f( currentBlob.getPosition() - this.getAimPos() ).getLength();
    		if(bestDistance > dist)
    		{
    	    	bestDistance = dist;
    	        bestIndex = i;
    	    }
    	}
	}
	else
	{
		for(int i = 0; i < blobs.length; i++)
		{
			CBlob@ currentBlob = blobs[i];
    	    if(currentBlob is null || currentBlob is this || currentBlob.getTeamNum() == this.getTeamNum())
			{continue;}

    		//f32 dist = this.getDistanceTo(currentBlob);
			f32 dist = Vec2f( currentBlob.getPosition() - this.getAimPos() ).getLength();
    		if(bestDistance > dist)
    		{
    	    	bestDistance = dist;
    	        bestIndex = i;
    	    }
    	}
	}
    
    return bestIndex;
}