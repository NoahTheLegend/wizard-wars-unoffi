#include "Hitters.as";
#include "HittersWW.as";
#include "TextureCreation.as";

void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("kill other spells");
	this.Tag("counterable");
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().getConsts().bullet = true;
	
	CSprite@ thisSprite = this.getSprite();
	CSpriteLayer@ l = thisSprite.addSpriteLayer("l", "ShadowBurstOrb.png", 24, 16);
	if (l !is null)
	{
		l.ScaleBy(Vec2f(0.95f, 0.95f));

		Animation@ anim = l.addAnimation("default", 0, false);
		if (anim !is null)
		{
			int[] frames = {0,1,2,1,0};
			anim.AddFrames(frames);
			
			l.SetAnimation(anim);
			l.setRenderStyle(RenderStyle::additive);
			l.SetRelativeZ(1.0f);
		}
	}

	this.getShape().SetGravityScale(0.0f);

	if (!isClient()) return;

	Vec2f frameSize = Vec2f(64, 48);
	this.getSprite().SetVisible(false);

	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "sb_rend0", false, false, Vec2f(0, 0), frameSize);
	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "sb_rend1", false, false, Vec2f(32, 0), frameSize);
	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "sb_rend2", false, false, Vec2f(64, 0), frameSize);
	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "sb_rend3", false, false, Vec2f(32, 0), frameSize);

	int cb_id = Render::addBlobScript(Render::layer_prehud, this, "PlagueBlob.as", "laserEffects");
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ l = this.getSpriteLayer("l");
	if (l !is null)
	{
		l.animation.frame = this.animation.frame;
	}
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 0)
	{
		CSprite@ sprite = this.getSprite();
		sprite.PlaySound("PoisonSurge"+XORRandom(3)+".ogg", 1.5f, 1.2f + XORRandom(11) * 0.01f);
		sprite.SetZ(-1.0f);
		sprite.SetRelativeZ(-1.0f);
	}

	if (!isClient()) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	if (getGameTime() % 1 == 0 && this.getTickSinceCreated() > 3)
    {
        CParticle@ p = ParticleAnimated("ShadowBurstOrb.png", this.getPosition(), Vec2f_zero, this.getAngleDegrees(), 1.0f, 5, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
			p.fastcollision = true;
			p.timeout = 30;
            p.growth = -0.05f;
	    	p.Z = -1.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
    }
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	return 
	(
		(target.getTeamNum() != this.getTeamNum() && (target.hasTag("kill other spells") || target.hasTag("door")
		|| target.getName() == "trap_block") || (target.hasTag("barrier") && target.getTeamNum() != this.getTeamNum()))
		||
		(
			target.hasTag("flesh") 
			&& !target.hasTag("dead") 
			&& target.getTeamNum() != this.getTeamNum() 
		)
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
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
	
	return (isEnemy(this, blob));
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f p1)
{
	if (solid || (blob !is null && blob.hasTag("kill poison spells")))
	{
		this.Tag("mark_for_death");
	}
	
	if (blob !is null && doesCollideWithBlob(this, blob))
	{
		this.Tag("mark_for_death");
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("CardDie.ogg", 1.0f, 0.65f+XORRandom(11) * 0.01f);
	Boom(this);
	sparks(this.getPosition(), 50);
}

void Boom(CBlob@ this)
{
	makeSmokeParticle(this);
	if (!isServer()) return;
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel = Vec2f_zero, const string filename = "WhitePuff")
{
	const f32 rad = 2.0f;
	Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64) * 0.015625f * rad;
	{
		CParticle@ p = ParticleAnimated(XORRandom(2) == 0 ? filename + ".png" : filename + "2.png", 
										this.getPosition(), 
										vel, 
										float(XORRandom(360)), 
										1.0f + XORRandom(50) * 0.01f,
										5, 
										0.0f, 
										false);

		if (p !is null)
		{
			p.bounce = 0;
    		p.fastcollision = true;
			p.colour = SColor(255, 255, 55+XORRandom(25), 180+XORRandom(75));
			p.forcecolor = SColor(255, 255, 55+XORRandom(25), 180+XORRandom(75));
			p.setRenderStyle(RenderStyle::additive);
			p.Z = 1.5f;
		}
	}
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

		u8 rnd = XORRandom(100);
		SColor col = SColor(255, 200+XORRandom(55), 55+rnd, 155+rnd);
        CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
        if (p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
		p.forcecolor = col;
        p.damping = 0.95f;
		p.gravity = Vec2f_zero;
		p.setRenderStyle(RenderStyle::additive);
    }
}

const string[] anim_loop = {
	"sb_rend0",
	"sb_rend1",
	"sb_rend2",
    "sb_rend3"
};
const u8 anim_time = 2;

void laserEffects(CBlob@ this, int id)
{
    int ts = this.getTickSinceCreated();
    string rendname = anim_loop[ts / anim_time % anim_loop.length];
    f32 z = 100.0f;

    Vec2f[] v_pos;
    Vec2f[] v_uv;
    SColor[] v_col;

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-16, -16));
    v_uv.push_back(Vec2f(0, 0));
    v_col.push_back(SColor(255, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(16, -16));
    v_uv.push_back(Vec2f(1, 0));
    v_col.push_back(SColor(255, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(16, 16));
    v_uv.push_back(Vec2f(1, 1));
    v_col.push_back(SColor(255, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-16, 16));
    v_uv.push_back(Vec2f(0, 1));
    v_col.push_back(SColor(255, 255, 255, 255));

    Render::QuadsColored(rendname, z, v_pos, v_uv, v_col);
}