#include "Hitters.as";
#include "ArcherCommon.as";

void onInit(CBlob@ this)
{
	if (!this.exists("stage")) this.set_u8("stage", 0);

	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;
	consts.bullet = false;
	consts.net_threshold_multiplier = 1.0f;
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("die_in_divine_shield");
	shape.SetGravityScale( 0.0f );

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
	
	this.setAngleDegrees(90);

	this.addCommandID("sync_shard_params");
	this.getSprite().PlaySound("WizardShoot.ogg", 1.5f, 1.5f);
}

const f32 damp = 0.95f;
void onTick(CBlob@ this)
{
	if (isClient())
	{
		for(int i = 0; i < 5; i ++)
		{
			float randomPVel = XORRandom(10) / 25.0f;
			Vec2f particleVel = Vec2f( randomPVel ,0).RotateByDegrees(XORRandom(360));
			particleVel += this.getVelocity();

    		CParticle@ p = ParticlePixelUnlimited(this.getPosition()+Vec2f(0,XORRandom(32)-16).RotateBy(this.getAngleDegrees()-90), particleVel, SColor(255,255,255,0), true);
   			if(p !is null)
    		{
    		    p.collides = false;
    		    p.gravity = Vec2f_zero;
    		    p.bounce = 1;
    		    p.lighting = false;
    		    p.timeout = 30;
				p.damping = 0.95;
    		}
		}
	}
	if (this.hasTag("static")) return;
	this.setVelocity(this.getVelocity()*damp);

	if (this.getTickSinceCreated() == 0)
	{
		this.Sync("stage", true);
	}

	if (isServer()) // shatter into 2 other shards
	{
		u8 stage = this.get_u8("stage");
		if (stage == 0)
		{
			if (!this.getShape().isOverlappingTileSolid(true))
			{
				ShapeConsts@ consts = this.getShape().getConsts();
				consts.mapCollisions = true;
			}
		}
		else
		{
			ShapeConsts@ consts = this.getShape().getConsts();
			consts.mapCollisions = true;
		}
		
		if (stage < 5)
		{
			if (this.getTickSinceCreated() == (stage == 0 ? 75 : 30) && !this.getShape().isStatic())
			{
				CBlob@ lshard = server_CreateBlob("holystrike");
				CBlob@ rshard = server_CreateBlob("holystrike");
				if (lshard !is null && rshard !is null)
				{
					u32 shooTime = getGameTime();
					{
						lshard.set_f32("damage", this.get_f32("damage")*0.75f);
						lshard.set_u32("shooTime", shooTime);
						lshard.set_u16("lifetime", this.getTimeToDie());
						lshard.server_SetTimeToDie(this.getTimeToDie());

						lshard.server_setTeamNum(this.getTeamNum());
						lshard.setPosition(Vec2f(this.getPosition() + Vec2f(6.0f-(1.0f*this.get_u8("stage")),0).RotateBy(this.getAngleDegrees()-90)));

						lshard.SetDamageOwnerPlayer( this.getDamageOwnerPlayer() );
						lshard.getShape().SetGravityScale(0);
						lshard.getShape().SetAngleDegrees(this.getAngleDegrees()-22.5f);
						lshard.set_u8("stage", this.get_u8("stage")+1);
						lshard.Tag("sync");
					}
					{
						rshard.set_f32("damage", this.get_f32("damage")*0.75f);
						rshard.set_u32("shooTime", shooTime);
						rshard.set_u16("lifetime", this.getTimeToDie());
						rshard.server_SetTimeToDie(this.getTimeToDie());

						rshard.server_setTeamNum(this.getTeamNum());
						rshard.setPosition(Vec2f(this.getPosition() + Vec2f(-6.0f+(1.0f*this.get_u8("stage")),0).RotateBy(this.getAngleDegrees()-90)));

						rshard.SetDamageOwnerPlayer( this.getDamageOwnerPlayer() );
						rshard.getShape().SetGravityScale(0);
						rshard.getShape().SetAngleDegrees(this.getAngleDegrees()+22.5f);
						rshard.set_u8("stage", this.get_u8("stage")+1);
						rshard.Tag("sync");
					}

					this.Tag("mark_for_death");
				}
			}
		}
		else
		{
			if (this.getVelocity().Length() < 1.0f)
				this.Tag("mark_for_death");
		}
	}

    CShape@ shape = this.getShape();

	if (this.getTickSinceCreated() < 1)
	{
		this.server_SetTimeToDie(this.get_u16("lifetime"));
	}

	if (isClient())
	{
		if (this.get_u8("stage") > 0 && !this.hasTag("scaled"))
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.ScaleBy((Vec2f(1.0f, 1.0f) * (1.0f-0.15f*this.get_u8("stage"))));
				sprite.SetOffset(Vec2f(-2.0f*this.get_u8("stage"), 0));
				this.Tag("scaled");
			}
		}
	}

    f32 angle;
    bool processSticking = true;
	if (!this.hasTag("collided")) //we haven't hit anything yet!
	{
		//prevent leaving the map
		{
			Vec2f pos = this.getPosition();
			if (
				pos.x < 0.1f ||
				pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
			) {
				this.Tag("mark_for_death");
				return;
			}
		}
        angle = (this.getVelocity()).Angle();
		Pierce(this);   //Pierce call
    }

	//start of sword launch logic
	u32 shooTime = this.get_u32("shooTime"); 		//base for timer system
	u32 lTime = getGameTime();						//clock

	if (!this.hasTag("canStickNow"))
	{
		u32 fTime = shooTime + 14;
		if (lTime > fTime)  //timer system for collision with walls
		{
		this.Tag("canStickNow"); //stops
		}
	}

	if (!this.hasTag("cruiseMode"))
	{
		if (lTime > shooTime)  //timer system for roboteching
		{
			this.AddForce(Vec2f(0, this.getMass()*2 + (8*this.get_u8("stage"))).RotateBy(this.getAngleDegrees()-90));
			shape.SetStatic(false);
			this.Tag("cruiseMode"); //stops
		}
	}
}

void Pierce( CBlob@ this )
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = this.getPosition() + Vec2f(0,20);
	
	if (this.hasTag("canStickNow"))  //doesn't do raycasts until needed
	{
		if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
		{
			ArrowHitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
		}
	}
}

void ArrowHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	if(isClient())
	{
		this.getSprite().PlaySound("bling.ogg", 1.0f, 1.075f+(XORRandom(126)*0.001f));
	}
	this.Tag("static");
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{	
	if (isServer() && this.get_u8("stage") == 0 && this.getTickSinceCreated() < 30) return;
	if (solid) this.getShape().SetStatic(true);
	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			float expundamage = this.get_f32("damage");
			if (!blob.hasTag("barrier"))
			{
				if(!blob.hasTag("zombie"))
				{
					{this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage, Hitters::arrow, true);}
				}
				else
				{
					this.server_Hit(blob, blob.getPosition(), this.getVelocity(), 0.4, Hitters::arrow, true);
				}
				
			}
			else
			{
				this.server_Hit(blob, blob.getPosition(), this.getVelocity(), expundamage , Hitters::arrow, true);
				this.Tag("mark_for_death");
			}
		}
	}
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
				&& (friend is null
					|| friend.getTeamNum() != this.getTeamNum()
					)
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}