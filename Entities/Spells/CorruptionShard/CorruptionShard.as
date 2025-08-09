#include "MagicCommon.as";
#include "SplashWater.as";
#include "SpellUtils.as";

const f32 y_offset = -15.0f;

void onInit(CBlob@ this)
{
    this.set_s32("aliveTime",1500);
    this.Tag("totem");
    this.Tag("cantparry");
    this.set_u8("despelled", 0);
    //this.Tag("multi_despell");
    this.Tag("counterable");
    this.Tag("cantmove");
    this.Tag("phase through spells");
    this.Tag("no trampoline collision");
    this.Tag("alt state");                  // has Fear else Poison
    this.set_f32("alt delay", 300.0f);
    this.set_f32("alt counter", 0.0f);
    
    this.getSprite().PlaySound("WizardShoot.ogg", 2.0f, 0.75f);

    this.addCommandID("add_mana");
}


void onTick(CBlob@ this)
{
    if(this.get_u8("despelled") >= 1 || this.getTickSinceCreated() > this.get_s32("aliveTime"))
    {
        this.Tag("mark_for_death");
    }
    CBlob@[] bs;
    getBlobsByTag("player", @bs);
    for (u16 i = 0; i < bs.length; i++){
        CBlob@ b = bs[i];
        if (this.getDistanceTo(b) > 100.0f || b.getTeamNum() == this.getTeamNum()) continue;
        if (this.hasTag("alt state")){
            Fear(b, 2.0f);
        } else {
            Poison(b, 2.0f);
        }
    }
    
    if (isServer()){
        if (this.getTickSinceCreated() - this.get_f32("alt counter") > this.get_f32("alt delay")){
            if (this.hasTag("alt state")){
                this.Untag("alt state");
            } else {
                this.Tag("alt state");
            }
            this.Sync("alt state", true);
            this.set_f32("alt counter", this.getTickSinceCreated());
        }
    }
    if (isClient()){
        CSprite@ sprite = this.getSprite();
        float waveOffset = (Maths::Sin(this.getTickSinceCreated()* 0.1f) * 2.0f) + y_offset;
        if (sprite.animation.frame == 2)
        if (this.hasTag("alt state")){
            sparks(this.getPosition()+Vec2f(0.0f, waveOffset), 10, Vec2f(0.0f, 0.0f), true);
        } else {
            sparks(this.getPosition()+Vec2f(0.0f, waveOffset), 10, Vec2f(0.0f, 0.0f), false);
        }
        sprite.SetOffset(Vec2f(0, waveOffset));
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

Random _sprk_r(21342);
void sparks(Vec2f pos, int amount, Vec2f gravity, bool alt = false)
{
	if ( !getNet().isClient() )
		return;

	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 3.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        //f32 rand = _sprk_r.NextRanged(50);
        if (alt){
            CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 255, 0, 255), true );
            if(p is null) return; //bail if we stop getting particles
            p.fastcollision = true;
            p.gravity = gravity+Vec2f(0.0f, 0.01f);
            p.timeout = 20 + _sprk_r.NextRanged(15);
            p.scale = 0.5f + _sprk_r.NextFloat();
            p.damping = 0.99f;
        }
            
        else {
            CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 0, 255, 0), true );
            if(p is null) return; //bail if we stop getting particles
            p.fastcollision = true;
            p.gravity = gravity+Vec2f(0.0f, 0.01f);
            p.timeout = 20 + _sprk_r.NextRanged(15);
            p.scale = 0.5f + _sprk_r.NextFloat();
            p.damping = 0.99f;
        }
            
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add_mana"))
	{
		u16 id = params.read_u16();
		CBlob@ b = getBlobByNetworkID(id);
		if (b is null) return;
		ManaInfo@ manaInfo;
		if (b.get("manaInfo", @manaInfo)) {
			print("add mana from " + b.getName() + " " + manaInfo.mana);
			if (manaInfo.mana < manaInfo.maxMana){
				manaInfo.mana = Maths::Min(manaInfo.mana + (this.hasTag("extra_damage") ? 30.0f : 20.0f), manaInfo.maxMana);
			}
		}
	}
}

void onDie(CBlob@ this)
{
    if (!isServer()) return;
    CPlayer@ player = this.getDamageOwnerPlayer();
    CBlob@ b = player !is null ? player.getBlob() : null;
    if (b !is null && !this.hasTag("counterspelled")){
        Heal(this, b, (this.hasTag("extra_damage") ? 3.0f : 2.0f));
        CBitStream params;
		params.write_u16(b.getNetworkID());
		this.SendCommand(this.getCommandID("add_mana"), params);
    }
}
