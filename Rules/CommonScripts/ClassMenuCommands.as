#include "PlayerPrefsCommon.as";

void onInit( CRules@ this )
{
	this.addCommandID("swap classes");
}

void onCommand( CRules@ this, u8 cmd, CBitStream @params )
{
	if (this.getCommandID("swap classes") == cmd)
	{
		u16 playerID = params.read_u16();
		string classConfig = params.read_string();
		
		CPlayer@ player = getPlayerByNetworkId(playerID);

		changeWizDefaultClass(player, classConfig);
			
		PlayerPrefsInfo@ playerPrefsInfo;
		if (!player.get( "playerPrefsInfo", @playerPrefsInfo ))
		{
			return;
		}
	}
}

void changeWizDefaultClass( CPlayer@ thisPlayer, string classConfig = "" )
{
	if (thisPlayer is null)
	{ return; }
	if (classConfig.length() < 1)
	{ return; }

	PlayerPrefsInfo@ playerPrefsInfo;
	if (!thisPlayer.get( "playerPrefsInfo", @playerPrefsInfo ))
	{ return; }

	playerPrefsInfo.classConfig = classConfig;
	ConfigFile cfg;
	if (cfg.loadFile("../Cache/WW_PlayerPrefs.cfg"))
	{
		cfg.add_string("class config", classConfig);
		cfg.saveFile("WW_PlayerPrefs.cfg");
	}
		
	if (thisPlayer.isMyPlayer())
	{
		client_AddToChat("You will now be a " + classConfig + " the next time you respawn or get revived.", SColor(255,255,0,200));
	}
}
