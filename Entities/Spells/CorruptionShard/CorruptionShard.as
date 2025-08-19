#include "MagicCommon.as";
#include "SplashWater.as";
#include "SpellUtils.as";

const f32 y_offset = 0.0f;
void onInit(CBlob@ this)
{
    this.set_s32("aliveTime", 1500);

    this.Tag("totem");
    this.Tag("counterable");
    this.Tag("cantmove");

    this.Tag("phase through spells");
    this.Tag("no trampoline collision");
    this.Tag("alt_state");

    this.set_u32("alt_counter", 0);
    this.set_Vec2f("smashtoparticles_grav", Vec2f(0, -0.035f));
    this.set_Vec2f("smashtoparticles_grav_rnd", Vec2f(0.035f, -0.035f));
    
    this.getShape().SetStatic(true);
    this.addCommandID("restore_caster");
    this.addCommandID("sfx");

    this.SetFacingLeft(XORRandom(2) == 0);
}

void onTick(CBlob@ this)
{
    if (this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.Tag("mark_for_death");
    }

    if (this.getTickSinceCreated() == 0)
    {
        this.getSprite().PlaySound("CorruptionShardSpawn.ogg", 0.75f, 1.0f + XORRandom(11) * 0.01f);
    }

    if (isServer())
    {
        CBlob@[] bs;
        getBlobsByTag("player", @bs);

        f32 maxRange = this.get_f32("max_range");
        u16 debuffTime = this.get_u16("debuff_time");

        if (getGameTime() > this.get_u32("alt_counter"))
        {
            if (this.hasTag("alt_state"))
                this.Untag("alt_state");
            else
                this.Tag("alt_state");

            this.Sync("alt_state", true);
            this.set_u32("alt_counter", getGameTime() + this.get_u32("alt_delay"));

            for (u16 i = 0; i < bs.length; i++)
            {
                CBlob@ b = bs[i];

                if (this.getDistanceTo(b) > maxRange || b.getTeamNum() == this.getTeamNum())
                    continue;

                if (this.hasTag("alt_state"))
                {
                    Fear(b, debuffTime);
                }
                else
                {
                    Poison(b, debuffTime);
                }
            }

            CBitStream params;
            this.SendCommand(this.getCommandID("sfx"), params);
        }
    }

    if (isClient())
    {
        CSprite@ sprite = this.getSprite();
        float waveOffset = (Maths::Sin(this.getTickSinceCreated()* 0.1f) * 2.0f) + y_offset;

        if (sprite.animation.frame == 2)
            sparks(this, this.getPosition() + Vec2f(0.0f, waveOffset), 20, Vec2f(0.0f, 0.0f), this.hasTag("alt_state"));

        sprite.SetOffset(Vec2f(0, waveOffset));
    }
}

void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return false;
}

Random _sprk_r(21342);
void sparks(CBlob@ this, Vec2f pos, int amount, Vec2f gravity, bool alt_state = false)
{
	if (!getNet().isClient())
		return;

    u8 step = 3 + XORRandom(3);
    u8 angle = XORRandom(360);

    u8 rnd = XORRandom(50);
    SColor col = !alt_state ? SColor(255, 200 + XORRandom(55), 80 + XORRandom(120), XORRandom(55)) : SColor(255, XORRandom(75) + rnd, 200 + rnd, 55 + rnd + XORRandom(10));

	for (int i = 0; i < amount; i++)
    {
        if (i % step == 0)
            angle = XORRandom(360);

        u8 cur_step = Maths::Floor(i / step);
        Vec2f offset = Vec2f(4 + XORRandom(12) + i % step, 0).RotateBy(angle);

        Vec2f vel(angle % 5 + 1.0f, 0);
        vel.RotateBy(angle);

        CParticle@ p = ParticlePixelUnlimited(pos + offset, vel, col, true);
        if (p is null) return;

        p.fastcollision = true;
        p.gravity = gravity + Vec2f(0.0f, 0.01f);
        p.timeout = 20 + _sprk_r.NextRanged(15);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }

    // sparks by radius
    f32 max_range = this.get_f32("max_range");
    u8 quantity = 25;

    Vec2f thisPos = this.getPosition();
    for (u8 i = 0; i < quantity; i++)
    {
        Vec2f ppos = thisPos + Vec2f(max_range, 0).RotateBy((360.0f/quantity) * i);
        Vec2f dir = thisPos - ppos;

        dir.Normalize();
        dir *= 2.0f + XORRandom(21) * 0.1f;

        CParticle@ p = ParticlePixelUnlimited(ppos, dir, col, true);
        if (p is null) return;

        p.fastcollision = true;
        p.gravity = gravity + Vec2f(0.0f, 0.00f);
        p.timeout = 20 + XORRandom(10);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sfx"))
    {
        if (isClient())
        {
            this.getSprite().PlaySound("CorruptionShardPeriod.ogg", 0.75f, 0.85f + XORRandom(11) * 0.01f);
        }
    }
	else if (cmd == this.getCommandID("restore_caster"))
	{
		u16 id = params.read_u16();

		CBlob@ b = getBlobByNetworkID(id);
		if (b is null) return;

		ManaInfo@ manaInfo;
		if (b.get("manaInfo", @manaInfo))
        {
			if (manaInfo.mana < manaInfo.maxMana)
            {
				manaInfo.mana = Maths::Min(manaInfo.mana + this.get_s32("mana_amount"), manaInfo.maxMana);
			}
		}

        Heal(this, b, this.get_f32("heal_amount"), true, false);
        if (b.getSprite() !is null) b.getSprite().PlaySound("mana_smooth", 0.75f, 0.75f + XORRandom(11) * 0.01f);
	}
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("PlagueBlobDie.ogg", 1.0f, 0.75f + XORRandom(11) * 0.01f);
    if (!isServer()) return;

    CPlayer@ player = this.getDamageOwnerPlayer();
    CBlob@ b = player !is null ? player.getBlob() : null;

    if (b !is null && !this.hasTag("counterspelled"))
    {
        CBitStream params;
		params.write_u16(b.getNetworkID());
		this.SendCommand(this.getCommandID("restore_caster"), params);
    }
}
