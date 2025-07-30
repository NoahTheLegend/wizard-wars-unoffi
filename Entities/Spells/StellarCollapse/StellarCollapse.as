#include "Hitters.as";
#include "TextureCreation.as";

const Vec2f frameSize = Vec2f(24, 32);
void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("medium weight");
	this.Tag("die_in_divine_shield");

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().SetGravityScale(0.5f);
	
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
	int ts = this.getTickSinceCreated();
	if (ts > 0)
	{
		Vec2f pos = this.getInterpolatedPosition();
		CSprite@ sprite = this.getSprite();
		f32 z = -10.0f;
		
		Vec2f[] v_pos;
		Vec2f[] v_uv;

		string rendname = anim_loop[ts / anim_time % anim_loop.length];
		f32 w = 1.0f;
		f32 h = 1.0f;

		f32 fsw = Maths::Min(1.0f, f32(ts / 30.0f) + 0.25f);
		f32 fsh = 1.0f;
	
		f32 framewidth = frameSize.x * fsw;
		f32 halfwidth = frameSize.x / 2;

		Vec2f o0 = Vec2f(halfwidth - framewidth/2, 0);
		Vec2f o1 = Vec2f(halfwidth + framewidth/2, 0);
		Vec2f o2 = Vec2f(halfwidth + framewidth/2, frameSize.y * fsh);
		Vec2f o3 = Vec2f(halfwidth - framewidth/2, frameSize.y * fsh);

		v_pos.push_back(pos + o0); v_uv.push_back(Vec2f(0,0));
		v_pos.push_back(pos + o1); v_uv.push_back(Vec2f(w,0));
		v_pos.push_back(pos + o2); v_uv.push_back(Vec2f(w,h));
		v_pos.push_back(pos + o3); v_uv.push_back(Vec2f(0,h));

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
		this.setPosition(Vec2f(this.getPosition().x, this.getPosition().y - 64.0f));
	}
	if (this.getTickSinceCreated() == 0)
	{
		this.setPosition(Vec2f(this.getPosition().x, -32.0f));
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && blob.hasTag("projectile"))
		return;

	if (solid || (solid && this.getTeamNum() != blob.getTeamNum()) || blob.hasTag("barrier"))
	{		
		
	}
}
