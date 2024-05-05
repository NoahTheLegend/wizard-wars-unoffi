#include "TeamColour.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	shape.getConsts().collidable = false;
	
	this.addCommandID("sync_id");
	this.set_u8("despelled", 0);
	this.Tag("counterable");

	//default values
	this.set_u16("lifetime", 15);
	//^
	this.set_u16("trapped_id", 0);
}

void onInit(CSprite@ this)
{
	this.PlayRandomSound("VineReveal", 3.0f, 1.1f);

	CSpriteLayer@ back = this.addSpriteLayer("bg", "VineTrapBack.png", 32, 16);
	if (back !is null)
	{
		Animation@ def = back.addAnimation("default", 6, false);
		if (def is null) return;
		int[] frames = {0,1,2,3,4};
		def.AddFrames(frames);
		
		back.SetAnimation(def);
		back.SetVisible(true);
		back.SetOffset(Vec2f(0,-8.0f));
	}
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();

	if(this.get_u8("despelled") >= 1 || this.get_s32("trap_time") > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }
	
	if (this.get_u16("trapped_id") > 0)
	{
		this.add_s32("trap_time", 1);
		
		CBlob@ trapped = getBlobByNetworkID(this.get_u16("trapped_id"));
		if (trapped !is null)
		{
			trapped.setPosition(this.getPosition()-Vec2f(0,7));
			trapped.setVelocity(Vec2f_zero);

			if (trapped.get_u16("slowed") < 15)
            {
                trapped.set_u16("slowed", 15);
                trapped.set_u16("heavy", 15);
            }
		}
		else this.set_u16("trapped_id", 0);

		return;
	}

	CBlob@[] chb;
	map.getBlobsAtPosition(this.getPosition()-Vec2f(12.0f, -8.0f), @chb);
	map.getBlobsAtPosition(this.getPosition()+Vec2f(0,     -8.0f), @chb);
	map.getBlobsAtPosition(this.getPosition()+Vec2f(-12.0f, -8.0f), @chb);

	for (u16 i = 0; i < chb.length; i++)
	{
		CBlob@ b = chb[i];
		if (b is null || !b.hasTag("player")) continue;
		if (isEnemy(this, b))
		{
			this.set_u16("trapped_id", b.getNetworkID());

			if (isServer())
			{
				CBitStream params;
				params.write_u16(b.getNetworkID());
				this.SendCommand(this.getCommandID("sync_id"), params);	
			}

			break;
		}
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

	//if (getGameTime() % 2 != 0) return;
	sparks(this.getPosition(), 1, this);
}

Random _sprk_r(1265);
void sparks(Vec2f pos, int amount, CBlob@ this)
{
	if (!getNet().isClient())
		return;

	CParticle@ p = ParticlePixelUnlimited(-getRandomVelocity(0,14,360) + pos, Vec2f(XORRandom(11)*0.1f-0.5f,-0.25f - XORRandom(6)*0.1f),SColor(255,65+XORRandom(65),175,0),
		true);
	if(p !is null)
	{
		p.fastcollision = true;
		p.gravity = Vec2f(0,0);
		p.bounce = 1;
		p.lighting = false;
		p.timeout = 15;
	}
}
