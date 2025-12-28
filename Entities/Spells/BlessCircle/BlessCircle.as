#include "Hitters.as";

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");
    this.SetLightRadius(effectRadius);
    this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);

    this.getSprite().SetRelativeZ(-10.1f);
    this.set("colour", SColor(255,200,0,255));
}

const int effectRadius = 8*10;

void onTick(CBlob@ this)
{
    bool fullCharge = this.hasTag("fullCharge");
    bool reverse = this.hasTag("reverse");

    if((!this.hasTag("finished") || reverse)  && getGameTime() % 2 == 0)
    {
        this.add_u8("frame", reverse ? -1 : 1);
        if(this.get_u8("frame") == 29)
        {
            this.Tag("finished");
        }
    }

    if(reverse && this.get_u8("frame") < 1) this.Tag("mark_for_death");
    if(!this.hasTag("finished")) return;

    if (isClient() && getGameTime() % 10 == 0)
    {
        CBlob@ local = getLocalPlayerBlob();
        if (local !is null && local.getDistanceTo(this) < effectRadius)
            local.set_u32("overload mana regen", getGameTime()+11);
    }
}

const float rotateSpeed = 1;

void onInit(CSprite@ this)
{
    {
        CSpriteLayer@ s = this.addSpriteLayer("circle","team_color_circle.png",100,100);
        s.setRenderStyle(RenderStyle::Style::light);
        s.ScaleBy(Vec2f(1.562,1.562));
        s.SetRelativeZ(-0.1f);
    }
    for (u8 i = 0; i < 4; i++)
    {
        CSpriteLayer@ s = this.addSpriteLayer("l"+i,"BlessCircleEdge.png",124,124);
        s.SetRelativeZ(i==3?-1.1f:-0.95f + i*0.01f);
        Animation@ anim = s.addAnimation("default", 0, false);
        if (anim !is null)
        {
            s.ScaleBy(Vec2f(1.15,1.15));
            anim.AddFrame(i);
            s.SetAnimation(anim);
        }
    }

    this.ScaleBy(Vec2f(1.165,1.165));
    this.PlaySound("circle_create.ogg",10,1.33f);
}

void onTick(CSprite@ this)
{
    bool reverse = this.getBlob().hasTag("reverse");
    CBlob@ b = this.getBlob();

    if(b.get_u8("frame") != 29 || reverse)
    {
        this.SetFrame(b.get_u8("frame"));
        this.SetVisible(true);
        
        for (u8 i = 0; i < 4; i++)
        {
            CSpriteLayer@ s = this.getSpriteLayer("l"+i);
            if (s !is null) s.SetVisible(false);
        }
    }
    else
    {
        this.RotateByDegrees((b.hasTag("fullCharge") ? rotateSpeed*2 : rotateSpeed) / (b.get_u8("dispelled") + 1) ,Vec2f(0,0));
        this.SetVisible(false);

        for (u8 i = 0; i < 4; i++)
        {
            CSpriteLayer@ s = this.getSpriteLayer("l"+i);
            if (s !is null) s.SetVisible(true);

            f32 deg = i%2==0?1:-1;
            if (i == 3) deg = b.getNetworkID()%2==0?0.25f:-0.25f;
            s.RotateByDegrees(deg,Vec2f_zero);
        }
    }

    const Vec2f aimPos = b.getPosition();

    CParticle@[] particleList;
    SColor col;
    b.get("ParticleList",particleList);
    b.get("colour", col);

    for(int a = 0; a < 3 + XORRandom(5); a++)
    {
        CParticle@ p = ParticlePixelUnlimited(getRandomVelocity(0,80,360) + aimPos, Vec2f(0,0), col,
            true);
            
        if (p !is null)
        {
            p.fastcollision = true;
            p.gravity = Vec2f(0,0);
            p.bounce = 0;
            p.Z = -10;
            p.timeout = 75;
            particleList.push_back(p);
        }
    }


    for(int a = 0; a < particleList.length(); a++)
    {
        CParticle@ particle = particleList[a];
        //check
        if(particle.timeout < 1)
        {
            particleList.erase(a);
            a--;
            continue;
        }

        //Gravity
        Vec2f tempGrav = Vec2f(0,0);
        tempGrav.x = -(particle.position.x - aimPos.x);
        tempGrav.y = -(particle.position.y - aimPos.y);
        tempGrav.RotateBy(-62);


        //Colour
        SColor col = particle.colour;
        col.setRed(col.getRed() - 1);
        col.setGreen(Maths::Clamp(col.getGreen() + 4, 0, 255));
        col.setBlue(col.getBlue() - 1);

        //set stuff
        particle.colour = col;
        particle.forcecolor = col;
        particle.gravity = tempGrav / 2000;

        //particleList[a] = @particle;

    }
    b.set("ParticleList",particleList);
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("circle_create.ogg",10,1.25f);
}
