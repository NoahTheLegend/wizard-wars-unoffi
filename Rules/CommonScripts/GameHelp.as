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

bool showHelp = true;
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

const string lastChangesInfo = "For changes please see https://github.com/Zable-the-Unable/WizardWarsPlus";

const string textInfo = 
		"- Default Basic Controls:\n" +
		" [ " + action1_key + " ] Hold and release to fire your selected primary spell.\n"+
		" [ " + action2_key + " ]  Hold and release to fire your secondary spell.\n"+
		" [ " + action3_key + " ]  Hold and release to fire your auxiliary1 spell.\n"+
		" [ " + taunts_key + " ]  Hold and release to fire your auxiliary2 spell.\n"+
		" [ MIDDLE MOUSE ]  Cancels currently charging spell.\n"+
		" [ " + zoomIn_key + " ], [ " + zoomOut_key + " ]  zoom in/out.\n"+
		"\n- Basic Gameplay:\n" +
		"  *Use mana to cast deadly spells and curses at enemies.\n"+
		"  *Touch mana obelisks to regenerate your mana faster. They contain a finite amount of mana that slowly regenerates over time.\n"+
		"  *Stay alive! You can heal yourself and allies with certain spells and even bring them back from the dead!\n"+
		"  *Eliminate all members of the enemy team to win.\n"+
		"\n- WIZARD WARS FAQ:\n\n"+
		" * How do I choose my primary spell???\n"+
		"Tap the '1' through '5' emote keys to select a spell from the bottom row of the hotbar (located bottom left of your screen). Tap the same key multiple times to go up a row.\n\n"+
		" * How do I swap out my secondary and auxiliary spells?\n"+
		"You must use the hotbar customization panel, located in the classes menu. See the next question for how it's used.\n\n"+
		" * How do I customize my spells hotbar?\n"+
		"First, go to the help screen by pressing F1. Next, go to the classes menu. Now, select the class that you want to customize spells for. Click on the spell button you wish to assign to a key, and click a location on the hotbar representation below it.\n\n"+
		" * How do I figure out what these spells do?\n"+
		"You can read spell descriptions by selecting a spell in the classes menu menu.\n\n"+
		" * How do I turn off this awesome music?! It's too good for my ears!!!\n"+
		"The in-game music is played through KAG's built-in jukebox system. Turn it off just like you would for the default music by going to your 'ESC' settings menu. Still, I recommend putting that shit on full blast to get the best experience!\n\n"+
		" * How do I use some of my spells? They get stuck in mid air or do nothing!\n"+
		"Press your SHIFT key.\n";

const Vec2f windowDimensions = Vec2f(1000,600); //temp

//----KGUI ELEMENTS----\\
	Window@ helpWindow;
	Label@ introText;
	Label@ infoText;
	Label@ helpText;
	Label@ changeText;
	Label@ particleText;
    Label@ itemDistanceText;
    Label@ hoverDistanceText;
	Button@ infoBtn;
	Button@ introBtn;
	Button@ optionsBtn;
	Button@ barNumBtn;
	Button@ startCloseBtn;
    Button@ toggleSpellWheelBtn;
	Button@ toggleHoverMessagesBtn;
	Button@ oneDimensionalSpellbar;
	Button@ achievementBtn;
	Button@ classesBtn;
    Button@ togglemenuBtn;
    Button@ toggleHotkeyEmotesBtn;
	Rectangle@ optionsFrame;
	Icon@ helpIcon;
	Icon@ spellHelpIcon;
	Icon@ spellAssignHelpIcon;
	ScrollBar@ particleCount;
    ScrollBar@ itemDistance;
    ScrollBar@ hoverDistance;

bool isGUINull()
{
	if ( helpWindow is null
		|| introText is null
		|| infoText is null
		|| helpText is null
		|| changeText is null
		|| particleText is null
        || itemDistanceText is null
        || hoverDistanceText is null
		|| infoBtn is null
		|| introBtn is null
		|| optionsBtn is null
		|| classesBtn is null
        || togglemenuBtn is null
        || toggleHotkeyEmotesBtn is null
		|| barNumBtn is null
		|| startCloseBtn is null
        || toggleSpellWheelBtn is null
		|| toggleHoverMessagesBtn is null
		|| oneDimensionalSpellbar is null
		|| achievementBtn is null
		|| optionsFrame is null
		|| helpIcon is null
		|| spellHelpIcon is null
		|| spellAssignHelpIcon is null
		|| particleCount is null
        || itemDistance is null
        || hoverDistance is null )
	{
		return true;
	}
	
	return false;
}
	
void onInit( CRules@ this )
{
	this.set_bool("GUI initialized", false);

	this.addCommandID("join");
	this.addCommandID("updateBAchieve");
	
	u_showtutorial = true;// for ShowTipOnDeath to work


	string configstr = "../Cache/WizardWars_KGUI.cfg";
	ConfigFile cfg = ConfigFile( configstr );
	if (!cfg.exists("Version"))
	{
		cfg.add_string("Version","KGUI 2.3");
		cfg.saveFile("WizardWars_KGUI.cfg");
	}
}

void ButtonClickHandler(int x , int y , int button, IGUIItem@ sender){ //Button click handler for KGUI
	if(sender is infoBtn){
		changeText.isEnabled = false;
		infoText.isEnabled = true;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		spellHelpIcon.isEnabled = false;
		spellAssignHelpIcon.isEnabled = false;
		optionsFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}
	if(sender is introBtn){
		changeText.isEnabled = false;
		infoText.isEnabled = false;
		introText.isEnabled = true;
		helpIcon.isEnabled = true;
		spellHelpIcon.isEnabled = false;
		spellAssignHelpIcon.isEnabled = false;
		optionsFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}
	if(sender is optionsBtn){
		changeText.isEnabled = false;
		infoText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		spellHelpIcon.isEnabled = true;
		spellAssignHelpIcon.isEnabled = false;
		optionsFrame.isEnabled = true;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = false;
	}
	if(sender is achievementBtn){
		changeText.isEnabled = false;
		infoText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		spellHelpIcon.isEnabled = false;
		spellAssignHelpIcon.isEnabled = false;
		optionsFrame.isEnabled = false;
		shipAchievements.isEnabled = true;
		playerClassButtons.isEnabled = false;
	}
	if(sender is classesBtn){
		changeText.isEnabled = false;
		infoText.isEnabled = false;
		introText.isEnabled = false;
		helpIcon.isEnabled = false;
		spellHelpIcon.isEnabled = false;
		spellAssignHelpIcon.isEnabled = true;
		optionsFrame.isEnabled = false;
		shipAchievements.isEnabled = false;
		playerClassButtons.isEnabled = true;
	}
    if(sender is togglemenuBtn){
        showHelp = !showHelp;
    }

	if (sender is barNumBtn){
		barNumBtn.toggled = !barNumBtn.toggled;
		getRules().set_bool("spell_number_selection", barNumBtn.toggled);

		barNumBtn.desc = (barNumBtn.toggled) ? "Spell Bar - ON" : "Spell Bar - OFF";
		barNumBtn.saveBool("Bar Numbers",barNumBtn.toggled,"WizardWars");
	}
	if (sender is startCloseBtn){
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
	if (sender is toggleHoverMessagesBtn)
    {
        toggleHoverMessagesBtn.toggled = !toggleHoverMessagesBtn.toggled;
		toggleHoverMessagesBtn.desc = (toggleHoverMessagesBtn.toggled) ? "Hover Messages - ON" : "Hover Messages - OFF";
		toggleHoverMessagesBtn.saveBool("Hover Messages Active", toggleHoverMessagesBtn.toggled,"WizardWars");
        
        getRules().set_bool("hovermessages_enabled", toggleHoverMessagesBtn.toggled);
    }
	if (sender is oneDimensionalSpellbar)
    {
        oneDimensionalSpellbar.toggled = !oneDimensionalSpellbar.toggled;
		oneDimensionalSpellbar.desc = (oneDimensionalSpellbar.toggled) ? "Spell bar in 1 row - ON" : "Spell bar in 1 row - OFF";
		oneDimensionalSpellbar.saveBool("Spell bar in 1 row", oneDimensionalSpellbar.toggled, "WizardWars");
        
        getRules().set_bool("one_row_spellbar", oneDimensionalSpellbar.toggled);
    }

    //getRules().set_bool("no_hotkey_emotes", true); // toggleHotkeyEmotesBtn

    if (sender is toggleHotkeyEmotesBtn)
    {
        toggleHotkeyEmotesBtn.toggled = !toggleHotkeyEmotesBtn.toggled;
		toggleHotkeyEmotesBtn.desc = (toggleHotkeyEmotesBtn.toggled) ? "Emotes - ON" : "Emotes - OFF";
		toggleHotkeyEmotesBtn.saveBool("Hotkey Emotes", toggleHotkeyEmotesBtn.toggled,"WizardWars");
        
        getRules().set_bool("hotkey_emotes", toggleHotkeyEmotesBtn.toggled);
    }
}

void SliderClickHandler(int dType ,Vec2f mPos, IGUIItem@ sender){
	//if (sender is test){test.slide();}
}

void onTick( CRules@ this )
{
	bool initialized = this.get_bool("GUI initialized");
	if ( !initialized || isGUINull() )		//this little trick is so that the GUI shows up on local host 
	{
        ConfigFile cfg;
        
        u16 itemDistance_value = 6;

        u16 hoverDistance_value = 6;

        if(cfg.loadFile("../Cache/WW_OptionsMenu.cfg"))//Load file, if file exists
        {
            print("options loaded");
            if(cfg.exists("item_distance"))//Value already set?
            {
                print("default set");
                itemDistance_value = cfg.read_u8("item_distance");//Set default
                print(""+itemDistance_value);
            }
            if(cfg.exists("hover_distance"))//Value already set?
            {
                hoverDistance_value = cfg.read_u8("hover_distance");//Set default
            }
        }

		CFileImage@ image = CFileImage( "GameHelp.png" );
		Vec2f imageSize = Vec2f( image.getWidth(), image.getHeight() );
		AddIconToken( "$HELP$", "GameHelp.png", imageSize, 0 );
	
		//---KGUI setup---\\
		@helpIcon = @Icon("GameHelp.png",Vec2f(40,40),imageSize,0,1.0f);
		@spellHelpIcon = @Icon("SpellHelp.png",Vec2f(300,40),Vec2f(450,420),0,0.5f);
		spellHelpIcon.isEnabled = false;
		@spellAssignHelpIcon = @Icon("SpellAssignHelp.png",Vec2f(270,40),Vec2f(500,430),0,0.5f);
		spellAssignHelpIcon.isEnabled = false;

		@helpWindow = @Window(Vec2f(200,-530),Vec2f(800,530));
		helpWindow.name = "Help Window";

		@infoText  = @Label(Vec2f(20,40),Vec2f(780,34),"",SColor(255,0,0,0),false);
		infoText.setText(infoText.textWrap(textInfo));
		@infoBtn = @Button(Vec2f(0,495),Vec2f(100,30),"How to Play",SColor(255,255,255,255));
		infoBtn.addClickListener(ButtonClickHandler);

		@changeText  = @Label(Vec2f(20,40),Vec2f(780,34),"",SColor(255,0,0,0),false);
		changeText.setText(changeText.textWrap(lastChangesInfo));

		@introText  = @Label(Vec2f(280,10),Vec2f(780,15),"",SColor(255,0,0,0),false);
		introText.setText(introText.textWrap("    Welcome to Wizard Wars!\n(Press F1 to close this window)"));
		@introBtn = @Button(Vec2f(160,495),Vec2f(100,30),"Home Page",SColor(255,255,255,255));
		introBtn.addClickListener(ButtonClickHandler);

		@helpText  = @Label(Vec2f(6,10),Vec2f(100,34),"",SColor(255,0,0,0),false);
		helpText.setText(helpText.textWrap(lastChangesInfo));

		@optionsBtn = @Button(Vec2f(265,495),Vec2f(100,30),"Options",SColor(255,255,255,255));
		optionsBtn.addClickListener(ButtonClickHandler);
		
		@barNumBtn = @Button(Vec2f(10,10),Vec2f(200,30),"",SColor(255,255,255,255));
		barNumBtn.addClickListener(ButtonClickHandler);
		
		@startCloseBtn = @Button(Vec2f(10,50),Vec2f(200,30),"",SColor(255,255,255,255));
		startCloseBtn.addClickListener(ButtonClickHandler);

        @toggleSpellWheelBtn = @Button(Vec2f(10,90),Vec2f(200,30),"",SColor(255,255,255,255));
		toggleSpellWheelBtn.addClickListener(ButtonClickHandler);

		@toggleHoverMessagesBtn = @Button(Vec2f(10,240),Vec2f(200,30),"",SColor(255,255,255,255));
		toggleHoverMessagesBtn.addClickListener(ButtonClickHandler);
		
		@oneDimensionalSpellbar = @Button(Vec2f(10,280),Vec2f(200,30),"",SColor(255,255,255,255));
		oneDimensionalSpellbar.addClickListener(ButtonClickHandler);

        @toggleHotkeyEmotesBtn = @Button(Vec2f(10,50),Vec2f(200,30),"",SColor(255,255,255,255));
		toggleHotkeyEmotesBtn.addClickListener(ButtonClickHandler);

		@achievementBtn = @Button(Vec2f(370,495),Vec2f(120,30),"Achievements",SColor(255,255,255,255));
		achievementBtn.addClickListener(ButtonClickHandler);
		
		@classesBtn = @Button(Vec2f(495,495),Vec2f(120,30),"Classes Menu",SColor(255,255,255,255));
		classesBtn.addClickListener(ButtonClickHandler);

        @togglemenuBtn = @Button(Vec2f(702,6),Vec2f(90,30),"Exit Menu",SColor(255,255,255,255));//How do close menu? durp. The pain i have gone through has warrented this.
		togglemenuBtn.addClickListener(ButtonClickHandler);

		@optionsFrame = @Rectangle(Vec2f(20,10),Vec2f(760,490), SColor(0,0,0,0));

        @particleCount = @ScrollBar(Vec2f(10,105),80,4,true,2);
		@particleText = @Label(Vec2f(10,90),Vec2f(100,10),"Particle counts:",SColor(255,0,0,0),false);
		particleCount.addSlideEventListener(SliderClickHandler);

		@itemDistance = @ScrollBar(Vec2f(10,150),160,10,true, itemDistance_value);
		@itemDistanceText = @Label(Vec2f(10,130),Vec2f(100,10),"Wheel radius:",SColor(255,0,0,0),false);
		itemDistance.addSlideEventListener(SliderClickHandler);

        @hoverDistance = @ScrollBar(Vec2f(10,200),160,10,true, hoverDistance_value);
		@hoverDistanceText = @Label(Vec2f(10,180),Vec2f(100,10),"Wheel deselect radius:",SColor(255,0,0,0),false);
		hoverDistance.addSlideEventListener(SliderClickHandler);

		//---KGUI Parenting---\\
		helpWindow.addChild(introText);
		helpWindow.addChild(helpIcon);
		helpWindow.addChild(infoText);
		helpWindow.addChild(changeText);
		helpWindow.addChild(introBtn);
		//helpWindow.addChild(infoBtn);
		helpWindow.addChild(optionsBtn);
		helpWindow.addChild(optionsFrame);
		helpWindow.addChild(achievementBtn);
		helpWindow.addChild(classesBtn);
        helpWindow.addChild(togglemenuBtn);
		optionsFrame.addChild(barNumBtn);
        optionsFrame.addChild(toggleSpellWheelBtn);
		optionsFrame.addChild(toggleHoverMessagesBtn);
		optionsFrame.addChild(oneDimensionalSpellbar);
        optionsFrame.addChild(toggleHotkeyEmotesBtn);
		helpWindow.addChild(spellHelpIcon);
		helpWindow.addChild(spellAssignHelpIcon);
        
        optionsFrame.addChild(itemDistance);
		optionsFrame.addChild(itemDistanceText);
        optionsFrame.addChild(hoverDistance);
		optionsFrame.addChild(hoverDistanceText);
		showHelp = startCloseBtn.getBool("Start Closed","WizardWars");
		startCloseBtn.toggled = !startCloseBtn.getBool("Start Closed","WizardWars");
		startCloseBtn.desc = (startCloseBtn.toggled) ? "Start Help Closed Enabled" : "Start Help Closed Disabled";
        
		toggleSpellWheelBtn.toggled = toggleSpellWheelBtn.getBool("Spell Wheel Active","WizardWars");
		toggleSpellWheelBtn.desc = (toggleSpellWheelBtn.toggled) ? "Spell Wheel - ON" : "Spell Wheel - OFF";
        WheelMenu@ menu = get_wheel_menu("spells");
        if (menu != null){
            this.set_bool("usespellwheel", toggleSpellWheelBtn.toggled);
        }
		
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
		infoText.isEnabled = false;

		intitializeAchieves();
		helpWindow.addChild(shipAchievements);	
		
		intitializeClasses();
		helpWindow.addChild(playerClassButtons);

        updateOptionSliderValues();//Takes slider values and sets other settings
		
		this.set_bool("GUI initialized", true);
		print("GUI has been initialized");
	}

	CControls@ controls = getControls();
	if ( controls.isKeyJustPressed( KEY_F1 ) )
	{
		showHelp = !showHelp;
	}

	CPlayer@ player = getLocalPlayer();  
	if ( player is null ) return;
	string name = player.getUsername();
	u16 pBooty = 0;
	pBooty = this.get_u16( "booty" + name );
	if (this.get_bool("join")){
		shipAchievements.unlockByName("First Join");
		shipAchievements.increaseCondition("Ten Joins", 1.0f);
		shipAchievements.increaseCondition("Keeps Coming Back", 1.0f);
		this.set_bool("join",false);
	}

	if (this.get_bool("winner")){
		if (this.get_f32("coreHP") <= 5)shipAchievements.unlockByName("Close Call");
		if (this.get_f32("coreHP") == 100)shipAchievements.unlockByName("Flawless");
		shipAchievements.unlockByName("Winner");
		shipAchievements.increaseCondition("Champion", 1.0f);
		shipAchievements.increaseCondition("Unstoppable", 1.0f);
		this.set_bool("winner",false);
	}

	if (pBooty > oldBooty && !this.get_bool("bootyAchieve") ){
		float amount = pBooty-oldBooty;
		shipAchievements.increaseCondition("Treasure", amount);
		shipAchievements.increaseCondition("Hoarder", amount);
		shipAchievements.increaseCondition("Plundering", amount);
		shipAchievements.increaseCondition("Motherload", amount);
	}else if ((pBooty - oldBooty) != 0 && this.get_bool("bootyAchieve")) {this.set_bool("bootyAchieve",false);}
	oldBooty=pBooty;

	if (shipAchievements.needsUpdate)
	{
		string[]@ tokens = shipAchievements.playerChooser.current.label.split("'");
		if (shipAchievements.playerChooser.current.label.substr(0,4) == "Your" ){tokens[0] = getLocalPlayer().getUsername();}
		CPlayer@ requestPlayer = getPlayerByUsername(tokens[0]);
		CBitStream params;
		params.write_string(tokens[0]);
		params.write_string(getLocalPlayer().getUsername());
		this.SendCommand(this.getCommandID("requestAchieves"),params);
	}
	
	//playerClassButtons.unlockByName("Wizard");
	if (playerClassButtons.needsUpdate)
	{
		string[]@ tokens = playerClassButtons.playerChooser.current.label.split("'");
		if (playerClassButtons.playerChooser.current.label.substr(0,4) == "Your" ){tokens[0] = getLocalPlayer().getUsername();}
		CPlayer@ requestPlayer = getPlayerByUsername(tokens[0]);
		CBitStream params;
		params.write_string(tokens[0]);
		params.write_string(getLocalPlayer().getUsername());
		this.SendCommand(this.getCommandID("requestClasses"),params);
	}

    if(previous_showHelp != showHelp)//Menu just closed or opened
    {
        if(previous_showHelp)//Menu closed
        {
            ConfigFile cfg;
            cfg.loadFile("../Cache/WW_OptionsMenu.cfg");

            cfg.add_u16("item_distance", itemDistance.value);
            cfg.add_u16("hover_distance", hoverDistance.value);

            cfg.saveFile("WW_OptionsMenu.cfg");
        }
    }

    if(showHelp)//Only do if the help menu is open
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
	/*else if (this.getCommandID("announce class unlock") == cmd)
	{
		string playerName = params.read_string(), className = params.read_string();
		client_AddToChat("***"+playerName+" has unlocked the class \""+className+"\"!***", SColor(255,0,196,155));
	}*/
	else if (this.getCommandID("requestClasses") == cmd)
	{	
		CPlayer@ sendFrom = getPlayerByUsername(params.read_string()),sendTo = getPlayerByUsername(params.read_string());
		if(sendFrom.isMyPlayer()){
			CBitStream toSend;
			toSend.write_string(sendTo.getUsername());
			for (int i = 0; i < playerClassButtons.list.length; i++){
				print(" gained for "+playerClassButtons.list[i].name);
			}
			this.SendCommand(this.getCommandID("sendClasses"),toSend);
		}
	}	
	else if (this.getCommandID("sendClasses") == cmd)
	{
		CPlayer@ sendTo = getPlayerByUsername(params.read_string());
		if (sendTo.isMyPlayer()){
			for (int i = 0; i < playerClassButtons.list.length; i++){
				playerClassButtons.list[i].gained = params.read_bool();
				print(" gained for "+playerClassButtons.list[i].name);
			}
		}
	}
}

//a work in progress
void onRender( CRules@ this )
{
	CPlayer@ player = getLocalPlayer();
	if ( player is null )
		return;

	//renderTutorial(this);
	
	if(shipAchievements.displaying)
	{
		shipAchievements.display();
	}
	if(playerClassButtons.displaying)
	{
		playerClassButtons.display();
	}

	if (particleCount is null) return;
	string temp = "Particle count: ";
	if (particleCount.value == 0){
		temp += "None";
	}else if (particleCount.value == 1){
		temp += "Low";
	}else if (particleCount.value == 2){
		temp += "Medium";
	} else{
		temp += "High";
	}
	particleText.setText(temp);


	int minHelpYPos = -530;
	int maxHelpYPos = 48;
	int scrollSpeed = 40;
	
	if ( helpWindow.position.y != minHelpYPos )
		helpWindow.draw();
	
	if (showHelp && helpWindow.position.y < maxHelpYPos) //controls opening and closing the gui
	{
		helpWindow.position = Vec2f( helpWindow.position.x,  Maths::Min(helpWindow.position.y + scrollSpeed, maxHelpYPos) );
	}
	if (!showHelp && helpWindow.position.y > minHelpYPos)
	{
		helpWindow.position = Vec2f( helpWindow.position.x, Maths::Max( helpWindow.position.y - scrollSpeed, minHelpYPos) );
	}

	CBlob@ localBlob = getLocalPlayerBlob();
	CControls@ controls = getControls();
	
	RenderClassMenus();
}