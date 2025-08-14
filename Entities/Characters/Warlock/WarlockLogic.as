// Warlock logic

#include "WarlockCommon.as"
#include "PlayerPrefsCommon.as"
#include "MagicCommon.as";
#include "ThrowCommon.as"
#include "KnockedCommon.as"
#include "Hitters.as"
#include "RunnerCommon.as"
#include "ShieldCommon.as";
#include "Help.as";
#include "BombCommon.as";
#include "SpellCommon.as";
#include "SpellUtils.as";

void onInit( CBlob@ this )
{
	WarlockInfo warlock;
	this.set("warlockInfo", @warlock);
	
	ManaInfo manaInfo;
	manaInfo.maxMana = WarlockParams::MAX_MANA;
	manaInfo.mana = 0;
	manaInfo.manaRegen = WarlockParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);

	this.set_s8( "charge_time", 0 );
	this.set_u8( "charge_state", WarlockParams::not_aiming );
	this.set_s32( "mana", 100 );
	this.set_f32("gib health", -3.0f);
	this.set_Vec2f("spell blocked pos", Vec2f(0.0f, 0.0f));
	this.set_bool("casting", false);
	this.set_bool("was_casting", false);
	//this.set_bool("shiftlaunch", false);

	Vec2f[] positions;
	this.set("old_positions", @positions);
	
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("ignore crouch");
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	this.set_bool("plague", false);

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
    this.addCommandID("freeze");
    this.addCommandID("spell");
	this.addCommandID("chronomantic_teleport");
	this.addCommandID("add_sb_cast");
	this.getShape().getConsts().net_threshold_multiplier = 1.5f;
	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_up | CBlob::map_collide_nodeath);
	this.getCurrentScript().removeIfTag = "dead";

	if(isServer())
		this.set_u8("spell_count", 0);
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 16, Vec2f(16,16));
	}
}

void ManageSpell( CBlob@ this, WarlockInfo@ warlock, PlayerPrefsInfo@ playerPrefsInfo, RunnerMoveVars@ moveVars )
{
	CSprite@ sprite = this.getSprite();
	bool ismyplayer = this.isMyPlayer();
	s32 charge_time = warlock.charge_time;
	u8 charge_state = warlock.charge_state;
	
	u8 spellID = playerPrefsInfo.primarySpellID;
	int hotbarLength = playerPrefsInfo.hotbarAssignments_Warlock.length;
	
	ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}	
    s32 wizMana = manaInfo.mana;

    string casting_key = "a1";
    bool is_pressed = this.isKeyPressed( key_action1 );
    bool just_pressed = this.isKeyJustPressed( key_action1 );
    bool just_released = this.isKeyJustReleased( key_action1 );

    bool is_secondary = false;
	bool is_aux1 = false;
	bool is_aux2 = false;
	
    if (!is_pressed and !just_released and !just_pressed)	//secondary hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(15,hotbarLength-1)];

        is_pressed = this.isKeyPressed( key_action2 );
		casting_key = "a2";
        just_pressed = this.isKeyJustPressed( key_action2 );
        just_released = this.isKeyJustReleased( key_action2 );

        is_secondary = true;
    }
    if (!is_pressed and !just_released and !just_pressed)	//auxiliary1 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(16,hotbarLength-1)];
		
        is_pressed = this.isKeyPressed( key_action3 );
		casting_key = "a3";
        just_pressed = this.isKeyJustPressed( key_action3 );
        just_released = this.isKeyJustReleased( key_action3 ); 

        is_aux1 = true;
    }
    if (!is_pressed and !just_released and !just_pressed)	//auxiliary2 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(17,hotbarLength-1)];
		
        is_pressed = this.isKeyPressed( key_taunts );
		casting_key = "a4";
        just_pressed = this.isKeyJustPressed( key_taunts );
        just_released = this.isKeyJustReleased( key_taunts ); 

        is_aux2 = true;
    }
	CRules@ rules = getRules();
	if (rules is null) return;
	if (isClient() && rules.get_bool("showHelp"))
	{
		is_pressed = false;
		just_pressed = false;
		just_released = false;

		is_secondary = false;
		is_aux1 = false;
		is_aux2 = false;

		casting_key = "a1";
	}

	this.set_string("casting_key", casting_key);
	
	Spell spell = WarlockParams::spells[spellID];

	//raycast arrow

	Vec2f pos = this.getPosition();
	Vec2f aimpos = this.getAimPos();
	Vec2f aimVec = aimpos - pos;
	Vec2f normal = aimVec;
	normal.Normalize();

	Vec2f tilepos = pos + normal * Maths::Min(aimVec.Length() - 1, spell.range);
	CMap@ map = this.getMap();
	Vec2f surfacePaddingVec = normal*4.0f;
	Vec2f surfacepos;
	bool aimPosBlocked = map.rayCastSolid(pos, tilepos + surfacePaddingVec, surfacepos);
	Vec2f spellPos = surfacepos - surfacePaddingVec;
	
	//Were we casting?
	this.set_bool("was_casting", this.get_bool("casting"));

	//Are we casting? 
	if ( is_pressed )
	{
		this.set_bool("casting", true);
		this.set_Vec2f("spell blocked pos", spellPos);
	}
	else
		this.set_bool("casting", false);

    // info about spell
    s32 readyTime = spell.readyTime;
    u8 spellType = spell.type;

    if (just_pressed)
    {
        charge_time = 0;
        charge_state = 0;
    }
	
	CControls@ controls = getControls();
	//cancel charging
	if ( controls.isKeyPressed( KEY_MBUTTON ) || warlock.spells_cancelling == true )
	{
		charge_time = 0;
		charge_state = WarlockParams::not_aiming;
		
		if (warlock.spells_cancelling == false)
		{
			sprite.PlaySound("PopIn.ogg", 1.0f, 1.0f);
		}
		warlock.spells_cancelling = true;	
		
		// only stop cancelling once all spells buttons are released
		if (!is_pressed)
		{
			warlock.spells_cancelling = false;
		}
	}

	f32 mod = 1.0f;
	if (this.hasTag("carnage_effect")) mod = 2.0f;

	f32 wizHealth = this.getHealth();
	bool enough_health = spell.type == SpellType::healthcost ? wizHealth >= spell.mana : wizHealth >= spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
	bool canCastSpell = ((spell.type == SpellType::healthcost ? wizHealth * 10 : wizMana) >= spell.mana || enough_health) && playerPrefsInfo.spell_cooldowns[spellID] <= 0;

    if (is_pressed && canCastSpell) 
    {
        moveVars.walkFactor *= 0.8f;
        charge_time += 1 * mod;

        if (charge_time >= spell.full_cast_period)
        {
            charge_state = WarlockParams::extra_ready;
            charge_time = spell.full_cast_period;
        }
        else if (charge_time >= spell.cast_period)
        {
            charge_state = WarlockParams::cast_3;
        }
        else if (charge_time >= spell.cast_period_2)
        {
            charge_state = WarlockParams::cast_2;
        }
        else if (charge_time >= spell.cast_period_1)
        {
            charge_state = WarlockParams::cast_1;
        }
    }
    else if (just_released)
    {
        if (canCastSpell && charge_state > WarlockParams::charging && not (spell.needs_full && charge_state < WarlockParams::cast_3) &&
            (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot()))
        {
            CBitStream params;
            params.write_u8(charge_state);
			u8 castSpellID;
			if ( is_aux2 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(17,hotbarLength-1)];
			else if ( is_aux1 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(16,hotbarLength-1)];
			else if ( is_secondary )
				castSpellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(15,hotbarLength-1)];
			else
				castSpellID = playerPrefsInfo.primarySpellID;
            CBlob@ target = spell.target_type == 2 ? client_getNearbySpellTarget(this, spell.range, spell.target_grab_range) : null;

			u16 targetID = 0;
			if (target !is null) targetID = target.getNetworkID();

			Spell castSpell = WarlockParams::spells[castSpellID];
			bool can_apply_cd_time = !this.hasTag("carnage_effect") || castSpell.typeName == "carnage";
			if (!can_apply_cd_time && this.hasTag("carnage_effect"))
				this.Untag("carnage_effect");

            params.write_u8(castSpellID);
            params.write_Vec2f(spellPos);
			params.write_Vec2f(pos);
			params.write_Vec2f(this.getAimPos());
			params.write_u16(targetID);
			this.SendCommand(this.getCommandID("spell"), params);
			
			int spell_cd_time = WarlockParams::spells[castSpellID].cooldownTime * getTicksASecond();
			f32 cd_reduction_factor = 1.0f * this.get_f32("majestyglyph_cd_reduction");
			int apply_cd_time = (spell_cd_time == 0 ? 0 : spell_cd_time * cd_reduction_factor);

			playerPrefsInfo.spell_cooldowns[castSpellID] = can_apply_cd_time ? apply_cd_time : 0;
        }
		
        charge_state = WarlockParams::not_aiming;
        charge_time = 0;
    }

    warlock.charge_time = charge_time;
    warlock.charge_state = charge_state;

    if ( ismyplayer )
    {
		if (!getHUD().hasButtons()) 
		{
			int frame = 0;
            if (charge_state == WarlockParams::extra_ready) {
                frame = 15 + (getGameTime()/(this.hasTag("extra_damage")?4:5))%12;	
            }
            else if (warlock.charge_time > spell.cast_period)
            {
                frame = 12 + warlock.charge_time % 15 / 5;
            }
			else if (warlock.charge_time > 0) {
				frame = warlock.charge_time * 12 /spell.cast_period; 
			}

			getHUD().SetCursorFrame(frame);
		}

        if (this.isKeyJustPressed(key_action3))
        {
			client_SendThrowOrActivateCommand( this );
        }
    }

	if (rules is null) return;
	if ( !is_pressed && rules.get_bool("spell_number_selection") )
	{
		if (WarlockParams::spells.length == 0) 
		{
			return;
		}

		WarlockInfo@ warlock;
		if (!this.get( "warlockInfo", @warlock )) 
		{
			return;
		}
		
		bool spellSelected = this.get_bool("spell selected");
		int currHotkey = playerPrefsInfo.primaryHotkeyID;
		int nextHotkey =  playerPrefsInfo.hotbarAssignments_Warlock.length;
		
		
		if (rules !is null && rules.hasTag("update_spell_selected")
			&& rules.exists("reset_spell_id") && rules.get_u16("reset_spell_id") > 0)
		{
			rules.Untag("update_spell_selected");

			currHotkey = rules.get_u16("reset_spell_id")-1;
			nextHotkey = currHotkey;
		}

		if ( controls.isKeyJustPressed(KEY_KEY_1) || controls.isKeyJustPressed(KEY_NUMPAD1) )
		{
			if ( (currHotkey == 0 || currHotkey == 5) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 0;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_2) || controls.isKeyJustPressed(KEY_NUMPAD2) )
		{
			if ( (currHotkey == 1 || currHotkey == 6) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 1;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_3) || controls.isKeyJustPressed(KEY_NUMPAD3))
		{
			if ( (currHotkey == 2 || currHotkey == 7) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 2;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_4) || controls.isKeyJustPressed(KEY_NUMPAD4) )
		{
			if ( (currHotkey == 3 || currHotkey == 8) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 3;
		}
		else if ( controls.isKeyJustPressed(KEY_KEY_5) || controls.isKeyJustPressed(KEY_NUMPAD5) )
		{
			if ( (currHotkey == 4 || currHotkey == 9) && !spellSelected )
				nextHotkey = currHotkey + 5;
			else
				nextHotkey = 4;
		}
		
		if ( nextHotkey <  playerPrefsInfo.hotbarAssignments_Warlock.length )
		{
			playerPrefsInfo.primaryHotkeyID = nextHotkey;
			playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Warlock[nextHotkey];
			this.set_bool("spell selected", false);
			
			sprite.PlaySound("PopIn.ogg");
		}
	}
	else
		this.set_bool("spell selected", true);
}

void onTick(CBlob@ this)
{
	// heal up to 5 hp slightly every 3 seconds
	if (this.getHealth() < 0.5f && this.getTickSinceCreated() % 90 == 0)
	{
		this.server_Heal(0.025f);
		if (this.getHealth() > 0.5f)
		{
			this.server_SetHealth(0.5f);
		}
	}

	if (this.getTickSinceCreated() % old_positions_save_threshold == 0)
	{
		Vec2f[]@ positions;
		if (this.get("old_positions", @positions))
		{
			if (positions.size() > positions_save_time_in_seconds * Maths::Round(f32(getTicksASecond()) / f32(old_positions_save_threshold)))
			{
				positions.erase(positions.size() - 1);
			}
			
			positions.insertAt(0, this.getPosition());
		}
	}

	if (getNet().isServer())
	{
		if(getGameTime() % 5 == 0)
		{
			u8 spellcount = this.get_u8("spell_count");
			if(spellcount > 1)
			{
				
			}
			else if(spellcount != 0)
			{
				this.set_u8("spell_count", 0);
			} 
		}
	}		

	
    WarlockInfo@ warlock;
	if (!this.get( "warlockInfo", @warlock )) 
	{
		return;
	}
	
	CPlayer@ thisPlayer = this.getPlayer();
	if ( thisPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!thisPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}
	
	if ( playerPrefsInfo.infoLoaded == false )
	{
		return;
	}

	/*if(getKnockedRemaining(this) > 0)
	{
		warlock.charge_state = 0;
		warlock.charge_time = 0;
		return;
	}*/

    RunnerMoveVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv

	if (!getNet().isClient()) return;

	if (this.isInInventory()) return;

    ManageSpell( this, warlock, playerPrefsInfo, moveVars );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("spell"))  //from standardcontrols
    {
		ManaInfo@ manaInfo;
		if (!this.get( "manaInfo", @manaInfo )) 
		{
			return;
		}
	
        u8 charge_state = params.read_u8();
		u8 spellID = params.read_u8();
		
        Spell spell = WarlockParams::spells[spellID];
        Vec2f aimpos = params.read_Vec2f();
		Vec2f thispos = params.read_Vec2f();
		Vec2f serverAimPos = params.read_Vec2f();
		u16 targetID = params.read_u16();

		f32 wizHealth = this.getHealth();
		f32 wizMana = manaInfo.mana;
		bool enough_health = spell.type == SpellType::healthcost ? wizHealth * 10 >= spell.mana : wizHealth >= spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
		
		if (wizMana >= spell.mana && spell.type != SpellType::healthcost)
		{
			manaInfo.mana -= spell.mana;
			CastSpell(this, charge_state, spell, aimpos, thispos, targetID);
		}
		else if (enough_health && spell.type != SpellType::healthcost)
		{
			f32 missingMana = spell.mana - wizMana;

			manaInfo.mana = 0;
			f32 healthCost = healthCost = missingMana * WarlockParams::HEALTH_COST_PER_1_MANA;

			this.server_Hit(this, this.getPosition(), Vec2f_zero, healthCost, Hitters::fall, true);
			CastSpell(this, charge_state, spell, aimpos, thispos, targetID, wizMana, healthCost);
		}
		else if (enough_health)
		{
			f32 healthCost = spell.mana * 0.2f;
			
			this.server_Hit(this, this.getPosition(), Vec2f_zero, healthCost, Hitters::fall, true);
			CastSpell(this, charge_state, spell, aimpos, thispos, targetID, 0, healthCost);
		}
	}
	else if (cmd == this.getCommandID("freeze"))
	{
		u16 blobid;
		f32 power;
		
		if (!params.saferead_u16(blobid)) return;
		if (!params.saferead_f32(power)) return;

		CBlob@ b = getBlobByNetworkID(blobid);
		if (b is null) return;

		Freeze(b, 2.0f*power);
	}
	else if (cmd == this.getCommandID("add_sb_cast"))
	{
		if (isClient() && !this.hasScript("ShadowBurstCast.as"))
		{
			u32 cast_time = params.read_u32();
			u8 max_count = params.read_u8();
			u8 period = params.read_u8();
			f32 speed = params.read_f32();
			f32 damage = params.read_f32();
			u8 unused = params.read_u8();

			this.set_u32("shadowburst_cast_time", cast_time);
			this.set_u8("shadowburst_count", max_count);
			this.set_u8("shadowburst_period", period);
			this.set_f32("shadowburst_speed", speed);
			this.set_f32("shadowburst_damage", damage);
			this.set_u8("shadowburst_current_count", 0);

			this.AddScript("ShadowBurstCast.as");
		}
	}
	else if (cmd == this.getCommandID("chronomantic_teleport"))
	{
		u8 spellType;
		if (!params.saferead_u8(spellType)) return;

		f32 cost;
		if (!params.saferead_f32(cost)) return;

		Vec2f pos;
		if (!params.saferead_Vec2f(pos)) return;

		s32 charge_state;
		if (!params.saferead_s32(charge_state)) return;

		bool extra_damage;
		if (!params.saferead_bool(extra_damage)) return;

		bool return_mana = false;
		if (charge_state <= 4)
		{
			int seed = pos.x * pos.y;
			Vec2f at = getRandomFloorLocationOnMap(seed, pos);

			if (at == Vec2f_zero)
			{
				return_mana = true;
			}

			this.setPosition(at);
			this.setVelocity(Vec2f_zero);

			if (isClient())
			{
				this.getSprite().PlaySound("warp_teleport.ogg", 0.65f, 1.35f+XORRandom(21)*0.01f);
			}

			ParticleAnimated("Flash3.png",
							  at,
							  Vec2f(0,0),
							  360.0f * XORRandom(100) * 0.01f,
							  1.0f, 
							  3, 
							  0.0f, true);
		}
		else
		{
			u8 seconds_warp = Maths::Min(5, positions_save_time_in_seconds);
			if (extra_damage) seconds_warp = Maths::Min(10, positions_save_time_in_seconds);

			Vec2f[]@ positions;
			if (!this.get("old_positions", @positions))
			{
				return_mana = true;
			}
			else
			{
				int index = Maths::Min(positions.length-1, seconds_warp * Maths::Round(f32(getTicksASecond()) / f32(old_positions_save_threshold)));
				if (index < 0 || index >= positions.length)
				{
					return_mana = true;
				}
				else
				{
					Vec2f at = positions[index];
					Vec2f prev = positions[index == positions.size() - 1 ? index : index + 1];
					Vec2f vel = prev == Vec2f_zero ? Vec2f_zero : (at-prev).Length() < 32 ? at - prev : Vec2f_zero;
	
					this.setPosition(at);
					this.setVelocity(vel);

					if (isClient())
					{
						this.getSprite().PlaySound("warp_teleport.ogg", 0.65f, 1.35f+XORRandom(21) * 0.01f);
					}

					ParticleAnimated("Flash3.png",
									  at,
									  Vec2f(0,0),
									  360.0f * XORRandom(100) * 0.01f,
									  1.0f, 
									  3, 
									  0.0f, true);
				}
			}
		}

		if (return_mana)
		{
			ManaInfo@ manaInfo;
			if (!this.get( "manaInfo", @manaInfo )) 
			{
				return;
			}

			if (spellType == SpellType::healthcost) Heal(this, this, cost);
			else manaInfo.mana += cost;

			return;
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    if ((hitterBlob.getName() == "wraith" || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;

	if (isServer() && damage > 0.1f)
	{
		CBlob@[] demons;
		getBlobsByTag("demon_of_" + this.getNetworkID(), @demons);

		for (u8 i = 0; i < demons.length; i++)
		{
			CBlob@ demon = demons[i];
			if (demon !is null)
			{
				demon.set_u16("charges", damage * 5); // for 1 hp damage we restore 1 charges
				demon.Sync("charges", true);
			}
		}
	}

    return damage;
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
	if (customData == Hitters::stab)
	{
		if (damage > 0.0f)
		{

			// fletch arrow
			if ( hitBlob.hasTag("tree") )	// make arrow from tree
			{
				if (getNet().isServer())
				{
					CBlob@ mat_arrows = server_CreateBlob( "mat_arrows", this.getTeamNum(), this.getPosition() );
					if (mat_arrows !is null)
					{
						mat_arrows.server_SetQuantity(10);//fletch_num_arrows);
						mat_arrows.Tag("do not set materials");
						this.server_PutInInventory( mat_arrows );
					}
				}
				this.getSprite().PlaySound( "Entities/Items/Projectiles/Sounds/ArrowHitGround.ogg" );
			}
			else
				this.getSprite().PlaySound("KnifeStab.ogg");
		}

		if (blockAttack(hitBlob, velocity, 0.0f))
		{
			this.getSprite().PlaySound("/Stun", 1.0f, this.getSexNum() == 0 ? 1.0f : 2.0f);
			setKnocked( this, 30 );
		}
	}
}