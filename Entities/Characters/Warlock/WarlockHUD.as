//archer HUD

#include "WarlockCommon.as";
#include "PlayerPrefsCommon.as";
#include "MagicCommon.as";
#include "HUDStartPos.as";

const string iconsFilename = "SpellIcons.png";
const int slotsSize = 6;

void onInit( CSprite@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	CBlob@ thisBlob = this.getBlob();
	
	thisBlob.set_u8("gui_HUD_slots_width", slotsSize);
}

bool jp_a1 = false;
bool jp_a2 = false;
bool jp_a3 = false;
bool jp_ts = false;

bool pr_a1 = false;
bool pr_a2 = false;
bool pr_a3 = false;
bool pr_ts = false;

bool just_pressed_a1 = false;
bool just_pressed_a2 = false;
bool just_pressed_a3 = false;
bool just_pressed_ts = false;

bool pressing_a1 = false;
bool pressing_a2 = false;
bool pressing_a3 = false;
bool pressing_ts = false;

Spell charging_spell;

void onTick( CSprite@ this )
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	if (!blob.isMyPlayer()) return;

	Spell@ sp = null;	
	PlayerPrefsInfo@ playerPrefsInfo;
	CPlayer@ local_player = getLocalPlayer();

	if (local_player !is null && local_player.get("playerPrefsInfo", @playerPrefsInfo) && playerPrefsInfo.infoLoaded)
	{
		u8[] hotbarAssignments = playerPrefsInfo.hotbarAssignments_Warlock;

		CControls@ c = getControls();
		if (c is null) return;

		// Refactored: Only allow one pressing_* at a time, lock others if any is pressed
		// Detect current key states
		jp_a1 = blob.isKeyJustPressed(key_action1);
		jp_a2 = blob.isKeyJustPressed(key_action2);
		jp_a3 = blob.isKeyJustPressed(key_action3);
		jp_ts = blob.isKeyJustPressed(key_taunts);

		pr_a1 = blob.isKeyPressed(key_action1);
		pr_a2 = blob.isKeyPressed(key_action2);
		pr_a3 = blob.isKeyPressed(key_action3);
		pr_ts = blob.isKeyPressed(key_taunts);

		// Only allow one button to be "pressing" at a time, lock others
		if (pr_a1)
		{
			pressing_a1 = true; just_pressed_a1 = jp_a1;
			pressing_a2 = false; just_pressed_a2 = false;
			pressing_a3 = false; just_pressed_a3 = false;
			pressing_ts = false; just_pressed_ts = false;
		}
		else if (pr_a2)
		{
			pressing_a1 = false; just_pressed_a1 = false;
			pressing_a2 = true; just_pressed_a2 = jp_a2;
			pressing_a3 = false; just_pressed_a3 = false;
			pressing_ts = false; just_pressed_ts = false;
		}
		else if (pr_a3)
		{
			pressing_a1 = false; just_pressed_a1 = false;
			pressing_a2 = false; just_pressed_a2 = false;
			pressing_a3 = true; just_pressed_a3 = jp_a3;
			pressing_ts = false; just_pressed_ts = false;
		}
		else if (pr_ts)
		{
			pressing_a1 = false; just_pressed_a1 = false;
			pressing_a2 = false; just_pressed_a2 = false;
			pressing_a3 = false; just_pressed_a3 = false;
			pressing_ts = true; just_pressed_ts = jp_ts;
		}
		else
		{
			// No button pressed, allow all just_pressed and pressing states
			pressing_a1 = pr_a1; just_pressed_a1 = jp_a1;
			pressing_a2 = pr_a2; just_pressed_a2 = jp_a2;
			pressing_a3 = pr_a3; just_pressed_a3 = jp_a3;
			pressing_ts = pr_ts; just_pressed_ts = jp_ts;
		}

		u8 spellsLength = WarlockParams::spells.length;
		u8 primarySpellID = Maths::Min(playerPrefsInfo.primarySpellID, WarlockParams::spells.length-1);
		u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Warlock[15], WarlockParams::spells.length-1);
		u8 auxiliary1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Warlock[16], WarlockParams::spells.length-1);
		u8 auxiliary2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Warlock[17], WarlockParams::spells.length-1);

		// Inline: Determine which spell is being charged based on pressed keys and hotkey assignments
		if 		(pr_a1)
				charging_spell = WarlockParams::spells[primarySpellID];
		else if (pr_a2)
				charging_spell = WarlockParams::spells[secondarySpellID];
		else if (pr_a3)
				charging_spell = WarlockParams::spells[auxiliary1SpellID];
		else if (pr_ts)
				charging_spell = WarlockParams::spells[auxiliary2SpellID];
		else
				charging_spell = Spell("", "", 0, "", SpellType::other, 0, 0, 0, 0, 0); // Reset to empty spell if no key is pressed

		if (hotbarAssignments.size() > 0)
		{
			Spell[] classSpells = WarlockParams::spells;
			int spellsLength = classSpells.length;

			u8 primarySpellID = Maths::Min(hotbarAssignments[playerPrefsInfo.primaryHotkeyID], spellsLength-1);
			@sp = @classSpells[primarySpellID];

			bool not_a2 = !blob.isKeyPressed(key_action2);
			bool not_aux1 = !blob.isKeyPressed(key_action3);
			bool not_aux2 = !blob.isKeyPressed(key_taunts);
			if (blob.isMyPlayer() && sp !is null && sp.typeName == "chronomantic_teleport" && not_a2 && not_aux1 && not_aux2)
			{
				int cursor_frame = getHUD().getCursorFrame();
				Vec2f[]@ positions;

				if (blob.get("old_positions", @positions) && cursor_frame >= 15)
				{
					u8 seconds_warp = Maths::Min(5, positions_save_time_in_seconds);
					if (blob.hasTag("extra_damage")) seconds_warp = Maths::Min(10, positions_save_time_in_seconds);

					int index = Maths::Min(positions.length-1, seconds_warp * Maths::Round(f32(getTicksASecond()) / f32(old_positions_save_threshold)));
					if (index >= 0 && index < positions.length)
					{
						u16 frame = this.getFrameIndex();
						bool lookingLeft = this.isFacingLeft(); // todo: make a duplicate array for facing left at the time we're showing the particle

						Vec2f pos = positions[index];
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
						if (p !is null)
						{
							p.bounce = 0;
							p.Z = -10.0f;
							p.collides = false;
							p.fastcollision = true;
							p.setRenderStyle(RenderStyle::additive);
						}
					}
				}
			}
		}
	}

	ManageCursors(blob, @charging_spell);
}

u8 cursorType = 255;
void ManageCursors(CBlob@ this, Spell@ spell = null)
{
	// set cursor
	if (getHUD().hasButtons()) 
	{
		if (cursorType != 255)
		{
			getHUD().SetDefaultCursor();
			cursorType = 255;
		}
	}
	else
	{
		f32 WarlockMana = 0.0f;
		f32 WarlockHealth = this.getHealth();

		ManaInfo@ manaInfo;
		if (this.get("manaInfo", @manaInfo))
			WarlockMana = manaInfo.mana;

		if (spell !is null
			&& spell.type == SpellType::healthcost
			|| (spell.mana > WarlockMana && WarlockHealth > spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f))
		{
			if (cursorType != 1)
			{
				getHUD().SetCursorImage("MagicCursorRed.png", Vec2f(32,32));
				getHUD().SetCursorOffset(Vec2f(-32, -32));
				cursorType = 1;
			}
		}
		else
		{
			if (cursorType != 0)
			{
				getHUD().SetCursorImage("MagicCursor.png", Vec2f(32,32));
				getHUD().SetCursorOffset(Vec2f(-32, -32));
				cursorType = 0;
			}
		}

		// frame is set in logic
	}
}

void DrawManaBar(CBlob@ this, Vec2f origin)
{
	ManaInfo@ manaInfo;
    if (!this.get( "manaInfo", @manaInfo )) 
	{
        return;
    }

    string manaFile = "GUI/ManaBar.png";
	int barLength = 4;
    int segmentWidth = 24;
    GUI::DrawIcon("GUI/jends.png", 0, Vec2f(8,16), origin+Vec2f(-8,0));
    s32 maxMana = manaInfo.maxMana;
    s32 currMana = manaInfo.mana;
	
	f32 manaPerSegment = maxMana/barLength;
	
	f32 fourthManaSeg = manaPerSegment*(1.0f/4.0f);
	f32 halfManaSeg = manaPerSegment*(1.0f/2.0f);
	f32 threeFourthsManaSeg = manaPerSegment*(3.0f/4.0f);

	f32 lifemod = 1.0f - Maths::Clamp(this.getHealth() / this.getInitialHealth(), 0.0f, 1.0f);
	SColor col = SColor(255, 
		245, 
		Maths::Clamp(0 + 200 * Maths::Sin(getGameTime() * 0.1f * lifemod), 25, 50), 
		Maths::Clamp(230 - 200 * Maths::Sin((getGameTime() + 30) * 0.1f * lifemod), 0, 230));
    if (this.get_u16("manaburn") > 0) col = SColor(255,155,155,155);
	
	int MANA = 0;
    for (int step = 0; step < barLength; step += 1)
    {
        GUI::DrawIcon("GUI/ManaBack.png", 0, Vec2f(12,16), origin+Vec2f(segmentWidth*MANA,0));
        f32 thisMANA = currMana - step*manaPerSegment;
        if (thisMANA > 0)
        {
            Vec2f manapos = origin+Vec2f(segmentWidth*MANA-1,0);
            if (thisMANA <= fourthManaSeg) { GUI::DrawIcon(manaFile, 4, Vec2f(16,16), manapos, 1, col); }
            else if (thisMANA <= halfManaSeg) { GUI::DrawIcon(manaFile, 3, Vec2f(16,16), manapos, 1, col); }
            else if (thisMANA <= threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 2, Vec2f(16,16), manapos, 1, col); }
            else if (thisMANA > threeFourthsManaSeg) { GUI::DrawIcon(manaFile, 1, Vec2f(16,16), manapos, 1, col); }
            else {GUI::DrawIcon(manaFile, 0, Vec2f(16,16), manapos, 1, col); }
        }
		
        MANA++;
    }

    GUI::DrawIcon("GUI/jends.png", 1, Vec2f(8,16), origin+Vec2f(segmentWidth*MANA,0));
	GUI::DrawText(""+currMana+"/"+maxMana, origin+Vec2f(-42,8), color_white );
}

void DrawHealthConsumptionWarning(CBlob@ this, Spell spell, f32 value)
{
	f32 wizHealth = this.getHealth();
	ManaInfo@ manaInfo;
	if (!this.get("manaInfo", @manaInfo))
		return;
	f32 wizMana = manaInfo.mana;

	if (spell is null)
		return;

	bool enough_health = spell.type == SpellType::healthcost ? wizHealth >= spell.mana * 0.1f : wizHealth >= spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
	if (spell.type != SpellType::healthcost)
	{
		if (wizMana >= spell.mana)
			return;

		if (!enough_health)
			return;

		f32 missingMana = spell.mana - wizMana;
		value = missingMana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
	}
	else
	{
		if (!enough_health)
			return;

		value = spell.mana * 0.1f;
	}

	if (value <= 0) return;

	CControls@ controls = getControls();
	if (controls is null) return;

	Vec2f pos = this.getPosition() + Vec2f(4,0);
	Vec2f mouseScreenPos = controls.getInterpMouseScreenPos();
	Vec2f worldpos = getDriver().getWorldPosFromScreenPos(mouseScreenPos);
	Vec2f dir = worldpos - pos;
	dir.Normalize();
	dir *= 48.0f;

	GUI::DrawTextCentered("-"+(Maths::Round(value * 100)*0.1)+"", mouseScreenPos + dir, SColor(255, 255, 0, 0));
}

void DrawSpellBar(CBlob@ this)
{
	if (WarlockParams::spells.length == 0) {
		return;
	}
	
	CPlayer@ thisPlayer = this.getPlayer();
	if (thisPlayer is null)
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!thisPlayer.get("playerPrefsInfo", @playerPrefsInfo)) 
	{
		return;
	}
	
    ManaInfo@ manaInfo;
    if (!this.get("manaInfo", @manaInfo)) 
	{
        return;
    }
	
	if (!playerPrefsInfo.infoLoaded)
	{
		return;
	}
	
	CControls@ controls = getControls();
	Vec2f mouseScreenPos = controls.getMouseScreenPos();
	int ticksPerSec = getTicksASecond();
	
	f32 WarlockMana = manaInfo.mana;
	f32 WarlockHealth = this.getHealth();
	u8[] primaryHotkeys = playerPrefsInfo.hotbarAssignments_Warlock;
	
	//PRIMARY SPELL HUD
    Vec2f primaryPos = Vec2f(16.0f, getScreenHeight()-128.0f);
	u8 primarySpell;
	if (playerPrefsInfo.hotbarAssignments_Warlock.length >= playerPrefsInfo.primaryHotkeyID)
		primarySpell = playerPrefsInfo.hotbarAssignments_Warlock[playerPrefsInfo.primaryHotkeyID];
	else
		primarySpell = 0;

	if (charging_spell.typeName != "")
		DrawHealthConsumptionWarning(this, charging_spell, charging_spell.type == SpellType::healthcost ? charging_spell.mana * 0.1f : charging_spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f);
	
	const u8 primaryHotkey = playerPrefsInfo.primaryHotkeyID;
	int spellsLength = WarlockParams::spells.length;
	int cooldownsLength = playerPrefsInfo.spell_cooldowns.length;

	for (uint i = 0; i < 15; i++) // only 15 total spells held inside primary hotbar
	{
		u8 primarySpellID = Maths::Min(primaryHotkeys[i], spellsLength-1);
		Spell spell = WarlockParams::spells[primarySpellID];
		
		f32 spellMana = spell.mana;
		if (spellMana == 0)
			spellMana = 1;

		bool is_health_cost = spell.type == SpellType::healthcost;
		f32 missing_mana = WarlockMana - spellMana;
		f32 health_cost = is_health_cost ? spell.mana * 0.1f : spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;

		s16 currSpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(primarySpellID, cooldownsLength)];
		if (currSpellCooldown > 0)
			currSpellCooldown = currSpellCooldown/ticksPerSec + 1;		//this is for rounding issues
		
		if (i < 5)
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i);
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,64) + Vec2f(32,0)*i);
			GUI::DrawText(""+((i+1)%10), primaryPos + Vec2f(8,-16) + Vec2f(32,0)*i, color_white );
			
			if (i == primaryHotkey)
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i, SColor(100, 0, 255, 0));

			if (is_health_cost)
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,64) + Vec2f(0, 32*(1 - Maths::Clamp(WarlockHealth/health_cost, 0.0f, 1.0f))) + Vec2f(32,0)*i, SColor(200, 0, 0, 0));
			else if (WarlockMana < spellMana)
			{
				bool enough_health = WarlockHealth > health_cost;
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,64) + Vec2f(0, 32*(1-(WarlockMana/spellMana))) + Vec2f(32,0)*i, SColor(enough_health ? 50 : 200, enough_health ? 255 : 0, 0, 0));
			}

			if (currSpellCooldown > 0)
			{
				GUI::DrawRectangle(primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, primaryPos + Vec2f(32,96) + Vec2f(32,0)*i, SColor(100, 255, 0, 0));
				GUI::DrawText(""+currSpellCooldown, primaryPos + Vec2f(0,64) + Vec2f(32,0)*i, color_white );
			}
		}
		else if (i < 10)
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5));
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5));
			
			if (i == primaryHotkey)
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5), SColor(100, 0, 255, 0));
				
			if (is_health_cost)
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,32) + Vec2f(0, 32*(1 - Maths::Clamp(WarlockHealth/health_cost, 0.0f, 1.0f))) + Vec2f(32,0)*(i-5), SColor(200, 0, 0, 0));
			else if (WarlockMana < spellMana)
			{
				bool enough_health = WarlockHealth > health_cost;
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,32) + Vec2f(0, 32*(1-(WarlockMana/spellMana))) + Vec2f(32,0)*(i-5), SColor(enough_health ? 50 : 200, enough_health ? 255 : 0, 0, 0));
			}

			if (currSpellCooldown > 0)
			{
				GUI::DrawRectangle(primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), primaryPos + Vec2f(32,64) + Vec2f(32,0)*(i-5), SColor(100, 255, 0, 0));
				GUI::DrawText(""+currSpellCooldown, primaryPos + Vec2f(0,32) + Vec2f(32,0)*(i-5), color_white );
			}
		}
		else
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10));
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16,16), primaryPos + Vec2f(32,0)*(i-10));			
			
			if (i == primaryHotkey)
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10), SColor(100, 0, 255, 0));
				
			if (is_health_cost)
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32, 0) + Vec2f(0, 32*(1 - Maths::Clamp(WarlockHealth/health_cost, 0.0f, 1.0f))) + Vec2f(32,0)*(i-10), SColor(200, 0, 0, 0));
			else if (WarlockMana < spellMana)
			{
				bool enough_health = WarlockHealth > health_cost;
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,0) + Vec2f(0, 32*(1-(WarlockMana/spellMana))) + Vec2f(32,0)*(i-10), SColor(enough_health ? 50 : 200, enough_health ? 255 : 0, 0, 0));
			}

			if (currSpellCooldown > 0)
			{
				GUI::DrawRectangle(primaryPos + Vec2f(32,0)*(i-10), primaryPos + Vec2f(32,32) + Vec2f(32,0)*(i-10), SColor(100, 255, 0, 0));
				GUI::DrawText(""+currSpellCooldown, primaryPos + Vec2f(32,0)*(i-10), color_white );
			}
		}
		
		//draw an arrow over the selected column
		bool spellSelected = this.get_bool("spell selected");
		if (spellSelected == false)
		{
			Vec2f arrowPosOffset = Vec2f(0,0);
		
			if ((primaryHotkey == 0 ||  primaryHotkey == 5 ||  primaryHotkey == 10))
				arrowPosOffset = Vec2f(0,0);
			else if ((primaryHotkey == 1 ||  primaryHotkey == 6 ||  primaryHotkey == 11))
				arrowPosOffset = Vec2f(32,0);
			else if ((primaryHotkey == 2 ||  primaryHotkey == 7 ||  primaryHotkey == 12))
				arrowPosOffset = Vec2f(64,0);
			else if ((primaryHotkey == 3 ||  primaryHotkey == 8 ||  primaryHotkey == 13))
				arrowPosOffset = Vec2f(96,0);
			else if ((primaryHotkey == 4 ||  primaryHotkey == 9 ||  primaryHotkey == 14))
				arrowPosOffset = Vec2f(128,0);
				
			GUI::DrawArrow2D( primaryPos + Vec2f(14,-32) + arrowPosOffset, primaryPos + Vec2f(14,-16) + arrowPosOffset, color_white);
		}
	}

	SColor col_mana = SColor(255, 158, 58, 187);
	SColor col_health = SColor(255, 225, 6, 41);
	
	//primary spell name
	GUI::DrawPane(primaryPos + Vec2f(32,96), primaryPos + Vec2f(64,116) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(WarlockParams::spells[primarySpell].name, primaryPos + Vec2f(40,98), color_white );
	
	//primary spell mana cost
	SColor col_primary = WarlockParams::spells[primarySpell].type == SpellType::healthcost ? col_health : col_mana;
	GUI::DrawPane(primaryPos + Vec2f(0,96), primaryPos + Vec2f(32,116), color_white);
	GUI::DrawText("-" + WarlockParams::spells[primarySpell].mana, primaryPos + Vec2f(2,98), col_primary );

	//SECONDARY SPELL HUD
    Vec2f secondaryPos = Vec2f( 192.0f, getScreenHeight()-128.0f );
	
	u8 secondarySpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Warlock[15], spellsLength-1);
	Spell secondarySpell = WarlockParams::spells[secondarySpellID];
	
	f32 secondarySpellMana = secondarySpell.mana;
	if (secondarySpellMana == 0)
		secondarySpellMana = 1;	
	
	s16 currSecSpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(secondarySpellID, cooldownsLength)];
	if (currSecSpellCooldown > 0)
		currSecSpellCooldown = currSecSpellCooldown/ticksPerSec + 1;		//this is for rounding issues
	
	GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32,32));
	GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16,16), secondaryPos);
	
	f32 secondary_cost_health = secondarySpell.type == SpellType::healthcost ? secondarySpell.mana * 0.1f : secondarySpell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
	if (secondarySpell.type == SpellType::healthcost)
		GUI::DrawRectangle(secondaryPos, secondaryPos + Vec2f(32, 32*(1-Maths::Clamp(WarlockHealth/secondary_cost_health, 0.0f, 1.0f))), SColor(200, 0, 0, 0));
	else if (WarlockMana < secondarySpellMana)
	{
		bool enough_health = WarlockHealth > secondary_cost_health;
		GUI::DrawRectangle(secondaryPos, secondaryPos + Vec2f(32, 32*(1-(WarlockMana/secondarySpellMana))), SColor(enough_health ? 50 : 200, enough_health ? 255 : 0, 0, 0));
	}

	if (currSecSpellCooldown > 0)
	{
		GUI::DrawRectangle(secondaryPos, secondaryPos + Vec2f(32, 32), SColor(100, 255, 0, 0));
		GUI::DrawText(""+currSecSpellCooldown, secondaryPos, color_white );
	}
		
	//secondary spell name
	GUI::DrawPane(secondaryPos + Vec2f(32,32), secondaryPos + Vec2f(64,52) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(secondarySpell.name, secondaryPos + Vec2f(40,34), color_white );
	
	//secondary spell mana cost
	SColor col_secondary = secondarySpell.type == SpellType::healthcost ? col_health : col_mana;
	GUI::DrawPane(secondaryPos + Vec2f(0,32), secondaryPos + Vec2f(32,52), color_white);
	GUI::DrawText("-" + secondarySpellMana, secondaryPos + Vec2f(2,34), col_secondary );

	GUI::DrawText("Secondary - "+controls.getActionKeyKeyName( AK_ACTION2 ), secondaryPos + Vec2f(32,8), color_white );	
	
	//AUXILIARY1 SPELL HUD
    Vec2f aux1Pos = Vec2f( 192.0f, getScreenHeight()-64.0f );
	
	u8 aux1SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Warlock[16], spellsLength-1);
	Spell aux1Spell = WarlockParams::spells[aux1SpellID];
	
	f32 aux1SpellMana = aux1Spell.mana;
	if (aux1SpellMana == 0)
		aux1SpellMana = 1;	
	
	s16 currAux1SpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(aux1SpellID, cooldownsLength)];
	if (currAux1SpellCooldown > 0)
		currAux1SpellCooldown = currAux1SpellCooldown/ticksPerSec + 1;		//this is for rounding issues
	
	GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32,32));
	GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16,16), aux1Pos);
	
	f32 aux1_cost_health = aux1Spell.type == SpellType::healthcost ? aux1Spell.mana * 0.1f : aux1Spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
	if (aux1Spell.type == SpellType::healthcost)
		GUI::DrawRectangle(aux1Pos, aux1Pos + Vec2f(32, 32*(1-Maths::Clamp(WarlockHealth/aux1_cost_health, 0.0f, 1.0f))), SColor(200, 0, 0, 0));
	else if (WarlockMana < aux1SpellMana)
	{
		bool enough_health = WarlockHealth > aux1_cost_health;
		GUI::DrawRectangle(aux1Pos, aux1Pos + Vec2f(32, 32*(1-(WarlockMana/aux1SpellMana))), SColor(enough_health ? 50 : 200, enough_health ? 255 : 0, 0, 0));
	}

	if (currAux1SpellCooldown > 0)
	{
		GUI::DrawRectangle(aux1Pos, aux1Pos + Vec2f(32, 32), SColor(100, 255, 0, 0));
		GUI::DrawText(""+currAux1SpellCooldown, aux1Pos, color_white );
	}
		
	//auxiliary1 spell name
	GUI::DrawPane(aux1Pos + Vec2f(32,32), aux1Pos + Vec2f(64,52) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(aux1Spell.name, aux1Pos + Vec2f(40,34), color_white );
	
	//auxiliary1 spell mana cost
	SColor col_aux1 = aux1Spell.type == SpellType::healthcost ? col_health : col_mana;
	GUI::DrawPane(aux1Pos + Vec2f(0,32), aux1Pos + Vec2f(32,52), color_white);
	GUI::DrawText("-" + aux1SpellMana, aux1Pos + Vec2f(2,34), col_aux1);

	GUI::DrawText("Auxiliary1 - "+controls.getActionKeyKeyName( AK_ACTION3 ), aux1Pos + Vec2f(32,8), color_white);	
	
	//AUXILIARY2 SPELL HUD
    Vec2f aux2Pos = Vec2f( 364.0f, getScreenHeight()-128.0f );
	
	u8 aux2SpellID = Maths::Min(playerPrefsInfo.hotbarAssignments_Warlock[17], spellsLength-1);
	Spell aux2Spell = WarlockParams::spells[aux2SpellID];	
	
	f32 aux2SpellMana = aux2Spell.mana;
	if (aux2SpellMana == 0)
		aux2SpellMana = 1;

	s16 currAux2SpellCooldown = playerPrefsInfo.spell_cooldowns[Maths::Min(aux2SpellID, cooldownsLength)];
	if (currAux2SpellCooldown > 0)
		currAux2SpellCooldown = currAux2SpellCooldown/ticksPerSec + 1;		//this is for rounding issues
	
	GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32,32));
	GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16,16), aux2Pos);
	
	f32 aux2_cost_health = aux2Spell.type == SpellType::healthcost ? aux2Spell.mana * 0.1f : aux2Spell.mana * WarlockParams::HEALTH_COST_PER_1_MANA * 0.5f;
	if (aux2Spell.type == SpellType::healthcost)
		GUI::DrawRectangle(aux2Pos, aux2Pos + Vec2f(32, 32*(1-Maths::Clamp(WarlockHealth/aux2_cost_health, 0.0f, 1.0f))), SColor(200, 0, 0, 0));
	else if (WarlockMana < aux2SpellMana)
	{
		bool enough_health = WarlockHealth > aux2_cost_health;
		GUI::DrawRectangle(aux2Pos, aux2Pos + Vec2f(32, 32*(1-(WarlockMana/aux2SpellMana))), SColor(enough_health ? 50 : 200, enough_health ? 255 : 0, 0, 0));
	}

	if (currAux2SpellCooldown > 0)
	{
		GUI::DrawRectangle(aux2Pos, aux2Pos + Vec2f(32, 32), SColor(100, 255, 0, 0));
		GUI::DrawText(""+currAux2SpellCooldown, aux2Pos, color_white );
	}

	//auxiliary1 spell name
	GUI::DrawPane(aux2Pos + Vec2f(32,32), aux2Pos + Vec2f(64,52) + Vec2f(32,0)*3, color_white);
	GUI::DrawText(aux2Spell.name, aux2Pos + Vec2f(40,34), color_white );
	
	//auxiliary1 spell mana cost
	SColor col_aux2 = aux2Spell.type == SpellType::healthcost ? col_health : col_mana;
	GUI::DrawPane(aux2Pos + Vec2f(0,32), aux2Pos + Vec2f(32,52), color_white);
	GUI::DrawText("-" + aux2SpellMana, aux2Pos + Vec2f(2,34), col_aux2);

	GUI::DrawText("Auxiliary2 - "+controls.getActionKeyKeyName( AK_TAUNTS ), aux2Pos + Vec2f(32,8), color_white );
}

void onRender( CSprite@ this )
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	CPlayer@ player = blob.getPlayer();

	// draw inventory
	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
	DrawInventoryOnHUD( blob, tl, Vec2f(0,58));
	
	f32 height = 48;
	#ifdef STAGING
		height += 20;
	#endif
	GUI::DrawIcon("GUI/jslot.png", 1, Vec2f(32,32), Vec2f(2,height));
	DrawManaBar(blob, Vec2f(52,height+8));
	DrawSpellBar(blob);
}
