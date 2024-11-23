//Mana Obelisk code
#include "MagicCommon.as";

const s16 MAX_MANA = 80;
const s16 MANA_REGEN_RATE = 2;
const s16 MANA_GIVE_RATE = 12;
const u16 REGEN_COOLDOWN_SECS = 10;

void onInit( CBlob@ this )
{
	this.Tag("mana obelisk");
	this.getSprite().SetZ(-100.0f);
	
	this.getShape().SetStatic(true);
	
	this.set_s16("mana", MAX_MANA);
	this.set_s16("regen cooldown", 0);
	
	this.addCommandID("sync mana");
}

void onTick( CBlob@ this )
{
	int ticksPerSec = getTicksASecond();

	// regen mana of wizards touching
	if (getGameTime() % ticksPerSec == 0)
	{
		if (getNet().isServer())
		{
			SyncMana( this );
		}
		
		s16 currRegenCooldown = this.get_s16("regen cooldown");
		if ( currRegenCooldown > 0 )
			currRegenCooldown -= ticksPerSec;

		s16 storedMana = this.get_s16("mana");
		
		CBlob@[] ps_raw;
		getBlobsByTag("player", @ps_raw);

		CBlob@[] ps;
		for (uint i = 0; i < ps_raw.size(); i++)
		{
			CBlob@ b = ps_raw[i];
			if (b is null) continue;
			if (b.isOverlapping(this)) ps.push_back(b);
		}

		int amo = ps.size();
		if (amo > 0)
		{
			int mana_to_give = Maths::Min(MANA_GIVE_RATE, storedMana)/amo;
			if (storedMana >= MANA_GIVE_RATE)
			{
				bool was_sound = false;
				for (uint step = 0; step < amo; step++)
				{	
					CBlob@ touchBlob = ps[step];
					bool allowed_to_consume = touchBlob !is null && !touchBlob.hasTag("no_mana_pool")
						&& (touchBlob.getName() != "entropist" || !touchBlob.get_bool("burnState"))
						&& !touchBlob.get_bool("manatohealth");

					if (allowed_to_consume)
					{
						ManaInfo@ manaInfo;
						if (touchBlob.get("manaInfo", @manaInfo) && !touchBlob.hasTag("dead"))
						{
							s32 wizMana = manaInfo.mana;
							s32 wizMaxMana = manaInfo.maxMana;

							if ( storedMana >= mana_to_give && wizMana < (wizMaxMana-mana_to_give) )
							{
								storedMana -= mana_to_give;
								manaInfo.mana = wizMana + mana_to_give;

								if (!was_sound)
								{
									touchBlob.getSprite().PlaySound("ManaGain.ogg", 0.75f, 1.0f + XORRandom(2)/10.0f);
									was_sound = true;
								}
								
								if (storedMana < mana_to_give)
									touchBlob.getSprite().PlaySound("ManaEmpty.ogg", 0.5f, 1.0f + XORRandom(2)/10.0f);

								currRegenCooldown = REGEN_COOLDOWN_SECS*ticksPerSec;
							}
						}				
					}
				}
			}
		}
		
		if ( storedMana < MAX_MANA && currRegenCooldown <= 0 )
			storedMana += MANA_REGEN_RATE;
		
		if ( getNet().isServer() )		
			this.set_s16("mana", storedMana);	
		
		this.set_s16( "regen cooldown", Maths::Max(currRegenCooldown, 0) );
	}
}

void SyncMana( CBlob@ this )
{
	s16 mana = this.get_s16("mana");
	CBitStream bt;
	bt.write_s16( mana );	
	this.SendCommand( this.getCommandID("sync mana"), bt );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if( cmd == this.getCommandID("sync mana") )
    {
		if ( getNet().isServer() )
		{
			s16 mana;	
			mana = params.read_s16();	
			this.set_s16("mana", mana);
		}
		this.Sync("mana", true);
	}
}

void onTick( CSprite@ this )
{
	f32 storedMana = this.getBlob().get_s16("mana");
	//print("obelisk mana: " + storedMana);
	u16 numFrames = 9;
	
	f32 manaFraction = storedMana/MAX_MANA;
	u16 currentFrame = manaFraction*(numFrames-1);
	this.SetFrame(currentFrame);
}