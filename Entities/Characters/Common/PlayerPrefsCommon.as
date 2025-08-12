//Wizard Include
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
#include "MagicCommon.as";

const u8 MAX_SPELLS = 20;
const u8 WIZARD_TOTAL_HOTKEYS = 18;
const u8 DRUID_TOTAL_HOTKEYS = 18;
const u8 NECROMANCER_TOTAL_HOTKEYS = 18;
const u8 SWORDCASTER_TOTAL_HOTKEYS = 18;
const u8 ENTROPIST_TOTAL_HOTKEYS = 18;
const u8 PRIEST_TOTAL_HOTKEYS = 18;
const u8 SHAMAN_TOTAL_HOTKEYS = 18;
const u8 PALADIN_TOTAL_HOTKEYS = 18;
const u8 JESTER_TOTAL_HOTKEYS = 18;
const u8 WARLOCK_TOTAL_HOTKEYS = 18;

shared class PlayerPrefsInfo
{
	bool infoLoaded;
	string classConfig;

	u8 primarySpellID;
	u8 primaryHotkeyID;
	u8 customSpellID;

	u8[] hotbarAssignments_Wizard;
	u8[] hotbarAssignments_Druid;
	u8[] hotbarAssignments_Necromancer;
	u8[] hotbarAssignments_SwordCaster;
	u8[] hotbarAssignments_Entropist;
	u8[] hotbarAssignments_Priest;
	u8[] hotbarAssignments_Shaman;
	u8[] hotbarAssignments_Paladin;
	u8[] hotbarAssignments_Jester;
	u8[] hotbarAssignments_Warlock;

	s32[] spell_cooldowns;

	PlayerPrefsInfo()
	{
		infoLoaded = false;
		classConfig = "wizard";

		//if (isClient())
		//{
		//	ConfigFile cfg;
		//	if (cfg !is null && cfg.loadFile("../Cache/WW_PlayerPrefs.cfg")) // NPE here
		//	{
		//		classConfig = cfg.read_string("class config");
		//	}
		//}
	
		primarySpellID = 0;
		primaryHotkeyID = 0;
		
		for (uint i = 0; i < MAX_SPELLS; ++i)
		{
			spell_cooldowns.push_back(0);
		}
	}
};

void SetCustomSpell( CPlayer@ this, const u8 id )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	playerPrefsInfo.customSpellID = id;
}

void assignHotkey( CPlayer@ this, const u8 hotkeyID, const u8 spellID, string playerClass )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	//print("hotkey " + hotkeyID + " assigned to spell " + spellID);
	if ( playerClass == "wizard" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Wizard.length;
		playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "druid" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Druid.length;
		playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "necromancer" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Necromancer.length;
		playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "swordcaster" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_SwordCaster.length;
		playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "entropist" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Entropist.length;
		playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "priest" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Priest.length;
		playerPrefsInfo.hotbarAssignments_Priest[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Priest[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "shaman" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Shaman.length;
		playerPrefsInfo.hotbarAssignments_Shaman[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Shaman[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "paladin" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Paladin.length;
		playerPrefsInfo.hotbarAssignments_Paladin[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Paladin[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "jester" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Jester.length;
		playerPrefsInfo.hotbarAssignments_Jester[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Jester[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	else if ( playerClass == "warlock" )
	{
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Warlock.length;
		playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(hotkeyID,hotbarLength-1)] = spellID;
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(playerPrefsInfo.primaryHotkeyID,hotbarLength-1)];
	}
	
	saveHotbarAssignments( this );
}

void defaultHotbarAssignments( CPlayer@ this, string playerClass )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	if ( playerClass == "wizard" )
	{
		playerPrefsInfo.hotbarAssignments_Wizard.clear();
		
		int spellsLength = WizardParams::spells.length;
		for (uint i = 0; i < WIZARD_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(3);	//assign aux2 to something
		}	
	}
	if ( playerClass == "druid" )
	{
		playerPrefsInfo.hotbarAssignments_Druid.clear();
		
		int spellsLength = DruidParams::spells.length;
		for (uint i = 0; i < DRUID_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Druid.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "necromancer" )
	{
		playerPrefsInfo.hotbarAssignments_Necromancer.clear();
		
		int spellsLength = NecromancerParams::spells.length;
		for (uint i = 0; i < NECROMANCER_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(0);
				continue;
			}
		
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "swordcaster" )
	{
		playerPrefsInfo.hotbarAssignments_SwordCaster.clear();
		
		int spellsLength = SwordCasterParams::spells.length;
		for (uint i = 0; i < SWORDCASTER_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(0);
				continue;
			}
		
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "entropist" )
	{
		playerPrefsInfo.hotbarAssignments_Entropist.clear();
		
		int spellsLength = EntropistParams::spells.length;
		for (uint i = 0; i < ENTROPIST_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "priest" )
	{
		playerPrefsInfo.hotbarAssignments_Priest.clear();
		
		int spellsLength = PriestParams::spells.length;
		for (uint i = 0; i < PRIEST_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Priest.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "shaman" )
	{
		playerPrefsInfo.hotbarAssignments_Shaman.clear();
		
		int spellsLength = ShamanParams::spells.length;
		for (uint i = 0; i < SHAMAN_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "paladin" )
	{
		playerPrefsInfo.hotbarAssignments_Paladin.clear();
		
		int spellsLength = PaladinParams::spells.length;
		for (uint i = 0; i < PALADIN_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "jester" )
	{
		playerPrefsInfo.hotbarAssignments_Paladin.clear();
		
		int spellsLength = JesterParams::spells.length;
		for (uint i = 0; i < JESTER_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Jester.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(3);	//assign aux2 to something
		}	
	}
	else if ( playerClass == "warlock" )
	{
		playerPrefsInfo.hotbarAssignments_Paladin.clear();
		
		int spellsLength = WarlockParams::spells.length;
		for (uint i = 0; i < WARLOCK_TOTAL_HOTKEYS; i++)
		{
			if ( i > spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(0);
				continue;
			}
				
			if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(i);
			else if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(3);	//assign aux2 to something
		}	
	}
}

void saveHotbarAssignments( CPlayer@ this )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	if (isClient())
	{
		ConfigFile cfg;
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Wizard.length; i++)
		{	
			cfg.add_u32("wizard hotkey" + i, playerPrefsInfo.hotbarAssignments_Wizard[i]);
		}
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Druid.length; i++)
		{	
			cfg.add_u32("druid hotkey" + i, playerPrefsInfo.hotbarAssignments_Druid[i]);
		}
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Necromancer.length; i++)
		{		
			cfg.add_u32("necromancer hotkey" + i, playerPrefsInfo.hotbarAssignments_Necromancer[i]);
		}
		
		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_SwordCaster.length; i++)
		{		
			cfg.add_u32("swordcaster hotkey" + i, playerPrefsInfo.hotbarAssignments_SwordCaster[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Entropist.length; i++)
		{	
			cfg.add_u32("entropist hotkey" + i, playerPrefsInfo.hotbarAssignments_Entropist[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Priest.length; i++)
		{	
			cfg.add_u32("priest hotkey" + i, playerPrefsInfo.hotbarAssignments_Priest[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Shaman.length; i++)
		{	
			cfg.add_u32("shaman hotkey" + i, playerPrefsInfo.hotbarAssignments_Shaman[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Paladin.length; i++)
		{	
			cfg.add_u32("paladin hotkey" + i, playerPrefsInfo.hotbarAssignments_Paladin[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Jester.length; i++)
		{	
			cfg.add_u32("jester hotkey" + i, playerPrefsInfo.hotbarAssignments_Jester[i]);
		}

		for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Warlock.length; i++)
		{	
			cfg.add_u32("warlock hotkey" + i, playerPrefsInfo.hotbarAssignments_Warlock[i]);
		}

		cfg.saveFile( "WW_PlayerPrefs.cfg" );
	}	
}

void loadHotbarAssignments( CPlayer@ this, string playerClass )
{
	PlayerPrefsInfo@ playerPrefsInfo;
	if (!this.get( "playerPrefsInfo", @playerPrefsInfo ))
	{
		return;
	}
	
	if ( playerClass == "wizard" )
	{
		playerPrefsInfo.hotbarAssignments_Wizard.clear();
		
		int spellsLength = WizardParams::spells.length;
		for (uint i = 0; i < WIZARD_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Wizard.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Wizard.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Wizard.length; i++)
				{		
					//if ( cfg.exists( "wizard hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("wizard hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Wizard = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "druid" )
	{
		playerPrefsInfo.hotbarAssignments_Druid.clear();
		
		int spellsLength = DruidParams::spells.length;
		for (uint i = 0; i < DRUID_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Druid.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Druid.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Druid.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Druid.length; i++)
				{		
					//if ( cfg.exists( "druid hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("druid hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Druid = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "necromancer" )
	{
		playerPrefsInfo.hotbarAssignments_Necromancer.clear();
		
		int spellsLength = NecromancerParams::spells.length;
		for (uint i = 0; i < NECROMANCER_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(0);
				continue;
			}
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Necromancer.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Necromancer.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Necromancer.length; i++)
				{		
					//if ( cfg.exists( "necromancer hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("necromancer hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Necromancer = loadedHotkeys;
				//ig file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "swordcaster" )
	{
		playerPrefsInfo.hotbarAssignments_SwordCaster.clear();
		
		int spellsLength = SwordCasterParams::spells.length;
		for (uint i = 0; i < SWORDCASTER_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(0);
				continue;
			}
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_SwordCaster.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_SwordCaster.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_SwordCaster.length; i++)
				{		
					//if ( cfg.exists( "swordcaster hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("swordcaster hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_SwordCaster = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "entropist" )
	{
		playerPrefsInfo.hotbarAssignments_Entropist.clear();
		
		int spellsLength = EntropistParams::spells.length;
		for (uint i = 0; i < ENTROPIST_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Entropist.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Entropist.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Entropist.length; i++)
				{		
					//if ( cfg.exists( "entropist hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("entropist hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Entropist = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "priest" )
	{
		playerPrefsInfo.hotbarAssignments_Priest.clear();
		
		int spellsLength = PriestParams::spells.length;
		for (uint i = 0; i < PRIEST_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Priest.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Priest.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Priest.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Priest.length; i++)
				{		
					//if ( cfg.exists( "priest hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("priest hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Priest = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Priest[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "shaman" )
	{
		playerPrefsInfo.hotbarAssignments_Shaman.clear();
		
		int spellsLength = ShamanParams::spells.length;
		for (uint i = 0; i < SHAMAN_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Shaman.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Shaman.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Shaman.length; i++)
				{		
					//if ( cfg.exists( "shaman hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("shaman hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Shaman = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Shaman[Maths::Min(0,hotbarLength-1)];
	}
	else if ( playerClass == "paladin" )
	{
		playerPrefsInfo.hotbarAssignments_Paladin.clear();
		
		int spellsLength = PaladinParams::spells.length;
		for (uint i = 0; i < PALADIN_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Paladin.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Paladin.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Paladin.length; i++)
				{		
					//if ( cfg.exists( "paladin hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("paladin hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Paladin = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Paladin[Maths::Min(0,hotbarLength-1)];
	}

	else if ( playerClass == "jester" )
	{
		playerPrefsInfo.hotbarAssignments_Jester.clear();
		
		int spellsLength = JesterParams::spells.length;
		for (uint i = 0; i < JESTER_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Jester.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Jester.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Jester.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Jester.length; i++)
				{		
					//if ( cfg.exists( "jester hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("jester hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Jester = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Jester[Maths::Min(0,hotbarLength-1)];
	}

	else if ( playerClass == "warlock" )
	{
		playerPrefsInfo.hotbarAssignments_Warlock.clear();
		
		int spellsLength = WarlockParams::spells.length;
		for (uint i = 0; i < WARLOCK_TOTAL_HOTKEYS; i++)
		{
			if ( i == 15 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(1);	//assign secondary to teleport
			else if ( i == 16 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(2);	//assign aux1 to counter spell
			else if ( i == 17 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(3);	//assign aux2 to something
			else if ( i >= spellsLength )
			{
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(0);
				continue;
			}	
			else if ( i < 15 )
				playerPrefsInfo.hotbarAssignments_Warlock.push_back(i);
		}
		
		int hotbarLength = playerPrefsInfo.hotbarAssignments_Warlock.length;
		if (isClient()) 
		{	
			u8[] loadedHotkeys;
			ConfigFile cfg;
			if ( cfg.loadFile("../Cache/WW_PlayerPrefs.cfg") )
			{
				for (uint i = 0; i < playerPrefsInfo.hotbarAssignments_Warlock.length; i++)
				{		
					//if ( cfg.exists( "warlock hotkey" + i ) )
					{
						u32 iHotkeyAssignment = cfg.read_u32("warlock hotkey" + i, i);
						loadedHotkeys.push_back( Maths::Min(iHotkeyAssignment, spellsLength-1) );
					}
					
				}
				playerPrefsInfo.hotbarAssignments_Warlock = loadedHotkeys;
				//print("Hotkey config file loaded.");
			}
		}
		
		playerPrefsInfo.primarySpellID = playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(0,hotbarLength-1)];
	}
}