#include "Hitters.as";
#include "WarpCommon.as";

const int effectRadiusBase = 128.0f;
const f32 lifetimeBase = 30.0f;
const f32 lifetimePortal = 5.0f;

const u32 cd_warp = 15; // time before you can warp again
const u32 cd_retry = 10; // time before you can retry warping
const u32 particle_spin = 90;

const f32 boundary_offset = 16.0f; // offset from the edge of the circle to prevent warping inside
const u32 lifetime = 60;
const u32 lifetime_rnd = 30; 

const float rotateSpeed = 4;
const u8 max_symbols = 25;
const u8 symbol_appearance_thresh = 3;

void onInit(CBlob@ this)
{
    this.addCommandID("warp");
    this.Tag("push_warp_portal");

    this.set_u8("frame", 0);
    this.Tag("magic_circle");

    this.getSprite().SetRelativeZ(-10.0f);
    this.set("colour", SColor(255,200,0,255));

    this.getShape().getConsts().mapCollisions = false;
    this.set_u8("type", this.getName().substr(0, 1) == "p" ? 1 : 0); // 1 = portal, 0 = field
    this.server_SetTimeToDie(this.get_u8("type") == 0 ? lifetimeBase : lifetimePortal);

    this.set_f32("scale", this.get_u8("type") == 0 ? 0.75f : 0.33f);
    f32 radius = effectRadiusBase * (this.get_f32("scale") / 2);
    this.set_s32("effectRadius", radius);

    if (getMap().isTileSolid(getMap().getTile(this.getPosition() + Vec2f(0, 8))))
    {
        this.setPosition(this.getPosition() - Vec2f(0, 6));
    }

    CBlob@[] ps;
    if (isServer() && getBlobsByTag("push_warp_portal", @ps))
    {
        Vec2f pos = this.getPosition();
        u8 tries = 0;

        for (int i = 0; i < ps.length; i++)
        {
            CBlob@ b = ps[i];
            if (b is null || b is this)
                continue;
            
            Vec2f dir = b.getPosition() - pos;
            f32 dir_len = dir.Length();

            f32 other_radius = effectRadiusBase * (b.get_f32("scale") / 2.0f);
            if (dir_len < other_radius * 2)
            {
                tries++;
                
                dir.Normalize();
                dir *= -other_radius * 2 + dir_len;

                Vec2f rand = getRandomVelocity(0, radius * 0.1f, XORRandom(360));
                pos += dir + rand;
                i--;

                if (tries > 200)
                {
                    break;
                }
            }
        }

        int seed = pos.x * pos.y;
        this.setPosition(pos);
        this.set_Vec2f("next_warp_portal_pos", getRandomFloorLocationOnMap(seed, pos));  
    }
}

void onTick(CBlob@ this)
{
    if (this.get_u8("dispelled") >= 1) this.server_Die();
    u8 type = this.get_u8("type");

    f32 lifetime_factor = Maths::Clamp((int(this.getTickSinceCreated() - 30) / 90.0f), 0.0f, 1.0f);
    f32 rot = rotateSpeed * lifetime_factor;
    this.setAngleDegrees(this.getAngleDegrees() + rot);

    if (this.getTickSinceCreated() == 0)
    {
        int seed = this.getPosition().x * this.getPosition().y;
        if (this.hasTag("extra_damage"))
        {
            // create a chain of 6 portals on the map
            this.set_Vec2f("next_warp_portal_pos", getRandomFloorLocationOnMap(seed, this.getPosition()));

            CBlob@ first_portal = createWarpPortal(seed, this.getPosition(), this.get_Vec2f("next_warp_portal_pos"));
            if (first_portal !is null)
            {
                int c = 6;
                first_portal.Tag("prespawned");
                first_portal.server_SetTimeToDie(lifetimeBase);

                first_portal.set_u16("last_warp_portal_chain", this.getNetworkID());
                this.set_u16("next_warp_portal_chain", first_portal.getNetworkID());

                CBlob@ portal = @first_portal;
                for (u8 i = 0; i < c; i++)
                {
                    if (portal is null) continue;

                    portal.Tag("prespawned");
                    portal.server_SetTimeToDie(this.getTimeToDie());
                    
                    first_portal.set_u16("next_warp_portal_chain", portal.getNetworkID());
                    portal.set_u16("last_warp_portal_chain", first_portal.getNetworkID());

                    seed = portal.getPosition().x * portal.getPosition().y;
                    CBlob@ new_portal = createWarpPortal(seed, portal.getPosition(), getRandomFloorLocationOnMap(seed, portal.getPosition()));
                    if (new_portal !is null)
                    {
                        new_portal.Tag("prespawned");
                        new_portal.server_SetTimeToDie(this.getTimeToDie());

                        portal.set_u16("next_warp_portal_chain", new_portal.getNetworkID());
                        new_portal.set_u16("last_warp_portal_chain", portal.getNetworkID());

                        seed = new_portal.getPosition().x * new_portal.getPosition().y;
                        if (i == c - 1)
                        {
                            new_portal.Tag("last_portal");
                            if (first_portal !is null)
                            {
                                new_portal.set_u16("next_warp_portal_chain", first_portal.getNetworkID());
                                first_portal.set_u16("last_warp_portal_chain", new_portal.getNetworkID());
                            }
                        }

                        @portal = @new_portal;
                    }
                    else
                    {
                        break; // no more space for portals
                    }
                }
            }
        }
        else if (!this.hasTag("prespawned"))
        {
            if (type == 0) this.set_Vec2f("next_warp_portal_pos", getRandomFloorLocationOnMap(seed, this.getPosition()));
            else
            {
                u16 last_chain = this.get_u16("next_warp_portal_chain");
                if (last_chain != 0)
                {
                    CBlob@ last_portal = getBlobByNetworkID(last_chain);
                    if (last_portal !is null)
                    {
                        last_portal.set_Vec2f("next_warp_portal_pos", this.getPosition());
                    }
                }
            }
        }
    }

    if (this.getTickSinceCreated() < 20)
    {
        return;
    }

    f32 scale = this.get_f32("scale");
    int effectRadius = this.get_s32("effectRadius");

    CMap@ map = this.getMap();
    CBlob@[] bs;
    if (map.getBlobsInRadius(this.getPosition(), effectRadius, @bs))
    {
        for (int i = 0; i < bs.length; i++)
        {
            CBlob@ b = bs[i];
            if (b is null || b is this || !(b.hasTag("player") || b.hasTag("zombie")))
                continue;

            if (!(isServer() || b.isMyPlayer()))
                continue;
            
            Vec2f dir = b.getPosition() - this.getPosition();
            dir.Normalize();

            bool tp_back = false;
            if (b.get_u32("last_warp" + this.getNetworkID()) < getGameTime()
                && (!b.exists("global_warp_time") || b.get_u32("global_warp_time") < getGameTime())
                && b.exists("teleported_time") && b.get_u32("teleported_time") >= getGameTime()-1)
            {
                if (isServer())
                {
                    CBlob@ portal = getBlobByNetworkID(this.get_u16("next_warp_portal_chain"));
                    if (this.hasTag("prespawned") || this.hasTag("extra_damage"))
                    {

                    }
                    else if (portal is null || this.get_u16("next_warp_portal_chain") == 0)
                    {
                        int seed = this.getPosition().x * this.getPosition().y;
                        @portal = createWarpPortal(seed, this.getPosition(), this.get_Vec2f("next_warp_portal_pos"));
                    }

                    if (portal !is null)
                    {
                        if (!this.hasTag("prespawned") && !this.hasTag("extra_damage"))
                        {
                            portal.server_SetTimeToDie(portal.get_u8("type") == 0 ? lifetimeBase : lifetimePortal);
                            
                            this.set_u16("next_warp_portal_chain", portal.getNetworkID());
                            portal.set_u16("last_warp_portal_chain", this.getNetworkID());
                        }
                        b.set_u32("global_warp_time", getGameTime() + 3);

                        if (!isClient()) // ignore localhost
                        {
                            CBitStream params;
                            params.write_u16(b.getNetworkID());
                            params.write_Vec2f(portal.getPosition());
                            this.SendCommand(this.getCommandID("warp"), params);
                        }
                        else
                        {
                            b.setPosition(portal.getPosition());
                            b.setVelocity(Vec2f(0, 0));
                            
                            b.set_u32("last_warp" + this.getNetworkID(), getGameTime() + cd_warp);
                            b.set_u32("particle_warp_spin" + this.getNetworkID(), getGameTime() + particle_spin);
                        }
                    }
                }
            }
            else if (type == 0)
            {
                if (b.exists("last_warp" + this.getNetworkID()) && b.get_u32("last_warp" + this.getNetworkID()) > getGameTime())
                {
                    tp_back = true;
                }
                else
                {
                    Vec2f warp_pos = this.getPosition() - dir * (effectRadius + 8.0f);
                    if (map.isTileSolid(map.getTile(warp_pos).type) || warp_pos.y > map.tilemapheight * map.tilesize - 16)
                    {
                        tp_back = true;
                    }
                    else
                    {
                        // moved inside
                        b.setPosition(warp_pos);
                        b.getSprite().PlaySound("warp_through.ogg", 0.8f, 0.65f+XORRandom(11) * 0.01f);

                        b.set_u32("last_warp" + this.getNetworkID(), getGameTime() + cd_warp);
                        b.set_u32("particle_warp_spin" + this.getNetworkID(), getGameTime() + particle_spin);
                    }
                }
            }

            if (tp_back && type == 0)
            {
                Vec2f b_dir = b.getPosition() - b.getVelocity();
                b.setPosition(b_dir + dir * 4);
                b.setVelocity(dir);

                b.set_u32("last_warp" + this.getNetworkID(), getGameTime() + cd_retry);
                b.set_u32("particle_warp_spin" + this.getNetworkID(), getGameTime() + particle_spin);
            }
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("warp"))
    {
        u16 blob_id;
        Vec2f pos;

        if (!params.saferead_u16(blob_id) || !params.saferead_Vec2f(pos))
            return;

        CBlob@ b = getBlobByNetworkID(blob_id);
        if (b !is null)
        {
            b.setPosition(pos);
            b.setVelocity(Vec2f(0, 0));
            
            b.set_u32("global_warp_time", getGameTime() + cd_warp);
            b.set_u32("last_warp" + this.getNetworkID(), getGameTime() + cd_warp);
            b.set_u32("particle_warp_spin" + this.getNetworkID(), getGameTime() + particle_spin);

            ParticleAnimated("Flash3.png",
							  pos,
							  Vec2f(0,0),
							  360.0f * XORRandom(100) * 0.01f,
							  1.0f, 
							  3, 
							  0.0f, true);

            b.getSprite().PlaySound("warp_teleport.ogg", 1.0f, 1.0f+XORRandom(10) * 0.01f);
        }
    }
}

void onInit(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    if (b is null) return;

    f32 scale = b.get_f32("scale");
    int effectRadius = b.get_s32("effectRadius");
    u8 type = b.get_u8("type");

    this.ScaleBy(Vec2f(scale, scale));
    this.PlaySound("warp_open.ogg", type == 0 ? 0.66f : 0.45f, type == 0 ? 1.0f : 1.15f + XORRandom(10) * 0.01f);
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

    if (type == 1) return;
    for (int i = 0; i < max_symbols; i++)
    {
        CSpriteLayer@ layer = this.addSpriteLayer("warpsymbol_"+i, "WarpSymbols.png", 8, 8);
        if (layer !is null)
        {
            Animation@ anim = layer.addAnimation("default", 0, false);
            anim.AddFrame(XORRandom(10));
            layer.SetAnimation(anim);
            layer.animation.frame = 0;

            layer.SetOffset(Vec2f(0, -effectRadius + 7).RotateBy((360.0f/f32(max_symbols)) * i));
            layer.RotateBy(-(360.0f/f32(max_symbols)) * i, Vec2f(0, 0));

            layer.SetRelativeZ(-1.0f);
            layer.ScaleBy(Vec2f(1.5f, 1.5f));
            layer.SetVisible(false);
            //layer.setRenderStyle(RenderStyle::additive);
        }
    }
}

void onTick(CSprite@ this)
{
    CBlob@ b = this.getBlob();
    if (b is null) return;

    f32 scale = b.get_f32("scale");
    int effectRadius = b.get_s32("effectRadius");

    if (!this.isAnimationEnded())
    {
        CSpriteLayer@ inner = this.getSpriteLayer("inner");
        if (inner !is null)
        {
            this.animation.frame += 1;
            inner.animation.frame = this.animation.frame;
        }

        return;
    }

    u8 type = b.get_u8("type");
    int tt = b.getTickSinceCreated() - 30;
    if (type == 0 && tt % symbol_appearance_thresh == 0 && (tt / symbol_appearance_thresh) < max_symbols)
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

    if (b.getTickSinceCreated() % (type == 0 ? 3 : 10) == 0)
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
                col.setRed( 155 + XORRandom(100)); // Randomize red between 128 and 255
                col.setGreen( 55 + XORRandom(55)); // Randomize green between 0 and 128
                col.setBlue( 155 + XORRandom(100)); // Randomize blue between 128 and 255

                p.colour = col;
                p.forcecolor = col;

                particleList.push_back(p);
            }
        }
    }

    if (type == 0)
    {
        Vec2f pos = b.getPosition();
        Vec2f mpos = getControls().getMouseWorldPos();
        bool cond = local.exists("particle_warp_spin" + b.getNetworkID()) && local.get_u32("particle_warp_spin" + b.getNetworkID()) > getGameTime();
        f32 diff = cond ? f32(local.get_u32("particle_warp_spin" + b.getNetworkID()) - getGameTime()) / particle_spin : 0.0f;
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
                particle.position = pos + pdir * (effectRadius - effectRadius * 0.1f);
            }
        }
    }
    else
    {
        Vec2f pos = b.getPosition();
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

            if ((particle.position - pos).Length() > effectRadius - effectRadius * 0.1f)
            {
                // loop back
                pdir.Normalize();
                particle.position = pos + pdir * (effectRadius - effectRadius * 0.1f);
            }
        }
    }

    b.set("ParticleList", particleList);
}

void onDie(CBlob@ this)
{
    u8 type = this.get_u8("type");
    this.getSprite().PlaySound(type == 0 ? "warp_end.ogg" : "warp_end_small.ogg", 1.0f, 1.0f + XORRandom(10) * 0.01f);

    f32 scale = this.get_f32("scale") * 2;
    Vec2f pos = this.getPosition();

    CParticle@[] particleList;
    this.get("ParticleList", particleList);

    for (int i = 0; i < particleList.length(); i++)
    {
        CParticle@ p = particleList[i];
        if (p !is null)
        {
            p.velocity = p.position - pos;
        }
    }

    Vec2f vel = Vec2f_zero;
    CParticle@ p = ParticleAnimated(CFileMatcher("Implosion4.png").getFirst(), 
								pos, 
								vel, 
								0, 
								scale, 
								3, 
								0.0f, 
								false);
								
    if(p is null) return; //bail if we stop getting particles
	
    p.frame = 2;
	p.colour = SColor(255,200,45,200);
    p.fastcollision = true;
    p.damping = 0.85f;
	p.Z = -5.0f;
	p.lighting = true;
    p.setRenderStyle(RenderStyle::additive);
}
