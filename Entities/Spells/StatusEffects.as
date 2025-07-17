//Status Effects
#include "RunnerCommon.as"
#include "MagicCommon.as";
#include "SplashWater.as";
#include "TeamColour.as";
#include "PaladinCommon.as";
#include "SpellUtils.as";
#include "EffectsCollection.as";
#include "PaladinCommon.as";

Random _r(94712);

void onTick(CBlob@ this)
{
	if (getGameTime() < 30) return;

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	if (this.get_u32("damage_boost") > getGameTime())
	{
		this.Tag("extra_damage");
	}
	else this.Untag("extra_damage");

	CSprite@ thisSprite = this.getSprite();

	//FREEZE
	bool isFrozen = this.get_bool("frozen");
	bool isInIce = this.isAttachedToPoint("PICKUP2");

	if ( isFrozen && !isInIce )
		this.set_bool("frozen", false);	
	else if ( isInIce )
	{
		this.set_bool("frozen", true);
	
		u16 takekeys;
		takekeys = key_left | key_right | key_up | key_down | key_action1 | key_action2 | key_action3 | key_pickup;

		this.DisableKeys(takekeys);
		this.DisableMouse(true);
	}
	else
	{
		this.DisableKeys(0);
		this.DisableMouse(false);
	}

	//ANTI DEBUFF // requires to be first in order to stop other spells from running in same tick when applied
	u16 antidebuff = this.get_u16("antidebuff");

	if (antidebuff > 0)
	{
		antidebuff--;
		this.set_u16("antidebuff", antidebuff);
		
		if (antidebuff % 2 == 0)
		{
			for (int i = 0; i < 1; i++)
			{		
				if (getNet().isClient()) 
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated("MissileFire8.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, true);
					if (p !is null)
					{
						p.bounce = 0;
    					p.fastcollision = true;
						if (XORRandom(2) == 0)
							p.Z = 10.0f;
						else
							p.Z = -10.0f;
					}
				}
			}
		}

		else if (this.get_u16("slowed") > 0)
		{				
			this.set_u16("slowed", 0);
		}
		else if (this.get_u16("manaburn") > 0)
		{				
			this.set_u16("manaburn", 0);
		}
		else if (this.get_u16("healblock") > 0)
		{				
			this.set_u16("healblock", 0);
		}
		
		if (antidebuff == 0)
		{
			thisSprite.PlaySound("HasteOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("hastened", true);
		}
	}
	
	//SLOW	
	u16 slowed = this.get_u16("slowed");

	if (slowed > 0)
	{
		slowed--;
		this.set_u16("slowed", slowed);
		
		Vec2f thisVel = this.getVelocity();
		this.setVelocity( Vec2f(thisVel.x*0.85f, thisVel.y) );
		
		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if (slowed % 2 == 0)
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated("MissileFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, true);
					if (p !is null)
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
		}
		
		if (slowed == 0)
		{
			thisSprite.PlaySound("SlowOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("slowed", true);
		}
	}

	//WET
	bool waterbarrier = this.get_bool("waterbarrier");
	u16 wet = this.get_u16("wet timer");
	if (waterbarrier || this.isInWater()) wet = wet_renew_time;

	if (wet > 0)
	{
		// decrease burn timer
		if (getGameTime() % 3 == 0 && this.exists("burn timer") && this.get_s16("burn timer") > 0)
		{
			this.sub_s16("burn timer", 1);
		}

		wet--;
		this.set_u16("wet timer", wet);

		if (wet % 2 == 0)
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f(XORRandom(96)-48, XORRandom(64)-32 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated("WaterDrops1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, true);
					if (p !is null)
					{
						p.bounce = 0;
    					p.fastcollision = true;

						if (XORRandom(2) == 0)
							p.Z = 10.0f;
						else
							p.Z = -10.0f;
					}
				}
			}
		}

		if (wet == 0)
		{
			this.Sync("wet timer", true);
		}
	}

	//CONFUSE
	u16 confused = this.get_u16("confused");

	if (confused > 0)
	{
		confused--;
		this.set_u16("confused", confused);

		if (confused % 7 == 0)
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 2.0f;
					Vec2f random = Vec2f(XORRandom(256)-128, XORRandom(256)-128) * 0.015625f * rad;
					f32 angle = 45.0f;

					f32 pangle = angle-XORRandom(angle*2+1);
					CParticle@ p = ParticleAnimated("Confuse1.png", this.getPosition()+random, Vec2f(0,-(2+XORRandom(21)*0.1f)).RotateBy(pangle), pangle, 1.0f, 3+XORRandom(2), 0.2f, true);
					if ( p !is null)
					{
						p.bounce = 0;
    					p.collides = false;
						if (XORRandom(2) == 0)
							p.Z = 10.0f;
						else
							p.Z = -10.0f;

						p.gravity = Vec2f_zero;
						p.damping = 0.9f;
						p.scale = 0.5f + XORRandom(26)*0.01f;
						p.deadeffect = -1;
						p.frame = XORRandom(4);
						p.colour = SColor(255,220+XORRandom(35),25+XORRandom(50),100+XORRandom(50));
						//p.setRenderStyle(RenderStyle::additive);
					}
				}
			}
		}
		
		if (confused == 0)
		{
			this.Sync("confused", true);
		}
	}

	//HEAVY
	u16 heavy = this.get_u16("heavy");

	if (heavy > 0)
	{
		heavy--;
		this.set_u16("heavy", heavy);
		
		Vec2f thisVel = this.getVelocity();
		this.setVelocity( Vec2f(thisVel.x*0.75f, thisVel.y) );
		if (thisVel.y < 0.00f) this.setVelocity(Vec2f(thisVel.x, 0));
		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		
		if ( heavy == 0 )
		{
			this.Sync("heavy", true);
		}
	}
	
	//MANABURN
	u16 manaburn = this.get_u16("manaburn");

	if (manaburn > 0)
	{
		manaburn--;
		this.set_u16("manaburn", manaburn);
		
		Vec2f thisVel = this.getVelocity();
		ManaInfo@ manaInfo;
		if (!this.get( "manaInfo", @manaInfo )) 
		{
			return;
		}
		if (manaInfo.mana > 0 && getGameTime()%15==0) manaInfo.mana -= 1;

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if (manaburn % 2 == 0)
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire5.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, true );
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
		}
		
		if ( manaburn == 0 )
		{
			thisSprite.PlaySound("SlowOff.ogg", 0.8f, 1.1f + XORRandom(1)/10.0f);
			this.Sync("manaburn", true);
		}
	}

	//HEAL BLOCK
	u16 healblock = this.get_u16("healblock");

	if (healblock > 0)
	{
		healblock--;
		this.set_u16("healblock", healblock);
		Vec2f thisVel = this.getVelocity();

		if (isClient())
		{
			CParticle@[] ps;
			this.get("healblock_particles", ps);

			if (healblock % 8 == 0)
			{
				const f32 rad = 6.0f;
				Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;

				CParticle@ p = ParticleAnimated("MissileFire6.png", random, Vec2f(0,0), 0, 1.0f, 1+XORRandom(2), 0.2f, true );
				if (p !is null)
				{
					p.gravity = random;
					p.bounce = 0;
					p.collides = false;
    				p.fastcollision = true;
					p.timeout = 30;

					if ( XORRandom(4) == 0 )
						p.Z = -10.0f;
					else
						p.Z = 10.0f;

					ps.push_back(p);
				}
			}

			for (int i = 0; i < ps.size(); i++)
			{
				CParticle@ p = ps[i];
				if (p is null) continue;
				if (p.timeout < 1)
				{
					ps.erase(i);
					i--;
					continue;
				}

				p.position = this.getPosition() + this.getVelocity() + p.gravity;
			}
			
			this.set("healblock_particles", ps);
		}
		
		if (healblock == 0)
		{
			thisSprite.PlaySound("SlowOff.ogg", 0.8f, 1.33f + XORRandom(1)/10.0f);
			this.Sync("healblock", true);
		}
	}

	//HASTE
	u16 hastened = this.get_u16("hastened");
	if (hastened > 0)
	{
		hastened--;
		this.set_u16("hastened", hastened);
		
		Vec2f thisVel = this.getVelocity();
		moveVars.walkFactor *= 1.5f;
		moveVars.jumpFactor *= 1.1f;		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( hastened % 2 == 0 )
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient()) 
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire3.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, true );
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
		}
		
		if ( hastened == 0 )
		{
			thisSprite.PlaySound("HasteOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("hastened", true);
		}
	}

	//REGEN
	u16 regen = this.get_u16("regen");

	if (regen > 0)
	{
		regen--;
		this.set_u16("regen", regen);
		
		f32 heal_amount = 0.1f;
		if (regen%30==0 && isServer())
		{
			Heal(this, this, heal_amount, false, false, 0.1f);
		}

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( regen % 2 == 0 )
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient()) 
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire4.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, true );
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
		}
		
		if ( regen == 0 )
		{
			thisSprite.PlaySound("HasteOff.ogg", 0.8f, 1.15f + XORRandom(1)/10.0f);
			this.Sync("regen", true);
		}
	}

	//SIDEWIND
	u16 sidewinding = this.get_u16("sidewinding");

	if (sidewinding > 0)
	{
		sidewinding--;
		thisSprite.SetVisible(false);
		this.getShape().getConsts().collidable = false;
		
		Vec2f thisVel = this.getVelocity();
		moveVars.walkFactor *= 2.5f;
		moveVars.jumpFactor *= 2.5f;
		moveVars.swimspeed = 5.0f;
		moveVars.swimforce = 70;		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( sidewinding % 2 == 0 )
		{
			if(isClient()) 
			{
				u16 frame = thisSprite.getFrameIndex();
				bool lookingLeft = thisSprite.isFacingLeft();

				Vec2f pos = this.getPosition() + Vec2f(3,-2);
				string afterimageFile = "afterimages.png";
				#ifdef STAGING
					afterimageFile = "afterimages_staging";
				#endif
				if (lookingLeft)
				{
					afterimageFile = "afterimagesleft.png";
					#ifdef STAGING
						afterimageFile = "afterimagesleft_staging";
					#endif
					pos -= Vec2f(6,0);
				}
				CParticle@ p = ParticleAnimated(afterimageFile, pos, Vec2f_zero, 0, 1.0f, 5, 0.0f, false);
				if ( p !is null)
				{
					p.bounce = 0;
					p.Z = -10.0f;
					p.collides = false;
					p.fastcollision = true;
					p.setRenderStyle(RenderStyle::additive);
				}
			}
		}
		
		if (sidewinding == 0)
		{
			if(isClient())
			{thisSprite.PlaySound("sidewind_exit.ogg", 3.0f, 1.0f + XORRandom(1)/10.0f);}
			this.Sync("sidewinding", true);
			thisSprite.SetVisible(true);
			this.getShape().getConsts().collidable = true;
			moveVars.swimspeed = 1.2f;
			moveVars.swimforce = 30;

			SColor color = SColor(255,255,0,XORRandom(191));
			for(int i = 0; i < 100; i ++)
			{
				Vec2f particleVel = Vec2f( 1.5f ,0).RotateByDegrees(XORRandom(361));
				CParticle@ p = ParticlePixelUnlimited( this.getPosition() , particleVel , color , true );
				if(p !is null)
				{
					p.gravity = Vec2f_zero;
					p.damping = 1.0;
					p.collides = false;
					p.fastcollision = true;
					p.bounce = 0;
					p.lighting = false;
					p.timeout = XORRandom(11) + 5;
				}
			}
		}
		this.set_u16("sidewinding", sidewinding);
	}

	u32 gt = getGameTime();
	//DAMAGE AURA
	{
		bool damageaura = this.get_bool("damageaura");
		u32 origindamageauratiming = this.get_u32("origindamageauratiming");
		u32 damageauratiming = this.get_u32("damageauratiming");
		u32 disabledamageauratiming = this.get_u32("disabledamageauratiming");

		f32 radius = 96.0f;
		u8 ticks_for_disable = 6; // for how long to run disable code

		if (damageaura)
		{
			Vec2f thisVel = this.getVelocity();
			this.set_u32("damageauratiming", gt);

			this.set_bool("disable_dash", true);
			moveVars.walkFactor *= 0.85f;
			moveVars.jumpFactor *= 0.85f;

			//workstate
			if (gt%15==0)
			{
				CBlob@[] bs;
				if (getMap() !is null) getMap().getBlobsInRadius(this.getPosition(), radius, @bs);
				for (u16 i = 0; i < bs.length; i++)
				{
					CBlob@ b = bs[i];
					if (b is null || b.getPlayer() is null || b.getTeamNum() != this.getTeamNum()
						|| b is this || b.getTickSinceCreated() < 90 || b.hasTag("dead") 
						|| b.get_u32("damage_boost") >= gt+30) continue;
					b.set_u32("damage_boost", gt+20);
					b.Sync("damage_boost", true);
				}
			}

			u32 diff = getGameTime() - origindamageauratiming;

			//particles
			if (isClient())
			{
				for (int i = 0; i < 120; i++)
				{
					SColor color = SColor(255,255,25,25);
					Vec2f pbPos = this.getOldPosition() + Vec2f_lengthdir(radius,i*(diff <= 30 ? (-3.0f * diff/30) : 3.0f)).RotateBy(90, Vec2f(0,0));//game time gets rid of some gaps and can add a rotation effect
					CParticle@ pb = ParticlePixelUnlimited( pbPos, this.getVelocity(), color , true );
					if(pb !is null)
					{
						pb.timeout = 0.01f;
						pb.gravity = Vec2f_zero;
						pb.damping = 0.9;
						pb.collides = false;
						pb.fastcollision = true;
						pb.bounce = 0;
						pb.lighting = false;
						pb.Z = 500;
					}
				}
			}
		}
		//disable
	    else if (damageauratiming+ticks_for_disable > gt
			)
		{
			for(int i = 0; i < 120; i++)
			{
				SColor color = SColor(255,255,25,25);
				Vec2f pbPos = this.getOldPosition() + Vec2f_lengthdir(radius,i*3);//game time gets rid of some gaps and can add a rotation effect
				CParticle@ pb = ParticlePixelUnlimited(pbPos, this.getVelocity()+Vec2f((pbPos-this.getPosition())*0.1f), color , true);
				if(pb !is null)
				{
					u8 time = i%4 * 2.5f;
					pb.timeout = 32.5f+time;
					pb.gravity = Vec2f_zero;
					pb.damping = 0.9;
					pb.collides = false;
					pb.fastcollision = true;
					pb.bounce = 0;
					pb.lighting = false;
					pb.Z = 500;
				}
			}
		}
	}

	//MANA TO HEALTH; visuals only, look at Regens.as for logic
	{
		bool manatohealth = this.get_bool("manatohealth");
		u32 originmanatohealthtiming = this.get_u32("originmanatohealthtiming");
		u32 manatohealthtiming = this.get_u32("manatohealthtiming");
		u32 disablemanatohealthtiming = this.get_u32("disablemanatohealthtiming");

		u8 ticks_for_disable = 1; // for how long to run disable code

		// particles
		f32 amount = 31;
		f32 sum = 0;
		f32 h = 16;

		if (manatohealth)
		{
			Vec2f thisVel = this.getVelocity();
			this.set_u32("manatohealthtiming", gt);
			u32 diff = getGameTime() - originmanatohealthtiming;

			//particles
			if (isClient())
			{
				for (int i = 0; i < amount; i++)
				{
					f32 val = Maths::Abs(Maths::Sin(gt * (i%3) * 0.1f))*4;
					sum += val;

					Vec2f pbPos = this.getOldPosition() - Vec2f(0,h) + Vec2f(val, 0).RotateBy(360/amount*i);

					u8 rnd = XORRandom(75);
					SColor color = SColor(255,255,25+rnd,25+rnd);

					CParticle@ pb = ParticlePixelUnlimited(pbPos, this.getVelocity(), color , true);
					if(pb !is null)
					{
						pb.timeout = 0.01f;
						pb.gravity = Vec2f_zero;
						pb.collides = false;
						pb.fastcollision = true;
						pb.bounce = 0;
						pb.lighting = false;
						pb.Z = 500;
					}
				}
				if (sum <= 8)
				{
					f32 angle = 67.5f;
					for (u8 i = 0; i < amount; i++)
					{
						Vec2f pbPos = this.getOldPosition() - Vec2f(0,h);
						Vec2f vel = Vec2f(XORRandom(5)-2,XORRandom(3)-1).RotateBy((XORRandom(10.0f * angle)-(10.0f * angle)/2) / 10);
						u8 rnd = XORRandom(75);
						SColor color = SColor(255,255,25+rnd,25+rnd);

						CParticle@ pb = ParticlePixelUnlimited(pbPos, vel, color , true);
						if(pb !is null)
						{
							pb.timeout = 20-vel.Length()*3 + XORRandom(6);
							pb.gravity = Vec2f(0,0.15f);
							pb.collides = false;
							pb.damping = 0.85f;
							pb.fastcollision = true;
							pb.bounce = 0;
							pb.lighting = false;
							pb.Z = 0;
						}
					}
				}
			}
		}
		//disable
	    else if (manatohealthtiming+ticks_for_disable+1 > gt)
		{
			for (int i = 0; i < amount*2; i++)
			{
				Vec2f pbPos = this.getOldPosition() - Vec2f(0,h);
				u8 rnd = XORRandom(55);
				SColor color = SColor(255,255,25+rnd,25+rnd);
				
				CParticle@ pb = ParticlePixelUnlimited(pbPos, Vec2f(4+XORRandom(2), 0).RotateBy(XORRandom(360)), color, true);
				if(pb !is null)
				{
					pb.timeout = 15+XORRandom(16);
					pb.collides = true;
					pb.gravity = Vec2f(0,0.5f);
					pb.damping = 0.85f;
					pb.fastcollision = true;
					pb.bounce = 0;
					pb.lighting = false;
					pb.Z = 500;
				}
			}
		}
	}

	//DAMAGE TO MANA
	{
		bool damagetomana = this.get_bool("damagetomana");
		u32 origindamagetomanatiming = this.get_u32("origindamagetomanatiming");
		u32 damagetomanatiming = this.get_u32("damagetomanatiming");
		u32 disabledamagetomanatiming = this.get_u32("disabledamagetomanatiming");
		u8 ticks_for_disable = 1; // for how long to run disable code

		Vec2f thisPos = this.getPosition();
		Vec2f thisVel = this.getVelocity();
		int teamNum = this.getTeamNum();
		u32 diff = getGameTime() - origindamagetomanatiming;

		if (damagetomana)
		{
			this.set_u32("damagetomanatiming", gt);

			CMap@ map = getMap();
			CBlob@[] enemiesInRadius;
			map.getBlobsInRadius(thisPos, aura_omega_radius, @enemiesInRadius);
			for (uint i = 0; i < enemiesInRadius.length; i++)
			{
				CBlob@ b = enemiesInRadius[i];
				if (b is null)
				{ continue; }

				if (b.getTeamNum() == teamNum)
				{ continue; }

				if (!b.hasTag("hull") && !b.hasTag("flesh") && !b.hasTag("counterable"))
				{ continue; }

				if (b.hasTag("dead")) continue;

				bool isZombie = b.hasTag("zombie");

				Vec2f blobPos = b.getPosition();
				Vec2f kickDir = blobPos - thisPos;
				kickDir.Normalize();
			}
			
			u16 particleNum = v_fastrender ? 15 : 40;
			SColor color = getTeamColor(teamNum);

			for(int i = 0; i < particleNum; i++)
    		{
				u8 alpha = 40 + (170.0f * _r.NextFloat()); //randomize alpha
				color.setAlpha(alpha);

				f32 randomDeviation = (i*0.3f) * _r.NextFloat(); //random pixel deviation
				Vec2f prePos = Vec2f(aura_omega_radius - randomDeviation, 0); //distance
				prePos.RotateByDegrees(360.0f * _r.NextFloat()); //random 360 rotation

				Vec2f pPos = thisPos + prePos;
				Vec2f pGrav = -prePos * 0.005f; //particle gravity

				prePos.Normalize();
				prePos *= 2.0f;

    		    CParticle@ p = ParticlePixelUnlimited(pPos, prePos, color, true);
    		    if(p !is null)
    		    {
    		        p.collides = false;
    		        p.gravity = pGrav;
    		        p.bounce = 0;
    		        p.Z = 7;
    		        p.timeout = 12;
					p.setRenderStyle(RenderStyle::light);
    		    }
    		}
		}
	}

	// COOLDOWN REDUCTION
	u16 cdreduction = this.get_u16("cdreduction");

	if (cdreduction > 0)
	{
		cdreduction--;
		this.set_u16("cdreduction", cdreduction);
		
		if (isClient())
		{
			CParticle@[] ps;
			this.get("cdreduction_particles", ps);

			if (cdreduction % 5 == 0)
			{
				const f32 rad = 6.0f;
				Vec2f random = Vec2f(XORRandom(150)-75, XORRandom(150)-75 ) * 0.015625f * rad;
				
				CParticle@ p = ParticleAnimated("MissileFire7.png", random, Vec2f(0,0), -random.Angle()+90, 1.0f, 1+XORRandom(2), 0.2f, true);
				if (p !is null)
				{
					p.gravity = random; // i really enjoy it works
					p.bounce = 0;
    				p.fastcollision = true;
					p.collides = false;
					p.timeout = 30;
					p.Z = 10.0f;

					ps.push_back(p);
				}
			}

			for (int i = 0; i < ps.size(); i++)
			{
				CParticle@ p = ps[i];
				if (p is null) continue;
				if (p.timeout < 1)
				{
					ps.erase(i);
					i--;
					continue;
				}

				p.position = this.getPosition() + this.getVelocity() + p.gravity;
			}
			
			this.set("cdreduction_particles", ps);
		}
		
		if (cdreduction == 0)
		{
			this.set_f32("majestyglyph_cd_reduction", 1.0f);
			
			thisSprite.PlaySound("HasteOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("cdreduction", true);
		}
	}

	//STUN
	u16 stunned = this.get_u16("stunned");
	if (stunned > 0)
	{
		stunned--;

		//this.DisableMouse(true);
		u16 takekeys;
		takekeys = key_action1 | key_action2 | key_action3 | key_taunts;
		this.DisableKeys(takekeys);

		if ( stunned == 0 )
		{
			//this.DisableMouse(false);
			this.DisableKeys(0);
		}
		this.set_u16("stunned", stunned);
	}

	//AIRBLAST SHIELD
	u16 airblastShield = this.get_u16("airblastShield");
	if (airblastShield > 0)
	{
		airblastShield--;
		if(!this.hasScript("Wards.as"))
		{
			thisSprite.PlaySound("Airblast.ogg", 1.0f, 1.0f + XORRandom(1)/10.0f);
			this.AddScript("Wards.as");
		}

		if(!this.exists("airblastSetupDone") || !this.get_bool("airblastSetupDone")) //Ward sprite setup
		{
			CSpriteLayer@ layer = thisSprite.addSpriteLayer("airblast_ward","Airblast Ward.png",25,25);
			if (layer !is null)
			{
				layer.SetRelativeZ(-5.4f);
			}
			this.set_bool("airblastSetupDone",true);
		}

		if (thisSprite.getSpriteLayer("airblast_ward") !is null)
		{
			CSpriteLayer@ layer = thisSprite.getSpriteLayer("airblast_ward");
			if (layer !is null)
			{
				layer.RotateBy(-0.5f, Vec2f(0,0));
			}
		}

		if(airblastShield == 0)
		{
			if(this.hasScript("Wards.as"))
			{
				this.RemoveScript("Wards.as");
			}
			thisSprite.RemoveSpriteLayer("airblast_ward"); //Ward sprite removal
			this.set_bool("airblastSetupDone",false);
		}

		this.set_u16("airblastShield", airblastShield);
	}

	//FIRE WARD
	u16 fireProt = this.get_u16("fireProt");
	if (fireProt > 0)
	{
		fireProt--;

		if(!this.hasScript("Wards.as"))
		{
			thisSprite.PlaySound("Airblast.ogg", 1.0f, 1.0f + XORRandom(1)/10.0f);
			this.AddScript("Wards.as");
		}

		if(!this.exists("fireprotSetupDone") || !this.get_bool("fireprotSetupDone")) //Ward sprite setup
		{
			CSpriteLayer@ layer = thisSprite.addSpriteLayer("fire_ward","Fire Ward.png",25,25);
			if (layer !is null)
			{
				layer.SetRelativeZ(-5.5f);
			}
			this.set_bool("fireprotSetupDone",true);
		}

		if (thisSprite.getSpriteLayer("fire_ward") !is null)
		{
			CSpriteLayer@ layer = thisSprite.getSpriteLayer("fire_ward");
			if (layer !is null)
			{
				layer.RotateBy(-0.5f, Vec2f(0,0));
			}
		}
		
		if (fireProt == 0)
		{
			thisSprite.PlaySound("SlowOff.ogg", 0.8f, 1.1f + XORRandom(1)/10.0f);
			thisSprite.RemoveSpriteLayer("fire_ward"); //Ward sprite removal
			this.set_bool("fireprotSetupDone",false);
		}

		this.set_u16("fireProt", fireProt);
	}

	//WATER BARRIER
	{
		// bool is at wet effect
		u32 originwaterbarriertiming = this.get_u32("originwaterbarriertiming");
		u32 waterbarriertiming = this.get_u32("waterbarrieriming");
		u32 disablewaterbarriertiming = this.get_u32("disablewaterbarriertiming");

		u8 ticks_for_disable = 1; // for how long to run disable code

		if (waterbarrier)
		{
			if (!this.hasScript("WaterBarrierWard.as"))
			{
				this.AddScript("WaterBarrierWard.as");
			}
			
			CSpriteLayer@ layer = thisSprite.getSpriteLayer("water_ward");
			if (layer is null)
			{
				@layer = thisSprite.addSpriteLayer("water_ward","WaterBarrier.png",64,64);
				if (layer !is null)
				{
					layer.SetRelativeZ(565.75f);
					layer.ScaleBy(Vec2f(1.33f,1.33f));
					layer.setRenderStyle(RenderStyle::light);
				}
			}
			if (layer !is null)
			{
				layer.SetVisible(true);
				layer.SetFacingLeft(false);
				layer.RotateBy(2, Vec2f_zero);
				//layer.setRenderStyle(RenderStyle::light);
			}
		}
		//disable
	    else if (this.hasScript("WaterBarrierWard.as"))
		{
			thisSprite.PlaySound("SplashFast.ogg", 1.25f, 0.9f);
			thisSprite.PlaySound("SplashSlow.ogg", 1.25f, 0.9f);
			Splash(this, 4, 4, 0, false);

			thisSprite.RemoveSpriteLayer("water_ward"); //Ward sprite removal
			this.RemoveScript("WaterBarrierWard.as");
		}
	}

	//DAMAGE CONNECTION
	u16 dmgconnection = this.get_u16("dmgconnection");
	if (dmgconnection > 0)
	{
		dmgconnection--;

		if(!this.hasScript("Wards.as"))
			this.AddScript("Wards.as");

		f32 narrow_center = (Maths::Sin(this.getTickSinceCreated() * 0.05f) + 8.0f) * 0.125f;
		f32 narrow_top = 	0.0f + narrow_center * 0.1f;
		f32 narrow_bottom = 0.0f + narrow_center * 0.1f;

		f32 sin = (Maths::Sin(getGameTime() * 0.1f) + 1.0f) * 0.5f;
		f32 lasthit_mod_old = this.get_f32("lasthit_mod");
		int t = 60;
		f32 diff = Maths::Clamp(float(getGameTime() - this.get_u32("dmgconnection_lasthit")) / t, 0.0f, 1.0f);
		f32 lasthit_mod = Maths::Sin(diff * Maths::Pi); // Peaks at 1 when diff = 0.5 (t/2) and 0 at 0 or 1 (t)
		this.set_f32("lasthit_mod", lasthit_mod);
		
		CBlob@ caster = getBlobByNetworkID(this.get_u16("dmgconnection_id"));
		bool is_caster_null = caster is null || caster.hasTag("dead");
		bool can_transfer = !is_caster_null && caster.getHealth() / caster.getInitialHealth() > min_connection_health_ratio;
		f32 height_mod = can_transfer ? 1 : 0.33f;

		makeSineSparks(this.getPosition(), 50 + sin*50 + lasthit_mod*50, 28 + 12 * lasthit_mod, height_mod * (24 + 12 * lasthit_mod),
			SColor(255, 255, 255, XORRandom(155)), narrow_top, narrow_bottom, narrow_center, 1.25f,
				1.0f, 2 + 4*sin + 6*lasthit_mod, SineStyle::easein, getSineSeed(this.getNetworkID()),
					can_transfer ? caster.getPosition() : Vec2f_zero, connection_dist);

		if (dmgconnection == 0 || this.hasTag("dead"))
		{
			dmgconnection = 0;
			this.set_bool("dmgconnectionSetupDone", false);
		}

		this.set_u16("dmgconnection", dmgconnection);
	}
	if (dmgconnection == 0)
	{
		this.set_u16("dmgconnection_id", 0);
	}

	u16 hallowedbarrier = this.get_u16("hallowedbarrier");
	if (hallowedbarrier > 0)
	{
    	u8 amount = this.get_u8("hallowedbarrieramount");
		hallowedbarrier--;

		if (hallowedbarrier == 0 || amount == 0 || this.hasTag("dead"))
		{
			u8 amount = this.get_u8("hallowedbarriermax");
			CSprite@ sprite = this.getSprite();
			if (isClient())
			{
				for (u8 i = 0; i < 16; i++)
				{
					string n = "hallowedbarrier_segment"+i;
					CSpriteLayer@ l = sprite.getSpriteLayer(n);
					if (l is null) continue;

					ParticlesFromSprite(l, l.getWorldTranslation(), Vec2f(0, -0.75f).RotateBy(XORRandom(360)), 0, 3);
					sprite.RemoveSpriteLayer(n);
				}
			}
			sprite.PlaySound("Zap1.ogg", 0.5f, 1.5f);
			hallowedbarrier = 0;
			this.set_u32("hallowedbarriertiming", 0);
			this.set_bool("hallowedbarrieractive", false);
		}

		this.set_u16("hallowedbarrier", hallowedbarrier);
	}

	//STONE SKIN
	/*u16 stoneSkin = this.get_u16("stoneSkin");
	if (stoneSkin > 0)
	{
		stoneSkin--;
		if(!this.hasScript("Wards.as"))
		{
			thisSprite.PlaySound("Airblast.ogg", 1.0f, 1.0f + XORRandom(1)/10.0f);
			this.AddScript("Wards.as");
		}

		if(!this.exists("stoneSkinSetupDone") || !this.get_bool("stoneSkinSetupDone")) //Ward sprite setup
		{
			CSpriteLayer@ layer = thisSprite.addSpriteLayer("stoneskin_ward","Stoneskin Ward.png",25,25);
			layer.SetRelativeZ(-1);
			this.set_bool("stoneSkinSetupDone",true);
		}

		if(stoneSkin == 0 )
		{
			stoneSkin = 0;
			if(this.hasScript("Wards.as") && this.get_u16("airblastShield") == 0)
			{
				this.RemoveScript("Wards.as");
			}
			thisSprite.RemoveSpriteLayer("stoneskin_ward"); //Ward sprite removal
			this.set_bool("stoneSkinSetupDone",false);
		}

		this.set_u16("stoneSkin", stoneSkin);
	}
	*/
}