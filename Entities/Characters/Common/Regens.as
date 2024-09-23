#include "MagicCommon.as";
#include "PaladinCommon.as";

const u8 MIN_FOCUS_TIME = 5; //in seconds

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";

    if(isClient())
    {
        this.set_u16("focus", 0);
    }
    
    if (isServer())
    {
        int tn = this.getTeamNum();
        // give 200% of max health in 2v1
        uint team0 = 0;
        uint team1 = 0;
        f32 team0kdr = 0;
        f32 team1kdr = 0;
        uint teamUnspecified = 0;
        u8 pc = getPlayersCount();
        for (u32 i = 0; i < pc; i++)//Get amount of players on each team
        {
            CPlayer@ p = getPlayer(i);
            if (p is null) continue;

            int pn = p.getTeamNum();
            if (pn == 0) {team0++; team0kdr += getKDR(p);}
            else if (pn == 1) {team1++; team1kdr += getKDR(p);}
            else teamUnspecified++;
        }

        f32 avg_kdr_team0 = team0kdr / team0;
        f32 avg_kdr_team1 = team1kdr / team1;

        if ((tn == 0 && team0 == 1 && team1 >= 2 && avg_kdr_team0 < avg_kdr_team1)
            || (tn == 1 && team1 == 1 && team0 >= 2 && avg_kdr_team1 < avg_kdr_team0))
        {
            this.server_SetHealth(this.getInitialHealth() * 2);
        }
    }

    this.set_s32("mana regen rate", 3);
    
    this.set_bool("manatohealth", false); // avoid having null (random) value there on client
    this.set_bool("damagetomana", false);
    this.set_u16("manaburn", 0);
    this.set_u32("overload mana regen", 0);

    this.addCommandID("request_heal");
}

f32 getKDR(CPlayer@ p)
{
    return p.getKills() / Maths::Max(f32(p.getDeaths()), 1.0f);
}

void onTick(CBlob@ this)
{
    if(!isClient())
    {
        return;
    }

    ManaInfo@ manaInfo;
	if (!this.get( "manaInfo", @manaInfo )) 
	{
		return;
	}

    u8 ticksPerSecond = getTicksASecond();
    bool mana_burning = this.get_u16("manaburn") > 0;
    bool can_regenerate = !this.get_bool("manatohealth") && !this.get_bool("damagetomana") && !mana_burning;

    if (!this.hasTag("mana_calcs_done") && can_regenerate)
    {
        u8 manaRegenRate = manaInfo.manaRegen;//Default mana regen
        //adjusting mana regen rate based on team balance
        uint team0 = 0;
        uint team1 = 0;
        uint teamUnspecified = 0;
        for (u32 i = 0; i < getPlayersCount(); i++)//Get amount of players on each team
        {
            CPlayer@ p = getPlayer(i);
            if (p !is null)
            {
                switch(p.getTeamNum())
                {
                    case 0:
                    {
                        team0++;
                    }
                    break;

                    case 1:
                    {
                        team1++;
                    }
                    break;

                    case 3:
                    {
                        manaRegenRate *= 3;
                    }

                    default:
                    {
                        teamUnspecified++;
                    }
                    break;
                }
            }
        }
        
        if (team0 > 0 && team1 > 0)//If there is a player on either team
        {
            CPlayer@ thisPlayer = this.getPlayer();
            if ( thisPlayer !is null )
            {
                int thisPlayerTeamNum = thisPlayer.getTeamNum();//Get the players team
                
                if ( team0 < team1 && thisPlayerTeamNum == 0 )//if we are team 0 and there are more team members on the enemy team
                {
                    manaRegenRate *= (team1/team0);
                }
                else if ( team1 < team0 && thisPlayerTeamNum == 1 )//if we are team 1 and there are more team members on the enemy team
                {
                    manaRegenRate *= (team0/team1);
                }
            }
        }
        
        this.set_s32("mana regen rate", manaRegenRate);//Set the mana regen rate
        this.set_s32("OG_manaRegen", manaRegenRate); //Reminder for the original value
        this.Tag("mana_calcs_done");
    }

	if (getGameTime() % ticksPerSecond == 0)
	{
		ManaInfo@ manaInfo;
		if (!this.get( "manaInfo", @manaInfo )) 
		{
			return;
        }

        u8 adjustedManaRegenRate = this.get_s32("mana regen rate");

        if (this.get_bool("manatohealth") && !mana_burning)
        {
            if (this.isMyPlayer())
			{
				CBitStream params;
				params.write_f32((adjustedManaRegenRate*mana_to_health_ratio+health_per_regen)*0.1f);
				this.SendCommand(this.getCommandID("request_heal"), params);
			}
        }

        if (can_regenerate)
        {
		    //now regen mana
		    s32 mana = manaInfo.mana;
		    s32 maxMana = manaInfo.maxMana;
		    s32 maxtestmana = manaInfo.maxtestmana;

		    if (mana < maxMana && !this.get_bool("burnState"))
		    {
		    	if (maxMana - mana >= adjustedManaRegenRate)
		    		manaInfo.mana += adjustedManaRegenRate;
                else
                    manaInfo.mana = maxMana;
            }
        }
    }

    if( this is null || !this.hasTag("mana_calcs_done") )
    return;

    u8 ogRegen = this.get_s32("OG_manaRegen");
    bool extra = this.get_u32("overload mana regen") > getGameTime();

    if(this.getVelocity() == Vec2f_zero || extra)
    {
        if(this.get_u16("focus") > (ticksPerSecond * MIN_FOCUS_TIME) || extra)
        {
            if(ogRegen != 0)
            {
                this.set_s32("mana regen rate", ogRegen+1);
            }

            if(!this.hasTag("focused"))
            {
                this.Tag("focused");
            }
                
            Vec2f thisPos = this.getPosition();
            for (int i = 0; i < 3; i++)
            {
                Vec2f pixelPos = thisPos + Vec2f( XORRandom(26)-13,XORRandom(26)-13 );
                CParticle@ p = ParticlePixelUnlimited( pixelPos , Vec2f_zero , SColor( 255, 120+XORRandom(40), 0, 255) , true);
                if(p !is null)
                {
                    p.gravity = Vec2f(0,-0.3f);
                    p.timeout = XORRandom(7)+3;
                }
            }
        }
        else
        {
            this.set_u16("focus", this.get_u16("focus")+1);
        }
    }
    else
    {
        if(this.hasTag("focused"))
        {
            this.Untag("focused");
        }
        
        this.set_u16("focus", 0);
        this.set_s32("mana regen rate", ogRegen);
        return;
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("request_heal"))
	{
		if (isServer())
		{
			f32 amount;
			if (!params.saferead_f32(amount)) return;

			f32 hp = this.getHealth();
			f32 ihp = this.getInitialHealth();
			
			if (hp+amount > ihp)
				this.server_SetHealth(ihp);
			else
				this.server_SetHealth(hp+amount);
		}
	}
}