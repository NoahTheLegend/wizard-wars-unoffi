#include "Hitters.as";
#include "SpellUtils.as";

const f32 damage = 1.0f;
const u16 fear_time = 150;
const u16 explosion_radius = 40.0f;
const f32 revive_time = 3.0f;

void onInit(CBlob@ this)
{
    this.Tag("projectile");
    this.Tag("counterable");
	this.Tag("phase through spells");
    this.Tag("cantmove");
    this.Tag("cantparry");
	this.Tag("no trampoline collision");

    this.getShape().getConsts().mapCollisions = false;
    this.SetMapEdgeFlags(CBlob::map_collide_none | CBlob::map_collide_nodeath);

    this.server_SetTimeToDie(revive_time);
    this.getSprite().PlaySound("BookSpawn.ogg", 1.0f, 1.0f);
}

void onTick(CBlob@ this)
{
    if (!isServer()) return;

    if (this.hasTag("mark_for_death") && !this.hasTag("counterspelled"))
    {
        Boom(this);
        this.Tag("counterspelled");

        return;
    }

    u16 follow_id = this.get_u16("follow_id");
    if (follow_id == 0)
    {
        Boom(this);
        this.Tag("mark_for_death");
        this.Tag("counterspelled");

        return;
    }

    CBlob@ follower = getBlobByNetworkID(follow_id);
    if (follower is null)
    {
        Boom(this);
        this.Tag("mark_for_death");
        this.Tag("counterspelled");
        
        return;
    }

    this.setPosition(Vec2f_lerp(this.getPosition(), follower.getPosition() - Vec2f(0, 32), 0.25f));
}

void onDie(CBlob@ this)
{
    if (isServer() && !this.hasTag("counterspelled"))
    {
        CBlob@ gravestone = getBlobByNetworkID(this.get_u16("follow_id"));
        if (gravestone !is null)
        {
            DemonicPact(this, gravestone);
        }
    }

    if (!isClient()) return;

    this.getSprite().PlaySound("BookSpawn.ogg", 1.0f, 1.0f);
    this.getSprite().PlaySound("GenericExplosion1.ogg", 1.0f, 1.0f + XORRandom(11) * 0.01f);
}

void Boom(CBlob@ this)
{
	makeSmokeParticle(this);
	if (!isServer()) return;

	CBlob@[] bs;
	getMap().getBlobsInRadius(this.getPosition(), explosion_radius, @bs);

	CPlayer@ owner = this.getDamageOwnerPlayer();
	CBlob@ hitter = owner !is null && owner.getBlob() !is null ? owner.getBlob() : null;

	for (int i = 0; i < bs.length; i++)
	{
		CBlob@ blob = bs[i];
		if (blob !is null && ((hitter !is null && blob is hitter) || isEnemy(this, blob)))
		{
			Vec2f dir = blob.getPosition() - this.getPosition();
			f32 dir_len = dir.Length();

			dir.Normalize();
			dir *= explosion_radius * 2 - dir_len;
			
			this.server_Hit(blob, this.getPosition(), dir, damage, Hitters::explosion, true);
			Fear(blob, fear_time);
		}
	}
}

void makeSmokeParticle(CBlob@ this, const Vec2f vel = Vec2f_zero, const string filename = "Smoke")
{
	const f32 rad = 2.0f;
	Vec2f random = Vec2f(XORRandom(128)-64, XORRandom(128)-64) * 0.015625f * rad;
	{
		CParticle@ p = ParticleAnimated("GenericBlast5.png", 
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
			p.colour = SColor(255, 255+XORRandom(25), 155 + XORRandom(100), 55+XORRandom(25));
			p.forcecolor = p.colour = SColor(255, 255+XORRandom(25), 155 + XORRandom(100), 55+XORRandom(25));
			p.setRenderStyle(RenderStyle::additive);
			p.Z = 1.5f;
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