#include "KGUI.as";
#include "PlayerPrefsCommon.as";
#include "PlatinumCommon.as";
#include "StatusCommon.as";
#include "AttributeCommon.as";
#include "WizardCommon.as";
#include "NecromancerCommon.as";
#include "DruidCommon.as";
#include "SwordCasterCommon.as";
#include "EntropistCommon.as";
#include "PriestCommon.as";
#include "ShamanCommon.as";
#include "PaladinCommon.as";
#include "JesterCommon.as";
#include "WarlockCommon.as";
#include "WWPlayerClassesCommon.as";
#include "MagicCommon.as";

string classesVersion = "1";
u32 lastHotbarPressTime = 0;

string tooltip = "";
Tooltip@[] tooltips_fetcher;

const Vec2f iconSize = Vec2f(64, 64);

//----KGUI ELEMENTS----\\
WWPlayerClassButtonList playerClassButtons;
class WWPlayerClassButton 
{
	int classID;
	string name, modName, description, configFilename;
	Icon@ display;

	Button@ classButton;
	ProgressBar@ condition;
	
	Rectangle@ classFrame;
	Button@[] spellButtons;
	
	Label@ desc, conLbl, spellDescText;
	u32 classCost;

	u8[] specialties;
	u8[] stats;

	uint tickrate;
	Attribute@[] attributes;

	Button@ classDescriptionButton = @Button(descriptionButtonOffset, descriptionButtonSize, "", SColor(255, 255, 255, 255));
	Label@ classDescriptionText = @Label(classDescriptionButton.position, classDescriptionButton.size, "", SColor(255, 0, 0, 0), false);
	
	WWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, string _imageName, int _icon, int _rarity, string _modName, Vec2f _pos, Vec2f _size, u8[] _specialties, u8[] _stats)
	{
		name = _name;
		modName = _modName;
		description = _desc;
		configFilename = _configFilename;
		classID = _classID;
		classCost = _cost;

		specialties = _specialties;
		stats = _stats;
		tickrate = 0;

		// class button and its frame (view)
		Vec2f page_size = Vec2f(menuSize.x / 2 - 40, menuSize.y - 40);
		{
			@classButton = @Button(_pos, _size, "", SColor(255, 255, 255, 255));
			@display = @Icon(_imageName, Vec2f_zero, Vec2f(32, 32), classID, 1.0f);

			classButton.addChild(display);
			classButton.name = _configFilename;
			classButton.addClickListener(ClassButtonHandler);

			@classFrame = @Rectangle(Vec2f(40, 40), page_size, SColor(50,255,0,0));
			playerClassButtons.addChild(classFrame);

			classDescriptionButton._customData = classID;
			classDescriptionButton.addClickListener(ClassDescriptionButtonHandler);
			classDescriptionButton.isEnabled = false;

			classFrame.addChild(classDescriptionButton);
			classFrame.addChild(classDescriptionText);
		}

		// class spells
		Spell[] spells;
		{
			int classIndex = classes.find(_configFilename);
			switch(classIndex)
			{
				case 0:
					spells = WizardParams::spells;
					break;
				case 1:
					spells = NecromancerParams::spells;
					break;
				case 2:
					spells = DruidParams::spells;
					break;
				case 3:
					spells = SwordCasterParams::spells;
					break;
				case 4:
					spells = EntropistParams::spells;
					break;
				case 5:
					spells = PriestParams::spells;
					break;
				case 6:
					spells = ShamanParams::spells;
					break;
				case 7:
					spells = PaladinParams::spells;
					break;
				case 8:
					spells = JesterParams::spells;
					break;
				case 9:
					spells = WarlockParams::spells;
					break;
				default:
					break;
			}

			// spells selection grid divided by sections:
			array<uint> offensiveSpells, utilitySpells;
			
			int spellsLength = spells.length;
			const f32 gridSize = 48.0f;
			const f32 sectionGap = 48.0f;
			Vec2f offset = Vec2f(24, 80);

			// offensive, summoning, debuff
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::offensive)
					offensiveSpells.push_back(i);
			}
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::summoning)
					offensiveSpells.push_back(i);
			}
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::debuff)
					offensiveSpells.push_back(i);
			}

			// special > utility > defensive > support > heal
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::special)
					utilitySpells.push_back(i);
			}
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::heal)
					utilitySpells.push_back(i);
			}
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::support)
					utilitySpells.push_back(i);
			}
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::defensive)
					utilitySpells.push_back(i);
			}
			for (uint i = 0; i < spellsLength; i++)
			{
				if (spells[i].category == SpellCategory::utility)
					utilitySpells.push_back(i);
			}

			Vec2f offensiveOffset = offset;
			Vec2f utilityOffset = offensiveOffset + Vec2f(0, (Maths::Ceil(offensiveSpells.length / 6.0f) * gridSize) + (utilitySpells.size() > 0 ? sectionGap : 0));

			addSpellSection(offensiveSpells, offensiveOffset, spells, gridSize);
			addSpellSection(utilitySpells, utilityOffset, spells, gridSize);
		}

		//setSpecialties();

		@spellDescText = @Label(Vec2f(32, 450), Vec2f(480, 32), "Select a spell and click on this ^ hotbar.", SColor(255,0,0,0), false);
		classFrame.addChild(spellDescText);
		
		classFrame.isEnabled = false;
	}

	void addSpellSection(array<uint>@ spellIndices, Vec2f sectionOffset, Spell[] &in spells, f32 gridSize)
	{
		uint numRows = Maths::Ceil(spellIndices.length / 6.0f);
		for (uint row = 0; row < numRows; row++)
		{
			uint startIdx = row * 6;
			uint endIdx = Maths::Min(startIdx + 6, spellIndices.length);
			uint rowCount = endIdx - startIdx;

			f32 rowOffsetX = 0;
			if (rowCount < 6)
			{
				rowOffsetX = ((6 - rowCount) * gridSize) * 0.5f;
			}

			for (uint col = 0; col < rowCount; col++)
			{
				uint idx = startIdx + col;
				uint i = spellIndices[idx];
				Vec2f offset = sectionOffset + Vec2f(rowOffsetX + col * gridSize, row * gridSize);

				spellButtons.push_back(@Button(offset, Vec2f(gridSize, gridSize), "", SColor(255,234,205,163)));
				spellButtons[spellButtons.length - 1].name = spells[i].name;

				Icon@ spellIcon = @Icon("SpellIcons.png", Vec2f(8, 8), Vec2f(16, 16), spells[i].iconFrame, 1.0f);
				spellButtons[spellButtons.length - 1].addChild(spellIcon);
				spellButtons[spellButtons.length - 1].addClickListener(SpellButtonHandler);

				spellButtons[spellButtons.length - 1]._customData = i;
				classFrame.addChild(spellButtons[spellButtons.length - 1]);
			}
		}
	}

	void setSpecialties()
	{
		Label@ specialtiesText = @Label(Vec2f(8, 26), Vec2f(160, 33.5f), "Specialties: ", SColor(255, 255, 255, 255), false);
		classFrame.addChild(specialtiesText);

		Vec2f firstIconPos = Vec2f(6 + (0 == 0 ? 0 : 12), 12) + (0 == 0 ? Vec2f_zero : Vec2f(8,8)) + Vec2f(-6, -6);
		Vec2f lastIconPos = Vec2f(494, 42);
		
		classFrame.addChild(@Rectangle(firstIconPos, lastIconPos + Vec2f(16,16), SColor(255,66,72,75)));
		classFrame.addChild(@Rectangle(firstIconPos + Vec2f(2,2), lastIconPos + Vec2f(12,12), SColor(255,151,167,146)));
		classFrame.addChild(@Rectangle(firstIconPos + Vec2f(4,4), lastIconPos + Vec2f(8,8), SColor(255,108,119,110)));

		for (u8 i = 0; i < stats.size(); i++)
		{
			Vec2f pos = Vec2f(98 + 40 * i + 11, 10);
			int frame = 47;

			u8 row = 12;
			u8 level = stats[i];
			
			if (i > 0) frame += i + level * row;
			SColor col = i == 0 ? stats_middle_color[level] : stats_color[i-1];

			Icon@ temp = @Icon("Specializations.png", Vec2f(104, 11), Vec2f(16,16), frame, 1.5f);
			temp.color = col;

			classFrame.addChild(temp);
		}

		for (u8 i = 0; i < stats.size(); i++)
		{
			Vec2f pos = Vec2f(110.5f + 40 * i + 12, 11);
			Vec2f centering = Vec2f(40 * i, -16);

			u8 level = stats[i];
			int seed = level * 20 + i;

			Label@ statLabel = @Label(pos + stat_labels_offsets[i] - centering, Vec2f(16,16), stats_labels[i], SColor(255,255,255,255), true, "default", seed);
			statLabel.addHoverStateListener(statHover);
			classFrame.addChild(statLabel);
		}

		for (u8 i = 1; i < specialties.size() + 1; i++)
		{
			Vec2f pos = Vec2f(104 + 40 * i + 12, 11);
			Icon@ temp = @Icon("Specializations.png", pos + Vec2f(8,8), Vec2f(16, 16), specialties[i - 1], 1.0f);
			temp.addHoverStateListener(iconHover);
			classFrame.addChild(temp);
		}
	}

	void update()
	{
		f32 factor = f32(v_fpslimit) / 30;
		tickrate++;

		if (tickrate % factor != 0)
			return;

		Vec2f mpos = getControls().getInterpMouseScreenPos();
		for (u8 i = 0; i < attributes.size(); i++)
        {
            if (attributes[i] is null)
                continue;
			
            attributes[i].hover = mpos.x >= attributes[i].pos.x && mpos.x <= attributes[i].pos.x + attributes[i].dim.x &&
								  mpos.y >= attributes[i].pos.y && mpos.y <= attributes[i].pos.y + attributes[i].dim.y;

            attributes[i].tick();
        }
	}

	void renderClassDescriptions()
	{
		f32 factor = f32(v_fpslimit) / 60.0f;
		f32 df = classDescriptionFadeFactor * getRenderDeltaTime() * 60.0f;

		bool start = classDescriptionOpenTimer < 30;
		f32 fade = start ? 0 : Maths::Lerp(classDescriptionFade, showClassDescription ? 1.0f : 0.0f, df);
		classDescriptionOpenTimer += 1.0f / factor;

		classDescriptionFade = fade;
		classDescriptionText.color = SColor(255 * fade, 255, 255, 255);

		Vec2f lerped_offset = !start && showClassDescription ? Vec2f(0, descriptionButtonOffsetOut.y * fade) : Vec2f(0, descriptionButtonOffset.y);
		classDescriptionButton.setPosition(Vec2f(descriptionButtonOffset.x, lerped_offset.y));
		classDescriptionText.setPosition(classDescriptionButton.position + Vec2f(2, 2));

		Vec2f lerped_size = !start && showClassDescription ? Vec2f(descriptionButtonSize.x, descriptionButtonSize.y + descriptionButtonSizeExtra.y * fade) : descriptionButtonSize;
		classDescriptionButton.size = lerped_size;
		classDescriptionText.size = lerped_size;
	}

	void draw(Vec2f pos)
	{
		if (classButton.toggled || classButton.render_one_more_time) renderClassDescriptions();

		classButton.position = pos;
		classButton.draw();

		classButton.render_one_more_time = false;
	}
}

class WWPlayerClassButtonList : GenericGUIItem
{
	WWPlayerClassButton@[] list;

	int style;
	int timer = 0;
	bool displaying = false;
	bool needsUpdate = false;
	u8[] specialties;
	
	//Styles: 0 = mini|1= small\\
	WWPlayerClassButtonList(Vec2f _position,Vec2f _size, int _style){

		super(_position, _size);
		style = _style;

		DebugColor = SColor(155,0,0,0);
		CRules@ rules = getRules();
	}

	void registerWWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, int _icon = 0, int _rarity = 0, string _modName = "Default", 
		u8[] _specialties = array<u8>(), u8[] _stats = array<u8>(), string _imageName = classIconsImage, Vec2f _size = iconSize)
	{
		WWPlayerClassButton@ classButton = @WWPlayerClassButton(_name, _desc, _configFilename, _classID, _cost, _imageName, _icon, _rarity, _modName, position, _size, _specialties, _stats);
		list.push_back(classButton);

		specialties = _specialties;
	}
	
	void startDisplay(WWPlayerClassButton@ classButton)
	{
		Icon display = classButton.display; // ^

		displaying = true;
	}
	void display(){}

	void drawSelf()
	{
		if (style == 1) renderSmall();
		GenericGUIItem::drawSelf();
	}

	void renderSmall()
	{
		needsUpdate = false;

		int classesPerRow = 12;
		int spacingX = iconSize.x;
		int spacingY = iconSize.y;
		int startY = -32;

		for (int i = 0; i < list.length; i++)
		{
			int row = i / classesPerRow;
			int col = i % classesPerRow;

			f32 offset = i >= 5 ? 128.0f : 32.0f;
			Vec2f classPos = position + Vec2f(col * spacingX + offset, row * spacingY + startY);
			list[i].draw(classPos);
		}
	}
}

void initClasses()
{
	string configstr = "../Cache/WizardWars_Classes"+classesVersion+".cfg";
	ConfigFile cfg = ConfigFile(configstr);

	if (!cfg.exists("Version")){cfg.add_string("Version","Classes 1.2");
		cfg.saveFile("WizardWars_Classes"+classesVersion+".cfg");}

	playerClassButtons = WWPlayerClassButtonList(Vec2f(0, -32), menuSize, 1);
	playerClassButtons.isEnabled = false;
	
	playerClassButtons.registerWWPlayerClassButton("Wizard", 
													"\nSpecialties: \n\n" +
													"\n     Health: 75" +
													"     Mana: " + WizardParams::MAX_MANA +
													"     Mana rate: " + WizardParams::MANA_REGEN + " mana/sec", 
													"wizard", 0, 0, 2, 5, "WizardWars", specialties_wizard, STATS[0]);
	
	playerClassButtons.registerWWPlayerClassButton("Necromancer", 
													"\nSpecialties: \n\n" +
													"\n     Health: 100" +
													"     Mana: " + NecromancerParams::MAX_MANA +
													"     Mana rate: " + NecromancerParams::MANA_REGEN + " mana/sec", 
													"necromancer", 1, 0, 3, 5, "WizardWars", specialties_necromancer, STATS[1]);

	playerClassButtons.registerWWPlayerClassButton("Druid", 
													"\nSpecialties: \n\n" +
													"\n     Health: 70" +
													"     Mana: " + DruidParams::MAX_MANA +
													"     Mana rate: " + DruidParams::MANA_REGEN + " mana/sec",
													"druid", 2, 20, 4, 0, "WizardWars", specialties_druid, STATS[2]);
													
	playerClassButtons.registerWWPlayerClassButton("Swordcaster", 
													"\nSpecialties: \n\n" +
													"\n     Health: 90" +
													"     Mana: " + SwordCasterParams::MAX_MANA +
													"     Mana rate: " + SwordCasterParams::MANA_REGEN + " mana/sec",
													"swordcaster", 3, 0, 5, 0, "WizardWars", specialties_swordcaster, STATS[3]);
	playerClassButtons.registerWWPlayerClassButton("Entropist", 
													"\nSpecialties: \n\n" +
													"\n     Health: 75" +
													"     Mana: " + EntropistParams::MAX_MANA +
													"     Mana rate: " + EntropistParams::MANA_REGEN + " mana/sec",
													"entropist", 4, 0, 6, 0, "WizardWars", specialties_entropist, STATS[4]);

	playerClassButtons.registerWWPlayerClassButton("Priest", 
													"\nSpecialties: \n\n" +
													"\n     Health: 80" +
													"     Mana: " + PriestParams::MAX_MANA +
													"     Mana rate: " + PriestParams::MANA_REGEN + " mana/sec",
													"priest", 5, 0, 7, 0, "WizardWars", specialties_priest, STATS[5]);

	playerClassButtons.registerWWPlayerClassButton("Shaman", 
													"\nSpecialties: \n\n" +
													"\n     Health: 80" +
													"     Mana: " + ShamanParams::MAX_MANA +
													"     Mana rate: " + ShamanParams::MANA_REGEN + " mana/sec",
													"shaman", 6, 0, 8, 0, "WizardWars", specialties_shaman, STATS[6]);

	playerClassButtons.registerWWPlayerClassButton("Paladin", 
													"\nSpecialties: \n\n" +
													"\n     Health: 100" +
													"     Mana: " + PaladinParams::MAX_MANA +
													"     Mana rate: " + PaladinParams::MANA_REGEN + " mana/sec",
													"paladin", 7, 0, 9, 0, "WizardWars", specialties_paladin, STATS[7]);

	playerClassButtons.registerWWPlayerClassButton("Jester", 
													"\nSpecialties: \n\n" + 
													"\n     Health: 80" +
													"     Mana: " + JesterParams::MAX_MANA +
													"     Mana rate: " + JesterParams::MANA_REGEN + " mana/sec",
													"jester", 8, 0, 10, 0, "WizardWars", specialties_jester, STATS[8]);
	
	playerClassButtons.registerWWPlayerClassButton("Warlock", 
													"\nSpecialties: \n\n" + 
													"\n   Health: 80" +
													"     Life Mana: " + WarlockParams::MAX_MANA +
													"     Mana restoration: " + WarlockParams::MANA_PER_1_DAMAGE + " mana / 1 dmg",
													"warlock", 9, 0, 11, 0, "WizardWars", specialties_warlock, STATS[9]);
}

void statHover(bool hover, IGUIItem@ item)
{
	if (item is null) return;

	Label@ sender = cast<Label>(item);
	if (sender is null) return;
	
	int cd = sender._customData;
	int value = cd; // Assuming cd contains the 2-digit value
	int textIndex = value % 20; // Extract the first 20 as text index
	int level = value / 20; // Extract the level from the value
	string text = stats_names[textIndex];

	if (hover)
	{
		if (text != "")
		{
			tooltip = text + (textIndex == 0 ? ": " + diff_levels[level] : "");
		}
	}
	else
	{
		tooltip = "";
	}
}

void iconHover(bool hover, IGUIItem@ item)
{
	if (item is null) return;

	Icon@ sender = cast<Icon>(item);
	if (sender is null) return;

	string text = specialties_names[sender.index];
	if (hover)
	{
		if (text != "")
		{
			tooltip = text;
		}
	}
	else if (text == tooltip) 
	{
		tooltip = "";
	}
}

void SwapButtonHandler(int x, int y, int button, IGUIItem@ sender) //Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
		return;
		
	string playerName = localPlayer.getUsername();
	//bool[] unlocks = server_getPlayerUnlocks(playerName);
	
	u16 callerID = localPlayer.getNetworkID();

	CBitStream params;
	params.write_u16(callerID);
	params.write_string(selectedClass);
	
	CRules@ rules = getRules();
	rules.SendCommand(rules.getCommandID("swap classes"), params);

	Sound::Play("MenuSelect2.ogg");
}
/*
void UnlockButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if ( localPlayer is null )
		return;
	
	string playerName = localPlayer.getUsername();
	for(int i = 0; i < playerClassButtons.list.length; i++)
	{
		Button@ iButton = playerClassButtons.list[i].classButton;
		if ( iButton.toggled == true )
		{
			CBitStream params;
			params.write_string(playerName);
			params.write_u16(i);
			
			CRules@ rules = getRules();
			rules.SendCommand(rules.getCommandID("buy unlock"), params);
			
			u32 clientPlatinum = client_getPlayerPlatinum(playerName);
			if ( clientPlatinum >= playerClassButtons.list[i].classCost )
				playerClassButtons.list[i].gained = true;
		}
	}

	Sound::Play( "MenuSelect2.ogg" );	
}
*/

void ClassButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{
	// toggle buttons accordingly
	for (int i = 0; i < playerClassButtons.list.length; i++)
	{
		Button@ iButton = playerClassButtons.list[i].classButton;
		if (iButton.name == sender.name)
		{
			PlayFlipSound();

			if (!playerClassButtons.list[i].classFrame.isEnabled)
			{
				classDescriptionFade = 0;
				classDescriptionOpenTimer = 0;

				int c = playerClassButtons.list[i].classID;
				showClassDescription = canShowClassDescription(c);
				
				playerClassButtons.list[i].classDescriptionButton.isEnabled = showClassDescription;
				playerClassButtons.list[i].classDescriptionButton._customData = c;
				playerClassButtons.list[i].classDescriptionText.setText(playerClassButtons.list[i].classDescriptionText.textWrap(classDescriptions[c]));
			}

			playerClassButtons.list[i].classFrame.isEnabled = true;
			iButton.toggled = true;
			selectedClass = iButton.name;
		}
		else
		{
			iButton.toggled = false;
			iButton.render_one_more_time = true;

			playerClassButtons.list[i].classFrame.isEnabled = false;
			playerClassButtons.list[i].classDescriptionButton.isEnabled = false;
			playerClassButtons.list[i].classDescriptionText.setText("");
		}
	}	
}

void SpellButtonHandler(int x, int y, int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null )
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!localPlayer.get( "playerPrefsInfo", @playerPrefsInfo )) 
	{
		return;
	}

	// toggle buttons accordingly
	bool buttonToggled = false;
	int cd = sender._customData;

	for (int c = 0; c < playerClassButtons.list.length; c++)
	{
		playerClassButtons.list[c].attributes.clear();

		Button@ cButton = playerClassButtons.list[c].classButton;
		for (int s = 0; s < playerClassButtons.list[c].spellButtons.length; s++)
		{
			Button@ sButton = playerClassButtons.list[c].spellButtons[s];
			if (sButton.name == sender.name && playerClassButtons.list[c].classFrame.isEnabled)
			{
				SetCustomSpell(localPlayer, cd);

				if (sButton.toggled == false && sender.name != "")
					Sound::Play("MenuSelect2.ogg");

				sButton.toggled = true;
				Spell sSpell;
				if (cButton.name == "wizard")
					sSpell = WizardParams::spells[Maths::Min(cd, WizardParams::spells.length - 1)];
				else if (cButton.name == "druid")
					sSpell = DruidParams::spells[Maths::Min(cd, DruidParams::spells.length - 1)];
				else if (cButton.name == "necromancer")
					sSpell = NecromancerParams::spells[Maths::Min(cd, NecromancerParams::spells.length - 1)];
				else if (cButton.name == "swordcaster")
					sSpell = SwordCasterParams::spells[Maths::Min(cd, SwordCasterParams::spells.length - 1)];
				else if (cButton.name == "entropist")
					sSpell = EntropistParams::spells[Maths::Min(cd, EntropistParams::spells.length - 1)];
				else if (cButton.name == "priest")
					sSpell = PriestParams::spells[Maths::Min(cd, PriestParams::spells.length - 1)];
				else if (cButton.name == "shaman")
					sSpell = ShamanParams::spells[Maths::Min(cd, ShamanParams::spells.length - 1)];
				else if (cButton.name == "paladin")
					sSpell = PaladinParams::spells[Maths::Min(cd, PaladinParams::spells.length - 1)];
				else if (cButton.name == "jester")
					sSpell = JesterParams::spells[Maths::Min(cd, JesterParams::spells.length - 1)];
				else if (cButton.name == "warlock")
					sSpell = WarlockParams::spells[Maths::Min(cd, WarlockParams::spells.length - 1)];

				playerClassButtons.list[c].spellDescText.setText(playerClassButtons.list[c].spellDescText.textWrap("-- " + sSpell.name + " --" +
																													"\n     " + sSpell.spellDesc +
																													"\n " + (sSpell.type == SpellType::healthcost ? "Health cost: " : "Mana cost: ") + sSpell.mana));
				playerClassButtons.list[c].attributes = sSpell.attributes;
			}
			else
			{
				sButton.toggled = false;
			}
		}
	}
}

void RenderClassMenus()
{
	if (playerClassButtons.isEnabled == false)
		return;

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
	{
		return;
	}

	if (tooltip != "")
	{
		GUI::SetFont("hud");
		Vec2f mouseScreenPos = getControls().getInterpMouseScreenPos();
		Vec2f dim;
		GUI::GetTextDimensions(tooltip, dim);
		Vec2f extra = Vec2f(8, 8);
		GUI::DrawSunkenPane(mouseScreenPos - extra + Vec2f(8, 8), mouseScreenPos + dim + extra + Vec2f(8, 8));
		GUI::DrawText(tooltip, mouseScreenPos + Vec2f(7, 8), color_white);
	}

	PlayerPrefsInfo@ playerPrefsInfo;
	if (!localPlayer.get("playerPrefsInfo", @playerPrefsInfo))
	{
		return;
	}

	if (playerPrefsInfo.infoLoaded == false)
	{
		return;
	}

	for (int i = 0; i < playerClassButtons.list.length; i++)
	{
		WWPlayerClassButton@ s = playerClassButtons.list[i];
		Button@ iButton = s.classButton;
		if (iButton.toggled == true)
		{
			s.update();
			if (s.attributes.size() > 0)
			{
				// draw attributes
				Vec2f start_pos = s.spellButtons[s.spellButtons.size() - 1].position + Vec2f(8, 131);
				Vec2f attributesPos = start_pos;

				for (u8 i = 0; i < s.attributes.size(); i++)
				{
					s.attributes[i].pos = attributesPos - Vec2f((s.attributes[i].dim.x + 12) * i, 16);
					s.attributes[i].render(s.attributes[i].pos, 1.0f, tooltips_fetcher);
				}

				GUI::SetFont("hud");
			}

			spellAssignHelpIcon.isEnabled = false;
			const string buttonName = iButton.name;

			if (buttonName == "wizard") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Wizard, WizardParams::spells);
			} else if (buttonName == "druid") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Druid, DruidParams::spells);
			} else if (buttonName == "necromancer") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Necromancer, NecromancerParams::spells);
			} else if (buttonName == "swordcaster") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_SwordCaster, SwordCasterParams::spells);
			} else if (buttonName == "entropist") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Entropist, EntropistParams::spells);
			} else if (buttonName == "priest") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Priest, PriestParams::spells);
			} else if (buttonName == "shaman") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Shaman, ShamanParams::spells);
			} else if (buttonName == "paladin") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Paladin, PaladinParams::spells);
			} else if (buttonName == "jester") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Jester, JesterParams::spells);
			} else if (buttonName == "warlock") {
				RenderClassHotbar(localPlayer, playerPrefsInfo, buttonName, playerPrefsInfo.hotbarAssignments_Warlock, WarlockParams::spells);
			} else if (buttonName == "Knight") {

			}

			break;
		}
	}
}

const u8 spells_maxcount = 15;
void RenderClassHotbar(CPlayer@ localPlayer, PlayerPrefsInfo@ playerPrefsInfo, string className, u8[] hotbarAssignments, Spell[] classSpells)
{
	CControls@ controls = localPlayer.getControls();
	Vec2f mouseScreenPos = controls.getMouseScreenPos();

	Vec2f offset = Vec2f(50.0f, 350.0f);
	bool canCustomizeHotbar = controls.mousePressed1 && controls.lastKeyPressTime != lastHotbarPressTime;
	bool hotbarClicked = false;
	int spellsLength = classSpells.length;

	Vec2f primaryPos = helpWindow.position + Vec2f(16.0f, 0.0f) + offset;
	for (uint i = 0; i < spells_maxcount; i++)
	{
		u8 primarySpellID = Maths::Min(hotbarAssignments[i], spellsLength - 1);
		Spell spell = classSpells[primarySpellID];

		if (i < 5)
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0, 64) + Vec2f(32, 0) * i, primaryPos + Vec2f(32, 96) + Vec2f(32, 0) * i);
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16, 16), primaryPos + Vec2f(0, 64) + Vec2f(32, 0) * i);
			GUI::DrawText("" + ((i + 1) % 10), primaryPos + Vec2f(8, -16) + Vec2f(32, 0) * i, color_white);
			if (canCustomizeHotbar && (mouseScreenPos - (primaryPos + Vec2f(16, 80) + Vec2f(32, 0) * i)).Length() < 16.0f)
			{
				assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, className);
				hotbarClicked = true;
			}
		}
		else if (i < 10)
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0, 32) + Vec2f(32, 0) * (i - 5), primaryPos + Vec2f(32, 64) + Vec2f(32, 0) * (i - 5));
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16, 16), primaryPos + Vec2f(0, 32) + Vec2f(32, 0) * (i - 5));
			if (canCustomizeHotbar && (mouseScreenPos - (primaryPos + Vec2f(16, 48) + Vec2f(32, 0) * (i - 5))).Length() < 16.0f)
			{
				assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, className);
				hotbarClicked = true;
			}
		}
		else
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(32, 0) * (i - 10), primaryPos + Vec2f(32, 32) + Vec2f(32, 0) * (i - 10));
			GUI::DrawIcon("SpellIcons.png", spell.iconFrame, Vec2f(16, 16), primaryPos + Vec2f(32, 0) * (i - 10));
			if (canCustomizeHotbar && (mouseScreenPos - (primaryPos + Vec2f(16, 16) + Vec2f(32, 0) * (i - 10))).Length() < 16.0f)
			{
				assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, className);
				hotbarClicked = true;
			}
		}
	}

	Vec2f secondaryPos = helpWindow.position + Vec2f(192.0f, 0.0f) + offset;
	u8 secondarySpellID = Maths::Min(hotbarAssignments[spells_maxcount], spellsLength - 1);
	Spell secondarySpell = classSpells[secondarySpellID];
	GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32, 32));
	GUI::DrawIcon("SpellIcons.png", secondarySpell.iconFrame, Vec2f(16, 16), secondaryPos);
	if (canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16, 16))).Length() < 16.0f)
	{
		assignHotkey(localPlayer, spells_maxcount, playerPrefsInfo.customSpellID, className);
		hotbarClicked = true;
	}
	GUI::SetFont("default");
	GUI::DrawText("" + controls.getActionKeyKeyName(AK_ACTION2), secondaryPos + Vec2f(32, 8), color_white);

	Vec2f aux1Pos = helpWindow.position + Vec2f(192.0f, 64.0f) + offset;
	u8 aux1SpellID = Maths::Min(hotbarAssignments[16], spellsLength - 1);
	Spell aux1Spell = classSpells[aux1SpellID];
	GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32, 32));
	GUI::DrawIcon("SpellIcons.png", aux1Spell.iconFrame, Vec2f(16, 16), aux1Pos);
	if (canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16, 16))).Length() < 16.0f)
	{
		assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, className);
		hotbarClicked = true;
	}
	GUI::DrawText("" + controls.getActionKeyKeyName(AK_ACTION3), aux1Pos + Vec2f(32, 8), color_white);

	Vec2f aux2Pos = helpWindow.position + Vec2f(258.0f + 32.0f, 64.0f) + offset;
	u8 aux2SpellID = Maths::Min(hotbarAssignments[17], spellsLength - 1);
	Spell aux2Spell = classSpells[aux2SpellID];
	GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32, 32));
	GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16, 16), aux2Pos);
	if (canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16, 16))).Length() < 16.0f)
	{
		assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, className);
		hotbarClicked = true;
	}
	GUI::DrawText("" + controls.getActionKeyKeyName(AK_TAUNTS), aux2Pos + Vec2f(32, 8), color_white);
	
	if (canCustomizeHotbar && hotbarClicked)
	{
		lastHotbarPressTime = controls.lastKeyPressTime;
		Sound::Play("MenuSelect1.ogg");
	}
}
