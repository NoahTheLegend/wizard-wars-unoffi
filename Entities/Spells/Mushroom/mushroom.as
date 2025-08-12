void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",300);
    this.set_s32("nextSpore",getGameTime());
    this.Tag("counterable");
    this.Tag("totem");
}

void onTick(CBlob@ this)
{
    if (this.getTickSinceCreated() == 1)
    {
        CBlob@[] bs;
        getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @bs);

        for (u32 i = 0; i < bs.length; i++)
        {
            CBlob@ blob = bs[i];

            if (blob !is null && blob.getTeamNum() == this.getTeamNum() && blob.getName() == "moss")
            {
                CPlayer@ owner = blob.getDamageOwnerPlayer();
                if (owner !is null && owner is this.getDamageOwnerPlayer())
                {
                    if (isClient())
                    {
                        for (int i = 0; i < 8+XORRandom(5); i++)
                        {
                            Vec2f vel(1.0f + XORRandom(10)*0.1f, 0);
                            vel.RotateBy(XORRandom(360));

                            CParticle@ p = ParticleAnimated(CFileMatcher("GenericSmoke"+(1+XORRandom(2))+".png").getFirst(), 
                                                            this.getPosition(), 
                                                            vel, 
                                                            float(XORRandom(360)), 
                                                            1.0f, 
                                                            4 + XORRandom(8), 
                                                            0.0f, 
                                                            false );

                            if (p !is null)
                            {
                                p.fastcollision = true;
                                p.scale = 1.0f - XORRandom(51) * 0.01f;
                                p.damping = 0.925f;
                                p.Z = 750.0f;
                                p.colour = SColor(255, 100+XORRandom(55), 200+XORRandom(55), 125+XORRandom(35));
                                p.forcecolor = SColor(255, 100+XORRandom(55), 200+XORRandom(55), 125+XORRandom(35));
                                p.setRenderStyle(RenderStyle::additive);
                            }
                        }
                    }

                    if (isServer())
                    {
                        CBlob@ mossy_golem = server_CreateBlob("mossygolem", this.getTeamNum(), this.getPosition() - Vec2f(0, 4));
                        if (mossy_golem !is null)
                        {
                            mossy_golem.SetFacingLeft(XORRandom(2) == 0);
                            mossy_golem.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
                            mossy_golem.server_SetTimeToDie(18+XORRandom(8)*0.1f);

                            mossy_golem.set_u16("owner_id", this.getDamageOwnerPlayer().getNetworkID());
                            mossy_golem.Tag("mg_owner" + this.getDamageOwnerPlayer().getNetworkID());
                        }

                        blob.server_Die();
                    }
                }
            }
        }
    }

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

void onDie(CBlob@ this)
{
    if (isServer())
    {
        if (this.hasTag("extra_damage"))
        {
            for (u8 i = 0; i < XORRandom(2) + 2; i++)
            {
                CBlob@ spore = createSporeshot(this);
                if (spore !is null)
                {
                    Vec2f vel = getRandomVelocity(0, 1.5f, 360);
                    spore.setVelocity(vel);
                    spore.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
                }
            }
        }
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