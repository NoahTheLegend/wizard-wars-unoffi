// Simple chat processing example.
// If the player sends a command, the server does what the command says.
// You can also modify the chat message before it is sent to clients by modifying text_out
// By the way, in case you couldn't tell, "mat" stands for "material(s)"

#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";
#include "EffectMissileEnum.as";
#include "MagicCommon.as";

void onInit(CRules@ this)
{
	this.set_bool("awootism",false);
}

string awootismIfy(string s){
	return s.replace("O","OwO").replace("o","OwO").replace("U","UwU").replace("u","UwU");
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if(this.get_bool("awootism"))
	{
		text_out = awootismIfy(text_in);
	}

	if (player is null)
	{
		return true;
	}
	bool admin = (getSecurity().getPlayerSeclev(player).getName() == 'Super Admin');

	if(admin && text_in == "!awootism")
	{
		this.set_bool("awootism",!this.get_bool("awootism"));
		this.Sync("awootism",false);
	}

	CBlob@ blob = player.getBlob(); // now, when the code references "blob," it means the player who called the command

	if(admin && text_in == "!givmana")
	{
		if (isServer())
		{
			CBlob@ orb = server_CreateBlob( "effect_missile", blob.getTeamNum(), blob.getPosition() ); 
			if (orb !is null)
			{
				orb.set_u8("effect", mana_effect_missile);
				orb.set_u8("mana_used", 20);
				orb.set_u8("caster_mana", 3);
				orb.set_u8("direct_restore", 0);
                orb.set_bool("silent", true);

				orb.IgnoreCollisionWhileOverlapped( blob );
                Vec2f orbVel = Vec2f( 0.1f , 0 ).RotateByDegrees(XORRandom(360));
				orb.setVelocity( orbVel );
			}
		}
	}

	if (blob is null)
	{
		if(admin && text_in == "!admin")
		{
			server_CreateBlob("pixie",3,Vec2f(getMap().tilemapwidth*4,0)).server_SetPlayer(player);
		}
		return true;
	}

	if(admin && text_in == "!admin")
	{
		server_CreateBlob("pixie",blob.getTeamNum(),blob.getPosition()).server_SetPlayer(player);
		blob.server_Die();
	}


	Vec2f pos = blob.getPosition(); // grab player position (x, y)
	int team = blob.getTeamNum(); // grab player team number (for i.e. making all flags you spawn be your team's flags)

	// MODDERS --- WRITE ALL COMMANDS BELOW!!

	// commands that don't rely on sv_test being on (sv_test = 1)

	if (text_in == "!bot" && player.isMod()) // TODO: whoaaa check seclevs
	{
		CPlayer@ bot = AddBot("Henry"); //when there are multiple "Henry" bots, they'll be differentiated by a number (i.e. Henry2)
		return true;
	}
	else if (text_in == "!t")
	{
		LoadMap("Infinity.png");
	}
	else if (text_in == "!debug" && player.isMod())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");
		}
	}

	// if the game mode is Sandbox OR if sv_test is true, you can use these commands
	if (this.gamemode_name == "Sandbox" || sv_test == true ||  admin)
	{
		if (text_in == "!allmats") // 500 wood, 500 stone, 100 gold
		{
			//wood
			CBlob@ wood = server_CreateBlob('mat_wood', -1, pos);
			wood.server_SetQuantity(500); // so I don't have to repeat the server_CreateBlob line again
			//stone
			CBlob@ stone = server_CreateBlob('mat_stone', -1, pos);
			stone.server_SetQuantity(500);
			//gold
			CBlob@ gold = server_CreateBlob('mat_gold', -1, pos);
			gold.server_SetQuantity(100);
		}
		else if (text_in == "!woodstone") // 250 wood, 500 stone
		{
			CBlob@ b = server_CreateBlob('mat_wood', -1, pos);

			for (int i = 0; i < 2; i++)
			{
				CBlob@ b = server_CreateBlob('mat_stone', -1, pos);
			}
		}
		else if (text_in == "!stonewood") // 500 wood, 250 stone
		{
			CBlob@ b = server_CreateBlob('mat_stone', -1, pos);

			for (int i = 0; i < 2; i++)
			{
				CBlob@ b = server_CreateBlob('mat_wood', -1, pos);
			}
		}
		else if (text_in == "!wood") // 250 wood
		{
			CBlob@ b = server_CreateBlob('mat_wood', -1, pos);
		}
		else if (text_in == "!stones" || text_in == "!stone") // 250 stone
		{
			CBlob@ b = server_CreateBlob('mat_stone', -1, pos);
		}
		else if (text_in == "!gold") // 200 gold
		{
			for (int i = 0; i < 4; i++)
			{
				CBlob@ b = server_CreateBlob('mat_gold', -1, pos);
			}
		}
	}

	// spawning things

	// these all require sv_test - no spawning without it
	// some also require the player to have mod status (!spawnwater)

	if (sv_test || admin)
	{
		if (text_in == "!tree") // pine tree (seed)
		{
			server_MakeSeed(pos, "tree_pine", 600, 1, 16);
		}
		else if (text_in == "!btree") // bushy tree (seed)
		{
			server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
		}
		else if (text_in == "!allarrows") // 30 normal arrows, 2 water arrows, 2 fire arrows, 1 bomb arrow (full inventory for archer)
		{
			CBlob@ normal = server_CreateBlob('mat_arrows', -1, pos);
			CBlob@ water = server_CreateBlob('mat_waterarrows', -1, pos);
			CBlob@ fire = server_CreateBlob('mat_firearrows', -1, pos);
			CBlob@ bomb = server_CreateBlob('mat_bombarrows', -1, pos);
		}
		else if (text_in == "!arrows") // 3 mats of 30 arrows (90 arrows)
		{
			for (int i = 0; i < 3; i++)
			{
				CBlob@ b = server_CreateBlob('mat_arrows', -1, pos);
			}
		}
		else if (text_in == "!allbombs") // 2 normal bombs, 1 water bomb
		{
			for (int i = 0; i < 2; i++)
			{
				CBlob@ bomb = server_CreateBlob('mat_bombs', -1, pos);
			}
			CBlob@ water = server_CreateBlob('mat_waterbombs', -1, pos);
		}
		else if (text_in == "!bombs") // 3 (unlit) bomb mats
		{
			for (int i = 0; i < 3; i++)
			{
				CBlob@ b = server_CreateBlob('mat_bombs', -1, pos);
			}
		}
		else if (text_in == "!spawnwater" && player.isMod())
		{
			getMap().server_setFloodWaterWorldspace(pos, true);
		}
		/*else if (text_in == "!drink") // removes 1 water tile roughly at the player's x, y, coordinates (I notice that it favors the bottom left of the player's sprite)
		{
			getMap().server_setFloodWaterWorldspace(pos, false);
		}*/
		else if (text_in == "!seed")
		{
			// crash prevention?
		}
		else if (text_in == "!crate")
		{
			client_AddToChat("usage: !crate BLOBNAME [DESCRIPTION]", SColor(255, 255, 0, 0)); //e.g., !crate shark Your Little Darling
			server_MakeCrate("", "", 0, team, Vec2f(pos.x, pos.y - 30.0f));
		}
		else if (text_in == "!coins") // adds 100 coins to the player's coins
		{
			player.server_setCoins(player.getCoins() + 100);
		}
		else if (text_in == "!coinoverload") // + 10000 coins
		{
			player.server_setCoins(player.getCoins() + 10000);
		}
		else if (text_in == "!fishyschool") // spawns 12 fishies
		{
			for (int i = 0; i < 12; i++)
			{
				CBlob@ b = server_CreateBlob('fishy', -1, pos);
			}
		}
		else if (text_in == "!chickenflock") // spawns 12 chickens
		{
			for (int i = 0; i < 12; i++)
			{
				CBlob@ b = server_CreateBlob('chicken', -1, pos);
			}
		}
		// removed/commented out since this can easily be abused...
		/*else if (text_in == "!sharkpit") // spawns 5 sharks, perfect for making shark pits
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ b = server_CreateBlob('shark', -1, pos);
			}
		}
		else if (text_in == "!bisonherd") // spawns 5 bisons
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ b = server_CreateBlob('bison', -1, pos);
			}
		}*/
		else if (text_in.substr(0, 1) == "!")
		{
			// check if we have tokens
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "!class")
				{
					CBlob@ b = server_CreateBlob(tokens[1], blob.getTeamNum(), blob.getPosition());
					if (b !is null) b.server_SetPlayer(player);
				}
				if (tokens[0] == "!hp")
				{
					getPlayer(0).getBlob().server_SetHealth(parseFloat(tokens[1]));
				}
				if (tokens[0] == "!mana")
				{
					CBlob@ b = getPlayer(0).getBlob();
					if (b !is null)
					{
						ManaInfo@ manaInfo;
						if (b.get("manaInfo", @manaInfo))
						{
							manaInfo.mana = parseInt(tokens[1]);
						}
						else
						{
							client_AddToChat("Mana info not found for " + b.getName(), SColor(255, 255, 0, 0));
						}
					}
				}
				if (tokens[0] == "!addtime")
				{
					getRules().set_u32("game_end_time", getRules().get_u32("game_end_time") + parseInt(tokens[1]));
				}
				//(see above for crate parsing example)
				if (tokens[0] == "!crate")
				{
					int frame = tokens[1] == "catapult" ? 1 : 0;
					string description = tokens.length > 2 ? tokens[2] : tokens[1];
					server_MakeCrate(tokens[1], description, frame, -1, Vec2f(pos.x, pos.y));
				}
				// eg. !team 2
				else if (tokens[0] == "!team")
				{
					// Picks team color from the TeamPalette.png (0 is blue, 1 is red, and so forth - if it runs out of colors, it uses the grey "neutral" color)
					int team = parseInt(tokens[1]);
					blob.server_setTeamNum(team);
					// We should consider if this should change the player team as well, or not.
				}
				else if (tokens[0] == "!scroll")
				{
					string s = tokens[1];
					for (uint i = 2; i < tokens.length; i++)
					{
						s += " " + tokens[i];
					}
					server_MakePredefinedScroll(pos, s);
				}

				return true;
			}

			// otherwise, try to spawn an actor with this name !actor
			string name = text_in.substr(1, text_in.size());

			if (server_CreateBlob(name, team, pos) is null)
			{
				client_AddToChat("blob " + text_in + " not found", SColor(255, 255, 0, 0));
			}
		}
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if(this.get_bool("awootism"))
	{
		text_out = awootismIfy(text_in);
	}
	if (text_in == "!debug" && !getNet().isServer())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob@[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob@ overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}

	return true;
}
