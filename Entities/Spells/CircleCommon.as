void onInit(CBlob@ this)
{
    this.getShape().SetGravityScale(0);
    this.set_u8("dispelled",0);
    this.set_s32("aliveTime",10);
    this.Tag("magic_circle");
    this.Tag("multi_dispell");
    this.Tag("no trampoline collision");

    this.getShape().SetStatic(true);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

void onTick(CBlob@ this)
{
    if(this.getTickSinceCreated() > this.get_s32("aliveTime") || this.get_u8("dispelled") >= 2)
        this.Tag("reverse");
}