void onInit(CBlob@ this)
{
	this.SetLightColor(SColor(255,255,0,0));
    this.SetLight(true);

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().mapCollisions = false;

	bool t = this.hasTag("clone");

	CSprite@ sprite = this.getSprite();
	sprite.ScaleBy(Vec2f(0.33f, 0.33f));
	sprite.SetZ(100.0f);

	if (t) return;

	if (isServer())
	{
		CBlob@ cloned = server_CreateBlobNoInit("polarityfield");
		cloned.set_u16("follow_id", this.getNetworkID());
		cloned.server_setTeamNum(this.getTeamNum());
		cloned.Tag("clone");
		cloned.Init();
	}

	if (isClient())
	{
		sprite.SetEmitSound("polarity_loop.ogg");
		sprite.SetEmitSoundPaused(false);
		sprite.SetEmitSoundSpeed(1.0f);
		sprite.SetEmitSoundVolume(2.0f);
	}

	if (!this.exists("stages")) this.set_u8("stages", 3);
	this.Sync("stages", true);

	this.set_u8("despelled",0);
	this.Tag("circle");

	this.server_SetTimeToDie(15.0f + 15.0f*(this.get_u8("stages")-2));
}

const int const_stage_frequency = 30;

void onTick(CBlob@ this)
{
	bool t = this.hasTag("clone");
	if (this.getTickSinceCreated() == 0)
	{
		this.set_Vec2f("init_pos", this.getPosition());
		this.getShape().SetGravityScale(0.0f);
		
		CSprite@ sprite = this.getSprite();
		sprite.setRenderStyle(RenderStyle::outline);
		sprite.PlaySound("WizardShoot.ogg", 2.5f, 0.8f);
	}

	if (t)
	{
		if (isServer())
		{
			CBlob@ follow = getBlobByNetworkID(this.get_u16("follow_id"));
			if (follow !is null)
			{
				Vec2f center = follow.get_Vec2f("init_pos");
				f32 rot = getGameTime()*(this.getNetworkID()%10+10)%360.0f;
				this.setPosition(center+Vec2f(2.0f, 0.0f).RotateBy(rot));
				follow.setPosition(center-Vec2f(2.0f, -2.0f).RotateBy(rot));
			}
			else this.server_Die();
		}
		return;
	}

	u8 stages = this.get_u8("stages");
	int stage_frequency = const_stage_frequency/(stages-2);

	if (isServer())
	{
		if (this.get_u8("despelled") >= 2) this.server_Die();
		//create
		if (this.getTickSinceCreated() <= stages * stage_frequency && getGameTime()%stage_frequency == 0)
		{
			u8 i = Maths::Min(this.getTickSinceCreated()/stage_frequency, stages);
			u16[] stage_ids;
			u8 orbs = 4 + i*4;

			for (u8 j = 0; j < orbs; j++)
			{
				CBlob@ orb = server_CreateBlob("polarityprojectile", this.getTeamNum(), this.getPosition());
				orb.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
				orb.IgnoreCollisionWhileOverlapped(this);
				stage_ids.push_back(orb.getNetworkID());
			}

			this.set("stage_ids"+i, stage_ids);
		}
		//rotate
		f32 rot = this.getTickSinceCreated()%360.0f;
		for (u8 i = 0; i < stages; i++)
		{
			u16[] new_stage_ids;
			u16[] stage_ids;
			if (!this.get("stage_ids"+i, stage_ids))
			{
				continue;
			}

			f32 dist = 48.0f + 48.0f*i;
			for (u8 j = 0; j < stage_ids.size(); j++)
			{
				bool clock = (i%2==0||stages<4);
				CBlob@ orb = getBlobByNetworkID(stage_ids[j]);
				if (orb !is null)
				{
					f32 lifetime_mod = Maths::Min(1.0f, f32(orb.getTickSinceCreated())/15.0f);
					f32 angle = 360/stage_ids.size() * j;
					f32 fin_dist = lifetime_mod * dist * (Maths::Sin(getGameTime()*0.05f)/2+1.0f);

					Vec2f pos = Vec2f_lerp(orb.getPosition(), this.getPosition()+Vec2f(fin_dist, 0).RotateBy((clock?1.0f:-1.0f)*(angle+rot)), 0.05f);
					orb.setPosition(pos);

					new_stage_ids.push_back(orb.getNetworkID());
				}
			}
			
			this.set("stage_ids"+i, new_stage_ids);
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.hasTag("clone"))
	{
		return;
	}

	if (isClient())
	{
		this.getSprite().PlaySound("sidewind_init.ogg", 1.5f, 0.75f + XORRandom(1)/10.0f);
	}

	u8 stages = this.get_u8("stages");
	sparks(this.getPosition(), 10);

	if (isServer())
	{
		f32 rot = this.getTickSinceCreated()%360.0f;
		for (u8 i = 0; i < stages; i++)
		{
			u16[] stage_ids;
			if (!this.get("stage_ids"+i, stage_ids))
			{
				continue;
			}

			for (u8 j = 0; j < stage_ids.size(); j++)
			{
				CBlob@ orb = getBlobByNetworkID(stage_ids[j]);
				if (orb !is null)
				{
					orb.server_SetTimeToDie(5.0f);

					Vec2f vel = orb.getPosition()-orb.getOldPosition();
					orb.setVelocity(vel);
					orb.Tag("accelerate");
				}
			}
		}
	}
}

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount)
{
	if (!getNet().isClient())
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 1.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

		u8 rnd = XORRandom(75);
        CParticle@ p = ParticlePixelUnlimited(pos, vel, SColor(255-rnd, 255, 75+rnd, 255), true);
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 10 + _sprk_r.NextRanged(20);
        p.scale = 0.5f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}

void onTick(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;
	sprite.RotateBy((this.getNetworkID()%6)/2+1, Vec2f(0,0));
	if (this.hasTag("clone")) return;

	sprite.SetEmitSoundVolume(Maths::Min(2.0f, this.getTickSinceCreated()*0.025f));
	
	orbit(this.get_Vec2f("init_pos"), 1, this, 32.0f);
}

void orbit(Vec2f pos, int amount, CBlob@ this, f32 radius)
{
	if (!getNet().isClient())
		return;

	u32 gt = getGameTime();
	bool s = gt%3==0;
	f32 angle = 90-Maths::Sin(gt*0.01f)*20;

	for(int i = 0; i < angle; i++)
	{
		f32 fin_radius = radius;
		SColor color = SColor(255,s?0:75+XORRandom(125),s?0:XORRandom(25),s?XORRandom(50):75+XORRandom(125));

		f32 sin = Maths::Sin(gt*0.1f+Maths::Tan(i))*7.5f;
		f32 cos = Maths::Cos(s?Maths::Sin(gt)*4:0);
		fin_radius -= s?2:0;

		f32 wave = s ? 0 : sin;
		f32 rot = i*(360.0f/angle);
		Vec2f npos = pos + Vec2f_lengthdir(fin_radius + wave,rot);

		CParticle@ pb = ParticlePixelUnlimited(npos+Vec2f(s?XORRandom(21)*0.1f-1:0,cos/sin),Vec2f_zero,color,true);
		if(pb !is null)
		{
			pb.timeout = 10;
			pb.gravity = Vec2f_zero;
			pb.damping = 0.9;
			pb.collides = false;
			pb.fastcollision = true;
			pb.bounce = 0;
			pb.lighting = false;
			pb.Z = 500;
		}
	}
}
