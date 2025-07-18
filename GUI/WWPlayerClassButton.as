#include "KGUI.as";
#include "PlayerPrefsCommon.as";
#include "PlatinumCommon.as";
#include "StatusCommon.as";
#include "AttributeCommon.as";
//#include "UnlocksCommon.as";

string classesVersion = "1";
u32 lastHotbarPressTime = 0;
const u8 max_classes_on_page = 8;

string tooltip = "";

//----KGUI ELEMENTS----\\
	 	WWPlayerClassButtonList playerClassButtons;

const string[] specialties_names = {
	"Fire - may ignite enemies","Water - extinguishes fire","Earth - physical damage","Air - high knockback","Nature - organic spells","Electricity - deals more damage to wet enemies",
	"Ice - may freeze or deal more damage to wet enemies","Holy - holy spells","Unholy - unholy spells","Poison - poisonous spells","","",
	"","","","","","",
	"Heal - restore health of allies and self","Support - wide variety of buffs","Summoner - create NPCs or sentries","AoE - Area of Effect spells","Control - some spells can control your enemies","Versatile - good at offense and defense",
	"Impacter - damage dealer",	"Agility - movement spells","Map control - deny large area on the map for some time","Tank - great survivability","Life stealer - some spells might heal you on damage","Mana dependency - core spells require plenty of mana to cast",
	"Cheap spells - spamming those is not a bad decision","Life force - some spells may consume you health instead of mana",			"",			"",			"",	"",
};

// first is main
const u8[] specialties_wizard = {24, 0, 5, 6, 21, 22, 23, 29};
const u8[] specialties_necromancer = {20, 8, 21, 22, 26, 28};
const u8[] specialties_druid = {18, 2, 4, 19, 22, 26, 30};
const u8[] specialties_swordcaster = {25, 21, 22, 24, 30};
const u8[] specialties_entropist = {29, 3, 21, 23, 24, 25, 26};
const u8[] specialties_priest = {18, 0, 7, 19, 21, 22, 26};
const u8[] specialties_shaman = {0, 1, 2, 3, 5, 6, 18, 20, 26};
const u8[] specialties_paladin = {27, 7, 19, 24, 29};
const u8[] specialties_jester = {23, 19, 21, 22, 25, 26};
const u8[] specialties_warlock = {24};

class WWPlayerClassButton 
{
	int classID;
	string name, modName, description, configFilename;
	Icon@ rarity, display;
	Button@ classButton, swapButton;
	ProgressBar@ condition;
	
	Rectangle@ classFrame;
	Button@[] spellButtons;
	Label@ desc, conLbl, spellDescText;
	u32 classCost;

	u8[] specialties;

	Rectangle@ specialties_bg;
	bool gained, hasCon = false;
	
	WWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, string _imageName, int _icon, int _rarity, string _modName, Vec2f _pos, int _size, u8[] _specialties)
	{
		name = _name;
		modName = _modName;
		description = _desc;
		configFilename = _configFilename;
		classID = _classID;
		classCost = _cost;
		@classButton = @Button(_pos,Vec2f(200,46),"",SColor(255,255,255,255));
		@desc = @Label(Vec2f(44,5),Vec2f(114,38),_name,SColor(255,0,0,0),false);
		classButton.addChild(desc);
		switch(_size)
		{
			case 1: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(32,32),_icon,0.44f);break;}
			case 2: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(114,114),_icon,0.13f);break;}
			default: {@display = @Icon(_imageName,Vec2f(9,9),Vec2f(16,16),_icon,0.87f);}
		}
		classButton.addChild(display);
		@rarity = @Icon("GUI/Rarity.png",Vec2f(5,5),Vec2f(18,18),_rarity,1.0f);

		specialties = _specialties;
		
		//gained = checkUnlocked();
		
		classButton.name = _configFilename;
		classButton.addClickListener(ClassButtonHandler);
		
		@classFrame = @Rectangle(Vec2f(232,0),Vec2f(760,490), SColor(0,0,0,0));
		playerClassButtons.addChild(classFrame);
		
		@swapButton = @Button(Vec2f(0,-24), Vec2f(200,24), "Respawn as "+_name, SColor(255,255,255,255));
		swapButton.name = _configFilename;
		classFrame.addChild(swapButton);
		swapButton.addClickListener(SwapButtonHandler);
		
		Label@ classDescText = @Label(Vec2f(0,16), Vec2f(480,34), "", SColor(255,0,0,0), false);
		classDescText.setText(classDescText.textWrap(_desc));
		classFrame.addChild(classDescText);
		
		Spell[] spells;
		if ( _configFilename == "wizard" )
			spells = WizardParams::spells;
		else if ( _configFilename == "druid" )
			spells = DruidParams::spells;
		else if ( _configFilename == "necromancer" )
			spells = NecromancerParams::spells;
		else if ( _configFilename == "swordcaster" )
			spells = SwordCasterParams::spells;
		else if ( _configFilename == "entropist" )
			spells = EntropistParams::spells;
		else if ( _configFilename == "priest" )
			spells = PriestParams::spells;
		else if ( _configFilename == "shaman" )
			spells = ShamanParams::spells;
		else if ( _configFilename == "paladin" )
			spells = PaladinParams::spells;
		else if ( _configFilename == "jester" )
			spells = JesterParams::spells;
		else if ( _configFilename == "warlock" )
			spells = WarlockParams::spells;
		
		
		int spellsLength = spells.length;
		for (uint i = 0; i < spellsLength; i++)
		{
			f32 gridSize = 48.0f;
			Vec2f offset;
			if ( i < 10 )
				offset = Vec2f(gridSize*i,0);
			else
				offset = Vec2f(gridSize*(i-10),gridSize);
			
			spellButtons.push_back( @Button(Vec2f(0,100) + offset, Vec2f(gridSize,gridSize), "", SColor(255,255,255,255)) );
			spellButtons[i].name = spells[i].name;
			
			Icon@ spellIcon = @Icon("SpellIcons.png", Vec2f(8,8), Vec2f(16,16) , spells[i].iconFrame, 1.0f);
			spellButtons[i].addChild(spellIcon);
			spellButtons[i].addClickListener(SpellButtonHandler);
			
			classFrame.addChild(spellButtons[i]);
		}

		Vec2f firstIconPos = Vec2f(98 + 40*0 + (0 == 0 ? 0 : 12), 12) + (0 == 0 ? Vec2f_zero : Vec2f(8,8)) + Vec2f(-6, -6);
		Vec2f lastIconPos = Vec2f(98 + 40*(specialties.size()-1) + ((specialties.size()-1) == 0 ? 0 : 12), 12) + ((specialties.size()-1) == 0 ? Vec2f_zero : Vec2f(8,8)) + Vec2f(-70, 22);
		
		classFrame.addChild(@Rectangle(firstIconPos, lastIconPos + Vec2f(16,16), SColor(255,66,72,75)));
		classFrame.addChild(@Rectangle(firstIconPos + Vec2f(2,2), lastIconPos + Vec2f(12,12), SColor(255,151,167,146)));
		classFrame.addChild(@Rectangle(firstIconPos + Vec2f(4,4), lastIconPos + Vec2f(8,8), SColor(255,108,119,110)));
		
		for (u8 i = 0; i < specialties.size(); i++)
		{
			Icon@ temp = @Icon("Specializations.png", Vec2f(98 + 40*i + (i == 0 ? 0 : 12), 12) + (i == 0 ? Vec2f_zero : Vec2f(8,8)), Vec2f(16,16), specialties[i], i == 0 ? 1.5f : 1.0f);
			temp.addHoverStateListener(iconHover);
			classFrame.addChild(temp);
		}
		
		@spellDescText = @Label(Vec2f(0,200), Vec2f(480,34), "Select a spell above to see its description.", SColor(255,0,0,0), false);
		classFrame.addChild(spellDescText);
		
		Label@ hotbarHelpText = @Label(Vec2f(0,408), Vec2f(480,34), "", SColor(255,0,0,0), false);
		hotbarHelpText.setText(hotbarHelpText.textWrap("HOW TO ASSIGN HOTKEYS: Select a spell at the top of the page and click a location in the hotbar directly above this hint")); 
		classFrame.addChild(hotbarHelpText);
		
		classFrame.isEnabled = false;
	}
	
	void draw(Vec2f pos)
	{
		classButton.position = pos;
		classButton.draw();
	}
}

class WWPlayerClassButtonList : GenericGUIItem
{
	WWPlayerClassButton@[] list;
	int style, timer = 0, page = 1, ApP, totalPages;
	GUIContainer@ tipAnchor = @GUIContainer(Vec2f(0,0),Vec2f(200,46)), pageAnchor = @GUIContainer(Vec2f(0,0),Vec2f(110,30));
	Window@ dropDownW = @Window(Vec2f(getScreenWidth()-400,-150),Vec2f(250,200),3);
	Button@ nextP = @Button(Vec2f(-540,-20),Vec2f(100,40),"->",SColor(255,255,255,255)), prevP = @Button(Vec2f(-640,-20),Vec2f(100,40),"<-",SColor(255,255,255,255));
	Label@ pageNum = @Label(Vec2f(-568,28),Vec2f(30,10),"PAGE 1",SColor(255,0,0,0),false);
	Label dropDownL;
	Icon dropDownD,dropDownR;
	Icon@ dropDownT = @Icon("GUI/achievement_get.png",Vec2f(45,3),Vec2f(157,25),0,0.5f);
	List@ playerChooser = @List(Vec2f(0,0),Vec2f(300,30));
	Button@ playerChooserArrow = @Button(Vec2f(-322,-430),Vec2f(30,30),"V",SColor(255,255,255,255));
	bool displaying = false, needsUpdate = false, hoverDet = false;
	u8[] specialties;

	//Styles: 0 = mini|1= small\\
	WWPlayerClassButtonList(Vec2f _position,Vec2f _size,int _style){

		super(_position,_size);
		style = _style;
		DebugColor = SColor(155,0,0,0);
		CRules@ rules = getRules();
		pageAnchor.addChild(nextP);
		nextP.locked = true;
		pageAnchor.addChild(pageNum);
		pageAnchor.addChild(prevP);
		prevP.locked = true;
		playerChooserArrow.locked = true;
		ApP = max_classes_on_page;
		//rules.addCommandID("announce class unlock");
		rules.addCommandID("requestClasses");
		rules.addCommandID("sendClasses");
		playerChooser.setCurrentItem("Your Classes");
	}

	void registerWWPlayerClassButton(string _name, string _desc, string _configFilename, int _classID, int _cost, int _icon = 0, int _rarity = 0,string _modName = "Default", 
		u8[] _specialties = array<u8>(), string _imageName = "GUI/ClassIcons.png", int _size = 1)
	{
		WWPlayerClassButton@ classButton = @WWPlayerClassButton(_name, _desc, _configFilename, _classID, _cost, _imageName, _icon, _rarity, _modName, position, _size, _specialties);
		list.push_back(classButton);
		totalPages = (list.length / ApP)+1;
		if (totalPages > 1)nextP.locked = false;
		pageNum.setText("PAGE "+page);
		this.specialties = _specialties;
	}
	
	/*void unlockByName(string _name)
	{
	
		CRules@ rules = getRules();
		CPlayer@ player = getLocalPlayer();
		string playerName;  
		bool temp;
		if ( player is null ){ playerName = "Unknown Player";}
		else {playerName = player.getUsername();}
		for(int i = 0; i < list.length; i++)
		{
			if(list[i].name == _name && !list[i].checkUnlocked())
			{
				if (playerChooser.current.label != "Your Classes") temp = list[i].gained;
				list[i].Unlock();
				if (playerChooser.current.label != "Your Classes") list[i].gained = temp;
				startDisplay(list[i]);
				CBitStream params;
				params.write_string(playerName);
				params.write_string(list[i].name);
				rules.SendCommand(rules.getCommandID("announce class unlock"),params);
			}
		}
		
	}*/
	

	void startDisplay(WWPlayerClassButton@ classButton)
	{
		Icon rarity  = classButton.rarity;//Required for a linux fix (on asu's build) caused by .rarity and others being const
		Icon display = classButton.display;//^
		Label desc   = classButton.desc;// ^
		dropDownR = rarity;
		dropDownR.localPosition = classButton.rarity.localPosition + Vec2f(0,30);
		dropDownD = display;
		dropDownD.localPosition = classButton.display.localPosition + Vec2f(0,30);
		dropDownL = desc;
		dropDownL.localPosition = classButton.desc.localPosition + Vec2f(0,30);
		dropDownL.size = classButton.desc.size + Vec2f(110,0);
		dropDownL.setText(dropDownL.label + "\n"+ dropDownL.textWrap(classButton.description));
		dropDownW.clearChildren();
		dropDownW.addChild(dropDownD);
		dropDownW.addChild(dropDownR);
		dropDownW.addChild(dropDownL);
		dropDownW.addChild(dropDownT);
		displaying = true;
	}

	void display()
	{
		if(dropDownW.position.y < 0 && timer < 10){ dropDownW.position = dropDownW.position + Vec2f(0,10);}
		else{ timer++;}
		if (timer > 80 && dropDownW.position.y > -150){ dropDownW.position = dropDownW.position - Vec2f(0,10);}
		else if (timer > 80){ displaying = false; timer = 0;}
		dropDownW.draw();
	}

	void drawSelf(){
		hoverDet = false;
		if (nextP.isClickedWithLButton)clickerHandle(nextP);
		if (prevP.isClickedWithLButton)clickerHandle(prevP);
		if (style == 1)renderSmall();
		if (playerChooser.isClickedWithLButton)clickerHandle(playerChooser);
		if (playerChooser.anchor.isClickedWithLButton) {needsUpdate = true;playerChooser.anchor.isClickedWithLButton=false;}
		pageAnchor.position = position + Vec2f(size.x-60,size.y);
		pageAnchor.draw();
		if (hoverDet && !playerChooser.open) tipAnchor.draw();
		GenericGUIItem::drawSelf();
	}

	void renderSmall()
	{
		needsUpdate = false;
		int counterH=0,counterV=0, i = ApP * (page-1);
		for(i; i < list.length; i++){
			if(50*counterV+46 > size.y){counterH++;counterV= 0;}
			if(204*counterH+200 > size.x)break;
			if(i>=page*ApP)break;
			list[i].draw(position+Vec2f((204*counterH),(50*counterV)-20));
			GUI::DrawRectangle(list[i].classButton.position, list[i].classButton.position+list[i].classButton.size,SColor(0,150,150,150));
			counterV++;
		}
	}

	void clickerHandle(IGUIItem@ sender){ //Internal click handler to operate playerchooser, and page buttons
		if(sender is nextP){
			page +=1;
			if (page == totalPages)sender.locked = true;
			if (prevP.locked) prevP.locked = false;
			pageNum.setText("PAGE "+page);
		}
		if (sender is prevP){
			page -=1;
			if (page == 1)sender.locked = true;
			if (nextP.locked ) nextP.locked = false;
			pageNum.setText("PAGE "+page);
		}
		if (sender is playerChooser){
			playerChooser.resetList();
			int count = getPlayerCount();
			for(int i = 0; i < count; i++){
				CPlayer@ player = getPlayer(i);
				if (player.isMyPlayer()){playerChooser.addItem("Your Classes");}
				else {playerChooser.addItem(player.getUsername()+"'s Classes");}
			}
			playerChooser.open = true;
		}
	}
}

void intitializeClasses()
{
	string configstr = "../Cache/WizardWars_Classes"+classesVersion+".cfg";
	ConfigFile cfg = ConfigFile(configstr);
	if (!cfg.exists("Version")){cfg.add_string("Version","Classes 1.2");
		cfg.saveFile("WizardWars_Classes"+classesVersion+".cfg");}
	playerClassButtons = WWPlayerClassButtonList(Vec2f(50,40),Vec2f(700,400),1);
	playerClassButtons.isEnabled = false;
	
	playerClassButtons.registerWWPlayerClassButton("Wizard", 
													"\nSpecialties: \n\n" +
													"\n     Health: 75" +
													"     Mana: 150" +
													"     Mana rate: 3 mana/sec", 
													"wizard", 0, 0, 2, 5, "WizardWars", specialties_wizard);
	
	playerClassButtons.registerWWPlayerClassButton("Necromancer", 
													"\nSpecialties: \n\n" +
													"\n     Health: 100" +
													"     Mana: 100" +
													"     Mana rate: 4 mana/sec", 
													"necromancer", 1, 0, 3, 5, "WizardWars", specialties_necromancer);

	playerClassButtons.registerWWPlayerClassButton("Druid", 
													"\nSpecialties: \n\n" +
													"\n     Health: 70" +
													"     Mana: 150" +
													"     Mana rate: 4 mana/sec",
													"druid", 3, 20, 4, 0, "WizardWars", specialties_druid);
													
	playerClassButtons.registerWWPlayerClassButton("Swordcaster", 
													"\nSpecialties: \n\n" +
													"\n     Health: 90" +
													"     Mana: 100" +
													"     Mana rate: 3 mana/sec",
													"swordcaster", 4, 0, 5, 0, "WizardWars", specialties_swordcaster);
	playerClassButtons.registerWWPlayerClassButton("Entropist", 
													"\nSpecialties: \n\n" +
													"\n     Health: 75" +
													"     Mana: 200" +
													"     Mana rate: 2 mana/sec",
													"entropist", 5, 0, 6, 0, "WizardWars", specialties_entropist);

	playerClassButtons.registerWWPlayerClassButton("Priest", 
													"\nSpecialties: \n\n" +
													"\n     Health: 80" +
													"     Mana: 150" +
													"     Mana rate: 4 mana/sec",
													"priest", 6, 0, 7, 0, "WizardWars", specialties_priest);

	playerClassButtons.registerWWPlayerClassButton("Shaman", 
													"\nSpecialties: \n\n" +
													"\n     Health: 80" +
													"     Mana: 125" +
													"     Mana rate: 4 mana/sec",
													"shaman", 7, 0, 8, 0, "WizardWars", specialties_shaman);

	playerClassButtons.registerWWPlayerClassButton("Paladin", 
													"\nSpecialties: \n\n" +
													"\n     Health: 100" +
													"     Mana: 250" +
													"     Mana rate: 3 mana/sec",
													"paladin", 8, 0, 9, 0, "WizardWars", specialties_paladin);

	playerClassButtons.registerWWPlayerClassButton("Jester", 
													"\nSpecialties: \n\n" + 
													"\n     Health: 80" +
													"     Mana: 150" +
													"     Mana rate: 3 mana/sec",
													"jester", 9, 0, 10, 0, "WizardWars", specialties_jester);
	
	playerClassButtons.registerWWPlayerClassButton("Warlock", 
													"\nSpecialties: \n\n" + 
													"\n   Health: 80" +
													"     Life Mana: 50" +
													"     Life mana restoration: 1 mana/1 dmg",
													"warlock", 10, 0, 11, 0, "WizardWars", specialties_warlock);
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

void SwapButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
{ 
	CPlayer@ localPlayer = getLocalPlayer();
	if ( localPlayer is null )
		return;
		
	string playerName = localPlayer.getUsername();
	//bool[] unlocks = server_getPlayerUnlocks(playerName);
	
	u16 callerID = localPlayer.getNetworkID();

	CBitStream params;
	params.write_u16(callerID);
	params.write_string(sender.name);
	
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
	for(int i = 0; i < playerClassButtons.list.length; i++)
	{
		Button@ iButton = playerClassButtons.list[i].classButton;	
		if ( iButton.name == sender.name )
		{
			if ( iButton.toggled == false )
				Sound::Play( "MenuSelect2.ogg" );
				
			iButton.toggled = true;
			
			playerClassButtons.list[i].classFrame.isEnabled = true;
		}
		else
		{
			iButton.toggled = false;
			
			playerClassButtons.list[i].classFrame.isEnabled = false;
		}
	}	
}

void SpellButtonHandler(int x , int y , int button, IGUIItem@ sender)	//Button click handler for KGUI
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
	for (int c = 0; c < playerClassButtons.list.length; c++)
	{
		Button@ cButton = playerClassButtons.list[c].classButton;	
		for (int s = 0; s < playerClassButtons.list[c].spellButtons.length; s++)
		{
			Button@ sButton = playerClassButtons.list[c].spellButtons[s];
			if (sButton.name == sender.name && playerClassButtons.list[c].classFrame.isEnabled)
			{
				SetCustomSpell(localPlayer, s);
			
				if (sButton.toggled == false && sender.name != "") 
					Sound::Play( "MenuSelect2.ogg" );
				
				sButton.toggled = true;
				
				Spell sSpell;
				if ( cButton.name == "wizard" )
					sSpell = WizardParams::spells[Maths::Min( s,(WizardParams::spells.length-1) )];
				else if ( cButton.name == "druid" )
					sSpell = DruidParams::spells[Maths::Min( s,(DruidParams::spells.length-1) )];
				else if ( cButton.name == "necromancer" )
					sSpell = NecromancerParams::spells[Maths::Min( s,(NecromancerParams::spells.length-1) )];
				else if ( cButton.name == "swordcaster" )
					sSpell = SwordCasterParams::spells[Maths::Min( s,(SwordCasterParams::spells.length-1) )];
				else if ( cButton.name == "entropist" )
					sSpell = EntropistParams::spells[Maths::Min( s,(EntropistParams::spells.length-1) )];
				else if ( cButton.name == "priest" )
					sSpell = PriestParams::spells[Maths::Min( s,(PriestParams::spells.length-1) )];
				else if ( cButton.name == "shaman" )
					sSpell = ShamanParams::spells[Maths::Min( s,(ShamanParams::spells.length-1) )];
				else if ( cButton.name == "paladin" )
					sSpell = PaladinParams::spells[Maths::Min( s,(PaladinParams::spells.length-1) )];
				else if ( cButton.name == "jester" )
					sSpell = JesterParams::spells[Maths::Min( s,(JesterParams::spells.length-1) )];
				else if ( cButton.name == "warlock" )
					sSpell = WarlockParams::spells[Maths::Min( s,(WarlockParams::spells.length-1) )];

				playerClassButtons.list[c].spellDescText.setText(playerClassButtons.list[c].spellDescText.textWrap("-- " + sSpell.name + " --" + 
																													"\n     " + sSpell.spellDesc + 
																													"\n  Mana cost: " + sSpell.mana));
			
				/*todo: find where to place this:
	Tooltip@[] tooltips;
	
	// draw attributes
	Vec2f attributesPos = helpWindow.position + Vec2f(350.0f, 350.0f);
	for (u8 i = 0; i < classSpells.size(); i++)
	{
		Spell spell = classSpells[i];

		spell.attributes[i].pos = attributesPos - Vec2f(32 * i, 0);
		spell.attributes[i].render(spell.attributes[i].pos, 1.0f, tooltips);
	}

	RenderTooltips(tooltips);*/
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
		Button@ iButton = playerClassButtons.list[i].classButton;
		if (iButton.toggled == true)
		{
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

	Vec2f offset = Vec2f(264.0f, 350.0f);
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
	GUI::DrawText("Primary - " + controls.getActionKeyKeyName(AK_ACTION1), primaryPos + Vec2f(0, -32), color_white);

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
	GUI::DrawText("Secondary - " + controls.getActionKeyKeyName(AK_ACTION2), secondaryPos + Vec2f(32, 8), color_white);

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
	GUI::DrawText("Auxiliary1 - " + controls.getActionKeyKeyName(AK_ACTION3), aux1Pos + Vec2f(32, 8), color_white);

	Vec2f aux2Pos = helpWindow.position + Vec2f(364.0f, 0.0f) + offset;
	u8 aux2SpellID = Maths::Min(hotbarAssignments[17], spellsLength - 1);
	Spell aux2Spell = classSpells[aux2SpellID];
	GUI::DrawFramedPane(aux2Pos, aux2Pos + Vec2f(32, 32));
	GUI::DrawIcon("SpellIcons.png", aux2Spell.iconFrame, Vec2f(16, 16), aux2Pos);
	if (canCustomizeHotbar && (mouseScreenPos - (aux2Pos + Vec2f(16, 16))).Length() < 16.0f)
	{
		assignHotkey(localPlayer, 17, playerPrefsInfo.customSpellID, className);
		hotbarClicked = true;
	}
	GUI::DrawText("Auxiliary2 - " + controls.getActionKeyKeyName(AK_TAUNTS), aux2Pos + Vec2f(32, 8), color_white);

	if (canCustomizeHotbar && hotbarClicked)
	{
		lastHotbarPressTime = controls.lastKeyPressTime;
		Sound::Play("MenuSelect1.ogg");
	}
}
