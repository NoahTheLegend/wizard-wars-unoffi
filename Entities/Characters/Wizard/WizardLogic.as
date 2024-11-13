// Wizard logic

#include "WizardCommon.as"
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

void onInit( CBlob@ this )
{
	WizardInfo wizard;
	this.set("wizardInfo", @wizard);
	
	ManaInfo manaInfo;
	manaInfo.maxMana = WizardParams::MAX_MANA;
	manaInfo.manaRegen = WizardParams::MANA_REGEN;
	this.set("manaInfo", @manaInfo);

	this.set_s8( "charge_time", 0 );
	this.set_u8( "charge_state", WizardParams::not_aiming );
	this.set_s32( "mana", 100 );
	this.set_f32("gib health", -3.0f);
	this.set_Vec2f("spell blocked pos", Vec2f(0.0f, 0.0f));
	this.set_bool("casting", false);
	this.set_bool("was_casting", false);
	//this.set_bool("shiftlaunch", false);
	
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("ignore crouch");
	
	this.push("names to activate", "keg");
	this.push("names to activate", "nuke");

	//centered on arrows
	//this.set_Vec2f("inventory offset", Vec2f(0.0f, 122.0f));
	//centered on items
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	//no spinning
	this.getShape().SetRotationsAllowed(false);
    this.addCommandID("freeze");
    this.addCommandID("spell");
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_up | CBlob::map_collide_nodeath);
	this.getCurrentScript().removeIfTag = "dead";

	if(isServer())
		this.set_u8("spell_count", 0);
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null){
		player.SetScoreboardVars("ScoreboardIcons.png", 6, Vec2f(16,16));
	}
}

void ManageSpell( CBlob@ this, WizardInfo@ wizard, PlayerPrefsInfo@ playerPrefsInfo, RunnerMoveVars@ moveVars )
{
	CSprite@ sprite = this.getSprite();
	bool ismyplayer = this.isMyPlayer();
	s32 charge_time = wizard.charge_time;
	u8 charge_state = wizard.charge_state;
	
	u8 spellID = playerPrefsInfo.primarySpellID;
	int hotbarLength = playerPrefsInfo.hotbarAssignments_Wizard.length;
	
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
        spellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(15,hotbarLength-1)];

        is_pressed = this.isKeyPressed( key_action2 );
		casting_key = "a2";
        just_pressed = this.isKeyJustPressed( key_action2 );
        just_released = this.isKeyJustReleased( key_action2 );

        is_secondary = true;
    }
    if (!is_pressed and !just_released and !just_pressed)	//auxiliary1 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(16,hotbarLength-1)];
		
        is_pressed = this.isKeyPressed( key_action3 );
		casting_key = "a3";
        just_pressed = this.isKeyJustPressed( key_action3 );
        just_released = this.isKeyJustReleased( key_action3 ); 

        is_aux1 = true;
    }
    if (!is_pressed and !just_released and !just_pressed)	//auxiliary2 hand
    {
        spellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(17,hotbarLength-1)];
		
        is_pressed = this.isKeyPressed( key_taunts );
		casting_key = "a4";
        just_pressed = this.isKeyJustPressed( key_taunts );
        just_released = this.isKeyJustReleased( key_taunts ); 

        is_aux2 = true;
    }
	this.set_string("casting_key", casting_key);
	
	Spell spell = WizardParams::spells[spellID];

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
	if ( controls.isKeyPressed( KEY_MBUTTON ) || wizard.spells_cancelling == true )
	{
		charge_time = 0;
		charge_state = WizardParams::not_aiming;
		
		if (wizard.spells_cancelling == false)
		{
			sprite.PlaySound("PopIn.ogg", 1.0f, 1.0f);
		}
		wizard.spells_cancelling = true;	
		
		// only stop cancelling once all spells buttons are released
		if ( !is_pressed )
		{
			wizard.spells_cancelling = false;
		}
	}
	/*
	if(this.getPlayer() is getLocalPlayer())
		{
			if(controls.isKeyJustPressed(KEY_LSHIFT))
			{
				this.set_bool("shiftlaunch", true);
				print("hello");
			}
			if(controls.isKeyJustReleased(KEY_LSHIFT))
			{
				this.set_bool("shiftlaunch", false);
				print("ohno");
			}
		}
	*/
	bool canCastSpell = wizMana >= spell.mana && playerPrefsInfo.spell_cooldowns[spellID] <= 0;
    if (is_pressed && canCastSpell) 
    {
        moveVars.walkFactor *= 0.8f;
        charge_time += 1;
        if (charge_time >= spell.full_cast_period)
        {
            charge_state = WizardParams::extra_ready;
            charge_time = spell.full_cast_period;
        }
        else if (charge_time >= spell.cast_period)
        {
            charge_state = WizardParams::cast_3;
        }
        else if (charge_time >= spell.cast_period_2)
        {
            charge_state = WizardParams::cast_2;
        }
        else if (charge_time >= spell.cast_period_1)
        {
            charge_state = WizardParams::cast_1;
        }
    }
    else if (just_released)
    {
        if (canCastSpell && charge_state > WizardParams::charging && not (spell.needs_full && charge_state < WizardParams::cast_3) &&
            (this.isMyPlayer() || this.getPlayer() is null || this.getPlayer().isBot()))
        {
            CBitStream params;
            params.write_u8(charge_state);
			u8 castSpellID;
			if ( is_aux2 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(17,hotbarLength-1)];
			else if ( is_aux1 )
				castSpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(16,hotbarLength-1)];
			else if ( is_secondary )
				castSpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(15,hotbarLength-1)];
			else
				castSpellID = playerPrefsInfo.primarySpellID;
            params.write_u8(castSpellID);
            params.write_Vec2f(spellPos);
			params.write_Vec2f(pos);
            this.SendCommand(this.getCommandID("spell"), params);
			
			int spell_cd_time = WizardParams::spells[castSpellID].cooldownTime * getTicksASecond();
			f32 cd_reduction_factor = 1.0f * this.get_f32("majestyglyph_cd_reduction");
			int apply_cd_time = (spell_cd_time == 0 ? 0 : spell_cd_time * cd_reduction_factor);

			playerPrefsInfo.spell_cooldowns[castSpellID] = apply_cd_time;
        }
        charge_state = WizardParams::not_aiming;
        charge_time = 0;
    }

    wizard.charge_time = charge_time;
    wizard.charge_state = charge_state;

    if ( ismyplayer )
    {
		if (!getHUD().hasButtons()) 
		{
			int frame = 0;
            if (charge_state == WizardParams::extra_ready) {
                frame = 15 + (getGameTime()/(this.hasTag("extra_damage")?4:5))%12;	
            }
            else if (wizard.charge_time > spell.cast_period)
            {
                frame = 12 + wizard.charge_time % 15 / 5;
            }
			else if (wizard.charge_time > 0) {
				frame = wizard.charge_time * 12 /spell.cast_period; 
			}
			getHUD().SetCursorFrame( frame );
		}

        if (this.isKeyJustPressed(key_action3))
        {
			client_SendThrowOrActivateCommand( this );
        }
    }
	
	if ( !is_pressed && getRules().get_bool("spell_number_selection") )
	{
		if (WizardParams::spells.length == 0) 
		{
			return;
		}

		WizardInfo@ wizard;
		if (!this.get( "wizardInfo", @wizard )) 
		{
			return;
		}
		
		bool spellSelected = this.get_bool("spell selected");
		int currHotkey = playerPrefsInfo.primaryHotkeyID;
		int nextHotkey =  playerPrefsInfo.hotbarAssignments_Wizard.length;
		
		CRules@ rules = getRules();
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
		
		if ( nextHotkey <  playerPrefsInfo.hotbarAssignments_Wizard.length )
		{
			playerPrefsInfo.primaryHotkeyID = nextHotkey;
			playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Wizard[nextHotkey];
			this.set_bool("spell selected", false);
			
			sprite.PlaySound("PopIn.ogg");
		}
	}
	else
		this.set_bool("spell selected", true);
}

void onTick( CBlob@ this )
{
	if(getNet().isServer())
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

	
    WizardInfo@ wizard;
	if (!this.get( "wizardInfo", @wizard )) 
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
		wizard.charge_state = 0;
		wizard.charge_time = 0;
		return;
	}*/

    RunnerMoveVars@ moveVars;
    if (!this.get( "moveVars", @moveVars )) {
        return;
    }

	// vvvvvvvvvvvvvv CLIENT-SIDE ONLY vvvvvvvvvvvvvvvvvvv

	if (!getNet().isClient()) return;

	if (this.isInInventory()) return;

    ManageSpell( this, wizard, playerPrefsInfo, moveVars );
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
		
        Spell spell = WizardParams::spells[spellID];
        Vec2f aimpos = params.read_Vec2f();
		Vec2f thispos = params.read_Vec2f();
        CastSpell(this, charge_state, spell, aimpos, thispos);
		
		manaInfo.mana -= spell.mana;
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
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    if (( hitterBlob.getName() == "wraith" || hitterBlob.getName() == "orb" ) && hitterBlob.getTeamNum() == this.getTeamNum())
        return 0;

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