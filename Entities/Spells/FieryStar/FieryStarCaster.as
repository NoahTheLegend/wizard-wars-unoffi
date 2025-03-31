void onInit(CBlob@ this)
{
    CShape@ shape = this.getShape();
    shape.SetGravityScale(0.0f);
    ShapeConsts@ consts = shape.getConsts();
    consts.mapCollisions = false;

    this.getSprite().SetZ(501.0f);
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
    
    if (dist <= 1.0f)
    {
        this.Tag("armed");
    }

    if (!this.hasTag("armed"))
    {
        this.setPosition(Vec2f_lerp(this.getPosition(), target_pos, 0.2f));
    }
    else
    {
        if (caster_blob.get_bool("shifting") && !this.hasScript("CastFieryStars.as"))
        {
            this.server_SetTimeToDie(5);
            this.AddScript("CastFieryStars.as");
        }
    }

    if (!isClient()) return;
    makeSineSparks(this);
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

void makeSineSparks(CBlob@ this)
{
    float width = 24.0f;
    float narrow_top = 0.5f;
    float narrow_bottom = 0.5f;
    f32 mod = 0.25f;

    for (u8 i = 0; i < (v_fastrender ? 35 : 70); i++)
    {
        float baseAngle = getGameTime() * 0.1f;
        float angle = baseAngle + i * 30.0f;
        float height = i * mod;

        float heightFactor = 1.0f - (Maths::Abs(height - 2.5f) * 0.4f);
        float narrowFactor = 1.0f - (height * narrow_top + (5.0f - height) * narrow_bottom) * 0.2f;

        float xOffset = width * Maths::Cos(angle) * Maths::Clamp(heightFactor * narrowFactor, 0.1f, 1.0f);
        float yOffset = Maths::Cos(i * 0.4f) * 5.0f;
        float zOffset = 10000 * Maths::Sin(angle);

        Vec2f offset = Vec2f(xOffset, yOffset);
        Vec2f pVel = Vec2f(0, 0).RotateByDegrees(angle) * speed;

        CParticle@ p = ParticlePixelUnlimited(this.getPosition() + offset, pVel, 
            SColor(155 + XORRandom(100), 255, 255, XORRandom(255)), true);

        if (p !is null)
        {
            p.gravity = Vec2f(0, 0);
            p.timeout = 3;
            p.Z = -100 + zOffset;
            p.collides = false;
            p.bounce = 0.0f;
            p.fastcollision = true;
            p.damping = 0.95f;
        }
    }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return false;
}