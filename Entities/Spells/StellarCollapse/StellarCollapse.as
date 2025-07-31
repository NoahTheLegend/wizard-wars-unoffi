#include "Hitters.as";
#include "TextureCreation.as";

const Vec2f frameSize = Vec2f(24, 32);
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("medium weight");
	this.Tag("cantmove");
	this.Tag("die_in_divine_shield");

	this.set_f32("delta", 0.0f);
	this.set_u32("collision_time", 0);
	this.set_u32("fold_time", 15);
	this.set_u32("explosion_delay", 5 + XORRandom(5));

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().SetGravityScale(0.5f);
	this.getShape().getConsts().bullet = true;
	
	//this.set_f32("explosive_radius", 64.0f);
	//this.set_f32("explosive_damage", 2.0f);
	//this.set_string("custom_explosion_sound", "FireBlast"+(XORRandom(2)+1)+".ogg");
	//this.set_f32("map_damage_radius", 24.0f);
	//this.set_f32("map_damage_ratio", 0.1f);
	//this.set_bool("map_damage_raycast", true);
	//this.set_bool("explosive_teamkill", false);
    //this.Tag("exploding");

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

	int cb_id = Render::addBlobScript(Render::layer_prehud, this, "StellarCollapse.as", "laserEffects");
}

const string[] anim_loop = {
	"sc_rend0",
	"sc_rend1",
	"sc_rend2"
};

const u8 anim_time = 3;
void laserEffects(CBlob@ this, int id)
{
	if (this.hasTag("stop_rendering")) return;

	int ts = this.getTickSinceCreated();
	u8 split_by_parts = 20;

	if (ts > 1)
	{
		Vec2f pos = this.getInterpolatedPosition();
		CSprite@ sprite = this.getSprite();
		CMap@ map = getMap();
		f32 z = -10.0f;

		Vec2f[] v_pos;
		Vec2f[] v_uv;

		string rendname = anim_loop[ts / anim_time % anim_loop.length];
		f32 w = 1.0f;
		f32 h = 1.0f;

		Vec2f map_dim = Vec2f(map.tilemapwidth * 8, map.tilemapheight * 8);
		f32 fsw = Maths::Min(1.0f, f32(ts / 30.0f) + 0.1f);

		f32 sin = Maths::Sin(ts * 0.05f);
		Vec2f vel = this.getVelocity();
		f32 delta = Maths::Lerp(this.get_f32("delta"), vel.Length(), 0.1f);
		this.set_f32("delta", delta);

		bool collided = this.hasTag("collided");
		u32 collision_time = this.get_u32("collision_time");

		int collision_diff = collision_time != 0 ? getGameTime() - collision_time : 0;
		u32 fold_time = this.get_u32("fold_time");
		f32 fold_factor = Maths::Clamp(f32(collision_diff) / f32(fold_time), 0.0f, 1.0f);

		for (u8 i = 0; i < split_by_parts; i++)
		{
			f32 fsh = (h / split_by_parts) * (i + 1);

			f32 delta_tail_stretch = (split_by_parts - i) * delta;
			f32 delta_tail_stretch_factor = Maths::Max(fold_factor, f32(i) / split_by_parts);
			f32 stretch = delta_tail_stretch * (1.0f - delta_tail_stretch_factor);

			f32 framewidth = frameSize.x * fsw * Maths::Sin(delta_tail_stretch_factor) * Maths::Min(delta_tail_stretch_factor * 2, 1.0f) + ts * 0.1f;
			f32 halfwidth = frameSize.x / 2;

			if (i == 0)
			{
				f32 trail_width = framewidth + 1.0f;
				
				Vec2f center_offset = Vec2f(-halfwidth, 0);

				Vec2f o0 = Vec2f(halfwidth, -map_dim.y * 2 * (1.0f - fold_factor)) + center_offset;
				Vec2f o1 = Vec2f(halfwidth, -map_dim.y * 2 * (1.0f - fold_factor)) + center_offset;
				Vec2f o2 = Vec2f(halfwidth + trail_width/2,  halfwidth / 2) + center_offset;
				Vec2f o3 = Vec2f(halfwidth - trail_width/2,  halfwidth / 2) + center_offset;

				v_pos.push_back(pos + o0); v_uv.push_back(Vec2f(0.5f,	0.1f));
				v_pos.push_back(pos + o1); v_uv.push_back(Vec2f(w,		0.1f));
				v_pos.push_back(pos + o2); v_uv.push_back(Vec2f(w,		0.1f));
				v_pos.push_back(pos + o3); v_uv.push_back(Vec2f(0,		0.1f));
			}

			Vec2f center_offset = Vec2f(-halfwidth, 0);
			Vec2f offset = Vec2f(0, stretch);

			f32 strip_height = frameSize.y / split_by_parts;

			f32 y0 = strip_height * i;
			f32 y1 = strip_height * (i + 1);

			Vec2f o0 = Vec2f(halfwidth - framewidth/2, y0) + Vec2f(offset.x, -offset.y - halfwidth) + center_offset;
			Vec2f o1 = Vec2f(halfwidth + framewidth/2, y0) + Vec2f(offset.x, -offset.y - halfwidth) + center_offset;
			Vec2f o2 = Vec2f(halfwidth + framewidth/2, y1) + Vec2f(offset.x,  -halfwidth) + center_offset;
			Vec2f o3 = Vec2f(halfwidth - framewidth/2, y1) + Vec2f(offset.x,  -halfwidth) + center_offset;

			f32 uv_y0 = y0 / frameSize.y;
			f32 uv_y1 = y1 / frameSize.y;

			v_pos.push_back(pos + o0); v_uv.push_back(Vec2f(0, uv_y0));
			v_pos.push_back(pos + o1); v_uv.push_back(Vec2f(w, uv_y0));
			v_pos.push_back(pos + o2); v_uv.push_back(Vec2f(w, uv_y1));
			v_pos.push_back(pos + o3); v_uv.push_back(Vec2f(0, uv_y1));
		}

		Render::Quads(rendname, z, v_pos, v_uv);
	}
}

void onTick(CBlob@ this)
{
	if (getControls().isKeyJustPressed(KEY_KEY_R))
	{
		this.server_Die();
		return;
	}
	if (getControls().isKeyJustPressed(KEY_KEY_E))
	{
		this.setVelocity(Vec2f(0, 0.0f));
		this.setPosition(Vec2f(this.getPosition().x, this.getPosition().y - 64.0f));
	}
	if (this.getTickSinceCreated() == 0)
	{
		this.setPosition(Vec2f(this.getPosition().x, -32.0f));
	}

	bool collided = this.hasTag("collided");
	if (collided && !this.hasTag("mark_for_death"))
	{
		u32 collision_time = this.get_u32("collision_time");
		int diff = getGameTime() - collision_time;
		f32 fold_factor = Maths::Clamp(f32(diff) / f32(this.get_u32("fold_time")), 0.0f, 1.0f);

		if (fold_factor == 1.0f)
		{
			CParticle@ p = ParticleAnimated("StellarCollapseExplosion.png", 
										this.getPosition(), 
										Vec2f_zero, 
										float(XORRandom(360)), 
										0.5f,
										5, 
										0.0f, 
										false);

			if (p !is null)
			{
				p.bounce = 0;
				p.collides = false;
    			p.fastcollision = true;
				p.Z = 100.0f;
				//p.setRenderStyle(RenderStyle::additive);
			}

			this.Untag("collided");
			this.Tag("mark_for_death");
			this.Tag("stop_rendering");
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && blob.hasTag("projectile"))
		return;

	if (solid || (solid && this.getTeamNum() != blob.getTeamNum()) || blob.hasTag("barrier"))
	{		
		this.Tag("collided");
		this.set_u32("collision_time", getGameTime());
	}
}
