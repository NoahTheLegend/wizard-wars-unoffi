#include "SpellUtils.as";

void onInit(CBlob@ this)
{
    this.addCommandID("heal_player");
    this.getSprite().SetRelativeZ(5.0f);
    this.Tag("projectile");

    this.set_u16("follow_id", 0);
    this.set_f32("dist", 99999);

    this.getSprite().setRenderStyle(RenderStyle::additive);
}

const f32 max_vel = 8.0f;
const f32 max_dist = 64.0f;
const f32 decel = 0.25f;

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();
    if (shape is null) return;

    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;

    u16 follow_id = this.get_u16("follow_id");
    CBlob@ b = getBlobByNetworkID(follow_id);
    if (follow_id == 0 || b is null || this.getDistanceTo(b) >= max_dist)
    {
        this.set_f32("dist", 99999);
        this.set_u16("follow_id", 0);

        shape.SetGravityScale(0.25f);
        shape.getConsts().mapCollisions = true;
        this.getSprite().SetRelativeZ(5.0f);

        if (this.isOnGround())
            this.server_Die();
    }

    if (b !is null)
    {
        Vec2f dir = (b.getPosition()-this.getPosition());
        dir.Normalize();
        if (this.getVelocity().Length() <= max_vel)
            this.AddForce(dir * (this.getMass() * decel));

        this.server_SetTimeToDie(5);
        
        shape.SetGravityScale(0.0f);
        shape.getConsts().mapCollisions = false;
        this.getSprite().SetRelativeZ(501.0f);
    }

    for (u8 i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ p = getPlayer(i);
        if (p is null) continue;

        CBlob@ b = p.getBlob();
        if (b is null) continue;
        
        f32 dist = this.get_f32("dist");
        f32 new_dist = this.getDistanceTo(b);
        if (new_dist < dist && new_dist < max_dist
            && !getMap().rayCastSolidNoBlobs(this.getPosition(), b.getPosition()))
        {
            this.set_f32("dist", new_dist);
            this.set_u16("follow_id", b.getNetworkID());
        }
    }

    string source = "heal_orb_trail.png";
    #ifdef STAGING
    source = "heal_orb_trail_staging.png";
    #endif
    
    if (!isClient()) return;
    {
        CParticle@ p = ParticleAnimated(source, this.getPosition(), Vec2f_zero, XORRandom(360), 1.0f, 2, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
	    	p.Z = -10.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("heal_player"))
    {
        if (this.hasTag("dead")) return;
        this.Tag("dead");

        if (!isClient()) return;
        u16 id = params.read_u16();

        CBlob@ blob = getBlobByNetworkID(id);
        if (blob is null) return;

        Heal(blob, 0.25f);
    }
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    if (blob !is null && blob.getNetworkID() == this.get_u16("follow_id"))
    {
        CBitStream params;
        params.write_u16(blob.getNetworkID());
        this.SendCommand(this.getCommandID("heal_player"), params);
        
        if (isServer())
        {
            Heal(blob, 0.25f);
            this.Tag("dead");
            this.server_Die();
        }
    }

    if (!isServer()) return;

    if (solid && blob is null)
        this.server_Die();
}