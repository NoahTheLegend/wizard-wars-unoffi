#include "MagicCommon.as";

float max_radius = 40.0f; // screenspace distance for logic and alpha
float max_distance = 9999.0f;

uint16[] blob_ids;
const Vec2f sc_pos = getDriver().getScreenCenterPos();

void onInit(CRules@ this)
{

}

void onRestart(CRules@ this)
{
	if (!this.hasCommandID("sync_mana")) this.addCommandID("sync_mana");
	if (!this.hasCommandID("callback_mana_request")) this.addCommandID("callback_mana_request");
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (isClient() && cmd == this.getCommandID("sync_mana"))
	{
		bool request = false;
		if (!params.saferead_bool(request)) return;
		u16 player_count = 0;
		if (!params.saferead_u16(player_count)) return;

		if (request) // send our mana
		{
			CBlob@ local = getLocalPlayerBlob();
			if (local is null) return;

			u16 local_id = local.getNetworkID();
			for (u8 i = 0; i < player_count; i++)
			{
				u16 id = 0;
				u16 mana = 0;
				if (!params.saferead_u16(id)) return;
				if (!params.saferead_u16(mana)) return;

				if (id == local_id)
				{
					ManaInfo@ manaInfo;
					if (!local.get("manaInfo", @manaInfo)) return;
					if (g_debug == 1) warn(this.getCommandID("sync_mana") + " [CL] Sending a callback to sync mana for server");

					CBitStream params1;
					params1.write_u16(id);
					params1.write_u16(manaInfo.mana);
					this.SendCommand(this.getCommandID("callback_mana_request"), params1);

					return;
				}
			}
		}
		else if (!request) // set mana for everyone on our client
		{
			for (u8 i = 0; i < player_count; i++)
			{
				u16 id = 0;
				u16 mana = 0;
				if (!params.saferead_u16(id)) return;
				if (!params.saferead_u16(mana)) return;

				CBlob@ blob = getBlobByNetworkID(id);
				if (blob !is null && !blob.isMyPlayer())
				{
					ManaInfo@ manaInfo;
					if (!blob.get("manaInfo", @manaInfo)) return;
					if (g_debug == 1) warn(this.getCommandID("sync_mana") + " [CL] Syncing mana for "+blob.getName()+" ("+id+") with "+mana+" mana");

					manaInfo.mana = mana;
				}
			}
		}
	}
	else if (isServer() && cmd == this.getCommandID("callback_mana_request"))
	{
		u16 id = 0;
		u16 mana = 0;
		if (!params.saferead_u16(id)) return;
		CBlob@ blob = getBlobByNetworkID(id);
		if (!params.saferead_u16(mana)) return;

		if (blob !is null)
		{
			ManaInfo@ manaInfo;
			if (!blob.get("manaInfo", @manaInfo)) return;

			manaInfo.mana = mana;
			if (g_debug == 1) warn(this.getCommandID("sync_mana") + " [SV] Received mana sync for "+blob.getName()+" ["+id+"] with "+manaInfo.mana+" mana");
		}
	}
}

const int mana_sync_period = 90;
void onTick(CRules@ this)
{
	if (isServer() && getGameTime() % mana_sync_period == 0)
	{
		CBlob@[] valid_players;
		for (u8 i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ player = getPlayer(i);
			if (player is null) continue;

			CBlob@ blob = player.getBlob();
			if (blob is null) continue;

			ManaInfo@ manaInfo;
			if (!blob.get("manaInfo", @manaInfo)) continue;

			valid_players.push_back(blob);
		}

		{
			// sync current mana to clients
			CBitStream params;
			params.write_bool(false);
			params.write_u16(valid_players.size());

			for (u8 i = 0; i < valid_players.size(); i++)
			{
				CBlob@ blob = valid_players[i];
				if (blob is null) return; // abort if valid_players suddenly has an invalid blob

				ManaInfo@ manaInfo;
				if (!blob.get("manaInfo", @manaInfo)) return;
				if (g_debug == 1) warn(this.getCommandID("sync_mana") + " [SV] Syncing mana to client "+blob.getPlayer().getUsername()+" with "+manaInfo.mana+" mana");

				params.write_u16(blob.getNetworkID());
				params.write_u16(manaInfo.mana);
			}
		}

		{
			// request next sync
			CBitStream params;
			params.write_bool(true);
			params.write_u16(valid_players.size());

			for (u8 i = 0; i < valid_players.size(); i++)
			{
				CBlob@ blob = valid_players[i];
				if (blob is null) return;

				ManaInfo@ manaInfo;
				if (!blob.get("manaInfo", @manaInfo)) return;
				if (g_debug == 1) warn(this.getCommandID("sync_mana") + " [SV] Requesting mana sync from client "+blob.getPlayer().getUsername()+" for mana sync");

				params.write_u16(blob.getNetworkID());
				params.write_u16(manaInfo.mana);
			}

			this.SendCommand(this.getCommandID("sync_mana"), params);
		}
	}

	if (!isClient()) return;

	if (g_videorecording)
		return;

	blob_ids.clear();
	CControls@ c = getControls();
	Vec2f mouse_pos = c.getMouseWorldPos();

	uint8 team = this.getSpectatorTeamNum();
	CBlob@ my_blob = getLocalPlayerBlob();
	if(my_blob !is null) // dont change team if we are dead, so that we can see everyone names
		team = my_blob.getTeamNum();

	f32 processed_dist = 8;
	CCamera@ camera = getCamera();
	if (camera !is null)
		processed_dist = 8*camera.targetDistance;

	CMap@ map = getMap();
	for (int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		CBlob@ blob = player.getBlob();
		
		if (blob is null || blob is my_blob)
			continue;

		//if (blob.getTeamNum() != team && team != this.getSpectatorTeamNum())
		//	continue;

		Vec2f bpos = blob.getPosition();
		if ((u_shownames && team == this.getSpectatorTeamNum() && (mouse_pos - bpos).Length() <= max_radius)
			|| (u_shownames && (mouse_pos - bpos).Length() <= max_radius && map.getColorLight(bpos).getLuminance() > 50
			&& (blob.getScreenPos()-sc_pos).Length()/processed_dist < max_distance))
		{
			blob_ids.push_back(blob.getNetworkID());
		}
	}
}

void onRender(CRules@ this)
{
	if (!isClient()) return;

	if (g_videorecording)
		return;
	
	CControls@ c = getControls();
	Vec2f mouse_screen_pos = c.getInterpMouseScreenPos();

	for (int i = 0; i < blob_ids.size(); i++)
	{
		CBlob@ blob = getBlobByNetworkID(blob_ids[i]);
		if(blob !is null) // you never know...
		{
			CPlayer@ player = blob.getPlayer();
			if (player !is null)
			{
				Vec2f center = blob.getPosition();
				Vec2f mouseWorld = getControls().getMouseWorldPos();
				const f32 renderRadius = (blob.getRadius()) * 4.0f;

				// Show health
				Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 20);
				Vec2f dim = Vec2f(24, 8);
				const f32 y = blob.getHeight() * 0.8f;

				const f32 initialHealth = blob.getInitialHealth();
				const f32 health = blob.getHealth();
				if (initialHealth > 0.0f)
				{
					const f32 perc = Maths::Clamp(health / initialHealth, 0.0f, 1.0f);
					if (perc >= 0.0f)
					{
						GUI::DrawRectangle(Vec2f(pos2d.x - dim.x, pos2d.y + y), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 6), SColor(100, 255, 255, 255));
						GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x, pos2d.y + y + dim.y + 4),
							SColor(150, (perc < 0.5f ? 255 : 255 - 255 * (perc - 0.5f) * 2), (perc < 0.5f ? 230 * perc * 2 : 230), 0));
						GUI::DrawTextCentered("" + Maths::Round(health * 10) + " / " + Maths::Round(initialHealth * 10), Vec2f(pos2d.x - dim.x + 22, pos2d.y + y + 5), SColor(255, 255, 255, 255));
					}
				}

				ManaInfo@ info;
				if (blob.get("manaInfo", @info))
				{
					CPlayer@ local = getLocalPlayer();
					if (local is null) break;
					
					// Show mana
					if (blob.getTeamNum() == local.getTeamNum() || local.getTeamNum() == getRules().getSpectatorTeamNum())
					{
						Vec2f pos2d = blob.getScreenPos() + Vec2f(0, 40);
						Vec2f dim = Vec2f(24, 8);
						const f32 y = blob.getHeight() * 0.8f;

						const f32 maxMana = info.maxMana;
						const f32 mana = info.mana;

						if (maxMana > 0.0f)
						{
							const f32 perc = mana / maxMana;
							if (perc >= 0.0f)
							{
								GUI::DrawRectangle(Vec2f(pos2d.x - dim.x, pos2d.y + y), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 6), SColor(100, 255, 255, 255));
								GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + perc * 2.0f * dim.x, pos2d.y + y + dim.y + 4),
									SColor(150, (perc < 0.5f ? 127 : 127 - 127 * (perc - 0.5f) * 2), 0, (perc < 0.5f ? 230 * perc * 2 : 230)));
								GUI::DrawTextCentered("" + Maths::Round(mana) + " / " + Maths::Round(maxMana), Vec2f(pos2d.x - dim.x + 22, pos2d.y + y + 5), SColor(255, 255, 255, 255));
							}
						}
					}
				}
			}
		}
	}
}