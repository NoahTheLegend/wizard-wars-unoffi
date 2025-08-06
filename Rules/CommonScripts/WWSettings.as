#include "MagicCommon.as";

void onInit(CRules@ this)
{
	#ifndef STAGING
	v_no_renderscale = true;
	#endif
	sv_visiblity_scale = 6.0f;

	this.addCommandID("shapeshift_gatherstats");
	this.addCommandID("shapeshift_swap");
	this.addCommandID("shapeshift_setstats");
}

bool[] server_buffered_ready;
u16[] server_buffered_ids;
f32[] server_buffered_health;
int[] server_buffered_mana;

void eraseBuffers()
{
	server_buffered_ready.erase(1);
	server_buffered_ids.erase(1);
	server_buffered_health.erase(1);
	server_buffered_mana.erase(1);
	
	server_buffered_ready.erase(0);
	server_buffered_ids.erase(0);
	server_buffered_health.erase(0);
	server_buffered_mana.erase(0);
}

void onTick(CRules@ this)
{
	if (!isServer()) return;

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

		target.server_SetPlayer(casterPlayer);
		caster.server_SetPlayer(targetPlayer);

		CBitStream params;
		params.write_u16(server_buffered_ids[0]);
		params.write_u16(server_buffered_ids[1]);
		params.write_f32(server_buffered_health[0]);
		params.write_f32(server_buffered_health[1]);
		params.write_s32(server_buffered_mana[0]);
		params.write_s32(server_buffered_mana[1]);
		this.SendCommand(this.getCommandID("shapeshift_swap"), params);
		print("4");

		eraseBuffers();
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shapeshift_setstats"))
	{
		if (!isServer()) return;
		print("2");

		u16 id = params.read_u16();
		f32 health = params.read_f32();
		s32 mana = params.read_s32();

		CBlob@ blob = getBlobByNetworkID(id);
		if (blob is null) return;
		print("3 "+blob.getName()+" "+blob.getNetworkID());

		server_buffered_ready.push_back(true);
		server_buffered_health.push_back(health);
		server_buffered_ids.push_back(blob.getNetworkID());
		server_buffered_mana.push_back(mana);
	}
	else if (cmd == this.getCommandID("shapeshift_gatherstats"))
	{
		bool from_client = params.read_bool();
		u16 thisID = params.read_u16();
		u16 blobID = params.read_u16();

		CBlob@ thisBlob = getBlobByNetworkID(thisID);
		CBlob@ blob = getBlobByNetworkID(blobID);

		if (!from_client && isClient()) // send mana
		{
			if (thisBlob !is null && blob !is null && (thisBlob.isMyPlayer() || blob.isMyPlayer()))
			{
				print("0 "+thisBlob.getName()+" "+blob.getName());
				if (getLocalPlayerBlob() is null) return; // just to make sure
				print("1");

				CBitStream params1;
				params1.write_bool(true);
				params1.write_u16(thisBlob.getNetworkID());
				params1.write_f32(thisBlob.getHealth());

				ManaInfo@ manaInfo;
				if (this.get("manaInfo", @manaInfo)) params1.write_s32(manaInfo.mana);
				else params1.write_s32(50);

				this.SendCommand(this.getCommandID("shapeshift_setstats"), params1);
			}
		}
	}
	else if (cmd == this.getCommandID("shapeshift_swap"))
	{
		if (!isClient()) return;
		print("5");
		
		u16 casterID = params.read_u16();
		u16 targetID = params.read_u16();

		f32 casterHealth = params.read_f32();
		f32 targetHealth = params.read_f32();

		s32 casterMana = params.read_s32();
		s32 targetMana = params.read_s32();

		CBlob@ caster = getBlobByNetworkID(casterID);
		CBlob@ target = getBlobByNetworkID(targetID);

		if (caster is null || target is null) return;
		print("6 "+caster.getName()+" "+target.getName());
		caster.getSprite().PlaySound("ObsessedSpellDie.ogg", 0.5f, 1.25f + XORRandom(15)*0.01f);
		target.getSprite().PlaySound("ObsessedSpellDie.ogg", 0.5f, 1.25f + XORRandom(15)*0.01f);

		caster.server_SetHealth(targetHealth);
		target.server_SetHealth(casterHealth);

		ManaInfo@ casterManaInfo;
		if (caster.get("manaInfo", @casterManaInfo))
		{
			casterManaInfo.mana = casterMana;
		}

		ManaInfo@ targetManaInfo;
		if (target.get("manaInfo", @targetManaInfo))
		{
			targetManaInfo.mana = targetMana;
		}
	}
}