#include "Hitters.as";

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");
    this.SetLightRadius(effectRadius);
    this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);
    this.getSprite().setRenderStyle(RenderStyle::additive);
    this.server_SetTimeToDie(999);
}

const int effectRadius = 8*10;

void onTick(CBlob@ this)
{
    if (isServer())
    {
        if (this.getTickSinceCreated() <= 2) this.server_SetTimeToDie(this.get_s32("aliveTime")/30);
        if (this.getTimeToDie() <= 1.0f)
        {
            this.server_SetTimeToDie(999);
            this.Tag("dying");
            this.server_SetHealth(0.5f);
        }
    }
    
    Vec2f pos = this.getInterpolatedPosition();
    CMap@ map = getMap();
    CBlob@[] blobs;
    
    map.getBlobsInRadius(pos,effectRadius,@blobs);
    if (this.getHealth() > 1.0f)
    {
        for(float i = 0; i < blobs.length; i++)
        {
            CBlob@ b = blobs[i];
            if (b is null || b is this) continue;
            if (b.exists("sidewinding") && b.get_u16("sidewinding") > 0) continue;
            if((b.getName() != "skeleton" && b.getName() != "zombie" && b.getName() != "zombieknight")
            && (b.getTeamNum() == this.getTeamNum() && b.hasTag("flesh"))) // friendly blobs
            {
                Vec2f tpos = this.getPosition();
                Vec2f bpos = b.getPosition();
                
                b.set_u32("divine_protection", getGameTime()+5);
            }
            else if (b.hasTag("flesh") || b.hasTag("magic_circle")) // push other outside
            {
                Vec2f tpos = this.getPosition();
                Vec2f bpos = b.getPosition();
                if (b.hasTag("magic_circle")) b.AddForce((bpos-tpos).Length() < 64.0f ? (bpos-tpos)*10 : bpos-tpos);
                else 
                {
                    b.setVelocity(Vec2f(0,0));
                    b.AddForce((bpos-tpos).Length() < 64.0f ? (bpos-tpos)*10 : bpos-tpos);
                }
            }
            else // rotate and change teamnum of incoming projectiles
            {
                if (b.getTeamNum() != this.getTeamNum() && (b.hasTag("projectile") || b.hasTag("die_in_divine_shield")))
                {
                    if (b.getShape() !is null)
                    {
                        Vec2f tpos = this.getPosition();
                        Vec2f bpos = b.getPosition();
                        Vec2f vec = bpos-tpos;
                        vec.Normalize();
                        vec *= effectRadius*1.15f;
                        f32 hitangle = -(tpos-bpos).Angle();

                        if (b.hasTag("projectile") && b.getName() != "arrow")
                        {
                            if (isServer())
                            {
                                f32 dmg;
                                dmg = (!b.exists("explosive_damage") || b.get_f32("damage") >= b.get_f32("explosive_damage")) ? b.get_f32("damage") * 0.5 : b.get_f32("explosive_damage") * 0.33f;
                                b.server_setTeamNum(this.getTeamNum());
                                b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
                                if (b.getName()=="bunker_buster") dmg *= 2.0f;
                                else if (b.getName() == "force_of_nature") this.server_SetTimeToDie(1.0f);
                                this.server_Hit(this, this.getPosition(), this.getVelocity(), dmg, Hitters::arrow, true);
                            }
                            if (isClient())
                            {
                                sparks(tpos, vec, hitangle);
                            }
                        }
                        if (b.hasTag("die_in_divine_shield") || b.getName() == "arrow")
                        {
                            if (isServer())
                            {
                                b.server_Die();
                            }
                            if (isClient())
                            {
                                sparks(tpos, vec, hitangle);
                            }
                        }
                        //b.getShape().SetAngleDegrees(b.getAngleDegrees()+180-(XORRandom(21)-10));
                        f32 vellen = b.getVelocity().Length();
                        b.setVelocity(Vec2f(-vellen, 0).RotateBy(hitangle)); // todo: calculate normal through b.angledegrees() and reflect in correct way
                        this.getSprite().PlaySound("shield_create.ogg", 1.0f, 2.0f+XORRandom(10)*0.1f);
                    }
                }
            }
        }
    }
    else if (this.getHealth() <= 1.0f)
    {
        if (!this.hasTag("soundplayed"))
        {
            this.Tag("soundplayed");
            this.getSprite().PlaySound("circle_create.ogg", 1.0f, 1.75f);
        }
        if(getGameTime()%30==0)
        {
            if (isServer())
            {
                this.server_SetHealth(this.getHealth()-0.25f);
                if (this.getHealth() <= 0.00f) this.server_Die();
            }
        }
        this.getSprite().RotateByDegrees((this.hasTag("fullCharge") ? rotateSpeed*2 : rotateSpeed) * (2-2*this.getHealth()) ,Vec2f(0,0));
        this.getSprite().ScaleBy(Vec2f(0.9f,0.9f));
    }
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    f32 damage_mod = f32(this.getTickSinceCreated())/this.get_s32("aliveTime");
    damage *= damage_mod;

    if (this.hasTag("dying")) return 0;
    if (isServer() && this.getHealth() - damage <= 1.0f)
    {
        this.Tag("dying");
        this.server_SetHealth(1.0f);
        return damage;
    }
    return damage;
}

const float rotateSpeed = 1;

void onInit(CSprite@ this)
{
    this.ScaleBy(Vec2f(1.4,1.4));
    //this.SetZ(0);
    //this.setRenderStyle(RenderStyle::light);
    //this.ReloadSprites(this.getBlob().getTeamNum(),0);
    this.PlaySound("circle_create.ogg", 1.0f, 2.5f);
    this.SetRelativeZ(888.0f);
}

void onTick(CSprite@ this)
{
    bool reverse = this.getBlob().hasTag("reverse");
    CBlob@ b = this.getBlob();
    {
        this.RotateByDegrees((b.hasTag("fullCharge") ? rotateSpeed*2 : rotateSpeed) / 4 ,Vec2f(0,0));
    }
    
}

void onDie(CBlob@ this)
{

}

Random _sprk_r(21342);
void sparks(Vec2f pos, Vec2f offset, f32 angle)
{
	for (int i = 0; i < 20; i++)
    {
        Vec2f ppos = pos + offset + Vec2f(1.0f * _sprk_r.NextRanged(3), 0).RotateBy(XORRandom(360));
        Vec2f vel = (ppos-(pos+offset)) * 0.1f + Vec2f(-1,0).RotateBy(angle);

        CParticle@ p = ParticlePixelUnlimited(ppos, vel, SColor( 255, 255, 200+_sprk_r.NextRanged(55), _sprk_r.NextRanged(128)), true);
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.gravity = Vec2f_zero;
        p.timeout = 30 + _sprk_r.NextRanged(20);
        p.damping = 0.975f;
    }
}