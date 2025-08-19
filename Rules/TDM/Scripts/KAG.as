#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"
#include "Hitters.as"

void onInit(CRules@ this)
{
	getNet().legacy_cmd = true;
	LoadDefaultMapLoaders();
	LoadDefaultGUI();

	sv_gravity = 9.81f;
	particles_gravity.y = 0.25f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	PrecacheTextures();

	//smooth shader
	Driver@ driver = getDriver();

	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", true);

	//reset var if you came from another gamemode that edits it
	SetGridMenusSize(24,2.0f,32);

	//also restart stuff
	onRestart(this);

	#ifndef STAGING
	if (s_gamemusic && s_musicvolume == 0)
		s_musicvolume = 0.5f;
	#endif
}

void ReselectSpell(CRules@ this)
{
	CPlayer@ p = getLocalPlayer();
	if (p is null) return;

	if (!this.exists("reset_spell_id")) return;
	if (this.get_u16("reset_spell_id") == 0) return;
	
	this.Tag("update_spell_selected");
}

bool need_sky_check = true;
void onRestart(CRules@ this)
{
	this.Tag("update_moss");

	ReselectSpell(this);

	//map borders
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetBorderFadeWidth(24.0f);
		map.SetBorderColourTop(SColor(0xff000000));
		map.SetBorderColourLeft(SColor(0xff000000));
		map.SetBorderColourRight(SColor(0xff000000));
		map.SetBorderColourBottom(SColor(0xff000000));

		//do it first tick so the map is definitely there
		//(it is on server, but not on client unfortunately)
		need_sky_check = true;
	}
}

void onTick(CRules@ this)
{
	if (this.hasTag("update_moss"))
	{
		this.Untag("update_moss");

		bool[][] captured_tiles;
		this.set("moss_captured_tiles", @captured_tiles);

		CMap@ map = getMap();
		if (map !is null)
		{
			captured_tiles.resize(map.tilemapwidth);
			for (u32 i = 0; i < captured_tiles.size(); i++)
			{
				captured_tiles[i].resize(map.tilemapheight);
			}
		}
	}

	if (isServer())
	{
		for (u8 i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p is null) continue;

			CBlob@ blob = p.getBlob();
			if (blob is null) continue;
			if (blob.hasTag("dead")) continue; //don't do this for dead players
			
			blob.server_Hit(blob, blob.getPosition(), Vec2f_zero, 0.0f, 255, true);
			//blob.server_SetHealth(blob.getHealth());
		}
	}

	//TODO: figure out a way to optimise so we don't need to keep running this hook
	if (need_sky_check)
	{
		need_sky_check = false;
		CMap@ map = getMap();
		//find out if there's any solid tiles in top row
		// if not - semitransparent sky
		// if yes - totally solid, looks buggy with "floating" tiles
		bool has_solid_tiles = false;
		for(int i = 0; i < map.tilemapwidth; i++) {
			if(map.isTileSolid(map.getTile(i))) {
				has_solid_tiles = true;
				break;
			}
		}
		map.SetBorderColourTop(SColor(has_solid_tiles ? 0xff000000 : 0x80000000));
	}
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, Emotes::dots, 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, Emotes::off);
}