#include "Hitters.as"
#include "TeamColour.as";

#include "FireCommon.as"

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	//shape.SetStatic(true);
	//shape.UpdateStaticBody();
	this.set_u16("lifetime", 3);

	this.Tag("barrier");
	this.Tag("solidblob");
	this.Tag("counterable");
}

void onTick( CBlob@ this )
{
	if (this.getTickSinceCreated() < 1)
	{		
		this.getSprite().PlaySound("rock_hit3.ogg", 1.0f, 1.0f);	
		this.server_SetTimeToDie(this.get_u16("lifetime"));
		
		CShape@ shape = this.getShape();
		shape.SetStatic(true);
		
		CSprite@ sprite = this.getSprite();
		sprite.getConsts().accurateLighting = false;
		//sprite.setRenderStyle(RenderStyle::additive);
		sprite.SetZ(-50);
	}
	
	CMap@ map = this.getMap();
	Vec2f thisPos = this.getPosition();
		
	TileType overtile = map.getTile(thisPos).type;
	if(map.isTileSolid(overtile))
	{
		//this.Tag("mark_for_death");
	}
}

void onDie(CBlob@ this)
{
	//counterSpell( this );
	
	//shieldSparks(this.getPosition(), 30, this.getAngleDegrees(), this.getTeamNum()); //Change to rock sparks
	
	this.getSprite().PlaySound("rocks_explode2.ogg", 1.0f, 1.0f);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	//this.getSprite().PlaySound("/build_wood.ogg");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return ( !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& (friend is null
			|| friend.getTeamNum() != this.getTeamNum()
		)
	);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ b )
{
	return ( isEnemy( this, b ) || b.hasTag("player") );
}

Random _sprk_r(32432);
void shieldSparks(Vec2f pos, int amountPerFan, f32 orientation, int teamNum)
{
	if ( !getNet().isClient() )
		return;
	
	f32 fanAngle = 10.0f;
	for (int i = 0; i < amountPerFan; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(orientation - fanAngle/2.0f + _sprk_r.NextFloat()*fanAngle);
		
		SColor col = getTeamColor(teamNum);
		
        CParticle@ p = ParticlePixelUnlimited( pos, vel, col, true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(30);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.collides = false;
		p.Z = 510.0f;
    }
	for (int i = 0; i < amountPerFan; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(orientation + 180.0f - fanAngle/2.0f + _sprk_r.NextFloat()*fanAngle);
		
		SColor col = getTeamColor(teamNum);
		
        CParticle@ p = ParticlePixelUnlimited( pos, vel, col, false );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(30);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.97f;
		p.gravity = Vec2f(0,0);
		p.collides = false;
		p.Z = 510.0f;
    }
}
