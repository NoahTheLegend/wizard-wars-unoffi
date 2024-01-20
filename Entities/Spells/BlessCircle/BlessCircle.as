#include "Hitters.as";

void onInit(CBlob@ this)
{
    this.set_u8("frame", 0);
    this.Tag("magic_circle");
    this.SetLightRadius(effectRadius);
    this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);

    this.getSprite().SetRelativeZ(-10.1f);
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

    if(reverse && this.get_u8("frame") < 1) this.server_Die();
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
        this.RotateByDegrees((b.hasTag("fullCharge") ? rotateSpeed*2 : rotateSpeed) / (b.get_u8("despelled") + 1) ,Vec2f(0,0));
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
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("circle_create.ogg",10,1.25f);
}
