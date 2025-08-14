#include "DruidCommon.as";
#include "PlayerPrefsCommon.as";

const u8 chance_flowers_default = 50;
const u8 chance_spore = 10;
const u16 slow_time = 60; // how long the slow effect lasts
const u16 haste_time = 60; // how long the hasten effect lasts

const u32 flowers_time_base = 450; // how long the flowers last
const u32 flowers_time_random = 150; // random time added to the flowers time
const u32 chance_flowers_per_tick = 7500;

void onInit(CBlob@ this)
{
	this.Tag("phase through spells");
	this.Tag("counterable");
	this.Tag("die_in_divine_shield");

	this.addCommandID("add_flowers");
	this.addCommandID("request_update");
	this.getShape().getConsts().mapCollisions = false;

	this.SetMapEdgeFlags(CBlob::map_collide_none);
	this.getShape().SetGravityScale(0.0f);
	this.SetFacingLeft(XORRandom(2) == 0);

	this.set_bool("has_flowers", false);
	this.set_u16("grow_delay", 0);
	this.set_u8("grow_delay_increment", 3); // how much to increase the delay by each time
	this.set_u32("flowers_time", 0); // how long the flowers last

	this.set_bool("grown", false);
	this.set_u8("grow_power", 0); // how many tiles can be captured
	this.Tag("fall damage reduction");

	CMap@ map = getMap();
	bool[][]@ captured_tiles;
	getRules().get("moss_captured_tiles", @captured_tiles);

	this.SetFacingLeft(XORRandom(2) == 0);
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)

	if (XORRandom(2) == 0)
		sprite.SetAnimation("alt_default");

	if (isServer() && XORRandom(chance_flowers_default) == 0)
	{
		captured_tiles.resize(map.tilemapwidth);
		for (u32 i = 0; i < captured_tiles.size(); i++)
		{
			captured_tiles[i].resize(map.tilemapheight);
		}

		server_SetFlowers(this);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add_flowers"))
	{
		u32 flowers_time = params.read_u32();
		this.set_u32("flowers_time", flowers_time);
		this.set_bool("has_flowers", true);
	}
	else if (isServer() && cmd == this.getCommandID("request_update"))
	{
		u16 pid;
		if (!params.saferead_u16(pid)) return;

		CPlayer@ player = getPlayerByNetworkId(pid);
		if (player is null) return;

		server_SetFlowers(this);
	}
}

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	this.PlaySound("Moss" + (XORRandom(3)) + ".ogg", 0.15f, 1.0f+ XORRandom(10) * 0.01f);
	Vec2f[] offsets = { Vec2f(0, -8), Vec2f(0, 8), Vec2f(8, 0), Vec2f(-8, 0) };
	for (u8 i = 0; i < 4; i++)
	{
		CSpriteLayer@ l = this.addSpriteLayer("moss_" + i, "Moss.png", 10, 8);
		if (l !is null)
		{
			f32 angle = -offsets[i].Angle() - 90;
			l.SetRelativeZ(1000.0f);
			l.SetOffset(Vec2f(0, 2));
			l.RotateBy(angle, -l.getOffset());
			l.SetVisible(false);
			l.ScaleBy(Vec2f(1.05f, 1.05f));
			
			Animation@ anim = l.addAnimation("default", 4, false);
			{
				u8 add = 8 * XORRandom(2);
				anim.AddFrame(0 + add);
				anim.AddFrame(1 + add);
				anim.AddFrame(2 + add);
				anim.AddFrame(3 + add);
			}
			
			Animation@ flowers = l.addAnimation("flowers", 0, false);
			{
				flowers.AddFrame(4);
				flowers.AddFrame(5);
				flowers.AddFrame(6);
				flowers.AddFrame(7);
			}

			l.SetAnimation("default");
			blob.set_string("moss_anim_"+i, "default");
		}
	}
}

void onTick(CBlob@ this)
{
	if (getControls().isKeyPressed(KEY_KEY_R))
	{
		this.server_Die();
		return;
	}

	const u32 tick = this.getTickSinceCreated();
	if (this.getCurrentScript().tickFrequency != 1 || tick % 30 == 0)
	{
		u32 flowers_time = this.get_u32("flowers_time");
		if (getGameTime() >= flowers_time)
		{
			this.set_bool("has_flowers", false);
			this.set_u32("flowers_time", 0);
		}
		else if (this.get_bool("has_flowers"))
		{
			if (XORRandom(300 / this.getCurrentScript().tickFrequency) == 0)
			{
				MakeFlowerParticles(this.getPosition(), 2 + XORRandom(2), Vec2f(0, -1.0f), 60);
			}
		}

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite is null) return;

			Vec2f[] offsets = { Vec2f(0, -8), Vec2f(0, 8), Vec2f(8, 0), Vec2f(-8, 0) };
			CMap@ map = getMap();
			Vec2f pos = this.getPosition();

			for (u8 i = 0; i < offsets.size(); i++)
			{
				CSpriteLayer@ l = sprite.getSpriteLayer("moss_" + i);
				if (l !is null)
				{
					l.SetVisible(map.isTileSolid(pos + offsets[i]));
				}
			}
		}
	}

	if (tick == 0)
	{
		CPlayer@ local = getLocalPlayer();
		if (isClient() && local !is null)
		{
			CBitStream params;
			params.write_u16(local.getNetworkID());
		}

		if (isServer())
		{
			bool[][]@ captured_tiles;
			if (getRules().get("moss_captured_tiles", @captured_tiles))
			{
				SetTile(getMap(), this.getPosition(), true, captured_tiles);
			}
		}
	}

	if (!isServer()) return;
	if (tick == 1)
	{
		if (isServer())
		{
			CBlob@[] div_shields;
			getBlobsByName("divine_shield", @div_shields);

			for (u8 i = 0; i < div_shields.length; i++)
			{
				CBlob@ b = div_shields[i];
				if (b.getTeamNum() != this.getTeamNum() && b.getDistanceTo(this) < 88.0f)
				{
					this.Tag("mark_for_death");
					return;
				}
			}
		}
	}

	if (XORRandom(chance_flowers_per_tick / this.getCurrentScript().tickFrequency) == 0)
	{
		server_SetFlowers(this);
	}

	u16 grow_delay = this.get_u16("grow_delay");
	if (tick >= grow_delay)
	{
		Grow(this, this.get_u8("grow_power"));
		this.set_bool("grown", this.get_u8("grow_power") <= 0);
	}
}

void server_SetFlowers(CBlob@ this)
{
	if (!isServer()) return;

	u32 rnd = XORRandom(flowers_time_random);
	u32 flowers_time = getGameTime() + flowers_time_base + rnd;

	this.set_u32("flowers_time", flowers_time);
	this.set_bool("has_flowers", true);

	CBitStream params;
	params.write_u32(flowers_time);
	this.SendCommand(this.getCommandID("add_flowers"), params);
}

Vec2f getFloorOffset(Vec2f pos)
{
	CMap@ map = getMap();
	if (map is null) return Vec2f_zero;

	Vec2f floor_offset = Vec2f(0, 0);
	if (map.isTileSolid(pos + Vec2f(0, -8))) floor_offset.y = -8;
	else if (map.isTileSolid(pos + Vec2f(0, 8))) floor_offset.y = 8;
	else if (map.isTileSolid(pos + Vec2f(8, 0))) floor_offset.x = 8;
	else if (map.isTileSolid(pos + Vec2f(-8, 0))) floor_offset.x = -8;

	return floor_offset;
}

void Grow(CBlob@ this, int power)
{
	if (this.get_bool("grown") || power <= 0)
	{
		this.getCurrentScript().tickFrequency = 30;
		return;
	}

	CMap@ map = getMap();
	if (map is null) return;

	bool[][]@ captured_tiles;
	if (!getRules().get("moss_captured_tiles", @captured_tiles)) return;

	Vec2f floor_offset = getFloorOffset(this.getPosition());
	floor_offset.x = Maths::Round(floor_offset.x);
	floor_offset.y = Maths::Round(floor_offset.y);

	Vec2f pos = this.getPosition() + floor_offset;
	pos.x = Maths::Floor(pos.x / 8) * 8 + 4;
	pos.y = Maths::Floor(pos.y / 8) * 8 + 4;

	Vec2f[] adjacency_offsets = { Vec2f(0, 0), Vec2f(0, -8), Vec2f(0, 8), Vec2f(8, 0), Vec2f(-8, 0), Vec2f(8, -8), Vec2f(-8, -8), Vec2f(8, 8), Vec2f(-8, 8) };
	Vec2f[] placement_offsets = { Vec2f(0, -8), Vec2f(8, 0), Vec2f(-8, 0), Vec2f(0, 8)};
	Vec2f[] positions;

	// remove opposite adjacent offsets depending on floor_offset
	// this will remove both cardinal and diagonal offsets in the blocked direction
	array<Vec2f> blocked_offsets;
	if (floor_offset.y > 0)
	{
		// on floor below, block lower tile and lower diagonals
		blocked_offsets.push_back(Vec2f(8, 8));
		blocked_offsets.push_back(Vec2f(-8, 8));

		if (map.isTileSolid(pos + Vec2f(-8, 8)) && map.isTileSolid(pos + Vec2f(8, 8)))
			blocked_offsets.push_back(Vec2f(0, 8)); // block lower tile if both sides are solid

	}
	else if (floor_offset.y < 0)
	{
		// on ceiling, block upper tile and upper diagonals
		blocked_offsets.push_back(Vec2f(8, -8));
		blocked_offsets.push_back(Vec2f(-8, -8));

		if (map.isTileSolid(pos + Vec2f(-8, -8)) && map.isTileSolid(pos + Vec2f(8, -8)))
			blocked_offsets.push_back(Vec2f(0, -8)); // block upper tile if both sides are solid
	}
	else if (floor_offset.x > 0)
	{
		// on right wall, block right tile and right diagonals
		blocked_offsets.push_back(Vec2f(8, 0));
		blocked_offsets.push_back(Vec2f(8, 8));
		blocked_offsets.push_back(Vec2f(8, -8));
	}
	else if (floor_offset.x < 0)
	{
		// on left wall, block left tile and left diagonals
		blocked_offsets.push_back(Vec2f(-8, 0));
		blocked_offsets.push_back(Vec2f(-8, 8));
		blocked_offsets.push_back(Vec2f(-8, -8));
	}

	// remove all blocked offsets from adjacency_offsets
	for (int i = int(adjacency_offsets.length) - 1; i >= 0; i--)
	{
		for (uint j = 0; j < blocked_offsets.length; j++)
		{
			if (adjacency_offsets[i] == blocked_offsets[j])
			{
				adjacency_offsets.erase(i);
				break;
			}
		}
	}

	bool added_moss = false;
	for (u8 i = 0; i < adjacency_offsets.length; i++)
	{
		if (power <= 0) break;

		Vec2f offset = adjacency_offsets[i].x != 0 ? map.isTileSolid(pos + adjacency_offsets[i] - Vec2f(0, 8)) ? adjacency_offsets[i] - Vec2f(0, 8) : adjacency_offsets[i] : adjacency_offsets[i];
		Vec2f solid_check_pos = pos + offset;
		if (map.isTileSolid(solid_check_pos))
		{
			for (u8 j = 0; j < placement_offsets.length; j++)
			{
				if (power <= 0) break;

				Vec2f placement_pos = solid_check_pos + placement_offsets[j];
				if (!map.isTileSolid(placement_pos) && !IsTileCaptured(map, placement_pos, captured_tiles))
				{
					if (SetTile(map, placement_pos, true, captured_tiles))
					{
						power--;
						positions.push_back(placement_pos);
						
						added_moss = true;
					}
				}
			}
		}
	}

	this.getCurrentScript().tickFrequency = added_moss ? 1 : 30;
	if (!positions.empty())
	{
		u16 grow_delay = this.get_u16("grow_delay") + XORRandom(this.get_u8("grow_delay_increment"));
		u16 grow_delay_inc = this.get_u8("grow_delay_increment");

		CPlayer@ owner = this.getDamageOwnerPlayer();
		const int team_num = this.getTeamNum();

		for (u8 i = 0; i < positions.length; i++)
		{
			CBlob@ moss = server_CreateBlob("moss", team_num, positions[i]);
			if (moss !is null)
			{
				moss.getShape().SetRotationsAllowed(false);
				moss.getShape().SetStatic(true);
				moss.SetDamageOwnerPlayer(owner);

				moss.set_u8("grow_power", power);
				moss.set_u16("grow_delay", grow_delay);
				moss.set_u8("grow_delay_increment", grow_delay_inc);
				this.add_u8("grow_delay_increment", grow_delay_inc);

				moss.set_u16("owner_id", this.get_u16("owner_id"));
				moss.Tag("owner" + this.get_u16("owner_id"));

				moss.server_SetTimeToDie(this.getTimeToDie());
			}
		}
	}

	this.set_u8("grow_power", power);
}

bool SetTile(CMap@ map, Vec2f pos, bool capture, bool[][]@ captured_tiles)
{
	Vec2f tilespace(Maths::Floor(pos.x / 8), Maths::Floor(pos.y / 8));
	if (tilespace.x < 0 || tilespace.x >= map.tilemapwidth || tilespace.y < 0 || tilespace.y >= map.tilemapheight)
		return false;

	if (captured_tiles.size() <= tilespace.x || captured_tiles[tilespace.x].size() <= tilespace.y)
		return false;

	captured_tiles[tilespace.x][tilespace.y] = capture;
	return true;
}

bool IsTileCaptured(CMap@ map, Vec2f pos, const bool[][]@ &in captured_tiles)
{
	Vec2f tilespace(Maths::Floor(pos.x / 8), Maths::Floor(pos.y / 8));
	if (tilespace.x < 0 || tilespace.x >= map.tilemapwidth || tilespace.y < 0 || tilespace.y >= map.tilemapheight)
		return false;

	if (captured_tiles.size() <= tilespace.x || captured_tiles[tilespace.x].size() <= tilespace.y)
		return false;

	return captured_tiles[uint(tilespace.x)][uint(tilespace.y)];
}

void onTick(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;

	bool grown = this.get_bool("grown");
	bool has_flowers = this.get_bool("has_flowers");

	for (u8 i = 0; i < 4; i++)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer("moss_" + i);
		if (layer is null) continue;

		string animation_name = this.get_string("moss_anim_" + i);
		bool animation_ended = layer.isAnimationEnded();

		if (animation_ended && animation_name == "default")
		{
			if (has_flowers)
			{
				layer.SetAnimation("flowers");
				layer.animation.frame = XORRandom(4);
				this.set_string("moss_anim_"+i, "flowers");
			}
		}
		else if (animation_name == "flowers")
		{
			if (!has_flowers)
			{
				layer.SetAnimation("default");
				layer.animation.frame = 3;
				this.set_string("moss_anim_"+i, "default");
			}
		}
	}
}

bool isEnemy(CBlob@ this, CBlob@ target)
{
	CBlob@ friend = getBlobByNetworkID(target.get_netid("brain_friend_id"));
	return 
	(
		target.hasTag("flesh") 
		&& target.getTeamNum() != this.getTeamNum() 
		&& (friend is null || friend.getTeamNum() != this.getTeamNum())
	);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null)
		return;

	if (blob.hasTag("flesh"))
	{
		if (isServer())
		{
			CBlob@[] mgs;
			getBlobsByTag("mg_owner" + this.get_u16("owner_id"), @mgs);
			for (u8 i = 0; i < mgs.length; i++)
			{
				CBlob@ mg = mgs[i];
				if (mg !is null && mg.getTeamNum() == this.getTeamNum()
					&& mg.getTeamNum() != blob.getTeamNum() && mg.getDistanceTo(blob) < 512.0f)
				{
					if (mg.get_u16("target_id") == 0)
						mg.set_u16("target_id", blob.getNetworkID());
				}
			}
		}
		if (this.get_bool("has_flowers"))
		{
			// sound
			if (isClient() && XORRandom(4) == 0)
			{
				MakeFlowerParticles(this.getPosition(), 3 + XORRandom(3), Vec2f(0, -1.0f), 90);
			}

			if (isEnemy(this, blob) && blob.get_u16("hastened") == 0)
			{
				// apply slow effect
				if (blob.hasTag("player"))
				{
					blob.set_u16("slowed", Maths::Max(slow_time, blob.get_u16("slowed")));
					if (isServer()) blob.Sync("slowed", true);
				}
			}
			else if (blob.get_u16("slowed") == 0)
			{
				// apply hastens effect
				if (blob.hasTag("player"))
				{
					blob.set_u16("hastened", Maths::Max(haste_time, blob.get_u16("hastened")));
					if (isServer()) blob.Sync("hastened", true);
				}
			}
		}
	}
	else
	{
		if (isServer() && blob.getName() == "sporeshot" && XORRandom(chance_spore) == 0)
		{
			server_SetFlowers(this);
		}
	}
}

void onDie(CBlob@ this)
{
	bool[][]@ captured_tiles;
	if (getRules().get("moss_captured_tiles", @captured_tiles))
	{
		SetTile(getMap(), this.getPosition(), false, captured_tiles);
	}

	if (!this.get_bool("has_flowers")) return;
	MakeFlowerParticles(this.getPosition(), 5+XORRandom(4), Vec2f(0, -1.0f), 60);
}

void MakeFlowerParticles(Vec2f pos, u8 count, Vec2f vel = Vec2f_zero, int angle_deviation = 0)
{
	for (u8 i = 0; i < count; i++)
	{
		f32 grav = 0.05f + XORRandom(50) * 0.001f;
		Vec2f _vel = vel;
		_vel.RotateBy(XORRandom(angle_deviation)-angle_deviation/2);
		Vec2f _pos = pos+Vec2f(XORRandom(4)-2, XORRandom(4)-2);

		CParticle@ p = ParticleAnimated("MossParticle.png", _pos, _vel, float(XORRandom(360)), 1.0f - XORRandom(25) * 0.001f, 8+XORRandom(3), grav, false);
		if (p !is null)
		{
			p.Z = 10.0f;
			p.gravity = Vec2f(0, grav);
			p.velocity = _vel;
			p.collides = false;
			p.fastcollision = true;
			p.timeout = 150;
		}
	}
}