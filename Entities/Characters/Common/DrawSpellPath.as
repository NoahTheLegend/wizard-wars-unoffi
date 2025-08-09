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
#include "SpellUtils.as";

const u32 fall_step = 24.0f;
const u32 fall_max_len = 24.0f;
const f32 fall_speed = 1.0f;

u16 target_grabber_time = 0;
const u16 max_grab_time = 10;
void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null || !blob.isMyPlayer()) return;

	if (blob.hasTag("update_target_grabber"))
	{
		PlayerPrefsInfo@ playerPrefsInfo;
		if (!blob.getPlayer().get("playerPrefsInfo", @playerPrefsInfo)) 
		{
			return;
		}

		u8 castSpellID;
		string bname = blob.getName();
		string casting_key = blob.get_string("casting_key");

		u8[] hotbarAssignments;
		Spell[] spellList;

		if (bname == "wizard")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Wizard;
			spellList = WizardParams::spells;
		}
		else if (bname == "necromancer")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Necromancer;
			spellList = NecromancerParams::spells;
		}
		else if (bname == "druid")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Druid;
			spellList = DruidParams::spells;
		}
		else if (bname == "swordcaster")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_SwordCaster;
			spellList = SwordCasterParams::spells;
		}
		else if (bname == "entropist")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Entropist;
			spellList = EntropistParams::spells;
		}
		else if (bname == "priest")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Priest;
			spellList = PriestParams::spells;
		}
		else if (bname == "shaman")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Shaman;
			spellList = ShamanParams::spells;
		}
		else if (bname == "paladin")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Paladin;
			spellList = PaladinParams::spells;
		}
		else if (bname == "jester")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Jester;
			spellList = JesterParams::spells;
		}
		else if (bname == "warlock")
		{
			hotbarAssignments = playerPrefsInfo.hotbarAssignments_Warlock;
			spellList = WarlockParams::spells;
		}

		int hotbarLength = hotbarAssignments.length;
		if (casting_key == "a2")
			castSpellID = hotbarAssignments[Maths::Min(15, hotbarLength-1)];
		else if (casting_key == "a3")
			castSpellID = hotbarAssignments[Maths::Min(16, hotbarLength-1)];
		else if (casting_key == "a4")
			castSpellID = hotbarAssignments[Maths::Min(17, hotbarLength-1)];
		else
			castSpellID = playerPrefsInfo.primarySpellID;

		Spell spell = spellList[castSpellID];
	
		target_grabber_time = Maths::Min(target_grabber_time + 1, max_grab_time);
		CBlob@ targetBlob = client_getNearbySpellTarget(blob, spell.range, spell.target_grab_range);
		if (targetBlob !is null)
		{
			blob.set_u16("target_grabber_id", targetBlob.getNetworkID());
		}
		else
		{
			blob.set_u16("target_grabber_id", 0);
		}

		blob.Untag("update_target_grabber");
	}
	else
	{
		target_grabber_time = 0;
	}
}

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

			u8 draw_mode = 0;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

				draw_mode = spell.target_type;
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

			if (draw_mode == 1)
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
			}
			else if (draw_mode == 2)
			{
				blob.Tag("update_target_grabber");

				u16 target_id = blob.get_u16("target_grabber_id");
				CBlob@ targetBlob = getBlobByNetworkID(target_id);

				if (targetBlob !is null)
				{
					f32 mod = f32(target_grabber_time) / f32(max_grab_time);
					Vec2f drawPos = getDriver().getScreenPosFromWorldPos(targetBlob.getPosition());

					f32 targetDistance = getCamera() !is null ? getCamera().targetDistance : 1.0f;
					GUI::DrawIcon("SpellTarget.png", (getGameTime() / 4) % 4, Vec2f(32, 48), drawPos - Vec2f(32, 60) * targetDistance, 1.0f * targetDistance, SColor(175 * mod, 255, 255, 255));
				}
			}
		}
	}
}