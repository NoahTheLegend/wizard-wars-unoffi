#include "Hitters.as";	   
#include "LimitedAttacks.as";
#include "TextureCreation.as";

Random@ _laser_r = Random(0x10003);
void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("phase through spells");

	this.addCommandID("shoot_sfx");
	
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;

	if (!isClient()) return;

	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 155, 155, 255));

	u16[] exclude_ids;
	this.set("exclude ids", @exclude_ids);
	
	CSprite@ thisSprite = this.getSprite();
	thisSprite.ScaleBy(Vec2f(0.5f,0.5f));
	CSpriteLayer@ l = thisSprite.addSpriteLayer("l", "BallLightning.png", 54, 54);
	if (l !is null)
	{
		l.ScaleBy(Vec2f(0.5f,0.5f));
		thisSprite.RotateBy(XORRandom(360), Vec2f_zero);

		Animation@ anim = l.addAnimation("default", 0, false);
		if (anim !is null)
		{
			int[] frames = {0,1,2,3};
			anim.AddFrames(frames);
			
			l.RotateBy(XORRandom(360), Vec2f_zero);
			l.SetAnimation(anim);
			l.setRenderStyle(RenderStyle::additive);
		}
	}

	thisSprite.SetZ(525.0f);
	thisSprite.SetEmitSound("BallLightningHum.ogg");
	thisSprite.SetEmitSoundSpeed(0.5f);
	thisSprite.SetEmitSoundVolume(0.25f);
	thisSprite.SetEmitSoundPaused(false);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	Setup(SColor(255, 155, 155, 255), "rend7", false);
	Setup(SColor(255, 190, 220, 245), "rend8", false);
	Setup(SColor(255, 255, 245, 255), "rend9", false);
	Setup(SColor(255, 195, 195, 255), "rend10", false);
	int cb_id = Render::addBlobScript(Render::layer_objects, this, "ArcLightning.as", "laserEffects");
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ l = this.getSpriteLayer("l");
	if (l !is null)
	{
		this.RotateBy(-3, Vec2f_zero);
		l.RotateBy(3,  Vec2f_zero);
		l.animation.frame = this.animation.frame;
	}
}

const f32 radius = 112.0f;
void onTick(CBlob@ this)
{
	this.server_SetTimeToDie(1);

	if (this.getTickSinceCreated() == 1)
		this.getSprite().PlaySound("BallLightningCreate.ogg", 0.8f, 0.9f+XORRandom(16)*0.01f);

	Vec2f dir = this.getPosition() - this.get_Vec2f("aim pos");
	f32 dir_len = dir.Length();
	dir.Normalize();
	dir *= 2.0f * Maths::Min(1.0f, dir_len / 32.0f);
	this.setVelocity(-dir);

	CBlob@[] blobsInRadius;
	u16[] arc_ids;
	if (getMap().getBlobsInRadius(this.getPosition(), radius, @blobsInRadius))
	{
		u16 tid = this.getNetworkID();

		u16[]@ exclude_ids;
		this.get("exclude ids", @exclude_ids);

		Vec2f[] path;
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ blob = blobsInRadius[i];

			if (blob !is null && blob !is this && blob.getName() == "arclightning")
			{
				u16 bid = blob.getNetworkID();
				if (exclude_ids.find(bid) != -1)
					continue;

				bool remove_our_id = tid < bid;
				u16[]@ b_exclude_ids;
				if (blob.get("exclude ids", @b_exclude_ids))
				{
					if (remove_our_id && b_exclude_ids.find(tid) == -1) b_exclude_ids.push_back(tid);
				}
				
				arc_ids.push_back(blob.getNetworkID());
				generateLightningPath(this.getPosition(), blob.getPosition(), path);
			}
		}
		this.set("lightning path", @path);
	}
	this.set("links", @arc_ids);

	updateLaserPositions(this);
}

const int MAX_LASER_POSITIONS = 2;

void updateLaserPositions(CBlob@ this)
{
	Vec2f thisPos = this.getPosition();
	
	Vec2f aimPos = this.get_Vec2f("aim pos");
	Vec2f aimVec = aimPos - thisPos;
	Vec2f aimNorm = aimVec;
	aimNorm.Normalize();
	
	Vec2f destination = aimPos;
	
	Vec2f shootVec = destination-thisPos;
	
	Vec2f normal = (Vec2f(aimVec.y, -aimVec.x));
	normal.Normalize();
	
	array<Vec2f> laser_positions;
	
	float[] positions;
	positions.push_back(0);
	for (int i = 0; i < MAX_LASER_POSITIONS; i++)
	{
		positions.push_back( _laser_r.NextFloat() );
	}		
	positions.sortAsc();
	
	const f32 sway = 10.0f;
	const f32 jaggedness = 1.0f/(4.0f*sway);
	
	Vec2f prevPoint = thisPos;
	f32 prevDisplacement = 0.0f;
	
	for (int i = 1; i < positions.length; i++)
	{
		float pos = positions[i];
 
		float scale = (shootVec.Length() * jaggedness) * (pos - positions[i - 1]);
		float envelope = pos > 0.95f ? 20 * (1 - pos) : 1;
 
		float displacement = _laser_r.NextFloat()*sway*2.0f - sway;
		displacement -= (displacement - prevDisplacement) * (1 - scale);
		displacement *= envelope;
 
		Vec2f point = thisPos + shootVec*pos + normal*displacement;
		
		laser_positions.push_back(prevPoint);
		prevPoint = point;
		prevDisplacement = displacement;
	}
	laser_positions.push_back(destination);
	
	this.set("laser positions", laser_positions);
	
	array<Vec2f> laser_vectors;
	for (int i = 0; i < laser_positions.length-1; i++)
	{
		laser_vectors.push_back(laser_positions[i+1] - laser_positions[i]);
	}		
	this.set("laser vectors", laser_vectors);	
}

void generateLightningPath(Vec2f start, Vec2f end, Vec2f[] &inout path)
{
	Vec2f vec = end - start;
	Vec2f norm = vec;
	norm.Normalize();
	Vec2f normal = Vec2f(norm.y, -norm.x);
	
	float[] positions;
	positions.push_back(0);
	for (int i = 0; i < MAX_LASER_POSITIONS / 2; i++)
	{
		positions.push_back(_laser_r.NextFloat());
	}
	positions.sortAsc();
	
	const f32 sway = 8.0f;
	const f32 jaggedness = 1.0f/(4.0f*sway);
	
	Vec2f prevPoint = start;
	f32 prevDisplacement = 0.0f;
	
	path.push_back(start);
	for (int i = 1; i < positions.length; i++)
	{
		float pos = positions[i];
		float scale = (vec.Length() * jaggedness) * (pos - positions[i - 1]);
		float envelope = pos > 0.95f ? 20 * (1 - pos) : 1;
		
		float displacement = _laser_r.NextFloat()*sway*2.0f - sway;
		displacement -= (displacement - prevDisplacement) * (1 - scale);
		displacement *= envelope;
		
		Vec2f point = start + vec*pos + normal*displacement;
		path.push_back(point);
		
		prevPoint = point;
		prevDisplacement = displacement;
	}
	
	path.push_back(end);
}

void laserEffects(CBlob@ this, int id)
{
	CSprite@ thisSprite = this.getSprite();
	Vec2f thisPos = this.getPosition();

	u16[]@ links;
	if (!this.get("links", @links) || links.length == 0)
	{
		return;
	}

	if (this.getTickSinceCreated() <= 0)
		return;
	
	f32 z = this.getSprite().getZ() - 0.4f;
	Vec2f[]@ path;

	if (!this.get("lightning path", @path)) return;

	for (uint i = 0; i < links.length; i++)
	{
		CBlob@ source = getBlobByNetworkID(links[i]);
		if (source is null) continue;
		
		Vec2f sourcePos = source.getPosition();
		renderLightningPath(path, z);
	}
}

void renderLightningPath(array<Vec2f>@ path, f32 z)
{
	if (path.length < 2) return;

	const f32 LASER_WIDTH = 1.0f;
	for (uint i = 0; i < path.length - 1; i++)
	{
		Vec2f start = path[i];
		Vec2f end = path[i + 1];
		Vec2f segVec = end - start;
		Vec2f segNorm = segVec;
		segNorm.Normalize();
		Vec2f perpendicular = Vec2f(segNorm.y, -segNorm.x);
		
		Vec2f[] v_pos;
		Vec2f[] v_uv;
		
		v_pos.push_back(start - perpendicular * LASER_WIDTH); v_uv.push_back(Vec2f(0, 0));
		v_pos.push_back(end - perpendicular * LASER_WIDTH); v_uv.push_back(Vec2f(1, 0));
		v_pos.push_back(end + perpendicular * LASER_WIDTH); v_uv.push_back(Vec2f(1, 1));
		v_pos.push_back(start + perpendicular * LASER_WIDTH); v_uv.push_back(Vec2f(0, 1));
			
		Render::Quads("rend" + (XORRandom(4) + 7), z, v_pos, v_uv);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null && solid)
	{
		this.getSprite().PlaySound("lightning"+(1+XORRandom(2))+".ogg", 0.4f, 1.33f + XORRandom(16)*0.01f);
		this.getSprite().PlaySound("BallLightningBounce.ogg", 0.4, 0.75f + XORRandom(16)*0.01f);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shoot_sfx"))
	{
		if (!isClient()) return;

		this.getSprite().PlaySound("BallLightningShoot.ogg", 0.75f, 0.75f);
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("lightning"+(1+XORRandom(2))+".ogg", 0.75f, 0.8f + XORRandom(16)*0.01f);
	blast(this.getPosition(), 1, 0.5f);
}

Random _blast_r(0x10002);
void blast(Vec2f pos, int amount, f32 scale = 1.0f)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel = Vec2f_zero;

        CParticle@ p = ParticleAnimated(CFileMatcher("Implosion3.png").getFirst(), 
									pos, 
									vel, 
									0, 
									scale, 
									4, 
									0.0f, 
									false);
									
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.damping = 0.85f;
		p.Z = 200.0f;
		p.lighting = true;
        p.setRenderStyle(RenderStyle::additive);
    }
}