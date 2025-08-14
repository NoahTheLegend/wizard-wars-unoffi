#include "TextureCreation.as";

void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
    shape.getConsts().bullet = true;
    shape.getConsts().mapCollisions = false;

    shape.SetGravityScale(0.0f);
    shape.SetRotationsAllowed(false);

    this.set_u8("dispelled", 0);
    this.set_Vec2f("smashtoparticles_grav", Vec2f_zero);

    this.Tag("multi_dispell");
    this.Tag("cantparry");
    this.Tag("cantmove");
    this.Tag("no trampoline collision");
    this.Tag("solidblob");

    this.set_Vec2f("init_pos", Vec2f_zero);
    this.set_f32("push_mod", 1.0f);

    this.set_bool("small", this.getName() == "magicplatformsmall");
    this.getSprite().SetRelativeZ(5.0f);

    f32 height = 32.0f;
    if (this.getTeamNum() > 1)
    {
        // map prop
        height += (this.getTeamNum() - 2) * 8.0f;
        this.Tag("extra_damage");
        this.AddScript("IgnoreDamage.as");
        this.server_setTeamNum(3);
    }

    this.set_f32("speed_reduction", height / 128.0f);
    this.set_f32("height", height);
}

const f32 max_dist = 32.0f;
const f32 push_lerp = 0.5f;

const f32 LARGE_FLOAT = 1e30;

bool IsFinite(f32 value)
{
    return value < LARGE_FLOAT && value > -LARGE_FLOAT && value == value;
}

void onTick(CBlob@ this)
{
    if (this.get_u8("dispelled") >= (this.get_bool("small") ? 1 : 2))
    {
        this.Tag("mark_for_death");
    }

    Vec2f pos = this.getPosition();
    Vec2f init_pos = this.get_Vec2f("init_pos");
    Vec2f vel = this.getVelocity();

    if (this.hasTag("extra_damage"))
    {
        init_pos.y += Maths::Sin(this.getTickSinceCreated() * (0.0225f / this.get_f32("speed_reduction"))) * this.get_f32("height") * (this.get_bool("inversed") ? -1 : 1);
    }

    if (isClient() && getGameTime() % (v_fastrender ? 2 : 1) == 0)
    {
        CParticle@ p = ParticleAnimated(this.getSprite().getConsts().filename, Vec2f_lerp(pos, pos + vel, getInterpolationFactor()) - Vec2f(0, 2), Vec2f_zero, 0, 1.0f, v_fastrender ? 15 : 5, 0.0f, true);
        if (p !is null)
        {
            p.bounce = 0;
            p.collides = true;
            p.fastcollision = true;
            p.timeout = 15;
            p.growth = -0.01f;
            p.Z = -1.0f;
            p.gravity = Vec2f_zero;
            p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
        }
    }

    if (this.getTickSinceCreated() == 0)
    {
        bool inversed = this.get_Vec2f("spawn_customData").y == -1;
        this.set_bool("inversed", inversed);

        Vec2f pos = this.getPosition();
        Vec2f init_pos = pos;
        
        this.set_Vec2f("init_pos", init_pos);
        if (isServer()) this.Sync("init_pos", true);

        this.setPosition(init_pos + Vec2f(0, 1 + XORRandom(31)*0.1f));
    }

    this.setPosition(Vec2f(init_pos.x, pos.y));
    if (!isServer()) return;

    u8 t = 4;
    if (getGameTime() % t == 0)
    {
        Vec2f boundaries = this.get_bool("small") ? Vec2f(64 / 2, 0) : Vec2f(112 / 2, 0);
        CMap@ map = getMap();

        Vec2f tl = this.getPosition() - Vec2f(boundaries.x, 16);
        Vec2f br = this.getPosition() + Vec2f(boundaries.x, -12);

        CBlob@[] bs;
        map.getBlobsInBox(tl, br, bs);

        for (int i = 0; i < bs.length; i++)
        {
            CBlob@ b = bs[i];
            if (b !is null && b.hasTag("flesh"))
            {
                b.set_u32("trampoline_floor", getGameTime() + t);
            }
        }
    }

    f32 mod = Maths::Lerp(this.get_f32("push_mod"), 2.0f, push_lerp);
    this.set_f32("push_mod", mod);

    Vec2f dir = pos - init_pos;
    f32 dir_len = dir.Length();
    if (dir_len > 0.001f)
        dir.Normalize();
    else
        dir = Vec2f_zero;

    s8 s = pos.y < init_pos.y ? 1 : -1;
    f32 dist_factor = Maths::Clamp(dir_len / max_dist, 0.0f, 5.0);
    f32 damp_range = 16.0f;

    if (Maths::Abs(pos.y - init_pos.y) < damp_range)
    {
        this.setVelocity(Vec2f(vel.x, vel.y * 0.9f));
    }

    f32 mass = this.getMass();
    if (IsFinite(dist_factor) && IsFinite(mod) && IsFinite(mass))
    {
        f32 force = s * mass * dist_factor * mod;
        if (IsFinite(force) && Maths::Abs(force) < 10000.0f) // arbitrary large value clamp
        {
            this.AddForce(Vec2f(0, force));
        }
    }
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
    if (blob !is null && blob.hasTag("flesh") && blob.getPosition().y < this.getPosition().y)
    {
        blob.set_u32("trampoline_floor", getGameTime() + 5);

        //f32 vel_y = blob.getVelocity().y;
        //f32 lerp_val = Maths::Abs(Maths::Sqrt(Maths::Abs(vel_y)));
        //if (IsFinite(lerp_val))
        //{
        //    this.set_f32("push_mod", Maths::Lerp(this.get_f32("push_mod"), 0.0f, lerp_val));
        //}
    }
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
    if (blob !is null && blob.exists("trampoline_floor"))
    {
        blob.set_u32("trampoline_floor", 0);
    }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return blob.hasTag("flesh") && blob.getPosition().y < this.getPosition().y - 10;
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("EnergySound2.ogg", 0.8f, 0.85f + XORRandom(11) * 0.01f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return false;
}