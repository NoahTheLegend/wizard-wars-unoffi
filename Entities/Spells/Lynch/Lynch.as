#include "TeamColour.as";
#include "Hitter.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.getConsts().mapCollisions = false;
	shape.getConsts().collidable = false;
	
	this.addCommandID("sync_id");
    this.addCommandID("sfx");

	//default values
	if (!this.exists("lifetime")) this.set_u16("lifetime", 90);
	this.set_u16("trapped_id", 0);
	this.getShape().SetStatic(true);

    this.set_Vec2f("smashtoparticles_grav", Vec2f(0,0.1f));
    this.set_Vec2f("smashtoparticles_grav_rnd", Vec2f(0, 0.2f));

    this.set_u8("state", 0);
    this.set_u8("spawned_swords", 0);
    this.set_u32("next_sword", 0);

    u16[] swords;
    this.set("swords", swords);
}

void onInit(CSprite@ this)
{
    this.SetZ(-1.0f);
    CSpriteLayer@ l = this.addSpriteLayer("l", "Lynch.png", 64, 64);
    if (l !is null)
    {
        //l.setRenderStyle(RenderStyle::outline);
        l.SetRelativeZ(-2.0f);

        Animation@ anim = l.addAnimation("default", this.animation.time, false);
        int[] frames = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
        
        anim.AddFrames(frames);
        l.SetAnimation(anim);
    }
}

const u8 spawn_delay = 3;
const u8 anim_time = 3;

void onTick(CBlob@ this)
{
    if (this.get_u8("dispelled") >= 2) this.Tag("mark_for_death");
    if (this.getTickSinceCreated() < 16 * anim_time) return;
    
    f32 rad = this.getRadius() * 2 + 4.0f;
	CMap@ map = getMap();

    f32 dmg = this.get_f32("damage");
	
	if (this.get_u16("trapped_id") > 0)
	{
		this.Tag("cantparry");
		
		CBlob@ trapped = getBlobByNetworkID(this.get_u16("trapped_id"));
		if (trapped !is null)
		{
            //if (trapped.getDistanceTo(this) > rad * 2)
            //{
            //    this.set_u16("trapped_id", 0);
            //    this.set_u8("state", 0);
            //    SyncId(this, 0);
            //    if (isServer())
            //    {
            //        ClearSwords(this);
            //        this.server_Hit(trapped, trapped.getPosition(), Vec2f_zero, dmg, Hitters::fall, true);
            //        return;
            //    }
            //}

            Vec2f dir = this.getPosition() - trapped.getPosition();
            f32 dist = dir.Length();

            dir.Normalize();
            f32 mod = Maths::Lerp(dist, 0, 0.25f);

			trapped.setVelocity(dir * mod);

            this.set_u8("state", 1);
		}
		else this.set_u16("trapped_id", 0);
	}

	if (!isServer()) return;
    u8 state = this.get_u8("state");
    u8 launch_delay = this.get_u8("launch_delay");

    if (state == 0)
    {
        this.set_u32("launch_time", getGameTime() + launch_delay);
	    CBlob@[] chb;
        map.getBlobsInRadius(this.getPosition(), rad, @chb);

        for (u16 i = 0; i < chb.length; i++)
	    {
	    	CBlob@ b = chb[i];
	    	if (b is null || !b.hasTag("player")) continue;
	    	if (isEnemy(this, b))
	    	{
	    		this.set_u16("trapped_id", b.getNetworkID());
	    		SyncId(this, b.getNetworkID());

                this.set_u32("next_sword", getGameTime() + spawn_delay);

	    		break;
	    	}
	    }
    }
    else if (state == 1 && this.get_u16("trapped_id") != 0)
    {
        this.set_u8("state", 1);

        u32 next_sw = this.get_u32("next_sword");
        bool spawn_sword = next_sw != 0 && next_sw <= getGameTime();
        if (spawn_sword) this.set_u32("next_sword", getGameTime() + spawn_delay);

        u32 launch_time = this.get_u32("launch_time");

        u16[]@ swords;
        if (this.get("swords", @swords) && this.get_u8("spawned_swords") < 4 && spawn_sword)
        {
            Vec2f bpos =  this.getPosition() + Vec2f(0, -64.0f).RotateBy(this.get_u8("spawned_swords") * 90);
            CBlob@ b = server_CreateBlob("executioner", this.getTeamNum(), bpos);
            if (b !is null)
            {
                Vec2f dir = b.getPosition() - this.getPosition();
                f32 angle = -dir.Angle() + 180;

                b.setAngleDegrees(angle);
                b.set_f32("damage", dmg);
                b.set_f32("lifetime", this.getTimeToDie());

                b.Tag("aimMode");

                b.Tag("no_map_collision");
                b.Sync("no_map_collision", true);

                b.Tag("no_player_control");
                b.Sync("no_player_control", true);
                b.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());

                this.add_u8("spawned_swords", 1);
                swords.push_back(b.getNetworkID());
            }
        }
        this.set("swords", @swords);

        bool launch = launch_time <= getGameTime() && launch_time != 0;
        CBlob@ trapped = getBlobByNetworkID(this.get_u16("trapped_id"));
		if (trapped is null && !launch)
		{
            this.set_u8("state", 0);
            state = 0;

            ClearSwords(this);
        }
        else if (launch && !this.hasTag("launched"))
        {
            this.Tag("launched");

            u16[]@ swords;
            this.get("swords", @swords);
            for (u8 i = 0; i < swords.size(); i++)
            {
                CBlob@ b = getBlobByNetworkID(swords[i]);
                if (b !is null)
                {
                    b.Tag("cruiseMode");
                    b.Untag("aimMode");
                    b.setVelocity(Vec2f(15.0f, 0).RotateBy(b.getAngleDegrees()));
                }
            }

            CBitStream params;
            this.SendCommand(this.getCommandID("sfx"), params);
            this.server_SetTimeToDie(0.25f);
        }
    }
}

void SyncId(CBlob@ this, u16 id)
{
    if (isServer())
	{
		CBitStream params;
		params.write_u16(id);
		this.SendCommand(this.getCommandID("sync_id"), params);	
	}
}

void onDie(CBlob@ this)
{
    if (isServer())
    {
        ClearSwords(this);
    }

	this.getSprite().Gib();
}

void ClearSwords(CBlob@ this)
{
    this.set_u8("spawned_swords", 0);
    this.set_u32("next_sword", 0);
            
    u16[]@ swords;
    if (this.get("swords", @swords))
    {
        for (u8 i = 0; i < swords.size(); i++)
        {
            CBlob@ b = getBlobByNetworkID(swords[i]);
            if (b !is null)
            {
                b.Tag("mark_for_death");
            }
        }
    }
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (isClient())
    {
        if (cmd == this.getCommandID("sync_id"))
	    {
	    	u16 id = params.read_u16();
	    	this.set_u16("trapped_id", id);
        }
        else if (cmd == this.getCommandID("sfx"))
        {
            this.getSprite().PlaySound("execruise.ogg", 1.5f);
        }
    }
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return ( !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& (friend is null
			|| friend.getTeamNum() != this.getTeamNum()
		)
	);
}

void onTick(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;

    if (sprite.animation.ended())
	{
        u8 rnd = XORRandom(100);
		SColor col = SColor(255, 100+rnd, 100+rnd, 100+rnd);
		
		u8 t = this.getTeamNum();
		for (u8 i = 0; i < 4; i++)
		{
			Vec2f ppos = this.getPosition() + Vec2f(0, -this.getRadius() / 2).RotateBy(i * 90);
			Vec2f pvel = ppos - this.getPosition();
            pvel.Normalize();
            pvel *= 3.0f;
			
			CParticle@ p = ParticlePixelUnlimited(ppos, pvel, col, true);
    		if(p !is null)
			{
    			p.fastcollision = true;
    			p.timeout = 25;
    			p.damping = 0.95f + XORRandom(6)*0.001f;
				p.gravity = Vec2f(0,0);
				p.collides = false;
				p.Z = 510.0f;
				p.setRenderStyle(RenderStyle::additive);
			}
		}
	}
    
    f32 amplitude = 0.05f;
    f32 power = 7.5f;
    f32 factor = Maths::Sin(getGameTime() * amplitude) * power;
    factor = Maths::Abs(factor);

    f32 ts_factor = Maths::Min(1.0f, this.getTickSinceCreated() / 60.0f);
    factor *= ts_factor;

    CSpriteLayer@ l = sprite.getSpriteLayer("l");
    if (l is null) return;
    
    l.animation.frame = Maths::Min(15, sprite.animation.frame+1);

    f32 distortion = 1.0f;
    f32 val = distortion * factor;
    
    f32 lerp = 0.25f;
    Vec2f old_offset = this.get_Vec2f("old_offset");
    Vec2f new_offset = Vec2f_lerp(old_offset, Vec2f(XORRandom(val*10)*0.1f - val/2, XORRandom(val*10)*0.1f - val/2), lerp);
    
    l.ResetTransform();
    l.SetOffset(new_offset);

    this.set_Vec2f("old_offset", new_offset);
}