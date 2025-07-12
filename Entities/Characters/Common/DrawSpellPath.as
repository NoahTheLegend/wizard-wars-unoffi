// Wizard logic
#include "PlayerPrefsCommon.as"
#include "WizardCommon.as";
#include "NecromancerCommon.as";
#include "DruidCommon.as";
#include "SwordCasterCommon.as";
#include "EntropistCommon.as";
#include "PriestCommon.as";
#include "ShamanCommon.as";
#include "PaladinCommon.as";
#include "JesterCommon.as";
#include "WarlockCommon.as";

const u32 fall_step = 24.0f;
const u32 fall_max_len = 24.0f;
const f32 fall_speed = 1.0f;

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CMap@ map = blob.getMap();
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is blob)
	{
		Vec2f pos = blob.getPosition();
    	Vec2f aimpos = blob.getAimPos();
		Vec2f aimVec = aimpos - pos;
		Vec2f normal = aimVec;
		normal.Normalize();

		// show spell path
		if (blob.get_bool("casting"))
		{
			PlayerPrefsInfo@ playerPrefsInfo;
			if (!blob.getPlayer().get("playerPrefsInfo", @playerPrefsInfo)) 
			{
				return;
			}

			bool draw_grounded = false;
			string bname = blob.getName();
			f32 spell_range = -1;

			string casting_key = blob.get_string("casting_key");
			if (bname == "wizard")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Wizard.length;
				Spell spell = WizardParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Wizard[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "necromancer")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Necromancer.length;
				Spell spell = NecromancerParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Necromancer[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "druid")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Druid.length;
				Spell spell = DruidParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Druid[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "swordcaster")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_SwordCaster.length;
				Spell spell = SwordCasterParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_SwordCaster[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "entropist")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Entropist.length;
				Spell spell = EntropistParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Entropist[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "priest") 
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Priest.length;
				Spell spell = PriestParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Priest[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Priest[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Priest[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "shaman")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Shaman.length;
				Spell spell = ShamanParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Shaman[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Shaman[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Shaman[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "paladin")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Paladin.length;
				Spell spell = PaladinParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Paladin[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Paladin[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Paladin[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			else if (bname == "jester")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Jester.length;
				Spell spell = JesterParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Jester[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Jester[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Jester[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}
			if (bname == "warlock")
			{
				int hotbarLength = playerPrefsInfo.hotbarAssignments_Warlock.length;
				Spell spell = WarlockParams::spells[
					casting_key == "a2" ? playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(15,hotbarLength-1)] :
					casting_key == "a3" ? playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(16,hotbarLength-1)] :
					casting_key == "a4" ? playerPrefsInfo.hotbarAssignments_Warlock[Maths::Min(17,hotbarLength-1)] :
					playerPrefsInfo.primarySpellID];

				draw_grounded = spell.grounded;
				spell_range = spell.range;
			}

			Vec2f prop_blockedPos = blob.get_Vec2f("spell blocked pos");
			Vec2f raw_blockedPos = prop_blockedPos;
			raw_blockedPos -= normal*4;
			Vec2f blockedPos = Vec2f_zero;
			if (!blob.exists("old_blockedpos") || (blob.get_bool("casting") && !blob.get_bool("was_casting")))
			{
				blob.set_Vec2f("old_blockedpos", raw_blockedPos);
				blockedPos = raw_blockedPos;
			}
			else
			{
				blockedPos = Vec2f_lerp(blob.get_Vec2f("old_blockedpos"), raw_blockedPos, getInterpolationFactor());
				blob.set_Vec2f("old_blockedpos", blockedPos);
			}


			Vec2f myPos = getDriver().getScreenPosFromWorldPos(pos);
			Vec2f aimPos2D = getDriver().getScreenPosFromWorldPos(aimpos);

			Vec2f blockedPos2D = getDriver().getScreenPosFromWorldPos( blockedPos );
			GUI::DrawArrow2D(myPos, blockedPos2D, SColor(255, 189, 69, 224)); //SColor(255, 189, 69, 224));

			if (blob.getPlayer() is null) return;

			if (draw_grounded)
			{
				u32 height = getLandHeight(blockedPos);
				bool fail = height == 0;
				Vec2f ground_cast = Vec2f(blockedPos.x, fail ? map.tilemapheight * 8 : height);

				Vec2f ground_pos2d = getDriver().getScreenPosFromWorldPos(ground_cast);

				f32 zoom = getCamera().targetDistance;

				Vec2f fall_vec = ground_pos2d - blockedPos2D;
				u32 max_steps = fall_vec.Length()/fall_step/2;

				SColor col = fail ? SColor(175, 255, 55, 55) : SColor(175, 255, 255, 255);
				int gt = getGameTime();
				for (u32 i = 0; i < max_steps; i++)
				{
					SColor new_col = col;
					Vec2f extra_offset = Vec2f(0, (gt*fall_speed) % fall_step);
					
					f32 opacity = i == 0 ? extra_offset.y / f32(fall_step) : i == max_steps - 1 ? 1.0f - extra_offset.y / f32(fall_step) : 1;
					new_col.setAlpha(new_col.getAlpha() * opacity);

					Vec2f offset = Vec2f(0, fall_step * i) + extra_offset;
					Vec2f step_line_pos = blockedPos2D + offset;
					
					GUI::DrawLine2D(step_line_pos+offset, step_line_pos+offset+Vec2f(0, fall_max_len), new_col);
				}
				//GUI::DrawLine2D(blockedPos2D, ground_pos2d, fail ? SColor(125, 255, 55, 55) : SColor(125, 255, 255, 255));
			}
		}
	}
}

u32 getLandHeight(Vec2f pos)
{
	CMap@ map = getMap(); //standard map check
	if(map is null)
	{return 0;}

	u16 tilesdown = 0;
	
	u32 pos_y = pos.y - pos.y % map.tilesize;//Store the y pos floored to the nearest top of a tile
	while(true)//Loop until stopped inside
	{
		if(map.tilemapheight * map.tilesize < pos_y + tilesdown * map.tilesize)//If we are checking below the map itself
		{
			break;
		}
		if(map.isTileSolid(Vec2f(pos.x, pos_y + map.tilesize * tilesdown)))//if this current point has a solid tile
		{
			return(pos_y + tilesdown * map.tilesize);//The current blobs pos plus one or more tiles down
		}
		tilesdown += 1;
	}
	return 0;
}