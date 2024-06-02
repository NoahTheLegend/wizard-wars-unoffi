#include "RunnerCommon.as";

const f32 jump_mod = 2.5f;

void onTick(CBlob@ this)
{
	if(this is null)
	{return;}

    CSprite@ sprite = this.getSprite();
    this.set_u32("teleport_disable", getGameTime()+3);

	if(!this.exists("pogoSetupDone") || !this.get_bool("pogoSetupDone"))
	{
		if (isClient())
		{
			sprite.AddScript("PogoStick.as");
            smoke(this.getPosition()-Vec2f(0,4), 25);
		}

		this.set_bool("pogoSetupDone",true);
        this.set_f32("lean", 90);
        this.set_u32("landed", 0);
        this.AddForce(Vec2f(0, -this.getMass()*jump_mod));
	}

    this.set_bool("disable_dash", true);
    RunnerMoveVars@ moveVars;
	if (this.get("moveVars", @moveVars))
	{
        moveVars.walkFactor = 0;
        moveVars.stoppingFactor = 0.25f;
    }

    if (this.hasScript("FallDamage.as"))
        this.RemoveScript("FallDamage.as");
    if (this.hasScript("FallSounds.as"))
        this.RemoveScript("FallSounds.as");

    const bool left = this.isKeyPressed(key_left);
    const bool right = this.isKeyPressed(key_right);
    f32 vellen = this.getVelocity().Length();
    f32 max_speed = moveVars.walkSpeedInAir*2.0f;

    f32 mod = (this.getVelocity().x > max_speed && !left) || (this.getVelocity().x < -max_speed && !right)
                ? 0.0f /* <-- change to 0 and get brain damage from --> */ : !this.isOnGround() ? moveVars.stoppingFactor : 0.0f;
    f32 lean = this.get_f32("lean");

    if (left && !right)
    {
        lean = Maths::Lerp(lean, 90-max_lean, 0.25f);
        this.AddForce(Vec2f(mod * -this.getMass(), 0));
    }
    else if (right && !left)
    {
        lean = Maths::Lerp(lean, 90+max_lean, 0.25f);
        this.AddForce(Vec2f(mod * this.getMass(), 0));
    }
    else
    {
        lean = Maths::Lerp(lean, 90, 0.25f);
    }
    this.set_f32("lean", lean);

    if (this.isOnWall())
    {
        this.set_u32("landed", 0);
    }
    else if (this.isKeyPressed(key_up) && this.getVelocity().y <= 0
        && this.get_u32("landed")+5 >= getGameTime())
    {
        this.AddForce(Vec2f(0, -this.getMass()));
    }

    f32 angle = lean - 90.0f;
    Vec2f offset = Vec2f(0, this.getRadius());

    sprite.ResetTransform();
    sprite.RotateBy(angle, offset);

    CSpriteLayer@ head = sprite.getSpriteLayer("head");
    if (head !is null)
    {
        head.ResetTransform();
        head.RotateBy(angle, offset-head.getOffset()/2);
    }

	if (this.hasTag("dead") || this.hasTag("pogo_remove")) 
	{
		cleanUp(this);
		return;
	}
}

const f32 max_lean = 30.0f;

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
    if (solid && (blob is null || this.doesCollideWithBlob(blob)))
    {
        f32 angle = -normal.Angle() + this.get_f32("lean")-90;
        Vec2f force = Vec2f(this.getMass(), 0).RotateBy(angle);
        if (this.isOnWall() || this.isOnCeiling())
            return;
        
        force.y *= Maths::Clamp((this.isKeyPressed(key_down) ? 0.5f : 1.0f) * this.getOldVelocity().y, jump_mod, jump_mod*2);
        this.AddForce(force);

        if (isClient())
            this.getSprite().PlaySound("PogoBounce", 0.5f, 1.35f + XORRandom(16)*0.01f);

        this.set_u32("landed", getGameTime());
    }
}

void cleanUp(CBlob@ this)
{
	if(this is null || this.getSprite() is null)
	{
		return;
	}

    if (isClient())
    {
        smoke(this.getPosition()-Vec2f(0,4), 25);

        CSprite@ sprite = this.getSprite();
        sprite.ResetTransform();

        CSpriteLayer@ head = sprite.getSpriteLayer("head");
        if (head !is null)
        {
            head.ResetTransform();
        }
    }

    this.set_bool("disable_dash", false);
    this.Untag("pogo_remove");

    this.AddScript("FallDamage.as");
    this.AddScript("FallSounds.as");

	this.set_bool("pogoSetupDone",false);
	this.set_bool("pogoSpriteSetupDone",false);
	this.RemoveScript("PogoStick.as");
}

Random _smoke_r(0x10001);
void smoke(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(3.0f + _smoke_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_smoke_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke2.png").getFirst(), 
									pos, 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.scale = 1.0f + _smoke_r.NextFloat()*0.5f;
        p.damping = 0.8f;
		p.Z = 200.0f;
		p.lighting = false;
        p.deadeffect = -1;
		p.setRenderStyle(RenderStyle::additive);
    }
}

bool isOwnerBlob(CBlob@ this, CBlob@ target)
{
	//easy check
	if (this.getDamageOwnerPlayer() is target.getPlayer())
	{
		return true;
	}
	return false;
}