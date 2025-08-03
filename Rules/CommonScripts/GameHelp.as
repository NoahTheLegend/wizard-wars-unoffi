#define CLIENT_ONLY

#include "ActorHUDStartPos.as"
#include "TeamColour.as"
#include "IslandsCommon.as"
#include "KGUI.as";
#include "Achievements.as";
#include "shipAchieves.as";
#include "WWPlayerClassButton.as";
#include "WheelMenuCommon.as";
#include "Tutorial.as";

const Vec2f menuSize = Vec2f(800, 538);
const string classIconsImage = "GUI/ClassIcons.png";

bool showHelp = true;
f32 active_time = 0;

bool previous_showHelp = true;
bool justJoined = true;
bool page1 = true;

const int slotsSize = 6;
f32 boxMargin = 50.0f;

//key names
const string party_key = getControls().getActionKeyKeyName( AK_PARTY );
const string inv_key = getControls().getActionKeyKeyName( AK_INVENTORY );
const string pick_key = getControls().getActionKeyKeyName( AK_PICKUP );
const string taunts_key = getControls().getActionKeyKeyName( AK_TAUNTS );
const string use_key = getControls().getActionKeyKeyName( AK_USE );
const string action1_key = getControls().getActionKeyKeyName( AK_ACTION1 );
const string action2_key = getControls().getActionKeyKeyName( AK_ACTION2 );
const string action3_key = getControls().getActionKeyKeyName( AK_ACTION3 );
const string map_key = getControls().getActionKeyKeyName( AK_MAP );
const string zoomIn_key = getControls().getActionKeyKeyName( AK_ZOOMIN );
const string zoomOut_key = getControls().getActionKeyKeyName( AK_ZOOMOUT );

const string lastChangesInfo = "";
const Vec2f windowDimensions = Vec2f(1000,600);

//----KGUI ELEMENTS----\\
	Window@ helpWindow;
	Label@ introText;
	Label@ helpText;
	Label@ changeText;
	Label@ resetSpellText;
    Label@ itemDistanceText;
    Label@ hoverDistanceText;
	Button@ infoBtn;
	Button@ introBtn;
	Button@ optionsBtn;
	Button@ barNumBtn;
	Button@ startCloseBtn;
    Button@ toggleSpellWheelBtn;
	Button@ toggleSpellHealthConsumeScreenFlash;
	Button@ resetShowClassDescriptions;
	Button@ toggleHoverMessagesBtn;
	Button@ oneDimensionalSpellbar;
	ScrollBar@ resetSpell;
	Button@ achievementBtn;
	Button@ classesBtn;
    Button@ togglemenuBtn;
    Button@ toggleHotkeyEmotesBtn;
	Rectangle@ optionsFrame;
	Rectangle@[] optionsFramePages;
	Rectangle@ classesFrame;
	Icon@ helpIcon;
	Icon@ canvasIcon;
	Icon@ spellHelpIcon;
	Icon@ spellAssignHelpIcon;
    ScrollBar@ itemDistance;
    ScrollBar@ hoverDistance;

bool isGUINull()
{
	if (helpWindow is null) { warn("debug: helpWindow is null"); return true; }
	if (introText is null) { warn("debug: introText is null"); return true; }
	if (helpText is null) { warn("debug: helpText is null"); return true; }
	if (changeText is null) { warn("debug: changeText is null"); return true; }
	if (itemDistanceText is null) { warn("debug: itemDistanceText is null"); return true; }
	if (hoverDistanceText is null) { warn("debug: hoverDistanceText is null"); return true; }
	if (infoBtn is null) { warn("debug: infoBtn is null"); return true; }
	if (introBtn is null) { warn("debug: introBtn is null"); return true; }
	if (optionsBtn is null) { warn("debug: optionsBtn is null"); return true; }
	if (classesBtn is null) { warn("debug: classesBtn is null"); return true; }
	if (togglemenuBtn is null) { warn("debug: togglemenuBtn is null"); return true; }
	if (toggleHotkeyEmotesBtn is null) { warn("debug: toggleHotkeyEmotesBtn is null"); return true; }
	if (barNumBtn is null) { warn("debug: barNumBtn is null"); return true; }
	if (startCloseBtn is null) { warn("debug: startCloseBtn is null"); return true; }
	if (toggleSpellWheelBtn is null) { warn("debug: toggleSpellWheelBtn is null"); return true; }
	if (toggleSpellHealthConsumeScreenFlash is null) { warn("debug: toggleSpellHealthConsumeScreenFlash is null"); return true; }
	if (resetShowClassDescriptions is null) { warn("debug: resetShowClassDescriptions is null"); return true; }
	if (toggleHoverMessagesBtn is null) { warn("debug: toggleHoverMessagesBtn is null"); return true; }
	if (oneDimensionalSpellbar is null) { warn("debug: oneDimensionalSpellbar is null"); return true; }
	if (resetSpellText is null) { warn("debug: resetSpellText is null"); return true; }
	if (resetSpell is null) { warn("debug: resetSpell is null"); return true; }
	if (achievementBtn is null) { warn("debug: achievementBtn is null"); return true; }
	if (optionsFrame is null) { warn("debug: optionsFrame is null"); return true; }
	if (classesFrame is null) { warn("debug: classesFrame is null"); return true; }
	if (helpIcon is null) { warn("debug: helpIcon is null"); return true; }
	if (canvasIcon is null) { warn("debug: canvasIcon is null"); return true; }
	if (spellHelpIcon is null) { warn("debug: spellHelpIcon is null"); return true; }
	if (spellAssignHelpIcon is null) { warn("debug: spellAssignHelpIcon is null"); return true; }
	if (itemDistance is null) { warn("debug: itemDistance is null"); return true; }
	if (hoverDistance is null) { warn("debug: hoverDistance is null"); return true; }
	
	return false;
}

void onInit(CRules@ this)
{
	this.set_bool("GUI initialized", false);

	this.addCommandID("join");
	this.addCommandID("updateBAchieve");
	u_showtutorial = true; // for ShowTipOnDeath to work

	string configstr = "../Cache/WizardWars_KGUI.cfg";
	ConfigFile cfg = ConfigFile(configstr);
	if (!cfg.exists("Version"))
	{
		cfg.add_string("Version", "KGUI 2.3");
		cfg.saveFile("WizardWars_KGUI.cfg");
	}
}

void PlayFlipSound()
{
	Sound::Play2D("PageFlip"+XORRandom(6)+".ogg", 0.15f, 0.0f);
}

void classFrameClickHandler(int x, int y, int button, IGUIItem@ sender)
{
	if (sender is null || playerClassButtons is null) return;

	if (sender._customData > 100)
	{
		int classIndex = sender._customData - 101; // 0 is empty, 1 is wizard and so on

		Rectangle@ leftPage = cast<Rectangle>(classesFrame.getChild("classFrameLeftPage"));
		if (leftPage is null) return;

		Label@ title0 = cast<Label@>(leftPage.getChild("classFrameLeftPageTitle0"));
		if (title0 is null) return;

		Label@ title1 = cast<Label@>(leftPage.getChild("classFrameLeftPageTitle1"));
		if (title1 is null) return;

		Label@ description = cast<Label@>(leftPage.getChild("classFrameLeftPageDescription"));
		if (description is null) return;

		PlayFlipSound();

		title0.font = "DragonFire_56";
		title1.font = "DragonFire_24";
		description.font = "KingThingsPetrockLight_22";

		if (classIndex == 0)
		{
			title0.font = "DragonFire_32";
			title1.font = "DragonFire_24";
			description.font = "DragonFire_12";
			
			title0.setText("Hey!");
			title1.setText("This hasn' t been made yet. . .");

			u8[] added;
			u8[] random_offsets;
			for (u8 i = 0; i < 3; i++)
			{
				added.push_back(XORRandom(symbol_lines.length));
				random_offsets.push_back(XORRandom(110));
			}

			string text = CombineSymbols(added, random_offsets);
			description.setText(text);
		}
		else if (classIndex < classTitles.size() + 1)
		{
			classIndex--;

			title0.setText(classTitles[classIndex]);
			title1.setText(classSubtitles[classIndex]);
			description.setText(description.textWrap(classDescriptions[classIndex]));
		}
	}
	else
	{
		Sound::Play("MenuSelect2.ogg");
	}
}

void ButtonClickHandler(int x, int y, int button, IGUIItem@ sender)
{
	//Button click handler for KGUI
	canvasIcon.isEnabled = true;
	if (sender.level == ContainerLevel::PAGE) PlayFlipSound();

	if (sender is infoBtn)
	{
		canvasIcon.isEnabled = false;

		changeText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		optionsFrame.isEnabled = false;
		classesFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}

	if (sender is introBtn)
	{
		canvasIcon.isEnabled = false;

		changeText.isEnabled = false;
		introText.isEnabled = true;
		helpIcon.isEnabled = true;
		optionsFrame.isEnabled = false;
		classesFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}

	if (sender is optionsBtn)
	{
		changeText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		optionsFrame.isEnabled = true;
		classesFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}

	if (sender is classesBtn)
	{
		changeText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		optionsFrame.isEnabled = false;
		classesFrame.isEnabled = true;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}

	if (sender._customData == 100) // class frame button
	{
		changeText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		optionsFrame.isEnabled = false;
		classesFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = true;
	}

	//if (sender is achievementBtn)
	//{
	//	changeText.isEnabled = false;
	//	introText.isEnabled = false;
	//	helpIcon.isEnabled = false;
	//	spellAssignHelpIcon.isEnabled = false;
	//	optionsFrame.isEnabled = false;
	//	classesFrame.isEnabled = false;
	//	shipAchievements.isEnabled = true;
	//	playerClassButtons.isEnabled = false;
	//}

    if (sender is togglemenuBtn)
	{
        showHelp = !showHelp;
    }

	if (sender is barNumBtn)
	{
		barNumBtn.toggled = !barNumBtn.toggled;
		getRules().set_bool("spell_number_selection", barNumBtn.toggled);

		barNumBtn.desc = (barNumBtn.toggled) ? "Spell Bar - ON" : "Spell Bar - OFF";
		barNumBtn.saveBool("Bar Numbers",barNumBtn.toggled,"WizardWars");
	}

	if (sender is startCloseBtn)
	{
		startCloseBtn.toggled = !startCloseBtn.toggled;
		startCloseBtn.desc = (startCloseBtn.toggled) ? "Start Help Closed Enabled" : "Start Help Closed Disabled";
		startCloseBtn.saveBool("Start Closed",!startCloseBtn.toggled,"WizardWars");
	}

    if (sender is toggleSpellWheelBtn)
    {
        toggleSpellWheelBtn.toggled = !toggleSpellWheelBtn.toggled;
		toggleSpellWheelBtn.desc = (toggleSpellWheelBtn.toggled) ? "Spell Wheel - ON" : "Spell Wheel - OFF";
		toggleSpellWheelBtn.saveBool("Spell Wheel Active", toggleSpellWheelBtn.toggled,"WizardWars");
        
        WheelMenu@ menu = get_wheel_menu("spells");
        if (menu != null){
            getRules().set_bool("usespellwheel", toggleSpellWheelBtn.toggled);
        }
    }

	if (sender is toggleSpellHealthConsumeScreenFlash)
	{
		toggleSpellHealthConsumeScreenFlash.toggled = !toggleSpellHealthConsumeScreenFlash.toggled;
		toggleSpellHealthConsumeScreenFlash.desc = (toggleSpellHealthConsumeScreenFlash.toggled) ? "HP consume red flash - ON" : "HP consume red flash - OFF";
		toggleSpellHealthConsumeScreenFlash.saveBool("Spell health consume screen flash", toggleSpellHealthConsumeScreenFlash.toggled,"WizardWars");
		
		if (toggleSpellHealthConsumeScreenFlash.toggled)
		{
			getRules().set_bool("spell_health_consume_screen_flash", true);
		}
		else
		{
			getRules().set_bool("spell_health_consume_screen_flash", false);
		}
	}

	if (sender is resetShowClassDescriptions)
	{
		Sound::Play("MenuSelect2.ogg");
		setCachedClassesSeen(false);
		showClassDescription = false;
		classDescriptionFade = 0;
		classDescriptionOpenTimer = 0;
		//print("debug: reset class descriptions");
	}

	if (sender is toggleHoverMessagesBtn)
    {
        toggleHoverMessagesBtn.toggled = !toggleHoverMessagesBtn.toggled;
		toggleHoverMessagesBtn.desc = (toggleHoverMessagesBtn.toggled) ? "Hover Messages - ON" : "Hover Messages - OFF";
		toggleHoverMessagesBtn.saveBool("Hover Messages Active", toggleHoverMessagesBtn.toggled, "WizardWars");
        
        getRules().set_bool("hovermessages_enabled", toggleHoverMessagesBtn.toggled);
    }
	
	if (sender is oneDimensionalSpellbar)
    {
        oneDimensionalSpellbar.toggled = !oneDimensionalSpellbar.toggled;
		oneDimensionalSpellbar.desc = (oneDimensionalSpellbar.toggled) ? "Spell bar in 1 row - ON" : "Spell bar in 1 row - OFF";
		oneDimensionalSpellbar.saveBool("Spell bar in 1 row", oneDimensionalSpellbar.toggled, "WizardWars");
        
        getRules().set_bool("one_row_spellbar", oneDimensionalSpellbar.toggled);
    }

    if (sender is toggleHotkeyEmotesBtn)
    {
        toggleHotkeyEmotesBtn.toggled = !toggleHotkeyEmotesBtn.toggled;
		toggleHotkeyEmotesBtn.desc = (toggleHotkeyEmotesBtn.toggled) ? "Emotes - ON" : "Emotes - OFF";
		toggleHotkeyEmotesBtn.saveBool("Hotkey Emotes", toggleHotkeyEmotesBtn.toggled,"WizardWars");
        
        getRules().set_bool("hotkey_emotes", toggleHotkeyEmotesBtn.toggled);
    }
}

const int OPTIONS_SCROLLER_ITEMS_PER_GROUP = 2;
void OptionsScrollerClickHandler(int x, int y, int button, IGUIItem@ sender)
{
    if (sender is null || optionsFramePages.length <= OPTIONS_SCROLLER_ITEMS_PER_GROUP)
    {
        return;
    }

	PlayFlipSound();

    int numGroups = (optionsFramePages.length + OPTIONS_SCROLLER_ITEMS_PER_GROUP - 1) / OPTIONS_SCROLLER_ITEMS_PER_GROUP;
    int currentGroup = optionsFrame._customData;

    if (sender._customData == 0)
    {
        currentGroup--;
        if (currentGroup < 0)
        {
            currentGroup = numGroups - 1;
        }
    }
    else if (sender._customData == 1)
    {
        currentGroup++;
        if (currentGroup >= numGroups)
        {
            currentGroup = 0;
        }
    }

    optionsFrame._customData = currentGroup;
    updateOptionsScroller();
}

void updateOptionsScroller()
{
    int currentGroup = optionsFrame._customData;
    int startIndex = currentGroup * OPTIONS_SCROLLER_ITEMS_PER_GROUP;

    for (int i = 0; i < optionsFramePages.length; i++)
    {
        optionsFramePages[i].isEnabled = false;
    }

    for (int i = 0; i < OPTIONS_SCROLLER_ITEMS_PER_GROUP; i++)
    {
        int pageIndex = startIndex + i;
        
        if (pageIndex < optionsFramePages.length)
        {
            optionsFramePages[pageIndex].isEnabled = true;
        }
    }
}

void SliderClickHandler(int dType ,Vec2f mPos, IGUIItem@ sender){
	//if (sender is test){test.slide();}
}

void onTick(CRules@ this)
{
	bool initialized = this.get_bool("GUI initialized");
	if ((!initialized || isGUINull()))		//this little trick is so that the GUI shows up on local host 
	{
        ConfigFile cfg;
        
        u16 itemDistance_value = 6;
        u16 hoverDistance_value = 6;
		u16 resetSpell_value = 0;

        if (cfg.loadFile("../Cache/WW_OptionsMenu.cfg"))//Load file, if file exists
        {
            print("options loaded");
            if (cfg.exists("item_distance"))//Value already set?
            {
                print("default set");
                itemDistance_value = cfg.read_u16("item_distance");//Set default
            }
            if (cfg.exists("hover_distance"))//Value already set?
            {
                hoverDistance_value = cfg.read_u16("hover_distance");//Set default
            }
			if (cfg.exists("reset_spell_id"))
			{
				resetSpell_value = cfg.read_u16("reset_spell_id");
			}

			this.set_u16("reset_spell_id", resetSpell_value);
        }

		// main window
		@helpWindow = @Window(Vec2f(getDriver().getScreenWidth() / 2 - menuSize.x / 2, -menuSize.y), menuSize);
		helpWindow.name = "Help Window";
		helpWindow.nodraw = true;
		helpWindow.setLevel(ContainerLevel::WINDOW);

		// intro background
		{
			CFileImage@ image = CFileImage("GameHelp.png");
			Vec2f imageSize = Vec2f(image.getWidth(), image.getHeight());

			AddIconToken("$HELP$", "GameHelp.png", imageSize, 0);
			@helpIcon = @Icon("GameHelp.png", Vec2f(0, 0), imageSize, 0, 0.5f);
			helpIcon.setLevel(ContainerLevel::PAGE);
		}

		// background
		{
			CFileImage@ image = CFileImage("MenuCanvas.png");
			Vec2f imageSize = Vec2f(image.getWidth(), image.getHeight());

			AddIconToken("$CANVAS$", "MenuCanvas.png", imageSize, 0);
			@canvasIcon = @Icon("MenuCanvas.png", Vec2f(0, 0), Vec2f(imageSize.x, imageSize.y), 0, 0.5f);
			canvasIcon.isEnabled = false;
			canvasIcon.setLevel(ContainerLevel::BACKGROUND);
		}

		//---KGUI Parenting---\\
		// helpWindow
		{
			@infoBtn = @Button(Vec2f(0,495),Vec2f(100,30),"How to Play",SColor(255,255,255,255));
			infoBtn.setLevel(ContainerLevel::PAGE);
			infoBtn.addClickListener(ButtonClickHandler);

			@changeText  = @Label(Vec2f(20,40),Vec2f(780,34),"",SColor(255,0,0,0),false);
			changeText.setText(changeText.textWrap(lastChangesInfo));

			@introText  = @Label(Vec2f(280,10),Vec2f(780,15),"",SColor(255,0,0,0),false);
			introText.setText(introText.textWrap("    Welcome to Wizard Wars!\n(Press F1 to close this window)"));

			@introBtn = @Button(Vec2f(160,495),Vec2f(100,30),"Home Page",SColor(255,255,255,255));
			introBtn.setLevel(ContainerLevel::PAGE);
			introBtn.addClickListener(ButtonClickHandler);

			@helpText  = @Label(Vec2f(6,10),Vec2f(100,34),"",SColor(255,0,0,0),false);
			helpText.setText(helpText.textWrap(lastChangesInfo));

			@optionsBtn = @Button(Vec2f(265,495),Vec2f(100,30),"Options",SColor(255,255,255,255));
			optionsBtn.setLevel(ContainerLevel::PAGE);
			optionsBtn.addClickListener(ButtonClickHandler);

			@classesBtn = @Button(Vec2f(495,495),Vec2f(120,30),"Classes Menu",SColor(255,255,255,255));
			classesBtn.setLevel(ContainerLevel::PAGE);
			classesBtn.addClickListener(ButtonClickHandler);

			@achievementBtn = @Button(Vec2f(370,495),Vec2f(120,30),"Achievements",SColor(255,255,255,255));
			achievementBtn.setLevel(ContainerLevel::PAGE);
			achievementBtn.addClickListener(ButtonClickHandler);
			achievementBtn.isEnabled = false; // disabled for now

        	@togglemenuBtn = @Button(Vec2f(702,6),Vec2f(90,30),"Exit Menu",SColor(255,255,255,255));//How do close menu? durp. The pain i have gone through has warrented this.
			togglemenuBtn.addClickListener(ButtonClickHandler);
		
			helpWindow.addChild(introText);
			helpWindow.addChild(helpIcon);
			helpWindow.addChild(canvasIcon);
			helpWindow.addChild(changeText);
			helpWindow.addChild(introBtn);
			helpWindow.addChild(optionsBtn);
			helpWindow.addChild(achievementBtn);
       		helpWindow.addChild(togglemenuBtn);
		}

		// init classes menu
		initClasses();
		helpWindow.addChild(playerClassButtons);

		// class selection page
		@classesFrame = @Rectangle(Vec2f(20, 10), Vec2f(760, 490), SColor(0, 0, 0, 0));
		classesFrame.isEnabled = false; 
		classesFrame.setLevel(ContainerLevel::PAGE);
		{
			Vec2f page_size = Vec2f(menuSize.x / 2 - 40, menuSize.y - 40);

			Rectangle@ leftPage = @Rectangle(Vec2f(0, 0), page_size - Vec2f(20, 0), SColor(0, 0, 0, 0));
			leftPage.name = "classFrameLeftPage";
			leftPage.setLevel(ContainerLevel::PAGE_FRAME);

			Label@ title0 = @Label(Vec2f(page_size.x / 2 + 5, 50), Vec2f(100, 32), "Wizard Wars", SColor(255, 0, 0, 0), true, "DragonFire_48");
			Label@ title1 = @Label(Vec2f(page_size.x / 2 + 5, 95), Vec2f(100, 32), "Bestiary", SColor(255, 0, 0, 0), true, "DragonFire_32");
			
			title0.name = "classFrameLeftPageTitle0";
			title1.name = "classFrameLeftPageTitle1";

			string leftPageDesc = "Hello!\n\n This is the place where you can see info about the classes.\nSelect one and press the \"Choose\" button on the right page.\n\n You might also want to rebind your hotbar spells - check out the \"Binds\" section and follow the tips there.\n\n There is also a very useful \"Guides\" section for new players, so just in case, i would advise you to join the spectator team and read, that will help a lot!\n                     (press ESC -> Change Team)";
			Label@ description = @Label(Vec2f(30, 112), Vec2f(page_size.x - 60, page_size.y - 150),
				leftPageDesc, SColor(255, 0, 0, 0), false, "KingThingsPetrockLight_22");
			description.name = "classFrameLeftPageDescription";
			description.setText(description.textWrap(description.label));

			leftPage.addChild(title0);
			leftPage.addChild(title1);
			leftPage.addChild(description);

			Rectangle@ rightPage = @Rectangle(Vec2f(menuSize.x / 2, 0), page_size, SColor(0, 0, 0, 0));
			rightPage.name = "classFrameRightPage";
			rightPage.setLevel(ContainerLevel::PAGE_FRAME);

			// classes' icons
			Rectangle@ classList = @Rectangle(Vec2f(40, 40), Vec2f(page_size.x - 80, page_size.y - 100), SColor(0, 0, 0, 0));
			Vec2f grid = Vec2f(4, 4);

			Vec2f last_icon_size = Vec2f(0, 0);
			for (u8 i = 0; i < grid.x * grid.y; i++)
			{
				Button@ reference;
				if (i < playerClassButtons.list.length)
				{
					WWPlayerClassButton@ WWClassButton = @playerClassButtons.list[i];
					if (WWClassButton is null) continue;

					@reference = @Button(Vec2f(0, 0), WWClassButton.classButton.size, "", SColor(0, 0, 0, 0));
					Icon@ icon = @WWClassButton.display;
					reference.addChild(icon);

					if (i == playerClassButtons.list.length - 1)
					{
						last_icon_size = reference.size;
					}
				}
				else
				{
					@reference = @Button(Vec2f(0, 0), last_icon_size, "", SColor(255, 125, 125, 125));
				}

				reference._customData = i < playerClassButtons.list.length ? i + 102 : 101; // 100 is reserved for "info" redirect button
				reference.addClickListener(classFrameClickHandler);
				reference.setPosition(Vec2f(
					(i % int(grid.x)) * (classList.size.x / grid.x),
					(i / int(grid.x)) * (classList.size.y / grid.y)
				));
				classList.addChild(reference);

				Button@ swapButton = @Button(Vec2f(32, page_size.y - 64), Vec2f(100,32), "", SColor(0, 0, 0, 0));
				swapButton.nodraw = true;
				swapButton.addClickListener(SwapButtonHandler);

				Icon@ swapIcon = @Icon("Paper0.png", Vec2f(0, 0), Vec2f(240, 96), 0, 1.0f, true, Vec2f(100, 32));
				swapButton.addChild(swapIcon);

				rightPage.addChild(swapButton);
			}
			rightPage.addChild(classList);

			classesFrame.addChild(leftPage);
			classesFrame.addChild(rightPage);
		}
		helpWindow.addChild(classesFrame);
		helpWindow.addChild(classesBtn);

		// options
		@optionsFrame = @Rectangle(Vec2f(20, 10), Vec2f(760, 490), SColor(0, 0, 0, 0));
		optionsFrame._customData = 0; // page index
		optionsFrame.setLevel(ContainerLevel::PAGE);
		{
			f32 button_width = 250.0f;
			f32 left_margin = 45.0f;
			f32 top_margin = 20.0f;

			f32 bottom_margin_button = 40.0f;
			f32 bottom_margin_text = 20.0f;
			f32 bottom_margin_slider = 30.0f;

			Vec2f page_size = Vec2f(menuSize.x / 2 - 40, menuSize.y - 40);
			Rectangle@ optionsFramePage0 = @Rectangle(Vec2f(0, 0), page_size, SColor(0, 0, 0, 0));
			
			if (optionsFramePage0 !is null)
			{
				f32 current_y = top_margin;

				@barNumBtn = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				barNumBtn.addClickListener(ButtonClickHandler);

				@startCloseBtn = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				startCloseBtn.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				@toggleHotkeyEmotesBtn = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				toggleHotkeyEmotesBtn.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				@toggleSpellWheelBtn = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				toggleSpellWheelBtn.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				@itemDistanceText = @Label(Vec2f(left_margin, current_y), Vec2f(100, 10), "Wheel radius:", SColor(255,0,0,0), false);
				current_y += bottom_margin_text;

				@itemDistance = @ScrollBar(Vec2f(left_margin, current_y), 160, 10, true, itemDistance_value);
				itemDistance.addSlideEventListener(SliderClickHandler);
				current_y += bottom_margin_slider;

				@hoverDistanceText = @Label(Vec2f(left_margin, current_y), Vec2f(100, 10), "Wheel deselect radius:", SColor(255,0,0,0), false);
				current_y += bottom_margin_text;

				@hoverDistance = @ScrollBar(Vec2f(left_margin, current_y), 160, 10, true, hoverDistance_value);
				hoverDistance.addSlideEventListener(SliderClickHandler);
				current_y += bottom_margin_slider;

				@toggleHoverMessagesBtn = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				toggleHoverMessagesBtn.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				@oneDimensionalSpellbar = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				oneDimensionalSpellbar.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				@resetSpellText = @Label(Vec2f(left_margin, current_y), Vec2f(100, 10), "Reset spell on restart: ", SColor(255,0,0,0), false);
				current_y += bottom_margin_text;

				@resetSpell = @ScrollBar(Vec2f(left_margin, current_y), 160, 16, true, resetSpell_value);
				resetSpell.addSlideEventListener(SliderClickHandler);
				current_y += bottom_margin_slider;

				@toggleSpellHealthConsumeScreenFlash = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "", SColor(255,255,255,255));
				toggleSpellHealthConsumeScreenFlash.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				@resetShowClassDescriptions = @Button(Vec2f(left_margin, current_y), Vec2f(button_width, 30), "Reset Class Descriptions", SColor(255,255,255,255));
				resetShowClassDescriptions.addClickListener(ButtonClickHandler);
				current_y += bottom_margin_button;

				optionsFramePage0.addChild(barNumBtn);
        		optionsFramePage0.addChild(toggleSpellWheelBtn);
				optionsFramePage0.addChild(toggleSpellHealthConsumeScreenFlash);
				optionsFramePage0.addChild(resetShowClassDescriptions);
				optionsFramePage0.addChild(toggleHoverMessagesBtn);
				optionsFramePage0.addChild(oneDimensionalSpellbar);
        		optionsFramePage0.addChild(toggleHotkeyEmotesBtn);
        		optionsFramePage0.addChild(itemDistance);
				optionsFramePage0.addChild(itemDistanceText);
        		optionsFramePage0.addChild(hoverDistance);
				optionsFramePage0.addChild(hoverDistanceText);
				optionsFramePage0.addChild(resetSpellText);
				optionsFramePage0.addChild(resetSpell);
			}

			optionsFrame.addChild(optionsFramePage0);
			optionsFramePages.push_back(optionsFramePage0);

			//Rectangle@ test0 = @Rectangle(Vec2f(menuSize.x / 2, 0), page_size, SColor(125, 255, 0, 0));
			//test0.setLevel(ContainerLevel::PAGE_FRAME);
			//optionsFrame.addChild(test0);
			//optionsFramePages.push_back(test0);

			//Rectangle@ test1 = @Rectangle(Vec2f(0, 0), page_size, SColor(125, 0, 255, 255));
			//test1.setLevel(ContainerLevel::PAGE_FRAME);
			//optionsFrame.addChild(test1);
			//optionsFramePages.push_back(test1);

			if (optionsFramePages.length > OPTIONS_SCROLLER_ITEMS_PER_GROUP)
			{
				Button@ scroller_left = @Button(Vec2f(-90, 255), Vec2f(40, 20), "Previous", SColor(255, 255, 255, 255));
				scroller_left._customData = 0;
				scroller_left.addClickListener(OptionsScrollerClickHandler);

				Button@ scroller_right = @Button(Vec2f(menuSize.x, 255), Vec2f(40, 20), "Next", SColor(255, 255, 255, 255));
				scroller_right._customData = 1;
				scroller_right.addClickListener(OptionsScrollerClickHandler);

				optionsFrame.addChild(scroller_left);
				optionsFrame.addChild(scroller_right);
			}
		}
		updateOptionsScroller();
		helpWindow.addChild(optionsFrame);

		// rework this, keeping as leftover for now
		@spellAssignHelpIcon = @Icon("SpellAssignHelp.png", Vec2f(270, 40), Vec2f(500, 430), 0, 0.5f);
		spellAssignHelpIcon.isEnabled = false;

		@spellHelpIcon = @Icon("SpellHelp.png", Vec2f(300, 40), Vec2f(450, 420), 0, 0.5f);
		spellHelpIcon.isEnabled = false;
		
		helpWindow.addChild(spellHelpIcon); // rework both
		helpWindow.addChild(spellAssignHelpIcon);
		
		// set toggled states
		showHelp = startCloseBtn.getBool("Start Closed", "WizardWars");
		startCloseBtn.toggled = !startCloseBtn.getBool("Start Closed","WizardWars");
		startCloseBtn.desc = (startCloseBtn.toggled) ? "Start Help Closed Enabled" : "Start Help Closed Disabled";
        
		toggleSpellWheelBtn.toggled = toggleSpellWheelBtn.getBool("Spell Wheel Active","WizardWars");
		toggleSpellWheelBtn.desc = (toggleSpellWheelBtn.toggled) ? "Spell Wheel - ON" : "Spell Wheel - OFF";

        WheelMenu@ menu = get_wheel_menu("spells");
        if (menu != null){
            this.set_bool("usespellwheel", toggleSpellWheelBtn.toggled);
        }

		toggleSpellHealthConsumeScreenFlash.toggled = toggleSpellHealthConsumeScreenFlash.getBool("Spell health consume screen flash","WizardWars");
		toggleSpellHealthConsumeScreenFlash.desc = (toggleSpellHealthConsumeScreenFlash.toggled) ? "HP consume red flash - ON" : "HP consume red flash - OFF";
		this.set_bool("spell_health_consume_screen_flash", toggleSpellHealthConsumeScreenFlash.toggled);

		resetShowClassDescriptions.desc = "Reset class descriptions";

		toggleHoverMessagesBtn.toggled = toggleHoverMessagesBtn.getBool("Hover Messages Active","WizardWars");
		toggleHoverMessagesBtn.desc = (toggleHoverMessagesBtn.toggled) ? "Hover Messages - ON" : "Hover Messages - OFF";
        this.set_bool("hovermessages_enabled", toggleHoverMessagesBtn.toggled);

		oneDimensionalSpellbar.toggled = oneDimensionalSpellbar.getBool("Spell bar in 1 row","WizardWars");
		oneDimensionalSpellbar.desc = (oneDimensionalSpellbar.toggled) ? "Spell bar in 1 row - ON" : "Spell bar in 1 row - OFF";
        this.set_bool("one_row_spellbar", oneDimensionalSpellbar.toggled);

        toggleHotkeyEmotesBtn.toggled = toggleHotkeyEmotesBtn.getBool("Hotkey Emotes","WizardWars");
		toggleHotkeyEmotesBtn.desc = (toggleHotkeyEmotesBtn.toggled) ? "Emotes - ON" : "Emotes - OFF";
        this.set_bool("hotkey_emotes", toggleHotkeyEmotesBtn.toggled);

		barNumBtn.toggled = barNumBtn.getBool("Bar Numbers","WizardWars");
		this.set_bool("spell_number_selection", barNumBtn.toggled);
		
		barNumBtn.desc = (barNumBtn.toggled) ? "Spell Bar - ON" : "Spell Bar - OFF";
		optionsFrame.isEnabled = false;
		changeText.isEnabled = false;
		
		// disabled for now
		intitializeAchieves();
		//helpWindow.addChild(shipAchievements);	

        updateOptionSliderValues(); // takes slider values and sets other settings
		setCachedClassesSeen();
		
		this.set_bool("GUI initialized", true);
		print("GUI has been initialized");
	}

	CControls@ controls = getControls();
	if (controls.isKeyJustPressed(KEY_F1)) showHelp = !showHelp;
	
	CPlayer@ player = getLocalPlayer();  
	if (player is null) return;

	string name = player.getUsername();
    if (previous_showHelp != showHelp)
    {
        if(previous_showHelp)
        {
            ConfigFile cfg;
            cfg.loadFile("../Cache/WW_OptionsMenu.cfg");

            cfg.add_u16("item_distance", itemDistance.value);
            cfg.add_u16("hover_distance", hoverDistance.value);
			cfg.add_u16("reset_spell_id", resetSpell.value);

			this.set_u16("reset_spell_id", resetSpell.value);

            cfg.saveFile("WW_OptionsMenu.cfg");
        }
    }

    if (showHelp)
    {
        updateOptionSliderValues();
    }

    bool previous_showHelp = showHelp;//Must be last
}

void updateOptionSliderValues()
{
    float item_distance = 0.3f;//used for changing the value and storing the final value
    for(uint i = 0; i < itemDistance.value; i++)
    {
        item_distance += 0.1f;
    }
    item_distance = WheelMenu::default_item_distance * item_distance;

    float hover_distance = 0.3f;//used for changing the value and storing the final value
    for(uint i = 0; i < hoverDistance.value; i++)
    {
        hover_distance += 0.1f;
    }
    hover_distance = WheelMenu::default_hover_distance * hover_distance;


    WheelMenu@ menu = get_wheel_menu("spells");
    if (menu != null){
        menu.item_distance = item_distance;
        menu.hover_distance = hover_distance;
    }
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if (this.getCommandID("unlockAchievement") == cmd){
		string playerName = params.read_string(), achieveName = params.read_string();
		client_AddToChat("***"+playerName+" has got the achievement \""+achieveName+"\"!***", SColor(255,200,96,145));
	}
	else if (this.getCommandID("requestAchieves") == cmd)
	{	
		CPlayer@ sendFrom = getPlayerByUsername(params.read_string()),sendTo = getPlayerByUsername(params.read_string());
		if(sendFrom.isMyPlayer()){
			CBitStream toSend;
			toSend.write_string(sendTo.getUsername());
			for (int i = 0; i < shipAchievements.list.length; i++){
				toSend.write_bool(shipAchievements.list[i].checkUnlocked());
				print("Added "+shipAchievements.list[i].checkUnlocked()+" gained for "+shipAchievements.list[i].name);
				if (shipAchievements.list[i].hasCon){
					toSend.write_f32(shipAchievements.list[i].getProgress());
					print("Added "+shipAchievements.list[i].getProgress()+" progress for "+shipAchievements.list[i].name);
				}
			}
			this.SendCommand(this.getCommandID("sendAchieves"),toSend);
		}
	}	
	else if (this.getCommandID("sendAchieves") == cmd)
	{
		CPlayer@ sendTo = getPlayerByUsername(params.read_string());
		if (sendTo.isMyPlayer()){
			for (int i = 0; i < shipAchievements.list.length; i++){
				shipAchievements.list[i].gained = params.read_bool();
				print("Set "+shipAchievements.list[i].gained+" gained for "+shipAchievements.list[i].name);
				if (shipAchievements.list[i].hasCon){
					shipAchievements.list[i].conditionSet(params.read_f32());
					print("Set "+shipAchievements.list[i].conCurrent+" progress for "+shipAchievements.list[i].name);
				}
			}
		}
	}
	// the command was removed	
	//else if (this.getCommandID("requestClasses") == cmd)
	//{	
	//	CPlayer@ sendFrom = getPlayerByUsername(params.read_string()),sendTo = getPlayerByUsername(params.read_string());
	//	if(sendFrom.isMyPlayer()){
	//		CBitStream toSend;
	//		toSend.write_string(sendTo.getUsername());
	//		for (int i = 0; i < playerClassButtons.list.length; i++){
	//			print(" gained for "+playerClassButtons.list[i].name);
	//		}
	//		this.SendCommand(this.getCommandID("sendClasses"),toSend);
	//	}
	//}	
	//else if (this.getCommandID("sendClasses") == cmd)
	//{
	//	CPlayer@ sendTo = getPlayerByUsername(params.read_string());
	//	if (sendTo.isMyPlayer()){
	//		for (int i = 0; i < playerClassButtons.list.length; i++){
	//			playerClassButtons.list[i].gained = params.read_bool();
	//			print(" gained for "+playerClassButtons.list[i].name);
	//		}
	//	}
	//}
}

void onRender(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null)
		return;

	//renderTutorial(this);
	
	if (playerClassButtons.displaying)
	{
		playerClassButtons.display();
	}

	if (resetSpell !is null)
	{
		string temp = "First spell selection: "+resetSpell.value;
		if (resetSpell.value == 0) temp = "First spell selection: none";

		resetSpellText.setText(temp);
	}

	Driver@ driver = getDriver();
	if (driver is null) return;

	f32 screen_height = driver.getScreenHeight();
	int minHelpYPos = -menuSize.y - 1;
	int maxHelpYPos = screen_height / 2 - Maths::Clamp(helpWindow.size.y, 0, screen_height) / 2 - 80;

	if (helpWindow.position.y != minHelpYPos)
		helpWindow.draw();
	
	f32 df = 0.33f * getRenderDeltaTime() * 60.0f;
	if (showHelp && helpWindow.position.y < maxHelpYPos) // controls opening and closing the gui
	{
		helpWindow.position = Vec2f(helpWindow.position.x, Maths::Lerp(helpWindow.position.y, maxHelpYPos, df));
		if (Maths::Abs(Maths::Abs(helpWindow.position.y) - Maths::Abs(maxHelpYPos)) <= 1) helpWindow.position = Vec2f(helpWindow.position.x, maxHelpYPos);
	}
	else if (!showHelp && helpWindow.position.y > minHelpYPos)
	{
		helpWindow.position = Vec2f(helpWindow.position.x, Maths::Lerp(helpWindow.position.y, minHelpYPos, df * 2));
	}

	f32 tick = f32(v_fpslimit) / 30.0f;
	active_time = showHelp ? active_time + 1.0f / tick : 0;

	bool initialized = this.get_bool("GUI initialized");
	if (!initialized) return;
	
	RenderClassMenus();
	RenderTooltips(tooltips_fetcher);
	tooltips_fetcher.clear();
}