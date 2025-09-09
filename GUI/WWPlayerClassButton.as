#include "KGUI.as";
#include "PlayerPrefsCommon.as";
#include "PlatinumCommon.as";
#include "StatusCommon.as";
#include "AttributeCommon.as";
#include "WWPlayerClassesCommon.as";
#include "MagicCommon.as";

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

string classesVersion = "1";
u32 lastHotbarPressTime = 0;

string tooltip = "";
Tooltip@[] tooltips_fetcher;

const Vec2f iconSize = Vec2f(64, 64);
const Vec2f classIconSize = Vec2f(64, 96);

const f32 gridSize = 40.0f;
const f32 sectionGap = 12.0f;

const Vec2f descriptionButtonOffset = Vec2f(menuSize.x / 2 - 154, 256); // offset from parent
const Vec2f descriptionButtonOffsetOut = Vec2f(0, 280); // offset added
const Vec2f descriptionButtonSize = Vec2f(menuSize.x / 2 - 72, 128);
const Vec2f descriptionButtonSizeExtra = Vec2f(0, 32);

//----KGUI ELEMENTS----\\
WWPlayerClassButtonList playerClassButtons;
class WWPlayerClassButton 
{
	int classID;
	string name, modName, description, configFilename;
	Icon@ display, selectedSpellIcon, selectedSpellSketch;

	Button@ classButton;
	ProgressBar@ condition;
	
	Rectangle@ classFrame, leftPage, rightPage;
	Button@[] spellButtons;
	
	Label@ desc, conLbl, spellDescText, selectedSpellName, selectedSpellDescription;
	u32 classCost;

	u8[] specialties;
	u8[] stats;

	uint tickrate;
	Attribute@[] attributes;
	Rectangle@ attributesContainer;

	Button@ classDescriptionButton;
	Icon@ classDescriptionBackground;
	Label@ classDescriptionText;

	int iconCount;
	
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

		iconCount = 0;

		// top side
		// class button and its frame (view)
		Vec2f page_size = Vec2f(menuSize.x / 2 - 140, menuSize.y - 80);
		{
			@classButton = @Button(_pos + Vec2f(0, 0), _size, "", SColor(255, 255, 255, 255));
			@display = @Icon(_imageName, Vec2f(0, -8), Vec2f(128, 192), classID, 1.0f, true, Vec2f(64, 96));

			display._customData = display.localPosition.y;
			display.name = "iconback";

			classButton.nodraw = true;
			classButton.addHoverStateListener(BookMarkHoverStateHandler);

			classButton.addChild(display);
			classButton.name = _configFilename;
			classButton.addClickListener(ClassButtonHandler);

			@classFrame = @Rectangle(Vec2f(0, 0), page_size + Vec2f(page_size.x, 0), SColor(0,0,0,0));
			playerClassButtons.addChild(classFrame);

			Icon@ ornamentPage = @Icon("OrnamentPageLight.png", Vec2f(6, 36), Vec2f(800, 538), 0, 0.5f);
			classFrame.addChild(ornamentPage);
			
			@leftPage = @Rectangle(Vec2f(85, 58), page_size, SColor(0, 0, 0, 0));
			leftPage.name = _configFilename + "_leftPage";
			leftPage.setLevel(ContainerLevel::PAGE_FRAME);

			@spellDescText = @Label(Vec2f(4, 402), Vec2f(480, 32), "Select a spell and click on the hotbar. Right click to clear.", col_text, false, "DragonFire_12");
			leftPage.addChild(spellDescText);

			Label@ offensiveTitle = @Label(Vec2f(page_size.x / 2, 30), Vec2f(480, 32), classTitles[classID]+" Spells", col_text, true, "KingThingsPetrockLight_32");
			leftPage.addChild(offensiveTitle);

			Icon@ ornamentLine0 = @Icon("OrnamentLine0.png", Vec2f(4, offensiveTitle.localPosition.y + 18), Vec2f(336, 32), 0, 1.0f, true, Vec2f(272, 32));
			ornamentLine0.name = "ornamentLine0";
			leftPage.addChild(ornamentLine0);

			Label@ hotbarTitle = @Label(Vec2f(page_size.x / 2, 52 + sectionGap * 4 + gridSize * 4), Vec2f(480, 32), "Hotbar", col_text, true, "KingThingsPetrockLight_32");
			leftPage.addChild(hotbarTitle);

			Icon@ ornamentLine1 = @Icon("OrnamentLine1.png", Vec2f(4, hotbarTitle.localPosition.y + 14), Vec2f(336, 32), 0, 1.0f, true, Vec2f(272, 32));
			ornamentLine1.name = "ornamentLine1";
			leftPage.addChild(ornamentLine1);

			@rightPage = @Rectangle(Vec2f(leftPage.localPosition.x + 112 + page_size.x, leftPage.localPosition.y), page_size, SColor(0, 0, 0, 0));
			rightPage.name = _configFilename + "_rightPage";
			rightPage.setLevel(ContainerLevel::PAGE_FRAME);

			CRules@ rules = getRules();
			string iconTexture = rules !is null && rules.get_bool("book_old_spell_icons") ? "SpellIconsHud.png" : "SpellIcons.png";

			// position empty frame
			@selectedSpellIcon = @Icon(iconTexture, Vec2f(page_size.x / 2 - 32, 54), Vec2f(16, 16), 0, 2.0f);
			@selectedSpellName = @Label(Vec2f(page_size.x / 2, 30), Vec2f(page_size.x, 32), "Select a spell", col_text, true, "KingThingsPetrockLight_32");
			@selectedSpellDescription = @Label(Vec2f(10, 124), Vec2f(page_size.x + 24, 32), "Description", col_text, false, "KingThingsPetrockLight_18");

			Icon@ ornamentLine2 = @Icon("OrnamentCurvyWide.png", Vec2f(-6, hotbarTitle.localPosition.y + 13), Vec2f(336, 48), 0, 1.0f, true, Vec2f(272, 48));
			ornamentLine2.name = "ornamentLine2";
			ornamentLine2.isEnabled = false;
			rightPage.addChild(ornamentLine2);

			@selectedSpellSketch = @Icon("SpellSketch6.png", Vec2f(0, ornamentLine2.localPosition.y + 48), Vec2f(128, 64), 0, 1.0f);
			selectedSpellSketch.isEnabled = false;
			rightPage.addChild(selectedSpellSketch);

			selectedSpellIcon.isEnabled = false;
			selectedSpellDescription.isEnabled = false;

			if (classID == 0 || classID == 2 || classID == 4 || classID == 5 || classID == 7)
			{
				string tex = "OrnamentSun.png";
				Icon@ placeholder = @Icon(tex, Vec2f(page_size.x / 2 - 64, page_size.y / 2 - 64 - 20), Vec2f(64, 64), 0, 1.0f);
				placeholder.name = "placeholder_" + iconCount;
				iconCount++;
				rightPage.addChild(placeholder);
			}
			else
			{
				string text = "OrnamentMoon.png";
				Icon@ placeholder = @Icon(text, Vec2f(page_size.x / 2 - 92, page_size.y / 2 - 92 - 12), Vec2f(92, 92), 0, 1.0f);
				placeholder.name = "placeholder_" + iconCount;
				iconCount++;
				rightPage.addChild(placeholder); 
			}

			@classDescriptionButton = @Button(descriptionButtonOffset, descriptionButtonSize, "", SColor(255, 255, 255, 255));
			@classDescriptionBackground = @Icon("Paper"+XORRandom(2)+".png", Vec2f_zero, Vec2f(240, 96), 0, 1.0f, true, Vec2f(descriptionButtonSize.x, descriptionButtonSize.y * (classID == 8 ? 1.75f : 1.5f)));
			@classDescriptionText = @Label(Vec2f(24, 32), Vec2f(descriptionButtonSize.x - 24, descriptionButtonSize.y), "", col_text, false, "KingThingsPetrockLight_18");

			classDescriptionBackground._customData = classID;
			classDescriptionButton.addClickListener(ClassDescriptionButtonHandler);
			classDescriptionButton.isEnabled = false;
			classDescriptionButton.nodraw = true;
			//classDescriptionBackground.isEnabled = false;

			helpWindow.pushToFirst(classDescriptionButton);
			classDescriptionButton.addChild(classDescriptionBackground);
			classDescriptionButton.addChild(classDescriptionText);
			classDescriptionText.name = "classDescriptionText";

			Rectangle@ container = @Rectangle(Vec2f(8, page_size.y - 192), Vec2f(page_size.x - 16, 32), SColor(0, 0, 0, 0));
			container.name = "attributesContainer";
			container.isEnabled = false;
			rightPage.addChild(container);

			rightPage.addChild(selectedSpellIcon);
			rightPage.addChild(selectedSpellName);
			rightPage.addChild(selectedSpellDescription);

			classFrame.isEnabled = false;
			leftPage.isEnabled = false;
			rightPage.isEnabled = false;

			classFrame.addChild(leftPage);
			classFrame.addChild(rightPage);
		}

		// left page
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
			Vec2f offset = Vec2f(page_size.x/2 - (gridSize * 3), 72);

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
	}

	void addSpellSection(array<uint>@ spellIndices, Vec2f sectionOffset, Spell[] &in spells, f32 gridSize)
	{
		uint numRows = Maths::Ceil(spellIndices.length / 6.0f);
		for (uint row = 0; row < numRows; row++)
		{
			uint startIdx = row * 6;
			uint endIdx = Maths::Min(startIdx + 6, spellIndices.length);
			uint rowCount = endIdx - startIdx;

			f32 rowGap = 2.0f;
			f32 colGap = 2.0f;

			f32 rowOffsetX = 0;
			if (rowCount < 6)
			{
				rowOffsetX = ((6 - rowCount) * (gridSize + colGap)) * 0.5f;
			}

			f32 iconScale = 1.0f;
			Vec2f iSize = Vec2f(16, 16);
			Vec2f bSize = Vec2f(24, 24);

			Vec2f iconOffset = getIconOffset(iSize);
			Vec2f iconOffsetBackground = getIconOffset(bSize);
			if (gridSize >= iconOffsetBackground.x)
				iconOffsetBackground.x = 0;
			if (gridSize >= iconOffsetBackground.y)
				iconOffsetBackground.y = 0;

			CRules@ rules = getRules();
			const string iconTexture = rules !is null && rules.get_bool("book_old_spell_icons") ? "SpellIconsHud.png" : "SpellIcons.png";

			for (uint col = 0; col < rowCount; col++)
			{
				uint idx = startIdx + col;
				uint i = spellIndices[idx];
				Vec2f offset = sectionOffset
					+ Vec2f(rowOffsetX + col * (gridSize + colGap), row * (gridSize + rowGap));

				Button@ button = @Button(offset, Vec2f(gridSize, gridSize), "", SColor(255,234,205,163));
				button.nodraw = true;
				button.addHoverStateListener(paperButtonHover);

				Icon@ background = @Icon("PaperButton.png", iconOffsetBackground, bSize, 0, 1.0f, true, Vec2f(gridSize, gridSize));
				background.name = "background";
				button.addChild(background);

				spellButtons.push_back(button);
				spellButtons[spellButtons.length - 1].name = spells[i].name;

				Icon@ spellIcon = @Icon(iconTexture, iconOffset, iSize, spells[i].iconFrame, iconScale);
				spellButtons[spellButtons.length - 1].addChild(spellIcon);
				spellButtons[spellButtons.length - 1].addClickListener(SpellButtonHandler);

				spellButtons[spellButtons.length - 1]._customData = i;
				leftPage.addChild(spellButtons[spellButtons.length - 1]);
			}
		}
	}

	Vec2f getIconOffset(Vec2f iSize)
	{
		f32 iconScale = 1.0f;
		Vec2f iOffset = Vec2f(
			(gridSize - iSize.x * iconScale) * 0.5f - iSize.x / 2,
			(gridSize - iSize.y * iconScale) * 0.5f - iSize.y / 2
		);

		return iOffset;
	}

	void setSpecialties()
	{
		Label@ specialtiesText = @Label(Vec2f(8, 26), Vec2f(160, 33.5f), "Specialties: ", SColor(255, 255, 255, 255), false);
		rightPage.addChild(specialtiesText);

		Vec2f firstIconPos = Vec2f(6 + (0 == 0 ? 0 : 12), 12) + (0 == 0 ? Vec2f_zero : Vec2f(8,8)) + Vec2f(-6, -6);
		Vec2f lastIconPos = Vec2f(494, 42);
		
		rightPage.addChild(@Rectangle(firstIconPos, lastIconPos + Vec2f(16,16), SColor(255,66,72,75)));
		rightPage.addChild(@Rectangle(firstIconPos + Vec2f(2,2), lastIconPos + Vec2f(12,12), SColor(255,151,167,146)));
		rightPage.addChild(@Rectangle(firstIconPos + Vec2f(4,4), lastIconPos + Vec2f(8,8), SColor(255,108,119,110)));

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

			rightPage.addChild(temp);
		}

		for (u8 i = 0; i < stats.size(); i++)
		{
			Vec2f pos = Vec2f(110.5f + 40 * i + 12, 11);
			Vec2f centering = Vec2f(40 * i, -16);

			u8 level = stats[i];
			int seed = level * 20 + i;

			Label@ statLabel = @Label(pos + stat_labels_offsets[i] - centering, Vec2f(16,16), stats_labels[i], SColor(255,255,255,255), true, "default", seed);
			statLabel.addHoverStateListener(statHover);
			rightPage.addChild(statLabel);
		}

		for (u8 i = 1; i < specialties.size() + 1; i++)
		{
			Vec2f pos = Vec2f(104 + 40 * i + 12, 11);
			Icon@ temp = @Icon("Specializations.png", pos + Vec2f(8,8), Vec2f(16, 16), specialties[i - 1], 1.0f);
			temp.addHoverStateListener(iconHover);
			rightPage.addChild(temp);
		}
	}

	void update()
	{
		f32 factor = 2; // vanilla build is capped at 60 fps
		#ifdef STAGING
		factor = maths::max(2 ,f32(v_fpslimit) / 30);
		#endif
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
		if (!classFrame.isEnabled)
		{
			classDescriptionFade = 0;
			classDescriptionOpenTimer = 0;

			return;
		}

		f32 factor = 1;
		#ifdef STAGING
		factor = maths::max(1 ,f32(v_fpslimit) / 60);
		#endif

		f32 df = classDescriptionFadeFactor * getRenderDeltaTime() * 60.0f;

		bool start = classDescriptionOpenTimer < 90;
		f32 fade = start ? 0 : Maths::Lerp(classDescriptionFade, showClassDescription ? 1.0f : 0.0f, df);
		classDescriptionOpenTimer += 1.0f / factor;

		classDescriptionFade = fade;
		classDescriptionText.color = SColor(255 * fade, col_text.getRed(), col_text.getGreen(), col_text.getBlue());

		Vec2f thisOffset = descriptionButtonOffset;
		Vec2f bottomOffset = descriptionButtonOffsetOut;
		Vec2f lerped_offset = !start && showClassDescription
			? bottomOffset * fade + thisOffset
			: thisOffset;

		classDescriptionButton.setPosition(Vec2f(lerped_offset.x, lerped_offset.y));
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
	WWPlayerClassButtonList(Vec2f _position, Vec2f _size, int _style){

		super(_position, _size);
		style = _style;

		DebugColor = SColor(155,0,0,0);
	}

	void registerWWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, int _icon = 0, int _rarity = 0, string _modName = "Default", 
		u8[] _specialties = array<u8>(), u8[] _stats = array<u8>(), string _imageName = classIconsImage, Vec2f _size = classIconSize)
	{
		CRules@ rules = getRules();
		_imageName = rules !is null && rules.get_bool("book_old_spell_icons") ? "ClassButtonsHud.png": "ClassButtons.png"; // hardcoded rn

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
		int spacingX = iconSize.x + 4;
		int spacingY = iconSize.y;
		int startY = -32;

		for (int i = 0; i < list.length; i++)
		{
			int row = i / classesPerRow;
			int col = i % classesPerRow;

			f32 offset = i >= 5 ? 88.0f : 40.0f;
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
	if (rules !is null)
		rules.SendCommand(rules.getCommandID("swap classes"), params);

	Sound::Play2D("MenuSelect5.ogg", 0.75f, 0);
}

void ClassButtonHandler(int x, int y, int button, IGUIItem@ sender)	//Button click handler for KGUI
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
				playerClassButtons.list[i].classDescriptionText.setText(playerClassButtons.list[i].classDescriptionText.textWrap(classTips[c]));
			}

			playerClassButtons.list[i].classFrame.isEnabled = true;
			playerClassButtons.list[i].leftPage.isEnabled = true;
			playerClassButtons.list[i].rightPage.isEnabled = true;
			iButton.toggled = true;
			selectedClass = iButton.name;
		}
		else
		{
			iButton.toggled = false;
			iButton.render_one_more_time = true;

			playerClassButtons.list[i].classFrame.isEnabled = false;
			playerClassButtons.list[i].leftPage.isEnabled = false;
			playerClassButtons.list[i].rightPage.isEnabled = false;
			playerClassButtons.list[i].classDescriptionButton.isEnabled = false;
			playerClassButtons.list[i].classDescriptionText.setText("");
		}
	}	
}

void paperButtonHover(bool hover, IGUIItem@ item)
{
	if (item is null) return;

	Icon@ sender = cast<Icon>(item.getChild("background"));
	if (sender is null) return;

	sender.index = hover ? 1 : 0;
}

void SpellButtonHandler(int x, int y, int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
	{
		return;
	}
	
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!localPlayer.get("playerPrefsInfo", @playerPrefsInfo)) 
	{
		return;
	}

	// toggle buttons accordingly
	bool buttonToggled = false;
	int cd = sender._customData;

	for (int c = 0; c < playerClassButtons.list.length; c++)
	{
		Button@ cButton = playerClassButtons.list[c].classButton;
		for (int s = 0; s < playerClassButtons.list[c].spellButtons.length; s++)
		{
			Button@ sButton = playerClassButtons.list[c].spellButtons[s];
			if (sButton.name == sender.name && playerClassButtons.list[c].classFrame.isEnabled)
			{
				SetCustomSpell(localPlayer, cd);

				if (sButton.toggled == false && sender.name != "")
					PlayFlipSound();

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
				
				playerClassButtons.list[c].selectedSpellSketch.iconName = "SpellSketch"+sSpell.iconFrame+".png";
				playerClassButtons.list[c].selectedSpellIcon.index = sSpell.iconFrame;
				playerClassButtons.list[c].selectedSpellName.setText(sSpell.name);

				string statsText = (sSpell.type == SpellType::healthcost ? "Health cost: " : "Mana cost: ") + sSpell.mana;
				playerClassButtons.list[c].selectedSpellDescription.setText(playerClassButtons.list[c].selectedSpellDescription.textWrap(sSpell.spellDesc + "\n\n" + statsText));

				playerClassButtons.list[c].selectedSpellIcon.isEnabled = true;
				playerClassButtons.list[c].selectedSpellSketch.isEnabled = true;
				playerClassButtons.list[c].selectedSpellName.isEnabled = true;
				playerClassButtons.list[c].selectedSpellDescription.isEnabled = true;

				//set attributes
				playerClassButtons.list[c].attributes.clear();
				playerClassButtons.list[c].attributes = sSpell.attributes;

				CRules@ rules = getRules();
				string attributesTexture = rules !is null && rules.get_bool("book_old_spell_icons") ? "SpellAttributeIconsHud.png" : "SpellAttributeIcons.png";
				for (u8 i = 0; i < playerClassButtons.list[c].attributes.size(); i++)
				{
					playerClassButtons.list[c].attributes[i].icon = attributesTexture;
				}
				
				for (u8 i = 0; i < playerClassButtons.list[c].iconCount; i++)
				{
					Icon@ icon = cast<Icon>(playerClassButtons.list[c].rightPage.getChild("placeholder_" + i));
					if (icon !is null)
					{
						icon.isEnabled = false;
					}
				}

				Icon@ ornamentLine2 = cast<Icon>(playerClassButtons.list[c].rightPage.getChild("ornamentLine2"));
				if (ornamentLine2 !is null) ornamentLine2.isEnabled = true;

				Rectangle@ attributesContainer = cast<Rectangle>(playerClassButtons.list[c].rightPage.getChild("attributesContainer"));
				if (attributesContainer !is null) attributesContainer.isEnabled = true;
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

	GUI::SetFont("hud");
	if (tooltip != "")
	{
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
			Rectangle@ container = cast<Rectangle>(s.rightPage.getChild("attributesContainer"));
			if (container is null) continue;

			s.update();
			if (s.attributes.size() > 0)
			{
				Vec2f attributesPos = container.position;
				f32 gap = 4;
				f32 totalWidth = 0.0f;

				gap += 20;
				for (u8 i = 0; i < s.attributes.size(); i++)
				{
					totalWidth += s.attributes[i].dim.x;
					if (i > 0) totalWidth += gap;
				}
				f32 startX = attributesPos.x + (container.size.x - totalWidth) * 0.5f;
				for (u8 i = 0; i < s.attributes.size(); i++)
				{
					Vec2f attrPos = Vec2f(startX, attributesPos.y + 16);
					s.attributes[i].pos = attrPos;
					s.attributes[i].render(attrPos, 1.0f, tooltips_fetcher);
					startX += s.attributes[i].dim.x + gap;
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

bool was_left_click = false;
bool was_right_click = false;
void UpdateClassHotbar()
{
	CControls@ controls = getControls();
	was_left_click = controls.isKeyJustPressed(KEY_LBUTTON);
	was_right_click = controls.isKeyJustPressed(KEY_RBUTTON);
}

const Spell emptySpell = Spell("", "", 0, "Empty spell", SpellCategory::other, SpellType::other, 0, 0, 0, 0.0f, WizardSpellAttributesCollection[WizardSpellAttributes::ORB]);

const u8 spells_maxcount = 15;
void RenderClassHotbar(CPlayer@ localPlayer, PlayerPrefsInfo@ playerPrefsInfo, string className, u8[] hotbarAssignments, Spell[] classSpells)
{
	CControls@ controls = localPlayer.getControls();
	Vec2f mouseScreenPos = controls.getMouseScreenPos();

	Vec2f offset = Vec2f(120, 330);
	bool canCustomizeHotbar = was_left_click || was_right_click;
	bool hotbarClicked = false;
	int spellsLength = classSpells.length;

	CRules@ rules = getRules();
	const string iconTexture = rules !is null && rules.get_bool("book_old_spell_icons") ? "SpellIconsHud.png" : "SpellIcons.png";
	Vec2f primaryPos = helpWindow.position + Vec2f(16.0f, 0.0f) + offset;

	for (uint i = 0; i < spells_maxcount; i++)
	{
		u8 primarySpellID = Maths::Min(hotbarAssignments[i], spellsLength - 1);
		Spell spell = classSpells[primarySpellID];

		if (i < 5)
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0, 64) + Vec2f(32, 0) * i, primaryPos + Vec2f(32, 96) + Vec2f(32, 0) * i);
			GUI::DrawIcon(iconTexture, spell.iconFrame, Vec2f(16, 16), primaryPos + Vec2f(0, 64) + Vec2f(32, 0) * i);
			GUI::DrawText("" + ((i + 1) % 10), primaryPos + Vec2f(8, -16) + Vec2f(32, 0) * i, color_white);
			if (canCustomizeHotbar && (mouseScreenPos - (primaryPos + Vec2f(16, 80) + Vec2f(32, 0) * i)).Length() < 16.0f)
			{
				if (was_left_click)
					assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, className);
				else if (was_right_click)
					assignHotkey(localPlayer, i, playerPrefsInfo.spell_cooldowns.size() - 1, className); // 255 = empty spell
				hotbarClicked = true;
			}
		}
		else if (i < 10)
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(0, 32) + Vec2f(32, 0) * (i - 5), primaryPos + Vec2f(32, 64) + Vec2f(32, 0) * (i - 5));
			GUI::DrawIcon(iconTexture, spell.iconFrame, Vec2f(16, 16), primaryPos + Vec2f(0, 32) + Vec2f(32, 0) * (i - 5));
			if (canCustomizeHotbar && (mouseScreenPos - (primaryPos + Vec2f(16, 48) + Vec2f(32, 0) * (i - 5))).Length() < 16.0f)
			{
				if (was_left_click)
					assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, className);
				else if (was_right_click)
					assignHotkey(localPlayer, i, playerPrefsInfo.spell_cooldowns.size() - 1, className);
				hotbarClicked = true;
			}
		}
		else
		{
			GUI::DrawFramedPane(primaryPos + Vec2f(32, 0) * (i - 10), primaryPos + Vec2f(32, 32) + Vec2f(32, 0) * (i - 10));
			GUI::DrawIcon(iconTexture, spell.iconFrame, Vec2f(16, 16), primaryPos + Vec2f(32, 0) * (i - 10));
			if (canCustomizeHotbar && (mouseScreenPos - (primaryPos + Vec2f(16, 16) + Vec2f(32, 0) * (i - 10))).Length() < 16.0f)
			{
				if (was_left_click)
					assignHotkey(localPlayer, i, playerPrefsInfo.customSpellID, className);
				else if (was_right_click)
					assignHotkey(localPlayer, i, playerPrefsInfo.spell_cooldowns.size() - 1, className);
				hotbarClicked = true;
			}
		}
	}

	Vec2f secondaryPos = helpWindow.position + Vec2f(192.0f, 0.0f) + offset;
	u8 secondarySpellID = Maths::Min(hotbarAssignments[spells_maxcount], spellsLength - 1);
	Spell secondarySpell = classSpells[secondarySpellID];
	GUI::DrawFramedPane(secondaryPos, secondaryPos + Vec2f(32, 32));
	GUI::DrawIcon(iconTexture, secondarySpell.iconFrame, Vec2f(16, 16), secondaryPos);
	if (canCustomizeHotbar && (mouseScreenPos - (secondaryPos + Vec2f(16, 16))).Length() < 16.0f)
	{
		if (was_left_click)
			assignHotkey(localPlayer, spells_maxcount, playerPrefsInfo.customSpellID, className);
		else if (was_right_click)
			assignHotkey(localPlayer, spells_maxcount, playerPrefsInfo.spell_cooldowns.size() - 1, className);
		hotbarClicked = true;
	}
	GUI::SetFont("default");
	GUI::DrawText("A1", secondaryPos + Vec2f(32, 8), color_white);

	Vec2f aux1Pos = helpWindow.position + Vec2f(192.0f, 64.0f) + offset;
	u8 aux1SpellID = Maths::Min(hotbarAssignments[16], spellsLength - 1);
	Spell aux1Spell = classSpells[aux1SpellID];
	GUI::DrawFramedPane(aux1Pos, aux1Pos + Vec2f(32, 32));
	GUI::DrawIcon(iconTexture, aux1Spell.iconFrame, Vec2f(16, 16), aux1Pos);
	if (canCustomizeHotbar && (mouseScreenPos - (aux1Pos + Vec2f(16, 16))).Length() < 16.0f)
	{
		if (was_left_click)
			assignHotkey(localPlayer, 16, playerPrefsInfo.customSpellID, className);
		else if (was_right_click)
			assignHotkey(localPlayer, 16, playerPrefsInfo.spell_cooldowns.size() - 1, className);
		hotbarClicked = true;
	}
	GUI::DrawText("A2", aux1Pos + Vec2f(32, 8), color_white);

	Vec2f aux2Pos = helpWindow.position + Vec2f(224.0f, 32.0f) + offset;
	u8 aux2SpellID = Maths::Min(hotbarAssignments[17], spellsLength - 1);
	Spell aux2Spell = classSpells[aux2SpellID];
	GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32, 32));
	GUI::DrawIcon(iconTexture, aux2Spell.iconFrame, Vec2f(16, 16), aux2Pos);
	if (canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16, 16))).Length() < 16.0f)
	{
		if (was_left_click)
			assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, className);
		else if (was_right_click)
			assignHotkey(localPlayer, 17, playerPrefsInfo.spell_cooldowns.size() - 1, className);
		hotbarClicked = true;
	}
	GUI::DrawText("A3", aux2Pos + Vec2f(-20, 8), color_white);
	
	if (canCustomizeHotbar && hotbarClicked)
	{
		if (controls.lastKeyPressTime != lastHotbarPressTime) Sound::Play2D("MenuSelect5.ogg", 0.5f, 0.0f);
		lastHotbarPressTime = controls.lastKeyPressTime;
		was_left_click = false;
		was_right_click = false;
	}
}
