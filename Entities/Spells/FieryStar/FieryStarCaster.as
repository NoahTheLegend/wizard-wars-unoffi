#include "EffectsCollection.as";

void onInit(CBlob@ this)
{
    this.Tag("counterable");

    CShape@ shape = this.getShape();
    shape.SetGravityScale(0.0f);
    ShapeConsts@ consts = shape.getConsts();
    consts.mapCollisions = false;

    this.getSprite().SetZ(501.0f);
    this.getSprite().setRenderStyle(RenderStyle::additive);
}

void onTeamChange(CBlob@ this, const int oldTeam)
{
    this.getSprite().setRenderStyle(RenderStyle::additive);
}

const f32 speed = 6;
void onTick(CBlob@ this)
{
    CPlayer@ caster = this.getDamageOwnerPlayer();
    if (caster is null) return;

    CBlob@ caster_blob = caster.getBlob();
    if (caster_blob is null) return;

    Vec2f target_pos = this.get_Vec2f("target_pos");
    Vec2f dir = target_pos - this.getPosition();
    f32 dist = dir.Length();
    
    if (dist <= 8.0f)
    {
        this.Tag("armed");
    }

    this.setPosition(Vec2f_lerp(this.getPosition(), target_pos, 0.15f));
    if (this.hasTag("armed"))
    {
        if (caster_blob.get_bool("shifting") && !this.hasScript("CastFieryStars.as"))
        {
            this.server_SetTimeToDie(5);
            this.AddScript("CastFieryStars.as");
        }
    }

    if (!isClient()) return;

    f32 narrow_center = (Maths::Sin(this.getTickSinceCreated() * 0.05f) + 8.0f) * 0.125f;
	f32 narrow_top = 	0.0f + narrow_center * 0.1f;
	f32 narrow_bottom = 0.0f + narrow_center * 0.1f;

    f32 sin = (Maths::Sin(getGameTime() * 0.1f) + 1.0f) * 0.5f;
    makeSineSparks(this.getPosition(), 20 + sin*20, 12, 12, SColor(255, 255, 255, XORRandom(155)),
        narrow_top, narrow_bottom, narrow_center, 1.25f, 1.0f, 2 + 3*sin, SineStyle::easeout,
            getSineSeed(this.getNetworkID()));

    sparks(this, Vec2f(0,-2), 1);
    sparks(this, Vec2f(0,2), 1);
}

void sparks(CBlob@ this, Vec2f vel, int amount)
{
    Vec2f pPos = this.getPosition();
    Vec2f pVel = vel;
    SColor color = SColor(155 + XORRandom(100), 255, 255, XORRandom(255));
    for (int i = 0; i < amount; i++)
    {
        CParticle@ p = ParticlePixelUnlimited(pPos, pVel, color, true);
        if (p !is null)
        {
            p.gravity = Vec2f(0, 0);
            p.timeout = 10+XORRandom(10);
            p.Z = 50;
            p.collides = false;
            p.bounce = 0.0f;
            p.fastcollision = true;
            p.damping = 0.9f+XORRandom(10) * 0.01f;
        }
    }
}