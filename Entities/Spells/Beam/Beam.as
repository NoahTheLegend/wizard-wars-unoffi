#include "Hitters.as";       
#include "LimitedAttacks.as";
#include "SpellUtils.as";
#include "TextureCreation.as";
#include "ShieldCommon.as";

const f32 RANGE = 128.0f;
const f32 DAMAGE = 0.2f;

const f32 LIFETIME = 3.0f;
const u8 MANA_TAKE_PERIOD = 5;
const u8 CONTINUOUS_MANA_TAKE = 1;

const int MAX_LASER_POSITIONS = 10;
const int LASER_UPDATE_TIME = 5;

const f32 TICKS_PER_SEG_UPDATE = 1;
const f32 LASER_WIDTH = 1.0f; //0.5f;

Random@ _laser_r = Random(0x10001);

void onInit(CBlob@ this)
{
	this.addCommandID("upgrade");

	this.Tag("phase through spells");
	this.Tag("counterable");
	this.Tag("cantparry");

	//dont collide with edge of the map
	this.SetMapEdgeFlags( u8(CBlob::map_collide_none) | u8(CBlob::map_collide_nodeath) );
	
	CShape@ shape = this.getShape();
	shape.SetStatic(true);
	shape.SetGravityScale( 0.0f );
	shape.SetRotationsAllowed(true);
	  
	CSprite@ thisSprite = this.getSprite();
	thisSprite.getConsts().accurateLighting = false;
	
	this.set_bool("initialized", false);
	
	this.server_SetTimeToDie(LIFETIME);
	CSpriteLayer@ l = thisSprite.addSpriteLayer("beam", "BeamLaser.png", 16, 16);
	if (l !is null)
	{
		l.SetOffset(Vec2f(-48,0));
		l.SetVisible(false);
		Animation@ anim = l.addAnimation("default", 3, true);
		if (anim !is null)
		{
			int[] frames = {3,2,1,0};
			anim.AddFrames(frames);
			l.SetAnimation(anim);
		}
	}
	CSpriteLayer@ endpos = thisSprite.addSpriteLayer("endpos", "Beam.png", 8, 8);
	if (endpos !is null)
	{
		l.SetVisible(false);
	}
	this.addCommandID("beam");
}

void setPositionToOwner(CBlob@ this)
{
	CPlayer@ ownerPlayer = this.getDamageOwnerPlayer();
	if ( ownerPlayer !is null )
	{
		CBlob@ ownerBlob = ownerPlayer.getBlob();
		if ( ownerBlob !is null )
			this.setPosition( ownerBlob.getPosition() );
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (this.getCommandID("beam") == cmd)
    {
        if (isServer())
		{
			CBlob@ shooter = getBlobByNetworkID(this.get_u16("shooter"));
			if (shooter is null) return;

			ManaInfo@ manaInfo;
			if (!shooter.get( "manaInfo", @manaInfo)) {
				return;
			}

			this.server_SetTimeToDie(0.5);
		}
    }
	else if (cmd == this.getCommandID("upgrade"))
	{
		if (this.hasTag("upgraded")) return;
		this.Tag("upgraded");

		if (isServer())
		{
			this.server_SetTimeToDie(0.5);
		}

		if (isClient())
		{
			CSprite@ thisSprite = this.getSprite();
			CSpriteLayer@ l = thisSprite.getSpriteLayer("beam");
			if (l !is null)
			{
				l.ResetTransform();
				l.ScaleBy(Vec2f(1.0f, 1.5f));
				l.SetRelativeZ(100.0f);
				l.SetVisible(true);

				Animation@ anim = l.addAnimation("default", 3, true);
				if (anim !is null)
				{
					int[] frames = {3,2,1,0};
					anim.AddFrames(frames);
					l.SetAnimation(anim);
				}
			}

			CSpriteLayer@ e = thisSprite.getSpriteLayer("endpos");
			if (e !is null)
			{
				e.ResetTransform();
				e.ScaleBy(Vec2f(1.0f, 1.5f));
				e.SetRelativeZ(100.0f);
				e.SetVisible(true);
			}
		}
	}
}

void onTick(CBlob@ this)
{
	CSprite@ thisSprite = this.getSprite();
	thisSprite.setRenderStyle(RenderStyle::additive);
	Vec2f thisPos = this.getPosition();
	CSpriteLayer@ l = thisSprite.getSpriteLayer("beam");
	CSpriteLayer@ e = thisSprite.getSpriteLayer("endpos");

	bool upgraded = this.hasTag("upgraded");
	setPositionToOwner(this);

	if (getGameTime() % 10 == 0) thisSprite.PlaySound("ManaGain.ogg", upgraded ? 0.75f : 0.6f, upgraded ? 1.4f : 1.5f);
	int mod = upgraded ? 2 : 1;

	f32 range = RANGE;
	f32 damage = DAMAGE * (mod * 0.75f);
	u8 manaTakePeriod = MANA_TAKE_PERIOD;
	u8 continuousManaTake = CONTINUOUS_MANA_TAKE * mod;

	if (this.getTickSinceCreated() > 1)
	{
		this.SetLight(true);
		this.SetLightRadius(24.0f);
		SColor lightColor = SColor(255, 255, 150, 0);
		this.SetLightColor(lightColor);
		thisSprite.SetZ(500.0f);
		if (l !is null) l.SetVisible(true);
		if (e !is null) e.SetVisible(true);

		CBlob@ shooter = getBlobByNetworkID(this.get_u16("shooter"));
		if (shooter is null)
		{
			this.Sync("shooter", true);
			@shooter = getBlobByNetworkID(this.get_u16("shooter"));
		}
		if (shooter is null || shooter.hasTag("dead"))
		{
			if (isServer()) this.server_Die();
			return;
		}
		shooter.set_u16("beam_id", this.getNetworkID());

		ManaInfo@ manaInfo;
		if (!shooter.get("manaInfo", @manaInfo))
		{
			return;
		}

		if (manaInfo.mana > 1)
		{
			if (getGameTime() % manaTakePeriod == 0)
			{
				if (shooter.isKeyPressed(key_action1) && isClient())
				{
					CBitStream params;
					this.SendCommand(this.getCommandID("beam"), params);
					if (upgraded) shooter.set_u32("NOLMB", getGameTime() + 10);
				}

				manaInfo.mana -= continuousManaTake;
			}
		}
		else if (isServer() && this.getTimeToDie() <= 0.25f) this.server_Die();

		Vec2f aimPos = shooter.getAimPos();
		Vec2f aimVec = aimPos - thisPos;
		Vec2f aimNorm = aimVec;
		aimNorm.Normalize();

		if (isServer())
		{
			this.setAngleDegrees(-aimNorm.Angle());
			this.getShape().SetAngleDegrees(-aimNorm.Angle());
		}

		Vec2f shootVec = aimNorm * range;

		Vec2f destination = thisPos + shootVec;

		CMap@ map = this.getMap();
		f32 shortestHitDist = 9999.9f;
		HitInfo@[] hitInfos;
		int attackAngle = this.getAngleDegrees();
		bool hasHit = map.getHitInfosFromRay(thisPos, attackAngle, range, this, @hitInfos);
		bool no_reset = false;
		if (hasHit)
		{
			bool damageDealt = false;
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];

				if (hi.blob !is null) // blob
				{
					CBlob@ target = hi.blob;
					if (target is this || target.hasTag("dead") || target.hasTag("invincible") || target.hasTag("counterable") || target is shooter || (!target.hasTag("barrier") && !target.hasTag("flesh")) || target.hasTag("magic_circle"))
					{
						continue;
					}
					else if (!damageDealt)
					{
						f32 extraDamage = 1.0f;
						if (this.hasTag("extra_damage"))
						{
							extraDamage += 0.25f;
						}
						Vec2f attackVector = Vec2f(1, 0).RotateBy(attackAngle);
						f32 heal = 0.075f + (XORRandom(50) * 0.001f);
						if (getGameTime() % 5 == 0 && target.getTeamNum() != this.getTeamNum())
						{
							if (isServer())
								this.server_Hit(target, hi.hitpos, this.hasTag("pull") ? -attackVector : attackVector, damage * extraDamage, Hitters::flying, true);
						}
						else if (getGameTime() % 10 == 0 && target.getTeamNum() == this.getTeamNum() && target.getHealth() + heal < target.getInitialHealth())
						{
							Heal(this, target, heal);
						}
					}
				}

				Vec2f hitPos = hi.hitpos;
				f32 distance = hi.distance;
				if (shortestHitDist > distance)
				{
					shortestHitDist = distance;
					destination = hitPos;
				}
				this.set_f32("dist", distance);
				no_reset = true;
			}
		}

		f32 dist = this.get_f32("dist");
		if (!no_reset) dist = range;

		CSpriteLayer@ b = thisSprite.getSpriteLayer("beam");
		CSpriteLayer@ e = thisSprite.getSpriteLayer("endpos");

		f32 width_mod = upgraded ? 0.7f : 1;
		if (e !is null) e.SetOffset(Vec2f(-dist, 1).RotateBy(-attackAngle, Vec2f(-dist, 1)));
		if (b !is null)
		{
			b.SetAnimation("default");
			if (dist > 1.0f && dist < 128.0f)
			{
				b.ResetTransform();
				b.setRenderStyle(RenderStyle::additive);
				b.ScaleBy(Vec2f((dist / 128.0f) * 7.75f * width_mod, 1.0f));
				b.SetOffset(Vec2f(64.0f * (dist / -128.0f), 0));
			}
			else
			{
				b.ResetTransform();
				b.setRenderStyle(RenderStyle::additive);
				b.ScaleBy(Vec2f(7.75f * width_mod, 1.0f));
				b.SetOffset(Vec2f(-64.0f, 0));
			}
		}

		this.set_Vec2f("aim pos", destination);

		Vec2f normal = (Vec2f(aimVec.y, -aimVec.x));
		normal.Normalize();

		if (shortestHitDist < range)
			beamSparks(destination - aimNorm * 4.0f, 20);
	}
	else this.Sync("pull", true);
}

Random@ _sprk_r = Random(23453);
void beamSparks(Vec2f pos, int amount)
{
	if ( !getNet().isClient() )
		return;
		
	for (int i = 0; i < amount; i++)
    {
        Vec2f vel(_sprk_r.NextFloat() * 4.0f, 0);
        vel.RotateBy(_sprk_r.NextFloat() * 360.0f);

        CParticle@ p = ParticlePixelUnlimited( pos, vel, SColor( 255, 200+_sprk_r.NextRanged(55), 128+_sprk_r.NextRanged(128), 0), true );
        if(p is null) return; //bail if we stop getting particles

    	p.fastcollision = true;
        p.timeout = 20 + _sprk_r.NextRanged(20);
        p.scale = 1.0f + _sprk_r.NextFloat();
        p.damping = 0.95f;
    }
}