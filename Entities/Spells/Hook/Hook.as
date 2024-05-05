#include "Hitters.as";
#include "ArcherCommon.as";
#include "TextureCreation.as";

const f32 arrowMediumSpeed = 8.0f;
const f32 arrowFastSpeed = 13.0f;
const f32 max_dist = 328.0f;

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = true;	 // we have our own map collision
	consts.bullet = true;
	consts.net_threshold_multiplier = 0.25f;
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("die_in_divine_shield");
	this.set_bool("following", false);
	this.set_u16("attached",0);
	shape.SetGravityScale(1.0f);

    //dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	Setup(SColor(175, 100, 175, 255), "hook0", false);
	Setup(SColor(175, 255, 125, 100), "hook1", false);

	if (this is null) return;
	if (isClient())
	{
    	int cb_id = Render::addBlobScript(Render::layer_prehud, this, "Hook.as", "laserEffects");
	}

    this.server_SetTimeToDie(2.5f);
}

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();

	if (this.hasTag("collided"))
		shape.SetGravityScale(0.0f);

	if (this.getDamageOwnerPlayer() !is null)
	{
		CBlob@ owner = this.getDamageOwnerPlayer().getBlob();
		if (owner !is null)
		{
			if (this.getDistanceTo(owner) > max_dist && !shape.isStatic())
			{
				this.Tag("return");
			}
			owner.set_u8("dashCoolDown", 2);
			owner.set_bool("dashing", true);
			owner.set_u32("teleport_disable", getGameTime()+2);

			if ((this.getTickSinceCreated() > 10 && this.hasTag("returning") && !shape.isStatic() && this.getDistanceTo(owner) <= 24.0f)
			|| (this.hasTag("collided_blob")
				&& this.getDistanceTo(owner) <= 24.0f) && !this.getShape().isStatic())
					this.server_Die();

			if (!this.hasTag("collided")) // return mode
			{
				if (!this.hasTag("return") && this.getVelocity().Length() > 0.5f)
				{
					if (this.getVelocity().Length() < 1.0f)
					{
						this.setVelocity(Vec2f_zero);
						this.Tag("return");
					}
					this.Tag("returning");

					this.setVelocity(this.getVelocity()*0.9f);

					Vec2f force = this.getPosition() - owner.getPosition();
					force.Normalize();
					this.AddForce(-force*12);
					shape.SetGravityScale(1.0f);
				}
				else // flying mode
				{
					this.Untag("return");
					shape.SetGravityScale(0.0f);
					Vec2f dir = (this.getPosition() - owner.getPosition());
					this.setVelocity(-dir/8);
				}
			}
			else
			{
				Vec2f tp = this.getPosition();
				Vec2f op = owner.getPosition();
				Vec2f force = (tp-op);

				this.setPosition(this.get_Vec2f("lock"));

				if (this.getDistanceTo(owner) < max_dist/1.25f)
				{
					if (owner.isKeyJustPressed(key_use))
					{
						this.server_Die();
						return;
					}
					else if (owner.isKeyPressed(key_down) && !owner.isKeyPressed(key_up))
					{
						force.y *= 0.5f;
					}

					if (owner.isKeyPressed(key_up) && op.y > tp.y)
					{
						force.y *= 1.75f;
					}
					else if (owner.getDistanceTo(this) < max_dist/2
						&& ((owner.isKeyPressed(key_left) && op.x < tp.x)
						|| (owner.isKeyPressed(key_right) && op.x > tp.x)))
					{
						force.x *= -0.33f;
					}
				}

				owner.AddForce(force/1.85f);
				//if (owner.getVelocity().y > 8.0f) owner.setVelocity(Vec2f(owner.getVelocity().x, owner.getVelocity().y*0.5f));
			}
		}
	}

    f32 angle;
	if (!this.hasTag("collided")) //we haven't hit anything yet!
	{
		//prevent leaving the map
		{
			Vec2f pos = this.getPosition();
			if (
				pos.x < 0.1f ||
				pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
			) {
				this.server_Die();
				return;
			}
		}
		if(this.hasTag("primed"))
		{
    	    angle = (this.getVelocity()).Angle();
			this.setAngleDegrees(-angle);
		}
		
		this.Sync("following", true);
		if(this.get_bool("following"))
		{
			u16 targetid = this.get_u16("attached"); //finds target ID
			CBlob@ target = getBlobByNetworkID(targetid);
			if(target !is null && !target.hasTag("dead"))
			{
				this.setVelocity(Vec2f_zero);
				this.setPosition(target.getPosition());
			}
			else
			{
				this.server_Die();
			}
		}
    }
}

void ArrowHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	if (velocity.Length() > arrowFastSpeed)
	{
		this.getSprite().PlaySound("ArrowHitGroundFast.ogg");
	}
	else
	{
		this.getSprite().PlaySound("ArrowHitGround.ogg");
	}

	f32 radius = this.getRadius();
	f32 angle = velocity.Angle();
	this.set_u8("angle", Maths::get256DegreesFrom360(angle));

	Vec2f lock = worldPoint;
	this.set_Vec2f("lock", lock);

	this.Sync("lock", true);
	this.Sync("angle", true);

	this.setVelocity(Vec2f(0, 0));
	this.setPosition(lock);
	//this.getShape().server_SetActive( false );

	this.Tag("collided");
	this.Untag("primed");

	if (this.getDamageOwnerPlayer() !is null)
	{
		CBlob@ owner = this.getDamageOwnerPlayer().getBlob();
		if (owner !is null)
		{
			owner.setVelocity(owner.getVelocity()+(this.getPosition()-owner.getPosition())/(18+XORRandom(3)));
			//if (owner.getVelocity().y > 8.0f) owner.setVelocity(Vec2f(owner.getVelocity().x, owner.getVelocity().y*0.5f));

			this.setVelocity(Vec2f_zero);
			this.getShape().SetStatic(true);
			this.getShape().SetGravityScale(0.0f);
			this.server_SetTimeToDie(10.0f);
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f p1, Vec2f p2)
{	
	float expundamage = this.get_f32("damage");
	if (solid && blob is null && !this.hasTag("collided_blob"))
	{
		ArrowHitMap(this, p2, Vec2f_zero, 0, 0);
	}

	if (blob !is null)
	{
		if (isEnemy(this, blob))
		{
			if (blob.hasTag("barrier"))
			{
				this.server_Die();
			}
			else if (!this.hasTag("collided_blob") && !this.getShape().isStatic())
			{
				this.Tag("collided_blob");
				this.Tag("return");

				if (this.getDamageOwnerPlayer() is null || this.getDamageOwnerPlayer().getBlob() is null) return;
				CBlob@ owner = this.getDamageOwnerPlayer().getBlob();

				blob.setVelocity((owner.getPosition()-blob.getPosition())/8);
				this.setVelocity(Vec2f_zero);

				blob.set_u8("dashCoolDown", 30);
				blob.set_bool("dashing", true);
				blob.set_u32("teleport_disable", getGameTime()+30);

				this.Tag("returning");
					
				owner.setVelocity((this.getPosition()-owner.getPosition())/16);
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


void laserEffects(CBlob@ this, int id)
{
    
	if (this.getDamageOwnerPlayer() is null || this.getDamageOwnerPlayer().getBlob() is null) return;
	CBlob@ owner = this.getDamageOwnerPlayer().getBlob();


	Vec2f thisPos = this.getPosition();
   	Vec2f ownerPos = Vec2f_lerp(owner.getOldPosition(), owner.getPosition(), getInterpolationFactor());
	f32 dist = (thisPos-ownerPos).Length();
	f32 size = 0.5f;

	Vec2f[] v_pos;
	Vec2f[] v_uv;

	v_pos.push_back(thisPos + Vec2f(0,   -size).RotateBy(-(ownerPos-thisPos).Angle())); v_uv.push_back(Vec2f(0,0)); //Top left?
	v_pos.push_back(thisPos + Vec2f(dist,-size).RotateBy(-(ownerPos-thisPos).Angle())); v_uv.push_back(Vec2f(1,0)); //Top right?
	v_pos.push_back(thisPos + Vec2f(dist, size).RotateBy(-(ownerPos-thisPos).Angle())); v_uv.push_back(Vec2f(1,1)); //Bottomright?
	v_pos.push_back(thisPos + Vec2f(0,    size).RotateBy(-(ownerPos-thisPos).Angle())); v_uv.push_back(Vec2f(0,1)); //Bottom left?

	Render::Quads("hook"+this.getTeamNum(), -50.0f, v_pos, v_uv);

	v_pos.clear();
	v_uv.clear();
}
