//SwordCaster Include

#include "MagicCommon.as";

namespace SwordCasterParams
{
	enum Aim 
		{
			not_aiming = 0,
			charging,
			cast_1,
			cast_2,
			cast_3,
			extra_ready,
		}

	const ::f32 shoot_max_vel = 8.0f;
	const ::f32 MAX_ATTACK_DIST = 400.0f;
	const ::s32 MAX_MANA = 100;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		//Spell("orb", "Orb", 6, "Fire a basic orb which ricochets off of most surfaces until impacting an enemy and exploding, dealing minor damage.",
		//	SpellType::other, 3, 40, 0, 360.0f),
		//					// 2 is the cost // 40 is the charge time //360.0f is the range //the 0 is the cooldown //6 is the icon it uses
		Spell("impaler", "Impaler", 45, "Sharpen your enemies and use them as a weapon against themselves.",
				SpellType::other, 6, 15, 0, 360.0f, true),
				
		Spell("teleport", "Teleport", 40, "Point to any visible position and teleport there.",
				SpellType::other, 20, 6, 0, 250.0f, true), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
				SpellType::other, 30, 10, 0, 64.0f, true),
			
		Spell("executioner", "Executioner", 43, "The Executioner was a sword used, as the name implies, in execution by decapitation. Today, it serves another purpose. Press SHIFT to launch them in the direction of your mouse.",
				SpellType::other, 30, 45, 3, 360.0f, true),
			
		Spell("crusader", "Crusader", 42, "This spell materializes three big swords to block the enemy advancement.",
				SpellType::other, 25, 40, 0, 360.0f, true),
			
		Spell("sword_cast", "Expunger", 41, "Conjure your vast arsenal of magical daggers to attack the enemy.",
				SpellType::other, 15, 30, 0, 360.0f, true),
			 
		Spell("bladed_shell", "Bladed Shell", 44, "A circle of shear death... or at least it would be if you used the edge. This spell makes you weak to some magic attacks.",
				SpellType::other, 35, 75, 0, 0.0f, true),
			 
		Spell("hook", "Hook", 86, "Throws a sticky knife which pulls enemies or yourself to a wall. press | USE | button to cut the rope off. Disables dashing and teleporting while active. Overcharge increases throw distance.",
				SpellType::other, 6, 15, 0, 256.0f),
			 
		Spell("parry", "Parry", 46, "Reflect enemy attacks.",
				SpellType::other, 10, 10, 0, 20.0f, true),
			 
		Spell("vectorial_dash", "Vectorial Dash", 47, "Cheap movement spell for specific situations. Has a long cooldown.",
				SpellType::other, 0, 5, 8, 180.0f, true),
			 
		Spell("flame_slash", "Flame Slash", 64, "Forward slash that incinerates your enemies.",
				SpellType::other, 10, 25, 1, 70.0f, true),
			
		Spell("nemesis", "Nemesis", 85, "Summons a row of falling swords from the sky. Overcharge increases the amount of swords and decreases the delay between load and launch.",
				SpellType::other, 30, 30, 3, 384.0f),
			 
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),
			
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),			
				
		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f),

		Spell("", "", 0, "Empty spell.",
				SpellType::other, 1, 1, 0, 0.0f)						
	};
}

class SwordCasterInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	SwordCasterInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 