#include "Hitters.as";
#include "TextureCreation.as";

const Vec2f frameSize = Vec2f(24, 32);
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("counterable");
	this.Tag("cantmove");
	this.Tag("die_in_divine_shield");
	this.Tag("no trampoline collision");

	this.set_f32("delta", 0.0f);
	this.set_u32("collision_time", 0);
	this.set_u32("fold_time", 10);
	this.set_u32("explosion_delay", 5 + XORRandom(5));

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	if (!isClient()) return;
	Vec2f framePos = Vec2f(0, 0);

	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend0", false, false, Vec2f(0, 0), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend1", false, false, Vec2f(24, 0), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend2", false, false, Vec2f(0, 32), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend3", false, false, Vec2f(24, 32), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend4", false, false, Vec2f(0, 64), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend5", false, false, Vec2f(24, 64), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend6", false, false, Vec2f(0, 128), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend7", false, false, Vec2f(24, 128), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend8", false, false, Vec2f(0, 160), frameSize);
	SetupImage("StellarCollapse.png", SColor(255, 255, 255, 255), "sc_rend9", false, false, Vec2f(24, 160), frameSize);

	int cb_id = Render::addBlobScript(Render::layer_tiles, this, "StellarCollapse.as", "laserEffects");
}

const string[] anim_loop = {
	"sc_rend0",
	"sc_rend1",
	"sc_rend2"
};

const string[] anim_end = {
	"sc_rend3",
	"sc_rend4",
	"sc_rend5",
	"sc_rend6",
	"sc_rend7",
	"sc_rend8",
	"sc_rend9"
};

const u8 anim_time = 3;
const f32 prog_mod = 2;
const u32 collision_delay = 3;
const Vec2f render_offset = Vec2f(0, -10);

void laserEffects(CBlob@ this, int id)
{
	if (this.hasTag("stop_rendering")) return;

	int ts = this.getTickSinceCreated();
	u8 split_by_parts = 20;

	if (ts > 1)
	{
		Vec2f pos = this.getInterpolatedPosition() + render_offset;
		CSprite@ sprite = this.getSprite();
		CMap@ map = getMap();
		f32 z = 100.0f;

		Vec2f[] v_pos;
		Vec2f[] v_uv;
		SColor[] v_col;

		bool collided = this.hasTag("collided");
		u32 collision_time = this.get_u32("collision_time");

		int collision_diff = collision_time != 0 ? getGameTime() - collision_time : 0;
		u32 fold_time = this.get_u32("fold_time");
		f32 fold_factor = Maths::Clamp(f32(collision_diff) / f32(fold_time), 0.0f, 1.0f);

		string rendname = collided ? anim_end[anim_end.length * fold_factor] : anim_loop[ts / anim_time % anim_loop.length];
		f32 w = 1.0f;
		f32 h = 1.0f;

		ts *= prog_mod;
		Vec2f map_dim = Vec2f(map.tilemapwidth * 8, map.tilemapheight * 8);
		f32 fsw = Maths::Min(1.0f, f32(ts / 30.0f) + 0.1f);

		f32 sin = Maths::Sin(ts * 0.05f);
		Vec2f vel = this.getVelocity();
		f32 delta = Maths::Lerp(this.get_f32("delta"), vel.Length(), 0.1f);
		this.set_f32("delta", delta);

		f32 trail_width = 0;
		for (u8 i = 0; i < split_by_parts; i++)
		{
			f32 fsh = (h / split_by_parts) * (i + 1);

			f32 delta_tail_stretch = (split_by_parts - i) * delta;
			f32 delta_tail_stretch_factor = Maths::Max(1.0f - fold_factor, f32(i) / split_by_parts);
			f32 stretch = delta_tail_stretch * (1.0f - delta_tail_stretch_factor);

			f32 framewidth = frameSize.x * fsw * Maths::Sin(delta_tail_stretch_factor) * Maths::Min(delta_tail_stretch_factor * 2, 1.0f) + ts * 0.1f;
			f32 halfwidth = frameSize.x / 2;

			if (i == 0)
			{
				trail_width = framewidth - 1;
			}
			else if (i == split_by_parts - 1)
			{
				Vec2f center_offset = Vec2f(-halfwidth, 0);

				Vec2f o0 = Vec2f(halfwidth, -map_dim.y * 2 * Maths::Max(1.0f - fold_factor * 2, 0)) + center_offset;
				Vec2f o1 = Vec2f(halfwidth, -map_dim.y * 2 * Maths::Max(1.0f - fold_factor * 2, 0)) + center_offset;
				Vec2f o2 = Vec2f(halfwidth + trail_width/2,  -halfwidth + 1 + frameSize.y * fold_factor) + center_offset;
				Vec2f o3 = Vec2f(halfwidth - trail_width/2,  -halfwidth + 1 + frameSize.y * fold_factor) + center_offset;

				v_pos.push_back(pos + o0); v_uv.push_back(Vec2f(0.5f,	0.5f));
				v_pos.push_back(pos + o1); v_uv.push_back(Vec2f(w,		0.5f));
				v_pos.push_back(pos + o2); v_uv.push_back(Vec2f(w,		0.5f));
				v_pos.push_back(pos + o3); v_uv.push_back(Vec2f(0,		0.5f));

				for (u8 i = 0; i < 4; i++){ v_col.push_back(SColor(200 * (1.0f - fold_factor), 255, 255, 255)); }
			}

			Vec2f center_offset = Vec2f(-halfwidth, 0);
			Vec2f offset = Vec2f(0, stretch);

			f32 strip_height = frameSize.y / split_by_parts;

			f32 y0 = strip_height * i;
			f32 y1 = strip_height * (i + 1);

			Vec2f o0 = Vec2f(halfwidth - framewidth/2, y0) + Vec2f(offset.x, -offset.y - halfwidth) + center_offset;
			Vec2f o1 = Vec2f(halfwidth + framewidth/2, y0) + Vec2f(offset.x, -offset.y - halfwidth) + center_offset;
			Vec2f o2 = Vec2f(halfwidth + framewidth/2, y1) + Vec2f(offset.x,  -halfwidth + 8 * fold_factor) + center_offset;
			Vec2f o3 = Vec2f(halfwidth - framewidth/2, y1) + Vec2f(offset.x,  -halfwidth + 8 * fold_factor) + center_offset;

			f32 uv_y0 = y0 / frameSize.y;
			f32 uv_y1 = y1 / frameSize.y;

			v_pos.push_back(pos + o0); v_uv.push_back(Vec2f(0, uv_y0));
			v_pos.push_back(pos + o1); v_uv.push_back(Vec2f(w, uv_y0));
			v_pos.push_back(pos + o2); v_uv.push_back(Vec2f(w, uv_y1));
			v_pos.push_back(pos + o3); v_uv.push_back(Vec2f(0, uv_y1));
			
			for (u8 i = 0; i < 4; i++){ v_col.push_back(SColor(200 * Maths::Max(1.0f - fold_factor * 1.25f, 0), 255, 255, 255)); }
		}

		Render::QuadsColored(rendname, z, v_pos, v_uv, v_col);
	}
}

void onTick(CBlob@ this)
{
	this.AddForce(Vec2f(0, this.getMass() * 0.5f));

	if (this.getTickSinceCreated() == 0)
	{
		this.setPosition(Vec2f(this.getPosition().x, -32.0f));
		this.getSprite().PlaySound("StellarCollapseSpawn.ogg", 2.0f, 0.9f + XORRandom(15) * 0.01f);
	}

	bool collided = this.hasTag("collided");
	if (collided && !this.hasTag("mark_for_death"))
	{
		u32 collision_time = this.get_u32("collision_time");
		int diff = getGameTime() - collision_time;

		f32 fold_factor = Maths::Clamp(f32(diff) / f32(this.get_u32("fold_time")), 0.0f, 1.0f);
		bool last_tick = fold_factor == 1.0f;

		if (isClient() && !this.hasTag("particles"))
		{
			this.Tag("particles");

			this.getSprite().PlaySound("FireBlast4.ogg", 1.0f, 0.75f + XORRandom(10) * 0.01f);
			this.getSprite().PlaySound("StellarCollapseExplode.ogg", 0.5f, 1.15f + XORRandom(10) * 0.01f);
			
			CParticle@ p = ParticleAnimated("StellarCollapseExplosion.png", 
												this.getPosition()+ Vec2f(0, 4), 
												Vec2f_zero, 
												float(XORRandom(360)), 
												1.0f,
												5, 
												0.0f, 
												false);

			if (p !is null)

				p.bounce = 0;
				p.collides = false;
    			p.fastcollision = true;
				p.Z = 1000.0f;
				//p.setRenderStyle(RenderStyle::additive);
		}

		if (last_tick)
		{
			MakeParticles(this);

			this.Untag("collided");
			this.Tag("mark_for_death");
			this.Tag("stop_rendering");
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1, Vec2f point2)
{
	if (blob !is null && blob.hasTag("projectile"))
		return;

	if (!this.hasTag("collided") && (solid || (solid && this.getTeamNum() != blob.getTeamNum()) || blob.hasTag("barrier")))
	{
		this.Tag("collided");

		this.set_u32("collision_time", int(getGameTime()) + collision_delay);
		Explode(this);

		this.setPosition(this.getPosition() + this.getVelocity());
		this.getShape().SetStatic(true);
		this.getSprite().PlaySound("StellarCollapseCollide.ogg", 1.0f, 0.75f + XORRandom(10) * 0.01f);
	}
}

void MakeParticles(CBlob@ this)
{
	for (u8 i = 0; i < 5+XORRandom(5); i++)
	{
		const f32 rad = 2.0f;
		Vec2f vel = Vec2f(1.0f + XORRandom(51) * 0.01f, 0).RotateBy(XORRandom(360));
		Vec2f random = Vec2f( XORRandom(128)-64, XORRandom(128)-64 ) * 0.015625f * rad;
		{
			CParticle@ p = ParticleAnimated("GenericBlast6.png", 
											this.getPosition(), 
											vel, 
											float(XORRandom(360)), 
											1.0f, 
											3, 
											0.0f, 
											false);
			if (p !is null)
			{
				p.bounce = 0;
				p.scale = 3.0f;
    			p.fastcollision = true;
				p.Z = 55.0f;
				p.setRenderStyle(RenderStyle::additive);

				p.colour = SColor(255, 185, 55, 255);
				p.forcecolor = SColor(255, 185, 55, 255);
			}
		}
		{
			CParticle@ p = ParticleAnimated("GenericBlast5.png", 
											this.getPosition(), 
											vel, 
											float(XORRandom(360)), 
											1.0f, 
											3, 
											0.0f, 
											false );
			if (p !is null)
			{
				p.bounce = 0;
				p.scale = 2.0f;
    			p.fastcollision = true;
				p.Z = 20.0f;
				p.setRenderStyle(RenderStyle::additive);

				p.colour = SColor(255, 185, 55, 255);
				p.forcecolor = SColor(255, 185, 55, 255);
			}
		}
	}
}

void Explode(CBlob@ this)
{
	if (!isServer()) return;
	if (this.hasTag("dead")) return;
	
    CMap@ map = getMap();
	if (map is null) return;

	Vec2f thisPos = this.getPosition();
	CBlob@[] blobsInRadius;

	f32 explosion_radius = this.get_f32("explosion_radius");
	f32 damage = this.get_f32("explosion_damage");

	if (map.getBlobsInRadius(thisPos, explosion_radius, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b !is null && isEnemy(this, b))
			{
				Vec2f bPos = b.getPosition();
				Vec2f dir = bPos - thisPos;
				f32 dir_len = dir.Length();
				dir.Normalize();
				dir *= explosion_radius - dir_len * 8;
				this.server_Hit(b, bPos, dir, damage, Hitters::explosion, true);
			}
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CPlayer@ damageOwner = this.getDamageOwnerPlayer();
	return true;
	return
	(
		(damageOwner !is null && damageOwner.getBlob() is target)
		||
		(target !is null && target.getTeamNum() != this.getTeamNum() && (target.hasTag("barrier") || target.hasTag("flesh")))
		||
		(target !is null
		&& target.hasTag("flesh")
		&& !target.hasTag("dead") 
		&& target.getTeamNum() != this.getTeamNum())
	);
}	

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}