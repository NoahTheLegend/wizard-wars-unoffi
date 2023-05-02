#include "Hitters.as"
#include "EffectMissileEnum.as";

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",900);
    this.set_s32("nextorb", getGameTime());
    //this.Tag("counterable");
    this.Tag("totem");
    this.Tag("cantparry");
    this.set_u8("despelled", 0);
    this.set_u16("fire_delay", 120);
    this.set_f32("max_dist", 64.0f);

    this.Tag("exploding");
    this.set_string("custom_explosion_sound", "OrbExplosion.ogg");
	this.set_bool("fl", XORRandom(2)==1?true:false);

    this.getSprite().PlaySound("WizardShoot.ogg", 2.0f, 0.65f);
    this.addCommandID("sync");
    if (isClient())
    {
        CBitStream params;
        params.write_bool(true);
        this.SendCommand(this.getCommandID("sync"), params);
    }

    this.setPosition(Vec2f(Maths::Ceil(this.getPosition().x/8)*8-4.0f, this.getPosition().y));

    CSprite@ thisSprite = this.getSprite();
    //thisSprite.SetEmitSound("MolotovBurning.ogg");
    thisSprite.SetEmitSoundVolume(1.0f);
    thisSprite.SetEmitSoundSpeed(0.75f);
    thisSprite.SetEmitSoundPaused(false);
    thisSprite.SetZ(-10.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync"))
    {
        bool init = params.read_bool();
        if (init && isServer())
        {
            CBitStream stream;
            stream.write_bool(false);
            stream.write_u16(this.get_f32("max_dist"));
        }
        else if (!init && isClient())
        {
            u16 val = params.read_u16();
            this.set_f32("max_dist", val);
        }
    }
}

void onTick(CBlob@ this)
{
    if(this.get_u8("despelled") >= 2 || this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.server_Die();
    }

    bool had_first = false;
    u16 first = 0;
    u16 last = 0;

    for (u16 i = 1; i < this.get_f32("max_dist")/4; i++)
    {
        HitInfo@[] infos;

        Vec2f startPos = this.getPosition() - Vec2f(0, 16.0f) + Vec2f(-this.get_f32("max_dist")+(this.get_f32("max_dist")/8*i) / ((this.get_f32("max_dist")/64.0f)), 0);
        if (!getMap().getHitInfosFromRay(startPos, 90, 64.0f, this, @infos)) continue;

        CSpriteLayer@ segment = this.getSprite().getSpriteLayer("segment"+i);
        if (segment is null) continue;

        Vec2f showPos = Vec2f(0,0);

        bool doContinue = false;
        for (u16 j = 0; j < infos.length; j++)
        {
            if (doContinue) continue;

            HitInfo@ info = infos[j];
            if (info is null || info.blob !is null) continue;

            if (info.tileOffset != 0 && info.tileOffset <= getMap().tilemapwidth*getMap().tilemapheight)
            {
                showPos = getMap().getTileSpacePosition(info.tileOffset)*8-Vec2f(0,Maths::ATan(Maths::Sin(((this.get_bool("fl")?-1.0f:1.0f)*getGameTime()+((i-1.5f)%3.0f*2.25f))*0.15f)*(1+3*Maths::Cos(getGameTime()*0.065f))));
                doContinue = true;
            }
        }
        // iterate again to overwrite showPos
        for (u16 j = 0; j < infos.length; j++)
        {
            HitInfo@ info = infos[j];
            if (info.blob is null) continue;
            
            if (info.blob.getTeamNum() != this.getTeamNum() && info.blob.hasTag("player"))
            {
                if (info.blob.get_u16("slowed") < 45 && getGameTime()%3==0 && info.blob.isOnGround())
                {
                    info.blob.set_u16("slowed", 45);
                    info.blob.set_u16("heavy", 15);
                }
            }
        }

        if (showPos.x == 0 && showPos.y == 0)
        {
            segment.SetVisible(false);
            segment.SetOffset(Vec2f(0,0));
            continue;
        }

        if (!had_first)
        {
            segment.SetFrameIndex(0);
            had_first = true;
            first = i;
        }
        else
        {
            segment.SetFrameIndex(2);

            if (i != first && last != first && last != 0)
            {
                
                CSpriteLayer@ prev = this.getSprite().getSpriteLayer("segment"+last);
                if (prev !is null)
                {
                    prev.SetFrameIndex(1);
                }
            }
            last = i;
        }
        segment.SetVisible(true);

        segment.SetOffset(Vec2f(-1 * Maths::Ceil((showPos-this.getPosition()).x/8)*8, (showPos-this.getPosition()).y-1));
    }

    for (u8 i = 0; i < 3; i++)
    {
        CSpriteLayer@ gem = this.getSprite().getSpriteLayer("gem"+i);
        if (gem !is null)
        {
            gem.SetVisible(true);
            Vec2f offset = Vec2f(0, -18.0f);
            Vec2f rotation = Vec2f(0,-8).RotateBy(i*120, Vec2f(0,-2));
            Vec2f fin = (offset+rotation).RotateBy(getGameTime()%360, Vec2f(0, -20));
            gem.SetOffset(Vec2f(fin.x*1.25f, fin.y*0.33f) - Vec2f(0, 11.0f));
            gem.SetRelativeZ(fin.y > -16.0f ? 20.0f : fin.y);
        }
    }

    //for (u16 i = 0; i < getPlayersCount(); i++)
    //{
    //    if (getPlayer(i) is null || getPlayer(i).getBlob() is null) continue;
    //}
}
void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

void onInit(CSprite@ this)
{
    this.getBlob().set_s32("frame",0);
    CBlob@ blob = this.getBlob();

    for (u16 i = 0; i < 128.0f/4; i++)
    {
        CSpriteLayer@ segment = this.addSpriteLayer("segment"+i, "earthsegment.png", 8, 8);
        if (segment !is null)
        {
            Animation@ anim = segment.addAnimation("default", 0, false);
            if (anim !is null)
            {
                int[] frames = {0,1,2};
                anim.AddFrames(frames);
                segment.SetAnimation(anim);
                segment.SetFrameIndex(1);
            }
            segment.SetVisible(false);
            segment.SetRelativeZ(-15.0f);
        }
    }

    for (u8 i = 0; i < 3; i++)
    {
        CSpriteLayer@ gem = this.addSpriteLayer("gem"+i, "gems.png", 10, 8);
        if (gem !is null)
        {
            Animation@ anim = gem.addAnimation("default", 0, false);
            if (anim !is null)
            {
                int[] frames = {0,1,2};
                anim.AddFrames(frames);
                gem.SetAnimation(anim);
                gem.SetFrameIndex(i);
                gem.SetVisible(false);
                gem.SetRelativeZ(5.0f);
            }
        }
    }
}

void onTick(CSprite@ this)
{
    this.SetOffset(Vec2f(0,-15));
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}

void onDie(CBlob@ this)
{
    this.getSprite().PlaySound("ManaDraining.ogg", 0.75f, 1.15f + XORRandom(16)*0.01f);
    if ( this.hasTag("replaced")) return;
    if (!isServer()) return;

    u8 rand = XORRandom(3);
    u16 randdeg = XORRandom(360);
    f32 vel = 3.5f;
    Vec2f orbPos = this.getPosition()-Vec2f(0,16);
	{
	    CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
	    if (orb !is null)
	    {
            Vec2f orbVel = Vec2f(0,-vel).RotateBy(randdeg+120*rand);
            if (XORRandom(2)==0)
            {
	    	    orb.set_u8("effect", haste_effect_missile);
	    	    orb.set_u16("effect_time", 900);
            }
            else
            {
                orb.set_u8("effect", airblastShield_effect_missile);
                orb.set_u16("effect_time", 900);
            }

	    	orb.IgnoreCollisionWhileOverlapped( this );
	    	orb.SetDamageOwnerPlayer( this.getPlayer() );
	    	orb.setVelocity( orbVel );
	    }
    }
    {
        CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
	    if (orb !is null)
	    {
            Vec2f orbVel = Vec2f(0,-vel).RotateBy(randdeg+120+120*rand);
            if (XORRandom(2)==0)
            {
	    	    orb.set_u8("effect", regen_effect_missile);
                orb.set_u16("effect_time", 300);
            }
            else
            {
                orb.set_u8("effect", fireProt_effect_missile);
                orb.set_u16("effect_time", 900);
            }

	    	orb.IgnoreCollisionWhileOverlapped( this );
	    	orb.SetDamageOwnerPlayer( this.getPlayer() );
	    	orb.setVelocity( orbVel );
	    }
    }
    {
        CBlob@ orb = server_CreateBlob( "effect_missile", this.getTeamNum(), orbPos ); 
	    if (orb !is null)
	    {
            Vec2f orbVel = Vec2f(0,-vel).RotateBy(randdeg+240+120*rand);
            //if (XORRandom(2)==0)
            {
	    	    orb.set_u8("effect", mana_effect_missile);
                orb.set_u8("mana_used", 1);
	    	    orb.set_u8("caster_mana", 2);
                orb.set_u8("direct_restore", 6+XORRandom(3));
            }
            //else
            //{
            //    orb.set_u8("effect", manaburn_effect_missile);
            //    orb.set_u16("effect_time", 450);
            //}

	    	orb.IgnoreCollisionWhileOverlapped( this );
	    	orb.SetDamageOwnerPlayer( this.getPlayer() );
	    	orb.setVelocity( orbVel );
	    }
    }
}