//Spells Common
#include "MagicCommon.as";
#include "NecromancerCommon.as";
#include "Hitters.as";
#include "PlayerPrefsCommon.as";
#include "SpellHashDecoder.as";
#include "EffectMissileEnum.as";

const int minimum_cast = NecromancerParams::cast_1;
const int medium_cast = NecromancerParams::cast_2;
const int complete_cast = NecromancerParams::cast_3;
const int super_cast = NecromancerParams::extra_ready;
const float necro_shoot_speed = NecromancerParams::shoot_max_vel;

Random _spell_common_r(26784);

void CastSpell(CBlob@ this, const s8 charge_state, const Spell spell, Vec2f aimpos , Vec2f thispos)
{	//To get a spell hash to add more spells type this in the console (press home in game)
	//print('cfg_name'.getHash()+'');
	//As an example with the meteor spell, i'd type out
	//print('meteor_strike'.getHash()+'');
	//then add whatever case with the hash

	/* Standard spell damage procedure
		f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
		f32 orbDamage = X.Xf * extraDamage;
	*/

	if(isClient())
	{
		this.set_u16("focus", 0);
	}

	CMap@ map = getMap();
	CPlayer@ player = this.getPlayer();

    string spellName = spell.typeName;

	Vec2f castPos = this.getPosition();
	Vec2f aimVector = aimpos - castPos;
	Vec2f aimNorm = aimVector;
	aimNorm.Normalize();
	aimVector -= aimNorm*4;
	aimpos -= aimNorm*4;

	f32 aim_angle = aimVector.Angle();

	switch(spellName.getHash())
	{
		case 1476886618:
		{
			if(isServer())
			{
			Vec2f aim = aimpos;
			Vec2f vel = aim - thispos;
			Vec2f norm = vel;
			norm.Normalize();
			CBlob@ b = server_CreateBlob('boulder',this.getTeamNum(),thispos + norm*2);
			b.server_SetHealth(999);
			b.server_SetTimeToDie(3);
			b.setVelocity(vel/32);
			b.getShape().SetGravityScale(0.75);
			b.server_setTeamNum(b.getTeamNum());
			b.SetDamageOwnerPlayer(this.getPlayer());
			}
		}
		break;
		
		case -825046729: //mushroom
		{

			CBlob@[] mushrooms;
			getBlobsByName("mushroom",@mushrooms);

			if (this.getPlayer() is null)
			{return;}

			CBlob@ mushroom1 = null;
			CBlob@ mushroom2 = null;

			for(int i = 0; i < mushrooms.length; i++)
			{
				if (mushrooms[i] is null)
				{continue;}
				if (mushrooms[i].getDamageOwnerPlayer() is null)
				{continue;}
				if(mushrooms[i].getDamageOwnerPlayer().getNetworkID() == this.getPlayer().getNetworkID())
				{
					if (mushroom1 is null) @mushroom1 = @mushrooms[i];
					else if (mushroom2 is null) @mushroom2 = @mushrooms[i];
					
					if (mushroom1 !is null && mushroom2 !is null)
					{
						mushroom1.server_Die();
						break;
					}
				}
			}

			int height = getLandHeight(aimpos);
			if(height != 0)
			{
				if(isServer())
				{
					CBlob@ mush = server_CreateBlob("mushroom",this.getTeamNum(),Vec2f(aimpos.x,height) );
					mush.SetDamageOwnerPlayer(this.getPlayer());
					mush.set_s32("aliveTime",charge_state == 5 ? 1200 : 900); //if full charge last longer
				}
			}
			else
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
			}
		}
		break;

		case 1538155802: //vinetrap
		{
			int height = getLandHeight(aimpos);
			if(height != 0)
			{
				if(isServer())
				{
					CBlob@ mush = server_CreateBlob("vinetrap",this.getTeamNum(),Vec2f(aimpos.x,height) );
					mush.SetDamageOwnerPlayer(this.getPlayer());
					u8 ttd;

					switch (charge_state)
					{
						case 1:
						case 2:
						{
							ttd = 10;
							mush.set_s32("aliveTime", 180);
							break;
						}
						case 3:
						{
							ttd = 15;
							mush.set_s32("aliveTime", 180);
							break;
						}
						case 4:
						{
							ttd = 20;
							mush.set_s32("aliveTime", 240);
							break;
						}
						case 5:
						{
							mush.set_s32("aliveTime", 300);
							ttd = 30;
							break;
						}
					}

					mush.server_SetTimeToDie(ttd);
				}
			}
			else
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
			}
		}
		break;

		case -726215270: //vinewaver
		{
			if (!isServer()){
           		return;
			}

			bool extraDamage = this.hasTag("extra_damage");

			f32 orbspeed = 3.0f;
			f32 orbDamage = 0.4f + (extraDamage ? 0.2f : 0);

			Vec2f orbPos = thispos;
			Vec2f orbVel = (aimpos - this.getPosition());
			bool spawn_second = false;
			f32 ttd = extraDamage ? 5.0f : 3.0f;
            
			switch(charge_state)
			{
				case super_cast:
				{
					orbspeed = 3.0f;
					spawn_second = true;
					ttd += 1.0f;
				}
				break;

				default: break;
			}

			orbVel.Normalize();
			orbVel *= orbspeed;
			Vec2f offset = spawn_second ? Vec2f(0,8).RotateBy(-aim_angle) : Vec2f_zero;

			{
				CBlob@ orb = server_CreateBlobNoInit("vinewaver");
				if (orb !is null)
				{
					orb.Init();

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.server_setTeamNum(this.getTeamNum());
					orb.setPosition(orbPos-offset);
					orb.setVelocity(orbVel);
					orb.server_SetTimeToDie(ttd);

					orb.setAngleDegrees(-orbVel.Angle());
					orb.set_Vec2f("initvel", orbVel);
					orb.set_f32("dmg", orbDamage);
				}
			}
			if (spawn_second)
			{
				CBlob@ orb = server_CreateBlobNoInit("vinewaver");
				if (orb !is null)
				{
					orb.Init();
					orb.set_bool("back", true);

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.server_setTeamNum(this.getTeamNum());
					orb.setPosition(orbPos+offset);
					orb.setVelocity(orbVel);
					orb.server_SetTimeToDie(ttd);

					orb.setAngleDegrees(-orbVel.Angle());
					orb.set_Vec2f("initvel", orbVel);
					orb.set_f32("dmg", orbDamage);
				}
			}
		}
		break;
		
		case 1299162377://boulder_throw
		{
			this.getSprite().PlaySound("Rubble" + (XORRandom(2) + 1) + ".ogg", 1.25f, 1.1f);
			this.getSprite().PlaySound("rock_hit3.ogg", 1.25f, 0.85f);

			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 1.0f * extraDamage;
            
			switch(charge_state)
			{
				case minimum_cast:
				{
					orbspeed *= (1.0f/2.0f);
					orbDamage *= 0.5f;
				}
				break;

				case medium_cast:
				{
					orbspeed *= (4.0f/5.0f);
					orbDamage *= 0.7f;
				}
				break;

				case complete_cast:
				{
					orbDamage *= 1.0f;
				}
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage *= 1.5f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-4.0f);	

			CBlob@ orb = server_CreateBlob( "boulder" );
			if (orb !is null)
			{
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				Vec2f vec = aimNorm.RotateBy(this.isFacingLeft()?5.0f:-5.0f)*1000.0f;
				orb.AddForce(Vec2f(vec.x + (this.getVelocity().x*50), vec.y + (this.getVelocity().y*50)));
				orb.server_SetTimeToDie(10.0f);
			}
		}
		break;

		case -1727909596: //arcane_circle
			if(isServer())
			{
				CBlob@ circle = server_CreateBlob('arcane_circle',this.getTeamNum(),aimpos);
				circle.SetDamageOwnerPlayer(this.getPlayer());
				circle.set_s32("aliveTime",charge_state == 5 ? 1350 : 900);
			}
		break;
		case 750462252: //mana_drain_circle
		if(isServer())
		{
			CBlob@ circle = server_CreateBlob("mana_drain_circle",this.getTeamNum(),aimpos);
			circle.set_s32("aliveTime",charge_state == 5 ? 1350 : 900);
		}
		break;

		case -1625426670: //orb
		{
			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 1.0f * extraDamage;
            
			switch(charge_state)
			{
				case minimum_cast:
				{
					orbspeed *= (1.0f/2.0f);
					orbDamage *= 0.5f;
				}
				break;

				case medium_cast:
				{
					orbspeed *= (4.0f/5.0f);
					orbDamage *= 0.7f;
				}
				break;

				case complete_cast:
				{
					orbDamage *= 1.0f;
				}
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage *= 1.5f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "orb" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 1463630946://spikeorb
		{
			if (!isServer()){
           		return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 0.2f : 0.0f;
			f32 orbDamage = 0.2f + extraDamage;
			f32 orbspeed = necro_shoot_speed / 2;

			switch(charge_state)
			{
				case complete_cast:
				break;
				case super_cast:
				{
					orbspeed *= 1.5f;
					orbDamage += 0.2f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "spikeorb" );
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 829656850: //sporeshot
		{
			if (!isServer()){
           		return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbspeed = necro_shoot_speed;
			f32 orbDamage = 0.4f * extraDamage;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 0.5f;
					orbDamage *= 1.0f;
				}
				break;

				case super_cast:
				{
					orbspeed *= 1.0f;
					orbDamage *= 2.0f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "sporeshot" );
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case -377943487: //forceorb
		{
			if (!isServer())
				return;

			f32 orbspeed = necro_shoot_speed;
			f32 orbDamage = 0.0f;

			if (charge_state == NecromancerParams::cast_1) {
				orbspeed *= (1.0f/2.0f);
				orbDamage *= 0.0f;
			}
			else if (charge_state == NecromancerParams::cast_2) {
				orbspeed *= (4.0f/5.0f);
				orbDamage *= 0.0f;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				orbDamage *= 0.0f;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "forceorb" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 2016613317://firebomb
		{
			if (!isServer()){
           		return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbspeed = necro_shoot_speed*0.75f;
			f32 orbDamage = 2.0f * extraDamage;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					orbDamage *= 1.0f;
				}
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage *= 1.5f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "firebomb" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 1174066691://fire_sprite
		{
			if(!isServer()){
				return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 1.2f * extraDamage;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbDamage *= 1.0f;
				}
				break;

				case super_cast:
				{
					orbDamage *= 1.5f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= 2;

			CBlob@ orb = server_CreateBlob( "fire_sprite" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);
				orb.set_Vec2f("aimpos", aimpos);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 18140583://frost_ball
		{
			if (!isServer())
			{return;}

			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbspeed = 6.0f;
			f32 orbDamage = 1.0f * extraDamage;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage += 0.4f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			//power of spell determined by caster's health
			f32 initialHealth = this.getInitialHealth();
			f32 health = this.getHealth();
			f32 freezePower = 1.0f - (health/initialHealth);

			CBlob@ orb = server_CreateBlob( "frost_ball" );
			if (orb !is null)
			{
				orb.set_f32("freeze_power", freezePower);
				orb.set_f32("damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 979982427://heal
		{
			f32 orbspeed = 4.0f;
			f32 healAmount = 0.4f;

			switch(charge_state)
			{
				case minimum_cast:
				{
					orbspeed *= 0.5f;
				}
				break;

				case medium_cast:
				{
					orbspeed *= 0.8f;
					healAmount = 0.6f;
				}
				break;

				case complete_cast:
				{
					orbspeed *= 1.0f;
					healAmount = 0.8f;
				}
				break;

				case super_cast:
				{
					Heal(this, healAmount);
					return;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", heal_effect_missile);
					orb.set_f32("heal_amount", healAmount);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 1961711901://nature's helpers
		{
			f32 orbspeed = 5.0f;
			f32 healAmount = 0.2f;
			int numOrbs = 8;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
				}
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					numOrbs += 4;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				for (int i = 0; i < numOrbs; i++)
				{
					CBlob@ orb = server_CreateBlob( "bee", this.getTeamNum(), orbPos ); 
					if (orb !is null)
					{
						orb.set_f32("heal_amount", healAmount);

						orb.IgnoreCollisionWhileOverlapped( this );
						orb.SetDamageOwnerPlayer( this.getPlayer() );
						Vec2f newVel = orbVel;
						newVel.RotateBy( -10 + 3*i, Vec2f());
						orb.setVelocity( newVel );
					}
				}
			}
		}
		break;

		case -456270322://counter_spell
		{
			counterSpell(this, aimpos, thispos);
		}
		break;

		case -1214504009://magic_missile
		{
			f32 orbspeed = 2.0f;
			float spreadarc = 10;
			//bool lowboid = false;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					orbspeed *= 2.0f;
					spreadarc = 5;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				const int numOrbs = 4;
				for (int i = 0; i < numOrbs; i++)
				{
					CBlob@ orb = server_CreateBlob( "magic_missile", this.getTeamNum(), orbPos ); 
					if (orb !is null)
					{	
                        if(!this.hasTag("extra_damage"))
						{
                        	this.set_f32("damage", 1.0f);
						}
						else
						{
							this.set_f32("damage", 1.2f);
						}

                        orb.IgnoreCollisionWhileOverlapped( this );
						orb.SetDamageOwnerPlayer( this.getPlayer() );
						Vec2f newVel = orbVel;
						newVel.RotateBy( -spreadarc + (spreadarc/2)*i, Vec2f());
						orb.setVelocity( newVel );
					}
				}
			}
			else
			{
				this.getSprite().PlaySound("MagicMissile.ogg", 0.8f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );
			}
		}
		break;

		case 882940767://black_hole
		{
			if (!isServer()){
				return;
			}
			f32 orbspeed = 6.0f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					orbspeed *= 1.2f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "black_hole" );
			if (orb !is null)
			{
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			} 
		}
		break;

		case 1838498488://slow
		{
			f32 orbspeed = 4.2f;
			u16 effectTime = 600;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.6f;
					effectTime *= 1.2f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", slow_effect_missile);
					orb.set_u16("effect_time", effectTime);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 888767856://haste
		{
			f32 orbspeed = 4.0f;
			u16 effectTime = 600;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					effectTime *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					Haste(this, effectTime);
					return; //hastes self, doesn't send projectile
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", haste_effect_missile);
					orb.set_u16("effect_time", effectTime);
					
					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 545705456://revive
		{
			f32 orbspeed = 4.0f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.3f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", revive_effect_missile);

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.setVelocity(orbVel);
				}
			}
		}
		break;

		case -1686119404://knight_revive
		{
			f32 orbspeed = 4.0f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.3f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", revive_knight_effect_missile);
					orb.set_u8("override_sprite_frame", 3);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 1998653938://unholy_resurrection
		{
			f32 orbspeed = 4.0f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					orbspeed *= 1.2f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;	
			
			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("gravestone",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", unholyRes_effect_missile);

					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 571136820://mana_transfer
		{
			f32 orbspeed = 4.0f;
			
			u16 manaUsed = spell.mana;

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (charge_state == super_cast)
			{
				manaUsed += 1;
			}

			ManaInfo@ manaInfo;
			if (!this.get( "manaInfo", @manaInfo )) {return;}
			u16 casterMana = manaInfo.manaRegen;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", mana_effect_missile);
					orb.set_u8("mana_used", manaUsed);
					orb.set_u8("caster_mana", casterMana);
					orb.set_u8("direct_restore", 0);
					orb.set_bool("silent", false);

					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case -4956908://sidewind
		{
			u16 windTime = 40;

			if (charge_state == super_cast)
			{
				windTime = 50;
			}

			Sidewind(this, windTime);
		}
		break;

		case 1227615081://airblast_shield
		{
			f32 orbspeed = 4.0f;
			u16 effectTime = 600;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					effectTime *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					AirblastShield(this, effectTime);
					return; //Airblast self, doesn't send projectile
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", airblastShield_effect_missile);
					orb.set_u16("effect_time", effectTime);

					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
			
		}
		break;

		case -282533932://fire_ward
		{
			f32 orbspeed = 4.0f;
			u16 effectTime = 900;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					effectTime *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					FireWard(this, effectTime);
					return; //Fireward self, doesn't send projectile
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", fireProt_effect_missile);
					orb.set_u16("effect_time", effectTime);

					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
			
		}
		break;

		case -954155722://stone_skin
		{
			/*
			f32 orbspeed = 4.0f;
			u16 effectTime = 600;

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (charge_state == NecromancerParams::extra_ready)
			{
				StoneSkin(this, effectTime);
			}
			else if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", "stoneSkin");
					orb.set_u16("effect_time", effectTime);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
			*/
		}
		break;

		case -2014033180://magic_barrier
		{
			u16 extraLifetime = this.hasTag("extra_damage") ? 5 : 0;
			u16 lifetime = 20 + extraLifetime;

			Vec2f orbPos = aimpos;
			Vec2f targetPos = orbPos + Vec2f(0.0f,2.0f);
			Vec2f dirNorm = (targetPos - thispos);
			dirNorm.Normalize();

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					lifetime += 5;
				}
				break;
				
				default:return;
			}

			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "magic_barrier", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u16("lifetime", lifetime);

					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setAngleDegrees(-dirNorm.Angle()+90.0f);
				}
			}
		}
		break;
		
		case 652962395:	//healing_plant
		{
			u16 extraLifetime = this.hasTag("extra_damage") ? 5 : 0;
			u16 lifetime = 10 + extraLifetime;
			f32 moveSpeed = 4.0f;

			u32 landheight = getLandHeight(aimpos);
			if(landheight != 0)
			{
				if (isClient())
				{
					Sound::Play("PlantShotLaunch.ogg", thispos, 2.0f, 0.2f + _spell_common_r.NextFloat() );
				}
				
				if (!isServer())
				{ return; }

				Vec2f targetPos = Vec2f(aimpos.x , landheight - 8);

				CBlob@ plantShot = server_CreateBlob( "plant_aura_shot", this.getTeamNum(), thispos );
				if (plantShot !is null)
				{
					if( charge_state == super_cast )//full charge
					{
						lifetime = 15;
						moveSpeed += 1.0f;
					}
					plantShot.set_u16("lifetime", lifetime);
					plantShot.set_f32("move_Speed", moveSpeed);
					plantShot.SetDamageOwnerPlayer( this.getPlayer() );

					plantShot.set_Vec2f("target", targetPos);
				}
			}
            else//Can't place this under the map
            {
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
            }
		}
		break;

		case 382419657://rock_wall
		{
			u16 extraLifetime = this.hasTag("extra_damage") ? 3 : 0;
			u16 lifetime = 5 + extraLifetime;

			switch(charge_state) //trickle down lifetime adder
			{
				case super_cast:
				{
					lifetime += 2;
				}

				case complete_cast:
				{
					lifetime++;
				}

				case medium_cast:
				{
					lifetime++;
				}

				case minimum_cast:
				break;

				default:return;
			}


			Vec2f orbPos = aimpos;
			Vec2f targetPos = orbPos + Vec2f(0.0f,2.0f);
			Vec2f dirNorm = (targetPos - thispos);
			dirNorm.Normalize();

			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "rock_wall", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u16("lifetime", lifetime);

					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setAngleDegrees(-dirNorm.Angle()+90.0f);
				}
			}
		}
		break;

		case -1005340482://teleport
		{
			CMap@ map = getMap(); //standard map check
			if (map is null)
			{ return; }

			int teamNum = this.getTeamNum();

			bool failedCast = false;

			if (this.get_u16("slowed") > 0 
			|| (this.exists("teleport_disable") && this.get_u32("teleport_disable") > getGameTime()))	//cannot teleport while slowed
			{ failedCast = true; }

			if (failedCast)
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
			}
			else
			{
				Vec2f hitPos = Vec2f_zero;

				HitInfo@[] hitInfos;
				bool teleBlock = false;
				bool hasHit = map.getHitInfosFromRay(castPos, -aimNorm.getAngle(), aimVector.Length(), this, @hitInfos);
				if ( hasHit )
				{
					for (uint i = 0; i < hitInfos.length; i++)
					{
						if ( teleBlock ){break;}

						HitInfo@ hi = hitInfos[i];
						if (hi.blob !is null) // check
						{
							if (hi.blob.getTeamNum() == teamNum)
							{continue;}

							if (!hi.blob.hasTag("TeleportBlocker"))
							{continue;}
							else 
							{
								hitPos = hitInfos[i].hitpos;
								aimpos = hitPos - aimNorm*4; //sets both aimpos and aimVector to correspond with the teleport blocker
								aimVector = hitPos - castPos;
								teleBlock = true; //no more blob checking
							}
						}
					}
				}

				if(isClient())
				{
					Vec2f clientCastPos = this.getPosition();

					//if teleport was blocked, set particle destination to raycast hitpos
					Vec2f clientAimVector = teleBlock ? hitPos : aimpos ; 
					clientAimVector -= clientCastPos;
					Vec2f clientAimNorm = clientAimVector;
					clientAimNorm.Normalize();

					clientAimVector -= clientAimNorm*4; //reduction in range of half a block

					for (uint step = 0; step < clientAimVector.Length(); step += 8)
					{
						teleSparks( clientCastPos + clientAimNorm*step, 5, clientAimNorm*4.0f );
					}
				
					ParticleAnimated( "Flash3.png",
								clientCastPos,
								Vec2f(0,0),
								360.0f * _spell_common_r.NextFloat(),
								1.0f, 
								3, 
								0.0f, true );
				}

				this.setVelocity( Vec2f_zero );
				this.setPosition( aimpos );
								
				this.getSprite().PlaySound("Teleport.ogg", 0.8f, 1.0f);
			}
		}
		break;

		case -2025350104: //recall_undead
		{
			CPlayer@ thisPlayer = this.getPlayer();
			if ( thisPlayer !is null )
			{		
				CBlob@[] zombies;
				getBlobsByTag("zombie", @zombies);

				for (uint i = 0; i < zombies.length; i++)
				{
					CBlob@ zombie = zombies[i];
					if ( zombie !is null && thisPlayer is zombie.getDamageOwnerPlayer() )
					{
						if ( isClient() )
							ParticleZombieLightning( zombie.getPosition() );
						zombie.setPosition( thispos );
						zombie.setVelocity( Vec2f(0,0) );
					}
				}
			}
			
			if (isClient())
			{
				this.getSprite().PlaySound("Summon1.ogg", 1.0f, 1.0f);
				ParticleZombieLightning( this.getPosition() );
			}
		}
		break;

		case 770505718://leech
		{
			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
		
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "leech", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
                    if(this.hasTag("extra_damage"))
                        orb.Tag("extra_damage");//Remember to change this in Leech.as

					orb.set_Vec2f("aim pos", aimpos);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
		}
		break;

		case -401411067://lightning
		{
            Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
		
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "lightning", this.getTeamNum(), Vec2f(aimpos.x, 4.0f) ); 
				if (orb !is null)
				{
                    if(this.hasTag("extra_damage"))
                        orb.Tag("extra_damage");//Remember to change this in Lightning.as

					orb.set_Vec2f("aim pos", aimpos);

					orb.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
		}
		break;

		case -1612772378://force_of_nature
		{
			int castTime = getGameTime();
		
			this.set_Vec2f("spell aim vec", aimpos - thispos);
			
			this.Tag("in spell sequence");
			this.set_u16("FoN cast time", castTime);
			this.Sync("FoN cast time", true);
			
			this.getSprite().PlaySound("forceofnature_start.ogg", 2.0f, 1.0f);
		}
		break;
		
		case 482205956: //expunger
		{
			this.getSprite().PlaySound("swordsummon.ogg");

			if (!isServer())
			{return;}

			bool extra_damage = this.hasTag("extra_damage");
			bool charged = false;
			f32 extraDamage = extra_damage ? 1.3f : 1.0f;
			f32 orbDamage = 0.4f * extraDamage;
			f32 orbspeed = necro_shoot_speed * 1.1f * extraDamage;
			int numOrbs = extra_damage ? 15 : 10;  //number of swords
			
            switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.3f;
					orbDamage += 0.2f;
					numOrbs += extra_damage ? 10 : 5; //25 swords if damage buff, 15 if not
					charged = true;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			
			float anglePerOrb = 360/numOrbs;
			float swordWheelRot = anglePerOrb * _spell_common_r.NextFloat();
			for (int i = 0; i < numOrbs; i++)
			{
				CBlob@ orb = server_CreateBlob( "expunger" );
				if (orb !is null)
				{
					u32 shooTime = getGameTime() + ( (16.0f * _spell_common_r.NextFloat()) + 42.0f);
					orb.set_Vec2f("targetto", orbVel);
					orb.set_f32("speeddo", orbspeed);
					orb.set_f32("damage", orbDamage);
					orb.set_u32("shooTime", shooTime);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.server_setTeamNum( this.getTeamNum() );
					orb.getShape().SetGravityScale(0);
					orb.setPosition( orbPos );

					Vec2f spawnVel = Vec2f(0,3);

					spawnVel.RotateBy(swordWheelRot + anglePerOrb*i, Vec2f());
					orb.setVelocity(spawnVel);
				}
			}
		}
		break;

		case -32608566://crusader
		{
			u32 landheight = getLandHeight(aimpos);
			if(landheight != 0)
			{
                if (!isServer())
				{return;}

				u16 extraLifetime = this.hasTag("extra_damage") ? 5 : 0;
				u16 lifetime = 20 + extraLifetime;

				f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
				f32 orbDamage = 1.0f * extraDamage;

				switch(charge_state)
				{
					case minimum_cast:
					case medium_cast:
					case complete_cast:
					break;
				
					case super_cast:
					{
						orbDamage *= 1.2f;
						lifetime += 5;
					}
					break;
					default:return;
				}

				Vec2f baseSite = Vec2f(aimpos.x , landheight - 8);
				const int numOrbs = 3;
				for (int i = 0; i < numOrbs; i++)
				{
					Vec2f cruSpawn = baseSite + Vec2f(-30.0f + 30.0f*i, -90.0f);

					CBlob@ orb = server_CreateBlob( "crusader" );
					if (orb !is null)
					{
						orb.set_f32("damage", orbDamage);
						u32 shooTime = getGameTime() + ( (15.0f * _spell_common_r.NextFloat()) + 42.0f ); //half a second randomness for fall delay (makes it look cooler)
						orb.set_u32("shooTime", shooTime);
						orb.set_u16("lifetime", lifetime);

						orb.SetDamageOwnerPlayer( this.getPlayer() );
						orb.getShape().SetGravityScale(0);
						orb.server_setTeamNum( this.getTeamNum() );
						orb.setPosition( cruSpawn );
					}
				}
			}
            else//Can't place this under the map
            {
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo ))
				{return;}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
            }
		}
		break;

		case 603057094://executioner
		{
			this.getSprite().PlaySound("execast.ogg");

			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed * 1.0f;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 2.0f * extraDamage; 

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage *= 1.2f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f shootVec = (aimpos - orbPos);
			Vec2f orbVel = shootVec;
			orbVel.Normalize();
			orbVel *= orbspeed;

			//distance between you and the target
			float stopLength = shootVec.Length() - 4.0f;
			f32 lifetime = stopLength / orbspeed;

			CBlob@ orb = server_CreateBlob("executioner",this.getTeamNum(),orbPos);
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);
				orb.set_f32("lifetime", lifetime);

				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.getShape().SetGravityScale(0);
				orb.setVelocity( orbVel );
			}
			
		}
		break;

		case 408450338://bladed_shell
		{
			if(this.hasScript("BladedShell.as"))
			{
				this.set_u32("timeActive",(10*30) + getGameTime());
				if(!this.hasTag("doubleBlade"))
				{
					this.Tag("doubleBlade");
					this.set_f32("effectRadius",8*4);
					this.set_u32("attackRate",10); //3 hits a second
				}
			}
			else
			{
				this.AddScript("BladedShell.as");
			}

		}
		break;

		case 799586754://flame_slash
		{
			if(this.hasScript("FlameSlash.as"))
			{
				this.set_Vec2f("flame_slash_blobpos",thispos);
				this.set_Vec2f("flame_slash_aimpos",aimpos);
				this.set_bool("slashSpriteSetupDone", false);
				this.set_bool("flame_slash_activation", true);

				switch(charge_state)
				{
					case minimum_cast:
					case medium_cast:
					case complete_cast:
					break;
				
					case super_cast:
					{
						this.Tag("super_flame_slash");
					}
					break;
				
					default:return;
				}
				
				if(isClient())
				{
					this.getSprite().PlaySound("flame_slash_sound", 3.0f);
				}
			}
			else
			{
				//this.set_Vec2f("flame_slash_aimpos",aimpos);
				this.AddScript("FlameSlash.as");
				
				if(isClient())
				{
					this.getSprite().PlaySound("flame_slash_setup", 3.0f);
				}
			}
		}
		break;

		case -1661937901://impaler
		{
			this.getSprite().PlaySound("ImpCast.ogg", 100.0f);

			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed*1.1f;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.25f : 1.0f;
			f32 orbDamage = 0.5f * extraDamage;
           
            if (charge_state == NecromancerParams::cast_3) {
				orbDamage *= 1.0f;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.25f;
				orbDamage *= 1.5f;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "impaler" );
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
				orb.Tag("primed");
			}
		}
		break;

		case 1647813557://parry
		{
			float effectRadius = 8.0f; //length of a block
			f32 scale = 0.25f;
			f32 extraRadius = this.hasTag("extra_damage") ? 0.3f : 0.0f; //if yes, a bit more range

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					effectRadius *= (2.0f + extraRadius); //2 block radius
				}
				break;
				
				case super_cast:
				{
					effectRadius *= (3.0f + extraRadius); //3 block radius
					scale *= (1.5f + extraRadius);
				}
				break;
				
				default:return;
			}

			Vec2f casterPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f castDir = (aimpos - casterPos);
			castDir.Normalize();
			castDir *= 24; //all of this to get offset 3 blocks in front of caster
			Vec2f castPos = casterPos + castDir;  //exact position of effect

			if ( isClient() ) //temporary Counterspell effect
			{
				CParticle@ p = ParticleAnimated( "Flash2.png",
						castPos,
						Vec2f(0,0),
						0,
						scale, 
						8, 
						0.0f, true ); 	
										
				if ( p !is null)
				{
					p.bounce = 0;
    				p.fastcollision = true;
					p.Z = 600.0f;
				}
				CParticle@ pb = ParticleAnimated( "Shockwave2.png",
						castPos,
						Vec2f(0,0),
						360.0f * _spell_common_r.NextFloat(),
						scale, 
						2, 
						0.0f, true );    
				if ( pb !is null)
				{
					pb.bounce = 0;
    				pb.fastcollision = true;
					pb.Z = -10.0f;
				}
				this.getSprite().PlaySound("CounterSpell.ogg", 0.8f, 1.0f);
			}

			CMap@ map = getMap(); //standard map check
			if(map is null)
			{return;}

			CBlob@[] blobs;//blob handle array to store blobs we want to effect
			int ownTeam = this.getTeamNum(); //Team of caster shortcut

			map.getBlobsInRadius(castPos,effectRadius, @blobs);//get the blobs
			for(uint i = 0; i < blobs.length(); i++)//itterate through blobs
			{
				if(@blobs[i] is null){continue;}
				CBlob@ other = @blobs[i];//setting other blob to a variable for readability
				if(other.getTeamNum() == ownTeam){continue;}//Does nothing if same team
				if(other.hasTag("barrier")){continue;} //do nothing if it's a barrier
				if(other.hasTag("cantparry")){continue;}
				Vec2f othVel = other.getVelocity(); //velocity of target shortcut

				s8 blobType = parryTargetIdentifier(other);

				switch(blobType)  //decides what to do with the parried blob
				{
					case 0: //normal projectiles
					{
						other.server_setTeamNum(ownTeam);
						other.SetDamageOwnerPlayer( this.getPlayer() ); //<<doesn't seem to work properly
						float othVelAngle = othVel.getAngleDegrees();
						float parryAngle = castDir.getAngleDegrees();
						float redirectAngle = (othVelAngle-parryAngle) % 360;
						othVel.RotateBy(redirectAngle);
						other.setVelocity(othVel);
					}
					break;
					case 1: //projectiles that follow mouse
					{
						if (isServer())
						{
							CBlob@ orb = server_CreateBlob(other.getName(),this.getTeamNum(),other.getPosition());
							if (orb !is null)
							{
								if(other.exists("explosive_damage"))
								{
									orb.set_f32("explosive_damage", other.get_f32("explosive_damage"));
								}
								if(other.exists("damage"))
								{
									orb.set_f32("damage", other.get_f32("damage"));
								}
								if(other.exists("lifetime"))
								{
									orb.set_f32("lifetime", other.get_f32("lifetime"));
								}
								if(other.hasTag("extra_damage"))
								{
                        			orb.Tag("extra_damage");
								}

								orb.IgnoreCollisionWhileOverlapped( other );
								orb.SetDamageOwnerPlayer( this.getPlayer() );
								orb.getShape().SetGravityScale(0);

								other.Untag("exploding");
								other.server_Die();
							}
						}
					}
					break;
					case 2: //players
					{
						other.setVelocity( othVel + (castDir / 3)); //slight push using cast direction for convenience
					}
					break;
					case 3: //undead
					{
						other.setVelocity( othVel + (castDir * 2)); //strong push using cast direction for convenience
					}
					break;
					default:
					{
						continue;
					}
				}
			}
		}
		break;

		case -1532527513://nemesis
		{
			if (!isServer()) return;
			
			CBlob@ orb = server_CreateBlob("nemesis" , this.getTeamNum() , aimpos);
			if (orb !is null)
			{
				switch (charge_state)
				{
					case minimum_cast:
					case medium_cast:
					{
						if (isClient())
						{
							ManaInfo@ manaInfo;
							if (!this.get( "manaInfo", @manaInfo )) {
								return;
							}
							manaInfo.mana += spell.mana;
						}
						return;
					}
					case complete_cast:
					{
						orb.set_s32("max_swords", 7);
						orb.set_u32("delay_time", 30);
						break;
					}
					case super_cast:
					{
						orb.set_s32("max_swords", 10);
						orb.set_u32("delay_time", 15);
						break;
					}
				}

				if (this.hasTag("extra_damage"))
				{
					orb.add_s32("max_swords", 5);
					orb.Sync("max_swords", true);
					orb.Sync("delay_time", true);
				}
				orb.SetDamageOwnerPlayer(this.getPlayer());
			}
		}
		break;

		case -1395850262://hook
		{
			bool failedCast = false;
			if ( this.get_u16("slowed") > 0 )	//cannot teleport while slowed
			{ failedCast = true; }

			if (failedCast)
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				return;
			}

			this.getSprite().PlaySound("swordsummon.ogg", 1.0f, 1.33f);

			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed*2;
			f32 orbDamage = 0.25f;
           
            if (charge_state == complete_cast) {
				orbspeed = necro_shoot_speed*3.5f;
			}
			else if (charge_state == super_cast) {
				orbspeed = necro_shoot_speed*4.5f;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "hook" );
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
				orb.Tag("primed");
			}
		}
		break;

		case -1418908460://bunker_buster
		{
			this.getSprite().PlaySound("bunkercast.ogg", 100.0f);

			if (!isServer()){
           		return;
			}
			f32 orbspeed = necro_shoot_speed*0.3f;
            f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 1.0f * extraDamage;

            if (charge_state == NecromancerParams::cast_3) {
				orbspeed *= 1.0f;
				orbDamage *= 1.0f;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
				orbDamage *= 1.5f;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "bunker_buster" );
			if (orb !is null)
			{
				if(this.hasTag("extra_damage"))  //if buffed, more blast power
				{
					orb.set_f32("blastStr", 1.2f);
				}
				else
				{
					orb.set_f32("blastStr", 1.0f);
				}

				orb.set_f32("damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel + Vec2f(0,-0.6f));
			}
		}
		break;

		case 2065576553://vectorial_dash
		{
			if (!isClient())
			{ return; }

			CMap@ map = getMap(); //standard map check
			if (map is null)
			{return;}

			int teamNum = this.getTeamNum();

			bool failedCast = false;

			if (failedCast)
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				return;
			}

			this.getSprite().PlaySound("bunkercast.ogg", 100.0f);
			f32 orbspeed = 1.0f;

            if (charge_state == NecromancerParams::cast_3) {
				orbspeed *= 1.0f;
			}
			else if (charge_state == NecromancerParams::extra_ready) {
				orbspeed *= 1.2f;
			}

			Vec2f targetPos = aimpos + Vec2f(0.0f,-2.0f);
			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (targetPos- orbPos) / 10;
			orbVel *= orbspeed;

			/*if(orbVel.x < 6 && orbVel.x > 0) //Minimum X velocity
			{orbVel.x = 6;}
			else if(orbVel.x > -6 && orbVel.x < 0)
			{orbVel.x = -6;}

			if(orbVel.y < 7 && orbVel.y > 0) //Minimum Y velocity
			{orbVel.y = 7;}
			else if(orbVel.y > -7 && orbVel.y < 0)
			{orbVel.y = -7;}*/

			this.setVelocity( this.getVelocity() + orbVel ); //add velocity to caster's current velocity
		}
		break;

		case 39628416://no_teleport_barrier
		{
			u16 extraLifetime = this.hasTag("extra_damage") ? 5 : 0;
			u16 lifetime = 30 + extraLifetime;

			Vec2f orbPos = aimpos;
			Vec2f targetPos = orbPos + Vec2f(0.0f,2.0f);
			Vec2f dirNorm = (targetPos - thispos);
			dirNorm.Normalize();

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					lifetime += 5;
				}
				break;
				
				default:return;
			}

			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "no_teleport_barrier", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u16("lifetime", lifetime);

					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setAngleDegrees(-dirNorm.Angle()+90.0f);
					orb.getShape().SetStatic(true);
				}
			}
		}
		break;

		case -445081510://negatisphere
		{
			if (!isServer()){
           		return;
			}
			f32 orbspeed = necro_shoot_speed*0.5f;
			int amount = this.hasTag("extra_damage") ? 4 : 3;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					orbspeed *= 1.3f;
					amount = 4;
				}
				break;
				
				default:return;
			}

			
			f32 angle_per_circle = 360/amount;

			for (u8 i = 0; i < amount; i++)
			{
				Vec2f orbPos = thispos + Vec2f(0.0f,-16.0f).RotateBy(i * angle_per_circle);
				Vec2f orbVel = (aimpos - orbPos);
				orbVel.Normalize();
				orbVel *= orbspeed;

				CBlob@ orb = server_CreateBlob( "negatisphere" , this.getTeamNum() , orbPos);
				if (orb !is null)
				{
					orb.set_Vec2f("caster", orbPos);
					orb.set_s8("lifepoints", 10); //"life" that drains when cancelling other spells.

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );

					if(this.get_bool("shifting"))
					{
						orb.set_Vec2f("target", aimpos);
						orb.set_bool("launch", true);
					}
				}
			}
		}
		break;

		case 1324044072://disruption_wave
		{
			float damage = 0.8f;
			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					damage = 1.2f;
				}
				break;
				
				default:return;
			}

			int castTime = getGameTime();
		
			this.set_Vec2f("spell aim vec", aimpos - thispos);
			this.set_f32("DW_damage", damage); //sets damage for Disruption Wave to use
			
			this.Tag("in spell sequence");
			this.set_u16("DW cast moment", castTime);
			this.Sync("DW cast moment", true);

			if (isClient())
			{this.getSprite().PlaySound("dw_cast_sequence.ogg", 3.0f, 1.5f);}
		}
		break;

		case -139761568: //dmine
		{
			int height = getLandHeight(aimpos);
			if(height != 0 && (charge_state == complete_cast || charge_state == super_cast))
			{
				CBlob@[] list;
				map.getBlobsInRadius(Vec2f(aimpos.x,height), 8, @list);
				bool can_place = true;
				for (u16 i = 0; i < list.length; i++)
				{
					CBlob@ b = list[i];
					if (b is null) continue;
					if (b.getName()=="dmine")
					{
						ManaInfo@ manaInfo;
						if (!this.get( "manaInfo", @manaInfo )) {
							return;
						}

						can_place = false;

						if (!this.get_bool("burnState"))
						{
							manaInfo.mana += spell.mana;
						}
						this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
					}
				}
				if(isServer() && can_place)
				{
					CBlob@ mush = server_CreateBlob("dmine",this.getTeamNum(),Vec2f(aimpos.x,height) );
					mush.SetDamageOwnerPlayer(this.getPlayer());
					mush.set_s32("aliveTime",charge_state == 5 ? 1350 : 900); //45s\30s
				}
			}
			else
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				if (height == 0) this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
			}
		}
		break;

		case -595243942://voltage_field
		{
			if(this.hasScript("VoltageField.as"))
			{
				return;
			}

			if(!this.hasScript("VoltageField.as"))
			{
				this.AddScript("VoltageField.as");
				this.set_u16("stunned", 5*30);//disables casting and the such
				if(isClient())
				{
					this.getSprite().PlaySound("voltage.ogg", 3.0f);
				}
			}
		}
		break;

		case -997077766://magicarrows
		{
			if(this.hasScript("CastMagicArrows.as"))
			{
				return;
			}

			u8 amount = 4;
			f32 orbDamage = 0.25f;
			u8 delay = 5;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				break;

				case complete_cast:
				{
					delay = 4;
					amount = 5;
					orbDamage = 0.325f;
				}
				break;

				case super_cast:
				{
					delay = 3;
					amount = 6;
					orbDamage = 0.375f;
				}
				break;
				default:return;
			}
			if (this.hasTag("extra_damage"))
			{
				delay = 2;
				amount += 2;
			}

			if(!this.hasScript("CastMagicArrows.as"))
			{
				this.set_u8("magicarrows_amount", amount);
				this.set_u8("magicarrows_current", amount);
				this.set_f32("magicarrows_damage", orbDamage);
				this.set_u8("magicarrows_delay", delay);
				this.set_u32("magicarrows_time", getGameTime());
				this.AddScript("CastMagicArrows.as");
				this.set_u16("stunned", delay*amount);//disables casting and the such
			}
		}
		break;

		case 1341451107: //polarityfield
		{
			if (!isServer()){
           		return;
			}

			f32 orbspeed = 0;
			bool extraDamage = this.hasTag("extra_damage");
			f32 orbDamage = 2.0f;
			u8 stages = 3;
            
			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
					return;
									
				case complete_cast:
				{
					stages = 3;
				}
				break;

				case super_cast:
				{
					stages = 4;
				}
				break;
			}

			bool extra_damage = this.hasTag("extra_damage");
			if (extra_damage)
				stages += 1;

			CBlob@ orb = server_CreateBlobNoInit("polarityfield");
			if (orb !is null)
			{
				orb.set_u8("stages", stages);
				orb.Init();

				orb.IgnoreCollisionWhileOverlapped(this);
				orb.SetDamageOwnerPlayer(this.getPlayer());
				orb.server_setTeamNum(this.getTeamNum());
				orb.setPosition(aimpos);
				orb.getShape().SetStatic(true);
			}
		}
		break;

		case -2121014561://nova
		{
			if(!isServer()){
				return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 2.0f * extraDamage;

			if (charge_state == super_cast) {
				orbDamage += 1.0f;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= 2;

			CBlob@ orb = server_CreateBlob( "nova_bolt" );
			if (orb !is null)
			{
				orb.set_f32("explosive_damage", orbDamage);
				orb.set_Vec2f("aimpos", aimpos);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
			}
		}
		break;

		case -1037635552: //plasma_shot
		{
			if(isClient())
			{
				this.getSprite().PlaySound("MagicMissile.ogg", 0.8f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );
			}

			if (!isServer()){
           		return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbspeed = 2.2f;
			f32 orbDamage = 2.33f * extraDamage;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage *= 1.5f;
				}
				break;
				default:return;
			}

			CBlob@ orb = server_CreateBlob( "plasma_shot" , this.getTeamNum() , thispos);
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);
				orb.set_f32("move_Speed", orbspeed);
				orb.set_Vec2f("target", aimpos);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.setVelocity( Vec2f_zero );
			}
		}
		break;

		case 2029285710://zombie_rain
		case 1033042153://skeleton_rain
		case 1761466304://meteor_rain
		case 1137221912://meteor_strike
		case 1057572449://arrow_rain
		case 1693590535://smite
		{
			if (!isServer())
			{
				return;
			}
			CBitStream params;
			params.write_string(spellName);
			params.write_u8(charge_state);
			params.write_Vec2f(aimpos);

			this.SendCommand(this.getCommandID("rain"), params);
		}
		break;

		case -1911379896://stone_spikes
		{
			if (!isServer())
				return;
			bool isleft = this.isFacingLeft();
			Vec2f tilespace(int(aimpos.x / 8), int(aimpos.y / 8));
			Vec2f worldspace = tilespace * 8 + Vec2f(4, 4);
			Vec2f spawnpos = Vec2f_zero;
			
			CMap@ map = getMap(); //standard map check
			if(map is null)
			{return;}

			for(int i = 0; i < 50; i++)
			{
				if(!map.isTileSolid(worldspace + Vec2f(0, i * 8)) && map.isTileSolid(worldspace + Vec2f(0, i * 8 + 8)))
				{
					spawnpos = worldspace + Vec2f(0, i * 8);
					break;
				}	
				/*else if(!map.isTileSolid(worldspace + Vec2f(0, i * -8)) && map.isTileSolid(worldspace + Vec2f(0, i * -8 + 8)))
				{
					spawnpos = worldspace + Vec2f(0, i * -8);
					break;
				}*/
			}
			if(spawnpos != Vec2f_zero)
			{
				if(map.getBlobAtPosition(spawnpos) is null || !(map.getBlobAtPosition(spawnpos).getName() == "stone_spike"))
				{
					CBlob@ newblob = server_CreateBlob("stone_spike", this.getTeamNum(), spawnpos);
					newblob.set_u8("spikesleft", 8 + charge_state * 1.5 + (charge_state == 5 ? 7 : 0));
					newblob.set_bool("leftdir", isleft);
				}
			}
		}
		break;

		case -1488386525://fiery_star
		{
			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed * 0.25f;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.15f : 1.0f;
			f32 orbDamage = 1.0f * extraDamage;
            
			if (charge_state == super_cast) {
				orbDamage *= 1.25f;
				orbspeed *= 1.25;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "fiery_star" );
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 1375277208://burn
		{
			this.set_bool("burnState", true);
		}
		break;

		case 890496406://negentropy
		{
			if(!this.get_bool("burnState"))
			{
				this.set_bool("negentropyStart",true);
			}
		}
		break;

		case 11469271://crystallize
		{
			u8 shardAmount = this.get_u8("shard_amount");

			if ( shardAmount > 7 )	//cannot create more than 8
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				if(!this.get_bool("burnState"))
				{
					manaInfo.mana += spell.mana;
				}
				
				if(isClient())
				{
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
				return;
			}

			shardAmount++;
			this.set_u8("shard_amount",shardAmount); //increases by one
		}
		break;

		case 1552774047://dematerialize
		{
			u8 shardAmount = this.get_u8("shard_amount");

			if ( shardAmount == 0 )	//no shards left
			{
				if(isClient())
				{
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
				return;
			}

			ManaInfo@ manaInfo;
			if (!this.get( "manaInfo", @manaInfo )) {
				return;
			}

			if(!this.get_bool("burnState"))
			{
				if(manaInfo.mana + 20 > manaInfo.maxMana)
				{
					manaInfo.mana = manaInfo.maxMana;
				}
				else 
				{
					manaInfo.mana += 20;
				}
			}

			shardAmount--;
			this.set_u8("shard_amount",shardAmount); //decreases by one
		}
		break;

		case -1648886327://polarity
		{
			this.set_bool("attack", !this.get_bool("attack"));
		}
		break;

		// PRIEST

		case 1637274485://holystrike
		{
            if (!isServer())
			{return;}

			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbDamage = 1.5f * extraDamage;
			u8 lt = 25;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					lt = 30;
				}
				break;
			
				case super_cast:
				{
					lt = 40;
					orbDamage *= 1.25f;
				}
				break;
				default:return;
			}

			Vec2f baseSite = aimpos;
			const int numOrbs = 1;
			for (int i = 0; i < numOrbs; i++)
			{
				Vec2f cruSpawn = baseSite + Vec2f(0, (aimpos.y+24.0f < baseSite.y-270.0f ? -270.0f : aimpos.y-baseSite.y));

				CBlob@ orb = server_CreateBlob( "holystrike" );
				if (orb !is null)
				{
					orb.set_f32("damage", orbDamage);
					u32 shooTime = getGameTime() + ( (15.0f * _spell_common_r.NextFloat()) + 42.0f ); //half a second randomness for fall delay (makes it look cooler)
					orb.set_u32("shooTime", shooTime);
					orb.set_u16("lifetime", lt);
					orb.server_SetTimeToDie(lt);

					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.getShape().SetGravityScale(0);
					orb.server_setTeamNum( this.getTeamNum() );
					//orb.setPosition( cruSpawn );
					orb.setPosition( aimpos );
				}
			}
		}
		break;

		case 848283115://divine shield
			if(isServer())
			{
				f32 extraDamage = this.hasTag("extra_damage") ? 1.5f : 1.0f;
				CBlob@ circle = server_CreateBlob('divine_shield',this.getTeamNum(),aimpos);
				circle.SetDamageOwnerPlayer(this.getPlayer());
				circle.set_s32("aliveTime", (180 * extraDamage)+(charge_state>2?charge_state*120:charge_state*75));
			}
		break;

		case -1487767046://beam
		{
			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
		
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "beam", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
                    if(this.hasTag("extra_damage"))
                        orb.Tag("extra_damage");

					orb.set_u16("shooter", this.getNetworkID());
					if (charge_state == 5)
					{
						orb.set_bool("force", true);
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
		}
		break;

		case -49146465://fireorbs
		{
			if (!isServer()){
           		return;
			}
			f32 orbspeed = necro_shoot_speed*0.5f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
				}
				break;
				
				case super_cast:
				{
					orbspeed *= 1.3f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "fireorbs" , this.getTeamNum() , aimpos);
			if (orb !is null)
			{
				orb.set_Vec2f("caster", orbPos);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.set_u16("shooter", this.getNetworkID());
				bool extraDamage = this.hasTag("extra_damage");
				orb.set_f32("explosive_damage", extraDamage ? 24.0f : 1.0f);

				orb.setVelocity( orbVel );
			}
		}
		break;

		case 491688572://singularity
		{
			if (!isServer()) return;
			CBlob@ orb = server_CreateBlob( "singularity" , this.getTeamNum() , aimpos);
			if (orb !is null)
			{
				orb.set_f32("lifetime",15.0f-(charge_state));
				orb.SetDamageOwnerPlayer(this.getPlayer());
			}
		}
		break;

		case 16724762://regen
		{
			f32 orbspeed = 6.0f;
			u16 effectTime = 300+(XORRandom(4)*10);
			f32 extraDamage = this.hasTag("extra_damage") ? 1.25f : 1.0f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					effectTime *= 1.0f * extraDamage;
				}
				break;
				
				case super_cast:
				{
					Regen(this, (effectTime+45) * extraDamage);
					return; //hastes self, doesn't send projectile
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", regen_effect_missile);
					orb.set_u16("effect_time", effectTime);
					
					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case 1938943027://damage aura
		{
			DamageAura(this, !this.get_bool("damageaura"));
		}
		break;

		case 1342704485://emergency teleport
		{
			CMap@ map = getMap(); //standard map check
			if (map is null)
			{ return; }

			int teamNum = this.getTeamNum();

			bool failedCast = false;

			if ( this.get_u16("slowed") > 0 )	//cannot teleport while slowed
			{ failedCast = true; }

			if (failedCast)
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				return;
			}
			else
			{
				Vec2f castPos = thispos;
				Vec2f endpos;

				f32 temp_hp = 0;
				u16 id = 0;
				
				for (u8 i = 0; i < getPlayersCount(); i++)
				{
					CPlayer@ p = getPlayer(i);
					if (p !is null && p.getBlob() !is null)
					{
						CBlob@ b = p.getBlob();
						if (b is this || b.getHealth() == b.getInitialHealth() || b.getTeamNum() != this.getTeamNum()) continue;
						if (temp_hp == 0 || b.getHealth()/b.getInitialHealth() < temp_hp)
						{
							temp_hp = b.getHealth()/b.getInitialHealth();
							id = b.getNetworkID();
						}
					}
				}

				if(isClient())
				{
					Vec2f clientCastPos = this.getPosition();
				
					ParticleAnimated( "Flash3.png",
								clientCastPos,
								Vec2f(0,0),
								360.0f * _spell_common_r.NextFloat(),
								1.0f, 
								3, 
								0.0f, true );
				}

				CBlob@ target = getBlobByNetworkID(id);
				if (target !is null)
				{
					endpos = target.getPosition();
					this.setVelocity( Vec2f_zero );
					this.setPosition( endpos );
					if (isServer())
					{
						f32 mod = target.getHealth()/target.getInitialHealth();
						f32 base_heal = 1.5f;
						base_heal = Maths::Min(5.0f, base_heal);
						
						if (this.getHealth()+(base_heal * 0.75f) >= this.getInitialHealth())
							this.server_SetHealth(this.getInitialHealth());
						else
							this.server_Heal(base_heal * 0.75f);

						// heal target more
						if (target.getHealth()+(base_heal * 1.25f) >= target.getInitialHealth())
							target.server_SetHealth(target.getInitialHealth());
						else
							target.server_Heal(base_heal * 1.25f);
					}
					this.getSprite().PlaySound("Teleport.ogg", 0.8f, 1.0f);
					this.getSprite().PlaySound("Heal.ogg", 0.8f, 0.95f);
				}
				else // heal self
				{
					if (isServer())
					{
						f32 mod = this.getHealth()/this.getInitialHealth();
						f32 base_heal = 1.5f;
						base_heal *= 3.0f-(3.0f*mod);
						base_heal = Maths::Min(2.5f, base_heal);
						
						if (this.getHealth()+base_heal >= this.getInitialHealth())
							this.server_SetHealth(this.getInitialHealth());
						else
							this.server_Heal(base_heal);
					}
					this.getSprite().PlaySound("Heal.ogg", 0.8f, 0.95f);
				}
			}
		}
		break;

		case 1633040867://manaburn
		{
			f32 orbspeed = 3.25f;
			u16 effectTime = 450;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.75f;
					effectTime *= 1.2f;
				}
				break;

				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", manaburn_effect_missile);
					orb.set_u16("effect_time", effectTime);

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
					orb.setVelocity( orbVel );
				}
			}
		}
		break;

		case -618011624: //epicorb
		{
			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed;
			bool extraDamage = this.hasTag("extra_damage");
			f32 orbDamage = 1.0f;
			u8 orbs;
            
			switch(charge_state)
			{
				case minimum_cast:
				{
					orbs = 1;
				}
				break;

				case medium_cast:
				{
					orbs = 2;
				}
				break;

				case complete_cast:
				{
					orbs = 3;
				}
				break;

				case super_cast:
				{
					orbs = 5;
					orbspeed *= 1.33f;
					if (extraDamage)
					{
						orbs = 7;
						orbspeed *= 1.5f;
					}
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed*(1.5f-orbs*0.175f);

			CBlob@ orb = server_CreateBlobNoInit( "epicorbmain" );
			if (orb !is null)
			{
				orb.set_u8("orbs", orbs);
				orb.Init();

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		// SHAMAN

		case 1117884490: //firetotem
		{
			{
				CBlob@[] totems;
				getBlobsByName("firetotem",@totems);

				if (this.getPlayer() is null)
				{return;}

				CBlob@ totem1 = null;
				CBlob@ totem2 = null;

				for(int i = 0; i < totems.length; i++)
				{
					if (totems[i] is null)
					{continue;}
					if (totems[i].getDamageOwnerPlayer() is null)
					{continue;}
					if(totems[i].getDamageOwnerPlayer().getNetworkID() == this.getPlayer().getNetworkID())
					{
						if (totem1 is null) @totem1 = @totems[i];
						else if (totem2 is null) @totem2 = @totems[i];
						
						if (totem1 !is null && totem2 !is null)
						{
							totem1.server_Die();
							break;
						}
					}
				}

				int height = getLandHeight(aimpos);
				if(height != 0)
				{
					if(isServer())
					{
						CBlob@ tot = server_CreateBlob("firetotem",this.getTeamNum(),Vec2f(aimpos.x,height) );
						tot.SetDamageOwnerPlayer(this.getPlayer());

						switch (charge_state)
						{
							case 1:
							case 2:
							{
								tot.set_s32("aliveTime", 750);
								break;
							}
							case 3:
							{
								tot.set_u16("fire_delay", 150);
								tot.set_s32("aliveTime", 900);
								break;
							}
							case 4:
							{
								tot.set_u16("fire_delay", 135);
								tot.set_s32("aliveTime", 900);
								break;
							}
							case 5:
							{
								tot.set_u16("fire_delay", 120);
								tot.set_s32("aliveTime", 1350);
								break;
							}
						}
						if (this.hasTag("extra_damage"))
						{
							tot.set_u16("fire_delay", 105);
						}
					}
				}
				else
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					
					manaInfo.mana += spell.mana;
					
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
			}
			break;
		}

		case -981925343: // watertotem
		{
			{
				CBlob@[] totems;
				getBlobsByName("watertotem",@totems);

				if (this.getPlayer() is null)
				{return;}

				for(int i = 0; i < totems.length; i++)
				{
					if (totems[i] is null)
					{continue;}
					if (totems[i].getDamageOwnerPlayer() is null)
					{continue;}
					if(totems[i].getDamageOwnerPlayer().getNetworkID() == this.getPlayer().getNetworkID())
					{
						totems[i].server_Die();
						break;
					}
				}

				int height = getLandHeight(aimpos);
				if(height != 0)
				{
					if(isServer())
					{
						CBlob@ tot = server_CreateBlob("watertotem",this.getTeamNum(),Vec2f(aimpos.x,height) );
						tot.SetDamageOwnerPlayer(this.getPlayer());

						switch (charge_state)
						{
							case 1:
							case 2:
							{
								tot.set_s32("aliveTime", 1800);
								break;
							}
							case 3:
							{
								tot.set_u16("charge_delay", 120);
								tot.set_s32("aliveTime", 2100); //1m10s
								break;
							}
							case 4:
							{
								tot.set_u16("charge_delay", 115);
								tot.set_s32("aliveTime", 2400);//1m20s
								break;
							}
							case 5:
							{
								tot.set_u16("charge_delay", 105);
								tot.set_s32("aliveTime", 2700); //1m30s
								break;
							}
						}
						if (this.hasTag("extra_damage"))
						{
							tot.set_s32("aliveTime", 2700); //1m30s
							tot.set_u16("charge_delay", 105);
						}
					}
				}
				else
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					
					manaInfo.mana += spell.mana;
					
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
			}
			break;
		}
		
		case -231280296: // earthtotem
		{
			{
				CBlob@[] totems;
				getBlobsByName("earthtotem",@totems);

				if (this.getPlayer() is null)
				{return;}

				for(int i = 0; i < totems.length; i++)
				{
					if (totems[i] is null)
					{continue;}
					if (totems[i].getDamageOwnerPlayer() is null)
					{continue;}
					if(totems[i].getDamageOwnerPlayer().getNetworkID() == this.getPlayer().getNetworkID())
					{
						totems[i].Tag("replaced");
						totems[i].server_Die();
						break;
					}
				}

				int height = getLandHeight(aimpos);
				if(height != 0)
				{
					if(isServer())
					{
						CBlob@ tot = server_CreateBlob("earthtotem",this.getTeamNum(),Vec2f(aimpos.x,height) );
						tot.SetDamageOwnerPlayer(this.getPlayer());

						switch (charge_state)
						{
							case 1:
							case 2:
							{
								tot.set_s32("aliveTime", 600);
								break;
							}
							case 3:
							{
								tot.set_s32("aliveTime", 600);
								tot.set_f32("max_dist", 64.0f+16.0f);
								break;
							}
							case 4:
							{
								tot.set_s32("aliveTime", 750);//25s
								tot.set_f32("max_dist", 64.0f+32.0f);
								break;
							}
							case 5:
							{
								tot.set_s32("aliveTime", 900); //30s
								tot.set_f32("max_dist", 64.0f+64.0f);
								break;
							}
						}
						if (this.hasTag("extra_damage"))
						{
							tot.set_s32("aliveTime", 1200); //40s
						}
					}
				}
				else
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					
					manaInfo.mana += spell.mana;
					
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
			}
			break;
		}

		case 468301997: // flameorb
		{
			if (!isServer()){
           		return;
			}

			if (this.get_u16("waterbarrier") > 0)
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 0.85f, 0.85f);
				return;
			}

			f32 orbspeed = necro_shoot_speed/1.5f;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;

			switch(charge_state)
			{
				case minimum_cast:
				{
					orbspeed *= (1.0f/2.0f); // wtf is this code even? 
				}
				break;

				case medium_cast:
				{
					orbspeed *= (4.0f/5.0f);
				}
				break;

				case complete_cast:
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "flameorb" );
			if (orb !is null)
			{
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
			break;
		}
		case 241951502: // massfreeze
		{
			f32 distance = 48.0f;
			f32 power = 1.0f;
			bool cancel = false;
			bool short_self = this.hasTag("extra_damage");

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					manaInfo.mana += spell.mana;
					cancel = true;
				}
				case complete_cast:
				{
					distance = 96.0f;
					power = 1.0f;
				}
				break;
				
				case super_cast:
				{
					distance = 142.0f;
					power = 1.33f;
					short_self = true;

					if (this.hasTag("extra_damage"))
					{
						distance = 186.0f;
						power = 1.5f;
					}
				}
				break;
			}
			
			if (!cancel)
			{
				for (u8 i = 0; i < getPlayersCount(); i++)
				{
					if (getPlayer(i) is null) continue;
					CBlob@ b = getPlayer(i).getBlob();

					if (b is null || b.hasTag("burning")) continue;
					if (b.getDistanceTo(this) > distance) continue;
					
					b.getSprite().PlaySound("IceShoot.ogg", 0.75f, 1.3f + XORRandom(11)/10.0f);
					this.server_Hit(b, b.getPosition(), b.getVelocity(), 0.001f, Hitters::water, true);

					if (this.isMyPlayer())
					{
						CBitStream params;
						f32 pow = 2.0f*power;
						if (short_self && b.isMyPlayer()) pow /= 2;
						params.write_u16(b.getNetworkID());
						params.write_f32(pow);
						this.SendCommand(this.getCommandID("freeze"), params);
					}

					{									
						const f32 rad = 16.0f;
						Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
    			    	CParticle@ p = ParticleAnimated( "IceBlast" + (XORRandom(3)+1) + ".png", 
													b.getPosition(), 
													Vec2f(0,0), 
													0.0f, 
													1.0f, 
													2 + XORRandom(4), 
													0.0f, 
													false );
    			    	if(p is null) return; //bail if we stop getting particles
    					p.fastcollision = true;
    			    	p.damping = 0.85f;
						p.Z = 500.0f;
						p.lighting = false;
    				}
				}
			}

			break;
		}

		case 1545514257: //spikeburst
		{
			if(this.hasScript("SpikeBurst.as"))
			{
				return;
			}
			switch(charge_state)
			{
				case minimum_cast:
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					manaInfo.mana += spell.mana;

					return;
				}
				case medium_cast:
				{
					this.set_u8("spikes", 10);
				}
				break;
				case complete_cast:
				{
					this.set_u8("spikes", 14);
					if (this.hasTag("extra_damage"))
					{
						this.set_u8("spikes", 20);
					}
				}
				break;
				case super_cast:
				{
					this.set_u8("spikes", 20);
					if (this.hasTag("extra_damage"))
					{
						this.set_u8("spikes", 24);
					}
				}
				break;
			
				default:return;
			}

			this.set_u32("spikeburst_start", getGameTime());

			if(!this.hasScript("SpikeBurst.as"))
			{
				this.AddScript("SpikeBurst.as");
			}
		}
		break;
		
		case 1833734392: //iciclerain
		{
			if(this.hasScript("IcicleRain.as"))
			{
				return;
			}
			switch(charge_state)
			{
				case minimum_cast:
				{
					this.set_u8("icicles", 10);
					this.set_u8("icicle_delay", 5);
					this.set_u8("icicle_wait", 45);
					this.set_u8("icicle_launch_delay",45);
					this.set_Vec2f("icicles_aimPos", aimpos);
					this.set_bool("static", true);
				}
				case medium_cast:
				{
					this.set_u8("icicles", 10);
					this.set_u8("icicle_delay", 4);
					this.set_u8("icicle_wait", 30);
					this.set_u8("icicle_launch_delay", 3);
					this.set_Vec2f("icicles_aimPos", aimpos);
					this.set_bool("static", true);
				}
				break;
				case complete_cast:
				{
					this.set_u8("icicles", 13);
					this.set_u8("icicle_delay", 3);
					this.set_u8("icicle_wait", 20);
					this.set_u8("icicle_launch_delay", 2);
					this.set_Vec2f("icicles_aimPos", aimpos);
					this.set_bool("static", true);
					if (this.hasTag("extra_damage"))
					{
						this.set_u8("icicles", 20);
					}
				}
				break;
				case super_cast:
				{
					this.set_u8("icicles", 16);
					this.set_u8("icicle_delay", 3);
					this.set_u8("icicle_wait", 15);
					this.set_u8("icicle_launch_delay", 2);
					this.set_bool("static", false);

					if (this.hasTag("extra_damage"))
					{
						this.set_u8("icicles", 20);
						this.set_u8("icicle_delay", 2);
					}
				}
				break;
			
				default:return;
			}

			this.set_u32("icicle_start", getGameTime());

			if(!this.hasScript("IcicleRain.as"))
			{
				this.AddScript("IcicleRain.as");
			}
		}
		break;

		case -412789577://frost_spirit
		{
			if (!isServer())
			{return;}

			f32 extraDamage = this.hasTag("extra_damage") ? 1.3f : 1.0f;
			f32 orbspeed = 6.0f;
			f32 orbDamage = 1.0f * extraDamage;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;

				case super_cast:
				{
					orbspeed *= 1.2f;
					orbDamage += 0.4f;
				}
				break;
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob( "frost_spirit" );
			if (orb !is null)
			{
				orb.set_f32("damage", 2.0f * extraDamage);

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case 1050564475: //lavashot
		{
			if (!isServer()){
           		return;
			}

			if (this.get_u16("waterbarrier") > 0)
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 0.85f, 0.85f);
				return;
			}

			f32 orbspeed = necro_shoot_speed * 0.75f;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.25f : 1.0f;
			f32 orbDamage = 0.5f * extraDamage;

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);

			CBlob@ orb = server_CreateBlob( "lavashot" );
			if (orb !is null)
			{
				if (charge_state == complete_cast) {
					orb.set_u8("lavadrop_time", 30);
					orb.set_u8("lavadrop_amount", 12);
					orbDamage *= 1.15f;
					orbspeed *= 1.15f;
				}
				else if (charge_state == super_cast) {
					orb.set_u8("lavadrop_time", 20);
					orb.set_u8("lavadrop_amount", 16);
					orbDamage *= 1.33f;
					orbspeed *= 1.33f;
				}
				orb.set_f32("damage", orbDamage);

				orbVel.Normalize();
				orbVel *= orbspeed;

				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		
		case 564111203://waterbarrier
		{
			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					manaInfo.mana += spell.mana;
					break;
				}
				case complete_cast:
				case super_cast:
				{
					this.getSprite().PlaySound("WaterBubble1.ogg", 1.5f, 0.75f);
					this.getSprite().PlaySound("WaterBubble2.ogg", 1.25f, 0.75f);

					WaterBarrier(this, charge_state == complete_cast ? 900 : 1350);
					return; //Fireward self, doesn't send projectile
				}
				break;
				
				default:return;
			}
		}
		break;

		
		case -1908358180://chainlightning
		{
			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
		
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "chainlightning", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					switch (charge_state)
					{
						case minimum_cast:
						case medium_cast:
						{
							orb.set_u8("targets", 1);
							orb.set_f32("damage", 1.25f);
							break;
						}
						case complete_cast:
						{
							orb.set_u8("targets", 2);
							orb.set_f32("damage", 1.75f);
							break;
						}
						case super_cast:
						{
							orb.set_u8("targets", 4);
							orb.set_f32("damage", 2.25f);
							break;
						}
						if (this.hasTag("extra_damage"))
						{
							// extra damage is inside the spell's logic
							orb.add_u8("targets", 2);
						}
					}

                    if(this.hasTag("extra_damage"))
                        orb.Tag("extra_damage");

					orb.set_Vec2f("aim pos", aimpos);
					orb.set_u16("follow_id", this.getNetworkID());

					orb.IgnoreCollisionWhileOverlapped( this );
					orb.SetDamageOwnerPlayer( this.getPlayer() );
				}
			}
		}
		break;

		// PALADIN

		case 1909995520: // spiritual connection
		{
			f32 orbspeed = 4.2f;
			u16 effectTime = 1350;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.6f;
					effectTime *= 1.5f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", dmgconnection_effect_missile);
					orb.set_u8("override_sprite_frame", 3); // missile sprite is hardcoded
					orb.set_u16("effect_time", effectTime);
					orb.set_u16("link_id", this.getNetworkID());

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.setVelocity(orbVel);
				}
			}
		}
		break;

		case -1351043648: // celestial crush
		{
			u32 landheight = getLandHeight(aimpos);
			if(landheight != 0)
			{
				this.getSprite().PlaySound("celestialcrushcast.ogg", 1.0f, 0.85f+XORRandom(11)*0.01f);

                if (!isServer())
				{return;}
				
				f32 hitradius = 12;
				f32 orbDamage = 0.35f;
				f32 decel = 0.225f;

				if (this.hasTag("extra_damage"))
				{
					orbDamage += 0.15f;
					hitradius += 4;
				}

				switch(charge_state)
				{
					case minimum_cast:
					case medium_cast:
					case complete_cast:
					break;
					
					case super_cast:
					{
						orbDamage += 0.15f;
						hitradius += 4;
						decel = 0.3f;
					}
					break;
					default:return;
				}

				Vec2f baseSite = Vec2f(aimpos.x , landheight - 8);
				Vec2f cruSpawn = baseSite + Vec2f(0, -12.0f);

				CBlob@ orb = server_CreateBlob("celestialcrush");
				if (orb !is null)
				{
					orb.SetFacingLeft(this.isFacingLeft());
					orb.set_f32("damage", orbDamage);

					orb.set_f32("hitradius", hitradius);
					orb.set_f32("deceleration", decel);
					orb.Sync("hitradius", true);
					orb.Sync("deceleration", true);

					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.getShape().SetGravityScale(0);
					orb.server_setTeamNum(this.getTeamNum());
					orb.setPosition(cruSpawn);
				}
			}
            else//Can't place this under the map
            {
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo ))
				{return;}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
            }
		}
		break;

		case 1676183192: // templar hammer
		{
			if (!isServer())
			{return;}

			bool extra_damage = this.hasTag("extra_damage");
			int numOrbs = extra_damage ? 3 : 1;
			
            switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					numOrbs += 2;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,0);
			Vec2f orbVel = (aimpos - orbPos);
			
			f32 angle = 5.0f;
			f32 tot_angle = numOrbs * angle;
			for (int i = 0; i < numOrbs; i++)
			{
				CBlob@ orb = server_CreateBlob("templarhammer");
				if (orb !is null)
				{
					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.server_setTeamNum(this.getTeamNum());
					orb.getShape().SetGravityScale(0.0f);
					orb.setPosition(orbPos);
					orb.getShape().SetGravityScale(0.0f);
				
					Vec2f aim = aimpos;
					Vec2f vel = aim - thispos;
					Vec2f norm = vel;
					norm.Normalize();

					f32 ff = (this.isFacingLeft()?-1:1);

					if (numOrbs > 1) norm.RotateBy(ff*(-tot_angle/2 + angle/2*i + i*angle));
					orb.setVelocity(norm*12);
				}
			}
		}
		break;
		
		case 895532553://manatohealth
		{
			bool state = this.get_bool("manatohealth");
			ManaToHealth(this, !state);

			bool other = this.get_bool("damagetomana");
			if (other) DamageToMana(this, false);
		}
		break;

		case -1449680114://damagetomana
		{
			bool state = this.get_bool("damagetomana");
			DamageToMana(this, !state);

			bool other = this.get_bool("manatohealth");
			if (other) ManaToHealth(this, false);
		}
		break;

		case 1006366403: //healblock
		{
			f32 orbspeed = 3.25f;
			u16 effectTime = 1800;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					orbspeed *= 1.75f;
					effectTime = 1350;
				}
				break;

				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;
			
			if (isServer())
			{
				CBlob@ orb = server_CreateBlob("effect_missile", this.getTeamNum(), orbPos ); 
				if (orb !is null)
				{
					orb.set_u8("effect", healblock_effect_missile);
					orb.set_u8("override_sprite_frame", 0);
					orb.set_u16("effect_time", effectTime);

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.setVelocity(orbVel);
				}
			}
		}
		break;

		case -774033844://hallowedbarrier
		{
			u8 amount = 3;
			u16 effectTime = 1800;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				{
					effectTime = 900;
					amount = 4;
				}
				break;
				case complete_cast:
				{
					effectTime = 1350;
					amount = 5;
				}
				break;
				
				case super_cast:
				{
					effectTime = 1800;
					amount = 6;
				}
				break;

				default:return;
			}

			if (this.hasTag("extra_damage"))
			{
				amount += 2;
			}

			Barrier(this, effectTime, amount);
		}
		break;

		case -1347011254://majesty glyph
		{
			f32 orbspeed = 4.0f;
			u16 effectTime = 1350;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					effectTime = 900;
				}
				break;
				
				case super_cast:
				{
					effectTime *= 1.5f;
					CooldownReduce(this, effectTime, 0.5f);
					return;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob("effect_missile", this.getTeamNum(), orbPos); 
				if (orb !is null)
				{
					orb.set_u8("effect", cooldownreduce_effect_missile);
					orb.set_u8("override_sprite_frame", 10);
					orb.set_u16("effect_time", effectTime);
					
					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.setVelocity(orbVel);
				}
			}
		}
		break;

		case -842442030://seal of wisdom
		{
			f32 orbspeed = 4.0f;
			u16 effectTime = 1350;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
					orbspeed *= 1.0f;
					effectTime = 1500;
				}
				break;
				
				case super_cast:
				{
					effectTime = 1800;
					AntiDebuff(this, effectTime);
					return;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			if (isServer())
			{
				bool targetless = true;

				CBlob@[] blobs;
				getBlobsByTag("player",@blobs);
				int bestIndex = closestBlobIndex(this,blobs,true);

				if(bestIndex != -1)
				{
					targetless = false;
				}

				CBlob@ orb = server_CreateBlob("effect_missile", this.getTeamNum(), orbPos); 
				if (orb !is null)
				{
					orb.set_u8("effect", antidebuff_effect_missile);
					orb.set_u8("override_sprite_frame", 11);
					orb.set_u16("effect_time", effectTime);
					
					if(!targetless)
					{
						CBlob@ target = blobs[bestIndex];
						if(target !is null)
						{
							orb.set_netid("target", target.getNetworkID());
							orb.set_bool("target found", true);
						}
					}

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.setVelocity(orbVel);
				}
			}
		}
		break;
		
		case -258200095://fury
		{
			if (!isServer()){
           		return;
			}

			f32 orbspeed = necro_shoot_speed * 0.25f;
			bool extraDamage = this.hasTag("extra_damage");
			int bladesRate = 10;
            
			if (charge_state == super_cast) {
				orbspeed *= 1.25f;
				bladesRate -= 2;
			}
			if (extraDamage)
				bladesRate -= 2;

			Vec2f orbPos = thispos;
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob("fury");
			if (orb !is null)
			{
				orb.set_f32("spawnrate", bladesRate);
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
			}
		}
		break;

		case -1482927474://noble lance
		{
			this.getSprite().PlaySound("hammercast.ogg", 1.0f, 0.75f+XORRandom(6)*0.01f);

			if (!isServer()){
           		return;
			}

			f32 extraDamage = this.hasTag("extra_damage") ? 1.25f : 1.0f;
			f32 orbDamage = 1.0f * extraDamage;
			f32 velo = 7.0f;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				break;

				case complete_cast:
				{
					velo += 2.0f;
					orbDamage *= 1.25f;
				}
				break;
				
				case super_cast:
				{
					velo += 2.0f;
					orbDamage *= 1.25f;
				}
				break;
				
				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);

			CBlob@ orb = server_CreateBlob("noblelance",this.getTeamNum(),orbPos);
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);
				orb.set_Vec2f("target_pos", aimpos);
				orb.set_f32("speed", velo);
				
				Vec2f dir = aimpos - this.getPosition();
				f32 deg = -dir.Angle();
				orb.setAngleDegrees(deg);

				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.getShape().SetGravityScale(0);
			}
		}
		break;

		case -836474293://faith glaive
		{
			f32 damage = 1.0f;
			f32 extraDamage = this.hasTag("extra_damage") ? 1.5f : 1.0f;

			switch(charge_state)
			{
				case minimum_cast:
				{
					return;
				}
				case medium_cast:
				{
					damage = 1.5f;
				}
				break;
				case complete_cast:
				{
					damage = 2.0f;
				}
				break;
				
				case super_cast:
				{
					damage = 3.0f;
				}
				break;
				
				default:return;
			}

			damage *= extraDamage;
			
			if(!this.hasScript("FaithGlaive.as"))
			{
				this.getSprite().PlaySound("swordsummon.ogg", 1.5f, 0.85f+XORRandom(6)*0.01f);

				this.set_bool("faithglaiveplaysound", true);
				this.set_f32("faithglaivedamage", damage);
				this.set_f32("faithglaiverotation", 0);
				this.set_u32("faithglaivetiming", getGameTime());

				this.AddScript("FaithGlaive.as");
			}
			else
			{
				ManaInfo@ manaInfo;
				if (!this.get( "manaInfo", @manaInfo )) {
					return;
				}
				
				manaInfo.mana += spell.mana;
				
				this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
			}
		}
		break;

		case -1260314500: //bless circle
			if(isServer())
			{
				CBlob@ circle = server_CreateBlob('bless_circle',3,aimpos);
				circle.SetDamageOwnerPlayer(this.getPlayer());
				circle.set_s32("aliveTime",charge_state == 5 ? 1800 : 1350);
			}
		break;

		// JESTER

		case -1436608895: //jestergas
		{
			this.getSprite().PlayRandomSound("gasleak", 0.85f, 0.85f+XORRandom(26)*0.01f);
			//this.getSprite().PlayRandomSound("klaxon"+XORRandom(4), 0.66f, 1.25f+XORRandom(16)*0.01f);
			
			if (!isServer()){
           		return;
			}
			f32 extraDamage = this.hasTag("extra_damage") ? 0.1f : 0.0f;
			f32 orbspeed = 2.5f + XORRandom(6)*0.1f;
			f32 orbDamage = 0.2f + extraDamage;
			u8 max_hits = this.hasTag("extra_damage") ? 7 : 5;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				{
				}
				break;

				case super_cast:
				{
					orbDamage += 0.1f;
					orbspeed *= 1.5f;
					max_hits += 1;
				}
				break;

				default:return;
			}

			Vec2f orbPos = thispos + Vec2f(0.0f,-2.0f);
			Vec2f orbVel = (aimpos - orbPos);
			orbVel.Normalize();
			orbVel *= orbspeed;

			CBlob@ orb = server_CreateBlob("jestergas");
			if (orb !is null)
			{
				orb.set_f32("dmg", orbDamage);
				orb.set_s8("hits", max_hits);
				orb.IgnoreCollisionWhileOverlapped( this );
				orb.SetDamageOwnerPlayer( this.getPlayer() );
				orb.server_setTeamNum( this.getTeamNum() );
				orb.setPosition( orbPos );
				orb.setVelocity( orbVel );
				orb.server_SetTimeToDie(15+XORRandom(6));
			}
		}
		break;
		
		case -1962610873: //flowerpad
		{
			if (isClient())
			{
				this.getSprite().PlayRandomSound("VineReveal", 1.25f, 1.3f+XORRandom(31)*0.01f);
				this.getSprite().PlayRandomSound("TreeGrow", 0.75f, 1.1f+XORRandom(21)*0.01f);
			}

			{
				CBlob@[] totems;
				getBlobsByName("flowerpad",@totems);

				if (this.getPlayer() is null)
				{return;}

				for(int i = 0; i < totems.length; i++)
				{
					if (totems[i] is null)
					{continue;}
					if (totems[i].getDamageOwnerPlayer() is null)
					{continue;}
					if(totems[i].getDamageOwnerPlayer().getNetworkID() == this.getPlayer().getNetworkID())
					{
						totems[i].server_Die();
						break;
					}
				}

				int height = getLandHeight(aimpos);
				if(height != 0)
				{
					if(isServer())
					{
						CBlob@ tot = server_CreateBlob("flowerpad",this.getTeamNum(),Vec2f(aimpos.x,height-8) );
						tot.SetDamageOwnerPlayer(this.getPlayer());

						switch (charge_state)
						{
							case 1:
							case 2:
							{
								tot.set_s32("aliveTime", 1800);
								break;
							}
							case 3:
							{
								tot.set_u16("charge_delay", 120);
								tot.set_s32("aliveTime", 2100); //1m10s
								break;
							}
							case 4:
							{
								tot.set_u16("charge_delay", 115);
								tot.set_s32("aliveTime", 2400);//1m20s
								break;
							}
							case 5:
							{
								tot.set_u16("charge_delay", 105);
								tot.set_s32("aliveTime", 2700); //1m30s
								break;
							}
						}
						if (this.hasTag("extra_damage"))
						{
							tot.set_s32("aliveTime", 2700); //1m30s
							tot.set_u16("charge_delay", 105);
						}
					}
				}
				else
				{
					ManaInfo@ manaInfo;
					if (!this.get( "manaInfo", @manaInfo )) {
						return;
					}
					
					manaInfo.mana += spell.mana;
					
					this.getSprite().PlaySound("ManaStunCast.ogg", 1.0f, 1.0f);
				}
			}
			break;
		}
		
		case 1127025508: //mitten 
		{
			if (!isServer()){
           		return;
			}

			u8 state = 1;

			switch(charge_state)
			{
				case minimum_cast:
				case medium_cast:
				case complete_cast:
				break;
				
				case super_cast:
				{
					state = 3;
				}
				break;
				
				default:return;
			}

			bool respawn = true;
			Vec2f orbPos = thispos + Vec2f(0.0f,-32.0f);
			if (player !is null)
			{
				CBlob@[] bs;
				getBlobsByTag(player.getUsername(), bs);
				for (u8 i = 0; i < bs.size(); i++)
				{
					CBlob@ mitten = bs[i];
					if (mitten !is null && mitten.get_u8("state") == 0)
					{
						respawn = false;
						mitten.set_u8("state", state);
						mitten.set_Vec2f("aimpos", aimpos);
						mitten.set_bool("force_fl", aimpos.x < this.getPosition().x);
						mitten.server_SetTimeToDie(30);

						mitten.getSprite().SetAnimation("transform");
					}
				}
			}

			if (respawn)
			{
				CBlob@ orb = server_CreateBlob("mitten", this.getTeamNum(), aimpos);
				if (orb !is null)
				{
					orb.set_u16("caster", this.getNetworkID());
					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getPlayer());
					orb.setAngleDegrees(-(this.getAimPos()-orb.getPosition()).Angle());
				}
			}
		}
		break;

		case -1428802522://pogostick
		{
			if (this.hasScript("PogoStick.as"))
			{
				this.Tag("pogo_remove");
			}

			if (!this.hasScript("PogoStick.as"))
			{
				this.AddScript("PogoStick.as");
			}
		}
		break;

		default:
		{
			if (spell.type == SpellType::summoning)
			{
				Vec2f pos = aimpos + Vec2f(0.0f,-0.5f*this.getRadius());
				SummonZombie(this, spellName, pos, this.getTeamNum());
			}
			else if ( spellName.getHash() == -2128831035)
			{
				//print("someone just used the blank spell :facepalm:");
			}
			else
			{
				print("spell not found " + spellName +  " with spell hash : " + spellName.getHash()+'' + " in file : spellCommon.as");
			}
		}
	}
}

void Freeze(CBlob@ blob, f32 frozenTime)
{	
	blob.getShape().getConsts().collideWhenAttached = false;

	Vec2f blobPos = blob.getPosition();
	if(isServer())
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
		
		if(kill)
		{
			b.Untag("exploding");
			b.server_Die();
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

void Heal( CBlob@ blob, f32 healAmount )
{
	f32 health = blob.getHealth();
	f32 initHealth = blob.getInitialHealth();
	
	if ( (health + healAmount) > initHealth )
		blob.server_SetHealth(initHealth);
	else
		blob.server_SetHealth(health + healAmount);
		
    if (blob.isMyPlayer())
    {
        SetScreenFlash( 80, 0, 225, 0 );
    }
		
	blob.getSprite().PlaySound("Heal.ogg", 0.8f, 1.0f + (0.2f * _spell_common_r.NextFloat()) );
	makeHealParticles(blob);
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
			
			blob.server_Die();
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
			
			blob.server_Die();
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
			
			blob.server_Die();
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
			if ( b.hasTag("counterable") && (!sameTeam || b.hasTag("alwayscounter")) )
			{
				b.Untag("exploding");
				b.server_Die();
				if (b.getName() == "plant_aura")
				{retribution = true;}
					
				countered = true;
			}
			else if ( b.get_u16("slowed") > 0 && sameTeam )
			{				
				b.set_u16("slowed", 1);
				b.Sync("slowed", true);
					
				countered = true;
			}
			else if ( b.get_u16("manaburn") > 0 && sameTeam )
			{				
				b.set_u16("manaburn", 1);
				b.Sync("manaburn", true);
					
				countered = true;
			}
			else if ( b.get_u16("healblock") > 0 && sameTeam )
			{				
				b.set_u16("healblock", 1);
				b.Sync("healblock", true);
					
				countered = true;
			}
			else if (
			(b.get_u16("hastened") > 0
			 || b.get_u16("regen") > 0
			 || b.get_u16("fireProt") > 0 
			 || b.get_u16("airblastShield") > 0 
			 || b.get_u16("stoneSkin") > 0
			 || b.get_u16("waterbarrier") > 0
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

				if (b.get_u16("waterbarrier") > 0)
				{
					b.set_u16("waterbarrier", 1);
					b.Sync("waterbarrier", true);
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
			else if(!sameTeam && (b.hasTag("circle") || b.hasTag("totem")))
			{
				b.add_u8("despelled",1);
				countered = true;
			}
			if ( retribution == true )
			{
				/*ManaInfo@ manaInfo;
				if (!caster.get( "manaInfo", @manaInfo )) {
					return;
				}
				manaInfo.mana += 10;*/
				if(caster !is null)
				{Heal(caster, 1.0f);}
			}

			if ( countered == true )
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
						p.Z = 600.0f;
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

void Slow( CBlob@ blob, u16 slowTime )
{	
	if ( blob.get_u16("hastened") > 0 )
	{
		blob.set_u16("hastened", 1);
		blob.Sync("hastened", true);
	}
	else
	{
		blob.set_u16("slowed", slowTime);
		blob.Sync("slowed", true);
		blob.getSprite().PlaySound("SlowOn.ogg", 0.8f, 1.0f + XORRandom(1)/10.0f);
	}
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

	blob.set_f32("majestyglyph_cd_reduction", 0.5f);
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

void WaterBarrier( CBlob@ blob, u16 wardTime )
{
	blob.set_u16("waterbarrier", wardTime);
	blob.Sync("waterbarrier", true);
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