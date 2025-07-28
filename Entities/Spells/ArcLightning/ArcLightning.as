#include "Hitters.as";
#include "HittersWW.as";
#include "LimitedAttacks.as";
#include "TextureCreation.as";

Random@ _laser_r = Random(0x10003);

const f32 radius = 128.0f;
const u8 update_thresh = 5;

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("phase through spells");

	this.addCommandID("shoot_sfx");
	
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = true;

	if (!isClient()) return;

	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 155, 155, 255));

	CSprite@ thisSprite = this.getSprite();
	CSpriteLayer@ l = thisSprite.addSpriteLayer("l", "ArcLightning.png", 16, 16, this.getTeamNum(), 0);
	if (l !is null)
	{
		thisSprite.ScaleBy(Vec2f(1.5f, 1.5f));
		l.ScaleBy(Vec2f(1.5f, 1.5f));

		Animation@ anim = l.addAnimation("default", 0, false);
		if (anim !is null)
		{
			int[] frames = {0,1,2,3,4,5,6};
			anim.AddFrames(frames);
			
			l.SetAnimation(anim);
			l.setRenderStyle(RenderStyle::additive);
		}
	}

	Vec2f[] last_path;
	this.set("last_lightning_path", @last_path);

	thisSprite.SetZ(525.0f);
	thisSprite.SetEmitSound("BallLightningHum.ogg");
	thisSprite.SetEmitSoundSpeed(1.15f);
	thisSprite.SetEmitSoundVolume(0.15f);
	thisSprite.SetEmitSoundPaused(false);
	
	//dont collide with edge of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	SetupImage("ArcLightningTrail.png", SColor(175, 175, 175, 255), "arc_rend0", false);
	SetupImage("ArcLightningTrail.png", SColor(175, 210, 240, 255), "arc_rend1", false);
	SetupImage("ArcLightningTrail.png", SColor(175, 255, 255, 255), "arc_rend2", false);
	SetupImage("ArcLightningTrail.png", SColor(175, 215, 215, 255), "arc_rend3", false);
	int cb_id = Render::addBlobScript(Render::layer_objects, this, "ArcLightning.as", "laserEffects");
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ l = this.getSpriteLayer("l");
	if (l !is null)
	{
		this.RotateBy(3, Vec2f_zero);
		l.RotateBy(-3, Vec2f_zero);
		l.animation.frame = this.animation.frame;
	}
}

const f32 damage_mod_wet = 1.33f;
void DamageBlobs(CBlob@ this, CBlob@ blob, Vec2f a, Vec2f b)
{
	if (!isServer()) return;
	
	f32 damage = Maths::Max(this.get_f32("damage"), blob.get_f32("damage"));
	u8 damage_thresh = Maths::Max(this.get_u8("damage_thresh"), blob.get_u8("damage_thresh"));

	if (getGameTime() % damage_thresh == 0)
	{
		Vec2f dir = b - a;
		HitInfo@[] hitInfos;
		if (getMap().getHitInfosFromRay(a, -dir.Angle(), dir.Length(), this, hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hit = hitInfos[i];
				CBlob@ blob = hit.blob;

				if (blob !is null && isEnemy(this, blob))
				{
					if (blob.get_u16("wet timer") > 0) damage *= damage_mod_wet;
					this.server_Hit(blob, hit.hitpos, Vec2f_zero, damage, HittersWW::electricity, true);
				}
			}
		}
	}
}

void onTick(CBlob@ this)
{
    if (this.getTickSinceCreated() == 1)
        this.getSprite().PlaySound("BallLightningCreate.ogg", 0.9f, 2.0f+XORRandom(16)*0.01f);

	if (!this.hasTag("stop moving"))
    {
        Vec2f dir = this.getPosition() - this.get_Vec2f("aim pos");
        f32 dir_len = dir.Length();
		if (dir_len < 4.0f) this.Tag("stop moving");

        dir.Normalize();
        dir *= 2.0f * Maths::Min(1.0f, dir_len / 32.0f);
        this.setVelocity(-dir);
    }

    CBlob@[] blobsInRadius;
    u16[] arc_ids;

	bool was_update = false;
    if (getMap().getBlobsInRadius(this.getPosition(), radius, @blobsInRadius))
    {
        u16 tid = this.getNetworkID();
        dictionary lightning_paths;
		
        for (uint i = 0; i < blobsInRadius.length; i++)
        {
            CBlob@ blob = blobsInRadius[i];

            if (blob !is null && blob !is this
				&& blob.getTeamNum() == this.getTeamNum()
				&& blob.getName() == "arclightning")
            {
                u16 bid = blob.getNetworkID();

                bool remove_our_id = tid > bid;

                if (remove_our_id)
				{
					continue;
				}

                arc_ids.push_back(bid);
				DamageBlobs(this, blob, this.getPosition(), blob.getPosition());

				if (this.getTickSinceCreated() % update_thresh == 0)
				{
                	Vec2f[] path;
					float[] positions;

					positions.push_back(0);
					for (int i = 0; i < MAX_LASER_POSITIONS / 2; i++)
					{
						positions.push_back(_laser_r.NextFloat());
					}

					positions.sortAsc();
                	generateLightningPath(this, this.getPosition(), blob.getPosition(), path, positions);

                	lightning_paths.set("" + bid, @path);
					was_update = true;
				}
            }
        }
        if (was_update) this.set("lightning_paths", lightning_paths);
    }
    if (was_update) this.set("links", @arc_ids);

	if (isClient())
	{
		const f32 sway = 24.0f;
		const f32 jaggedness = 1.0f/((Maths::Sin(getGameTime()*0.05f)*2+sway)*sway);

		this.set_f32("sway", sway);
		this.set_f32("jaggedness", jaggedness);
	}
}

const int MAX_LASER_POSITIONS = 4;
void generateLightningPath(CBlob@ this, Vec2f start, Vec2f end, Vec2f[] &inout path, float[] positions)
{
	Vec2f vec = end - start;
	Vec2f norm = vec;
	norm.Normalize();
	Vec2f normal = Vec2f(norm.y, -norm.x);

	f32 sway = this.get_f32("sway");
	f32 jaggedness = this.get_f32("jaggedness");

	Vec2f[]@ old_path;
	this.get("last_lightning_path", @old_path);

	Vec2f prevPoint = start;
	f32 prevDisplacement = 0.0f;

	path.resize(0);
	path.push_back(start);
	for (int i = 0; i < positions.length; i++)
	{
		float pos = positions[i];
		float scale = (vec.Length() * jaggedness) * (pos - positions[i - 1]);
		float envelope = pos > 0.95f ? 20 * (1 - pos) : 1;

		float displacement = _laser_r.NextFloat()*sway*2.0f - sway;
		displacement -= (displacement - prevDisplacement) * (1 - scale);
		displacement *= envelope;

		Vec2f point = start + vec*pos + normal*displacement;
		if (old_path.length > i)
		{
			point = Vec2f_lerp(old_path[i], point, 0.5f);
		}

		path.push_back(point);

		prevPoint = point;
		prevDisplacement = displacement;
	}

	path.push_back(end);
	old_path = path;
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
    dictionary lightning_paths;
    if (!this.get("lightning_paths", lightning_paths)) return;
    u16 bid = this.getNetworkID();

    for (uint i = 0; i < links.length; i++)
    {
        u16 linkId = links[i];
        CBlob@ source = getBlobByNetworkID(linkId);
        if (source is null) continue;
		if (this.getDistanceTo(source) > radius) continue;
        
        Vec2f[]@ path;
        if (lightning_paths.get("" + linkId, @path))
        {
            renderLightningPath(this, path, z);
        }
    }
}

const f32 SLIDE_HEIGHT = 1.0f; // Show 25% of the sprite
void renderLightningPath(CBlob@ this, Vec2f[]@ &in path, f32 z)
{
    if (path.length < 2) return;
    const f32 LASER_WIDTH = 8.0f;
    
    // Calculate the slide offset based on time
    f32 slideOffset = Maths::Sin(this.getTickSinceCreated() * 0.1f) * Maths::Cos(this.getTickSinceCreated());
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

        // Apply the sliding window effect to UVs
        // We only show SLIDE_HEIGHT portion of the texture, shifted by slideOffset
        v_pos.push_back(start - perpendicular * LASER_WIDTH); 
        v_uv.push_back(Vec2f(0, slideOffset));
        
        v_pos.push_back(end - perpendicular * LASER_WIDTH); 
        v_uv.push_back(Vec2f(0, slideOffset + SLIDE_HEIGHT));
        
        v_pos.push_back(end + perpendicular * LASER_WIDTH); 
        v_uv.push_back(Vec2f(1, slideOffset + SLIDE_HEIGHT));
        
        v_pos.push_back(start + perpendicular * LASER_WIDTH); 
        v_uv.push_back(Vec2f(1, slideOffset));
            
        Render::Quads("arc_rend" + (XORRandom(4)), z, v_pos, v_uv);
    }
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null && solid)
	{
		this.Tag("stop moving");
		this.getSprite().PlaySound("lightning"+(1+XORRandom(2))+".ogg", 0.4f, 1.33f + XORRandom(16)*0.01f);
		this.getSprite().PlaySound("BallLightningBounce.ogg", 0.4, 1.5f + XORRandom(16)*0.01f);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shoot_sfx"))
	{
		if (!isClient()) return;

		this.getSprite().PlaySound("BallLightningShoot.ogg", 0.75f, 1.5f);
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

bool isEnemy(CBlob@ blob, CBlob@ this)
{
	if (blob.getTeamNum() == this.getTeamNum()) return false;
	return blob.hasTag("barrier") || blob.hasTag("flesh") || blob.hasTag("player");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getShape() !is null && blob.getShape().isStatic())
	{
		if (blob.hasTag("door") && blob.isCollidable())
		{
			return true;
		}
		
		ShapePlatformDirection@ plat = blob.getShape().getPlatformDirection(0);
		if (plat !is null)
		{
			Vec2f pos = this.getPosition();
			Vec2f bpos = blob.getPosition();

			Vec2f dir = plat.direction;
			if ((dir.x > 0 && pos.x > bpos.x)
				|| (dir.x < 0 && pos.x < bpos.x)
				|| (dir.y > 0 && pos.y > bpos.y)
				|| (dir.y < 0 && pos.y < bpos.y))
			{
				return true;
			}
		}
	}

	return blob.getName() == this.getName();
}
