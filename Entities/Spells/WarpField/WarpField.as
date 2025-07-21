#include "Hitters.as";

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");

    this.SetLightRadius(effectRadius);
    this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);

    this.getSprite().SetRelativeZ(-10.0f);
    this.set("colour", SColor(255,200,0,255));

    this.getShape().getConsts().mapCollisions = false;
}

const f32 scale = 0.75f;
const int effectRadius = 128.0f * (scale / 2);

const u32 cd_warp = 30; // time before you can warp again
const u32 cd_retry = 15; // time before you can retry warping
const u32 particle_spin = 90;

const f32 boundary_offset = 16.0f; // offset from the edge of the circle to prevent warping inside
const u32 lifetime = 60;
const u32 lifetime_rnd = 30; 

void onTick(CBlob@ this)
{
    this.server_SetTimeToDie(15);
    if (this.getTickSinceCreated() < 20)
    {
        return;
    }

    CMap@ map = this.getMap();
    CBlob@[] bs;
    if (map.getBlobsInRadius(this.getPosition(), effectRadius, @bs))
    {
        for (int i = 0; i < bs.length; i++)
        {
            CBlob@ b = bs[i];
            if (b is this || !(b.hasTag("player") || b.hasTag("zombie")))
                continue;

            if (!(isServer() || b.isMyPlayer()))
                continue;

            Vec2f dir = b.getPosition() - this.getPosition();
            dir.Normalize();

            f32 delta = (b.getOldPosition() - b.getPosition()).Length();
            if (delta > b.getVelocity().Length() && delta > b.getOldVelocity().Length())
            {
                // teleport to another location
            }
            else
            {
                bool tp_back = false;
                if (b.exists("last_warp") && b.get_u32("last_warp") > getGameTime())
                {
                    tp_back = true;
                }
                else
                {
                    Vec2f warp_pos = this.getPosition() - dir * (effectRadius + 8.0f);
                    if (map.isTileSolid(map.getTile(warp_pos).type))
                    {
                        tp_back = true;
                    }
                    else
                    {
                        // moved inside
                        b.setPosition(warp_pos);
                        b.set_u32("last_warp", getGameTime() + cd_warp);
                        b.set_u32("particle_warp_spin", getGameTime() + particle_spin);
                    }
                }

                if (tp_back)
                {
                    Vec2f b_dir = b.getPosition() - b.getVelocity();
                    b.setPosition(b_dir + dir * 4);
                    b.setVelocity(dir);

                    this.getSprite().PlaySound("NoAmmo.ogg", 1.0f, 1.5f + XORRandom(15) * 0.01f);
                    b.set_u32("last_warp", getGameTime() + cd_retry);
                    b.set_u32("particle_warp_spin", getGameTime() + particle_spin);
                }
            }
        }
    }
}

const float rotateSpeed = 4;
void onInit(CSprite@ this)
{
    this.ScaleBy(Vec2f(scale, scale));
    this.PlaySound("circle_create.ogg", 5, 1.33f);
    this.setRenderStyle(RenderStyle::additive);

    CSpriteLayer@ layer = this.addSpriteLayer("inner", "WarpFieldInner.png", 128, 128);
    if (layer !is null)
    {
        layer.SetRelativeZ(-5.0f);
        layer.ScaleBy(Vec2f(scale, scale));
        layer.setRenderStyle(RenderStyle::shadow);

        Animation@ anim = layer.addAnimation("default", 0, false);
        if (anim !is null)
        {
            int[] frames = {0, 0, 1, 2, 3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 9};
            anim.AddFrames(frames);
        }
    }

    for (int i = 0; i < max_symbols; i++)
    {
        CSpriteLayer@ layer = this.addSpriteLayer("warpsymbol_"+i, "WarpSymbols.png", 8, 8);
        if (layer !is null)
        {
            Animation@ anim = layer.addAnimation("default", 0, false);
            anim.AddFrame(XORRandom(10));
            layer.SetAnimation(anim);
            layer.animation.frame = 0;

            layer.SetOffset(Vec2f(0, -effectRadius + 8).RotateBy((360/max_symbols) * i));
            layer.RotateBy(-(360/max_symbols) * i, Vec2f(0, 0));

            layer.SetRelativeZ(-1.0f);
            layer.ScaleBy(Vec2f(1.5f, 1.5f));
            layer.SetVisible(false);
            layer.setRenderStyle(RenderStyle::additive);
        }
    }
}

const u8 max_symbols = 30;
const u8 symbol_appearance_thresh = 3;

void onTick(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    if (b is null) return;
    
    f32 lifetime_factor = Maths::Clamp((int(b.getTickSinceCreated() - 30) / 90.0f), 0.0f, 1.0f);
    f32 rot = rotateSpeed * lifetime_factor;

    if (this.isAnimationEnded()) b.setAngleDegrees(b.getAngleDegrees() + rot);
    else
    {
        CSpriteLayer@ inner = this.getSpriteLayer("inner");
        if (inner !is null)
        {
            this.animation.frame += 1;
            inner.animation.frame = this.animation.frame;
        }

        return;
    }

    int tt = b.getTickSinceCreated() - 30;
    if (tt % symbol_appearance_thresh == 0 && (tt / symbol_appearance_thresh) < max_symbols)
    {
        CSpriteLayer@ layer = this.getSpriteLayer("warpsymbol_" + (tt / symbol_appearance_thresh));
        if (layer !is null)
        {
            layer.SetVisible(true);
        }
    }

    CBlob@ local = getLocalPlayerBlob();
    if (local is null) return;

    CParticle@[] particleList;
    SColor col;

    b.get("ParticleList", particleList);
    b.get("colour", col);

    if (b.getTickSinceCreated() % 3 == 0)
    {
        for (int a = 0; a < 5 + XORRandom(5); a++)
        {
            Vec2f offset = Vec2f_lerp(Vec2f(XORRandom(effectRadius - boundary_offset), 0), Vec2f(effectRadius - boundary_offset, 0), 0.5f);
            CParticle@ p = ParticlePixelUnlimited(b.getPosition() + offset.RotateBy(XORRandom(360)), Vec2f(0,0), col,
                true);

            if (p !is null)
            {
                p.collides = false;
                p.fastcollision = true;
                p.gravity = Vec2f(0,0);
                p.bounce = 0;
                p.Z = -2;
                p.timeout = lifetime + XORRandom(lifetime_rnd);
                p.oldposition = Vec2f(XORRandom(100)*0.001f+0.01f, XORRandom(100)*0.001f+0.01f); // seed for random movement, x = sin amplitude, y = speed mod

                SColor col = p.colour;
                col.setRed(  155 + XORRandom(100)); // Randomize red between 128 and 255
                col.setGreen( 55 + XORRandom(55)); // Randomize green between 0 and 128
                col.setBlue( 155 + XORRandom(100)); // Randomize blue between 128 and 255

                p.colour = col;
                p.forcecolor = col;

                particleList.push_back(p);
            }
        }
    }

    Vec2f pos = b.getPosition();
    Vec2f mpos = getControls().getMouseWorldPos();
    bool cond = local.exists("particle_warp_spin") && local.get_u32("particle_warp_spin") > getGameTime();
    f32 diff = cond ? f32(local.get_u32("particle_warp_spin") - getGameTime()) / particle_spin : 0.0f;
    Vec2f local_pos = local.getPosition();

    for (int a = 0; a < particleList.length(); a++)
    {
        CParticle@ particle = particleList[a];

        //check
        if (particle.timeout < 1)
        {
            particleList.erase(a);
            a--;
            continue;
        }

        SColor col = particle.colour;

        f32 sin_amplitude = particle.oldposition.x;
        f32 speed_mod = particle.oldposition.y;
        
        f32 speed = Maths::Clamp(speed_mod * Maths::Sin(f32(getGameTime()) * sin_amplitude), 0.0f, 1.0f);
        Vec2f slide_dir = Vec2f(0, speed).RotateBy((col.getRed() * col.getGreen() * col.getBlue()) % 360);

        f32 side = Maths::Round(sin_amplitude * 1000) % 2 == 0 ? -1.0f : 1.0f;
        f32 rot_mod =  Maths::Clamp(f32(particle.timeout) / f32(lifetime + lifetime_rnd), 0.0f, 1.0f);
        f32 deg = 360 * side * rot_mod;
        slide_dir.RotateByDegrees(deg);

        slide_dir.x = Maths::Round(slide_dir.x);
        slide_dir.y = Maths::Round(slide_dir.y);

        Vec2f pdir = particle.position - pos;
        particle.position += slide_dir;

        if (!v_fastrender && diff > 0)
        {
            f32 pangle = (particle.position - local_pos).Angle();
            f32 mangle = pdir.Angle();
            particle.position = Vec2f_lerp(particle.position, local_pos, Maths::Cos(pangle - mangle) * 0.1f * diff);
        }

        if ((particle.position - pos).Length() > effectRadius - 8)
        {
            // loop back
            pdir.Normalize();
            particle.position = pos + pdir * (effectRadius - 8);
        }
    }

    b.set("ParticleList", particleList);
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("circle_create.ogg",10,1.25f);
}
