#include "MagicCommon.as";

float max_radius = 40.0f; // screenspace distance for logic and alpha
float max_distance = 9999.0f;

uint16[] blob_ids;
const Vec2f sc_pos = getDriver().getScreenCenterPos();

void onInit(CRules@ this)
{
	this.addCommandID("sync_mana");
	this.addCommandID("callback_mana_request");
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
		bool request = params.read_bool();
		u16 player_count = params.read_u16();

		if (request) // send our mana
		{
			CBlob@ local = getLocalPlayerBlob();
			if (local is null) return;

			u16 local_id = local.getNetworkID();
			for (u8 i = 0; i < player_count; i++)
			{
				u16 id = params.read_u16();
				u16 mana = params.read_u16();

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
				u16 id = params.read_u16();
				u16 mana = params.read_u16();

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
		u16 id = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(id);
		u16 mana = params.read_u16();

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
				Vec2f draw_pos = blob.getInterpolatedPosition() + Vec2f(0.0f, blob.getRadius() * 1.5f);
				draw_pos = getDriver().getScreenPosFromWorldPos(draw_pos);

				// change alpha depending on distance between mouse and player
                float dist = Maths::Min(max_radius, (mouse_screen_pos - blob.getInterpolatedScreenPos()).Length());
				float alpha = Maths::Min(1.0f, 2.0f - (dist / max_radius)); // min 0.4, max 1

				// now draw nickname
				string name = player.getCharacterName();

				Vec2f text_dim;
				GUI::SetFont("menu");
				GUI::GetTextDimensions(name, text_dim);
				Vec2f text_dim_half = Vec2f(text_dim.x/2.0f, text_dim.y/2.0f);

				SColor text_color = SColor(255, 200, 200, 200);

				u8 teamnum = blob.getTeamNum();
				if (teamnum != 6) // violet is black here so keep the text white
					text_color = teamnum == 0 ? SColor(255, 115, 115, 255) : SColor(255, 225, 85, 85);
				
                text_color.setAlpha(255 * alpha);

				SColor rect_color = SColor(80 * alpha, 0, 0, 0);
                
				GUI::DrawRectangle(draw_pos - text_dim_half, draw_pos + text_dim_half + Vec2f(5.0f, 3.0f), rect_color);
				GUI::DrawText(name, draw_pos - text_dim_half, text_color);

				Vec2f padding = Vec2f(3, 0);
				Vec2f dim = Vec2f(48, 16) - padding;
				Vec2f hp_bar_pos = draw_pos + Vec2f(-dim.x/2, dim.y-2) + padding;
				f32 hp_ratio = Maths::Clamp(blob.getHealth()/blob.getInitialHealth(), 0.1f, 1.0f);
				u8 hp_alpha = text_color.getAlpha();

				//red
				if (hp_ratio < 1)
				{
					Vec2f hp_missing_tl = hp_bar_pos + dim * hp_ratio;
					hp_missing_tl.y = hp_bar_pos.y;
					
					GUI::DrawPane(hp_missing_tl - Vec2f(padding.x, 0), hp_bar_pos + dim, SColor(hp_alpha, 85, 55, 35));
				}

				//green
				Vec2f hp_br = hp_bar_pos + dim * hp_ratio;
				hp_br.y = hp_bar_pos.y + dim.y;
				Vec2f extra = Vec2f(2, 2);

				bool healblock = blob.get_u16("healblock") > 0;
				//GUI::DrawRectangle(hp_bar_pos + extra, hp_br - extra,
				//	healblock ? SColor(hp_alpha, 120, 120, 120) : SColor(hp_alpha, 34, 120, 14));

				GUI::DrawRectangle(hp_bar_pos + extra + Vec2f(1, 0), hp_br - extra,
					healblock ? SColor(hp_alpha, 155, 155, 155) : SColor(hp_alpha, 55, 190, 40));

				GUI::SetFont("default");
				GUI::DrawTextCentered(Maths::Floor(blob.getHealth() * 10) + "/" + Maths::Floor(blob.getInitialHealth() * 10), hp_bar_pos + Vec2f(dim.x/2, dim.y/2) - Vec2f(extra.x + 1.5f, extra.y), SColor(hp_alpha, 255, 255, 255));

				u8 local_team = 0;
				CBlob@ local_blob = getLocalPlayerBlob();
				if (local_blob !is null)
					local_team = local_blob.getTeamNum();

				ManaInfo@ manaInfo;
				if (blob.getTeamNum() == local_team && local_team != this.getSpectatorTeamNum() && blob.get("manaInfo", @manaInfo))
				{
					Vec2f mana_bar_pos = draw_pos + Vec2f(-dim.x / 2 + padding.x * 2, dim.y * 2 - 3);
					f32 mana_ratio = f32(manaInfo.mana) / f32(manaInfo.maxMana);
					u8 mana_alpha = text_color.getAlpha();

					Vec2f mana_dim = Vec2f(dim.x - padding.x - extra.x, 4); // height of mana bar is 4 px
					Vec2f mana_br = mana_bar_pos + mana_dim * mana_ratio;
					mana_br.y = mana_bar_pos.y + mana_dim.y;

					SColor col = SColor(255, 163, 66, 178); // mana bar color

					// background
					GUI::DrawRectangle(mana_bar_pos - Vec2f(0, 1), mana_bar_pos + mana_dim, SColor(255, 42, 11, 71));

					// foreground
					GUI::DrawRectangle(mana_bar_pos + Vec2f(1, 1), mana_br - Vec2f(1, 1), col);
				}
			}
		}
	}
}