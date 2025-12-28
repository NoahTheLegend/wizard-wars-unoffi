#include "Hitters.as";	   
#include "/Entities/Common/Attacks/LimitedAttacks.as";

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("phase through spells");

	this.addCommandID("shoot_sfx");
	
	this.getShape().SetGravityScale(0.0f);
	this.server_SetTimeToDie(12);
	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 155, 155, 255));
	
	CSprite@ thisSprite = this.getSprite();
	thisSprite.ScaleBy(Vec2f(0.5f,0.5f));
	CSpriteLayer@ l = thisSprite.addSpriteLayer("l", "BallLightning.png", 54, 54);
	if (l !is null)
	{
		l.ScaleBy(Vec2f(0.5f,0.5f));
		thisSprite.RotateBy(XORRandom(360), Vec2f_zero);

		Animation@ anim = l.addAnimation("default", 0, false);
		if (anim !is null)
		{
			int[] frames = {0,1,2,3};
			anim.AddFrames(frames);
			
			l.RotateBy(XORRandom(360), Vec2f_zero);
			l.SetAnimation(anim);
			l.setRenderStyle(RenderStyle::additive);
		}
	}
	thisSprite.SetZ(525.0f);
	//thisSprite.setRenderStyle(RenderStyle::additive);

	thisSprite.SetEmitSound("BallLightningHum.ogg");
	thisSprite.SetEmitSoundSpeed(0.5f);
	thisSprite.SetEmitSoundVolume(0.25f);
	thisSprite.SetEmitSoundPaused(false);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ l = this.getSpriteLayer("l");
	if (l !is null)
	{
		this.RotateBy(-3, Vec2f_zero);
		l.RotateBy(3,  Vec2f_zero);
		l.animation.frame = this.animation.frame;
	}
}

const f32 radius = 112.0f;

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 1)
		this.getSprite().PlaySound("BallLightningCreate.ogg", 0.8f, 0.9f+XORRandom(16)*0.01f);

	if (isServer() && this.get_u32("next_shot") < getGameTime())
	{
		u16[] ids;
		for (u8 i = 0; i < this.get_u8("max_lightnings"); i++)
		{
			u16 id;
			f32 closest = 999.0f;
			CBlob@[] list;

			f32 chain_radius = radius;
			getMap().getBlobsInRadius(this.getPosition(), chain_radius, @list);

			for (u16 i = 0; i < list.length; i++)
			{
				CBlob@ l = list[i];
				if (l is null) continue;
				if (ids.find(l.getNetworkID()) != -1) continue;

				if (!l.hasTag("flesh") || l.hasTag("dead") || l.getTeamNum() == this.getTeamNum())
					continue;

				if (l.get_u32("strike_by_lightning") > getGameTime()
					|| getMap().rayCastSolidNoBlobs(this.getPosition(), l.getPosition()))
						continue;

				f32 dist = (l.getPosition() - this.getPosition()).Length();
				if (dist < closest)
				{
					id = l.getNetworkID();
					closest = dist;
				}
			}

			CBlob@ t = getBlobByNetworkID(id);
			if (t !is null)
			{
				ids.push_back(id);

				CBlob@ orb = server_CreateBlob("chainlightning", this.getTeamNum(), this.getPosition()); 
				if (orb !is null)
				{
					orb.set_f32("damage", this.get_f32("damage"));

					orb.set_u8("targets", 0);
					orb.set_Vec2f("aim pos", t.getPosition() + t.getVelocity());

					orb.Tag("secondary");

					orb.IgnoreCollisionWhileOverlapped(this);
					orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
				}
			}
		}

		if (ids.size() > 0)
		{
			this.set_u32("next_shot", getGameTime()+this.get_u8("cooldown"));

			CBitStream params;
			this.SendCommand(this.getCommandID("shoot_sfx"), params);
		}
	}

	sparks(this.getPosition() + this.getVelocity() * 4, 1, this);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null && solid)
	{
		this.getSprite().PlaySound("lightning"+(1+XORRandom(2))+".ogg", 0.4f, 1.33f + XORRandom(16)*0.01f);
		this.getSprite().PlaySound("BallLightningBounce.ogg", 0.4, 0.75f + XORRandom(16)*0.01f);
	}
	
	sparks(this.getPosition(), 5, this);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shoot_sfx"))
	{
		if (!isClient()) return;

		this.getSprite().PlaySound("BallLightningShoot.ogg", 0.75f, 0.75f);
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("lightning"+(1+XORRandom(2))+".ogg", 0.75f, 0.8f + XORRandom(16)*0.01f);
	sparks(this.getPosition(), 30, this);
	blast(this.getPosition(), 1, 0.5f);
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount, f32 scale = 1.0f)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel = Vec2f_zero;

        CParticle@ p = ParticleAnimated(CFileMatcher("Implosion3.png").getFirst(), 
									pos, 
									vel, 
									0, 
									scale, 
									4, 
									0.0f, 
									false);
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = true;
        p.setRenderStyle(RenderStyle::additive);
    }
}

Random _sprk_r(1265);
void sparks(Vec2f pos, int amount, CBlob@ this)
{
	if (!getNet().isClient())
		return;

	CParticle@[] particleList;
	this.get("ParticleList",particleList);

	for(int a = 0; a < 2; a++)
	{	
		CParticle@ p = ParticleAnimated("ElectricBlob.png", this.getPosition() + Vec2f(8 + XORRandom(16), 0).RotateBy(XORRandom(360)), Vec2f(0,0), XORRandom(360), 1.0f, 1, 0.5f, true);
		if(p !is null)
		{
			p.fastcollision = true;
			p.gravity = Vec2f(0,0);
			p.bounce = 1;
			p.lighting = false;
			p.timeout = 90;
			p.setRenderStyle(RenderStyle::additive);
			p.Z = 1.03f;


			particleList.push_back(p);
		}
	}
	for(int a = 0; a < particleList.length(); a++)
	{
		CParticle@ particle = particleList[a];
		//check
		if(particle.timeout < 1 || particle.Z != 1.03f)
		{
			particleList.erase(a);
			a--;
			continue;
		}

		//Gravity
		Vec2f tempGrav = Vec2f(0,0);
		tempGrav.x = -(particle.position.x - pos.x);
		tempGrav.y = -(particle.position.y - pos.y);
		particle.gravity = tempGrav / 10;//tweak the 20 till your heart is content

		//particleList[a] = @particle;

	}
	this.set("ParticleList",particleList);
}