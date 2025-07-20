void onDie(CBlob@ this) //so its synced
{
    if (this.hasTag("particles_done")) return;
    
    if (!makeParticlesFromSpriteAccurate(this, this.getSprite(), this.get_u16("smashtoparticles_probability")))
    {
        ParticlesFromSprite(this.getSprite());
    }
}

void onTick(CBlob@ this)
{
    if (this.hasTag("mark_for_death"))
    {
        onDie(this);
        this.Tag("particles_done");
    }
}

const int[] cols = {0xff2cafde,0xff1d85ab,0xff1a4e83,0xff222760,0xffd5543f,0xffb73333,0xff941b1b,0xff3b1406,0xffd379e0,0xff9e3abb,0xff621a83,0xff2a0b47};

SColor colorSwap(SColor oldcol, u8 t)
{
    SColor newcol = oldcol.color;

    if (t == 3 && newcol.getRed() < 125)
    {
        int idx = cols.find(oldcol.color);
        if (idx+4 < cols.size()-1) newcol = cols[idx+8];
    }

    if (t == 1 && newcol.getRed() < 125)
    {
        int idx = cols.find(oldcol.color);
        if (idx+4 < cols.size()-1) newcol = cols[idx+4];
    }
    
    return SColor(newcol);
}

bool makeParticlesFromSpriteAccurate(CBlob@ this, CSprite@ sprite, u16 probability)
{
    CFileImage@ image;
    @image = CFileImage(sprite.getConsts().filename);

	if (image.isLoaded())
	{
        sprite.SetVisible(false); // force disable sprite visibility to prevent dublicate in rendering
        
        Vec2f pos = this.getOldPosition();
        Vec2f vel = this.getOldVelocity();
        f32 deg = this.getAngleDegrees();
        bool fl = this.isFacingLeft();
        f32 layer = sprite.getZ();
        
        int w = image.getWidth(); 
        int h = image.getHeight();
        
        int frame = 0;
        Vec2f framesize = Vec2f_zero;
        if (sprite.animation !is null)
        {
            framesize.x = sprite.getFrameWidth();
            framesize.y = sprite.getFrameHeight();
            frame = sprite.animation.frame;

            int max_frames_in_row = Maths::Floor(w / framesize.x);
            image.setPixelPosition(Vec2f((frame * framesize.x % max_frames_in_row), Maths::Floor((frame * framesize.y) / max_frames_in_row)));
        }
        else framesize = Vec2f(w,h);
        //printf("frsize: "+framesize+" fr: "+frame);

        Vec2f center = Vec2f(-framesize.x/2, -framesize.y/2) + sprite.getOffset(); // shift it to upper left corner for 1/2 of sprite size
        Vec2f grav = this.exists("smashtoparticles_grav") ? this.get_Vec2f("smashtoparticles_grav") : Vec2f(0, 0.33f);
        Vec2f grav_rnd = this.exists("smashtoparticles_grav_rnd") ? this.get_Vec2f("smashtoparticles_grav_rnd") : Vec2f_zero;

        int temp_x = 0;
        int temp_y = 0;

        u32 max = 100000;
        u32 temp_max = 0;

        bool additive = this.hasTag("smashtoparticles_additive");
        
        while (image.nextPixel() && w != 0 && h != 0)
		{
            if (temp_max >= max)
            {
                warn("Smash particles limit was reached");
                break;
            }
            temp_max++;

            Vec2f px_pos = image.getPixelPosition();
            temp_x++;

            if (temp_x == framesize.x)
            {
                temp_x = 0;
                temp_y++;
                if (temp_y > framesize.y)
                {
                    break;
                }
                
                int new_y = px_pos.y + 1;
                image.setPixelPosition(Vec2f(px_pos.x - framesize.x, new_y));
            }

			SColor px_col = image.readPixel();
            if (XORRandom(probability) != 0) continue;
            if (px_col.getAlpha() != 255) continue;
            px_col = colorSwap(px_col, this.getTeamNum());

            if (fl) px_pos.x = w-px_pos.x;

            Vec2f offset = center + Vec2f(px_pos.x % framesize.x, px_pos.y % framesize.y);
            //printf(pos+"<pos center>"+center+" & "+offset+"<offset px_pos>"+px_pos+" pos+offset>"+(pos+offset));
            
            offset.RotateBy(deg);
            MakeParticle(pos + offset, vel * (0.5f + XORRandom(51)*0.01f), px_col, layer, additive, grav, grav_rnd);
        }

        return true;
    }

    return false;
}

void MakeParticle(Vec2f pos, Vec2f vel, SColor col, f32 layer, bool additive = false, Vec2f grav = Vec2f(69,0), Vec2f grav_rnd = Vec2f(69,0))
{
    CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
    if(p !is null)
    {
        if (grav.x == 69) grav = Vec2f(0, 0.5f);

        p.bounce = 0.25f + XORRandom(26)*0.01f;
        p.fastcollision = true;

        f32 grx = 0; 
        f32 gry = 0; 
        if (grav_rnd.x != 69)
        {
            grx = (XORRandom(Maths::Abs(grav_rnd.x) * 1000) * 0.001f - grav_rnd.x / 2);
            gry = (XORRandom(Maths::Abs(grav_rnd.y) * 1000) * 0.001f - grav_rnd.y / 2);
        }

        p.gravity = grav + Vec2f(grx, gry);
        p.timeout = 15+XORRandom(30);
        p.Z = layer;
        if (additive) p.setRenderStyle(RenderStyle::additive);
    }
}