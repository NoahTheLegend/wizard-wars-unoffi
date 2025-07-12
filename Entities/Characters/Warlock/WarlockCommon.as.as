//Warlock Include

#include "MagicCommon.as";

namespace WarlockParams
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
	const ::f32 MAX_ATTACK_DIST = 500.0f;
	const ::s32 MAX_MANA = 50;
	const ::s32 MANA_REGEN = 3;
	
	const ::string[] zombieTypes = {"zombie", "skeleton", "greg", "wraith"};
	
	const ::Spell[] spells = 
	{
		Spell("bloodarrow_rain", "Tome of Blood", 122, "Embodies many drops of blood into sharp daggers to launch.",
			SpellType::other, 5, 20, 0, 256.0f, true),
			
		Spell("teleport", "Teleport to Target", 40, "Point to any visible position and teleport there.",
			SpellType::other, 10, 6, 0, 270.0f, true), 
			
		Spell("counter_spell", "Counter Spell", 16, "Destroy all spells around you. Also able to severely damage summoned creatures.",
			SpellType::other, 10, 10, 0, 64.0f, true),
			
		Spell("leech", "Leech", 25, "Fire a short-ranged arc of dark energy which steals the life-force from foes and revitalizes the user.",
				SpellType::other, 20, 40, 3, 180.0f, true),
		
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

class WarlockInfo
{
	s32 charge_time;
	u8 charge_state;
	bool spells_cancelling;

	WarlockInfo()
	{
		charge_time = 0;
		charge_state = 0;
		spells_cancelling = false;
	}
}; 