#include "PlayerPrefsCommon.as";

void onInit( CRules@ this )
{
	this.addCommandID("swap classes");
	this.addCommandID("select class");
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (this.getCommandID("swap classes") == cmd)
	{
		u16 playerID = params.read_u16();
		string classConfig = params.read_string();
		
		CPlayer@ player = getPlayerByNetworkId(playerID);
		if (isServer() && this.isWarmup())
		{
			if (player !is null)
			{
				CBlob@ caster_blob = player.getBlob();
				if (caster_blob !is null) caster_blob.server_Die();
			}
		}

		changeWizDefaultClass(player, classConfig);
		if (player !is null) saveClass_server(this, player.getUsername(), classConfig);
	}
	else if (cmd == this.getCommandID("select class"))
	{
		if (!isServer()) return;

		string username;
		if (!params.saferead_string(username)) return;

		string new_class;
		if (!params.saferead_string(new_class)) return;

		saveClass_server(this, username, new_class);
	}
}

void saveClass_server(CRules@ this, string username, string new_class)
{
	ConfigFile cfg;
	cfg.loadFile("../Cache/WW_ClassSelections.cfg");

	string[] arr = {new_class};
	cfg.addArray_string(username, arr);
	cfg.saveFile("WW_ClassSelections.cfg");
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
		client_AddToChat("You will be a " + classConfig + " the next time you respawn or get revived.", SColor(255,255,0,200));
	}
}