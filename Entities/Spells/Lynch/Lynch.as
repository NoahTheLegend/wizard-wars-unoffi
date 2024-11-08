#include "TeamColour.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	shape.getConsts().collidable = false;
	
	this.addCommandID("sync_id");
	this.Tag("counterable");

	//default values
	if (!this.exists("lifetime")) this.set_u16("lifetime", 90);
	this.set_u16("trapped_id", 0);
	this.getShape().SetStatic(true);

    this.set_Vec2f("smashtoparticles_grav", Vec2f(0,0))
    this.set_Vec2f("smashtoparticles_grav_rnd", Vec2f(0, 1.0f));

    this.set_u8("state", 0);
}

void onInit(CSprite@ this)
{
    CSpriteLayer@ l = this.addSpriteLayer("l", "Lynch.png", 64, 64);
    if (l !is null)
    {
        l.setRenderStyle(RenderStyle::additive);
    }
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();

	if(this.get_s32("trap_time") > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }

    f32 dmg = this.get_f32("damage");
	
	if (this.get_u16("trapped_id") > 0)
	{
		this.Tag("cantparry");
		this.add_s32("trap_time", 1);
		
		CBlob@ trapped = getBlobByNetworkID(this.get_u16("trapped_id"));
		if (trapped !is null)
		{
            if (isServer() && trapped.getDistanceTo(this) > 32.0f)
            {
                this.set_u16("trapped_id", 0);
                SyncId(this, trapped.getNetworkID());

                this.server_Hit(trapped, trapped.getPosition(), Vec2f_zero, dmg, Hitters::fall, true);
                return;
            }

			trapped.setPosition(this.getPosition());
			trapped.setVelocity(Vec2f_zero);

            this.set_u8("state", 1);
		}
		else this.set_u16("trapped_id", 0);

		return;
	}

	if (!isServer()) return;
    u8 state = this.get_u8("state");
    u8 launch_delay = this.get_u8("launch_delay");

    if (state == 0)
    {
        this.set_u32("launch_time", getGameTime() + launch_delay);
	    CBlob@[] chb;
        map.getBlobsInRadius(this.getPosition(), this.getRadius() + 8.0f;, @chb);

        for (u16 i = 0; i < chb.length; i++)
	    {
	    	CBlob@ b = chb[i];
	    	if (b is null || !b.hasTag("player")) continue;
	    	if (isEnemy(this, b))
	    	{
	    		this.set_u16("trapped_id", b.getNetworkID());

	    		SyncId(this, b,getNetworkID());

	    		break;
	    	}
	    }
    }
    else if (state == 1)
    {
        u32 launch_time = this.get_u32("launch_time");
        u16[] swords;

        for (u8 i = 0; i < 4; i++)
        {
            Vec2f bpos =  this.getPosition() + Vec2f(64.0f, 0).RotateBy(i * 90);
            CBlob@ b = server_CreateBlob("executioner", this.getTeamNum(), bpos);
            if (b !is null)
            {
                Vec2f dir = b.getPosition() - this.getPosition();
                f32 angle = -dir.Angle();

                b.setAngleDegrees(angle);
                b.set_f32("damage", dmg);
                b.set_f32("lifetime", this.getTimeToDie());

                b.Tag("aimMode");
                b.set_Vec2f("lock", bpos);
                b.set_f32("angle", angle);

                b.getShape().mapCollisions = false;

                b.Tag("no_player_control");
                b.Sync("no_player_control", true);
                b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

                swords.push_back(b.getNetworkID());
            }
        }

        bool launch = launch_time <= getGameTime();
        CBlob@ trapped = getBlobByNetworkID(this.get_u16("trapped_id"));
		if (trapped is null && !launch)
		{
            this.set_u8("state", 0);
            state = 0;

            for (u8 i = 0; i < swords.size(); i++)
            {
                CBlob@ b = getBlobByNetworkID(swords[i]);
                if (b !is null)
                {
                    b.server_Die();
                }
            }
        }
        else // launch
        {
            for (u8 i = 0; i < swords.size(); i++)
            {
                CBlob@ b = getBlobByNetworkID(swords[i]);
                if (b !is null)
                {
                    b.Tag("cruiseMode");
                    b.Untag("aimMode");
                    b.setVelocity(Vec2f(0, -15.0f).RotateBy(b.getAngleDegrees()));
                }
            }
        }
    }
}

void SyncId(CBlob@ this, u16 id)
{
    if (isServer())
	{
		CBitStream params;
		params.write_u16(id);
		this.SendCommand(this.getCommandID("sync_id"), params);	
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().Gib();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (isClient() && cmd == this.getCommandID("sync_id"))
	{
		u16 id = params.read_u16();
		this.set_u16("trapped_id", id);
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return ( !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& (friend is null
			|| friend.getTeamNum() != this.getTeamNum()
		)
	);
}

void onTick(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;

    f32 factor = Maths::Sin(getGameTime() * 0.25f) * 4;
    factor = Maths::Clamp(factor + 1.0f, 0.0f, 1.0f);

    CSpriteLayer@ l = this.getSpriteLayer("l");
    if (l is null) return;
    
    f32 distortion = 10.0f;
    f32 val = distortion * factor;
    l.ResetTransform();
    l.SetOffset(Vec2f(XORRandom(val*10)*0.1f - val * 2, XORRandom(val*10)*0.1f - val * 2))
}