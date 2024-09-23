#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.Tag("counterable");
	this.set_f32("glovedist", 0);
	this.set_f32("rotary_speed_delta", 0);

	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(50.0f);
	sprite.SetEmitSound("KOGun_loop.ogg");

	CSpriteLayer@ glove = sprite.addSpriteLayer("glove", "KOGun.png", 16, 16);
	if (glove !is null)
	{
		Animation@ def = glove.addAnimation("default", 0, false);
		def.AddFrame(1);
		glove.SetAnimation(def);
		glove.SetVisible(false);
		glove.SetRelativeZ(-5.0f);
		glove.ScaleBy(Vec2f(1.25f, 1.25f));
	}
	CSpriteLayer@ spring = sprite.addSpriteLayer("spring", "KOGun.png", 96, 16);
	if (spring !is null)
	{
		Animation@ def = spring.addAnimation("default", 0, false);
		int[] frames = {1,2,3,4,5,6};
		def.AddFrames(frames);
		spring.SetAnimation(def);
		spring.SetVisible(false);
		spring.SetRelativeZ(-6.0f);
	}

	this.set_Vec2f("glovepos", this.getPosition());
}

const f32 lerp = 0.15f;
const f32 lerp_back = 0.15f;
const f32 cut_length = 4.0f;

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	Vec2f pos = this.getPosition();

	if (!setPositionToOwner(this))
	{
		this.server_Die();
		return;
	}

	CMap@ map = getMap();
	if (map is null) return;

	bool r = this.hasTag("returning");

    Vec2f aimpos = this.get_Vec2f("aimpos");
	f32 max_dist = this.get_f32("dist");
	f32 damage = this.get_f32("damage");

	Vec2f dir = pos - aimpos;
	dir.Normalize();

	f32 angle = -dir.Angle();
	bool fl = aimpos.x < pos.x;
	this.SetFacingLeft(fl);

	f32 glove_dist = this.get_f32("glovedist");
	Vec2f glove_pos = pos + Vec2f(glove_dist, 0).RotateBy(angle+180);

	int diff = r ? getGameTime()-this.get_u32("return_time") : 0;
	f32 next_dist = r ? Maths::Lerp((glove_pos-pos).Length(), 0, lerp_back + (diff * 0.1f))
					  : Maths::Lerp((glove_pos-pos).Length(), (aimpos-pos).Length(), lerp);
	Vec2f next_pos = pos + Vec2f(next_dist, 0).RotateBy(angle+180);

	u16[] ignore_ids;
	this.get("ignore_ids", ignore_ids);
	CBlob@[] bs;
	map.getBlobsInRadius(next_pos, 16.0f, @bs);
	for (u16 i = 0; i < bs.size(); i++)
	{
		CBlob@ b = bs[i];
		if (b is null || !isEnemy(this, b)) continue;
		if (ignore_ids.find(b.getNetworkID()) != -1) continue;

		ignore_ids.push_back(b.getNetworkID());
		if (!map.rayCastSolidNoBlobs(pos, b.getPosition()))
		{
			if (b.hasTag("barrier"))
			{
				this.set_u32("return_time", getGameTime());
				this.Tag("returning");
				CPlayer@ ownerplayer = this.getDamageOwnerPlayer();
				if (ownerplayer !is null && ownerplayer.getBlob() !is null)
				{
					CBlob@ owner = ownerplayer.getBlob();
					owner.AddForce(Vec2f((1.0f - ((next_pos-owner.getPosition()).Length() / 80.0f)) * 2 * owner.getMass(), 0).RotateBy(angle));
					if (isServer())
						this.server_Hit(owner, pos, Vec2f_zero, this.get_f32("damage"), Hitters::crush, true);
				}
				if (isServer())
					this.server_Hit(b, pos, glove_pos-next_pos, this.get_f32("damage"), Hitters::crush, true);
			}
			else
			{
				if (isClient())
					ParticleBlood(pos,Vec2f_zero,SColor(255,XORRandom(191) + 64,XORRandom(50),XORRandom(50)));
				if (isServer())
					this.server_Hit(b, pos, glove_pos-next_pos, this.get_f32("damage"), Hitters::crush, true);
			}
		}
		if (isClient())
			this.getSprite().PlaySound("CardImpact.ogg", 1.25f, 0.85f+XORRandom(11)*0.01f);

	}
	this.set("ignore_ids", ignore_ids);

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite is null) return;

		CSpriteLayer@ glove = sprite.getSpriteLayer("glove");
		if (glove is null) return;

		CSpriteLayer@ spring = sprite.getSpriteLayer("spring");
		if (spring is null) return;

		f32 rot = fl ? angle : angle+180;

		sprite.ResetTransform();
		sprite.RotateBy(rot, Vec2f_zero);
		//sprite.setRenderStyle(RenderStyle::additive);

		glove.ResetTransform();
		spring.ResetTransform();

		glove.SetFacingLeft(fl);
		spring.SetFacingLeft(fl);
		
		glove.RotateBy(rot, Vec2f_zero);
		spring.RotateBy(rot, Vec2f_zero);

		Vec2f offset = glove_pos-pos;
		if (!fl) offset.x *= -1;

		glove.SetOffset(offset);
		spring.SetOffset(offset*0.5f);

		f32 scale_step = 12.0f;
		f32 len = offset.Length();
		f32 step = len / scale_step;
		spring.animation.frame = Maths::Round(step);

		glove.SetVisible(true);
		spring.SetVisible(true);
		
		f32 rotary_speed = Maths::Lerp(this.get_f32("rotary_speed_delta"), Maths::Min(1.0f, (glove_pos-next_pos).Length()*0.05f), 0.5f);
		this.set_f32("rotary_speed_delta", rotary_speed);
		sprite.SetEmitSoundVolume(Maths::Max(0.5f, rotary_speed));
		sprite.SetEmitSoundSpeed(0.5f + rotary_speed);
		sprite.SetEmitSoundPaused(false);
	}

	this.set_f32("glovedist", next_dist);

	if (((glove_pos - aimpos).Length() <= cut_length || (glove_pos - pos).Length() >= max_dist-cut_length)
		|| map.isTileSolid(map.getTile(next_pos)))
	{
		this.set_u32("return_time", getGameTime());
		this.Tag("returning");
	}

	if (r && (glove_pos - pos).Length() <= cut_length)
	{
		if (isServer())
			this.server_Die();
	}
}

bool setPositionToOwner(CBlob@ this)
{
	CPlayer@ ownerPlayer = this.getDamageOwnerPlayer();
	if (ownerPlayer !is null)
	{
		CBlob@ ownerBlob = ownerPlayer.getBlob();
		if (ownerBlob !is null)
		{
			this.setPosition(ownerBlob.getPosition());
			return true;
		}
	}

	return false;
}

bool isEnemy( CBlob@ this, CBlob@ target )
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		(
			target.hasTag("barrier") ||
			(
				target.hasTag("flesh") 
				&& !target.hasTag("dead") 
				&& (friend is null
					|| friend.getTeamNum() != this.getTeamNum()
					)
			)
		)
		&& target.getTeamNum() != this.getTeamNum() 
	);
}