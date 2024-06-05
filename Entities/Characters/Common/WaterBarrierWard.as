
void onTick(CBlob@ this)
{
    if (getMap() is null) return;
    if (this.get_bool("waterbarrier"))
    {
        CBlob@[] list;
        getMap().getBlobsInRadius(this.getPosition(), 40.0f, @list);

        for (u16 i = 0; i < list.length; i++)
        {
            CBlob@ b = list[i];
            if (b is null) continue;
            if (b.getTeamNum() == this.getTeamNum()) continue;

            if (b.hasTag("flesh"))
            {
                b.set_u32("in_water", getGameTime()+2);
            }
            else if (b.getVelocity().Length() > 1.5f ) b.setVelocity(b.getVelocity()*0.8f);
        }
    }
}