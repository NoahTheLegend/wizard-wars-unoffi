#define SERVER_ONLY

void onTick(CBlob@ this)
{
    if (this.hasTag("totally_dead"))
    {
        this.server_Die();
        this.getCurrentScript().runFlags |= Script::remove_after_this;
        return;
    }
    
    if (this.hasTag("mark_for_death"))
    {
        CShape@ shape = this.getShape();
        if (shape !is null)
        {
            shape.SetGravityScale(0.0f);
            shape.SetStatic(true);
            shape.SetRotationsAllowed(false);
            shape.server_SetActive(false);
            shape.getConsts().mapCollisions = false;
            shape.getConsts().collidable = false;
        }

        this.Tag("totally_dead");
        this.Tag("dead");
    }
}