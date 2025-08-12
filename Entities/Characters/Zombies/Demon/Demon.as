#include "SpellUtils.as";
#include "TextureCreation.as";

/*
/rcon CBlob@ b=server_CreateBlob('demonbig',1,Vec2f_zero);b.set_u16('ownerplayer_id',getPlayer(1).getNetworkID());b.server_SetPlayer(getPlayer(0));
CBlob@ k=getBlobByName('knight');CBlob@ w=server_CreateBlob('warlock',0,k.getPosition());w.server_SetPlayer(k.getPlayer());k.server_Die());
*/

const f32 max_vel = 6.0f;
const f32 acceleration = 1.0f;
const f32 max_range = 96.0f;
const f32 pull_radius = 64.0f;
const int max_charges = 12;
const int max_charges_big = 20;
const int fire_rate = 3;
const int cost_shield = 2; // how many charges per one shield
const int angle_rnd = 5;
const f32 heal_amount = 1.5f;

void onInit(CBlob@ this)
{
    this.Tag("counterable");
	this.Tag("phase through spells");
	this.Tag("no trampoline collision");
	this.Tag("cantparry");
	this.Tag("ignore_effects");
	this.Tag("hold_gravestone");
	this.Tag("follower");

	this.Tag("ignore_scoreboard");
	this.Tag("player");
	this.Tag("flesh");

	this.set_Vec2f("smashtoparticles_grav", Vec2f(0, -0.05f));
	this.set_Vec2f("smashtoparticles_grav_rnd", Vec2f(0.1, 0));

	this.getShape().getConsts().mapCollisions = true;
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetRotationsAllowed(false);

	this.set_bool("big", this.getName() == "demonbig");
	this.set_u16("charges", 0);

	this.addCommandID("restore_caster");

	if (!isClient()) return;
	//Vec2f frameSize = Vec2f(32, 48);

	//SetupImage("Demon.png", SColor(255, 255, 255, 255), "b_demon_rend0", false, false, Vec2f(0, 0), frameSize);
	//SetupImage("Demon.png", SColor(255, 255, 255, 255), "b_demon_rend1", false, false, Vec2f(32, 0), frameSize);
	//SetupImage("Demon.png", SColor(255, 255, 255, 255), "b_demon_rend2", false, false, Vec2f(64, 0), frameSize);
	//SetupImage("Demon.png", SColor(255, 255, 255, 255), "b_demon_rend3", false, false, Vec2f(0, 48), frameSize);
	//SetupImage("Demon.png", SColor(255, 255, 255, 255), "b_demon_rend4", false, false, Vec2f(32, 48), frameSize);
	//SetupImage("Demon.png", SColor(255, 255, 255, 255), "b_demon_rend5", false, false, Vec2f(64, 48), frameSize);

	//SetupImage("Demon_r.png", SColor(255, 255, 255, 255), "r_demon_rend0", false, false, Vec2f(0, 0), frameSize);
	//SetupImage("Demon_r.png", SColor(255, 255, 255, 255), "r_demon_rend1", false, false, Vec2f(32, 0), frameSize);
	//SetupImage("Demon_r.png", SColor(255, 255, 255, 255), "r_demon_rend2", false, false, Vec2f(64, 0), frameSize);
	//SetupImage("Demon_r.png", SColor(255, 255, 255, 255), "r_demon_rend3", false, false, Vec2f(0, 48), frameSize);
	//SetupImage("Demon_r.png", SColor(255, 255, 255, 255), "r_demon_rend4", false, false, Vec2f(32, 48), frameSize);
	//SetupImage("Demon_r.png", SColor(255, 255, 255, 255), "r_demon_rend5", false, false, Vec2f(64, 48), frameSize);

	//int cb_id = Render::addBlobScript(Render::layer_prehud, this, "Demon.as", "laserEffects");
}

void onTick(CBlob@ this)
{
	Vec2f aimpos = getControls().getMouseWorldPos();
	Vec2f pos = this.getPosition();

	u16 ownerplayer_id = this.exists("ownerplayer_id") ? this.get_u16("ownerplayer_id") : 0;
	if (ownerplayer_id == 0)
	{
		this.server_Die();
		return;
	}

	this.SetFacingLeft(aimpos.x < pos.x);
	CPlayer@ damageOwner = getPlayerByNetworkId(ownerplayer_id);

	if (damageOwner is null)
	{
		this.server_Die();
		return;
	}

	CBlob@ owner = damageOwner.getBlob();
	if (owner is null)
	{
		this.server_Die();
		return;
	}

	this.Tag("demon_of_"+owner.getNetworkID());
	if (isServer())
	{
		if (this.getPlayer() is null && this.getTickSinceCreated() > 30)
		{
			this.server_Die();
			return;
		}

		if (!this.exists("rope_id"))
		{
			CBlob@ rope = server_CreateBlob("rope", this.getTeamNum(), pos);
			if (rope !is null)
			{
				this.set_u16("rope_id", rope.getNetworkID());
				this.Sync("rope_id", true);
			}
		}

		Vec2f aimpos = this.getAimPos();
		Vec2f aimNorm = aimpos - pos;
		aimNorm.Normalize();
		
		u16 charges = this.get_u16("charges");
		if (charges > max_charges)
		{
			charges = max_charges;
			this.set_u16("charges", charges);
		}

		if (this.isKeyPressed(key_action1) && this.getTickSinceCreated() % fire_rate == 0 && charges > 0)
		{
			Vec2f offset = Vec2f(2 - XORRandom(4), 2 - XORRandom(4));
			Vec2f orbpos = pos + offset;
			Vec2f dir = aimpos - pos;
			dir.Normalize();

			CBlob@ orb = server_CreateBlob("bloodbolt", this.getTeamNum(), orbpos);
			if (orb !is null)
			{
				orb.set_Vec2f("dir", dir);

				orb.SetDamageOwnerPlayer(this.getPlayer());
				orb.server_SetTimeToDie(2.0f);

				orb.set_f32("damage", 0.4f);
				orb.set_f32("acceleration", this.get_bool("big") ? 16.0f : 12.0f);
				orb.set_u32("acceleration_tsc_mod", 30);
				orb.set_f32("max_speed", max_vel * 4.0f);

				orb.setAngleDegrees(-dir.Angle());
			}

			charges -= 1;
		}
		else if (this.isKeyJustPressed(key_action2) && charges >= cost_shield)
		{
			Vec2f shieldPos = pos + aimNorm * 16.0f;
			CBlob@ shield = server_CreateBlob("demonbarrier", this.getTeamNum(), shieldPos);
			if (shield !is null)
			{
				shield.SetDamageOwnerPlayer(this.getPlayer());
				shield.setAngleDegrees(-aimNorm.Angle()+90.0f + XORRandom(angle_rnd * 2) - angle_rnd);
			}

			charges -= cost_shield;
		}
		this.set_u16("charges", charges);
	}

	if (this.exists("rope_id") && this.get_u16("rope_id") != 0)
	{
		CBlob@ rope = getBlobByNetworkID(this.get_u16("rope_id"));
		if (rope is null)
		{
			this.server_Die();
			return;
		}

		rope.setPosition(pos);
		rope.set_bool("render", true);
		rope.server_SetTimeToDie(1.0f);

		rope.set_Vec2f("firstPos", owner.getPosition());
		rope.set_Vec2f("lastPos", pos);

		rope.Sync("render", true);
		rope.Sync("firstPos", true);
		rope.Sync("lastPos", true);
	}

	Vec2f vel = this.getVelocity();
	f32 vel_length = vel.Length();
	
	Vec2f inputVel(0, 0);

	if (this.isKeyPressed(key_left))  inputVel.x -= 1;
	if (this.isKeyPressed(key_right)) inputVel.x += 1;
	if (this.isKeyPressed(key_up))    inputVel.y -= 1;
	if (this.isKeyPressed(key_down))  inputVel.y += 1;

	if (inputVel.LengthSquared() > 0)
	{
		inputVel.Normalize();
		inputVel *= acceleration;

		Vec2f newVel = vel + inputVel;
		f32 newVelLength = newVel.Length();

		if (newVelLength > max_vel)
		{
			newVel.Normalize();
			newVel *= max_vel;
		}

		this.setVelocity(newVel);
	}
	else
	{
		this.setVelocity(vel * 0.95f);
	}

	if (pos.y + vel.y > getMap().tilemapheight * 8 - 16.0f)
	{
		this.setVelocity(Vec2f(vel.x, 0));
		this.setPosition(Vec2f(pos.x, getMap().tilemapheight * 8 - 16.0f));
	}

	Vec2f dir = owner.getPosition() - pos;
	f32 dist = dir.Length();
	dir.Normalize();

	if (dist > max_range)
	{
		this.setPosition(owner.getPosition() - dir * max_range);
		this.AddForce(dir * this.getMass() * 2);
	}
	else if (dist > pull_radius)
	{
		dist -= pull_radius;
		f32 pull_mod = Maths::Min(dist / (max_range - pull_radius), 1.0f);
		this.AddForce(dir * this.getMass() * pull_mod * 0.1f);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u16 customData)
{
	if (isClient() && damage > 0.1f)
	{
		this.getSprite().PlaySound("DemonHit.ogg", 1.0f, 1.0f);
	}

	return damage;
}

void onDie(CBlob@ this)
{
	if (!isClient()) return;
	{
		CBlob@ rope = getBlobByNetworkID(this.get_u16("rope_id"));
		if (rope !is null) rope.server_Die();

		u16 ownerplayer_id = this.exists("ownerplayer_id") ? this.get_u16("ownerplayer_id") : 0;
		if (ownerplayer_id != 0)
		{
			CPlayer@ player = getPlayerByNetworkId(ownerplayer_id);
			CBlob@ b = player !is null ? player.getBlob() : null;

    		if (b !is null && !this.hasTag("counterspelled"))
    		{
    		    CBitStream params;
				params.write_u16(b.getNetworkID());
				this.SendCommand(this.getCommandID("restore_caster"), params);
    		}
		}
	}

	if (!isClient()) return;

	this.getSprite().PlaySound("DemonDie.ogg", 0.75f, 1.0f);
	this.getSprite().PlaySound("chainrattle_end.ogg", 1.0f, 1.0f);
	//CParticle@ p = ParticleAnimated( "MissileFire3.png", this.getPosition() + random, Vec2f(0,0), float(XORRandom(360)), 1.0f, 2 + XORRandom(3), 0.0f, false );
	CParticle@ p = ParticleAnimated("DarkBubble.png", this.getPosition(), Vec2f_zero, XORRandom(360), 1.0f, 3, 0, false);
	if (p !is null)
	{
		p.fastcollision = true;
		p.collides = false;
		p.deadeffect = -1;
		p.Z = -25.0f;
	}
}

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	this.PlaySound("DemonSpawn.ogg", 0.75f, 1.0f);
	this.PlaySound("chainrattle_start", 1.0f, 1.0f);

	for (u16 i = 0; i < max_charges; i++) // 2 front, 2 back shards
    {
        CSpriteLayer@ shard = this.addSpriteLayer("shard"+i, "Demon.png", 16, 16);
        if (shard !is null)
        {
            shard.SetRelativeZ(1.0f);

            Animation@ anim = shard.addAnimation("default", 0, false);
            Animation@ animback = shard.addAnimation("defaultback", 0, false);

            if (anim !is null && animback !is null)
            {
                int[] frames = {56, 57, 58, 59};
                int[] framesback = {60, 61, 62, 63};

                anim.AddFrames(frames);
                animback.AddFrames(framesback);

				u16 rnd = XORRandom(4);
				anim.frame = rnd;
				animback.frame = rnd;

				blob.set_u16("shard_frame"+i, rnd);

                shard.SetAnimation(anim);
				shard.SetIgnoreParentFacing(true);
            }

            shard.SetVisible(false);
        }
    }
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

    this.SetEmitSound("chainrattle_loop3.ogg");
    this.SetEmitSoundPaused(false);
	
	Vec2f vel = blob.getVelocity();
	f32 mod = Maths::Min(vel.Length() / 4.0f, 1.0f);

	this.SetEmitSoundVolume(mod * 0.25f);
	this.SetEmitSoundSpeed(1.0f);
	this.SetAnimation(blob.getVelocity().Length() < 0.1f ? "default" : "fly");

	u16 charges = blob.get_u16("charges");
	bool fl = blob.isFacingLeft();

	bool big = blob.get_bool("big");
	if (getGameTime() % 2 == 0)
    {
		string side = fl ? "_l" : "_r";
        CParticle@ p = ParticleAnimated(big ? "DemonBigParticle"+side+".png" : "DemonParticle"+side+".png", blob.getPosition(), Vec2f_zero, 0, 1.0f, 3, 0.0f, true);
	    if (p !is null)
	    {
	    	p.bounce = 0;
        	p.collides = false;
			p.fastcollision = true;
            p.growth = -0.01f;
	    	p.Z = 500.0f;
	    	p.gravity = Vec2f_zero;
	    	p.deadeffect = -1;
            p.setRenderStyle(RenderStyle::additive);
	    }
    }

    for (u16 i = 0; i < max_charges; i++)
    {
        CSpriteLayer@ shard = this.getSpriteLayer("shard"+i);
        if (shard !is null)
        {
            shard.SetVisible(i < charges);
			shard.SetFacingLeft(true);

            f32 x = Maths::Round(Maths::Sin((getGameTime()+i*6) * 0.33f) * 11);
            f32 y = 1 + Maths::Round(-3 + Maths::Cos((getGameTime()+i*6) * 0.125f) * 6);
    
            Vec2f offset = Vec2f(0, 2) + Vec2f(x * 2, y);

            if (y < -5.0f || y > 2)
            {
                shard.SetRelativeZ(-1.0f);
                shard.SetAnimation("defaultback");
            }
            else
            {
                shard.SetRelativeZ(1.0f);
                shard.SetAnimation("default");
            }
			
			//if (fl) offset.x = -offset.x;
            shard.SetOffset(offset);
			shard.animation.frame = blob.get_u16("shard_frame"+i);
        }
    }
}

void onGib(CSprite@ this)
{
	if (!getNet().isClient())
		return;

    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;

    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u16 team = blob.getTeamNum();

    makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       0, 0, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 0, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 0, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       0, 3, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
    makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp + 1 , 80 ),   0, 4, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

void onSetPlayer( CBlob@ this, CPlayer@ player )
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 15, Vec2f(16, 16));
	}
}

const string[] anim_default_blue = {
	"b_demon_rend0",
	"b_demon_rend1",
	"b_demon_rend2",
	"b_demon_rend2",
	"b_demon_rend1",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0",
	"b_demon_rend0"
};

const string[] anim_big_blue = {
	"b_demon_rend3",
	"b_demon_rend4",
	"b_demon_rend5",
	"b_demon_rend5",
	"b_demon_rend4",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3",
	"b_demon_rend3"
};

const string[] anim_default_red = {
	"r_demon_rend0",
	"r_demon_rend1",
	"r_demon_rend2",
	"r_demon_rend2",
	"r_demon_rend1",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0",
	"r_demon_rend0"
};

const string[] anim_big_red = {
	"r_demon_rend3",
	"r_demon_rend4",
	"r_demon_rend5",
	"r_demon_rend5",
	"r_demon_rend4",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3",
	"r_demon_rend3"
};

const u16 anim_time = 6;
void laserEffects(CBlob@ this, int id)
{
	bool big = this.get_bool("big");

	CSprite@ sprite = this.getSprite();
	if (sprite is null || sprite.animation is null) return;

    int ts = this.getTickSinceCreated();
	string rendname;
	if (this.getTeamNum() == 0)
	{
		rendname = big ? anim_big_blue[sprite.animation.frame] : anim_default_blue[sprite.animation.frame];
	}
	else
	{
		rendname = big ? anim_big_red[sprite.animation.frame] : anim_default_red[sprite.animation.frame];
	}

    f32 z = 100.0f;

    Vec2f[] v_pos;
    Vec2f[] v_uv;
    SColor[] v_col;

	Vec2f s = Vec2f(16, 24);
	u16 alpha = 155;
	bool facing_left = this.isFacingLeft();
	SColor col = SColor(alpha, 255, 255, 255);

	Vec2f base_pos = this.getInterpolatedPosition();
	if (facing_left)
	{
		v_pos.push_back(base_pos + Vec2f(s.x, -s.y));
		v_uv.push_back(Vec2f(0, 0));
		v_col.push_back(col);

		v_pos.push_back(base_pos + Vec2f(-s.x, -s.y));
		v_uv.push_back(Vec2f(1, 0));
		v_col.push_back(col);

		v_pos.push_back(base_pos + Vec2f(-s.x, s.y));
		v_uv.push_back(Vec2f(1, 1));
		v_col.push_back(col);

		v_pos.push_back(base_pos + Vec2f(s.x, s.y));
		v_uv.push_back(Vec2f(0, 1));
		v_col.push_back(col);
	}
	else
	{
		v_pos.push_back(base_pos + Vec2f(-s.x, -s.y));
		v_uv.push_back(Vec2f(0, 0));
		v_col.push_back(col);

		v_pos.push_back(base_pos + Vec2f(s.x, -s.y));
		v_uv.push_back(Vec2f(1, 0));
		v_col.push_back(col);

		v_pos.push_back(base_pos + Vec2f(s.x, s.y));
		v_uv.push_back(Vec2f(1, 1));
		v_col.push_back(col);

		v_pos.push_back(base_pos + Vec2f(-s.x, s.y));
		v_uv.push_back(Vec2f(0, 1));
		v_col.push_back(col);
	}

    Render::QuadsColored(rendname, z, v_pos, v_uv, v_col);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("restore_caster"))
	{
		if (this.hasTag("healed")) return;
		this.Tag("healed");

		u16 id = params.read_u16();

		CBlob@ b = getBlobByNetworkID(id);
		if (b is null) return;

        Heal(this, b, heal_amount);
        if (b.getSprite() !is null) b.getSprite().PlaySound("mana_smooth", 0.75f, 1.25f + XORRandom(11) * 0.01f);
	}
}