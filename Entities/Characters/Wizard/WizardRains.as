#include "WizardCommon.as";
#include "MagicCommon.as";

void SummonBlob(CBlob@ this, string name, Vec2f pos, int team)
{
    if (getNet().isServer())
	{
        CBlob@ summoned = server_CreateBlob( name, team, pos );
		if ( summoned !is null )
		{
			summoned.SetDamageOwnerPlayer( this.getPlayer() );
		}
	}
}

namespace WizardRainTypes
{
    enum type{
        finished = 0,
        zombieRain,
        meteorRain,
		meteorStrike,
        skeletonRain,
		arrowRain,
        smite
    }
}

class WizardRain
{
    u8 type;
    u8 level;
    Vec2f position;
    int team;

    uint time;
    uint objectsAmount;
    uint initobjectsAmount;

    WizardRain(CBlob@ blob, u8 i_type, u8 i_level, Vec2f pos)
    {
        type = i_type;
        level = i_level;
        position = pos;
        team = blob.getTeamNum();

        if (type == WizardRainTypes::zombieRain)
        {
            if (level == WizardParams::extra_ready)
                SummonBlob(blob, "zombieknight", position, team);
            objectsAmount = 5;
            if (level == WizardParams::extra_ready)
                objectsAmount += XORRandom(15);
            else if (level == WizardParams::cast_3)
                objectsAmount += XORRandom(10);
            else if (level == WizardParams::cast_2)
                objectsAmount += XORRandom(6);
            else if (level == WizardParams::cast_1)
                objectsAmount += XORRandom(3);
            time = 1 + XORRandom(6);
        }
        else if (type == WizardRainTypes::meteorRain)
        {
            objectsAmount = 9;
            if (level == WizardParams::extra_ready)
                objectsAmount += 6;
            
            time = 1 + XORRandom(5);
        }
        else if (type == WizardRainTypes::meteorStrike)
        {
            objectsAmount = 1;
            time = 1;
        }
        else if (type == WizardRainTypes::skeletonRain)
        {
            objectsAmount = 5;
            if (level == WizardParams::extra_ready)
                objectsAmount += XORRandom(15);
            else if (level == WizardParams::cast_3)
                objectsAmount += XORRandom(10);
            else if (level == WizardParams::cast_2)
                objectsAmount += XORRandom(6);
            else if (level == WizardParams::cast_1)
                objectsAmount += XORRandom(3);
            time = 1;
        }
        else if (type == WizardRainTypes::arrowRain)
        {
            objectsAmount = 75;
            if (level == WizardParams::extra_ready)
                objectsAmount += XORRandom(100);
            time = 1;
        }
        else if (type == WizardRainTypes::meteorRain)
        {
            objectsAmount = 3;
            if (level == WizardParams::extra_ready)
                objectsAmount += 1;
            time = 1;
        }
        else if (type == WizardRainTypes::smite)
        {
            objectsAmount = 6;
            if (level == WizardParams::extra_ready)
                objectsAmount += 2;
            time = 1;
        }

        initobjectsAmount = objectsAmount;
    }

    void Manage( CBlob@ this )
    {
        time -= 1;
        if (time <= 0)
        {
            if (type == WizardRainTypes::zombieRain)
            {
                string[] possibleZombies = {"skeleton", "zombie"};
                if (level >= WizardParams::cast_3)
                {
                    possibleZombies.insertLast("greg");
                    possibleZombies.insertLast("wraith");
                }
                SummonBlob(this, possibleZombies[XORRandom(possibleZombies.length)], position + Vec2f(XORRandom(80) - 40, XORRandom(80) - 40), team);

                time = 1 + XORRandom(6);
            }
            else if (type == WizardRainTypes::meteorRain)
            {
                for (u8 i = 0; i < 1 + XORRandom(3); i++)
                {
                    SummonBlob(this, "volcanoshard", Vec2f(position.x + XORRandom(128.0f) - 64.0f, 10.0f), team);
                }
                time = 1 + XORRandom(4);
            }
            else if (type == WizardRainTypes::meteorStrike)
            {
                CBlob@ blob = server_CreateBlob("meteor", team, Vec2f(position.x, 10.0f));
                if (blob !is null)
                {
                    blob.SetDamageOwnerPlayer(this.getPlayer());
                    if (level == 5)
                    {
                        blob.getShape().SetGravityScale(1.0f);
                    }
                }

                time = 1;
            }
            else if (type == WizardRainTypes::skeletonRain)
            {
                SummonBlob(this, "skeleton", position + Vec2f(XORRandom(80) - 40, XORRandom(80) - 40), team);
                time = 4;
            }
            else if (type == WizardRainTypes::arrowRain)
            {
				CBlob@ arrow = server_CreateBlobNoInit("arrow");
				if (arrow !is null)
				{
					arrow.set_u8("arrow type", XORRandom(4));
                    arrow.server_setTeamNum(team);
					arrow.setPosition( Vec2f(position.x + XORRandom(100) - 50, 0.0f) );
					arrow.Init();

					arrow.IgnoreCollisionWhileOverlapped(this);
					arrow.SetDamageOwnerPlayer(this.getPlayer());
					arrow.setVelocity(Vec2f(0.0f, 8.0f));
				}
                time = 1 + XORRandom(2);
            }
            else if (type == WizardRainTypes::smite)
            {
                f32 gap = 2; // mod
                int quantity = initobjectsAmount - objectsAmount + 1;
                for (u8 i = 0; i < quantity; i++)
                {
                    CBlob@ blob = server_CreateBlobNoInit("templarhammer");
                    if (blob !is null)
                    {
                        blob.set_bool("smite", true);
                        blob.server_setTeamNum(team);

                        f32 offsetX = (i % 2 == 0) ? i / 2 * (8 * gap) : -(i / 2 + 1) * (8 * gap);
                        if (quantity % 2 == 0) offsetX += 8;
                        f32 offsetY = Maths::Abs(position.x - (position.x + offsetX));
                        if (this.getTeamNum() == 1) offsetX += 4;
                        else offsetX -= 4;
                        blob.setPosition(Vec2f(position.x + offsetX, -64 + 8.0f * initobjectsAmount - offsetY));
                        
                        blob.Init();
                        blob.getShape().SetGravityScale(2.5f);
                        blob.setAngleDegrees(90);
                        blob.set_f32("damage", 1.5f);
                    }
                }

                time = 1;
            }
            objectsAmount -= 1;
            if (objectsAmount <= 0)
            {
                type = WizardRainTypes::finished;
            }
        }
    }

    bool CheckFinished()
    {
        return (type == WizardRainTypes::finished);
    }
}

void onInit(CBlob@ this)
{
    this.addCommandID("rain");

    WizardRain[] rains;
    this.set("wizardRains", rains);

    this.getCurrentScript().tickFrequency = getTicksASecond()/4;
    this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
    if (!getNet().isServer())
        return;

    WizardRain[]@ rains;
    if (!this.get("wizardRains", @rains)){
        return;
    }

    if (rains.length == 0)
        return;
    for (int i=rains.length-1; i>=0; i--)
    {
        if (rains[i].CheckFinished())
        {
            rains.removeAt(i);
        }
    }
    for (uint i=0; i<rains.length; i++)
        rains[i].Manage(this);
}

void addRain(CBlob@ this, string type, u8 level, Vec2f pos)
{
    WizardRain[]@ rains;
    if (!this.get("wizardRains", @rains)){
        return;
    }
    if (!getNet().isServer())
        return;
    if (type == "zombie_rain")
        rains.insertLast(WizardRain(this, WizardRainTypes::zombieRain, level, pos));
    else if(type == "meteor_rain")
        rains.insertLast(WizardRain(this, WizardRainTypes::meteorRain, level, pos));
    else if(type == "meteor_strike")
        rains.insertLast(WizardRain(this, WizardRainTypes::meteorStrike, level, pos));
    else if(type == "skeleton_rain")
        rains.insertLast(WizardRain(this, WizardRainTypes::skeletonRain, level, pos));
    else if(type == "arrow_rain")
        rains.insertLast(WizardRain(this, WizardRainTypes::arrowRain, level, pos));
    else if(type == "smite")
        rains.insertLast(WizardRain(this, WizardRainTypes::smite, level, pos));
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("rain"))
    {
        string type = params.read_string();
        u8 charge_state = params.read_u8();
        Vec2f aimpos = params.read_Vec2f();
        addRain(this, type, charge_state, aimpos);
    }
}

/*
void ManageRains( CBlob@ this )
{
    if (this.hasTag("ZombieRain"))
    {
        s32 time = this.get_s32("zombiesTimeSpawn") - 1;
        if (time <= 0 )
        {
            Vec2f pos = this.get_Vec2f("zombiesRainPos") + Vec2f(20.0f - XORRandom(40.0f), 20.0f - XORRandom(40.0f));
            string name = WizardParams::zombieTypes[XORRandom(WizardParams::zombieTypes.length)];
            SummonZombie(name, pos,  this.getTeamNum());
            u8 zombiesToSpawn = this.get_u8("zombiesToSpawn");
            this.set_u8("zombiesToSpawn", zombiesToSpawn - 1);
            time = 15 + XORRandom(90);
        }
        if (this.get_u8("zombiesToSpawn") <= 0)
            this.Untag("ZombieRain");
        this.set_s32("zombiesTimeSpawn", time);    
    }// zombie_rain
    if (this.hasTag("SkeletonRain"))
    {
        s32 time = this.get_s32("skeletonsTimeSpawn") - 1;
        if (time <= 0 )
        {
            if (!getNet().isServer())
                return;
            Vec2f pos = Vec2f(this.get_Vec2f("skeletonsRainPos").x + 20.0f - XORRandom(40.0f), 20.0f);
            server_CreateBlob( "skeleton", this.getTeamNum(), pos );
            u8 skeletonsToSpawn = this.get_u8("skeletonsToSpawn");
            this.set_u8("skeletonsToSpawn", skeletonsToSpawn - 1);
            this.set_s32("skeletonsTimeSpawn", 15 + XORRandom(90));
        }
        if (this.get_u8("skeletonsToSpawn") <= 0)
            this.Untag("SkeletonRain");
        this.set_s32("skeletonsTimeSpawn", time);     
    }// skeleton_rain
    if (this.hasTag("MeteorRain"))
    {
        s32 time = this.get_s32("meteorsTimeSpawn") - 1;
        if (time <= 0 )
        {
            if (!getNet().isServer())
                return;
            Vec2f pos = Vec2f(this.get_Vec2f("meteorsRainPos").x + 100.0f - XORRandom(200.0f), 20.0f);
            server_CreateBlob( "skeleton", this.getTeamNum(), pos );
            u8 meteorsToSpawn = this.get_u8("meteorsToSpawn");
            this.set_u8("meteorsToSpawn", meteorsToSpawn - 1);
            time = 15 + XORRandom(60);
        }
        if (this.get_u8("meteorsToSpawn") <= 0)
            this.Untag("MeteorRain");
        this.set_s32("meteorsTimeSpawn", time);     
    }// meteor_rain
}*/