void onDie(CBlob@ this) //so its synced
{
    if (!makeParticlesFromSpriteAccurate(this, this.getSprite(), this.get_u16("smashtoparticles_probability")))
    {
        ParticlesFromSprite(this.getSprite());
    }
}

//doing this shitcode bc i am tired of trying to connect it to palette swap, i will hang myself
//if i get back to it again
//doesnt support framing and particle props yet

const int[] cols = {0xff2cafde,0xff1d85ab,0xff1a4e83,0xff222760,0xffd5543f,0xffb73333,0xff941b1b,0xff3b1406};

SColor blueRedSwap(SColor oldcol, u8 t)
{
    int newcol = oldcol.color;
    if (t > 1) return SColor(newcol);

    if (t == 1 && oldcol.getRed() < 125)
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
        
        Vec2f center = Vec2f(-w/2, -h/2) + sprite.getOffset(); // shift it to upper left corner for 1/2 of sprite size
        Vec2f grav = this.exists("smashtoparticles_grav") ? this.get_Vec2f("smashtoparticles_grav") : Vec2f_zero;
        Vec2f grav_rnd = this.exists("smashtoparticles_grav_rnd") ? this.get_Vec2f("smashtoparticles_grav_rnd") : Vec2f_zero;

        while(image.nextPixel() && w != 0 && h != 0)
		{
			SColor px_col = image.readPixel();
            if (XORRandom(probability) != 0) continue;
            if (px_col.getAlpha() != 255) continue;
            px_col = blueRedSwap(px_col, this.getTeamNum());

            Vec2f px_pos = image.getPixelPosition();
            if (fl) px_pos.x = w-px_pos.x;

            Vec2f offset = center + px_pos;
            offset.RotateBy(deg);
            MakeParticle(pos + offset, vel * (0.5f + XORRandom(51)*0.01f), px_col, layer, grav, grav_rnd);
        }

        return true;
    }

    return false;
}

void MakeParticle(Vec2f pos, Vec2f vel, SColor col, f32 layer, Vec2f grav = Vec2f(69,0), Vec2f grav_rnd = Vec2f(69,0))
{
    CParticle@ p = ParticlePixelUnlimited(pos, vel, col, true);
    if(p !is null)
    {
        if (grav.x == 69) grav = Vec2f(0, 0.5f);

        p.bounce = 0.15f + XORRandom(26)*0.01f;
        p.fastcollision = true;

        f32 grx = 0; 
        f32 gry = 0; 
        if (grav_rnd.x != 69)
        {
            grx = (XORRandom(Maths::Abs(grav_rnd.x) * 100) * 0.01f - grx * 2);
            gry = (XORRandom(Maths::Abs(grav_rnd.y) * 100) * 0.01f - gry * 2);
        }

        p.gravity = grav + Vec2f(grx, gry);
        p.timeout = 15+XORRandom(30);
        p.Z = layer;
    }
}