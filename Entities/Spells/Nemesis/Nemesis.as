#include "TextureCreation.as";

const u8 appear_delay = 3;
const f32 dist_step = 24.0f;

Random@ _laser_r = Random(0x10001);

void onInit(CBlob@ this)
{
    this.set_s32("max_swords", 5);
    this.set_u32("start_time", getGameTime());
    this.set_u32("delay_time", 60);
    this.getShape().SetGravityScale(0.0f);

    this.set_string("ids", "");

    this.server_SetTimeToDie(3.0f);
    this.getSprite().SetZ(-5.0f);

    if (!isClient()) return;
    if (this is null) return;

    Setup(SColor(55, 255, 255, 255), "nemesis", false);
    int cb_id = Render::addBlobScript(Render::layer_prehud, this, "Nemesis.as", "laserEffects");
}

void onTick(CBlob@ this)
{
    if (this.getTickSinceCreated() < 6)
    {
        this.set_s32("swords", this.get_s32("max_swords"));
        return;
    }

    CSprite@ sprite = this.getSprite();
            if (sprite is null) return;

    s32 max = this.get_s32("max_swords");
    s32 swords = this.get_s32("swords");

    if (swords == 0 && this.get_u32("delayed") < getGameTime())
    {
        string[] spl = this.get_string("ids").split(" ");
        for (u8 i = 0; i < spl.length; i++)
        {
            u16 id = parseInt(spl[i]);
            CBlob@ sword = getBlobByNetworkID(id);
            if (sword is null) continue;

            sword.Tag("primed");
            sword.setVelocity(-sword.get_Vec2f("nemesis_vel")/20);
            sword.server_SetTimeToDie(10.0f);
            sword.getShape().getConsts().mapCollisions = false;
        }

        if (getGameTime()%2==0 && (this.get_u32("stop_sound") > getGameTime() || !this.hasTag("ss")))
        {

            sprite.PlaySound("swordlaunch.ogg", 1.0f, 1.33f+XORRandom(max*2)*0.01f);
            if (!this.hasTag("ss"))
            {
                this.set_u32("stop_sound", getGameTime()+10);
                this.Tag("ss");
            }
        }
    }
    else if (this.getTickSinceCreated() % appear_delay == 0 && swords > 0)
    {
        Vec2f tpos = this.getPosition();

        f32 extra_dist_step = (this.getPosition().y/16);
        Vec2f top_pos = Vec2f(tpos.x - (max*(dist_step+extra_dist_step))/2 + ((dist_step+extra_dist_step)/2) + (max-swords)*(dist_step+extra_dist_step), 32);
        Vec2f dir = top_pos-tpos;
        //dir.Normalize();

        this.set_u32("delayed", getGameTime()+this.get_u32("delay_time"));

        if (isServer())
        {
            this.server_SetTimeToDie(3.0f);
			f32 orbDamage = 1.5f;

			Vec2f orbPos = top_pos;
			Vec2f orbVel = (dir);
			//orbVel.Normalize();

			CBlob@ orb = server_CreateBlob("impaler");
			if (orb !is null)
			{
				orb.set_f32("damage", orbDamage);
                orb.setAngleDegrees(180-orbVel.Angle());

				orb.IgnoreCollisionWhileOverlapped(this);
				orb.server_setTeamNum(this.getTeamNum());
				orb.setPosition(orbPos);
                orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
                orb.Tag("nemesis");

                orb.set_Vec2f("nemesis_vel", orbVel);
                orb.Tag("nemesis_proj");
                orb.Sync("nemesis_proj", true);
                this.set_string("ids", this.get_string("ids")+orb.getNetworkID()+" ");
                this.Sync("ids", true);
			}
        }
        if (isClient())
        {
            sprite.PlaySound("sidewind_init.ogg", 0.66f, 1.25f);
        }

        this.add_s32("swords", -1);
    }
}

void onInit(CShape@ this)
{
    this.SetStatic(true);
    this.getConsts().collidable = false;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob ){
    return false;
}

void laserEffects(CBlob@ this, int id)
{
    if (this.getTickSinceCreated() < 6) return;
    Vec2f thisPos = this.getPosition();
	
    s32 max = this.get_s32("max_swords");
    s32 swords = this.get_s32("swords");
    u32 gt = getGameTime();
    u32 start_time = this.get_u32("start_time");

    int start = (gt-start_time)/3-appear_delay*2;
    for (int i = start > 0 ? start : 0; i < max-swords; i++)
    {
        Vec2f aimPos;
	    Vec2f aimVec = aimPos - thisPos;
	    Vec2f aimNorm = aimVec;
	    aimNorm.Normalize();

	    Vec2f currSegPos = thisPos;				
	    Vec2f prevSegPos = aimPos;

	    Vec2f followVec = currSegPos - prevSegPos;
	    Vec2f followNorm = followVec;
	    followNorm.Normalize();
    
	    f32 followDist = followVec.Length();
	    f32 laserLength = followDist;
        f32 deg = 0;
        u32 tick = 0;
    
	    Vec2f[] v_pos;
	    Vec2f[] v_uv;

        string[] spl = this.get_string("ids").split(" ");
        for (int j = 0; j < spl.length; j++)
        {
            if (i < spl.length)
            {
                u16 id = parseInt(spl[i]);
                CBlob@ sword = getBlobByNetworkID(id);
                if (sword !is null)
                {
                    aimPos = sword.getPosition();
                    deg = ((aimPos - thisPos).getAngle()+180) * 360.0f;
                    sword.setAngleDegrees(-deg/360.0f);
                    tick = sword.getTickSinceCreated();

                    if (!this.exists("temp_deg"+i))
                    {
                        this.set_f32("temp_deg"+i, 270*360.0f);
                    }

                    f32 temp_deg = this.get_f32("temp_deg"+i);
                    deg = Maths::Lerp(temp_deg, deg, 0.25f);
                    this.set_f32("temp_deg"+i, deg);

                    f32 size = 0.5f;

	                v_pos.push_back(currSegPos + Vec2f(-followDist * laserLength,-size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(0,0));//Top left?
	                v_pos.push_back(currSegPos + Vec2f( followDist * laserLength,-size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(1,0));//Top right?
	                v_pos.push_back(currSegPos + Vec2f( followDist * laserLength, size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(1,1));//Bottom right?
	                v_pos.push_back(currSegPos + Vec2f(-followDist * laserLength, size).RotateBy(-deg/360.0f, Vec2f(0,0))); v_uv.push_back(Vec2f(0,1));//Bottom left?

	                Render::Quads("nemesis", -6.0f, v_pos, v_uv);

	                v_pos.clear();
	                v_uv.clear();
                }
            }
        }
    }
}