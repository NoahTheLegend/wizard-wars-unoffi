#include "SpellUtils.as";

const f32 radius = 8*10;

void onInit(CBlob@ this){
    this.addCommandID("heal_fx");
    this.Tag('counterable');
    this.Tag("projectile");
    this.getShape().SetGravityScale(0);
    this.set_f32("targetAngle",0);
    this.set_f32("heal_ammount",0.05);
    this.Tag("die_in_divine_shield");
    //this.set_netid("caster",0);
    if(!isServer()){return;}
    this.server_SetTimeToDie(5);

    this.set_u16("stunTimer", 0); //stun setup
}

void onTick(CBlob@ this){

    CBlob@[] blobs;
    getMap().getBlobsInRadius(this.getPosition(),radius,@blobs);

    CPlayer@ damageOwnerPlayer = this.getDamageOwnerPlayer();
    
    int index = closestBlobIndex(this,blobs,this.getDamageOwnerPlayer());
    if(index == -1) return;

    CBlob@ target = blobs[index];

    int stun = this.get_u16("stunTimer");
    int creaTicks = this.getTickSinceCreated();
    if(creaTicks >= 15 && creaTicks >= stun)//wait a bit before homing - don't home if stunned
    {
        Vec2f thisPos = this.getPosition();
        Vec2f targetPos = target.getPosition();
        Vec2f norm = targetPos - thisPos;
        norm.Normalize();

        Vec2f newVelocity = this.getVelocity() + norm;
        newVelocity.Normalize(); 
        this.setVelocity(newVelocity * 4);
    }

    if(this.getDistanceTo(target) <= 8.0f) //hit detection
    {
        if(target.getTeamNum() == this.getTeamNum())
        {
            f32 amo = this.get_f32("heal_amount");
            if (target.getPlayer() is this.getDamageOwnerPlayer())
                amo /= 2;
            
            //CBitStream params;
            //params.write_u16(target.getNetworkID());
            //params.write_f32(amo);
            //this.SendCommand(this.getCommandID("heal_fx"), params);

            Heal(this, target, amo, true, true, 0.2f);
            if (isServer())
            {
                this.Tag("dead");
                this.server_Die();
            }
        }
        else
        {
            float damage = 0.3f;
            if (target.getName() == "knight")
            {
                damage = 0.2f;
                if (target.hasTag("shielded"))
                {
                    if(isClient())
                    {this.getSprite().PlaySound("ShieldHit.ogg");}
                    damage = 0;
                }
            }
            this.server_Hit(target,this.getPosition(), Vec2f_zero,damage,41);
            this.server_Die();
        }
    }
}

void onTick(CSprite@ this){
    this.ResetTransform();
    this.RotateBy(this.getBlob().getVelocity().getAngle() * -1,Vec2f_zero);
}

int closestBlobIndex(CBlob@ this, CBlob@[] blobs, CPlayer@ caster)
{
    if (this.getTickSinceCreated() < 15) return -1;

    f32 bestDistance = 99999999;
    int bestIndex = -1;

    for(int i = 0; i < blobs.length; i++){
        if((this.getTeamNum() == blobs[i].getTeamNum() && blobs[i].getHealth() == blobs[i].getInitialHealth()) || blobs[i].getPlayer() is null){
            continue;
        }
        f32 dist = this.getDistanceTo(blobs[i]);
        if(bestDistance > dist)
        {
            bestDistance = dist;
            bestIndex = i;
        }
    }
    return bestIndex;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("heal_fx"))
    {
        if (this.hasTag("dead")) return;
        this.Tag("dead");

        if (!isClient()) return;
        if (isClient() && isServer()) return;

        u16 id = params.read_u16();
        f32 amo = params.read_f32();

        CBlob@ blob = getBlobByNetworkID(id);
        if (blob is null) return;

        Heal(this, blob, amo);
    }
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
    if (blob is null)
	{return;}

    if (blob.hasTag("barrier") || solid)
    {
        this.set_u16("stunTimer", this.getTickSinceCreated() + 15);
    }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(blob is null){return false;}

	if (blob.getShape() !is null && blob.getShape().isStatic())
	{
		if (blob.hasTag("door") && blob.isCollidable())
		{
			return true;
		}
		
		ShapePlatformDirection@ plat = blob.getShape().getPlatformDirection(0);
		if (plat !is null)
		{
			Vec2f pos = this.getPosition();
			Vec2f bpos = blob.getPosition();

			Vec2f dir = plat.direction;
			if ((dir.x > 0 && pos.x > bpos.x)
				|| (dir.x < 0 && pos.x < bpos.x)
				|| (dir.y > 0 && pos.y > bpos.y)
				|| (dir.y < 0 && pos.y < bpos.y))
			{
				return true;
			}
		}
	}

	return 
	(
		blob.getTeamNum() != this.getTeamNum()
		&& blob.hasTag("barrier")//collides with enemy barriers
	);
}

// Vec2f lerp(Vec2f start,Vec2f end, f32 percent){
//     Vec2f x = end - start;
//     x *= percent;
//     x += start;
//     return x;
// }