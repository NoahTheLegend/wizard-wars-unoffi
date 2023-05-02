//Status Effects
#include "RunnerCommon.as"
#include "MagicCommon.as";
#include "SplashWater.as";

void onTick( CBlob@ this)
{
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
	
	//SLOW	
	u16 slowed = this.get_u16("slowed");

	if (slowed > 0)
	{
		slowed--;
		this.set_u16("slowed", slowed);
		
		Vec2f thisVel = this.getVelocity();
		this.setVelocity( Vec2f(thisVel.x*0.85f, thisVel.y) );
		

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( slowed % 2 == 0 )
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire1.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, false );
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
		
		if ( slowed == 0 )
		{
			thisSprite.PlaySound("SlowOff.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
			this.Sync("slowed", true);
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
		if (getGameTime()%8==0) manaInfo.mana -= 1;

		//makeSmokeParticle(this, Vec2f(), "Smoke");
		if ( manaburn % 2 == 0 )
		{
			for (int i = 0; i < 1; i++)
			{		
				if(getNet().isClient())
				{
					const f32 rad = 6.0f;
					Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
					CParticle@ p = ParticleAnimated( "MissileFire5.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, false );
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
					CParticle@ p = ParticleAnimated( "MissileFire3.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, false );
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
		
		f32 heal_amount = 0.15f;
		if (regen%30==0 && isServer())
		{
			if (this.getHealth() + heal_amount < this.getInitialHealth())
				this.server_Heal(heal_amount);
			else (this.server_SetHealth(this.getInitialHealth()));
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
					CParticle@ p = ParticleAnimated( "MissileFire4.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.2f, false );
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
				if (lookingLeft)
				{
					afterimageFile = "afterimagesleft.png";
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
		
		if ( sidewinding == 0 )
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
				CParticle@ p = ParticlePixelUnlimited( this.getPosition() , particleVel , color , false );
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

	//DAMAGE AURA
	u16 damageaura = this.get_u16("damageaura");
	u32 damageauratiming = this.get_u32("damageauratiming");

	if (damageaura > 0)
	{
		damageaura--;
		Vec2f thisVel = this.getVelocity();

		this.set_bool("dashing", true); // disable dash
		moveVars.walkFactor *= 0.75f;
		moveVars.jumpFactor *= 0.75f;

		u32 diff = getGameTime() - damageauratiming;

		if (getGameTime()%15==0)
		{
			CBlob@[] bs;
			if (getMap() !is null) getMap().getBlobsInRadius(this.getPosition(), 64.0f, @bs);
			for (u16 i = 0; i < bs.length; i++)
			{
				CBlob@ b = bs[i];
				if (b is null || b.getPlayer() is null || b.getTeamNum() != this.getTeamNum() || b is this || b.getTickSinceCreated() < 90 || b.hasTag("dead")) continue;
				b.set_u32("damage_boost", getGameTime()+20);
				b.Sync("damage_boost", true);
			}
		}

		if (isClient())
		{
			{
				for(int i = 0; i < 120; i++)
				{
					SColor color = SColor(255,255,25,25);
					Vec2f pbPos = this.getOldPosition() + Vec2f_lengthdir(64.0f,i*(diff <= 30 ? (-3.0f * diff/30) : 3.0f)).RotateBy(90, Vec2f(0,0));//game time gets rid of some gaps and can add a rotation effect
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
		
		if (damageaura == 1)
		{
			this.Sync("damageaura", true);
			if(isClient())
			{this.getSprite().PlaySound("sidewind_init.ogg", 0.75f, 1.5f);}

			{
				for(int i = 0; i < 120; i++)
				{
					SColor color = SColor(255,255,25,25);
					Vec2f pbPos = this.getOldPosition() + Vec2f_lengthdir(64.0f,i*3);//game time gets rid of some gaps and can add a rotation effect
					CParticle@ pb = ParticlePixelUnlimited( pbPos, this.getVelocity()+Vec2f((pbPos-this.getPosition())*0.1f), color , true );
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
		this.set_u16("damageaura", damageaura);
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
	u16 water = this.get_u16("waterbarrier");
	if (water > 0)
	{
		water--;
		if(!this.hasScript("Wards.as"))
		{
			this.AddScript("Wards.as");
		}

		if(!this.exists("waterSetupDone") || !this.get_bool("waterSetupDone")) //Ward sprite setup
		{
			CSpriteLayer@ layer = thisSprite.addSpriteLayer("water_ward","WaterBarrier.png",64,64);
			if (layer !is null)
			{
				layer.SetRelativeZ(-5.75f);
				layer.ScaleBy(Vec2f(1.33f,1.33f));
				layer.setRenderStyle(RenderStyle::additive);
			}
			this.set_bool("waterSetupDone",true);
		}

		if (thisSprite.getSpriteLayer("water_ward") !is null)
		{
			CSpriteLayer@ layer = thisSprite.getSpriteLayer("water_ward");
			if (layer !is null)
			{
				layer.SetFacingLeft(false);
				layer.RotateBy(Maths::Sin(getGameTime()*0.1f)*1.5f, Vec2f(0,0));
				layer.setRenderStyle(RenderStyle::additive);
			}
		}

		if(water == 0)
		{
			water = 0;
			if(this.hasScript("Wards.as"))
			{
				this.RemoveScript("Wards.as");
			}
			thisSprite.PlaySound("SplashFast.ogg", 1.25f, 0.9f);
			thisSprite.PlaySound("SplashSlow.ogg", 1.25f, 0.9f);
			Splash(this, 4, 4, 0, false);
			thisSprite.RemoveSpriteLayer("water_ward"); //Ward sprite removal
			this.set_bool("waterSetupDone",false);
		}

		this.set_u16("waterbarrier", water);
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