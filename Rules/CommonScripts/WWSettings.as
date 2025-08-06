#include "MagicCommon.as";
#include "PlayerPrefsCommon.as"

void onInit(CRules@ this)
{
	#ifndef STAGING
	v_no_renderscale = true;
	#endif
	sv_visiblity_scale = 6.0f;
}

bool[] server_buffered_ready;
u16[] server_buffered_ids;
f32[] server_buffered_health;
int[] server_buffered_mana;

void eraseBuffers()
{
	if (server_buffered_ready.size() > 1)
		server_buffered_ready.erase(1);
	if (server_buffered_ids.size() > 1)
		server_buffered_ids.erase(1);
	if (server_buffered_health.size() > 1)
		server_buffered_health.erase(1);
	if (server_buffered_mana.size() > 1)
		server_buffered_mana.erase(1);

	if (server_buffered_ready.size() > 0)
		server_buffered_ready.erase(0);
	if (server_buffered_ids.size() > 0)
		server_buffered_ids.erase(0);
	if (server_buffered_health.size() > 0)
		server_buffered_health.erase(0);
	if (server_buffered_mana.size() > 0)
		server_buffered_mana.erase(0);
}

const u32 timeout_time = 5 * 30;
void onTick(CRules@ this)
{
	if (!isServer()) return;

	if (this.get_u32("shapeshift_timeout") != 0 && this.get_u32("shapeshift_timeout") < getGameTime())
	{
		if (server_buffered_ready.size() < 2)
		{
			print("Shapeshift timeout reached, removing buffered data");
			eraseBuffers();
		}
		
		return;
	}

	if (server_buffered_ready.size() >= 2)
	{
		CBlob@ caster = getBlobByNetworkID(server_buffered_ids[0]);
		CBlob@ target = getBlobByNetworkID(server_buffered_ids[1]);

		if (caster is null || target is null)
		{
			eraseBuffers();

			print("Shapeshift failed: caster or target is null, removing buffered data");
			return;
		}

		CPlayer@ casterPlayer = caster.getPlayer();
		CPlayer@ targetPlayer = target.getPlayer();

		if (casterPlayer is null || targetPlayer is null)
		{
			eraseBuffers();

			print("Shapeshift failed: caster or target player is null, removing buffered data");
			return;
		}

		u8 targetTeam = target.getTeamNum();
		u8 casterTeam = caster.getTeamNum();

		targetPlayer.server_setTeamNum(casterTeam);
		casterPlayer.server_setTeamNum(targetTeam);

		target.server_SetPlayer(casterPlayer);
		caster.server_SetPlayer(targetPlayer);

		u16 currentTargetID = target.getNetworkID();
		u16 currentCasterID = caster.getNetworkID();

		int target_idx = server_buffered_ids.find(currentTargetID);
		int caster_idx = server_buffered_ids.find(currentCasterID);

		f32 realTargetHealth = server_buffered_health[target_idx];
		f32 realCasterHealth = server_buffered_health[caster_idx];
		s32 realTargetMana = server_buffered_mana[target_idx];
		s32 realCasterMana = server_buffered_mana[caster_idx];

		CBitStream params;
		params.write_u16(currentCasterID);
		params.write_u16(currentTargetID);
		params.write_f32(realCasterHealth);
		params.write_f32(realTargetHealth);
		params.write_s32(realCasterMana);
		params.write_s32(realTargetMana);
		this.SendCommand(this.getCommandID("shapeshift_swap"), params);

		eraseBuffers();
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shapeshift_setstats"))
	{
		if (!isServer()) return;

		u16 id;
		f32 health;
		s32 mana;

		if (!params.saferead_u16(id)) return;
		if (!params.saferead_f32(health)) return;
		if (!params.saferead_s32(mana)) return;

		CBlob@ blob = getBlobByNetworkID(id);
		if (blob is null) return;

		server_buffered_ready.push_back(true);
		server_buffered_health.push_back(health);
		server_buffered_ids.push_back(blob.getNetworkID());
		server_buffered_mana.push_back(mana);

		this.set_u32("shapeshift_timeout", getGameTime() + timeout_time);
	}
	else if (cmd == this.getCommandID("shapeshift_gatherstats"))
	{
		bool from_client;
		u16 thisID;
		u16 blobID;

		if (!params.saferead_bool(from_client)) return;
		if (!params.saferead_u16(thisID)) return;
		if (!params.saferead_u16(blobID)) return;

		CBlob@ thisBlob = getBlobByNetworkID(thisID);
		CBlob@ blob = getBlobByNetworkID(blobID);

		if (!from_client && isClient()) // send mana
		{
			if (thisBlob !is null && blob !is null && (thisBlob.isMyPlayer() || blob.isMyPlayer()))
			{
				CBlob@ subj = thisBlob.isMyPlayer() ? thisBlob : blob.isMyPlayer() ? blob : null;
				if (subj !is null)
				{
					CBitStream params1;
					params1.write_u16(subj.getNetworkID());
					params1.write_f32(subj.getHealth());

					ManaInfo@ manaInfo;
					if (subj.get("manaInfo", @manaInfo)) params1.write_s32(manaInfo.mana);
					else params1.write_s32(50);

					this.SendCommand(this.getCommandID("shapeshift_setstats"), params1);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("shapeshift_swap"))
	{
		u16 casterID, targetID;
		f32 casterHealth, targetHealth;
		s32 casterMana, targetMana;

		if (!params.saferead_u16(casterID)) return;
		if (!params.saferead_u16(targetID)) return;
		if (!params.saferead_f32(casterHealth)) return;
		if (!params.saferead_f32(targetHealth)) return;
		if (!params.saferead_s32(casterMana)) return;
		if (!params.saferead_s32(targetMana)) return;

		CBlob@ caster = getBlobByNetworkID(casterID);
		CBlob@ target = getBlobByNetworkID(targetID);

		if (caster is null || target is null) return;

		if (isClient())
		{
			caster.getSprite().PlaySound("ObsessedSpellDie.ogg", 0.5f, 1.25f + XORRandom(15)*0.01f);
			target.getSprite().PlaySound("ObsessedSpellDie.ogg", 0.5f, 1.25f + XORRandom(15)*0.01f);
		}

		if (isServer())
		{
			caster.server_SetHealth(targetHealth);
			target.server_SetHealth(casterHealth);
		}

		ManaInfo@ casterManaInfo;
		if (caster.get("manaInfo", @casterManaInfo))
		{
			casterManaInfo.mana = targetMana;
			print("setting our "+casterManaInfo.mana+" mana to "+targetMana);
		}

		ManaInfo@ targetManaInfo;
		if (target.get("manaInfo", @targetManaInfo))
		{
			targetManaInfo.mana = casterMana;
			print("setting our "+targetManaInfo.mana+" mana to "+casterMana);
		}

		// reset cooldowns
		CPlayer@ casterPlayer = caster.getPlayer();
		CPlayer@ targetPlayer = target.getPlayer();

		PlayerPrefsInfo@ playerPrefsInfoCaster;
		if (casterPlayer.get("playerPrefsInfo", @playerPrefsInfoCaster))
		{
			for (int i = 0; i < playerPrefsInfoCaster.spell_cooldowns.length; i++)
			{
				playerPrefsInfoCaster.spell_cooldowns[i] = 0;
			}
		}

		PlayerPrefsInfo@ playerPrefsInfoTarget;
		if (targetPlayer.get("playerPrefsInfo", @playerPrefsInfoTarget))
		{
			for (int i = 0; i < playerPrefsInfoTarget.spell_cooldowns.length; i++)
			{
				playerPrefsInfoTarget.spell_cooldowns[i] = 0;
			}
		}
	}
}