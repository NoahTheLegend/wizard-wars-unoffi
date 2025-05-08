#include "Hitters.as"

const f32 duration = 15;
const f32 radius = 24.0f;
const f32 visible_radius = 56.0f;
const f32 damage = 0.5f;
const u8 delay = 3;

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",300);
    this.Tag("counterable");
    this.set_u32("boom_end", 0);

    this.addCommandID("sync");
}

void onTick(CBlob@ this)
{
    if(this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.Tag("mark_for_death");
    }

    if (this.get_u32("boom_end") != 0)
    {
        s32 diff = this.get_u32("boom_end")-getGameTime();
        if (diff == duration-1)
        {
            this.getSprite().PlaySound("dw_cast_sequence.ogg", 3.0f, 1.5f);
        }

        if (diff%delay==0)
        {
            if (isServer())
            {
                CBlob@[] list;
                getMap().getBlobsInRadius(this.getPosition(), radius, @list);

                for (u16 i = 0; i < list.length; i++)
                {
                    CBlob@ b = list[i];
                    if ((b.hasTag("player") || b.hasTag("zombie")) && b.getTeamNum() != this.getTeamNum())
                    {
                        this.server_Hit(b, b.getPosition(), (b.getPosition()-this.getPosition())/64, damage, Hitters::explosion, true);
                    }
                }
            }
            if (isClient())
            {
                makeBoomParticle(this, this.getPosition());
                this.getSprite().PlaySound("individual_boom.ogg", 3.0f, 0.85f);
            }
        }

        if (diff <= 0) this.Tag("mark_for_death");
    }
    
    if (!isClient()) return;
    CSprite@ sprite = this.getSprite();
    if (sprite is null) return;
    sprite.setRenderStyle(RenderStyle::additive);

    CPlayer@ local = getLocalPlayer();

    if (this.get_u32("boom_end") != 0)
    {
        sprite.SetVisible(true);
        return;
    }
    
    if (local !is null)
    {
        CBlob@ b = local.getBlob();

        if (b !is null) 
        {
            if (this.getTeamNum() == b.getTeamNum()) sprite.SetVisible(true);
            else if (this.getTeamNum() != b.getTeamNum() && this.getDistanceTo(b) > visible_radius) sprite.SetVisible(false);
            else sprite.SetVisible(true);
        }
        else // spectator team
        {
            if (this.getTeamNum() == local.getTeamNum()) sprite.SetVisible(true);
            else this.SetVisible(false);
        }
    }
}

void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

void onInit(CSprite@ this)
{
    this.ScaleBy(Vec2f(0.75,0.75));
    this.getBlob().set_s32("frame",0);
    this.SetOffset(Vec2f(0,-3));
    this.SetZ(-2.0f);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    if (isServer() && blob !is null && isEnemy(this, blob))
    {
        this.set_u32("boom_end", getGameTime()+duration);
        this.set_s32("aliveTime", getGameTime()+300);
        CBitStream params;
        params.write_u32(this.get_u32("boom_end"));
        this.SendCommand(this.getCommandID("sync"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync"))
    {
        if (isClient())
        {
            u32 boom_end;
            if (!params.saferead_u32(boom_end)) return;

            this.set_u32("boom_end", boom_end);
        }
    }
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return
	(	
		!target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum()
        && (target.hasTag("flesh") || target.hasTag("zombie"))
	);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

void makeElectricParticle( CBlob@ this , Vec2f pos )
{
	if (isClient())
	{
		CParticle@ p = ParticleAnimated( "caster_disruption.png", pos, Vec2f_zero, XORRandom(361), 0.8f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}
}

void makeBoomParticle( CBlob@ this , Vec2f pos )
{
	if (isClient())
	{
		CParticle@ p = ParticleAnimated( "small_boom.png", pos, Vec2f_zero, XORRandom(361), 1.0f, 1, 0.0f, true );
		if(p !is null)
		{
			p.Z = 1.0f;
			p.bounce = 0.0f;
    		p.fastcollision = true;
			p.gravity = Vec2f_zero;
		}
	}
}