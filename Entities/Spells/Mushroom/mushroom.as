

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",300);
    this.set_s32("nextSpore",getGameTime());
    this.Tag("counterable");
    this.Tag("totem");
}

void onTick(CBlob@ this)
{

    if(this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.Tag("mark_for_death");
    }

    if(getGameTime() >= this.get_s32("nextSpore"))
    {
        createSporeshot(this);
        this.set_s32("nextSpore",getGameTime() + 150);
    }

}

CBlob@ createSporeshot(CBlob@ this)
{
    if(!isServer()) return null;
    CBlob@ spore = server_CreateBlob("sporeshot",this.getTeamNum(),this.getPosition() + Vec2f(0,-8));
    spore.setVelocity(getRandomVelocity(180,2.0f,180));
    spore.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

    return spore;
}




void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

void onInit(CSprite@ this)
{
    this.ScaleBy(Vec2f(0.75,0.75));
    this.getBlob().set_s32("frame",0);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}