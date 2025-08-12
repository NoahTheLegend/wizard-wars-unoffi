#include "TextureCreation.as";

const u32 plague_delay = 5 * 30;

void onInit(CBlob@ this)
{
    this.Tag("counterable");
    this.Tag("phase through spells");
    this.Tag("no trampoline collision");

    this.getShape().SetGravityScale(0.0f);
    this.getShape().getConsts().mapCollisions = false;
    this.getShape().SetRotationsAllowed(false);
    this.getShape().getConsts().net_threshold_multiplier = 4.0f;
    
    this.set_Vec2f("smashtoparticles_grav", Vec2f_zero);
    this.getSprite().SetZ(580.0f);
    this.getSprite().SetRelativeZ(580.0f);
    this.getSprite().setRenderStyle(RenderStyle::additive);

    this.set_f32("acceleration", 0);
    this.set_f32("last_angle_diff", 0);
    this.server_SetTimeToDie(1);
    this.Tag("smashtoparticles_additive");

    this.SetMapEdgeFlags(CBlob::map_collide_none);
    this.SetMapEdgeFlags(CBlob::map_collide_nodeath);

    this.SetFacingLeft(XORRandom(2) == 0);
    if (!isClient()) return;

    this.getSprite().SetVisible(false);
    this.getSprite().PlaySound("PlagueBlobCreate.ogg", 0.75f, 1.25f + XORRandom(10) * 0.01f);
    const Vec2f frameSize(32, 32);

    SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend0", false, false, Vec2f(0, 0), frameSize);
	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend1", false, false, Vec2f(0, 32), frameSize);
	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend2", false, false, Vec2f(0, 64), frameSize);
	SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend3", false, false, Vec2f(0, 96), frameSize);
    SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend4", false, false, Vec2f(0, 128), frameSize);
    SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend5", false, false, Vec2f(0, 160), frameSize);
    SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend6", false, false, Vec2f(0, 192), frameSize);
    SetupImage("PlagueBlob.png", SColor(255, 255, 255, 255), "pb_rend7", false, false, Vec2f(0, 224), frameSize);
    int cb_id = Render::addBlobScript(Render::layer_prehud, this, "PlagueBlob.as", "laserEffects");

    for (int i = 0; i < 6+XORRandom(6); i++)
    {
		Vec2f vel(1.0f + XORRandom(100) * 0.01f * 2.0f, 0);
		vel.RotateBy(XORRandom(100) * 0.01f * 360.0f);

        CParticle@ p = ParticleAnimated( CFileMatcher("GenericSmoke"+(1+XORRandom(2))+".png").getFirst(), 
									this.getPosition(), 
									vel, 
									float(XORRandom(360)), 
									1.0f, 
									4 + XORRandom(8), 
									0.0f, 
									false );

        if (p is null) break;

    	p.fastcollision = true;
        p.scale = 1.0f;
        p.damping = 0.925f;
		p.Z = 600.0f;
		p.lighting = false;
		p.setRenderStyle(RenderStyle::additive);
    }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    CPlayer@ damageOwner = this.getDamageOwnerPlayer();
    if (damageOwner is null) return false;

    CBlob@ ownerBlob = damageOwner.getBlob();
    if (ownerBlob is null) return false;
    
    return blob is ownerBlob
            && !blob.isKeyPressed(key_down) && blob.getPosition().y < this.getPosition().y - 4;
}

void onDie(CBlob@ this)
{
    if (this.hasTag("counterspelled"))
    {
        CBlob@ blob = getBlobByNetworkID(this.get_u16("plague_owner"));
        if (blob !is null)
        {
            blob.set_u32("plague_delay", getGameTime() + plague_delay);
        }
    }

    this.getSprite().PlaySound("PlagueBlobDie.ogg", 0.75f, 1.25f + XORRandom(10) * 0.01f);
}

const string[] anim_loop = {
	"pb_rend0",
	"pb_rend1",
	"pb_rend2",
    "pb_rend3",
    "pb_rend4",
    "pb_rend5",
    "pb_rend6",
    "pb_rend7"
};

const u8 anim_time = 4;
void laserEffects(CBlob@ this, int id)
{
    if (this.hasTag("stop_rendering")) return;

    int ts = this.getTickSinceCreated();
    string rendname = anim_loop[ts / anim_time % anim_loop.length];
    f32 z = 100.0f;

    Vec2f[] v_pos;
    Vec2f[] v_uv;
    SColor[] v_col;

    u8 a = 255;

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-16, -16));
    v_uv.push_back(Vec2f(0, 0));
    v_col.push_back(SColor(a, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(16, -16));
    v_uv.push_back(Vec2f(1, 0));
    v_col.push_back(SColor(a, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(16, 16));
    v_uv.push_back(Vec2f(1, 1));
    v_col.push_back(SColor(a, 255, 255, 255));

    v_pos.push_back(this.getInterpolatedPosition() + Vec2f(-16, 16));
    v_uv.push_back(Vec2f(0, 1));
    v_col.push_back(SColor(a, 255, 255, 255));

    Render::QuadsColored(rendname, z, v_pos, v_uv, v_col);
}
