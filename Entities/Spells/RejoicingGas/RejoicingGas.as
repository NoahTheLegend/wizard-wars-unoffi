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
	shape.getConsts().net_threshold_multiplier = 0.5f;

	this.set_bool("back", false);

	this.getSprite().SetRelativeZ(33.0f);
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	this.getSprite().setRenderStyle(RenderStyle::additive);
}

const u8 hitrate = 8;
void onTick(CBlob@ this)
{
	if (isServer())
	{
		CMap@ map = getMap();
		if (map !is null && getGameTime()%hitrate==0)
		{
			u8 hits = 0;
			CBlob@[] bs;
			map.getBlobsInRadius(this.getPosition(), this.getRadius()*2, @bs);

			u8 max_hits = this.exists("max_hits") ? this.get_u8("max_hits") : 1;
			for (u16 i = 0; i < bs.size(); i++)
			{
				CBlob@ b = bs[i];
				if (b is null) continue;
				if (isEnemy(this, b))
				{
					hits++;
					this.server_Hit(b, b.getPosition(), Vec2f_zero, this.get_f32("dmg"), Hitters::fall, true);
					this.server_Hit(this, this.getPosition(), Vec2f_zero, this.getInitialHealth()/max_hits, Hitters::fall, true);
					if (hits >= max_hits)
					{
						break;
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
	if (oldHealth > hp) return;

	f32 inithp = this.getInitialHealth();
	f32 damage = Maths::Abs(oldHealth-hp);

	f32 val = damage / inithp;
	this.getSprite().ScaleBy(Vec2f(val, val));
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