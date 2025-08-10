#include "TeamColour.as";
#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("gas");
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	CShape@ shape = this.getShape();
	//shape.getConsts().net_threshold_multiplier = 2.0f;

	shape.SetGravityScale(0);
	shape.getConsts().net_threshold_multiplier = 1.5f;

	this.set_bool("back", false);

	this.getSprite().SetRelativeZ(33.0f);
	this.getSprite().setRenderStyle(RenderStyle::additive);
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	this.getSprite().setRenderStyle(RenderStyle::additive);
}

const u8 hitrate = 5;
void onTick(CBlob@ this)
{
	if (isServer())
	{
		if (this.getTickSinceCreated() < this.get_u8("ignore_time"))
			return;
			
		if (this.hasTag("dead")) return;
		CMap@ map = getMap();
		if (map !is null && (getGameTime()+this.getNetworkID())%hitrate==0)
		{
			CBlob@[] bs;
			map.getBlobsInRadius(this.getPosition(), this.getRadius()*2, @bs);

			for (u16 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null) continue;
				if (isEnemy(this, b))
				{
					this.server_Hit(b, b.getPosition(), Vec2f_zero, this.get_f32("dmg"), Hitters::fall, true);
					this.server_Hit(this, this.getPosition(), Vec2f_zero, this.getHealth()/this.get_s8("hits"), Hitters::fall, true);
					
					this.sub_s8("hits", 1);
					if (this.get_s8("hits") <= 0)
					{
						this.Tag("dead");
						this.Tag("mark_for_death");
						return;
					}
				}
			}
		}
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (!isClient()) return;

	f32 hp = this.getHealth();
	if (oldHealth < hp) return;
	this.getSprite().ScaleBy(Vec2f(0.9f, 0.9f));
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	if (this.getTickSinceCreated() < 2) return false;
	return 
	(
		(
			(target.hasTag("flesh")  || target.hasTag("zombie"))
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.hasTag("gas") || blob.hasTag("barrier");
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	ParticlesFromSprite(this.getSprite());
}